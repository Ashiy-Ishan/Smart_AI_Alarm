import 'package:flutter_test/flutter_test.dart';
import 'package:alarm_frontend/models/alarm_model.dart';

void main() {
  group('AlarmModel', () {
    test('should initialize with correct properties', () {
      const model = AlarmModel(
        title: 'Morning Run',
        time: '06:00 AM',
        date: 'Mon, Tue, Wed',
      );

      expect(model.title, 'Morning Run');
      expect(model.time, '06:00 AM');
      expect(model.date, 'Mon, Tue, Wed');
    });

    test('should allow empty strings', () {
      const model = AlarmModel(
        title: '',
        time: '',
        date: '',
      );

      expect(model.title, '');
      expect(model.time, '');
      expect(model.date, '');
    });
  });
}
