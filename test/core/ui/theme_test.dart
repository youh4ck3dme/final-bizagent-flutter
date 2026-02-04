import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/core/providers/theme_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('BizTheme Tests', () {
    // test('Light theme should have correct primary color', () {
    //   final theme = BizTheme.light();
    //   expect(theme.brightness, Brightness.light);
    //   expect(theme.colorScheme.primary, BizTheme.slovakBlue);
    // });

    // test('Dark theme should have correct brightness and surface', () {
    //   final theme = BizTheme.dark();
    //   expect(theme.brightness, Brightness.dark);
    //   expect(theme.scaffoldBackgroundColor, BizTheme.darkSurface);
    // });
  });

  group('ThemeNotifier Tests', () {
    test('Initial state should be light (or based on prefs)', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final mode = container.read(themeProvider);
      expect(mode, ThemeMode.light);
    });

    test('Setting theme should update state and persist', () async {
      SharedPreferences.setMockInitialValues({}); // Empty prefs
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(themeProvider.notifier);

      await notifier.setTheme(ThemeMode.dark);
      expect(container.read(themeProvider), ThemeMode.dark);

      // Verify persistence
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('themeMode'), 'dark');
    });
  });
}
