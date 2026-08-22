import 'package:flutter_test/flutter_test.dart';

// Helper to test logic present in HomeScreen/MainScreen
String getHiddenUid(String email) {
  String prefix = email.split('@').first.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
  String hash = email.hashCode.abs().toString();
  String suffix = hash.length > 4 ? hash.substring(hash.length - 4) : hash.padLeft(4, '0');
  return "user_${prefix}_$suffix";
}

void main() {
  group('UID Generation Logic Tests', () {
    test('Should generate valid UID from simple email', () {
      final email = "john.doe@gmail.com";
      final uid = getHiddenUid(email);
      
      expect(uid.startsWith("user_johndoe_"), true);
      expect(uid.length, greaterThan(10));
    });

    test('Should be deterministic for same email', () {
      final email = "test@example.com";
      expect(getHiddenUid(email), getHiddenUid(email));
    });

    test('Should handle special characters in email prefix', () {
      final email = "user+extra@domain.com";
      final uid = getHiddenUid(email);
      expect(uid.contains("+"), false);
      expect(uid.startsWith("user_userextra_"), true);
    });

    test('Should lowercase all prefixes', () {
      final email = "AliceBob@Work.com";
      final uid = getHiddenUid(email);
      expect(uid.contains("Alice"), false);
      expect(uid.startsWith("user_alicebob_"), true);
    });

    test('Should handle short email prefixes and pad hash if necessary', () {
      final email = "a@b.com";
      final uid = getHiddenUid(email);
      expect(uid.startsWith("user_a_"), true);
      expect(uid.length, greaterThan(6));
    });

  });
}
