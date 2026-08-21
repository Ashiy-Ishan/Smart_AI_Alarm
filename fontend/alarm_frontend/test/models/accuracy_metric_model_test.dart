import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alarm_frontend/models/accuracy_metric_model.dart';

void main() {
  group('AccuracyMetricModel', () {
    test('should initialize with correct values', () {
      const model = AccuracyMetricModel(
        icon: Icons.check,
        label: 'Accuracy',
        value: '95%',
      );

      expect(model.icon, Icons.check);
      expect(model.label, 'Accuracy');
      expect(model.value, '95%');
    });

    test('should support equality', () {
      const model1 = AccuracyMetricModel(
        icon: Icons.warning,
        label: 'Error',
        value: '2.5m',
      );

      const model2 = AccuracyMetricModel(
        icon: Icons.warning,
        label: 'Error',
        value: '2.5m',
      );

      // Models are not equitable out of the box unless specified, but we test field equality
      expect(model1.icon, model2.icon);
      expect(model1.label, model2.label);
      expect(model1.value, model2.value);
    });
  });
}
