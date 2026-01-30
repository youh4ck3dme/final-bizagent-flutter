import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bizagent/core/ui/biz_theme.dart';
import 'package:bizagent/core/providers/theme_provider.dart';
import 'package:bizagent/core/router/app_router.dart';
import 'package:bizagent/core/i18n/l10n.dart';
import 'package:bizagent/core/services/review_service.dart';
import 'package:bizagent/features/notifications/services/notification_service.dart';
import 'package:bizagent/features/notifications/services/notification_scheduler.dart';

class BizAgentApp extends ConsumerStatefulWidget {
  const BizAgentApp({super.key});

  @override
  ConsumerState<BizAgentApp> createState() => _BizAgentAppState();
}

class _BizAgentAppState extends ConsumerState<BizAgentApp> {
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  void _initializeServices() {
    // Initialize Review Monitoring
    ref.read(reviewServiceProvider).monitorMilestones();

    // Initialize Notifications
    ref.read(notificationServiceProvider).init().then((_) {
      if (!mounted) return;
      ref.read(notificationServiceProvider).requestPermissions();
      ref.read(notificationSchedulerProvider).scheduleAllAlerts();

      // Start Monitoring (Firestore Listener)
      // ref.read(monitoringServiceProvider).notifications(); // Stream is lazy loaded by UI
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

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
          if (child != null) return child;
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
