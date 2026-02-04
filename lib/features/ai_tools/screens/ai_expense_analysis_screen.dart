import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/ui/biz_theme.dart';

// UI Components following BizAgent's design patterns
class InsightCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final double? savings;
  final Duration delay;

  const InsightCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.savings,
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0, // BizAgent style is cleaner
      color: Theme.of(context).cardColor,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BizTheme.radiusLg),
        side: BorderSide(color: BizTheme.gray200.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(BizTheme.spacingMd),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(BizTheme.radiusMd),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: BizTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: BizTheme.gray600),
                  ),
                  if (savings != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: BizTheme.successGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(BizTheme.radiusSm),
                        border: Border.all(
                          color: BizTheme.successGreen.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.savings_outlined,
                            size: 14,
                            color: BizTheme.successGreen,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Možná úspora: ${savings!.toStringAsFixed(0)} €',
                            style: const TextStyle(
                              color: BizTheme.successGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: delay).fadeIn().slideY(begin: 0.1);
  }
}

class AiExpenseAnalysisScreen extends ConsumerStatefulWidget {
  const AiExpenseAnalysisScreen({super.key});

  @override
  ConsumerState<AiExpenseAnalysisScreen> createState() =>
      _AiExpenseAnalysisScreenState();
}

class _AiExpenseAnalysisScreenState
    extends ConsumerState<AiExpenseAnalysisScreen> {
  // Simulating async loading for the "Demo" experience
  // In real app, this would come from a FutureProvider
  bool _isLoading = true;
  final List<InsightCard> _insights = [];

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    // Simulate AI thinking
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _insights.addAll([
        const InsightCard(
          title: 'Cestovné náklady rastú',
          description:
              'Vaše výdavky na cestovanie stúpli o 40% tento mesiac. Zvážte online meetingy.',
          icon: Icons.trending_up,
          color: Colors.redAccent,
          savings: 150.0,
          delay: Duration(milliseconds: 100),
        ),
        const InsightCard(
          title: 'Lacnejšie kancelárske potreby',
          description:
              'Na základe vašich nákupov by ste hromadnou objednávkou ušetrili 50€.',
          icon: Icons.lightbulb_outline,
          color: Colors.amber,
          savings: 50.0,
          delay: Duration(milliseconds: 200),
        ),
        const InsightCard(
          title: 'Daňový Tip: Home Office',
          description:
              'Máte nárok na odpočet 230€ za energie pri práci z domu, ktorý ste si neuplatnili.',
          icon: Icons.account_balance,
          color: BizTheme.successGreen,
          savings: 230.0,
          delay: Duration(milliseconds: 300),
        ),
        const InsightCard(
          title: 'Internet a Telefón',
          description:
              'Váš operátor zvýšil ceny. Konkurencia ponúka podobný balík o 15€ lacnejšie.',
          icon: Icons.phonelink_setup,
          color: BizTheme.slovakBlue,
          savings: 180.0,
          delay: Duration(milliseconds: 400),
        ),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calculate total potential savings
    final totalSavings = _insights.fold<double>(
      0,
      (sum, item) => sum + (item.savings ?? 0),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Finančný Asistent'),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: BizTheme.slovakBlue),
                  const SizedBox(height: 24),
                  Text(
                    'Analyzujem vaše výdavky...',
                    style: Theme.of(context).textTheme.bodyLarge,
                  )
                      .animate(onPlay: (c) => c.repeat())
                      .shimmer(duration: 2.seconds),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.only(top: 16, bottom: 32),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smart Analýza',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'AI pohľad na optimalizáciu vašich nákladov.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: BizTheme.gray600,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Total Savings Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        BizTheme.successGreen,
                        BizTheme.successGreen.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(BizTheme.radiusLg),
                    boxShadow: [
                      BoxShadow(
                        color: BizTheme.successGreen.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.savings,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Možná ročná úspora',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${totalSavings.toStringAsFixed(0)} €',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().scale(delay: 100.ms),

                const SizedBox(height: 24),
                ..._insights,
              ],
            ),
    );
  }
}
