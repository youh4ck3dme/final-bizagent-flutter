import 'package:bizagent/app.dart';
import 'package:flutter/material.dart';
import 'package:bizagent/features/splash/screens/splash_screen.dart';
import 'package:bizagent/features/auth/providers/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:bizagent/core/services/local_persistence_service.dart';
import 'package:bizagent/features/limits/usage_limiter.dart';
import 'package:bizagent/core/router/app_router.dart';
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
import 'package:bizagent/features/auth/models/user_model.dart';
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
  void startListening() => print('[MOCK] MonitoringService.startListening bypassed');
  @override
  void stopListening() {}
}

class MockReviewService extends Fake implements ReviewService {
  @override
  void init() => print('[MOCK] ReviewService.init bypassed');
}

class FakeInitializationService extends StateNotifier<InitState> implements InitializationService {
  FakeInitializationService() : super(const InitState(progress: 0.0, message: 'Inicializácia...'));

  @override
  Future<void> initializeApp() async {
    // Artificial delay to allow listeners to register
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      state = state.copyWith(progress: 1.0, message: 'Hotovo!', isCompleted: true);
    }
  }
}

class FakeOnboardingNotifier extends StateNotifier<AsyncValue<bool>> implements OnboardingNotifier {
  FakeOnboardingNotifier() : super(const AsyncValue.loading()) {
    _startup();
  }

  Future<void> _startup() async {
    await Future.delayed(const Duration(milliseconds: 50));
    if (mounted) {
      state = const AsyncValue.data(false);
    }
  }

  @override
  Ref get ref => throw UnimplementedError();

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
    print('[TEST] Initializing test environment...');

    // Use SharedPreferences.setMockInitialValues for testing
    SharedPreferences.setMockInitialValues({});
    final sharedPrefs = await SharedPreferences.getInstance();

    final mockAuth = MockAuthRepository();
    final mockAnalytics = MockFirebaseAnalytics();

    print('[TEST] Pumping BizAgentApp...');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Basic Infrastructure
          sharedPrefsProvider.overrideWithValue(sharedPrefs),
          authRepositoryProvider.overrideWithValue(mockAuth),

          // Analytics & Review
          firebaseAnalyticsProvider.overrideWithValue(mockAnalytics),
          analyticsServiceProvider.overrideWith((ref) => AnalyticsService(mockAnalytics)),
          reviewServiceProvider.overrideWithValue(MockReviewService()),

          // Data Repositories
          invoicesRepositoryProvider.overrideWithValue(MockInvoicesRepository()),
          expensesRepositoryProvider.overrideWithValue(MockExpensesRepository()),
          monitoringServiceProvider.overrideWithValue(MockMonitoringService()),

          // Lifecycle Services
          initializationServiceProvider.overrideWith((ref) => FakeInitializationService()),
          onboardingProvider.overrideWith((ref) => FakeOnboardingNotifier()),

          // Basic mocks for notifications
          notificationServiceProvider.overrideWithValue(NotificationService(plugin: null)),
        ],
        child: const BizAgentApp(),
      ),
    );

    // 1. Handle Splash Screen
    print('[TEST] Settling Splash Screen...');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Wait for the mock initialization to complete and trigger redirect
    int splashRetry = 0;
    while (splashRetry < 15) {
       final hasSplash = find.byType(SplashScreen).evaluate().isNotEmpty;
       final hasLogin = find.byType(FirebaseLoginScreen).evaluate().isNotEmpty;

       if (hasLogin || !hasSplash) {
         print('[TEST] Left Splash Screen (retry $splashRetry).');
         break;
       }

       print('[TEST] Still on Splash Screen... (retry $splashRetry)');
       await tester.pump(const Duration(milliseconds: 500));
       splashRetry++;
    }

    // Nav settled?
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 2. Handle Onboarding Flow
    print('[TEST] Checking for Onboarding...');
    int onboardingRetry = 0;
    while (onboardingRetry < 10) {
       final nextBtn = find.text('Pokračovať');
       final finishBtn = find.text('Začať používať');

       if (finishBtn.evaluate().isNotEmpty) {
          print('[TEST] Final onboarding page reached, clicking Začať používať...');
          await tester.tap(finishBtn);
          await tester.pumpAndSettle(const Duration(seconds: 1));
          break;
       } else if (nextBtn.evaluate().isNotEmpty) {
          print('[TEST] Onboarding page $onboardingRetry, clicking Pokračovať...');
          await tester.tap(nextBtn);
          await tester.pumpAndSettle(const Duration(seconds: 1));
       } else {
          print('[TEST] No onboarding buttons found yet (retry $onboardingRetry).');
          await tester.pump(const Duration(milliseconds: 500));
          if (onboardingRetry > 2 && find.text('BizAgent').evaluate().isNotEmpty) {
             print('[TEST] Found BizAgent logo, skipping onboarding loop.');
             break;
          }
       }
       onboardingRetry++;
    }

    // Final settle after onboarding
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 3. Login Screen verification
    print('[TEST] Looking for Login screen widgets...');
    if (find.text('BizAgent').evaluate().isEmpty) {
       print('[TEST] DIAGNOSTICS: BizAgent not found. Dumping current tree text:');
       for (var t in tester.allWidgets.whereType<Text>()) {
         print('[TEST] - "${t.data}"');
       }
       // CHECK FOR ERROR WIDGETS
       final errorWidgets = find.byType(ErrorWidget).evaluate();
       if (errorWidgets.isNotEmpty) {
          print('[TEST] !!! FOUND ERROR WIDGETS:');
          for (var e in errorWidgets) {
             final error = e.widget as ErrorWidget;
             print('[TEST] ERROR: ${error.message}');
          }
       } else {
          print('[TEST] No error widgets found, just missing text.');
       }
    }

    expect(find.text('BizAgent'), findsWidgets);
    expect(find.text('Pokračovať s Google'), findsOneWidget);

    // 4. Tap Google Sign-In
    print('[TEST] Tapping Google Sign-In...');
    // Wrap in runAsync for web stability
    await tester.runAsync(() async {
       await tester.tap(find.text('Pokračovať s Google'));
    });

    print('[TEST] Waiting for Dashboard transition...');
    await tester.pumpAndSettle(const Duration(seconds: 3));

    int dashRetry = 0;
    while (find.text('Dashboard').evaluate().isEmpty && dashRetry < 20) {
       await tester.pump(const Duration(milliseconds: 500));
       dashRetry++;
    }

    // 5. Final Verification
    print('[TEST] Final Verification...');
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.byIcon(Icons.dashboard), findsWidgets);
    print('[TEST] SUCCESS: Reached Dashboard.');
  });
}
