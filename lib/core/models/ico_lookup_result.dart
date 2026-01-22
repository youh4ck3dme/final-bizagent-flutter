class IcoLookupResult {
  final String name;
  final String status;
  final String street;
  final String city;
  final String postalCode;
  final String? dic;
  final String? icDph;
  final String? riskHint;
  final int? resetIn; // seconds until rate limit resets
  final bool isRateLimited;
  final bool isPaymentRequired;

  IcoLookupResult({
    required this.name,
    required this.status,
    this.street = '',
    required this.city,
    this.postalCode = '',
    this.dic,
    this.icDph,
    this.riskHint,
    this.resetIn,
    this.isRateLimited = false,
    this.isPaymentRequired = false,
  });

  factory IcoLookupResult.fromMap(Map<String, dynamic> map) {
    // Handle nested address if present (from IcoAtlasSummary)
    final addr = map['address'] as Map<String, dynamic>?;
    
    return IcoLookupResult(
      name: map['name'] ?? '',
      status: map['status'] ?? '',
      street: addr?['street'] ?? '',
      city: addr?['city'] ?? map['city'] ?? '',
      postalCode: addr?['postalCode'] ?? '',
      dic: map['dic'],
      icDph: map['icDph'],
      riskHint: map['riskHint'] ?? (map['hints']?['riskHint']),
      resetIn: map['resetIn'] != null ? int.tryParse(map['resetIn'].toString()) : null,
      isRateLimited: false,
    );
  }

  factory IcoLookupResult.fromRealApi(Map<String, dynamic> json) {
    // Structure:
    // "identifiers": { "ico": "...", "dic": "...", "ic_dph": "..." }
    // "snapshot": { "name_current": "...", "status_current": "...", "address_current": { ... } }
    
    final identifiers = json['identifiers'] as Map<String, dynamic>?;
    final snapshot = json['snapshot'] as Map<String, dynamic>?;
    final address = snapshot?['address_current'] as Map<String, dynamic>?;

    return IcoLookupResult(
      name: snapshot?['name_current'] ?? '',
      status: snapshot?['status_current'] ?? '',
      street: address?['street'] ?? '',
      city: address?['city'] ?? '',
      postalCode: address?['postalCode'] ?? '',
      dic: identifiers?['dic'],
      icDph: identifiers?['ic_dph'],
      isRateLimited: false,
    );
  }

  factory IcoLookupResult.rateLimited({int? resetIn}) {
    return IcoLookupResult(
      name: '',
      status: 'Prekročený limit',
      city: '',
      resetIn: resetIn,
      isRateLimited: true,
      isPaymentRequired: false,
    );
  }

  factory IcoLookupResult.paymentRequired() {
    return IcoLookupResult(
      name: '',
      status: 'Vyžaduje sa platba',
      city: '',
      isRateLimited: false,
      isPaymentRequired: true,
    );
  }

  factory IcoLookupResult.empty() {
    return IcoLookupResult(
      name: '',
      status: '',
      city: '',
      isRateLimited: false,
      isPaymentRequired: false,
    );
  }

  String get fullAddress {
    final parts = [street, postalCode, city].where((s) => s.isNotEmpty).toList();
    return parts.join(', ');
  }
}
