import 'package:flutter/foundation.dart';
import 'demo_mode_service.dart';
import 'demo_scenarios.dart';

/// Spúšťa kompletný demo scenár s naratívom pre prezentácie / interné testovanie.
class DemoScenarioRunner {
  DemoScenarioRunner._();
  static final DemoScenarioRunner _instance = DemoScenarioRunner._();
  static DemoScenarioRunner get instance => _instance;

  final DemoModeService _demo = DemoModeService.instance;

  /// Spusti kompletný demo s výpisom scén (pre CLI / debug).
  Future<void> runFullDemo({void Function(String)? onScene}) async {
    if (kDebugMode) {
      debugPrint('🎬 Starting BizAgent AI Demo...\n');
    }
    onScene?.call('Starting BizAgent AI Demo');

    _demo.activateDemoMode(DemoScenario.standard);

    if (kDebugMode) {
      debugPrint('📊 Scene 1: AI Dashboard (Proaktívny AI účtovník)');
    }
    onScene?.call('Scene 1: AI Dashboard');
    await Future<void>.delayed(const Duration(seconds: 1));

    if (kDebugMode) {
      debugPrint('🔮 Scene 2: Prediction Alert');
    }
    onScene?.call('Scene 2: Prediction Alert');
    _demo.setScenario(DemoScenario.standard);
    await Future<void>.delayed(const Duration(seconds: 1));

    if (kDebugMode) {
      debugPrint('💰 Scene 3: Tax Optimization');
    }
    onScene?.call('Scene 3: Tax Optimization');
    _demo.setScenario(DemoScenario.taxOptimization);
    await Future<void>.delayed(const Duration(seconds: 1));

    if (kDebugMode) {
      debugPrint('⚠️ Scene 4: Anomaly Detection');
    }
    onScene?.call('Scene 4: Anomaly Detection');
    _demo.setScenario(DemoScenario.anomalyDetection);
    await Future<void>.delayed(const Duration(seconds: 1));

    if (kDebugMode) {
      debugPrint('🔍 Scene 5: Receipt Detective');
    }
    onScene?.call('Scene 5: Receipt Detective');
    _demo.setScenario(DemoScenario.receiptMissing);
    await Future<void>.delayed(const Duration(seconds: 2));

    if (kDebugMode) {
      debugPrint('\n✅ Demo Complete!');
    }
    onScene?.call('Demo Complete');
  }

  /// Zoznam názvov scén pre UI (napr. výber scenára).
  static List<String> get sceneLabels =>
      DemoScenario.values.map((s) => s.label).toList();
}
