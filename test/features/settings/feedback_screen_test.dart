import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bizagent/features/settings/screens/feedback_screen.dart';

// Mock Auth Provider if needed, but for feedback we just need it to render
// We will use ProviderOverrides to inject dependencies if necessary.
// For now, FeedbackScreen writes to Firestore, so we might need to mock that?
// Actually, FeedbackScreen uses `FirebaseFirestore.instance` directly in the code I wrote.
// IMPORTANT: I need to update FeedbackScreen to use a provider for Firestore to make it testable,
// OR (simpler for now) just test the UI validation logic which doesn't hit backend yet.
// Wait, the validation check "Select rating" happens BEFORE the async call.
// So I can test the validation UI without mocking Firestore if I don't trigger a valid submit properly?
// No, proper way is to allow mocking.
// But since I cannot easily refactor the whole app now, I will write a test that checks the UI elements
// and verifies the "Validation Error" snackbar appears if I tap submit without stars.

void main() {
  testWidgets('FeedbackScreen requires rating before submission', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: FeedbackScreen())),
    );

    // 1. Verify UI elements
    expect(find.text('Spätná väzba'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget); // Comment field
    expect(find.byType(ElevatedButton), findsOneWidget); // Submit button

    // 2. Tap submit without rating
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump(); // frame

    // 3. Verify Snackbar with error
    expect(
      find.text('Prosím, vyberte hodnotenie (hviezdičky).'),
      findsOneWidget,
    );

    // 4. Tap a star (e.g. 5th star)
    await tester.tap(find.byIcon(Icons.star_outline_rounded).last);
    await tester.pump();

    // Verify it changed to filled star
    expect(find.byIcon(Icons.star_rounded), findsWidgets);
  });
}
