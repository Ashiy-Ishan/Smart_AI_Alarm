import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:googleapis/gmail/v1.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:alarm_frontend/models/agenda_model.dart';
import 'package:alarm_frontend/services/notification_service.dart';

class GoogleSyncService {
  static final GoogleSyncService _instance = GoogleSyncService._internal();
  static final Logger _logger = Logger();
  factory GoogleSyncService() => _instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  GoogleSignInAccount? _cachedAccount;
  http.Client? _authenticatedClient;
  bool _isInitialized = false;

  GoogleSyncService._internal();

  Future<void> _ensureInitialized() async {
    if (_isInitialized && _cachedAccount != null) return;
    try {
      await _googleSignIn.initialize();
      _cachedAccount = await _googleSignIn.attemptLightweightAuthentication();
      _isInitialized = true;
    } catch (error, stackTrace) {
      _logger.e(
        'Failed to initialize Google Sign-In',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  final List<String> _scopes = [
    CalendarApi.calendarReadonlyScope,
    GmailApi.gmailReadonlyScope,
    "https://www.googleapis.com/auth/contacts.readonly",
  ];

  Future<bool> isLinked() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      await _ensureInitialized();
      _cachedAccount ??= await _googleSignIn.attemptLightweightAuthentication();

      if (_cachedAccount == null) return false;

      // verify that we have the required permissions
      final authz = await _cachedAccount!.authorizationClient.authorizationForScopes(_scopes);
      return authz?.accessToken != null;
    } catch (e) {
      return false;
    }
  }

  Future<GoogleSignInAccount?> linkAccount() async {
    try {
      await _ensureInitialized();
      _cachedAccount = await _googleSignIn.attemptLightweightAuthentication();

      // show account picker only if totally necessary
      _cachedAccount ??= await _googleSignIn.authenticate();
      if (_cachedAccount != null) {
        await _cachedAccount!.authorizationClient.authorizeScopes(_scopes);
      }
      _authenticatedClient = null;
      return _cachedAccount;
    } catch (error, stackTrace) {
      _logger.e(
        'Failed to link Google account',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> unlinkAccount() async {
    try {
      await _googleSignIn.signOut();
      _cachedAccount = null;
      _authenticatedClient = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_priority_emails');
      await prefs.remove('cached_agenda_events');
      await prefs.remove('cached_unified_agenda');
    } catch (error, stackTrace) {
      _logger.e(
        'Failed to unlink Google account',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<http.Client?> _getAuthenticatedClient() async {
    if (_authenticatedClient != null) return _authenticatedClient;
    try {
      await _ensureInitialized();
      _cachedAccount ??= await _googleSignIn.attemptLightweightAuthentication();
      if (_cachedAccount == null) return null;

      var authz = await _cachedAccount!.authorizationClient.authorizationForScopes(_scopes);
      if (authz?.accessToken == null) {
        try {
          authz = await _cachedAccount!.authorizationClient.authorizeScopes(_scopes);
        } catch (e) {
          return null;
        }
      }

      final token = authz?.accessToken;
      if (token == null) return null;

      _authenticatedClient = GoogleAuthenticatedClient(token);
      return _authenticatedClient;
    } catch (error, stackTrace) {
      _logger.e(
        'Failed to create an authenticated Google client',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

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
      if (client == null) return [];
      final calendar = CalendarApi(client);

      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day).toUtc();

      final events = await calendar.events.list(
        'primary',
        timeMin: timeMin.toUtc(),
        timeMax: timeMax?.toUtc(),
        maxResults: maxResults,
        orderBy: 'startTime',
        singleEvents: true,
      );

      final List<Event> items = events.items ?? [];
      _cacheAgendaEvents(items); // Cache raw events for Calendar Screen
      return items;
    } catch (e) {
      return [];
    }
  }

  // RESTORED: General unread email fetcher for Gmail Screen
  Future<List<Message>> fetchLatestEmails() async {
    try {
      final client = await _getAuthenticatedClient();
      if (client == null) return [];
      final gmail = GmailApi(client);

      final response = await gmail.users.messages.list(
        'me',
        maxResults: 10,
        q: 'is:unread -category:social -category:promotions',
      );
      if (response.messages == null) return [];

      final detailFutures = response.messages!
          .where((m) => m.id != null)
          .map((m) => gmail.users.messages.get('me', m.id!, format: 'full'))
          .toList();

      final List<Message> emails = await Future.wait(detailFutures);
      _cachePriorityEmails(emails); // Update generic email cache
      return emails;
    } catch (e) {
      _logger.e("Gmail Fetch Error", error: e);
      return [];
    }
  }

  Future<List<Message>> fetchPriorityMeetingEmails() async {
    try {
      final client = await _getAuthenticatedClient();
      if (client == null) return [];
      final gmail = GmailApi(client);
      const String query =
          '-category:social -category:promotions subject:(meeting OR scheduled OR canceled OR invitation OR updated OR "zoom link" OR "google meet" OR interview OR "sync")';
      final response = await gmail.users.messages.list('me', maxResults: 10, q: query);
      if (response.messages == null) return [];
      final detailFutures = response.messages!
          .where((m) => m.id != null)
          .map((m) => gmail.users.messages.get('me', m.id!, format: 'full'))
          .toList();
      return await Future.wait(detailFutures);
    } catch (e) {
      return [];
    }
  }

  Future<void> saveUnifiedAgenda(List<AgendaModel> agenda) async {
    final prefs = await SharedPreferences.getInstance();

    final List<AgendaModel> oldAgenda = await getCachedUnifiedAgenda();
    for (var newItem in agenda) {
      if (newItem.isUpdated) {
        final existing = oldAgenda.firstWhere((old) => old.id == newItem.id, orElse: () => newItem);
        if (existing.time != newItem.time) {
          NotificationService().showInstantNotification(
            title: "Meeting Rescheduled",
            body: "${newItem.title} moved to ${newItem.time}.",
          );
        }
      }
    }

    final List<String> data = agenda.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('cached_unified_agenda', data);
  }

  Future<List<AgendaModel>> getCachedUnifiedAgenda() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('cached_unified_agenda') ?? [];
      return list.map((s) => AgendaModel.fromJson(jsonDecode(s))).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getCachedEmails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('cached_priority_emails') ?? [];
      return list.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
    } catch (e) {
      return [];
    }
  }

  // RESTORED: Required by Calendar Screen
  Future<List<Event>> getCachedEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('cached_agenda_events') ?? [];
      return list.map((s) => Event.fromJson(jsonDecode(s))).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _cacheAgendaEvents(List<Event> events) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> data = events.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('cached_agenda_events', data);
  }

  Future<void> _cachePriorityEmails(List<Message> emails) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> data = emails.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('cached_priority_emails', data);
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _cachedAccount = null;
    _authenticatedClient = null;
  }
}

class GoogleAuthenticatedClient extends http.BaseClient {
  final String accessToken;
  final http.Client _inner = http.Client();
  GoogleAuthenticatedClient(this.accessToken);
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $accessToken';
    return _inner.send(request);
  }
}
