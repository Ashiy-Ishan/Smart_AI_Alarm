import 'package:flutter_test/flutter_test.dart';

// Helper to test logic present in ScheduleScreen
bool detectMeetingUpdate(String summary, String? description) {
  final combined = "${summary.toLowerCase()} ${description?.toLowerCase() ?? ''}";
  return combined.contains('rescheduled') || 
         combined.contains('updated') || 
         combined.contains('time changed');
}

void main() {
  group('Agenda Update Detection Logic', () {
    test('Should detect update from summary keyword', () {
      expect(detectMeetingUpdate("Updated: Project Sync", null), true);
      expect(detectMeetingUpdate("Rescheduled meeting", "Old time was 9am"), true);
    });

    test('Should detect update from description keyword', () {
      expect(detectMeetingUpdate("Team Lunch", "This has been updated to 1pm"), true);
      expect(detectMeetingUpdate("Interview", "Time changed due to overlap"), true);
    });

    test('Should return false for standard meetings', () {
      expect(detectMeetingUpdate("Product Sync", "Standard weekly sync"), false);
      expect(detectMeetingUpdate("Lunch", null), false);
    });

    test('Should be case insensitive', () {
      expect(detectMeetingUpdate("UPDATED: Sync", null), true);
      expect(detectMeetingUpdate("RESCHEDULED", null), true);
    });
  });
}
