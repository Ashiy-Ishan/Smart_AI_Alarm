import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:googleapis/gmail/v1.dart';
import 'package:http/http.dart' as http;

class GoogleSyncService {
  static final GoogleSyncService _instance = GoogleSyncService._internal();
  factory GoogleSyncService() => _instance;
  GoogleSyncService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  final List<String> _scopes = [
    CalendarApi.calendarReadonlyScope,
    GmailApi.gmailReadonlyScope,
  ];

  Future<GoogleSignInAccount?> linkAccount() async {
    try {
      await _googleSignIn.initialize();
      
      // log in and get user details
      final account = await _googleSignIn.authenticate();
      
      if (account != null) {
        // get permissions for calendar and gmail
        await account.authorizationClient.authorizeScopes(_scopes);
      }
      
      return account;
    } catch (e) {
      print('Error linking account: $e');
      return null;
    }
  }

  Future<http.Client?> _getAuthenticatedClient() async {
    try {
      await _googleSignIn.initialize();
      
      // check if user is already logged in
      final account = await _googleSignIn.authenticate();
      
      if (account == null) return null;

      // try to get access without showing a popup
      var authz = await account.authorizationClient.authorizationForScopes(_scopes);
      
      // if silent fails, show the popup
      authz ??= await account.authorizationClient.authorizeScopes(_scopes);
      
      final String? token = authz.accessToken;
      if (token == null) return null;
      
      return GoogleAuthenticatedClient(token);
    } catch (e) {
      print('Error getting authenticated client: $e');
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
        maxResults: 10,
        orderBy: 'startTime',
        singleEvents: true,
      );

      return events.items ?? [];
    } catch (e) {
      print('Error fetching events: $e');
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
      print('Error fetching emails: $e');
      return [];
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
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
