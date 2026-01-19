import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bizagent/app.dart';
import 'package:bizagent/features/auth/providers/auth_repository.dart';
import 'package:bizagent/features/auth/models/user_model.dart';
import 'package:bizagent/features/intro/providers/onboarding_provider.dart';
import 'package:bizagent/features/invoices/providers/invoices_provider.dart';
import 'package:bizagent/features/expenses/providers/expenses_provider.dart';
import 'package:bizagent/features/settings/providers/settings_provider.dart';
import 'package:bizagent/features/settings/models/user_settings_model.dart';
import 'package:bizagent/core/services/analytics_service.dart';
import 'package:bizagent/core/router/app_router.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:bizagent/features/notifications/services/notification_service.dart';
import 'dart:async';

class MockAuthRepository implements AuthRepository {
  @override
  UserModel? get currentUser =>
      const UserModel(id: '123', email: 'test@test.com');

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
  Future<UserModel?> signInWithGoogle() async => currentUser;
  @override
  Future<UserModel?> signInAnonymously() async => currentUser;
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

class FakeNotificationService extends Fake implements NotificationService {
  @override
  Future<void> init() async {}
  @override
  Future<bool?> requestPermissions() async => true;
  @override
  Future<void> showNotification(
      {required int id,
      required String title,
      required String body,
      String? payload}) async {}
  @override
  Future<void> scheduleNotification(
      {required int id,
      required String title,
      required String body,
      required DateTime scheduledDate,
      String? payload}) async {}
}

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'seen_onboarding': true});
    final mockAuth = MockAuthRepository();
    final mockAnalytics = MockFirebaseAnalytics();
    final fakeNotifications = FakeNotificationService();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuth),
          authStateProvider.overrideWith((ref) => mockAuth.authStateChanges),
          onboardingProvider.overrideWith((ref) => OnboardingNotifier()),
          invoicesProvider.overrideWith((ref) => Stream.value([])),
          expensesProvider.overrideWith((ref) => Stream.value([])),
          settingsProvider
              .overrideWith((ref) => Stream.value(UserSettingsModel.empty())),
          firebaseAnalyticsProvider.overrideWithValue(mockAnalytics),
          analyticsServiceProvider
              .overrideWithValue(AnalyticsService(mockAnalytics)),
          notificationServiceProvider.overrideWithValue(fakeNotifications),
        ],
        child: const BizAgentApp(),
      ),
    );

    // Initial pump for Splash
    await tester.pump();
    // Allow for redirect to Dashboard
    await tester.pump(const Duration(milliseconds: 100));
    // Dashboard has shimmer animation which is infinite, use pump(Duration)
    await tester.pump(const Duration(seconds: 2));

    // Verify that Dashboard is shown.
    expect(find.text('Dashboard'), findsWidgets);
  });
}
