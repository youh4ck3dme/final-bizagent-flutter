import 'package:cloud_firestore/cloud_firestore.dart';

class IcoLookupResult {
  final String ico;
  final String icoNorm;
  final String name;
  final String status;
  final String street;
  final String city;
  final String postalCode;
  final String? dic;
  final String? icDph;
  final String? riskHint;
  final String? riskLevel;
  final double? confidence;
  final String? headline;
  final String? explanation;
  final int? resetIn;
  final bool isRateLimited;
  final bool isPaymentRequired;
  final bool isOffline;
  final DateTime? fetchedAt; // Renamed from cachedAt to match schema
  final DateTime? expiresAt; // New field
  final String? source;      // New field
  final String? hash;        // New field
  final String? lastSyncFrom; // New field

  const IcoLookupResult._({
    this.ico = '',
    this.icoNorm = '',
    required this.name,
    required this.status,
    this.street = '',
    required this.city,
    this.postalCode = '',
    this.dic,
    this.icDph,
    this.riskHint,
    this.riskLevel,
    this.confidence,
    this.headline,
    this.explanation,
    this.resetIn,
    this.isRateLimited = false,
    this.isPaymentRequired = false,
    this.isOffline = false,
    this.fetchedAt,
    this.expiresAt,
    this.source,
    this.hash,
    this.lastSyncFrom,
  });

  factory IcoLookupResult({
    String ico = '',
    String icoNorm = '',
    required String name,
    required String status,
    String street = '',
    required String city,
    String postalCode = '',
    String? dic,
    String? icDph,
    String? riskHint,
    String? riskLevel,
    double? confidence,
    String? headline,
    String? explanation,
    int? resetIn,
    bool isRateLimited = false,
    bool isPaymentRequired = false,
    bool isOffline = false,
    DateTime? fetchedAt,
    DateTime? expiresAt,
    String? source,
    String? hash,
    String? lastSyncFrom,
  }) {
    final effectiveIcoNorm = icoNorm.isNotEmpty 
        ? icoNorm 
        : ico.replaceAll(RegExp(r'\D'), '');
        
    return IcoLookupResult._(
      ico: ico,
      icoNorm: effectiveIcoNorm,
      name: name,
      status: status,
      street: street,
      city: city,
      postalCode: postalCode,
      dic: dic,
      icDph: icDph,
      riskHint: riskHint,
      riskLevel: riskLevel,
      confidence: confidence,
      headline: headline,
      explanation: explanation,
      resetIn: resetIn,
      isRateLimited: isRateLimited,
      isPaymentRequired: isPaymentRequired,
      isOffline: isOffline,
      fetchedAt: fetchedAt,
      expiresAt: expiresAt,
      source: source,
      hash: hash,
      lastSyncFrom: lastSyncFrom,
    );
  }

  // --- Factories for Service Logic ---

  factory IcoLookupResult.invalid() {
    return IcoLookupResult(
      name: '',
      status: 'Neplatné dáta',
      city: '',
    );
  }

  factory IcoLookupResult.offline() {
    return IcoLookupResult(
      name: '',
      status: 'Offline',
      city: '',
      isOffline: true,
    );
  }

  factory IcoLookupResult.rateLimited({int? resetIn}) {
    return IcoLookupResult(
      name: '',
      status: 'Limit dosiahnutý',
      city: '',
      resetIn: resetIn,
      isRateLimited: true,
    );
  }

  factory IcoLookupResult.paymentRequired() {
    return IcoLookupResult(
      name: '',
      status: 'Premium feature',
      city: '',
      isPaymentRequired: true,
    );
  }

  factory IcoLookupResult.empty() {
    return IcoLookupResult.invalid();
  }

  // --- Serialization ---

  factory IcoLookupResult.fromFirestore(Map<String, dynamic> json) {
    return IcoLookupResult(
      ico: json['ico'] ?? '',
      icoNorm: json['icoNorm'] ?? '',
      name: json['name'] ?? '',
      status: json['status'] ?? '',
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      postalCode: json['postalCode'] ?? '',
      dic: json['dic'],
      icDph: json['icDph'],
      riskHint: json['riskHint'],
      riskLevel: json['riskLevel'],
      confidence: json['confidence'] != null ? double.tryParse(json['confidence'].toString()) : null,
      headline: json['headline'],
      explanation: json['explanation'],
      fetchedAt: (json['fetchedAt'] as Timestamp?)?.toDate(),
      expiresAt: (json['expiresAt'] as Timestamp?)?.toDate(),
      source: json['source'],
      hash: json['hash'],
      lastSyncFrom: json['lastSyncFrom'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'ico': ico,
    'icoNorm': icoNorm,
    'name': name,
    'status': status,
    'street': street,
    'city': city,
    'postalCode': postalCode,
    'dic': dic,
    'icDph': icDph,
    'riskHint': riskHint,
    'riskLevel': riskLevel,
    'confidence': confidence,
    'headline': headline,
    'explanation': explanation,
    'fetchedAt': fetchedAt != null ? Timestamp.fromDate(fetchedAt!) : FieldValue.serverTimestamp(),
    'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    'source': source,
    'hash': hash,
    'lastSyncFrom': lastSyncFrom,
  };

  factory IcoLookupResult.fromMap(Map<String, dynamic> map) {
    final addr = map['address'] as Map<String, dynamic>?;
    final verdict = map['ai_verdict'] as Map<String, dynamic>?;
    final rawIco = map['ico']?.toString() ?? '';

    return IcoLookupResult(
      ico: rawIco,
      name: map['name'] ?? '',
      status: map['status'] ?? '',
      street: addr?['street'] ?? '',
      city: addr?['city'] ?? map['city'] ?? '',
      postalCode: addr?['postalCode'] ?? '',
      dic: map['dic'],
      icDph: map['icDph'],
      riskHint: map['riskHint'] ?? (map['hints']?['riskHint']),
      riskLevel: map['riskLevel'] ?? map['risk_level'] ?? (map['hints']?['riskLevel']),
      confidence: map['confidence'] != null ? double.tryParse(map['confidence'].toString()) : null,
      headline: verdict?['headline'] ?? map['headline'],
      explanation: verdict?['explanation'] ?? map['explanation'],
      resetIn: map['resetIn'] != null ? int.tryParse(map['resetIn'].toString()) : null,
      fetchedAt: map['fetchedAt'] != null ? (map['fetchedAt'] is Timestamp ? (map['fetchedAt'] as Timestamp).toDate() : DateTime.tryParse(map['fetchedAt'].toString())) : null,
      expiresAt: map['expiresAt'] != null ? (map['expiresAt'] is Timestamp ? (map['expiresAt'] as Timestamp).toDate() : DateTime.tryParse(map['expiresAt'].toString())) : null,
      source: map['source'],
      hash: map['hash'],
      lastSyncFrom: map['lastSyncFrom'],
    );
  }

  factory IcoLookupResult.fromRealApi(Map<String, dynamic> json) {
    final identifiers = json['identifiers'] as Map<String, dynamic>?;
    final snapshot = json['snapshot'] as Map<String, dynamic>?;
    final address = snapshot?['address_current'] as Map<String, dynamic>?;
    
    final rawIco = identifiers?['ico']?.toString() ?? '';
    final normIco = rawIco.replaceAll(RegExp(r'\D'), '');

    return IcoLookupResult(
      ico: rawIco,
      icoNorm: normIco,
      name: snapshot?['name_current'] ?? '',
      status: snapshot?['status_current'] ?? '',
      street: address?['street'] ?? '',
      city: address?['city'] ?? '',
      postalCode: address?['postalCode'] ?? '',
      dic: identifiers?['dic'],
      icDph: identifiers?['ic_dph'],
      isRateLimited: false,
      cachedAt: DateTime.now(),
    );
  }

  // --- Getters ---

  bool get isValid => name.isNotEmpty;
  
  String get fullAddress {
    final parts = [street, postalCode, city].where((s) => s.isNotEmpty).toList();
    return parts.join(', ');
  }
}
