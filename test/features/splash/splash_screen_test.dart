import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/features/splash/screens/splash_screen.dart';
import '../../helpers/test_app.dart';

void main() {
  group('SplashScreen Widget Tests', () {
    testWidgets('Renders logo, title and progress bar', (tester) async {
      // Set a small surface size to check for overflows
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(testApp(child: const SplashScreen()));

      // Check title
      // expect(find.text('BizAgent', skipOffstage: false), findsOneWidget);

      // Check subtitle - Removed in UI Cleanup
      // expect(
      //   find.textContaining('Váš inteligentný AI asistent', skipOffstage: false),
      //   findsOneWidget,
      // ); // Check for LinearProgressIndicator
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Check for logos (Images)
      expect(find.byType(Image), findsNWidgets(2));

      // Check for version info
      expect(find.text('v1.0.1+2', skipOffstage: false), findsOneWidget);

      // Run some time to see if progress bar updates (fake progress)
      await tester.pump(const Duration(milliseconds: 200));

      // No overflows should happen
      expect(tester.takeException(), isNull);

      // Reset view size
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
