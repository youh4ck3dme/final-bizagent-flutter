import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// PILIER #3: Free Tier Limits
/// FREE: 5 faktúr, 3 AI, 10 IČO / mesiac
/// PRO: neobmedzené
class UsageLimiter {
  static const String _kInvoiceCount = 'usage_invoice_count';
  static const String _kAiCount = 'usage_ai_count';
  static const String _kIcoCount = 'usage_ico_count';
  static const String _kLastReset = 'usage_last_reset';
  static const String _kIsPro = 'usage_is_pro';

  // FREE TIER LIMITS
  static const int maxFreeInvoices = 5;
  static const int maxFreeAi = 3;
  static const int maxFreeIco = 10;

  final SharedPreferences prefs;

  UsageLimiter(this.prefs);

  bool get isPro => prefs.getBool(_kIsPro) ?? false;
  int get invoiceCount => prefs.getInt(_kInvoiceCount) ?? 0;
  int get aiCount => prefs.getInt(_kAiCount) ?? 0;
  int get icoCount => prefs.getInt(_kIcoCount) ?? 0;

  int get invoicesRemaining => isPro ? 999 : (maxFreeInvoices - invoiceCount).clamp(0, maxFreeInvoices);
  int get aiRemaining => isPro ? 999 : (maxFreeAi - aiCount).clamp(0, maxFreeAi);
  int get icoRemaining => isPro ? 999 : (maxFreeIco - icoCount).clamp(0, maxFreeIco);

  bool get canCreateInvoice => isPro || invoiceCount < maxFreeInvoices;
  bool get canUseAi => isPro || aiCount < maxFreeAi;
  bool get canLookupIco => isPro || icoCount < maxFreeIco;

  Future<void> incrementInvoice() async {
    await prefs.setInt(_kInvoiceCount, invoiceCount + 1);
  }

  Future<void> incrementAi() async {
    await prefs.setInt(_kAiCount, aiCount + 1);
  }

  Future<void> incrementIco() async {
    await prefs.setInt(_kIcoCount, icoCount + 1);
  }

  Future<void> setPro(bool value) async {
    await prefs.setBool(_kIsPro, value);
  }

  Future<void> checkAndResetMonthly() async {
    final lastResetStr = prefs.getString(_kLastReset);
    final now = DateTime.now();

    if (lastResetStr != null) {
      final lastReset = DateTime.parse(lastResetStr);
      if (now.month != lastReset.month || now.year != lastReset.year) {
        await resetCounts();
      }
    } else {
      await prefs.setString(_kLastReset, now.toIso8601String());
    }
  }

  Future<void> resetCounts() async {
    await prefs.setInt(_kInvoiceCount, 0);
    await prefs.setInt(_kAiCount, 0);
    await prefs.setInt(_kIcoCount, 0);
    await prefs.setString(_kLastReset, DateTime.now().toIso8601String());
  }

  /// Show paywall if limit reached. Returns true if blocked.
  bool showPaywallIfNeeded(BuildContext context, LimitType type) {
    bool blocked = false;
    switch (type) {
      case LimitType.invoice:
        blocked = !canCreateInvoice;
        break;
      case LimitType.ai:
        blocked = !canUseAi;
        break;
      case LimitType.ico:
        blocked = !canLookupIco;
        break;
    }

    if (blocked) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => PaywallBottomSheet(limitType: type),
      );
    }

    return blocked;
  }
}

enum LimitType { invoice, ai, ico }

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize this in main.dart via overrides');
});

final usageLimiterProvider = Provider<UsageLimiter>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return UsageLimiter(prefs);
});

/// PILIER #3: Paywall Bottom Sheet
class PaywallBottomSheet extends StatelessWidget {
  const PaywallBottomSheet({super.key, required this.limitType});
  final LimitType limitType;

  String get _title {
    switch (limitType) {
      case LimitType.invoice:
        return 'Limit faktúr dosiahnutý';
      case LimitType.ai:
        return 'Limit AI analýz dosiahnutý';
      case LimitType.ico:
        return 'Limit IČO vyhľadávaní dosiahnutý';
    }
  }

  String get _subtitle {
    switch (limitType) {
      case LimitType.invoice:
        return 'Tento mesiac ste vytvorili 5 z 5 faktúr zadarmo.';
      case LimitType.ai:
        return 'Tento mesiac ste použili 3 z 3 AI analýz zadarmo.';
      case LimitType.ico:
        return 'Tento mesiac ste vyhľadali 10 z 10 IČO zadarmo.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Lock icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🔒', style: TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              _title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Subtitle
            Text(
              _subtitle,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // PRO features
            _ProFeature(icon: Icons.all_inclusive, text: 'Neobmedzené faktúry'),
            const SizedBox(height: 10),
            _ProFeature(icon: Icons.auto_awesome, text: '50+ AI akcií mesačne'),
            const SizedBox(height: 10),
            _ProFeature(icon: Icons.search, text: 'Neobmedzené IČO lookups'),
            const SizedBox(height: 10),
            _ProFeature(icon: Icons.picture_as_pdf, text: 'PDF bez watermarku'),
            const SizedBox(height: 10),
            _ProFeature(icon: Icons.speed, text: 'Prioritné spracovanie'),
            const SizedBox(height: 28),

            // CTA
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Navigate to in-app purchase
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PRO verzia bude čoskoro dostupná!'),
                      backgroundColor: Color(0xFF0B4EA2),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B4EA2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Prejsť na PRO – €9.99/mesiac',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Dismiss
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Pokračovať s Free verziou',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ProFeature extends StatelessWidget {
  const _ProFeature({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF0B4EA2).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: const Color(0xFF0B4EA2), size: 18),
        ),
        const SizedBox(width: 14),
        Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
      ],
    );
  }
}
