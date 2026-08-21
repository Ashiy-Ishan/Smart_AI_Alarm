import 'package:flutter_test/flutter_test.dart';
import 'package:alarm_frontend/models/event_model.dart';

void main() {
  group('EventModel', () {
    test('should initialize with correct required properties', () {
      const model = EventModel(
        time: '09:00 AM',
        title: 'Standup Meeting',
      );

      expect(model.time, '09:00 AM');
      expect(model.title, 'Standup Meeting');
      expect(model.extra, isNull);
      expect(model.rightTime, isNull);
      expect(model.highlight, isFalse);
    });

    test('should allow setting optional properties', () {
      const model = EventModel(
        time: '12:00 PM',
        title: 'Lunch',
        extra: 'Cafe',
        rightTime: '12:30 PM',
        highlight: true,
      );

      expect(model.time, '12:00 PM');
      expect(model.title, 'Lunch');
      expect(model.extra, 'Cafe');
      expect(model.rightTime, '12:30 PM');
      expect(model.highlight, isTrue);
    });
  });
}
