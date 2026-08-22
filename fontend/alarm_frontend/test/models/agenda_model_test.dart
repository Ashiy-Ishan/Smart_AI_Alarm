import 'package:flutter_test/flutter_test.dart';
import 'package:alarm_frontend/models/agenda_model.dart';

void main() {
  group('AgendaModel Tests', () {
    test('AgendaModel should store standard values correctly', () {
      final now = DateTime.now();
      final agenda = AgendaModel(
        id: '123',
        time: '09:30',
        endTime: '10:30',
        title: 'Morning Sync',
        subtitle: 'Conference Room 1',
        source: AgendaSource.googleCalendar,
        dateTime: now,
      );

      expect(agenda.time, '09:30');
      expect(agenda.title, 'Morning Sync');
      expect(agenda.source, AgendaSource.googleCalendar);
      expect(agenda.isUpdated, false);
    });

    test('AgendaModel should store update-related values correctly', () {
      final now = DateTime.now();
      final agenda = AgendaModel(
        id: '456',
        time: '10:30',
        endTime: '11:30',
        title: 'Rescheduled Meeting',
        subtitle: 'Zoom',
        isUpdated: true,
        source: AgendaSource.gmail,
        dateTime: now,
        originalTime: '09:00',
        dateLabel: 'Monday, Nov 12',
      );

      expect(agenda.time, '10:30');
      expect(agenda.isUpdated, true);
      expect(agenda.originalTime, '09:00');
      expect(agenda.source, AgendaSource.gmail);
    });
  });
}
