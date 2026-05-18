import 'package:alarm_frontend/controller/auth_controller.dart';
import 'package:alarm_frontend/models/auth_model_user.dart';
import 'package:alarm_frontend/screens/home_screen.dart';
import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  AuthUserModel? _user;

  AuthUserModel? get user => _user;

  Future<void> signInWithGoogle(BuildContext context) async {
    final user = await AuthController.signInWithGoogle();
    if (user == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to sign in with Google")),
        );
      }
    } else {
      _user = AuthUserModel(
        email: user.email!,
        fullName: user.displayName!,
        profileImage: user.photoURL!,
      );
      notifyListeners();
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    }
  }
}
