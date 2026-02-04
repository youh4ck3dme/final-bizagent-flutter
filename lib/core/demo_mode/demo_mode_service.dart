import 'package:flutter/foundation.dart';
import '../../features/expenses/models/expense_model.dart';
import '../../features/invoices/models/invoice_model.dart';
import '../../features/proactive/models/proactive_alert_model.dart';
import '../../features/receipt_detective/models/reconstructed_suggestion_model.dart';
import 'demo_data_generator.dart';
import 'demo_scenarios.dart';

/// Demo mode pre prezentácie a testovanie BizAgent AI.
/// Aktivácia: triple tap na logo, secret gesture, alebo launch parameter.
class DemoModeService extends ChangeNotifier {
  DemoModeService._();
  static final DemoModeService _instance = DemoModeService._();
  static DemoModeService get instance => _instance;

  bool _isDemoMode = false;
  DemoScenario _currentScenario = DemoScenario.standard;

  bool get isDemoMode => _isDemoMode;
  DemoScenario get currentScenario => _currentScenario;

  /// Aktivuje demo mode s daným scenárom a vygeneruje demo dáta.
  void activateDemoMode(DemoScenario scenario) {
    _isDemoMode = true;
    _currentScenario = scenario;
    notifyListeners();
  }

  void deactivateDemoMode() {
    _isDemoMode = false;
    notifyListeners();
  }

  /// Prepnúť scenár (v demo mode).
  void setScenario(DemoScenario scenario) {
    if (!_isDemoMode) return;
    _currentScenario = scenario;
    notifyListeners();
  }

  /// Demo výdavky pre aktuálny scenár (použite v overrides providerov).
  List<ExpenseModel> getDemoExpenses() {
    return DemoDataGenerator.generateExpenses(_currentScenario);
  }

  /// Demo faktúry pre aktuálny scenár.
  List<InvoiceModel> getDemoInvoices() {
    return DemoDataGenerator.generateInvoices(_currentScenario);
  }

  /// Demo proaktívne alerty (priamo z generátora, bez reálneho TaxThermometer).
  List<ProactiveAlert> getDemoAlerts() {
    return DemoDataGenerator.generateProactiveAlerts(_currentScenario);
  }

  /// Demo návrhy Bloček Detective.
  List<ReconstructedExpenseSuggestion> getDemoSuggestions() {
    return DemoDataGenerator.generateReconstructedSuggestions(_currentScenario);
  }

  /// Počet triple-tapov (pre aktiváciu na logo).
  int _tripleTapCount = 0;
  DateTime? _lastTap;

  /// Zaznamenaj tap – ak 3x za 1.5 s, aktivuj demo (standard scenár).
  void recordLogoTap() {
    final now = DateTime.now();
    if (_lastTap != null && now.difference(_lastTap!).inMilliseconds > 1500) {
      _tripleTapCount = 0;
    }
    _lastTap = now;
    _tripleTapCount++;
    if (_tripleTapCount >= 3) {
      _tripleTapCount = 0;
      if (!_isDemoMode) {
        activateDemoMode(DemoScenario.standard);
      } else {
        deactivateDemoMode();
      }
    }
  }
}
