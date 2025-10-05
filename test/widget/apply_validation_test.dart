import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_project_final/screens/apply_stepper.dart';

void main() {
  group('ApplyStepper Validation Tests', () {
    testWidgets('shows validation errors when fields are empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ApplyStepper(userId: 'test-user'),
        ),
      );

      // Find the Next button and tap it without filling fields
      final nextButton = find.text('Next');
      expect(nextButton, findsOneWidget);
      
      await tester.tap(nextButton);
      await tester.pump();

      // Should show validation error for amount field
      expect(find.text('Enter amount'), findsOneWidget);
    });

    testWidgets('does not proceed when validation fails', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ApplyStepper(userId: 'test-user'),
        ),
      );

      // Fill only amount field, leave term empty
      await tester.enterText(find.byType(TextFormField).first, '1000');
      
      final nextButton = find.text('Next');
      await tester.tap(nextButton);
      await tester.pump();

      // Should show validation error for term field
      expect(find.text('Enter term'), findsOneWidget);
      
      // Should still be on step 0 (Details)
      expect(find.text('Details'), findsOneWidget);
    });

    testWidgets('proceeds to next step when validation passes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ApplyStepper(userId: 'test-user'),
        ),
      );

      // Fill both required fields
      await tester.enterText(find.byType(TextFormField).first, '1000');
      await tester.enterText(find.byType(TextFormField).at(1), '12');
      
      final nextButton = find.text('Next');
      await tester.tap(nextButton);
      await tester.pump();

      // Should proceed to Review step
      expect(find.text('Review'), findsOneWidget);
      expect(find.text('Review your loan'), findsOneWidget);
    });
  });
}

