// lib/shared/widgets/biz_empty_state.dart
import 'package:flutter/material.dart';
import '../../core/ui/biz_theme.dart';

class BizEmptyState extends StatelessWidget {
  const BizEmptyState({
    super.key,
    required this.title,
    required this.body,
    this.ctaLabel,
    this.onCta,
    this.icon = Icons.inbox_outlined,
  });

  final String title;
  final String body;
  final String? ctaLabel;
  final VoidCallback? onCta;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(BizTheme.pad),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 44),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(body, textAlign: TextAlign.center),
          if (ctaLabel != null && onCta != null) ...[
            const SizedBox(height: 14),
            FilledButton(onPressed: onCta, child: Text(ctaLabel!)),
          ],
        ],
      ),
    );
  }
}
