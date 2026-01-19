import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:firebase_analytics/firebase_analytics.dart';

class MockAuthRepository implements AuthRepository {
  @override
  UserModel? get currentUser => null;

  @override
  late final Stream<UserModel?> authStateChanges;

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

class MockFirebaseAnalytics extends Fake implements FirebaseAnalytics {
  @override
  Future<void> logEvent(
      {required String name,
      Map<String, Object?>? parameters,
      AnalyticsCallOptions? callOptions}) async {}
  @override
  Future<void> logAppOpen(
      {Map<String, Object?>? parameters,
      AnalyticsCallOptions? callOptions}) async {}
  @override
  Future<void> logScreenView(
      {String? screenClass,
      String? screenName,
      Map<String, Object?>? parameters,
      AnalyticsCallOptions? callOptions}) async {}
}

void main() {
  final mockAnalytics = MockFirebaseAnalytics();

  group('AppRouter Redirect Tests', () {
    testWidgets('Stays on /splash when auth is loading', (tester) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider
              .overrideWithValue(MockAuthRepository(const Stream.empty())),
          authStateProvider.overrideWith((ref) => const Stream.empty()),
          firebaseAnalyticsProvider.overrideWithValue(mockAnalytics),
          analyticsServiceProvider
              .overrideWithValue(AnalyticsService(mockAnalytics)),
        ],
      );

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
      expect(router.state.uri.path, '/splash');
    });

    testWidgets('Redirects to /onboarding when not seen', (tester) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider
              .overrideWithValue(MockAuthRepository(Stream.value(null))),
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          onboardingProvider.overrideWith((ref) =>
              OnboardingNotifier()..state = const AsyncValue.data(false)),
          firebaseAnalyticsProvider.overrideWithValue(mockAnalytics),
          analyticsServiceProvider
              .overrideWithValue(AnalyticsService(mockAnalytics)),
        ],
      );

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

      await tester.pumpAndSettle();

      final router = container.read(routerProvider);
      expect(router.state.uri.path, '/onboarding');
    });

    testWidgets(
        'Redirects to /login when not authenticated and seen onboarding',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider
              .overrideWithValue(MockAuthRepository(Stream.value(null))),
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          onboardingProvider.overrideWith((ref) =>
              OnboardingNotifier()..state = const AsyncValue.data(true)),
          firebaseAnalyticsProvider.overrideWithValue(mockAnalytics),
          analyticsServiceProvider
              .overrideWithValue(AnalyticsService(mockAnalytics)),
        ],
      );

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
      await tester.pump(const Duration(milliseconds: 100));
      // Use deterministic pump to avoid infinite animation timeout on LoginScreen
      await tester.pump(const Duration(seconds: 2));

      final router = container.read(routerProvider);
      expect(router.state.uri.path, '/login');
    });

    testWidgets('Redirects to /dashboard when authenticated', (tester) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const user = UserModel(id: '123', email: 'test@test.com');
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider
              .overrideWithValue(MockAuthRepository(Stream.value(user))),
          authStateProvider.overrideWith((ref) => Stream.value(user)),
          onboardingProvider.overrideWith((ref) =>
              OnboardingNotifier()..state = const AsyncValue.data(true)),
          invoicesProvider.overrideWith((ref) => Stream.value([])),
          expensesProvider.overrideWith((ref) => Stream.value([])),
          settingsProvider
              .overrideWith((ref) => Stream.value(UserSettingsModel.empty())),
          firebaseAnalyticsProvider.overrideWithValue(mockAnalytics),
          analyticsServiceProvider
              .overrideWithValue(AnalyticsService(mockAnalytics)),
        ],
      );

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
      await tester.pump(const Duration(milliseconds: 100));
      // Use deterministic pump to avoid potential animation timeouts on Dashboard
      await tester.pump(const Duration(seconds: 2));

      final router = container.read(routerProvider);
      expect(router.state.uri.path, '/dashboard');
    });
  });
}
