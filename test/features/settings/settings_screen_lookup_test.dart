import 'package:bizagent/core/models/ico_lookup_result.dart';
import 'package:bizagent/core/providers/theme_provider.dart';
import 'package:bizagent/core/services/company_lookup_service.dart';
import 'package:bizagent/core/services/icoatlas_service.dart';
import 'package:bizagent/features/auth/models/user_model.dart';
import 'package:bizagent/features/auth/providers/auth_repository.dart';
import 'package:bizagent/features/settings/models/user_settings_model.dart';
import 'package:bizagent/features/settings/providers/settings_provider.dart';
import 'package:bizagent/features/settings/providers/settings_repository.dart';
import 'package:bizagent/features/settings/screens/settings_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Fake classes to bypass Firebase initialization
class FakeFirebaseFunctions extends Fake implements FirebaseFunctions {}

class FakeFirebaseFirestore extends Fake implements FirebaseFirestore {}

class FakeIcoAtlasService extends Fake implements IcoAtlasService {
  @override
  Future<IcoLookupResult?> publicLookup(String ico) async => null;
}

// Fake service to avoid real API calls
class FakeCompanyLookupService implements CompanyLookupService {
  @override
  Future<IcoLookupResult> lookupByIco(String ico) async {
    if (ico == '36396567') {
      return IcoLookupResult(
        ico: '36396567',
        icoNorm: '36396567',
        name: 'Google Slovakia, s. r. o.',
        status: 'Active',
        city: 'Bratislava',
        street: 'Karadžičova 8/A',
        postalCode: '821 08',
        dic: '2020102636',
        icDph: 'SK2020102636',
          fetchedAt: DateTime.now(),
      );
    }
    throw Exception('Not found');
  }
}

class FakeSettingsRepository extends SettingsRepository {
  FakeSettingsRepository() : super(FakeFirebaseFirestore());

  @override
  Stream<UserSettingsModel> watchSettings(String userId) {
    return Stream.value(UserSettingsModel.empty());
  }
}

void main() {
  Finder _fieldByLabel(String label) {
    // TextFormField builds a TextField internally; TextField exposes `decoration`.
    return find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == label,
      description: 'TextField(labelText: $label)',
    );
  }

  testWidgets('SettingsScreen populates fields after IČO lookup',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    // Override providers
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          companyLookupServiceProvider
              .overrideWithValue(FakeCompanyLookupService()),
          settingsProvider
              .overrideWith((ref) => Stream.value(UserSettingsModel.empty())),
          settingsRepositoryProvider
              .overrideWithValue(FakeSettingsRepository()),
          authStateProvider.overrideWith((ref) => Stream.value(
              const UserModel(id: 'test-user', email: 'test@example.com'))),
          themeProvider.overrideWith((ref) => ThemeNotifier()), // Default theme
        ],
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle(); // Wait for AsyncValue data

    // Initial state: Empty Name
    expect(find.text('Google Slovakia, s. r. o.'), findsNothing);

    // Enter IČO
    final icoField = _fieldByLabel('IČO');
    expect(icoField, findsOneWidget);

    await tester.enterText(icoField, '36396567');
    await tester.pump();

    // Tap Search Icon
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle(); // Wait for async lookup

    // Verify Fields Populated (assert via controllers; TextFormField doesn't render its value as Text widgets)
    final nameField = tester.widget<TextField>(_fieldByLabel('Obchodné meno'));
    expect(nameField.controller?.text, 'Google Slovakia, s. r. o.');

    final addressField = tester.widget<TextField>(_fieldByLabel('Adresa sídla'));
    final addressText = addressField.controller?.text ?? '';
    expect(addressText, contains('Karadžičova 8/A'));
    expect(addressText, contains('821 08'));
    expect(addressText, contains('Bratislava'));

    final dicField = tester.widget<TextField>(_fieldByLabel('DIČ'));
    expect(dicField.controller?.text, '2020102636');

    final icDphField = tester.widget<TextField>(_fieldByLabel('IČ DPH'));
    expect(icDphField.controller?.text, 'SK2020102636');

    // Verify Snackbar feedback
    expect(find.text('Našli sme: Google Slovakia, s. r. o.'), findsOneWidget);
  });
}
