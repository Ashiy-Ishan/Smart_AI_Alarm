import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:googleapis/gmail/v1.dart';
import 'package:http/http.dart' as http;

class GoogleSyncService {
  static final GoogleSyncService _instance = GoogleSyncService._internal();
  factory GoogleSyncService() => _instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  GoogleSignInAccount? _cachedAccount;
  bool _isInitialized = false;

  GoogleSyncService._internal();

  Future<void> _ensureInitialized() async {
    if (_isInitialized && _cachedAccount != null) return;
    try {
      await _googleSignIn.initialize();
      _cachedAccount = await _googleSignIn.attemptLightweightAuthentication();
      _isInitialized = true;
    } catch (e) {
      print('Google Init Error: $e');
    }
  }

  final List<String> _scopes = [
    CalendarApi.calendarReadonlyScope,
    GmailApi.gmailReadonlyScope,
    "https://www.googleapis.com/auth/contacts.readonly",
  ];

  Future<bool> isLinked() async {
    await _ensureInitialized();
    
    _cachedAccount ??= await _googleSignIn.attemptLightweightAuthentication();
    if (_cachedAccount == null) return false;

    try {
      var authz = await _cachedAccount!.authorizationClient.authorizationForScopes(_scopes);
      return authz != null && authz.accessToken != null;
    } catch (e) {
      return false;
    }
  }

  Future<GoogleSignInAccount?> linkAccount() async {
    try {
      await _ensureInitialized();

      _cachedAccount = await _googleSignIn.attemptLightweightAuthentication();
      _cachedAccount ??= await _googleSignIn.authenticate();

      if (_cachedAccount != null) {
        await _cachedAccount!.authorizationClient.authorizeScopes(_scopes);
      }

      return _cachedAccount;
    } catch (e) {
      print('Link Error: $e');
      return null;
    }
  }

  Future<void> unlinkAccount() async {
    try {
      await _googleSignIn.signOut();
      _cachedAccount = null;
    } catch (e) {
      print('Unlink Error: $e');
    }
  }

  Future<http.Client?> _getAuthenticatedClient() async {
    try {
      await _ensureInitialized();
      _cachedAccount ??= await _googleSignIn.attemptLightweightAuthentication();

      if (_cachedAccount == null) return null;

      var authz = await _cachedAccount!.authorizationClient.authorizationForScopes(_scopes);

      if (authz == null || authz.accessToken == null) {
        authz = await _cachedAccount!.authorizationClient.authorizeScopes(_scopes);
      }

      final String? token = authz.accessToken;
      if (token == null) return null;

      return GoogleAuthenticatedClient(token);
    } catch (e) {
      print('Auth Client Error: $e');
      return null;
    }
  }

  Future<List<Event>> fetchUpcomingEvents() async {
    try {
      final client = await _getAuthenticatedClient();
      if (client == null) return [];

      final calendar = CalendarApi(client);
      final now = DateTime.now().toUtc();
      final events = await calendar.events.list(
        'primary',
        timeMin: now,
        maxResults: 15,
        orderBy: 'startTime',
        singleEvents: true,
      );

      return events.items ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Message>> fetchLatestEmails() async {
    try {
      final client = await _getAuthenticatedClient();
      if (client == null) return [];

      final gmail = GmailApi(client);
      final response = await gmail.users.messages.list('me', maxResults: 10, q: 'is:unread');

      List<Message> emails = [];
      if (response.messages != null) {
        for (var msg in response.messages!) {
          final fullMsg = await gmail.users.messages.get('me', msg.id!);
          emails.add(fullMsg);
        }
      }
      return emails;
    } catch (e) {
      return [];
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _cachedAccount = null;
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
