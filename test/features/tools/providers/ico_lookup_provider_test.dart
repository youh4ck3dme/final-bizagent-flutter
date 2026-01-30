import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:bizagent/features/tools/providers/ico_lookup_provider.dart';
import 'package:bizagent/features/tools/services/company_repository.dart';
import 'package:bizagent/core/models/ico_lookup_result.dart';
import 'package:bizagent/features/auth/providers/auth_repository.dart';

@GenerateNiceMocks([MockSpec<CompanyRepository>()])
import 'ico_lookup_provider_test.mocks.dart';

void main() {
  late MockCompanyRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = MockCompanyRepository();
    container = ProviderContainer(
      overrides: [
        companyRepositoryProvider.overrideWithValue(mockRepository),
        // Mock auth to avoid side effects (markAsOpened)
        authStateProvider.overrideWith((ref) => Stream.value(null)),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  /// LOAD FIXTURE HELPER
  Map<String, dynamic> loadFixture(String name) {
    final file = File('test/fixtures/$name');
    final jsonString = file.readAsStringSync();
    return jsonDecode(jsonString);
  }

  test('Initial state should be idle', () {
    final state = container.read(icoLookupProvider);
    expect(state.status, IcoLookupStatus.idle);
  });

  test('Lookup should cycle through loading to success when repo returns data (USING FIXTURE)', () async {
    // Arrange
    final fixtureData = loadFixture('ico_36396567.json');
    final mockResult = IcoLookupResult.fromMap(fixtureData);
    final ico = mockResult.ico;

    // Simulate no cache, fetch from backend
    when(mockRepository.getFromCache(ico)).thenAnswer((_) async => null);
    when(mockRepository.refresh(ico, existingHash: anyNamed('existingHash')))
        .thenAnswer((_) async => mockResult);

    // Act
    final future = container.read(icoLookupProvider.notifier).lookup(ico);

    // Assert - Check loading state
    expect(
      container.read(icoLookupProvider).status,
      IcoLookupStatus.loading,
    );

    await future;

    // Assert - Check success state
    final state = container.read(icoLookupProvider);
    expect(state.status, IcoLookupStatus.success);
    expect(state.result, mockResult);
    expect(state.result?.name, fixtureData['name']);
  });

  test('Lookup should return notFound when repo returns null', () async {
    // Arrange
    const ico = '00000000';
    when(mockRepository.getFromCache(ico)).thenAnswer((_) async => null);
    when(mockRepository.refresh(ico)).thenAnswer((_) async => null);

    // Act
    await container.read(icoLookupProvider.notifier).lookup(ico);

    // Assert
    expect(container.read(icoLookupProvider).status, IcoLookupStatus.notFound);
  });

  test('Lookup should handle errors and set errorOffline state on SocketException', () async {
    // Arrange
    const ico = '99999999';
    when(mockRepository.getFromCache(ico)).thenAnswer((_) async => null);
    when(mockRepository.refresh(ico)).thenThrow(Exception('SocketException: No internet'));

    // Act
    await container.read(icoLookupProvider.notifier).lookup(ico);

    // Assert
    expect(container.read(icoLookupProvider).status, IcoLookupStatus.errorOffline);
  });
}
