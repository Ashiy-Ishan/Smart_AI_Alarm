import 'dart:convert';

import 'package:alarm_frontend/models/agenda_model.dart';
import 'package:alarm_frontend/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:googleapis/gmail/v1.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoogleSyncService {
  static final GoogleSyncService _instance = GoogleSyncService._internal();

  static final Logger _logger = Logger();

  factory GoogleSyncService() => _instance;

  GoogleSyncService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  GoogleSignInAccount? _cachedAccount;

  http.Client? _authenticatedClient;

  bool _isInitialized = false;

  static const List<String> _scopes = [
    CalendarApi.calendarReadonlyScope,
    GmailApi.gmailReadonlyScope,
    'https://www.googleapis.com/auth/contacts.readonly',
  ];

  // =========================================================
  // GOOGLE INITIALIZATION
  // =========================================================

  Future<void> _ensureInitialized() async {
    if (_isInitialized) {
      return;
    }

    try {
      await _googleSignIn.initialize();

      _cachedAccount = await _googleSignIn.attemptLightweightAuthentication();

      _isInitialized = true;

      _logger.i('Google Sign-In initialized');
    } catch (e, stackTrace) {
      _logger.e(
        'Google initialization failed',
        error: e,
        stackTrace: stackTrace,
      );

      debugPrint('Google Init Error: $e');
    }
  }

  // =========================================================
  // CHECK LINK STATUS
  // =========================================================

  Future<bool> isLinked() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser == null) {
        return false;
      }

      await _ensureInitialized();

      _cachedAccount ??= await _googleSignIn.attemptLightweightAuthentication();

      final account = _cachedAccount;

      if (account == null) {
        return false;
      }

      final authorization = await account.authorizationClient
          .authorizationForScopes(_scopes);

      return authorization != null;
    } catch (e, stackTrace) {
      _logger.w(
        'Unable to check Google link status',
        error: e,
        stackTrace: stackTrace,
      );

      return false;
    }
  }

  // =========================================================
  // LINK GOOGLE ACCOUNT
  // =========================================================

  Future<GoogleSignInAccount?> linkAccount() async {
    try {
      await _ensureInitialized();

      _cachedAccount ??= await _googleSignIn.attemptLightweightAuthentication();

      if (_cachedAccount == null) {
        if (!_googleSignIn.supportsAuthenticate()) {
          debugPrint(
            'Google authenticate() is not supported on this platform.',
          );

          return null;
        }

        _cachedAccount = await _googleSignIn.authenticate();
      }

      final account = _cachedAccount;

      if (account == null) {
        return null;
      }

      await account.authorizationClient.authorizeScopes(_scopes);

      // Force a new HTTP client with the newly
      // authorized token.
      _authenticatedClient?.close();
      _authenticatedClient = null;

      return account;
    } catch (e, stackTrace) {
      _logger.e(
        'Google account linking failed',
        error: e,
        stackTrace: stackTrace,
      );

      debugPrint('Link Error: $e');

      return null;
    }
  }

  // =========================================================
  // UNLINK
  // =========================================================

  Future<void> unlinkAccount() async {
    try {
      await _ensureInitialized();

      await _googleSignIn.signOut();

      _cachedAccount = null;

      _authenticatedClient?.close();
      _authenticatedClient = null;

      final prefs = await SharedPreferences.getInstance();

      await prefs.remove('cached_priority_emails');

      await prefs.remove('cached_agenda_events');

      await prefs.remove('cached_unified_agenda');
    } catch (e, stackTrace) {
      _logger.e('Google unlink failed', error: e, stackTrace: stackTrace);

      debugPrint('Unlink Error: $e');
    }
  }

  // =========================================================
  // AUTHENTICATED HTTP CLIENT
  // =========================================================

  Future<http.Client?> _getAuthenticatedClient() async {
    if (_authenticatedClient != null) {
      return _authenticatedClient;
    }

    try {
      await _ensureInitialized();

      _cachedAccount ??= await _googleSignIn.attemptLightweightAuthentication();

      final account = _cachedAccount;

      if (account == null) {
        return null;
      }

      var authorization = await account.authorizationClient
          .authorizationForScopes(_scopes);

      if (authorization == null) {
        try {
          authorization = await account.authorizationClient.authorizeScopes(
            _scopes,
          );
        } catch (e, stackTrace) {
          _logger.w(
            'Google scopes were not authorized',
            error: e,
            stackTrace: stackTrace,
          );

          return null;
        }
      }

      _authenticatedClient = GoogleAuthenticatedClient(
        authorization.accessToken,
      );

      return _authenticatedClient;
    } catch (e, stackTrace) {
      _logger.e(
        'Unable to create authenticated Google client',
        error: e,
        stackTrace: stackTrace,
      );

      return null;
    }
  }

  // =========================================================
  // CALENDAR
  // =========================================================

  Future<List<Event>> fetchUpcomingEvents() async {
    return fetchEvents(timeMin: DateTime.now().toUtc(), maxResults: 15);
  }

  Future<List<Event>> fetchEvents({
    required DateTime timeMin,
    DateTime? timeMax,
    int maxResults = 250,
  }) async {
    try {
      final client = await _getAuthenticatedClient();

      if (client == null) {
        return [];
      }

      final calendar = CalendarApi(client);

      final events = await calendar.events.list(
        'primary',

        timeMin: timeMin.toUtc(),

        timeMax: timeMax?.toUtc(),

        maxResults: maxResults,

        orderBy: 'startTime',

        singleEvents: true,
      );

      final items = events.items ?? <Event>[];

      await _cacheAgendaEvents(items);

      return items;
    } catch (e, stackTrace) {
      _logger.e('Calendar fetch failed', error: e, stackTrace: stackTrace);

      debugPrint('Calendar Fetch Error: $e');

      return [];
    }
  }

  // =========================================================
  // GMAIL - LATEST EMAILS
  // =========================================================

  Future<List<Message>> fetchLatestEmails() async {
    try {
      final client = await _getAuthenticatedClient();

      if (client == null) {
        return [];
      }

      final gmail = GmailApi(client);

      final response = await gmail.users.messages.list(
        'me',
        maxResults: 10,
        q:
            'is:unread '
            '-category:social '
            '-category:promotions',
      );

      final messageRefs = response.messages;

      if (messageRefs == null || messageRefs.isEmpty) {
        return [];
      }

      final futures = messageRefs
          .where((message) => message.id != null)
          .map(
            (message) =>
                gmail.users.messages.get('me', message.id!, format: 'full'),
          )
          .toList();

      final emails = await Future.wait(futures);

      await _cachePriorityEmails(emails);

      return emails;
    } catch (e, stackTrace) {
      _logger.e('Gmail fetch failed', error: e, stackTrace: stackTrace);

      debugPrint('Gmail Fetch Error: $e');

      return [];
    }
  }

  // =========================================================
  // GMAIL - MEETING EMAILS
  // =========================================================

  Future<List<Message>> fetchPriorityMeetingEmails() async {
    try {
      final client = await _getAuthenticatedClient();

      if (client == null) {
        return [];
      }

      final gmail = GmailApi(client);

      const query =
          '-category:social '
          '-category:promotions '
          'subject:('
          'meeting OR '
          'scheduled OR '
          'canceled OR '
          'invitation OR '
          'updated OR '
          '"zoom link" OR '
          '"google meet" OR '
          'interview OR '
          '"sync"'
          ')';

      final response = await gmail.users.messages.list(
        'me',
        maxResults: 10,
        q: query,
      );

      final messageRefs = response.messages;

      if (messageRefs == null || messageRefs.isEmpty) {
        return [];
      }

      final futures = messageRefs
          .where((message) => message.id != null)
          .map(
            (message) =>
                gmail.users.messages.get('me', message.id!, format: 'full'),
          )
          .toList();

      return await Future.wait(futures);
    } catch (e, stackTrace) {
      _logger.e(
        'Priority Gmail fetch failed',
        error: e,
        stackTrace: stackTrace,
      );

      debugPrint('Priority Gmail Fetch Error: $e');

      return [];
    }
  }

  // =========================================================
  // UNIFIED AGENDA
  // =========================================================

  Future<void> saveUnifiedAgenda(List<AgendaModel> agenda) async {
    final prefs = await SharedPreferences.getInstance();

    final oldAgenda = await getCachedUnifiedAgenda();

    for (final newItem in agenda) {
      if (!newItem.isUpdated) {
        continue;
      }

      AgendaModel? existing;

      for (final oldItem in oldAgenda) {
        if (oldItem.id == newItem.id) {
          existing = oldItem;
          break;
        }
      }

      if (existing != null && existing.time != newItem.time) {
        await NotificationService().showInstantNotification(
          title: 'Meeting Rescheduled',
          body: '${newItem.title} moved to ${newItem.time}.',
        );
      }
    }

    final data = agenda.map((item) => jsonEncode(item.toJson())).toList();

    await prefs.setStringList('cached_unified_agenda', data);
  }

  Future<List<AgendaModel>> getCachedUnifiedAgenda() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final list = prefs.getStringList('cached_unified_agenda') ?? [];

      return list
          .map(
            (item) => AgendaModel.fromJson(
              Map<String, dynamic>.from(jsonDecode(item)),
            ),
          )
          .toList();
    } catch (e, stackTrace) {
      _logger.w(
        'Failed to read cached unified agenda',
        error: e,
        stackTrace: stackTrace,
      );

      return [];
    }
  }

  // =========================================================
  // EMAIL CACHE
  // =========================================================

  Future<List<Map<String, dynamic>>> getCachedEmails() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final list = prefs.getStringList('cached_priority_emails') ?? [];

      return list
          .map((item) => Map<String, dynamic>.from(jsonDecode(item)))
          .toList();
    } catch (e, stackTrace) {
      _logger.w(
        'Failed to read cached Gmail messages',
        error: e,
        stackTrace: stackTrace,
      );

      return [];
    }
  }

  // =========================================================
  // EVENT CACHE
  // =========================================================

  Future<List<Event>> getCachedEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final list = prefs.getStringList('cached_agenda_events') ?? [];

      return list
          .map(
            (item) =>
                Event.fromJson(Map<String, dynamic>.from(jsonDecode(item))),
          )
          .toList();
    } catch (e, stackTrace) {
      _logger.w(
        'Failed to read cached Calendar events',
        error: e,
        stackTrace: stackTrace,
      );

      return [];
    }
  }

  Future<void> _cacheAgendaEvents(List<Event> events) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final data = events.map((event) => jsonEncode(event.toJson())).toList();

      await prefs.setStringList('cached_agenda_events', data);
    } catch (e, stackTrace) {
      _logger.w(
        'Failed to cache Calendar events',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _cachePriorityEmails(List<Message> emails) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final data = emails.map((email) => jsonEncode(email.toJson())).toList();

      await prefs.setStringList('cached_priority_emails', data);
    } catch (e, stackTrace) {
      _logger.w(
        'Failed to cache Gmail messages',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  // =========================================================
  // SIGN OUT
  // =========================================================

  Future<void> signOut() async {
    try {
      await _ensureInitialized();

      await _googleSignIn.signOut();

      _cachedAccount = null;

      _authenticatedClient?.close();

      _authenticatedClient = null;
    } catch (e, stackTrace) {
      _logger.e('Google sign out failed', error: e, stackTrace: stackTrace);
    }
  }
}

// =============================================================
// AUTHENTICATED GOOGLE HTTP CLIENT
// =============================================================

class GoogleAuthenticatedClient extends http.BaseClient {
  final String accessToken;

  final http.Client _inner = http.Client();

  GoogleAuthenticatedClient(this.accessToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $accessToken';

    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();

    super.close();
  }
}
