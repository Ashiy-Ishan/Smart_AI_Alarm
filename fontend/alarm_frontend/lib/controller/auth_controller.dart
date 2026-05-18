import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';

class AuthController {
  static Future<User?> signInWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize();
      final googleUser = await googleSignIn.authenticate();

      final googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
       idToken: googleAuth.idToken,
       
      );

final userCredential= await FirebaseAuth.instance.signInWithCredential(credential);
return userCredential.user;
      
    } catch (e) {
      Logger().e(e);
    return null;
    }
  }
}
