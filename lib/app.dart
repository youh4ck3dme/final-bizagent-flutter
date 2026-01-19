import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/ui/biz_theme.dart';
import 'core/providers/theme_provider.dart';
import 'core/router/app_router.dart';

import 'core/i18n/l10n.dart';

import 'shared/widgets/offline_banner.dart';
import 'core/services/review_service.dart';
import 'features/notifications/services/notification_service.dart';
import 'features/notifications/services/notification_scheduler.dart';

class BizAgentApp extends ConsumerWidget {
  const BizAgentApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

    // Initialize Review Monitoring
    ref.read(reviewServiceProvider).monitorMilestones();

    // Initialize Notifications
    ref.read(notificationServiceProvider).init().then((_) {
      ref.read(notificationServiceProvider).requestPermissions();
      ref.read(notificationSchedulerProvider).scheduleAllAlerts();
    });

    return L10n(
      locale: AppLocale.sk,
      child: MaterialApp.router(
        title: 'BizAgent',
        localizationsDelegates: const [
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        debugShowCheckedModeBanner: false,
        theme: BizTheme.light(),
        darkTheme: BizTheme.dark(),
        themeMode: themeMode,
        routerConfig: router,
        builder: (context, child) {
          return Column(
            children: [
              const OfflineBanner(),
              if (child != null) Expanded(child: child),
            ],
          );
        },
      ),
    );
  }
}
