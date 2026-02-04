import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bizagent/features/proactive/widgets/proactive_alerts_widget.dart';
import 'package:bizagent/features/proactive/providers/proactive_alerts_provider.dart';
import 'package:bizagent/features/proactive/models/proactive_alert_model.dart';

void main() {
  group('ProactiveAlertsWidget', () {
    testWidgets('shows nothing when alerts are empty', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            proactiveAlertsProvider.overrideWith(
              (ref) => const AsyncValue.data([]),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: ProactiveAlertsWidget()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ProactiveAlertsWidget), findsOneWidget);
    });

    testWidgets('shows proactive section when provider has data', (
      tester,
    ) async {
      final alerts = [
        ProactiveAlert(
          id: '1',
          type: ProactiveAlertType.taxStrategist,
          title: 'Daňový stratég',
          body: 'Do konca kvartálu ti chýba €500.',
          icon: Icons.savings_outlined,
          color: Colors.green,
          createdAt: DateTime.now(),
        ),
      ];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            proactiveAlertsProvider.overrideWith(
              (ref) => AsyncValue.data(alerts),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: ProactiveAlertsWidget()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Proaktívny AI účtovník'), findsOneWidget);
      expect(find.text('Daňový stratég'), findsOneWidget);
      expect(find.textContaining('kvartál'), findsOneWidget);
    });
  });
}
