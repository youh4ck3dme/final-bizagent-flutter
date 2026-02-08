import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:bizagent/features/dashboard/screens/dashboard_screen.dart';
import 'package:bizagent/core/services/initialization_service.dart';
import 'package:bizagent/features/splash/screens/splash_screen.dart';
import 'package:bizagent/features/invoices/screens/invoices_screen.dart';
import 'package:bizagent/features/expenses/screens/expenses_screen.dart';
import 'package:bizagent/features/expenses/screens/expense_analytics_screen.dart';
import 'package:bizagent/features/expenses/screens/receipt_viewer_screen.dart';
import 'package:bizagent/features/settings/screens/settings_screen.dart';
import 'package:bizagent/features/settings/screens/trash_screen.dart';
import 'package:bizagent/features/settings/screens/feedback_screen.dart';
import 'package:bizagent/features/expenses/screens/expense_detail_screen.dart';
import 'package:bizagent/features/ai_tools/screens/ai_tools_screen.dart';
import 'package:bizagent/features/ai_tools/screens/ai_email_generator_screen.dart';
import 'package:bizagent/features/ai_tools/screens/ai_expense_analysis_screen.dart';
import 'package:bizagent/features/ai_tools/screens/ai_reminder_generator_screen.dart';
import 'package:bizagent/features/ai_tools/screens/biz_bot_screen.dart';
import 'package:bizagent/features/auth/screens/firebase_login_screen.dart';
import 'package:bizagent/features/auth/screens/pin_auth_screen.dart';
import 'package:bizagent/features/auth/providers/auth_repository.dart';
import 'package:bizagent/features/intro/providers/onboarding_provider.dart';
import 'package:bizagent/features/invoices/screens/create_invoice_screen.dart';
import 'package:bizagent/features/invoices/screens/invoice_detail_screen.dart';
import 'package:bizagent/features/invoices/screens/payment_reminders_screen.dart';
import 'package:bizagent/features/invoices/screens/pdf_preview_screen.dart';
import 'package:bizagent/features/tax/screens/cashflow_analytics_screen.dart';
import 'package:bizagent/features/intro/screens/modern_onboarding_screen.dart';
import 'package:bizagent/features/invoices/models/invoice_model.dart';
import 'package:bizagent/features/expenses/models/expense_model.dart';
import 'package:bizagent/features/expenses/screens/create_expense_screen.dart';
import 'package:bizagent/features/expenses/screens/voice_expense_screen.dart';
import 'package:bizagent/features/bank_import/screens/bank_import_screen.dart';
import 'package:bizagent/features/export/screens/export_screen.dart';
import 'package:bizagent/features/export/screens/reports_screen.dart';
import 'package:bizagent/features/legal/screens/terms_and_conditions_screen.dart';
import 'package:bizagent/features/legal/screens/privacy_policy_screen.dart';
import 'package:bizagent/features/tools/screens/ico_lookup_screen.dart';
import 'package:bizagent/features/tools/screens/watched_companies_screen.dart';
import 'package:bizagent/features/receipt_detective/screens/receipt_detective_screen.dart';
import 'package:bizagent/features/documents/screens/notepad_screen.dart';
import 'package:bizagent/features/documents/screens/note_editor_screen.dart';
import 'package:bizagent/features/documents/models/notepad_model.dart';
import 'package:bizagent/shared/widgets/scaffold_with_navbar.dart';
import 'package:bizagent/shared/widgets/biz_auth_required.dart';
import 'package:bizagent/features/notifications/screens/notifications_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {

  // We use ValueNotifier to bridge Riverpod states to GoRouter refreshListenable
  final refreshListenable = ValueNotifier<bool>(false);

  // Listen to changes and notify GoRouter
  ref.listen(authStateProvider, (_, __) => refreshListenable.value = !refreshListenable.value);
  ref.listen(onboardingProvider, (_, __) => refreshListenable.value = !refreshListenable.value);
  ref.listen(initializationServiceProvider, (_, __) => refreshListenable.value = !refreshListenable.value);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: refreshListenable,
    observers: [],
    redirect: (context, state) {
      final path = state.uri.path;
      final authState = ref.read(authStateProvider);
      final onboardingState = ref.read(onboardingProvider);
      final init = ref.read(initializationServiceProvider);

      // 1. Loading states
      if (authState.isLoading || onboardingState.isLoading) {
        if (kDebugMode && path.contains('ico-lookup')) {
          return null;
        }
        return path == '/splash' ? null : '/splash';
      }

      // 1b. Initialization (Force Splash)
      if (!init.isCompleted) {
        if (kDebugMode && path.contains('ico-lookup')) {
          return null;
        }
        return path == '/splash' ? null : '/splash';
      }

      // 2. Auth error
      if (authState.hasError) {
        return path == '/login' ? null : '/login';
      }

      final isLoggedIn = authState.asData?.value != null;
      final seenOnboarding = onboardingState.asData?.value ?? false;

      // 3. Onboarding Flow
      if (!seenOnboarding) {
        if (kDebugMode && path.contains('ico-lookup')) {
          return null;
        }
        return path == '/onboarding' ? null : '/onboarding';
      }

      // 4. Not Logged In
      if (!isLoggedIn) {
        if (path == '/login' ||
            path == '/onboarding' ||
            path.contains('ico-lookup')) {
          return null;
        }
        return '/login';
      }

      // 5. Already Logged In
      if (path == '/login' || path == '/splash' || path == '/onboarding') {
        if (kDebugMode && kIsWeb) {
          return null;
        }
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const FirebaseLoginScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const ModernOnboardingScreen(),
      ),
      GoRoute(
        path: '/create-invoice',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>?;
          return CreateInvoiceScreen(initialData: data);
        },
      ),
      GoRoute(
        path: '/create-expense',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra;
          final String? initialText = extra is String
              ? extra
              : (extra is Map<String, dynamic>
                  ? extra['initialText'] as String?
                  : null);
          final String? sharedImagePath = extra is Map<String, dynamic>
              ? extra['sharedImagePath'] as String?
              : null;
          return CreateExpenseScreen(
            initialText: initialText,
            sharedImagePath: sharedImagePath,
          );
        },
      ),
      GoRoute(
        path: '/voice-expense',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const VoiceExpenseScreen(),
      ),
      GoRoute(
        path: '/bank-import',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BankImportScreen(),
      ),
      GoRoute(
        path: '/receipt-detective',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ReceiptDetectiveScreen(),
      ),
      GoRoute(
        path: '/documents/notepad/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NoteEditorScreen(),
      ),
      GoRoute(
        path: '/documents/notepad/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final note = state.extra as NotepadItemModel;
          return NoteEditorScreen(note: note);
        },
      ),
      GoRoute(
        path: '/analytics',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CashflowAnalyticsScreen(),
      ),
      GoRoute(
        path: '/export',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          return Consumer(
            builder: (context, ref, _) {
              final user = ref.watch(authStateProvider).asData?.value;
              if (user == null) return const BizAuthRequired();
              return ExportScreen(uid: user.id);
            },
          );
        },
        routes: [
          GoRoute(
            path: 'reports',
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => const ReportsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/legal/terms',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const TermsAndConditionsScreen(),
      ),
      GoRoute(
        path: '/legal/privacy',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/invoices',
                builder: (context, state) => const InvoicesScreen(),
                routes: [
                  GoRoute(
                    path: 'detail',
                    builder: (context, state) {
                      final invoice = state.extra as InvoiceModel;
                      return InvoiceDetailScreen(invoice: invoice);
                    },
                  ),
                  GoRoute(
                    path: 'reminders',
                    builder: (context, state) => const PaymentRemindersScreen(),
                  ),
                  GoRoute(
                    path: 'preview',
                    builder: (context, state) {
                      final invoice = state.extra as InvoiceModel;
                      return PdfPreviewScreen(invoice: invoice);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/expenses',
                builder: (context, state) => const ExpensesScreen(),
                routes: [
                  GoRoute(
                    path: 'analytics',
                    builder: (context, state) => const ExpenseAnalyticsScreen(),
                  ),
                  GoRoute(
                    path: 'detail',
                    builder: (context, state) {
                      final expense = state.extra as ExpenseModel;
                      return ExpenseDetailScreen(expense: expense);
                    },
                  ),
                  GoRoute(
                    path: 'receipt-viewer',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final extras = state.extra as Map<String, dynamic>;
                      return ReceiptViewerScreen(
                        imageUrl: extras['url'],
                        isLocal: extras['isLocal'] ?? false,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/documents',
                builder: (context, state) => const NotepadScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ai-tools',
                builder: (context, state) => const AiToolsScreen(),
                routes: [
                  GoRoute(
                    path: 'email-generator',
                    name: 'emailGenerator',
                    builder: (context, state) {
                      final extra = state.extra as Map<String, dynamic>?;
                      return AiEmailGeneratorScreen(
                        initialType: extra?['type'],
                        initialContext: extra?['context'],
                      );
                    },
                  ),
                  GoRoute(
                    path: 'expense-analysis',
                    name: 'expenseAnalysis',
                    builder: (context, state) =>
                        const AiExpenseAnalysisScreen(),
                  ),
                  GoRoute(
                    path: 'reminder-generator',
                    name: 'reminderGenerator',
                    builder: (context, state) =>
                        const AiReminderGeneratorScreen(),
                  ),
                  GoRoute(
                    path: 'ico-lookup/:initialIco?',
                    name: 'icoLookup',
                    builder: (context, state) {
                      final initialIco = state.pathParameters['initialIco'];
                      return IcoLookupScreen(initialIco: initialIco);
                    },
                  ),
                  GoRoute(
                    path: 'biz-bot',
                    name: 'bizBot',
                    builder: (context, state) => const BizBotScreen(),
                  ),
                  GoRoute(
                    path: 'monitoring',
                    name: 'monitoring',
                    builder: (context, state) => const WatchedCompaniesScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'trash',
                    builder: (context, state) => const TrashScreen(),
                  ),
                  GoRoute(
                    path: 'pin-setup',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) =>
                        const PinAuthScreen(initialMode: PinMode.setup),
                  ),
                  GoRoute(
                    path: 'pin-verify',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) =>
                        const PinAuthScreen(initialMode: PinMode.verify),
                  ),
                  GoRoute(
                    path: 'feedback',
                    builder: (context, state) => const FeedbackScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
