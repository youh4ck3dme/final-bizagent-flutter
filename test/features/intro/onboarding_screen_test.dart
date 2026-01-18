
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/features/intro/screens/onboarding_screen.dart';

void main() {
  testWidgets('OnboardingScreen navigates through slides', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OnboardingScreen(),
      ),
    );

    // Initial Slide: Factoring
    expect(find.text('Rýchla fakturácia'), findsOneWidget);
    expect(find.text('Ďalej'), findsOneWidget);

    // Tap Next
    await tester.tap(find.text('Ďalej'));
    await tester.pumpAndSettle();

    // Second Slide: AI
    expect(find.text('AI Nástroje'), findsOneWidget);
    
    // Tap Next
    await tester.tap(find.text('Ďalej'));
    await tester.pumpAndSettle();

    // Third Slide: Payments
    expect(find.text('Sledujte platby'), findsOneWidget);
    expect(find.text('Začať'), findsOneWidget);
  });
}
