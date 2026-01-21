import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/shared/widgets/biz_widgets.dart';

void main() {
  group('BizStatsCard Widget Test', () {
    testWidgets('BizStatsCard displays metric and icon', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: BizStatsCard(
            title: 'Tržby',
            metric: '12 500 €',
            icon: Icons.attach_money,
          ),
        ),
      ));

      expect(find.text('Tržby'), findsOneWidget);
      expect(find.text('12 500 €'), findsOneWidget);
      expect(find.byIcon(Icons.attach_money), findsOneWidget);
    });

    testWidgets('BizStatsCard displays positive trend correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: BizStatsCard(
            title: 'Zisk',
            metric: '5 000 €',
            icon: Icons.trending_up,
            trend: '+15%',
            isPositive: true,
          ),
        ),
      ));

      expect(find.text('+15%'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    });

    testWidgets('BizStatsCard displays negative trend correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: BizStatsCard(
            title: 'Náklady',
            metric: '2 000 €',
            icon: Icons.trending_down,
            trend: '-5%',
            isPositive: false,
          ),
        ),
      ));

      expect(find.text('-5%'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    });
  });
}
