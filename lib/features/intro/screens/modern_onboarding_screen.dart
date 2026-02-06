import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/ui/biz_theme.dart';
import '../providers/onboarding_provider.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/demo_mode/demo_mode_service.dart';
import '../../../core/demo_mode/demo_scenarios.dart';

/// PILIER #1: Onboarding – 3 kroky k "AHA MOMENTU"
/// Step 1: PROBLÉM → Step 2: RIEŠENIE → Step 3: VÝSLEDOK
class ModernOnboardingScreen extends ConsumerStatefulWidget {
  const ModernOnboardingScreen({super.key});

  @override
  ConsumerState<ModernOnboardingScreen> createState() =>
      _ModernOnboardingScreenState();
}

class _ModernOnboardingScreenState
    extends ConsumerState<ModernOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsServiceProvider).logOnboardingStarted();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipToLogin() {
    _completeOnboarding();
  }

  void _tryDemo() {
    DemoModeService.instance.activateDemoMode(DemoScenario.standard);
    ref.read(onboardingProvider.notifier).completeOnboarding();
    ref.read(analyticsServiceProvider).logOnboardingCompleted();
    if (mounted) context.go('/dashboard');
  }

  Future<void> _completeOnboarding() async {
    await ref.read(onboardingProvider.notifier).completeOnboarding();
    ref.read(analyticsServiceProvider).logOnboardingCompleted();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  BizTheme.slovakBlue.withValues(alpha: 0.03),
                ],
              ),
            ),
          ),

          // Pages
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) => setState(() => _currentPage = index),
            children: const [
              _StepProblem(),
              _StepSolution(),
              _StepResult(),
            ],
          ),

          // Bottom Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.white,
                    Colors.white.withValues(alpha: 0.9),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Progress dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) => _Dot(
                        isActive: i == _currentPage,
                        isCompleted: i < _currentPage,
                      )),
                    ),
                    const SizedBox(height: 24),

                    // CTA Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _currentPage == 2 ? _tryDemo : _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BizTheme.slovakBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _currentPage == 0
                              ? 'Ukážte mi ako'
                              : _currentPage == 1
                                  ? 'Vyskúšajte naozaj'
                                  : 'Vyskúšať na reálnych dátach',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Secondary action
                    if (_currentPage == 2)
                      TextButton(
                        onPressed: _skipToLogin,
                        child: const Text(
                          'Mám účet – prihlásiť sa',
                          style: TextStyle(
                            color: BizTheme.slovakBlue,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      TextButton(
                        onPressed: _skipToLogin,
                        child: Text(
                          'Preskočiť',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 15,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// STEP 1: PROBLÉM
// ═══════════════════════════════════════════
class _StepProblem extends StatelessWidget {
  const _StepProblem();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(flex: 3),
          // Emoji icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: BizTheme.nationalRed.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('😩', style: TextStyle(fontSize: 48)),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Účtovníctvo\nvám kradne čas',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
              height: 1.15,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            'Faktúry, bločky, výdavky, IČO...\nVšetko ručne. Každý mesiac hodiny stratené.',
            style: TextStyle(
              fontSize: 17,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          // Pain points
          _PainPoint(icon: Icons.timer_off, text: '15 min na 1 faktúru'),
          const SizedBox(height: 12),
          _PainPoint(icon: Icons.error_outline, text: 'Chyby v údajoch'),
          const SizedBox(height: 12),
          _PainPoint(icon: Icons.money_off, text: 'Zabudnuté platby'),
          const Spacer(flex: 5),
        ],
      ),
    );
  }
}

class _PainPoint extends StatelessWidget {
  const _PainPoint({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: BizTheme.nationalRed, size: 22),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════
// STEP 2: RIEŠENIE
// ═══════════════════════════════════════════
class _StepSolution extends StatelessWidget {
  const _StepSolution();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(flex: 3),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: BizTheme.slovakBlue.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🤖', style: TextStyle(fontSize: 48)),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'BizAgent to robí\nza vás s AI',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
              height: 1.15,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            'Umelá inteligencia spracuje faktúry,\nbločky a firmy automaticky.',
            style: TextStyle(
              fontSize: 17,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _SolutionCard(
            icon: Icons.document_scanner,
            title: 'OCR skenovanie',
            subtitle: 'Ofoťte bloček → AI ho spracuje',
          ),
          const SizedBox(height: 12),
          _SolutionCard(
            icon: Icons.auto_awesome,
            title: 'AI kategorizácia',
            subtitle: 'Automatické triedenie výdavkov',
          ),
          const SizedBox(height: 12),
          _SolutionCard(
            icon: Icons.search,
            title: 'IČO lookup',
            subtitle: 'Údaje firmy za 1 sekundu',
          ),
          const Spacer(flex: 5),
        ],
      ),
    );
  }
}

class _SolutionCard extends StatelessWidget {
  const _SolutionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: BizTheme.slovakBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: BizTheme.slovakBlue.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: BizTheme.slovakBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: BizTheme.slovakBlue, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: BizTheme.successGreen, size: 22),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// STEP 3: VÝSLEDOK
// ═══════════════════════════════════════════
class _StepResult extends StatelessWidget {
  const _StepResult();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(flex: 3),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: BizTheme.successGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🚀', style: TextStyle(fontSize: 48)),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Ušetríte 10–20\nhodín mesačne',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
              height: 1.15,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            'Žiadne chyby. Žiadne zabudnuté platby.\nVšetko na jednom mieste.',
            style: TextStyle(
              fontSize: 17,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _ResultStat(
            number: '30s',
            label: 'na vytvorenie faktúry',
            color: BizTheme.slovakBlue,
          ),
          const SizedBox(height: 12),
          _ResultStat(
            number: '0',
            label: 'chýb v údajoch',
            color: BizTheme.successGreen,
          ),
          const SizedBox(height: 12),
          _ResultStat(
            number: '100%',
            label: 'platby pod kontrolou',
            color: BizTheme.warningAmber,
          ),
          const SizedBox(height: 28),
          // Free trial badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Začnite zadarmo – 5 faktúr/mesiac',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(flex: 5),
        ],
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  const _ResultStat({
    required this.number,
    required this.label,
    required this.color,
  });
  final String number;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.isActive, required this.isCompleted});
  final bool isActive;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 28 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: (isCompleted || isActive) ? BizTheme.slovakBlue : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
