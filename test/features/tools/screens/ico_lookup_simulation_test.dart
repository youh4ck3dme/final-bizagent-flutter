import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:bizagent/features/tools/screens/ico_lookup_screen.dart';
import 'package:bizagent/features/tools/services/company_repository.dart';
import 'package:bizagent/features/billing/subscription_guard.dart';
import 'package:bizagent/core/models/ico_lookup_result.dart';
import 'package:bizagent/features/auth/providers/auth_repository.dart';
import 'package:bizagent/features/limits/usage_limiter.dart';
import 'package:bizagent/features/billing/billing_service.dart';
import 'package:bizagent/core/services/analytics_service.dart';

@GenerateNiceMocks([
  MockSpec<CompanyRepository>(),
  MockSpec<WatchedCompaniesService>(),
])
import 'ico_lookup_simulation_test.mocks.dart';

import 'package:bizagent/features/tools/services/watched_companies_service.dart';

import 'package:bizagent/features/entitlements/user_entitlements.dart';

class MockSubscriptionGuard extends Mock implements SubscriptionGuard {
  @override
  bool canAccess(BizFeature? feature) => true;
}

class MockUsageLimiter extends Mock implements UsageLimiter {
  @override
  Future<void> incrementIco() async {}
}

class MockBillingService extends BillingService with Mock {
  @override
  BillingState build() => BillingState(entitlements: UserEntitlements.free());
  @override
  void refreshUsage() {}
  @override
  Future<void> loadProducts() async {}
  @override
  Future<void> purchaseProduct(ProductDetails product) async {}
  @override
  Future<void> restorePurchases() async {}
}

class MockAnalyticsService extends Mock implements AnalyticsService {
  @override
  Future<void> logIcoLookup({required bool success}) async {}
}

void main() {
  late MockCompanyRepository mockRepository;

  setUp(() {
    mockRepository = MockCompanyRepository();
  });

  /// LOAD FIXTURE HELPER
  Map<String, dynamic> loadFixture(String name) {
    final file = File('test/fixtures/$name');
    final jsonString = file.readAsStringSync();
    return jsonDecode(jsonString);
  }

  testWidgets('SIMULATION: User enters 36396567 and sees REAL fixture data', (
    WidgetTester tester,
  ) async {
    // 1. DATA SETUP (FROM GOLDEN FIXTURE - NO LIES)
    final fixtureData = loadFixture('ico_36396567.json');
    final mockCompany = IcoLookupResult.fromMap(fixtureData);

    const targetIco = '36396567';

    // Mock Provider Responses
    when(mockRepository.getFromCache(targetIco)).thenAnswer((_) async => null);
    when(
      mockRepository.refresh(targetIco, existingHash: anyNamed('existingHash')),
    ).thenAnswer((_) async => mockCompany);

    // 2. APP LAUNCH
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          companyRepositoryProvider.overrideWithValue(mockRepository),
          subscriptionGuardProvider.overrideWithValue(MockSubscriptionGuard()),
          usageLimiterProvider.overrideWithValue(MockUsageLimiter()),
          billingProvider.overrideWith(() => MockBillingService()),
          watchedCompaniesServiceProvider.overrideWithValue(
            MockWatchedCompaniesService(),
          ),
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          analyticsServiceProvider.overrideWithValue(MockAnalyticsService()),
        ],
        child: const MaterialApp(home: IcoLookupScreen()),
      ),
    );

    // 3. USER INTERACTION
    await tester.enterText(find.byType(TextField), targetIco);
    await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
    await tester.pump(); // Start animation

    // 4. WAIT FOR RESULT
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // 5. VERIFY RESULT AGAINST FIXTURE
    final name = fixtureData['name'];
    final rawAddr = fixtureData['address'];

    // Handle both Map and String address formats
    final street = rawAddr is Map ? rawAddr['street'] : rawAddr.toString();
    final city = rawAddr is Map ? rawAddr['city'] : null;

    // UI typically shows street or city
    expect(find.text(name), findsOneWidget);
    if (street != null) expect(find.textContaining(street), findsOneWidget);
    if (city != null) expect(find.textContaining(city), findsOneWidget);

    debugPrint('SUCCESS: UI matched Golden Fixture exactly.');
  });

  testWidgets('SIMULATION: User enters 57409625 (NEW FIXTURE)', (
    WidgetTester tester,
  ) async {
    // 1. DATA SETUP
    final fixtureData = loadFixture('ico_57409625.json');
    final mockCompany = IcoLookupResult.fromMap(fixtureData);

    const targetIco = '57409625';

    // Mock Provider Responses
    when(mockRepository.getFromCache(targetIco)).thenAnswer((_) async => null);
    when(
      mockRepository.refresh(targetIco, existingHash: anyNamed('existingHash')),
    ).thenAnswer((_) async => mockCompany);

    // 2. APP LAUNCH
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          companyRepositoryProvider.overrideWithValue(mockRepository),
          subscriptionGuardProvider.overrideWithValue(MockSubscriptionGuard()),
          usageLimiterProvider.overrideWithValue(MockUsageLimiter()),
          billingProvider.overrideWith(() => MockBillingService() as BillingService),
          watchedCompaniesServiceProvider.overrideWithValue(
            MockWatchedCompaniesService(),
          ),
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          analyticsServiceProvider.overrideWithValue(MockAnalyticsService()),
        ],
        child: const MaterialApp(home: IcoLookupScreen()),
      ),
    );

    // 3. USER INTERACTION
    await tester.enterText(find.byType(TextField), targetIco);
    await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
    await tester.pump();

    // 4. WAIT FOR RESULT
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // 5. VERIFY
    final effectiveData =
        fixtureData.containsKey('data') ? fixtureData['data'] : fixtureData;
    final name = effectiveData['name'];
    expect(find.text(name), findsOneWidget);
  });
}
