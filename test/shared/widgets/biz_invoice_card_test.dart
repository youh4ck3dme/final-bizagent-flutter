import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/semantics.dart';
import 'package:bizagent/shared/widgets/biz_widgets.dart'; // Correct package import

void main() {
  group('BizInvoiceCard Widget Test', () {
    testWidgets('BizInvoiceCard displays correct info', (WidgetTester tester) async {
      final date = DateTime(2025, 12, 31);
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: BizInvoiceCard(
            title: 'Firma XYZ',
            subtitle: 'FA-2025001',
            amount: 150.50,
            date: date,
            status: 'Odoslaná',
            onTap: (){},
          ),
        ),
      ));

      // 1. Verify Texts
      expect(find.text('Firma XYZ'), findsOneWidget);
      expect(find.text('FA-2025001'), findsOneWidget);
      expect(find.textContaining('150,50'), findsOneWidget);

      // 2. Verify Semantics
      final handle = tester.ensureSemantics();
      final semantics = tester.getSemantics(find.byType(BizInvoiceCard));
      expect(semantics.label, contains('Faktúra FA-2025001 pre Firma XYZ'));
      expect(semantics.label, contains('31.12.2025'));
      
      final data = semantics.getSemanticsData();
      expect(data.hasFlag(SemanticsFlag.isButton), true);
      expect(data.hasAction(SemanticsAction.tap), true);
      handle.dispose();
    });
  });
}
