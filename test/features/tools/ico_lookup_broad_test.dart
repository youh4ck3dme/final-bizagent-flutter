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
import 'package:bizagent/features/tools/services/watched_companies_service.dart';
import 'package:bizagent/features/entitlements/user_entitlements.dart';
import 'package:bizagent/core/services/analytics_service.dart';

@GenerateNiceMocks([
  MockSpec<CompanyRepository>(),
  MockSpec<WatchedCompaniesService>(),
])
import 'ico_lookup_broad_test.mocks.dart';

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
  late MockWatchedCompaniesService mockWatchedService;

  setUp(() {
    mockRepository = MockCompanyRepository();
    mockWatchedService = MockWatchedCompaniesService();
  });

  Map<String, dynamic> loadFixture(String name) {
    final file = File('test/fixtures/$name');
    final jsonString = file.readAsStringSync();
    return jsonDecode(jsonString);
  }

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        companyRepositoryProvider.overrideWithValue(mockRepository),
        subscriptionGuardProvider.overrideWithValue(MockSubscriptionGuard()),
        usageLimiterProvider.overrideWithValue(MockUsageLimiter()),
        billingProvider.overrideWith(() => MockBillingService() as BillingService),
        watchedCompaniesServiceProvider.overrideWithValue(mockWatchedService),
        authStateProvider.overrideWith((ref) => Stream.value(null)),
        analyticsServiceProvider.overrideWithValue(MockAnalyticsService()),
      ],
      child: const MaterialApp(home: IcoLookupScreen()),
    );
  }

  group('IČO Lookup Comprehensive Tests', () {
    testWidgets('1. Success with AI Analysis (WebSupport)', (tester) async {
      final fixtureData = loadFixture('ico_46359371.json');
      final mockCompany = IcoLookupResult.fromMap(fixtureData);
      const targetIco = '46359371';

      when(
        mockRepository.getFromCache(targetIco),
      ).thenAnswer((_) async => null);
      when(
        mockRepository.refresh(
          targetIco,
          existingHash: anyNamed('existingHash'),
        ),
      ).thenAnswer((_) async => mockCompany);

      await tester.pumpWidget(createTestWidget());
      await tester.enterText(find.byType(TextField), targetIco);
      await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify basic info
      expect(find.text('WebSupport, s.r.o.'), findsOneWidget);
      expect(find.textContaining('Karadžičova 12'), findsOneWidget);

      // Verify AI Verdict and Confidence
      expect(find.text('AI VERDIKT'), findsOneWidget);
      expect(find.text('Spoľahlivý partner'), findsOneWidget);
      expect(find.textContaining('98% istota'), findsOneWidget);

      // Verify Risk Badge
      expect(find.textContaining('Firma je stabilná'), findsOneWidget);
    });

    testWidgets('2. Result from BLESKOVÁ CACHE', (tester) async {
      final fixtureData = loadFixture('ico_36396567.json');
      final mockCompany = IcoLookupResult.fromMap(
        fixtureData,
      ).copyWith(expiresAt: DateTime.now().add(const Duration(hours: 1)));
      const targetIco = '36396567';

      when(
        mockRepository.getFromCache(targetIco),
      ).thenAnswer((_) async => mockCompany);

      await tester.pumpWidget(createTestWidget());
      await tester.enterText(find.byType(TextField), targetIco);
      await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('DÁTA Z CACHE (BLESKOVÉ)'), findsOneWidget);
      expect(find.text('Google Slovakia, s. r. o.'), findsOneWidget);
    });

    testWidgets('3. Not Found Scenario', (tester) async {
      const targetIco = '00000000';
      when(
        mockRepository.getFromCache(targetIco),
      ).thenAnswer((_) async => null);
      when(
        mockRepository.refresh(
          targetIco,
          existingHash: anyNamed('existingHash'),
        ),
      ).thenAnswer((_) async => null);

      await tester.pumpWidget(createTestWidget());
      await tester.enterText(find.byType(TextField), targetIco);
      await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Firma sa nenašla'), findsOneWidget);
    });

    testWidgets('4. Error Handling: Rate Limit', (tester) async {
      const targetIco = '12345678';
      when(
        mockRepository.getFromCache(targetIco),
      ).thenAnswer((_) async => null);
      when(
        mockRepository.refresh(
          targetIco,
          existingHash: anyNamed('existingHash'),
        ),
      ).thenThrow(Exception('Rate limit'));

      await tester.pumpWidget(createTestWidget());
      await tester.enterText(find.byType(TextField), targetIco);
      await tester.tap(find.byIcon(Icons.arrow_forward_rounded));
      await tester.pumpAndSettle();

      expect(find.textContaining('Rate limit'), findsOneWidget);
    });
  });
}

extension on IcoLookupResult {
  IcoLookupResult copyWith({DateTime? expiresAt}) {
    return IcoLookupResult(
      ico: ico,
      name: name,
      status: status,
      street: street,
      city: city,
      postalCode: postalCode,
      dic: dic,
      icDph: icDph,
      riskHint: riskHint,
      riskLevel: riskLevel,
      confidence: confidence,
      headline: headline,
      explanation: explanation,
      fetchedAt: fetchedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      source: source,
    );
  }
}
