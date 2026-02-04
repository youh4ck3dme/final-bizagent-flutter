/// Zdroj údajov pre rekonštruovaný doklad (Bloček Detective).
enum ReconstructedSource {
  bank,
  geo,
  email,
  photo,
  noReceipt, // výdavok bez účtenky – kandidát na rekonštrukciu
}

/// Jedna návrhová položka od "Bloček Detective" – rekonštrukcia z fragmentov.
class ReconstructedExpenseSuggestion {
  final String id;
  final double amount;
  final DateTime date;
  final String vendorHint;
  final String? description;
  final ReconstructedSource source;

  /// 0–100, ako istá je AI.
  final int confidence;

  /// Ak je z existujúceho výdavku (bez účtenky).
  final String? expenseId;

  /// Ak je z bankového pohybu (napr. id z importu).
  final String? bankTxId;

  const ReconstructedExpenseSuggestion({
    required this.id,
    required this.amount,
    required this.date,
    required this.vendorHint,
    this.description,
    required this.source,
    this.confidence = 80,
    this.expenseId,
    this.bankTxId,
  });

  String get sourceLabel {
    switch (source) {
      case ReconstructedSource.bank:
        return 'Bankový výpis';
      case ReconstructedSource.geo:
        return 'GPS lokácia';
      case ReconstructedSource.email:
        return 'E-mail';
      case ReconstructedSource.photo:
        return 'Fotka z galérie';
      case ReconstructedSource.noReceipt:
        return 'Výdavok bez účtenky';
    }
  }

  /// Textová etiketa spoľahlivosti (podľa referenčného ConfidenceScore).
  String get confidenceLabel {
    if (confidence >= 95) return 'Veľmi vysoká';
    if (confidence >= 85) return 'Vysoká';
    if (confidence >= 70) return 'Stredná';
    if (confidence >= 50) return 'Nízka';
    return 'Veľmi nízka';
  }

  /// Pre daňové účely je akceptovateľná spoľahlivosť ≥85% (SK odporúčanie).
  bool get isAcceptableForTax => confidence >= 85;
}
