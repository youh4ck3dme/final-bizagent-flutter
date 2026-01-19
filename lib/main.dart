import 'dart:async'; // For runZonedGuarded
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/cache_service.dart';
import 'firebase_options.dart';
import 'app.dart';

import 'package:flutter_web_plugins/url_strategy.dart'; // Import for Clean URLs

void main() {
  runZonedGuarded(() async {
    final startTime = DateTime.now();
    debugPrint('🚀 [PERF] App start: ${startTime.toIso8601String()}');

    // Use PathUrlStrategy for clean URLs (no /#/)
    usePathUrlStrategy();

    final bindingStart = DateTime.now();
    WidgetsFlutterBinding.ensureInitialized();

    // Light Cache Cleanup (Non-disruptive)
    await CacheService().performLightCleanup();
    debugPrint(
        '⏱️  [PERF] Binding initialized: ${DateTime.now().difference(bindingStart).inMilliseconds}ms');

    final firebaseStart = DateTime.now();
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Enable Firestore offline persistence
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      // Initial Performance Monitoring
      try {
        await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);
        debugPrint('⏱️  [PERF] Performance monitoring enabled');
      } catch (e) {
        debugPrint('⚠️ [PERF] Failed to enable performance monitoring: $e');
      }

      debugPrint(
          '⏱️  [PERF] Firebase initialized: ${DateTime.now().difference(firebaseStart).inMilliseconds}ms');
    } catch (e) {
      debugPrint('❌ Firebase init warning: $e');
    }

    final orientationStart = DateTime.now();
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    debugPrint(
        '⏱️  [PERF] Orientation set: ${DateTime.now().difference(orientationStart).inMilliseconds}ms');

    final totalTime = DateTime.now().difference(startTime).inMilliseconds;
    debugPrint('✅ [PERF] Total init time: ${totalTime}ms');
    debugPrint('🎯 [PERF] Running app...');

    runApp(const ProviderScope(child: BizAgentApp()));
  }, (error, stack) {
    debugPrint('🔥 CRITICAL APP CRASH: $error');
    debugPrint('Stack trace: $stack');
  });
}
