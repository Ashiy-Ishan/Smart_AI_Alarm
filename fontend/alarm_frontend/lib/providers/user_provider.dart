import 'package:alarm_frontend/controller/auth_controller.dart';
import 'package:alarm_frontend/models/auth_model_user.dart';
import 'package:alarm_frontend/routes/app_routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  AuthUserModel? _user;

  AuthUserModel? get user => _user;
  bool get isAuthenticated => _user != null;

  UserProvider() {
    FirebaseAuth.instance.authStateChanges().listen((User? firebaseUser) {
      if (firebaseUser == null) {
        _user = null;
      } else {
        _user = AuthUserModel(
          email: firebaseUser.email ?? '',
          fullName: firebaseUser.displayName ?? '',
          profileImage: firebaseUser.photoURL ?? '',
        );
      }
      notifyListeners();
    });
  }

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
        email: user.email ?? '',
        fullName: user.displayName ?? '',
        profileImage: user.photoURL ?? '',
      );
      notifyListeners();
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true)
            .pushReplacementNamed(AppRoutes.main);
      }
    }
  }

  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    required BuildContext context,
  }) async {
    try {
      final user = await AuthController.signUpWithEmailAndPassword(email, password, fullName);
      if (user != null) {
        _user = AuthUserModel(
          email: user.email ?? '',
          fullName: user.displayName ?? '',
          profileImage: user.photoURL ?? '',
        );
        notifyListeners();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Sign Up Failed: ${e.toString().split(']').last.trim()}",
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      rethrow;
    }
  }

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      final user = await AuthController.signInWithEmailAndPassword(email, password);
      if (user != null) {
        _user = AuthUserModel(
          email: user.email ?? '',
          fullName: user.displayName ?? '',
          profileImage: user.photoURL ?? '',
        );
        notifyListeners();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Sign In Failed: ${e.toString().split(']').last.trim()}",
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail({
    required String email,
    required BuildContext context,
  }) async {
    try {
      await AuthController.sendPasswordResetEmail(email);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Password reset link sent to your email"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to send reset link: ${e.toString().split(']').last.trim()}",
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      rethrow;
    }
  }

  Future<void> signOut(BuildContext context) async {
    try {
      await AuthController.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Sign out failed: $e")),
        );
      }
    }
  }
}

