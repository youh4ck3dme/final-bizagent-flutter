class IcoLookupResult {
  final String name;
  final String status;
  final String city;
  final String? riskHint;
  final int? resetIn; // seconds until rate limit resets
  final bool isRateLimited;
  final bool isPaymentRequired;

  IcoLookupResult({
    required this.name,
    required this.status,
    required this.city,
    this.riskHint,
    this.resetIn,
    this.isRateLimited = false,
    this.isPaymentRequired = false,
  });

  factory IcoLookupResult.fromMap(Map<String, dynamic> map) {
    return IcoLookupResult(
      name: map['name'] ?? '',
      status: map['status'] ?? '',
      city: map['city'] ?? '',
      riskHint: map['riskHint'],
      resetIn: map['resetIn'] != null ? int.tryParse(map['resetIn'].toString()) : null,
      isRateLimited: false,
    );
  }

  factory IcoLookupResult.rateLimited({int? resetIn}) {
    return IcoLookupResult(
      name: '',
      status: 'Rate Limited',
      city: '',
      resetIn: resetIn,
      isRateLimited: true,
      isPaymentRequired: false,
    );
  }

  factory IcoLookupResult.paymentRequired() {
    return IcoLookupResult(
      name: '',
      status: 'Payment Required',
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
}
