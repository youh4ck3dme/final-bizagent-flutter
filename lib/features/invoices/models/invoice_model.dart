// Tax calculation service is imported where needed
import '../../../core/services/tax_calculation_service.dart';

enum InvoiceStatus { draft, sent, paid, overdue, cancelled }

class InvoiceItemModel {
  final String title; // Changed from description for consistency
  final double amount; // Changed from quantity * unitPrice for NET amount
  final double vatRate;

  InvoiceItemModel({
    required this.title,
    required this.amount, // NET amount (bez DPH)
    required this.vatRate,
  });

  // For backward compatibility - create from old format
  factory InvoiceItemModel.fromOldFormat({
    required String description,
    required double quantity,
    required double unitPrice,
    double vatRate = 0.0,
  }) {
    return InvoiceItemModel(
      title: description,
      amount: quantity * unitPrice, // NET amount
      vatRate: vatRate,
    );
  }

  // Legacy getters for backward compatibility
  String get description => title;
  double get quantity => 1.0; // Simplified
  double get unitPrice => amount;
  double get subtotal => amount; // NET = subtotal
  double get vatAmount =>
      amount * vatRate; // raw, use TaxLine for proper rounding
  double get totalWithVat => amount + vatAmount;
  double get total => amount;

  // Tax calculation method
  TaxLine toTaxLine(TaxCalculationService tax) {
    return tax.calcLine(baseAmount: amount, vatRate: vatRate);
  }

  factory InvoiceItemModel.fromMap(Map<String, dynamic> map) {
    // Support both old and new formats
    final hasOldFormat =
        map.containsKey('description') && map.containsKey('quantity');

    if (hasOldFormat) {
      return InvoiceItemModel.fromOldFormat(
        description: map['description'] ?? '',
        quantity: (map['quantity'] ?? 0).toDouble(),
        unitPrice: (map['unitPrice'] ?? 0).toDouble(),
        vatRate: (map['vatRate'] ?? 0.0).toDouble(),
      );
    } else {
      // New format
      return InvoiceItemModel(
        title: map['title'] ?? map['description'] ?? '',
        amount: (map['amount'] ?? 0).toDouble(),
        vatRate: (map['vatRate'] ?? 0.0).toDouble(),
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'vatRate': vatRate,
    };
  }
}

class InvoiceModel {
  final String id;
  final String userId;
  final String number;
  final String clientName;
  final String? clientAddress; // Added
  final String? clientIco;
  final String? clientDic; // Added
  final String? clientIcDph; // Added
  final DateTime dateIssued;
  final DateTime dateDue;
  final List<InvoiceItemModel> items;
  final double totalAmount;
  final InvoiceStatus status;
  final String? pdfUrl;
  final String? variableSymbol; // Added
  final String? constantSymbol; // Added
  final bool isNumberProvisional; // Added for offline numbering

  InvoiceModel({
    required this.id,
    required this.userId,
    required this.number,
    required this.clientName,
    this.clientAddress,
    this.clientIco,
    this.clientDic,
    this.clientIcDph,
    required this.dateIssued,
    required this.dateDue,
    required this.items,
    required this.totalAmount,
    required this.status,
    this.pdfUrl,
    this.variableSymbol,
    this.constantSymbol,
    this.isNumberProvisional = false,
  });

  // VAT Calculations
  double get totalBeforeVat =>
      items.fold(0, (sum, item) => sum + item.subtotal);
  double get totalVat => items.fold(0, (sum, item) => sum + item.vatAmount);
  double get grandTotal => totalBeforeVat + totalVat;

  Map<double, double> get vatBreakdown {
    final breakdown = <double, double>{};
    for (var item in items) {
      breakdown[item.vatRate] = (breakdown[item.vatRate] ?? 0) + item.vatAmount;
    }
    return breakdown;
  }

  factory InvoiceModel.fromMap(Map<String, dynamic> map, String id) {
    return InvoiceModel(
      id: id,
      userId: map['userId'] ?? '',
      number: map['number'] ?? '',
      clientName: map['clientName'] ?? '',
      clientAddress: map['clientAddress'],
      clientIco: map['clientIco'],
      clientDic: map['clientDic'],
      clientIcDph: map['clientIcDph'],
      dateIssued: DateTime.parse(map['dateIssued']),
      dateDue: DateTime.parse(map['dateDue']),
      items: (map['items'] as List<dynamic>?)
              ?.map((x) => InvoiceItemModel.fromMap(x))
              .toList() ??
          [],
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      status: InvoiceStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'draft'),
        orElse: () => InvoiceStatus.draft,
      ),
      pdfUrl: map['pdfUrl'],
      variableSymbol: map['variableSymbol'],
      constantSymbol: map['constantSymbol'],
      isNumberProvisional: map['isNumberProvisional'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'number': number,
      'clientName': clientName,
      'clientAddress': clientAddress,
      'clientIco': clientIco,
      'clientDic': clientDic,
      'clientIcDph': clientIcDph,
      'dateIssued': dateIssued.toIso8601String(),
      'dateDue': dateDue.toIso8601String(),
      'items': items.map((x) => x.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status.name,
      'pdfUrl': pdfUrl,
      'variableSymbol': variableSymbol,
      'constantSymbol': constantSymbol,
      'isNumberProvisional': isNumberProvisional,
    };
  }
}
