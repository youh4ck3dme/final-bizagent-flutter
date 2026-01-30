import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
  show TargetPlatform, defaultTargetPlatform, kDebugMode, kIsWeb, debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
// import 'package:cloud_functions/cloud_functions.dart'; // Removed
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'core/services/local_persistence_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'features/limits/usage_limiter.dart';

Future<void> _initFirebaseAppCheck() async {
  const webSiteKey = String.fromEnvironment(
    'APP_CHECK_WEB_SITE_KEY',
    defaultValue: '6LfwZ1YsAAAAANYS3BP1DwHQ6o1ue8iDmlxjuLJN',
  );

  if (kIsWeb) {
    if (webSiteKey.isEmpty) {
      debugPrint('App Check: missing APP_CHECK_WEB_SITE_KEY, skipping web activation.');
      return;
    }

    await FirebaseAppCheck.instance.activate(
      webProvider: ReCaptchaEnterpriseProvider(webSiteKey),
    );
    return;
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      await FirebaseAppCheck.instance.activate(
        androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      );
      break;
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      await FirebaseAppCheck.instance.activate(
        appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
      );
      break;
    default:
      break;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode && !kIsWeb) {
    try {
      final r = await http.get(Uri.parse('https://www.google.com')).timeout(const Duration(seconds: 5));
      debugPrint('NET OK: ${r.statusCode}');
    } catch (e) {
      debugPrint('NET ERROR: $e');
    }
  }

  // Initialize Hive for Offline Storage
  await Hive.initFlutter();
  await initializeDateFormatting('sk', null);
  final persistenceService = LocalPersistenceService();
  await persistenceService.init();

  final sharedPrefs = await SharedPreferences.getInstance();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await _initFirebaseAppCheck();

  if (kDebugMode) {
    try {
      debugPrint('Using Firebase Emulators...');
      // Use emulators in debug mode
      // await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      // FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      // await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
      // FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
    } catch (e) {
      debugPrint('Emulator init error: $e');
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        localPersistenceServiceProvider.overrideWithValue(persistenceService),
        sharedPrefsProvider.overrideWithValue(sharedPrefs),
      ],
      child: const BizAgentApp(),
    ),
  );
}
