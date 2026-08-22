import 'package:flutter_test/flutter_test.dart';
import 'package:alarm_frontend/models/sleep_insight_model.dart';

void main() {
  group('SleepDay', () {
    test('fromJson should parse correctly', () {
      final json = {
        'date': '2026-08-20',
        'hours': 7.5,
        'score': 85.0,
        'awakenings': 1,
      };

      final day = SleepDay.fromJson(json);
      expect(day.date, '2026-08-20');
      expect(day.hours, 7.5);
      expect(day.score, 85.0);
      expect(day.awakenings, 1);
    });

    test('fromJson should fallback on missing fields', () {
      final day = SleepDay.fromJson(const {});
      expect(day.date, isNull);
      expect(day.hours, 0.0);
      expect(day.score, 0.0);
      expect(day.awakenings, 0);
    });
  });

  group('SleepInsightModel', () {
    test('fromJson should parse correctly with valid data', () {
      final json = {
        'available': true,
        'session_count': 5,
        'average_sleep_hours': 7.0,
        'total_sleep_hours': 35.0,
        'average_sleep_score': 80.0,
        'average_awakenings': 1.2,
        'trend': 'stable',
        'message': 'Good sleep',
        'daily': [
          {
            'date': '2026-08-19',
            'hours': 7.0,
            'score': 80.0,
            'awakenings': 1,
          }
        ]
      };

      final model = SleepInsightModel.fromJson(json);
      expect(model.available, isTrue);
      expect(model.sessionCount, 5);
      expect(model.averageSleepHours, 7.0);
      expect(model.totalSleepHours, 35.0);
      expect(model.averageSleepScore, 80.0);
      expect(model.averageAwakenings, 1.2);
      expect(model.trend, 'stable');
      expect(model.message, 'Good sleep');
      expect(model.daily.length, 1);
      expect(model.daily.first.hours, 7.0);
    });

    test('fromJson should fallback on missing fields', () {
      final json = <String, dynamic>{};
      final model = SleepInsightModel.fromJson(json);

      expect(model.available, isFalse);
      expect(model.sessionCount, 0);
      expect(model.averageSleepHours, isNull);
      expect(model.totalSleepHours, 0.0);
      expect(model.trend, 'not_enough_data');
      expect(model.daily, isEmpty);
    });
  });
}
