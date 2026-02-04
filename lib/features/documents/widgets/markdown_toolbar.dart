import 'package:flutter/material.dart';

class MarkdownToolbar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onStateChanged;

  const MarkdownToolbar({
    super.key,
    required this.controller,
    required this.onStateChanged,
  });

  void _insertText(String prefix, [String suffix = '']) {
    final text = controller.text;
    final selection = controller.selection;
    final start = selection.start;
    final end = selection.end;

    if (start < 0 || end < 0) return;

    final selectedText = text.substring(start, end);
    final newText = text.replaceRange(
      start,
      end,
      '$prefix$selectedText$suffix',
    );

    controller.text = newText;
    controller.selection = TextSelection(
      baseOffset: start + prefix.length,
      extentOffset: start + prefix.length + selectedText.length,
    );

    onStateChanged();
  }

  void _toggleList() {
    final text = controller.text;
    final selection = controller.selection;
    final start = selection.start;

    // Find start of current line
    final lineStart = text.lastIndexOf('\n', start - 1) + 1;

    final newText = text.replaceRange(lineStart, lineStart, '- ');
    controller.text = newText;
    controller.selection = TextSelection.collapsed(offset: selection.start + 2);

    onStateChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: Theme.of(context).cardColor,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          IconButton(
            icon: const Icon(Icons.format_bold),
            tooltip: 'Tučné',
            onPressed: () => _insertText('**', '**'),
          ),
          IconButton(
            icon: const Icon(Icons.format_italic),
            tooltip: 'Kurzíva',
            onPressed: () => _insertText('*', '*'),
          ),
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: 'Zoznam',
            onPressed: _toggleList,
          ),
          IconButton(
            icon: const Icon(Icons.title),
            tooltip: 'Nadpis',
            onPressed: () => _insertText('# '),
          ),
          IconButton(
            icon: const Icon(Icons.code),
            tooltip: 'Kód',
            onPressed: () => _insertText('`', '`'),
          ),
          IconButton(
            icon: const Icon(Icons.check_box_outlined),
            tooltip: 'Úloha',
            onPressed: () => _insertText('- [ ] '),
          ),
        ],
      ),
    );
  }
}
