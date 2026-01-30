import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/core/services/gemini_service.dart';

void main() {
  test('GeminiService Vercel migration smoke test', () {
    // New constructor has no dependencies (uses internal singletons/statics)
    // and calls Vercel Gateway.
    final service = GeminiService();
    expect(service, isNotNull);
  });
}
