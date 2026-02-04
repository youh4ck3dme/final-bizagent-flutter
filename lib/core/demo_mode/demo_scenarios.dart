/// Demo scenáre pre prezentácie a testovanie BizAgent AI funkcií.
enum DemoScenario {
  /// Bežný SZČO, 6 mesiacov dát.
  standard,

  /// Blíži sa k DPH limitu.
  approachingVat,

  /// Nízky cashflow, potrebuje alert.
  cashflowCrisis,

  /// Príležitosti na úsporu (daňový stratég).
  taxOptimization,

  /// Podozrivé transakcie / anomálie.
  anomalyDetection,

  /// Chýbajúce bločky na rekonštrukciu (Receipt Detective).
  receiptMissing,
}

extension DemoScenarioX on DemoScenario {
  String get label {
    switch (this) {
      case DemoScenario.standard:
        return 'Štandardný SZČO';
      case DemoScenario.approachingVat:
        return 'Blíži sa DPH limit';
      case DemoScenario.cashflowCrisis:
        return 'Cashflow kríza';
      case DemoScenario.taxOptimization:
        return 'Daňová optimalizácia';
      case DemoScenario.anomalyDetection:
        return 'Anomálie';
      case DemoScenario.receiptMissing:
        return 'Chýbajúce bločky';
    }
  }
}
