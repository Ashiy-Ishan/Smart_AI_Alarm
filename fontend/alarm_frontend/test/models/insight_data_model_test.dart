import 'package:flutter_test/flutter_test.dart';
import 'package:alarm_frontend/models/insight_data_model.dart';

void main() {
  group('InsightDataModel', () {
    test('fromJson should parse correctly with valid nested data', () {
      final json = {
        'user_id': 'user123',
        'period_days': 14,
        'sleep': {
          'available': true,
          'message': 'Sleep is good',
        },
        'habit': {
          'available': true,
          'sample_count': 5,
          'trend': 'improving',
        },
        'accuracy': {
          'trained': true,
          'sample_count': 20,
        },
      };

      final model = InsightDataModel.fromJson(json);
      expect(model.userId, 'user123');
      expect(model.periodDays, 14);
      
      expect(model.sleep.available, isTrue);
      expect(model.sleep.message, 'Sleep is good');
      
      expect(model.habit.available, isTrue);
      expect(model.habit.trend, 'improving');
      
      expect(model.accuracy.trained, isTrue);
      expect(model.accuracy.sampleCount, 20);
    });

    test('fromJson should handle empty json gracefully', () {
      final json = <String, dynamic>{};
      final model = InsightDataModel.fromJson(json);

      expect(model.userId, '');
      expect(model.periodDays, 7); // Default
      
      expect(model.sleep.available, isFalse);
      expect(model.habit.available, isFalse);
      expect(model.accuracy.trained, isFalse);
    });
  });
}
