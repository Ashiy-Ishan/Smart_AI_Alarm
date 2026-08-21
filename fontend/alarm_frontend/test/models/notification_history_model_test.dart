import 'package:flutter_test/flutter_test.dart';
import 'package:alarm_frontend/models/notification_history_model.dart';

void main() {
  group('NotificationHistoryModel', () {
    test('fromJson should parse correctly', () {
      final json = {
        'id': 'msg_1',
        'title': 'AI Buffer',
        'body': 'Your alarm was updated',
        'timestamp': '2026-08-20T10:00:00.000Z',
        'isRead': true,
      };

      final model = NotificationHistoryModel.fromJson(json);
      expect(model.id, 'msg_1');
      expect(model.title, 'AI Buffer');
      expect(model.body, 'Your alarm was updated');
      expect(model.timestamp.isUtc, isTrue);
      expect(model.isRead, isTrue);
    });

    test('fromJson should default isRead to false', () {
      final json = {
        'id': 'msg_2',
        'title': 'Weather Alert',
        'body': 'Rain expected',
        'timestamp': '2026-08-20T11:00:00.000Z',
      };

      final model = NotificationHistoryModel.fromJson(json);
      expect(model.isRead, isFalse);
    });

    test('toJson should serialize correctly', () {
      final model = NotificationHistoryModel(
        id: 'msg_3',
        title: 'Traffic',
        body: 'Heavy traffic',
        timestamp: DateTime.utc(2026, 8, 20, 12, 0, 0),
        isRead: false,
      );

      final json = model.toJson();
      expect(json['id'], 'msg_3');
      expect(json['title'], 'Traffic');
      expect(json['body'], 'Heavy traffic');
      expect(json['timestamp'], '2026-08-20T12:00:00.000Z');
      expect(json['isRead'], isFalse);
    });
  });
}
