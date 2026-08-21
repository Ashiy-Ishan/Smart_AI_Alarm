import 'package:flutter_test/flutter_test.dart';
import 'package:alarm_frontend/models/model_accuracy.dart';

void main() {
  group('ModelAccuracy', () {
    test('fromJson should parse correctly with valid data', () {
      final json = {
        'trained': true,
        'user_id': 'user123',
        'sample_count': 50,
        'accuracy_score': 0.95,
        'mae': 1.2,
        'rmse': 1.5,
        'r2': 0.88,
        'trained_at': '2026-08-20T10:00:00Z',
        'message': 'Success',
      };

      final model = ModelAccuracy.fromJson(json);
      expect(model.trained, isTrue);
      expect(model.userId, 'user123');
      expect(model.sampleCount, 50);
      expect(model.accuracyScore, 0.95);
      expect(model.mae, 1.2);
      expect(model.rmse, 1.5);
      expect(model.r2, 0.88);
      expect(model.trainedAt, DateTime.utc(2026, 8, 20, 10, 0, 0));
      expect(model.message, 'Success');
    });

    test('fromJson should handle missing fields gracefully', () {
      final json = <String, dynamic>{};
      final model = ModelAccuracy.fromJson(json);

      expect(model.trained, isFalse);
      expect(model.userId, isNull);
      expect(model.sampleCount, 0);
      expect(model.accuracyScore, isNull);
      expect(model.trainedAt, isNull);
    });

    test('fromJson should handle invalid date strings gracefully', () {
      final json = {
        'trained_at': 'invalid_date_format',
      };
      
      final model = ModelAccuracy.fromJson(json);
      expect(model.trainedAt, isNull);
    });
  });
}
