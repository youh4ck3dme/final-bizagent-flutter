import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/gemini_service.dart';

// Onboarding Status
final onboardingProvider =
    NotifierProvider<OnboardingNotifier, AsyncValue<bool>>(() {
  return OnboardingNotifier();
});

class OnboardingNotifier extends Notifier<AsyncValue<bool>> {
  @override
  AsyncValue<bool> build() {
    _loadStatus();
    return const AsyncValue.loading();
  }

  static const _key = 'seen_onboarding';

  Future<void> _loadStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool(_key) ?? false;
      state = AsyncValue.data(seen);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
      state = const AsyncValue.data(true);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// Demo Data Generation
final onboardingDemoProvider = NotifierProvider<OnboardingDemoNotifier,
    AsyncValue<OnboardingDemoData?>>(() {
  return OnboardingDemoNotifier();
});

class OnboardingDemoNotifier
    extends Notifier<AsyncValue<OnboardingDemoData?>> {
  @override
  AsyncValue<OnboardingDemoData?> build() => const AsyncValue.data(null);

  Future<void> generateDemoInvoice(String businessType) async {
    state = const AsyncValue.loading();

    try {
      final geminiService = ref.read(geminiServiceProvider);
      const prompt = 'Vytvor ukážkovú faktúru...'; // Simplified for now

      // In a real scenario, we'd use the full prompt from before
      final response = await geminiService.analyzeJson(prompt, '{}');
      final invoiceData = response as Map<String, dynamic>;

      final demoData = OnboardingDemoData(
        businessType: businessType,
        generatedInvoice: invoiceData,
        suggestedFeatures: ['AI skenovanie'],
        generatedAt: DateTime.now(),
      );

      state = AsyncValue.data(demoData);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

class OnboardingDemoData {
  final String businessType;
  final Map<String, dynamic> generatedInvoice;
  final List<String> suggestedFeatures;
  final DateTime generatedAt;

  OnboardingDemoData({
    required this.businessType,
    required this.generatedInvoice,
    required this.suggestedFeatures,
    required this.generatedAt,
  });
}
