import 'package:flutter_test/flutter_test.dart';
import 'package:alarm_frontend/models/auth_model_user.dart';

void main() {
  group('AuthUserModel Unit Tests', () {
    test('toMap should convert model to map correctly', () {
      const user = AuthUserModel(
        fullName: 'John Doe',
        email: 'john@gmail.com',
        profileImage: 'https://example.com/img.png',
      );

      final map = user.toMap();

      expect(map['fullName'], 'John Doe');
      expect(map['email'], 'john@gmail.com');
      expect(map['profileImage'], 'https://example.com/img.png');
    });

    test('fromJson should create model from json correctly', () {
      final json = {
        'fullName': 'Jane Doe',
        'email': 'jane@gmail.com',
        'password': 'password123',
        'confirmPassword': 'password123',
        'profileImage': '',
      };

      final user = AuthUserModel.fromJson(json);

      expect(user.fullName, 'Jane Doe');
      expect(user.email, 'jane@gmail.com');
    });

    test('copyWith should return updated object', () {
      const user = AuthUserModel(fullName: 'Original Name');
      final updated = user.copyWith(fullName: 'Updated Name');

      expect(updated.fullName, 'Updated Name');
      expect(user.fullName, 'Original Name');
    });
  });
}
