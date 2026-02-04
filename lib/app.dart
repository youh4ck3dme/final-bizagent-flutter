import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bizagent/core/ui/biz_theme.dart';
import 'package:bizagent/core/providers/theme_provider.dart';
import 'package:bizagent/core/router/app_router.dart';
import 'package:bizagent/core/i18n/l10n.dart';
import 'package:bizagent/core/services/review_service.dart';
import 'package:bizagent/core/demo_mode/demo_mode_service.dart';
import 'package:bizagent/features/expenses/providers/expenses_provider.dart';
import 'package:bizagent/features/invoices/providers/invoices_provider.dart';
import 'package:bizagent/features/notifications/services/notification_service.dart';
import 'package:bizagent/features/notifications/services/notification_scheduler.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'dart:async';

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
    _configureSharingIntent();
  }

  StreamSubscription? _intentDataStreamSubscription;

  void _configureSharingIntent() {
    if (kIsWeb) return;

    // 1. Listen for intent while app is running
    _intentDataStreamSubscription =
        ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> value) {
        if (value.isNotEmpty) {
          _handleSharedFile(value.first.path);
        }
      },
      onError: (err) {
        debugPrint("getIntentDataStream error: $err");
      },
    );

    // 2. Handle intent when app is launched from cold start
    ReceiveSharingIntent.instance.getInitialMedia().then((
      List<SharedMediaFile> value,
    ) {
      if (value.isNotEmpty) {
        _handleSharedFile(value.first.path);
      }
    });
  }

  void _handleSharedFile(String path) {
    if (path.isEmpty) return;

    // We delay slightly to ensure the router is ready if called immediately on startup
    Future.delayed(const Duration(milliseconds: 500), () {
      // Navigate to Receipt Viewer or Create Expense
      final router = ref.read(routerProvider);
      router.push(
        '/expenses/receipt-viewer',
        extra: {'url': path, 'isLocal': true},
      );
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription?.cancel();
    super.dispose();
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

  Widget _buildAppContent() {
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

  @override
  Widget build(BuildContext context) {
    final demo = DemoModeService.instance;

    return ListenableBuilder(
      listenable: demo,
      builder: (context, _) {
        if (demo.isDemoMode) {
          return ProviderScope(
            overrides: [
              expensesProvider.overrideWith(
                (ref) => Stream.value(demo.getDemoExpenses()),
              ),
              invoicesProvider.overrideWith(
                (ref) => Stream.value(demo.getDemoInvoices()),
              ),
            ],
            child: _buildAppContent(),
          );
        }
        return _buildAppContent();
      },
    );
  }
}
