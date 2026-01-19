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

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _animationController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _animationController.forward();
        }
      });

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
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 0. Unified Global Background
          Image.asset(
            'assets/images/background_fusion.jpg',
            fit: BoxFit.cover,
          ),

          // 1. Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeTransition(
                  opacity: _opacityAnimation,
                  child: ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 140, // Slightly larger
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(35),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withOpacity(0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Image.asset('assets/icon/app_icon_1024.png'), // Use main app icon
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Minimalist Loader
                SizedBox(
                  width: 160,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _p,
                      minHeight: 4,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Version info (kept discrete)
          Positioned(
            bottom: 40,
            child: Text(
              'v1.0.1+2',
              style: GoogleFonts.inter(
                color: const Color(0xFF64748B).withOpacity(0.6),
                fontSize: 12,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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
