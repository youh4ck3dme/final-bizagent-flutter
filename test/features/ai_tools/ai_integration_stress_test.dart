import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:bizagent/features/ai_tools/screens/biz_bot_screen.dart';
import 'package:bizagent/features/ai_tools/services/biz_bot_service.dart';
import 'package:bizagent/features/invoices/providers/invoices_provider.dart';
import 'package:bizagent/features/invoices/models/invoice_model.dart';

import 'screens/biz_bot_screen_test.mocks.dart';

void main() {
  late MockBizBotService mockBizBotService;

  setUp(() {
    mockBizBotService = MockBizBotService();
  });

  // Pomocná funkcia na vytvorenie fiktívnych faktúr
  List<InvoiceModel> generateInvoices(int count) {
    return List.generate(
      count,
      (index) => InvoiceModel(
        id: 'inv_$index',
        userId: 'test_user',
        createdAt: DateTime.now(),
        number: '2026/${index.toString().padLeft(3, '0')}',
        dateIssued: DateTime.now().subtract(Duration(days: index)),
        dateDue: DateTime.now().add(const Duration(days: 14)),
        clientName: 'Klient $index',
        totalAmount: (index + 1) * 100.0,
        items: [],
        status: InvoiceStatus.paid,
      ),
    );
  }

  Widget createWidgetWithLoad(List<InvoiceModel> invoices) {
    return ProviderScope(
      overrides: [
        bizBotServiceProvider.overrideWithValue(mockBizBotService),
        invoicesProvider.overrideWith((ref) => Stream.value(invoices)),
      ],
      child: const MaterialApp(home: BizBotScreen()),
    );
  }

  testWidgets('STRESS TEST: BizBot handles massive data context', (
    WidgetTester tester,
  ) async {
    final massiveData = generateInvoices(100);

    when(mockBizBotService.ask(any)).thenAnswer(
      (_) async =>
          'Analyzoval som vašich 100 faktúr. Celková suma je obrovská.',
    );

    await tester.pumpWidget(createWidgetWithLoad(massiveData));
    await tester.pumpAndSettle();

    // Vyvolanie AI akcie
    await tester.enterText(
      find.byKey(const Key('bizbot_input')),
      'Analyzuj moju celkovú bilanciu',
    );
    await tester.tap(find.byKey(const Key('bizbot_send_btn')));

    await tester.pumpAndSettle();

    expect(find.textContaining('100 faktúr'), findsOneWidget);
    verify(mockBizBotService.ask(any)).called(1);
  });

  testWidgets('LONG CONVERSATION: BizBot handles sequence of 10 messages', (
    WidgetTester tester,
  ) async {
    var responseCount = 0;
    // We use a Future.delayed to simulate real async gap and ensure pumpAndSettle works
    when(mockBizBotService.ask(any)).thenAnswer((_) async {
      await Future.delayed(const Duration(milliseconds: 10));
      responseCount++;
      return 'Odpoveď č. $responseCount';
    });

    await tester.pumpWidget(createWidgetWithLoad([]));
    await tester.pumpAndSettle();

    for (var i = 1; i <= 10; i++) {
      await tester.enterText(
        find.byKey(const Key('bizbot_input')),
        'Otázka č. $i',
      );
      await tester.tap(find.byKey(const Key('bizbot_send_btn')));

      // Wait for the async call and the state update
      await tester.pump(); // Starts loading
      await tester.pumpAndSettle(); // Completes processing and animations

      expect(find.text('Odpoveď č. $i'), findsOneWidget);
    }

    expect(responseCount, 10);
  });
}
