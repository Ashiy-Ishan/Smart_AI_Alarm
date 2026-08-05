import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:http/http.dart' as http;

/// Provides the small Google Calendar/Gmail surface used by the profile tabs.
class GoogleSyncService {
  static const _scopes = <String>[
    calendar.CalendarApi.calendarReadonlyScope,
    gmail.GmailApi.gmailReadonlyScope,
  ];

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Future<GoogleSignInAccount?> linkAccount() async {
    await _googleSignIn.initialize();
    final account = await _googleSignIn.authenticate(scopeHint: _scopes);
    await account.authorizationClient.authorizeScopes(_scopes);
    return account;
  }

  Future<AuthClient?> _client() async {
    await _googleSignIn.initialize();
    final account = await _googleSignIn.authenticate(scopeHint: _scopes);
    final authorization = await account.authorizationClient.authorizeScopes(_scopes);
    final token = authorization.accessToken;
    final credentials = AccessCredentials(
      AccessToken('Bearer', token, DateTime.now().toUtc().add(const Duration(minutes: 50))),
      null,
      _scopes,
    );
    return authenticatedClient(http.Client(), credentials);
  }

  Future<List<calendar.Event>> fetchUpcomingEvents() async {
    final client = await _client();
    if (client == null) return <calendar.Event>[];
    try {
      final events = await calendar.CalendarApi(client).events.list(
            'primary',
            timeMin: DateTime.now().toUtc(),
            maxResults: 20,
            singleEvents: true,
            orderBy: 'startTime',
          );
      return events.items ?? <calendar.Event>[];
    } catch (_) {
      return <calendar.Event>[];
    } finally {
      client.close();
    }
  }

  Future<List<gmail.Message>> fetchLatestEmails() async {
    final client = await _client();
    if (client == null) return <gmail.Message>[];
    try {
      final api = gmail.GmailApi(client);
      final listed = await api.users.messages.list('me', q: 'is:unread', maxResults: 20);
      final messages = listed.messages ?? <gmail.Message>[];
      return Future.wait(messages.map((message) => api.users.messages.get('me', message.id!)));
    } catch (_) {
      return <gmail.Message>[];
    } finally {
      client.close();
    }
  }
}
