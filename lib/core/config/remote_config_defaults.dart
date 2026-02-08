/// Default values for Firebase Remote Config
/// These are used when remote config fetch fails or app is offline
class RemoteConfigDefaults {
  static const Map<String, dynamic> defaults = {
    // App maintenance
    'maintenance_mode': false,
    'maintenance_message': 'Aplikácia je momentálne v údržbe. Skúste to prosím neskôr.',
    
    // Version control
    'min_app_version': '1.0.0',
    'latest_app_version': '1.0.2',
    'force_update': false,
    'update_message': 'Nová verzia aplikácie je k dispozícii!',
    
    // Feature flags
    'feature_ai_enabled': true,
    'feature_backup_enabled': true,
    'feature_multi_currency_enabled': true,
    'feature_dark_mode_enabled': true,
    'feature_receipt_scan_enabled': true,
    
    // AI Configuration
    'ai_max_tokens': 500,
    'ai_temperature': 0.7,
    'ai_model': 'gpt-3.5-turbo',
    
    // Limits
    'max_invoices_per_month': -1, // -1 = unlimited
    'max_expenses_per_month': -1,
    'max_file_size_mb': 10,
    'max_backup_size_mb': 100,
    
    // Analytics
    'analytics_enabled': true,
    'crashlytics_enabled': true,
    'performance_monitoring_enabled': true,
    
    // API endpoints
    'finstat_api_enabled': true,
    'finstat_api_timeout_seconds': 10,
    
    // UI/UX
    'show_onboarding': true,
    'show_whats_new': false,
    'whats_new_version': '1.0.2',
    
    // Promotional
    'promo_banner_enabled': false,
    'promo_banner_text': '',
    'promo_banner_url': '',
    
    // Support
    'support_email': 'support@bizagent.app',
    'support_phone': '+421944637232',
    'faq_url': 'https://bizagent.app/faq',
    
    // Social
    'instagram_url': 'https://instagram.com/bizagent_app',
    'facebook_url': 'https://facebook.com/bizagentapp',
    
    // Legal
    'privacy_policy_url': 'https://bizagent.app/privacy',
    'terms_url': 'https://bizagent.app/terms',
  };
}
