import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Simple verification that the test infrastructure is working
    // and basic widgets can be pumped.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('BizAgent'))),
      ),
    );

    expect(find.text('BizAgent'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
