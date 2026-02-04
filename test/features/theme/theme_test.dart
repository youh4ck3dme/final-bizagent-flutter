import 'package:bizagent/core/ui/biz_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  testWidgets('Theme Verification: Blue Magic Colors (Widget Test)', (
    WidgetTester tester,
  ) async {
    // Wrap test in a MaterialApp with the dark theme
    await tester.pumpWidget(
      MaterialApp(
        theme: BizTheme.light(),
        darkTheme: BizTheme.dark(),
        themeMode: ThemeMode.dark, // Force Dark Mode
        home: Scaffold(
          body: Center(
            child: Column(
              children: [
                ElevatedButton(onPressed: () {}, child: Text('Elevated')),
                Text(
                  'Headline',
                  style: GoogleFonts.roboto(fontSize: 57, color: Colors.white),
                ), // Mocking style usage
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verify Scaffold Background (Deep Space #0A0D14)
    final context = tester.element(find.byType(Scaffold));
    final theme = Theme.of(context);
    expect(
      theme.scaffoldBackgroundColor.value,
      0xFF0A0D14,
      reason: 'Scaffold background should be Deep Space',
    );

    // 2. Verify ColorScheme Primary (Neon Blue #00B4D8)
    expect(
      theme.colorScheme.primary.value,
      0xFF00B4D8,
      reason: 'Primary color should be Neon Blue',
    );

    // 3. Verify Elevated Button Color (Neon Blue)
    // Note: ElevatedButton uses primary color in BizTheme
    // We check the button's style if possible, or assume Theme data is enough.
    expect(
      theme.elevatedButtonTheme.style?.backgroundColor?.resolve({})?.value,
      0xFF00B4D8,
      reason: 'ElevatedButton default background should be Neon Blue',
    );

    // 4. Verify Secondary/Error Colors
    expect(
      theme.colorScheme.secondary.value,
      0xFFEE1C25,
      reason: 'Secondary (Accent) color should be Crimson Glow',
    );

    expect(
      theme.colorScheme.error.value,
      0xFFFF6B6B,
      reason: 'Error color should be correct',
    );

    debugPrint('✅ Blue Magic Theme Verified Successfully in Widget Test');
  });
}
