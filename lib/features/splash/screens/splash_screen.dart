import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/auth/providers/auth_repository.dart';
import '../../../features/intro/providers/onboarding_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  double _p = 0.06;
  Timer? _t;
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    // Start progress animation
    _t = Timer.periodic(const Duration(milliseconds: 60), (_) {
      if (!mounted) return;
      setState(() {
        if (_p < 0.95) {
          _p += (1.0 - _p) * 0.04;
        }
      });
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final onboardingState = ref.watch(onboardingProvider);

    // Listen to auth state changes and redirect accordingly
    ref.listen(authStateProvider, (previous, next) {
      if (!mounted) return;

      next.when(
        data: (user) {
          // Auth loaded successfully
          if (user != null) {
            // User is logged in, check onboarding
            final seenOnboarding = onboardingState.valueOrNull ?? false;
            if (!seenOnboarding) {
              context.go('/onboarding');
            } else {
              context.go('/dashboard');
            }
          } else {
            // No user, go to login
            context.go('/login');
          }
        },
        error: (error, stack) {
          // Auth error, go to login
          context.go('/login');
        },
        loading: () {
          // Still loading, stay on splash
        },
      );
    });

    // Also listen to onboarding changes
    ref.listen(onboardingProvider, (previous, next) {
      if (!mounted || authState.isLoading) return;

      final user = authState.valueOrNull;
      if (user != null) {
        final seenOnboarding = next.valueOrNull ?? false;
        if (!seenOnboarding) {
          context.go('/onboarding');
        } else {
          context.go('/dashboard');
        }
      }
    });

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              cs.surface,
              cs.primaryContainer.withValues(alpha: 0.1),
              cs.surface,
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Decorative background circles
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.primary.withValues(alpha: 0.03),
                ),
              ),
            ),

            FadeTransition(
              opacity: _opacityAnimation,
              child: ScaleTransition(
                scale: _pulseAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _FadeIn(
                      delay: const Duration(milliseconds: 200),
                      child: Image.asset(
                        'assets/icons/icoatlas-logo.png',
                        width: 150,
                        height: 150,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 120,
                      height: 120,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withValues(alpha: 0.1),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/icons/bizagent_logo.png',
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'BizAgent',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.0,
                                color: cs.onSurface,
                              ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Váš inteligentný AI asistent',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 64),
                    SizedBox(
                      width: 200,
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: _p,
                              minHeight: 6,
                              backgroundColor:
                                  cs.primaryContainer.withValues(alpha: 0.2),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(cs.primary),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Pripravujeme prostredie...',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: cs.onSurfaceVariant
                                      .withValues(alpha: 0.6),
                                  letterSpacing: 0.5,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Positioned(
              bottom: 48,
              child: Text(
                'v1.0.1+2',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FadeIn extends StatelessWidget {
  final Widget child;
  final Duration delay;

  const _FadeIn({required this.child, required this.delay});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
