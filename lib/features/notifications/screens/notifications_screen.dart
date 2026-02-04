import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/ui/biz_theme.dart';
import '../../../shared/widgets/biz_empty_state.dart';
import '../providers/notifications_provider.dart';
import '../models/notification_model.dart';
import '../../../shared/utils/biz_snackbar.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikácie'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Označiť všetko ako prečítané',
            onPressed: () {
              ref
                  .read(notificationsControllerProvider.notifier)
                  .markAllAsRead();
              BizSnackbar.showSuccess(
                context,
                'Všetky správy označené ako prečítané',
              );
            },
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: BizEmptyState(
                title: 'Žiadne notifikácie',
                body: 'Všetko máte vybavené! 🎉',
                icon: Icons.notifications_off_outlined,
              ),
            );
          }

          // Group by Date (Today, Yesterday, Older)
          // For simplicity now just list
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationItem(
                notification: notification,
                onTap: () {
                  // Mark as read immediately on tap
                  if (!notification.isRead) {
                    ref
                        .read(notificationsControllerProvider.notifier)
                        .markAsRead(notification.id);
                  }

                  // Handle navigation action if present
                  if (notification.actionUrl != null) {
                    context.push(notification.actionUrl!);
                  }
                },
                onDismissed: () {
                  ref
                      .read(notificationsControllerProvider.notifier)
                      .deleteNotification(notification.id);
                  BizSnackbar.showInfo(context, 'Notifikácia zmazaná');
                },
              ).animate().fade().slideX();
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stack) => Center(child: Text('Chyba: $e')),
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final BizNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const _NotificationItem({
    required this.notification,
    required this.onTap,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color iconColor;
    IconData iconData;

    switch (notification.type) {
      case NotificationType.info:
        iconColor = BizTheme.slovakBlue;
        iconData = Icons.info_outline;
        break;
      case NotificationType.warning:
        iconColor = BizTheme.warningAmber;
        iconData = Icons.warning_amber_rounded;
        break;
      case NotificationType.error:
        iconColor = BizTheme.nationalRed;
        iconData = Icons.error_outline;
        break;
      case NotificationType.success:
        iconColor = BizTheme.successGreen;
        iconData = Icons.check_circle_outline;
        break;
      case NotificationType.aiInsight:
        iconColor = Colors.purple;
        iconData = Icons.auto_awesome;
        break;
    }

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: BizTheme.nationalRed,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDismissed(),
      child: Container(
        color: notification.isRead
            ? null
            : theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: notification.isRead
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: BizTheme.slovakBlue,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withValues(
                            alpha: 0.8,
                          ),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('d.M. HH:mm').format(notification.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
