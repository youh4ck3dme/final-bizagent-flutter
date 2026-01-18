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
      expect(find.text('BizAgent'), findsOneWidget);
      
      // Check subtitle
      expect(find.textContaining('AI Business Assistant'), findsOneWidget);

      // Check for LinearProgressIndicator
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Check for logo (SvgPicture)
      // Note: In tests SvgPicture might render as a limited widget but we check it's in the tree
      expect(find.bySemanticsLabel('BizAgent logo'), findsOneWidget);
      
      // Check for version info
      expect(find.text('v1.0.0'), findsOneWidget);

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
