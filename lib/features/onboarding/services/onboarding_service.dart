import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider na sledovanie stavu onboardingu
final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  return OnboardingService();
});

class OnboardingService {
  String _getKey(String baseKey, String userId) => '${baseKey}_$userId';

  static const String _keyDashboardTour = 'has_seen_dashboard_tour';
  static const String _keyExpensesTour = 'has_seen_expenses_tour';
  static const String _keyInvoicesTour = 'has_seen_invoices_tour';

  Future<bool> hasSeenDashboardTour(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_getKey(_keyDashboardTour, userId)) ?? false;
  }

  Future<void> markDashboardTourSeen(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_getKey(_keyDashboardTour, userId), true);
  }

  Future<bool> hasSeenExpensesTour(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_getKey(_keyExpensesTour, userId)) ?? false;
  }

  Future<void> markExpensesTourSeen(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_getKey(_keyExpensesTour, userId), true);
  }

  Future<bool> hasSeenInvoicesTour(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_getKey(_keyInvoicesTour, userId)) ?? false;
  }

  Future<void> markInvoicesTourSeen(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_getKey(_keyInvoicesTour, userId), true);
  }

  // Wrapper pre zobrazenie pomocou TutorialCoachMark (voliteľné, ak chceme logiku tu)
}
