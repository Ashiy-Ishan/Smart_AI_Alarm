import 'package:flutter_test/flutter_test.dart';
import 'package:alarm_frontend/models/agenda_model.dart';

void main() {
  group('AgendaModel Tests', () {
    test('AgendaModel should store values correctly', () {
      const agenda = AgendaModel(
        time: '09:30',
        title: 'Morning Sync',
        subtitle: 'Conference Room 1',
      );

      expect(agenda.time, '09:30');
      expect(agenda.title, 'Morning Sync');
      expect(agenda.subtitle, 'Conference Room 1');
    });

    test('AgendaModel equality check (if applicable)', () {
      const a1 = AgendaModel(time: '10:00', title: 'T1', subtitle: 'S1');
      const a2 = AgendaModel(time: '10:00', title: 'T1', subtitle: 'S1');
      
      // Since it's a simple class without Equatable, we check fields
      expect(a1.title, a2.title);
      expect(a1.time, a2.time);
    });
  });
}
