import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alarm_frontend/models/email_model.dart';

void main() {
  group('EmailModel', () {
    test('should initialize with provided values', () {
      const model = EmailModel(
        name: 'John Doe',
        time: '10:00 AM',
        preview: 'Are we still meeting?',
        icon: Icons.person,
        isNew: true,
        isUrgent: true,
      );

      expect(model.name, 'John Doe');
      expect(model.time, '10:00 AM');
      expect(model.preview, 'Are we still meeting?');
      expect(model.icon, Icons.person);
      expect(model.isNew, isTrue);
      expect(model.isUrgent, isTrue);
    });

    test('should have correct default boolean values', () {
      const model = EmailModel(
        name: 'Jane Smith',
        time: 'Yesterday',
        preview: 'Status update attached.',
        icon: Icons.email,
      );

      expect(model.isNew, isFalse);
      expect(model.isUrgent, isFalse);
    });

    test('copyWith should update provided fields and retain others', () {
      const original = EmailModel(
        name: 'Boss',
        time: 'Now',
        preview: 'Urgent task',
        icon: Icons.warning,
        isNew: true,
        isUrgent: true,
      );

      final updated = original.copyWith(
        time: '5 mins ago',
        isNew: false,
      );

      expect(updated.name, 'Boss');
      expect(updated.time, '5 mins ago');
      expect(updated.preview, 'Urgent task');
      expect(updated.icon, Icons.warning);
      expect(updated.isNew, isFalse);
      expect(updated.isUrgent, isTrue);
    });
  });
}
