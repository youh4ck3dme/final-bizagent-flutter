import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/features/documents/widgets/markdown_toolbar.dart';

void main() {
  testWidgets('MarkdownToolbar inserts bold text correctly', (
    WidgetTester tester,
  ) async {
    final controller = TextEditingController(text: 'Hello');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownToolbar(controller: controller, onStateChanged: () {}),
        ),
      ),
    );

    // Select text 'Hello'
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);

    // Tap Bold button
    await tester.tap(find.byIcon(Icons.format_bold));
    await tester.pump();

    expect(controller.text, '**Hello**');
  });

  testWidgets('MarkdownToolbar inserts list item correctly', (
    WidgetTester tester,
  ) async {
    final controller = TextEditingController(text: 'Item 1');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MarkdownToolbar(controller: controller, onStateChanged: () {}),
        ),
      ),
    );

    // Cursor at end
    controller.selection = const TextSelection.collapsed(offset: 6);

    // Tap List button
    await tester.tap(find.byIcon(Icons.list));
    await tester.pump();

    expect(controller.text, '- Item 1');
  });
}
