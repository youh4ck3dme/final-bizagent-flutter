import 'package:flutter/material.dart';
import '../../../../core/ui/biz_theme.dart';

class BizStatsCard extends StatelessWidget {
  final String title;
  final String metric;
  final IconData icon;
  final Color? color;
  final String? trend;
  final bool isPositive;

  const BizStatsCard({
    super.key,
    required this.title,
    required this.metric,
    required this.icon,
    this.color,
    this.trend,
    this.isPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = color ?? theme.colorScheme.primary;

    return Card(
      child: Semantics(
        label: '$title: $metric${trend != null ? ', trend $trend' : ''}',
        container: true,
        child: Padding(
          padding: const EdgeInsets.all(BizTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: primaryColor),
                  if (trend != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isPositive ? BizTheme.successGreen : BizTheme.errorRed).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(BizTheme.radiusSm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                            size: 12,
                            color: isPositive ? BizTheme.successGreen : BizTheme.errorRed,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            trend!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isPositive ? BizTheme.successGreen : BizTheme.errorRed,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: BizTheme.spacingSm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metric,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
