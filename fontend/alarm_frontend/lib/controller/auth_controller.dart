import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:googleapis/gmail/v1.dart';
import 'package:logger/logger.dart';

class AuthController {
  // Define required scopes for the entire app
  static const List<String> _requiredScopes = [
    CalendarApi.calendarReadonlyScope,
    GmailApi.gmailReadonlyScope,
  ];

  static Future<User?> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn.instance;
      
      // 1. Initialize for v7.0.0+
      await googleSignIn.initialize();
      
      // 2. Authenticate (get identity)
      final googleUser = await googleSignIn.authenticate();

      // 3. Automatically request the required API scopes (Calendar/Gmail)
      // This triggers the combined "Request Access" screen
      await googleUser.authorizationClient.authorizeScopes(_requiredScopes);

      final googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      return userCredential.user;
      
    } catch (e) {
      Logger().e(e);
      return null;
    }
  }

  static Future<User?> signUpWithEmailAndPassword(
      String email, String password, String fullName) async {
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(fullName);
        await userCredential.user!.reload();
      }
      return FirebaseAuth.instance.currentUser;
    } catch (e) {
      Logger().e(e);
      rethrow;
    }
  }

  static Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      Logger().e(e);
      rethrow;
    }
  }

  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } catch (e) {
      Logger().e(e);
      rethrow;
    }
  }

  static Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.signOut();
    } catch (e) {
      Logger().e(e);
    }
  }
}
