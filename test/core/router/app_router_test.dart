import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bizagent/core/router/app_router.dart';
import 'package:bizagent/features/auth/providers/auth_repository.dart';
import 'package:bizagent/features/auth/models/user_model.dart';
import 'package:bizagent/features/intro/providers/onboarding_provider.dart';
import 'package:bizagent/features/invoices/providers/invoices_provider.dart';
import 'package:bizagent/features/expenses/providers/expenses_provider.dart';
import 'package:bizagent/features/settings/providers/settings_provider.dart';
import 'package:bizagent/features/settings/models/user_settings_model.dart';
import 'package:bizagent/core/i18n/l10n.dart';

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
  Future<void> signOut() async {}
  @override
  void dispose() {}
}

void main() {
  group('AppRouter Redirect Tests', () {
    testWidgets('Stays on /splash when auth is loading', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(MockAuthRepository(const Stream.empty())),
          authStateProvider.overrideWith((ref) => const Stream.empty()),
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
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(MockAuthRepository(Stream.value(null))),
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          onboardingProvider.overrideWith((ref) => OnboardingNotifier()..state = const AsyncValue.data(false)),
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

    testWidgets('Redirects to /login when not authenticated and seen onboarding', (tester) async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(MockAuthRepository(Stream.value(null))),
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          onboardingProvider.overrideWith((ref) => OnboardingNotifier()..state = const AsyncValue.data(true)),
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
      await tester.pumpAndSettle();

      final router = container.read(routerProvider);
      expect(router.state.uri.path, '/login');
    });

    testWidgets('Redirects to /dashboard when authenticated', (tester) async {
      const user = UserModel(id: '123', email: 'test@test.com');
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(MockAuthRepository(Stream.value(user))),
          authStateProvider.overrideWith((ref) => Stream.value(user)),
          onboardingProvider.overrideWith((ref) => OnboardingNotifier()..state = const AsyncValue.data(true)),
          invoicesProvider.overrideWith((ref) => Stream.value([])),
          expensesProvider.overrideWith((ref) => Stream.value([])),
          settingsProvider.overrideWith((ref) => Stream.value(UserSettingsModel.empty())),
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
      await tester.pumpAndSettle();

      final router = container.read(routerProvider);
      expect(router.state.uri.path, '/dashboard');
    });
  });
}
