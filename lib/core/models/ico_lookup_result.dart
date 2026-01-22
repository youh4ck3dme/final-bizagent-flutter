class IcoLookupResult {
  final String name;
  final String status;
  final String city;
  final String? riskHint;
  final int? resetIn; // seconds until rate limit resets
  final bool isRateLimited;

  IcoLookupResult({
    required this.name,
    required this.status,
    required this.city,
    this.riskHint,
    this.resetIn,
    this.isRateLimited = false,
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
    );
  }

  factory IcoLookupResult.empty() {
    return IcoLookupResult(
      name: '',
      status: '',
      city: '',
    );
  }
}
