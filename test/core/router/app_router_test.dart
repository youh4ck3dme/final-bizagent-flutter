import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:bizagent/core/router/app_router.dart';
import 'package:bizagent/core/services/analytics_service.dart';
import 'package:bizagent/features/auth/providers/auth_repository.dart';
import 'package:bizagent/features/auth/models/user_model.dart';
import 'package:bizagent/features/intro/providers/onboarding_provider.dart';
import 'package:bizagent/features/invoices/providers/invoices_provider.dart';
import 'package:bizagent/features/expenses/providers/expenses_provider.dart';
import 'package:bizagent/features/settings/providers/settings_provider.dart';
import 'package:bizagent/features/settings/models/user_settings_model.dart';
import 'package:bizagent/core/i18n/l10n.dart';
import 'package:bizagent/core/services/initialization_service.dart';
import 'package:bizagent/firebase_options.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:bizagent/features/notifications/services/notification_service.dart';
import 'package:bizagent/features/tools/services/monitoring_service.dart';
import 'package:bizagent/features/analytics/providers/expense_insights_provider.dart';
import 'package:bizagent/features/analytics/models/expense_insight_model.dart';
import 'dart:async';
import 'package:mocktail/mocktail.dart';
import 'package:bizagent/features/dashboard/providers/revenue_provider.dart';
import 'package:bizagent/features/dashboard/providers/profit_provider.dart';
import 'package:bizagent/features/tax/providers/tax_thermometer_service.dart';
import 'package:bizagent/features/tax/providers/tax_estimation_service.dart';
import 'package:bizagent/features/tax/providers/tax_provider.dart';

class MockAuthRepository implements AuthRepository {
  @override
  UserModel? get currentUser => null;

  @override
  late final Stream<UserModel?> authStateChanges;

  @override
  Future<String?> get currentUserToken async => 'fake-token-123';

  MockAuthRepository(Stream<UserModel?> stream) {
    authStateChanges = stream;
  }

  @override
  Future<UserModel?> signIn(String email, String password) async => null;
  @override
  Future<UserModel?> signUp(String email, String password) async => null;
  @override
  Future<UserModel?> signInWithGoogle() async => null;
  @override
  Future<UserModel?> signInAnonymously() async => null;
  @override
  Future<void> signOut() async {}
  @override
  void dispose() {}
}

class MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

class TestInitializationService extends InitializationService {
  final InitState _initialState;
  TestInitializationService(this._initialState);

  @override
  InitState build() => _initialState;

  @override
  Future<void> initializeApp() async {}
}

class FakeNotificationService extends Fake implements NotificationService {
  @override
  Future<void> init() async {}
  @override
  Future<bool?> requestPermissions() async => true;
  @override
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {}
  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {}
}

class FakeMonitoringService extends Fake implements MonitoringService {
  @override
  Stream<List<Map<String, dynamic>>> notifications() {
    return Stream.value([]);
  }

  @override
  Future<void> markAsRead(String id) async {}

  @override
  Future<void> markAllAsRead() async {}
}


class FakeExpenseInsightsNotifier extends ExpenseInsightsNotifier {
  final List<ExpenseInsight> data;
  FakeExpenseInsightsNotifier({this.data = const []});
  @override
  Future<List<ExpenseInsight>> build() async => data;
}

class FakeOnboardingNotifier extends OnboardingNotifier {
  final bool initialValue;
  FakeOnboardingNotifier({this.initialValue = true});

  @override
  AsyncValue<bool> build() => AsyncValue.data(initialValue);

  @override
  Future<void> completeOnboarding() async {
    state = const AsyncValue.data(true);
  }
}

void main() {
  final mockAnalytics = MockFirebaseAnalytics();
  bool skipLoginRedirect = false;

  setUpAll(() async {
    when(
      () => mockAnalytics.logScreenView(
        screenName: any(named: 'screenName'),
        screenClass: any(named: 'screenClass'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => mockAnalytics.logEvent(
        name: any(named: 'name'),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((_) async {});

    when(() => mockAnalytics.logAppOpen()).thenAnswer((_) async {});

    TestWidgetsFlutterBinding.ensureInitialized();
    if (Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } catch (_) {
        try {
          await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
        } catch (_) {}
      }
    }
    skipLoginRedirect = Firebase.apps.isEmpty;
  });

  group('AppRouter Redirect Tests', () {
    testWidgets('Stays on /splash when auth is loading', (tester) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            MockAuthRepository(const Stream.empty()),
          ),
          authStateProvider.overrideWith((ref) => const Stream.empty()),
          onboardingProvider.overrideWith(() => FakeOnboardingNotifier(initialValue: false)),
          initializationServiceProvider.overrideWith(
            () => TestInitializationService(const InitState(
              progress: 0.5,
              message: 'Načítam...',
              isCompleted: false,
            )),
          ),
          firebaseAnalyticsProvider.overrideWithValue(mockAnalytics),
          analyticsServiceProvider.overrideWithValue(
            AnalyticsService(mockAnalytics),
          ),
          notificationServiceProvider.overrideWithValue(
            FakeNotificationService(),
          ),
          monitoringServiceProvider.overrideWithValue(FakeMonitoringService()),
          expenseInsightsProvider.overrideWith(() => FakeExpenseInsightsNotifier()),
          revenueMetricsProvider.overrideWith(
            (ref) => Future.value(
              RevenueMetrics(
                totalRevenue: 0,
                thisMonthRevenue: 0,
                lastMonthRevenue: 0,
                unpaidAmount: 0,
                overdueCount: 0,
                averageInvoiceValue: 0,
              ),
            ),
          ),
          profitMetricsProvider.overrideWith(
            (ref) => Future.value(
              ProfitMetrics(profit: 0, profitMargin: 0, thisMonthProfit: 0),
            ),
          ),
          taxThermometerProvider.overrideWith(
            (ref) => AsyncValue.data(TaxThermometerResult(currentTurnover: 0)),
          ),
          taxEstimationProvider.overrideWith(
            (ref) => AsyncValue.data(TaxEstimationModel.empty()),
          ),
          upcomingTaxDeadlinesProvider.overrideWith((ref) => []),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: L10n(
            locale: AppLocale.sk,
            child: Consumer(
              builder: (context, ref, _) {
                return MaterialApp.router(
                  routerConfig: ref.watch(routerProvider),
                );
              },
            ),
          ),
        ),
      );

      final router = container.read(routerProvider);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));
      expect(router.state.uri.path, '/splash');

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(Container());
    });

    testWidgets('Redirects to /onboarding when not seen', (tester) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            MockAuthRepository(Stream.value(null)),
          ),
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          onboardingProvider.overrideWith(() => FakeOnboardingNotifier(initialValue: false)),
          initializationServiceProvider.overrideWith(
            () => TestInitializationService(const InitState(
              progress: 1.0,
              message: 'Hotovo!',
              isCompleted: true,
            )),
          ),
          firebaseAnalyticsProvider.overrideWithValue(mockAnalytics),
          analyticsServiceProvider.overrideWithValue(
            AnalyticsService(mockAnalytics),
          ),
          notificationServiceProvider.overrideWithValue(
            FakeNotificationService(),
          ),
          monitoringServiceProvider.overrideWithValue(FakeMonitoringService()),
          expenseInsightsProvider.overrideWith(() => FakeExpenseInsightsNotifier()),
          revenueMetricsProvider.overrideWith(
            (ref) => Future.value(
              RevenueMetrics(
                totalRevenue: 0,
                thisMonthRevenue: 0,
                lastMonthRevenue: 0,
                unpaidAmount: 0,
                overdueCount: 0,
                averageInvoiceValue: 0,
              ),
            ),
          ),
          profitMetricsProvider.overrideWith(
            (ref) => Future.value(
              ProfitMetrics(profit: 0, profitMargin: 0, thisMonthProfit: 0),
            ),
          ),
          taxThermometerProvider.overrideWith(
            (ref) => AsyncValue.data(TaxThermometerResult(currentTurnover: 0)),
          ),
          taxEstimationProvider.overrideWith(
            (ref) => AsyncValue.data(TaxEstimationModel.empty()),
          ),
          upcomingTaxDeadlinesProvider.overrideWith((ref) => []),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: L10n(
            locale: AppLocale.sk,
            child: Consumer(
              builder: (context, ref, _) {
                return MaterialApp.router(
                  routerConfig: ref.watch(routerProvider),
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      final router = container.read(routerProvider);
      expect(router.state.uri.path, '/onboarding');

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(Container());
    });

    testWidgets(
      'Redirects to /login when not authenticated and seen onboarding',
      (tester) async {
        if (skipLoginRedirect) return;
        tester.view.physicalSize = const Size(1000, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              MockAuthRepository(Stream.value(null)),
            ),
            authStateProvider.overrideWith((ref) => Stream.value(null)),
            onboardingProvider.overrideWith(() => FakeOnboardingNotifier(initialValue: true)),
            initializationServiceProvider.overrideWith(
              () => TestInitializationService(const InitState(
                progress: 1.0,
                message: 'Hotovo!',
                isCompleted: true,
              )),
            ),
            firebaseAnalyticsProvider.overrideWithValue(mockAnalytics),
            analyticsServiceProvider.overrideWithValue(
              AnalyticsService(mockAnalytics),
            ),
            notificationServiceProvider.overrideWithValue(
              FakeNotificationService(),
            ),
            monitoringServiceProvider.overrideWithValue(
              FakeMonitoringService(),
            ),
            expenseInsightsProvider.overrideWith(() => FakeExpenseInsightsNotifier()),
            revenueMetricsProvider.overrideWith(
              (ref) => Future.value(
                RevenueMetrics(
                  totalRevenue: 0,
                  thisMonthRevenue: 0,
                  lastMonthRevenue: 0,
                  unpaidAmount: 0,
                  overdueCount: 0,
                  averageInvoiceValue: 0,
                ),
              ),
            ),
            profitMetricsProvider.overrideWith(
              (ref) => Future.value(
                ProfitMetrics(profit: 0, profitMargin: 0, thisMonthProfit: 0),
              ),
            ),
            taxThermometerProvider.overrideWith(
              (ref) =>
                  AsyncValue.data(TaxThermometerResult(currentTurnover: 0)),
            ),
            taxEstimationProvider.overrideWith(
              (ref) => AsyncValue.data(TaxEstimationModel.empty()),
            ),
            upcomingTaxDeadlinesProvider.overrideWith((ref) => []),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: L10n(
              locale: AppLocale.sk,
              child: Consumer(
                builder: (context, ref, _) {
                  return MaterialApp.router(
                    routerConfig: ref.watch(routerProvider),
                  );
                },
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

        final router = container.read(routerProvider);
        expect(router.state.uri.path, '/login');

        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpWidget(Container());
      },
    );

    testWidgets('Redirects to /dashboard when authenticated', (tester) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const user = UserModel(id: '123', email: 'test@test.com');
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            MockAuthRepository(Stream.value(user)),
          ),
          authStateProvider.overrideWith((ref) => Stream.value(user)),
          onboardingProvider.overrideWith(() => FakeOnboardingNotifier(initialValue: true)),
          initializationServiceProvider.overrideWith(
            () => TestInitializationService(const InitState(
              progress: 1.0,
              message: 'Hotovo!',
              isCompleted: true,
            )),
          ),
          invoicesProvider.overrideWith((ref) => Stream.value([])),
          expensesProvider.overrideWith((ref) => Stream.value([])),
          settingsProvider.overrideWith(
            (ref) => Stream.value(UserSettingsModel.empty()),
          ),
          firebaseAnalyticsProvider.overrideWithValue(mockAnalytics),
          analyticsServiceProvider.overrideWithValue(
            AnalyticsService(mockAnalytics),
          ),
          notificationServiceProvider.overrideWithValue(
            FakeNotificationService(),
          ),
          monitoringServiceProvider.overrideWithValue(FakeMonitoringService()),
          expenseInsightsProvider.overrideWith(() => FakeExpenseInsightsNotifier()),
          revenueMetricsProvider.overrideWith(
            (ref) => Future.value(
              RevenueMetrics(
                totalRevenue: 0,
                thisMonthRevenue: 0,
                lastMonthRevenue: 0,
                unpaidAmount: 0,
                overdueCount: 0,
                averageInvoiceValue: 0,
              ),
            ),
          ),
          profitMetricsProvider.overrideWith(
            (ref) => Future.value(
              ProfitMetrics(profit: 0, profitMargin: 0, thisMonthProfit: 0),
            ),
          ),
          taxThermometerProvider.overrideWith(
            (ref) => AsyncValue.data(TaxThermometerResult(currentTurnover: 0)),
          ),
          taxEstimationProvider.overrideWith(
            (ref) => AsyncValue.data(TaxEstimationModel.empty()),
          ),
          upcomingTaxDeadlinesProvider.overrideWith((ref) => []),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: L10n(
            locale: AppLocale.sk,
            child: Consumer(
              builder: (context, ref, _) {
                // Ensure router is created
                ref.watch(routerProvider);
                return MaterialApp.router(
                  routerConfig: ref.watch(routerProvider),
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      final router = container.read(routerProvider);
      expect(router.state.uri.path, '/dashboard');

      await tester.pump(const Duration(seconds: 5));
      await tester.pump();
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
    });
  });
}
