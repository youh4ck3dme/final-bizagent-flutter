import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb, debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'core/services/local_persistence_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'features/limits/usage_limiter.dart';

Future<void> _initFirebaseAppCheck() async {
  if (kIsWeb) {
    const webSiteKey = String.fromEnvironment(
      'APP_CHECK_WEB_SITE_KEY',
      defaultValue: '6LfwZ1YsAAAAANYS3BP1DwHQ6o1ue8iDmlxjuLJN',
    );

    if (webSiteKey.isEmpty) {
      debugPrint('App Check: SKIPPING web activation (Missing key).');
      return;
    }

    try {
      await FirebaseAppCheck.instance.activate(
        webProvider: ReCaptchaEnterpriseProvider(webSiteKey),
      );
    } catch (e) {
      debugPrint('⚠️ App Check Warning: Failed to activate on Web: $e');
    }
    return;
  }

  // Modern activation API for native platforms
  await FirebaseAppCheck.instance.activate(
    androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
  );
}

void main() async {
  await runMain();
}

Future<void> runMain({List<dynamic> overrides = const []}) async {
  WidgetsFlutterBinding.ensureInitialized();

  // GLOBAL ERROR BOUNDARY
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (!kDebugMode) {
      // In production, log to Crashlytics
      // FirebaseCrashlytics.instance.recordFlutterError(details);
    }
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Container(
        padding: const EdgeInsets.all(16),
        color: const Color(0xFF0A0D14), // Deep Space
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFF00B4D8), size: 48),
            const SizedBox(height: 16),
            const Text(
              'Oops! Niečo sa pokazilo.',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              kDebugMode ? details.exception.toString() : 'Pracujeme na oprave. Skúste to prosím neskôr.',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  };

  if (kDebugMode && !kIsWeb) {
    try {
      final r = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));
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

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Configure Firebase UI Providers for modern login
  FirebaseUIAuth.configureProviders([
    EmailAuthProvider(),
    GoogleProvider(
      clientId:
          '542280140779-c5m14rqpih1j9tmf9km52aq1684l9qjd.apps.googleusercontent.com',
    ),
  ]);

  // Initialize App Check but don't block app startup
  unawaited(_initFirebaseAppCheck());

  if (kDebugMode) {
    debugPrint('Using Production Firebase (Debug Mode)');
  }

  runApp(
    ProviderScope(
      overrides: [
        localPersistenceServiceProvider.overrideWithValue(persistenceService),
        sharedPrefsProvider.overrideWithValue(sharedPrefs),
        ...overrides,
      ],
      child: const BizAgentApp(),
    ),
  );
}
