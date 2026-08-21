import 'package:flutter_test/flutter_test.dart';
import 'package:alarm_frontend/models/habit_insight_model.dart';

void main() {
  group('HabitDay', () {
    test('fromJson should parse correctly with valid data', () {
      final json = {
        'date': '2026-08-20',
        'actual_buffer_minutes': 15.5,
        'ai_buffer_minutes': 20.0,
        'difference_minutes': 4.5,
        'snooze_count': 2,
        'success': 1,
      };

      final day = HabitDay.fromJson(json);
      expect(day.date, '2026-08-20');
      expect(day.actualBufferMinutes, 15.5);
      expect(day.aiBufferMinutes, 20.0);
      expect(day.differenceMinutes, 4.5);
      expect(day.snoozeCount, 2);
      expect(day.success, 1);
    });

    test('fromJson should handle missing fields gracefully', () {
      final json = <String, dynamic>{};
      final day = HabitDay.fromJson(json);

      expect(day.date, isNull);
      expect(day.actualBufferMinutes, 0.0);
      expect(day.aiBufferMinutes, 0.0);
      expect(day.differenceMinutes, 0.0);
      expect(day.snoozeCount, 0);
      expect(day.success, 0);
    });

    test('fromJson should handle type conversion (int to double)', () {
      final json = {
        'actual_buffer_minutes': 15,
        'ai_buffer_minutes': 20,
      };

      final day = HabitDay.fromJson(json);
      expect(day.actualBufferMinutes, 15.0);
      expect(day.aiBufferMinutes, 20.0);
    });
  });

  group('HabitInsightModel', () {
    test('fromJson should parse correctly with valid data', () {
      final json = {
        'available': true,
        'sample_count': 10,
        'average_actual_buffer': 12.5,
        'average_ai_buffer': 15.0,
        'average_error_minutes': 2.5,
        'average_snooze': 1.5,
        'success_rate': 0.85,
        'trend': 'improving',
        'message': 'Good job',
        'daily': [
          {
            'date': '2026-08-19',
            'actual_buffer_minutes': 10.0,
            'ai_buffer_minutes': 10.0,
            'difference_minutes': 0.0,
            'snooze_count': 0,
            'success': 1,
          }
        ]
      };

      final model = HabitInsightModel.fromJson(json);
      expect(model.available, isTrue);
      expect(model.sampleCount, 10);
      expect(model.averageActualBuffer, 12.5);
      expect(model.averageAiBuffer, 15.0);
      expect(model.averageErrorMinutes, 2.5);
      expect(model.averageSnooze, 1.5);
      expect(model.successRate, 0.85);
      expect(model.trend, 'improving');
      expect(model.message, 'Good job');
      expect(model.daily.length, 1);
      expect(model.daily.first.date, '2026-08-19');
    });

    test('fromJson should handle missing fields and empty lists', () {
      final json = <String, dynamic>{};
      final model = HabitInsightModel.fromJson(json);

      expect(model.available, isFalse);
      expect(model.sampleCount, 0);
      expect(model.averageActualBuffer, isNull);
      expect(model.trend, 'not_enough_data');
      expect(model.daily, isEmpty);
    });
  });
}
