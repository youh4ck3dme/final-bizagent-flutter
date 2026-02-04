import 'expense_category.dart';

class ExpenseModel {
  final String id;
  final String userId;
  final String vendorName;
  final String description;
  final double amount;
  final DateTime date;

  // DPH sledovanie
  final double? vatAmount; // Suma DPH (ak je známa)
  final double? vatRate; // Sadzba DPH (0.0, 0.10, 0.20)

  /// Základ dane - ak máme vatAmount, odpočítame ho, inak celá suma
  double get baseAmount => amount - (vatAmount ?? 0);

  // Multi-currency
  final String currency;
  final double exchangeRate;

  // Prepočet na EUR pre reporting
  double get amountInEur => amount / exchangeRate;
  double get baseAmountInEur => baseAmount / exchangeRate;
  double get vatAmountInEur => (vatAmount ?? 0) / exchangeRate;

  // Kategorizácia
  final ExpenseCategory? category;
  final int? categorizationConfidence; // 0-100

  // Správa účteniek
  final List<String> receiptUrls; // Viacero obrázkov
  final String? thumbnailUrl; // Miniatura prvého obrázku
  final DateTime? receiptScannedAt; // Kedy naskenované
  final bool isOcrVerified; // Používateľ potvrdil OCR dáta

  ExpenseModel({
    required this.id,
    required this.userId,
    required this.vendorName,
    required this.description,
    required this.amount,
    required this.date,
    this.vatAmount,
    this.vatRate,
    this.category,
    this.categorizationConfidence,
    List<String>? receiptUrls,
    this.thumbnailUrl,
    this.receiptScannedAt,
    this.isOcrVerified = false,
    this.currency = 'EUR',
    this.exchangeRate = 1.0,
  }) : receiptUrls = receiptUrls ?? [];

  factory ExpenseModel.fromMap(Map<String, dynamic> map, String id) {
    return ExpenseModel(
      id: id,
      userId: map['userId'] ?? '',
      vendorName: map['vendorName'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      date: DateTime.parse(map['date']),
      vatAmount: map['vatAmount']?.toDouble(),
      vatRate: map['vatRate']?.toDouble(),
      category: expenseCategoryFromString(map['category']),
      categorizationConfidence: map['categorizationConfidence'],
      receiptUrls: map['receiptUrls'] != null
          ? List<String>.from(map['receiptUrls'])
          : [],
      thumbnailUrl: map['thumbnailUrl'],
      receiptScannedAt: map['receiptScannedAt'] != null
          ? DateTime.parse(map['receiptScannedAt'])
          : null,
      isOcrVerified: map['isOcrVerified'] ?? false,
      currency: map['currency'] ?? 'EUR',
      exchangeRate: (map['exchangeRate'] ?? 1.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'vendorName': vendorName,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'vatAmount': vatAmount,
      'vatRate': vatRate,
      'category': category?.name,
      'categorizationConfidence': categorizationConfidence,
      'receiptUrls': receiptUrls,
      'thumbnailUrl': thumbnailUrl,
      'receiptScannedAt': receiptScannedAt?.toIso8601String(),
      'isOcrVerified': isOcrVerified,
      'currency': currency,
      'exchangeRate': exchangeRate,
    };
  }

  ExpenseModel copyWith({
    String? id,
    String? userId,
    String? vendorName,
    String? description,
    double? amount,
    DateTime? date,
    double? vatAmount,
    double? vatRate,
    ExpenseCategory? category,
    int? categorizationConfidence,
    List<String>? receiptUrls,
    String? thumbnailUrl,
    DateTime? receiptScannedAt,
    bool? isOcrVerified,
    String? currency,
    double? exchangeRate,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vendorName: vendorName ?? this.vendorName,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      vatAmount: vatAmount ?? this.vatAmount,
      vatRate: vatRate ?? this.vatRate,
      category: category ?? this.category,
      categorizationConfidence:
          categorizationConfidence ?? this.categorizationConfidence,
      receiptUrls: receiptUrls ?? this.receiptUrls,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      receiptScannedAt: receiptScannedAt ?? this.receiptScannedAt,
      isOcrVerified: isOcrVerified ?? this.isOcrVerified,
      currency: currency ?? this.currency,
      exchangeRate: exchangeRate ?? this.exchangeRate,
    );
  }
}
