import 'package:flutter_test/flutter_test.dart';
import 'package:alarm_frontend/utils/validators.dart';

void main() {
  group('Validators Unit Tests', () {
    test('isValidGmail should return true for valid gmail', () {
      expect(Validators.isValidGmail('test@gmail.com'), true);
    });

    test('isValidGmail should return false for invalid emails', () {
      expect(Validators.isValidGmail('test@yahoo.com'), false);
      expect(Validators.isValidGmail('test@gmail'), false);
      expect(Validators.isValidGmail('test'), false);
    });

    test('validateRequired should return error message if empty', () {
      expect(Validators.validateRequired('', 'Name'), 'Name is required');
      expect(Validators.validateRequired(null, 'Name'), 'Name is required');
    });

    test('validateRequired should return null if not empty', () {
      expect(Validators.validateRequired('John Doe', 'Name'), null);
    });

    test('validateConfirmPassword should return error if not matching', () {
      expect(Validators.validateConfirmPassword('pass123', 'pass456'), 'Passwords do not match');
    });

    test('validateConfirmPassword should return null if matching', () {
      expect(Validators.validateConfirmPassword('pass123', 'pass123'), null);
    });
  });
}
