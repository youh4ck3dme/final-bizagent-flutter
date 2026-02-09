import 'package:bizagent/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:bizagent/features/splash/screens/splash_screen.dart';
import 'package:bizagent/features/auth/providers/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:bizagent/features/limits/usage_limiter.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:bizagent/features/invoices/providers/invoices_repository.dart';
import 'package:bizagent/features/expenses/providers/expenses_repository.dart';
import 'package:bizagent/features/notifications/services/notification_service.dart';
import 'package:bizagent/core/services/monitoring_service.dart';
import 'package:bizagent/core/services/initialization_service.dart';
import 'package:bizagent/core/services/analytics_service.dart';
import 'package:bizagent/core/services/review_service.dart';
import 'package:bizagent/features/intro/providers/onboarding_provider.dart';
import 'package:bizagent/features/invoices/models/invoice_model.dart';
import 'package:bizagent/features/expenses/models/expense_model.dart';
import 'package:bizagent/features/auth/screens/firebase_login_screen.dart'; // Added import

import 'mocks/google_sign_in_mock.dart';
import 'mocks/auth_repository_mock.dart';

// --- Mocks ---

class MockFirebaseAnalytics implements FirebaseAnalytics {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return Future.value();
  }
}

class MockInvoicesRepository extends Fake implements InvoicesRepository {
  @override
  Stream<List<InvoiceModel>> watchInvoices(String userId) => Stream.value([]);
}

class MockExpensesRepository extends Fake implements ExpensesRepository {
  @override
  Stream<List<ExpenseModel>> watchExpenses(String userId) => Stream.value([]);
}

class MockMonitoringService extends Fake implements MonitoringService {
  @override
  void startListening() {
    if (kDebugMode) {
      debugPrint('[MOCK] MonitoringService.startListening bypassed');
    }
  }

  @override
  void stopListening() {}
}

class MockReviewService extends Fake implements ReviewService {
  void init() {
    if (kDebugMode) {
      debugPrint('[MOCK] ReviewService.init bypassed');
    }
  }
}

class FakeInitializationService extends InitializationService {
  @override
  InitState build() => const InitState(progress: 0.0, message: 'Inicializácia...');

  @override
  Future<void> initializeApp() async {
    // Artificial delay to allow listeners to register
    await Future.delayed(const Duration(milliseconds: 100));
    state = state.copyWith(
      progress: 1.0,
      message: 'Hotovo!',
      isCompleted: true,
    );
  }
}

class FakeOnboardingNotifier extends OnboardingNotifier {
  @override
  AsyncValue<bool> build() {
    _startup();
    return const AsyncValue.loading();
  }

  Future<void> _startup() async {
    await Future.delayed(const Duration(milliseconds: 50));
    state = const AsyncValue.data(false);
  }

  @override
  Future<void> completeOnboarding() async {
    state = const AsyncValue.data(true);
  }
}

// --- Test ---

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Hive.initFlutter();
    await initializeDateFormatting('sk', null);
  });

  setUp(() {
    GoogleSignInPlatform.instance = MockGoogleSignIn();
  });

  testWidgets('E2E: Google Sign-In leads to dashboard', (tester) async {
    if (kDebugMode) {
      debugPrint('[TEST] Initializing test environment...');
    }

    // Use SharedPreferences.setMockInitialValues for testing
    SharedPreferences.setMockInitialValues({});
    final sharedPrefs = await SharedPreferences.getInstance();

    final mockAuth = MockAuthRepository();
    final mockAnalytics = MockFirebaseAnalytics();

    if (kDebugMode) {
      debugPrint('[TEST] Pumping BizAgentApp...');
    }
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Basic Infrastructure
          sharedPrefsProvider.overrideWithValue(sharedPrefs),
          authRepositoryProvider.overrideWithValue(mockAuth),

          // Analytics & Review
          firebaseAnalyticsProvider.overrideWithValue(mockAnalytics),
          analyticsServiceProvider.overrideWith(
            (ref) => AnalyticsService(mockAnalytics),
          ),
          reviewServiceProvider.overrideWithValue(MockReviewService()),

          // Data Repositories
          invoicesRepositoryProvider.overrideWithValue(
            MockInvoicesRepository(),
          ),
          expensesRepositoryProvider.overrideWithValue(
            MockExpensesRepository(),
          ),
          monitoringServiceProvider.overrideWithValue(MockMonitoringService()),

          // Lifecycle Services
          initializationServiceProvider.overrideWith(
            () => FakeInitializationService(),
          ),
          onboardingProvider.overrideWith(() => FakeOnboardingNotifier()),

          // Basic mocks for notifications
          notificationServiceProvider.overrideWithValue(
            NotificationService(plugin: null),
          ),
        ],
        child: const BizAgentApp(),
      ),
    );

    // 1. Handle Splash Screen
    if (kDebugMode) {
      debugPrint('[TEST] Settling Splash Screen...');
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Wait for the mock initialization to complete and trigger redirect
    int splashRetry = 0;
    while (splashRetry < 15) {
      final hasSplash = find.byType(SplashScreen).evaluate().isNotEmpty;
      final hasLogin = find.byType(FirebaseLoginScreen).evaluate().isNotEmpty;

      if (hasLogin || !hasSplash) {
        if (kDebugMode) {
          debugPrint('[TEST] Left Splash Screen (retry $splashRetry).');
        }
        break;
      }

      if (kDebugMode) {
        debugPrint('[TEST] Still on Splash Screen... (retry $splashRetry)');
      }
      await tester.pump(const Duration(milliseconds: 500));
      splashRetry++;
    }

    // Nav settled?
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 2. Handle Onboarding Flow
    if (kDebugMode) {
      debugPrint('[TEST] Checking for Onboarding...');
    }
    int onboardingRetry = 0;
    while (onboardingRetry < 10) {
      final nextBtn = find.text('Pokračovať');
      final finishBtn = find.text('Začať používať');

      if (finishBtn.evaluate().isNotEmpty) {
        if (kDebugMode) {
          debugPrint(
            '[TEST] Final onboarding page reached, clicking Začať používať...',
          );
        }
        await tester.tap(finishBtn);
        await tester.pumpAndSettle(const Duration(seconds: 1));
        break;
      } else if (nextBtn.evaluate().isNotEmpty) {
        if (kDebugMode) {
          debugPrint(
            '[TEST] Onboarding page $onboardingRetry, clicking Pokračovať...',
          );
        }
        await tester.tap(nextBtn);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      } else {
        if (kDebugMode) {
          debugPrint(
            '[TEST] No onboarding buttons found yet (retry $onboardingRetry).',
          );
        }
        await tester.pump(const Duration(milliseconds: 500));
        if (onboardingRetry > 2 &&
            find.text('BizAgent').evaluate().isNotEmpty) {
          if (kDebugMode) {
            debugPrint('[TEST] Found BizAgent logo, skipping onboarding loop.');
          }
          break;
        }
      }
      onboardingRetry++;
    }

    // Final settle after onboarding
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 3. Login Screen verification
    if (kDebugMode) {
      debugPrint('[TEST] Looking for Login screen widgets...');
    }
    if (find.text('BizAgent').evaluate().isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[TEST] DIAGNOSTICS: BizAgent not found. Dumping current tree text:',
        );
      }
      for (var t in tester.allWidgets.whereType<Text>()) {
        if (kDebugMode) {
          debugPrint('[TEST] - "${t.data}"');
        }
      }
      // CHECK FOR ERROR WIDGETS
      final errorWidgets = find.byType(ErrorWidget).evaluate();
      if (errorWidgets.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('[TEST] !!! FOUND ERROR WIDGETS:');
        }
        for (var e in errorWidgets) {
          final error = e.widget as ErrorWidget;
          if (kDebugMode) {
            debugPrint('[TEST] ERROR: ${error.message}');
          }
        }
      } else {
        if (kDebugMode) {
          debugPrint('[TEST] No error widgets found, just missing text.');
        }
      }
    }

    expect(find.text('BizAgent'), findsWidgets);
    expect(find.text('Pokračovať s Google'), findsOneWidget);

    // 4. Tap Google Sign-In
    if (kDebugMode) {
      debugPrint('[TEST] Tapping Google Sign-In...');
    }
    // Wrap in runAsync for web stability
    await tester.runAsync(() async {
      await tester.tap(find.text('Pokračovať s Google'));
    });

    if (kDebugMode) {
      debugPrint('[TEST] Waiting for Dashboard transition...');
    }
    await tester.pumpAndSettle(const Duration(seconds: 3));

    int dashRetry = 0;
    while (find.text('Dashboard').evaluate().isEmpty && dashRetry < 20) {
      await tester.pump(const Duration(milliseconds: 500));
      dashRetry++;
    }

    // 5. Final Verification
    if (kDebugMode) {
      debugPrint('[TEST] Final Verification...');
    }
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.byIcon(Icons.dashboard), findsWidgets);
    if (kDebugMode) {
      debugPrint('[TEST] SUCCESS: Reached Dashboard.');
    }
  });
}
