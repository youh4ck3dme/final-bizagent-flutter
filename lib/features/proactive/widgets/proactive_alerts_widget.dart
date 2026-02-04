import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/proactive_alert_model.dart';
import '../providers/proactive_alerts_provider.dart';
import '../../../shared/widgets/biz_shimmer.dart';
import '../../../core/ui/biz_theme.dart';

/// Widget "Proaktívny AI účtovník" – prediktívne alerty, daňový stratég.
class ProactiveAlertsWidget extends ConsumerWidget {
  const ProactiveAlertsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(proactiveAlertsProvider);

    return alertsAsync.when(
      data: (alerts) {
        if (alerts.isEmpty) return const SizedBox.shrink();
        final top = alerts.take(3).toList();
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.psychology,
                    color: BizTheme.slovakBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Proaktívny AI účtovník',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: BizTheme.slovakBlue,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...top.map((a) => _ProactiveAlertCard(alert: a)),
            ],
          ),
        );
      },
      loading: () => const _LoadingShimmer(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ProactiveAlertCard extends StatelessWidget {
  final ProactiveAlert alert;

  const _ProactiveAlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: alert.actionRoute != null
              ? () => context.push(alert.actionRoute!)
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: alert.color.withValues(alpha: 0.3),
                width: 1.5,
              ),
              color: alert.color.withValues(alpha: 0.06),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(alert.icon, color: alert.color, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        alert.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    if (alert.amount != null)
                      Text(
                        '€${alert.amount!.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: alert.color,
                            ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(alert.body, style: Theme.of(context).textTheme.bodySmall),
                if (alert.actionLabel != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    alert.actionLabel!,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: BizTheme.slovakBlue,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 24),
      child: BizShimmer.rectangular(height: 120, width: double.infinity),
    );
  }
}
