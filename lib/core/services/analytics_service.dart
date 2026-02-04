import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseAnalyticsProvider = Provider<FirebaseAnalytics>(
  (ref) => FirebaseAnalytics.instance,
);

final analyticsServiceProvider = Provider(
  (ref) => AnalyticsService(ref.read(firebaseAnalyticsProvider)),
);

class AnalyticsService {
  final FirebaseAnalytics _analytics;

  AnalyticsService(this._analytics);

  // Generic log method
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    await _analytics.logEvent(
      name: name,
      parameters: parameters?.cast<String, Object>(),
    );
  }

  // Scan Funnel
  Future<void> logScanStarted() async {
    await logEvent('scan_started');
  }

  Future<void> logScanSuccess(String vendor) async {
    await logEvent('scan_success', parameters: {'vendor': vendor});
  }

  Future<void> logExpenseCreated(double amount, String category) async {
    await logEvent(
      'expense_created',
      parameters: {'amount': amount, 'category': category},
    );
  }

  // Invoice Funnel
  Future<void> logInvoiceCreated(double amount) async {
    await logEvent('invoice_created', parameters: {'amount': amount});
  }

  Future<void> logQrShared() async {
    await logEvent('qr_shared');
  }

  // Onboarding Funnel
  Future<void> logOnboardingSeen() async {
    await logEvent('onboarding_seen');
  }

  Future<void> logOnboardingStarted() async {
    await logEvent('onboarding_started');
  }

  Future<void> logOnboardingCompleted() async {
    await logEvent('onboarding_completed');
  }

  Future<void> logTryWithoutRegistration() async {
    await logEvent('try_no_reg');
  }

  // Voice Expense Funnel
  Future<void> logVoiceExpenseStarted() async {
    await logEvent('voice_expense_started');
  }

  Future<void> logVoiceExpenseCompleted({required bool success}) async {
    await logEvent('voice_expense_completed', parameters: {'success': success});
  }

  // App Lifecycle
  Future<void> logAppOpen() async {
    await _analytics.logAppOpen();
  }

  // PDF Reports
  Future<void> logReportGenerated(String period) async {
    await logEvent('report_generated', parameters: {'period': period});
  }

  Future<void> logReportShared(String format) async {
    await logEvent('report_shared', parameters: {'format': format});
  }

  // AI Features
  Future<void> logAiAnalysisStarted(String type) async {
    await logEvent('ai_analysis_started', parameters: {'type': type});
  }

  Future<void> logAiAnalysisCompleted(
    String type, {
    bool success = true,
  }) async {
    await logEvent(
      'ai_analysis_completed',
      parameters: {'type': type, 'success': success},
    );
  }

  Future<void> logIcoLookup({required bool success}) async {
    await logEvent('ico_lookup', parameters: {'success': success});
  }

  // Notifications
  Future<void> logNotificationViewed(String type) async {
    await logEvent('notification_viewed', parameters: {'type': type});
  }

  Future<void> logNotificationActed(String action) async {
    await logEvent('notification_acted', parameters: {'action': action});
  }

  // Settings
  Future<void> logSettingsChanged(String setting) async {
    await logEvent('settings_changed', parameters: {'setting': setting});
  }

  Future<void> logLogoUploaded() async {
    await logEvent('logo_uploaded');
  }

  // Feature Usage
  Future<void> logFeatureUsed(String feature) async {
    await logEvent('feature_used', parameters: {'feature': feature});
  }

  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  // Errors & Performance
  Future<void> logError(String errorType, String message) async {
    await logEvent(
      'app_error',
      parameters: {
        'error_type': errorType,
        'message': message.substring(
          0,
          message.length > 100 ? 100 : message.length,
        ),
      },
    );
  }

  // User Properties
  Future<void> setUserProperty(String name, String value) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(id: userId);
  }
}
