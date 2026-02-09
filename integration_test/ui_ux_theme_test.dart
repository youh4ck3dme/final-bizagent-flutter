import 'package:bizagent/core/ui/biz_theme.dart';
import 'package:bizagent/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('UI/UX Theme Verification (Blue Magic)', () {
    testWidgets('App should verify Dark Mode colors are correctly applied', (
      tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();

      // 1. Verify Scaffold Background (Deep Space)
      final scaffoldFinder = find.byType(Scaffold).first;
      final Scaffold scaffold = tester.widget(scaffoldFinder);

      // Check if background color matches Blue Magic Deep Space (#0A0D14)
      final backgroundColor = scaffold.backgroundColor;
      expect(
        backgroundColor,
        const Color(0xFF0A0D14),
        reason: 'Scaffold background should be Deep Space (#0A0D14)',
      );

      // 2. Verify Primary Color (Neon Blue)
      final theme = Theme.of(tester.element(scaffoldFinder));
      expect(
        theme.primaryColor,
        const Color(0xFF00B4D8),
        reason: 'Primary color should be Neon Blue (#00B4D8)',
      );

      // 3. Verify Card Color (Midnight Blue)
      // We need to navigate or find a card. Assuming Dashboard has cards.
      // If intro screen is shown, we might check buttons mainly.

      // Let's verify Elevated Button Color (Neon Blue or Gradient)
      final buttonFinder = find.byType(ElevatedButton).first;
      if (buttonFinder.evaluate().isNotEmpty) {
        final ElevatedButton button = tester.widget(buttonFinder);
        final style = button.style;
        final bg = style?.backgroundColor?.resolve({});

        // It might be using primary color
        expect(
          bg,
          const Color(0xFF00B4D8),
          reason: 'ElevatedButton background should be Neon Blue',
        );
      }

      // 4. Verify Text Color (Pure White on Dark)
      final textFinder = find
          .text('Vitajte v BizAgent')
          .first; // Adjust text based on actual UI
      if (textFinder.evaluate().isNotEmpty) {
        final Text textWidget = tester.widget(textFinder);
        expect(
          textWidget.style?.color,
          const Color(0xFFFFFFFF),
          reason: 'Headline text should be Pure White (#FFFFFF)',
        );
      }
    });
  });
}
