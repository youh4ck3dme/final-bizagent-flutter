import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bizagent/app.dart';
import 'package:bizagent/features/auth/providers/auth_repository.dart';
import 'package:bizagent/features/auth/models/user_model.dart';
import 'package:bizagent/features/intro/providers/onboarding_provider.dart';
import 'package:bizagent/features/invoices/providers/invoices_provider.dart';
import 'package:bizagent/features/expenses/providers/expenses_provider.dart';
import 'package:bizagent/features/settings/providers/settings_provider.dart';
import 'package:bizagent/features/settings/models/user_settings_model.dart';
import 'dart:async';

class MockAuthRepository implements AuthRepository {
  @override
  UserModel? get currentUser => const UserModel(id: '123', email: 'test@test.com');

  @override
  late final Stream<UserModel?> authStateChanges;

  MockAuthRepository() {
    authStateChanges = Stream.value(currentUser);
  }

  @override
  Future<UserModel?> signIn(String email, String password) async => currentUser;
  @override
  Future<UserModel?> signUp(String email, String password) async => currentUser;
  @override
  Future<void> signOut() async {}
  @override
  void dispose() {}
}

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final mockAuth = MockAuthRepository();
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuth),
          authStateProvider.overrideWith((ref) => mockAuth.authStateChanges),
          onboardingProvider.overrideWith((ref) => OnboardingNotifier()..state = const AsyncValue.data(true)),
          invoicesProvider.overrideWith((ref) => Stream.value([])),
          expensesProvider.overrideWith((ref) => Stream.value([])),
          settingsProvider.overrideWith((ref) => Stream.value(UserSettingsModel.empty())),
        ],
        child: const BizAgentApp(),
      ),
    );
    
    // Initial pump for Splash
    await tester.pump();
    // Allow for redirect to Dashboard
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // Verify that Dashboard is shown.
    expect(find.text('Dashboard'), findsWidgets);
  });
}
