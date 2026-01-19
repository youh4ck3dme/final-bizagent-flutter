import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/onboarding_provider.dart';
import '../../auth/providers/auth_repository.dart';
import '../../../core/services/analytics_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingContent> _contents = [
    OnboardingContent(
      title: 'Inteligentná\nFakturácia',
      description:
          'Zabudnite na zdĺhavé vypisovanie. Vytvárajte profesionálne faktúry za pár sekúnd s automatickým prepojením na databázu firiem.',
      svgPath: 'assets/icons/onboarding_invoice.svg', // SVG path
      accentColor: const Color(0xFF2563EB), // Premium Blue
    ),
    OnboardingContent(
      title: 'Umelá\nInteligencia',
      description:
          'Váš osobný AI asistent prečíta bločky, vytriedi výdavky a dokonca za vás napíše profesionálne e-maily klientom.',
      svgPath: 'assets/icons/onboarding_ai.svg', // SVG path
      accentColor: const Color(0xFF7C3AED), // Royal Purple
    ),
    OnboardingContent(
      title: 'Finančný\nPrehľad',
      description:
          'Majte dokonalý prehľad o cash-flow. Sledujte, kto vám dlhuje, a automatizujte upomienky jedným klikom.',
      svgPath: 'assets/icons/onboarding_chart.svg', // SVG path
      accentColor: const Color(0xFFEA580C), // Vibrant Orange
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsServiceProvider).logOnboardingSeen();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Force light status bar for white background
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Content
          SafeArea(
            child: Column(
              children: [
                // Top Spacer / Skip button area
                const SizedBox(height: 16),

                const Spacer(flex: 1),

                // Page View
                Expanded(
                  flex: 12,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _contents.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return _OnboardingPage(content: _contents[index]);
                    },
                  ),
                ),

                const Spacer(flex: 1),

                // Bottom Controls
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Indicators
                          Row(
                            children: List.generate(
                              _contents.length,
                              (index) => _AnimatedDot(
                                isActive: index == _currentPage,
                                color: _contents[_currentPage].accentColor,
                              ),
                            ),
                          ),

                          // Floating Action Button
                          _AnimatedNextButton(
                            isLast: _currentPage == _contents.length - 1,
                            color: _contents[_currentPage].accentColor,
                            onPressed: () {
                              if (_currentPage == _contents.length - 1) {
                                ref
                                    .read(onboardingProvider.notifier)
                                    .completeOnboarding();
                              } else {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.fastOutSlowIn,
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Demo Mode Button (Anonymous Auth)
                      TextButton(
                        onPressed: () async {
                          // Log tracking
                          ref
                              .read(analyticsServiceProvider)
                              .logTryWithoutRegistration();

                          // Trigger anonymous login
                          await ref
                              .read(authRepositoryProvider)
                              .signInAnonymously();
                          // Onboarding completion is handled by auth state change listener in main app
                          // but we might need to mark onboarding as seen if logic differs
                          ref
                              .read(onboardingProvider.notifier)
                              .completeOnboarding();
                        },
                        child: Text(
                          "vyskúšať bez registrácie",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final OnboardingContent content;

  const _OnboardingPage({required this.content});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center, // Centered alignment
              children: [
                const SizedBox(height: 20),
                // SVG Illustration Container
                SizedBox(
                  height: 300,
                  width: constraints.maxWidth,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glow effect behind SVG
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: content.accentColor.withValues(alpha: 0.1),
                          boxShadow: [
                            BoxShadow(
                              color: content.accentColor.withValues(alpha: 0.1),
                              blurRadius: 60,
                              spreadRadius: 20,
                            ),
                          ],
                        ),
                      ),
                      SvgPicture.asset(
                        content.svgPath,
                        height: 280,
                        // width property removed to allow flexible width in small screens
                        fit: BoxFit.contain, 
                        placeholderBuilder: (context) =>
                            const Center(child: CircularProgressIndicator()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Title
                Text(
                  content.title,
                  textAlign: TextAlign.center, // Center text
                  style: GoogleFonts.outfit(
                    fontSize: 42,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 24),

                // Description
                Text(
                  content.description,
                  textAlign: TextAlign.center, // Center text
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    height: 1.6,
                    color: const Color(0xFF4B5563),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      }
    );
  }
}

class _AnimatedDot extends StatelessWidget {
  final bool isActive;
  final Color color;

  const _AnimatedDot({required this.isActive, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 8),
      height: 8,
      width: isActive ? 32 : 8,
      decoration: BoxDecoration(
        color: isActive ? color : const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _AnimatedNextButton extends StatelessWidget {
  final bool isLast;
  final Color color;
  final VoidCallback onPressed;

  const _AnimatedNextButton({
    required this.isLast,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 64,
        width: isLast ? 160 : 64,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedOpacity(
              opacity: isLast ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 28),
            ),
            AnimatedOpacity(
              opacity: isLast ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Začať",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle_outline_rounded,
                      color: Colors.white, size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingContent {
  final String title;
  final String description;
  final String svgPath; // Replaced IconData with svgPath
  final Color accentColor;

  OnboardingContent({
    required this.title,
    required this.description,
    required this.svgPath,
    required this.accentColor,
  });
}
