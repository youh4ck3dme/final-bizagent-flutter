import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'app.dart';

void main() async {
  final startTime = DateTime.now();
  debugPrint('🚀 [PERF] App start: ${startTime.toIso8601String()}');

  final bindingStart = DateTime.now();
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint(
      '⏱️  [PERF] Binding initialized: ${DateTime.now().difference(bindingStart).inMilliseconds}ms');

  final firebaseStart = DateTime.now();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
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
}
