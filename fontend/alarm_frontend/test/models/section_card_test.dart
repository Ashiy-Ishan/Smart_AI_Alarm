import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alarm_frontend/models/section_card.dart';

void main() {
  group('SectionCard Widget', () {
    testWidgets('should render correctly with title and children', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionCard(
              title: 'Settings',
              children: const [
                Text('Option 1'),
                Text('Option 2'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Option 1'), findsOneWidget);
      expect(find.text('Option 2'), findsOneWidget);
      expect(find.byType(Divider), findsOneWidget); // One divider between two children
    });

    testWidgets('should render correctly without title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionCard(
              children: const [
                Text('Single Item'),
              ],
            ),
          ),
        ),
      );

      // Title should not exist
      expect(find.byType(Text), findsOneWidget); 
      expect(find.text('Single Item'), findsOneWidget);
      expect(find.byType(Divider), findsNothing); // No divider for single child
    });
  });
}
