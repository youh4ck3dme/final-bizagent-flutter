import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final currencyServiceProvider = Provider<CurrencyService>((ref) {
  return CurrencyService();
});

class CurrencyService {
  static const String _ecbUrl =
      'https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml';
  static const String _prefsKey = 'bizagent_exchange_rates';
  static const String _lastFetchedKey = 'bizagent_exchange_rates_date';

  Map<String, double> _rates = {'EUR': 1.0};
  DateTime? _lastFetched;

  CurrencyService() {
    _loadFromCache();
  }

  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_prefsKey);
    final dateString = prefs.getString(_lastFetchedKey);

    if (jsonString != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(jsonString);
        _rates = decoded.map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        );
        // Ensure EUR is always 1.0
        _rates['EUR'] = 1.0;
      } catch (e) {
        debugPrint('Error loading rates from cache: $e');
      }
    }

    if (dateString != null) {
      _lastFetched = DateTime.tryParse(dateString);
    }
  }

  Future<void> fetchExchangeRates() async {
    try {
      final response = await http.get(Uri.parse(_ecbUrl));

      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.body);
        final cubes = document.findAllElements('Cube');

        final newRates = <String, double>{'EUR': 1.0};

        for (var cube in cubes) {
          final currency = cube.getAttribute('currency');
          final rateStr = cube.getAttribute('rate');

          if (currency != null && rateStr != null) {
            final rate = double.tryParse(rateStr);
            if (rate != null) {
              newRates[currency] = rate;
            }
          }
        }

        if (newRates.length > 1) {
          _rates = newRates;
          _lastFetched = DateTime.now();
          await _saveToCache();
          debugPrint(
            'Exchange rates updated from ECB. loaded ${_rates.length} currencies.',
          );
        }
      } else {
        debugPrint('Failed to load exchange rates: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching exchange rates: $e');
    }
  }

  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(_rates));
      if (_lastFetched != null) {
        await prefs.setString(_lastFetchedKey, _lastFetched!.toIso8601String());
      }
    } catch (e) {
      debugPrint('Error saving rates to cache: $e');
    }
  }

  double getRate(String currency) {
    return _rates[currency] ?? 1.0;
  }

  double convertToEur(double amount, String currency) {
    if (currency == 'EUR') return amount;
    final rate = getRate(currency);
    if (rate == 0) return amount; // Should not happen with valid rates
    return amount / rate;
  }

  List<String> getAvailableCurrencies() {
    final cur = _rates.keys.toList();
    cur.sort();
    // Move EUR to top
    if (cur.contains('EUR')) {
      cur.remove('EUR');
      cur.insert(0, 'EUR');
    }
    // Popular ones next
    final popular = ['USD', 'CZK', 'GBP', 'HUF', 'PLN'];
    for (var p in popular.reversed) {
      if (cur.contains(p)) {
        cur.remove(p);
        cur.insert(1, p);
      }
    }
    return cur;
  }

  DateTime? get lastFetched => _lastFetched;
}
