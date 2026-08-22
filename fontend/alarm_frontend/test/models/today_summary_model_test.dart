import 'package:flutter_test/flutter_test.dart';
import 'package:alarm_frontend/models/today_summary_model.dart';

void main() {
  group('TodayActivityModel', () {
    test('fromJson parses correctly', () {
      final json = {
        'available': true,
        'room_temperature': 24.5,
        'humidity': 50.0,
        'motion_detected': true,
        'light_level': 'bright',
        'motion_events': 3,
        'movement_minutes': 12.5,
        'steps': 5000,
        'calories': 200.0,
        'latest_reading_at': '2026-08-20T10:00:00Z',
        'message': 'Active day',
      };

      final model = TodayActivityModel.fromJson(json);
      expect(model.available, isTrue);
      expect(model.roomTemperature, 24.5);
      expect(model.motionDetected, isTrue);
      expect(model.motionEvents, 3);
      expect(model.latestReadingAt, isNotNull);
      expect(model.message, 'Active day');
    });

    test('fromJson handles fallbacks', () {
      final json = <String, dynamic>{};
      final model = TodayActivityModel.fromJson(json);

      expect(model.available, isFalse);
      expect(model.roomTemperature, isNull);
      expect(model.motionDetected, isFalse);
      expect(model.motionEvents, 0);
      expect(model.movementMinutes, 0.0);
    });
  });

  group('TodaySleepModel', () {
    test('fromJson parses correctly', () {
      final json = {
        'available': true,
        'duration_hours': 8.0,
        'sleep_score': 90.0,
        'awakenings': 1,
        'sleep_start': '2026-08-19T22:00:00Z',
        'sleep_end': '2026-08-20T06:00:00Z',
        'message': 'Good sleep',
      };

      final model = TodaySleepModel.fromJson(json);
      expect(model.available, isTrue);
      expect(model.durationHours, 8.0);
      expect(model.sleepStart, isNotNull);
      expect(model.sleepEnd, isNotNull);
    });

    test('fromJson handles fallbacks', () {
      final model = TodaySleepModel.fromJson(const {});
      expect(model.available, isFalse);
      expect(model.durationHours, isNull);
      expect(model.sleepStart, isNull);
    });
  });

  group('TodayAlarmSummaryModel', () {
    test('fromJson parses correctly', () {
      final json = {
        'completed': 5,
        'snoozes': 2,
        'success_rate': 0.8,
        'average_unlock_delay': 3.5,
      };

      final model = TodayAlarmSummaryModel.fromJson(json);
      expect(model.completed, 5);
      expect(model.snoozes, 2);
      expect(model.successRate, 0.8);
      expect(model.averageUnlockDelay, 3.5);
    });

    test('fromJson handles fallbacks', () {
      final model = TodayAlarmSummaryModel.fromJson(const {});
      expect(model.completed, 0);
      expect(model.snoozes, 0);
      expect(model.successRate, isNull);
      expect(model.averageUnlockDelay, isNull);
    });
  });

  group('TodayAiModel', () {
    test('fromJson parses correctly', () {
      final json = {
        'trained': true,
        'accuracy_score': 0.95,
        'sample_count': 100,
      };

      final model = TodayAiModel.fromJson(json);
      expect(model.trained, isTrue);
      expect(model.accuracyScore, 0.95);
      expect(model.sampleCount, 100);
    });

    test('fromJson handles fallbacks', () {
      final model = TodayAiModel.fromJson(const {});
      expect(model.trained, isFalse);
      expect(model.accuracyScore, isNull);
      expect(model.sampleCount, 0);
    });
  });

  group('TodaySummaryModel', () {
    test('fromJson parses correctly with valid data', () {
      final json = {
        'user_id': 'user123',
        'date': '2026-08-20',
        'generated_at': '2026-08-20T10:00:00Z',
        'activity': {'available': true, 'motion_events': 5},
        'sleep': {'available': true, 'duration_hours': 7.5},
        'alarms': {'completed': 2, 'snoozes': 1},
        'ai': {'trained': true, 'sample_count': 50},
        'health_insight': 'Great day overall!',
      };

      final model = TodaySummaryModel.fromJson(json);
      expect(model.userId, 'user123');
      expect(model.date, '2026-08-20');
      expect(model.generatedAt, isNotNull);
      expect(model.activity.available, isTrue);
      expect(model.sleep.durationHours, 7.5);
      expect(model.alarms.completed, 2);
      expect(model.ai.trained, isTrue);
      expect(model.healthInsight, 'Great day overall!');
    });

    test('fromJson handles empty data gracefully', () {
      final json = <String, dynamic>{};
      final model = TodaySummaryModel.fromJson(json);

      expect(model.userId, '');
      expect(model.date, '');
      expect(model.generatedAt, isNull);
      expect(model.activity.available, isFalse);
      expect(model.sleep.available, isFalse);
      expect(model.alarms.completed, 0);
      expect(model.ai.trained, isFalse);
      expect(model.healthInsight, 'No health insight available yet.');
    });
  });
}
