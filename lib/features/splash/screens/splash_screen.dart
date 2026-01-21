import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/auth/providers/auth_repository.dart';
import '../../../features/intro/providers/onboarding_provider.dart';

import '../../../core/ui/biz_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Check auth after a short delay to allow the "loading" animation to be seen
    // and ensuring the widget system is ready.
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _checkAuth();
      }
    });
  }

  void _checkAuth() {
     final authState = ref.read(authStateProvider);
     final onboardingState = ref.read(onboardingProvider);
     
     if (authState.valueOrNull != null) {
       if (onboardingState.valueOrNull == true) {
         context.go('/dashboard');
       } else {
         context.go('/onboarding');
       }
     } else {
       context.go('/login');
     }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to changes to handle async auth loading if it happens while on splash
    ref.listen(authStateProvider, (previous, next) {
      if (next.valueOrNull != null) {
         _checkAuth();
      } else if (next.hasError) {
         context.go('/login');
      }
    });

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 0. Unified Global Background
          Image.asset(
            'assets/images/background_fusion.webp',
            fit: BoxFit.cover,
          ),

          // 1. Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120, // Slightly larger
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Image.asset('assets/icon/app_icon_1024.png'),
                ),
                const SizedBox(height: 40),
                
                // Minimalist Loader using TweenAnimationBuilder
                SizedBox(
                  width: 160,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(seconds: 2),
                      curve: Curves.easeInOut,
                      builder: (context, value, _) {
                        return LinearProgressIndicator(
                          value: value,
                          minHeight: 4,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            BizTheme.slovakBlue,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Version info
          Positioned(
            bottom: 40,
            child: Text(
              'v1.0.1+2',
              style: TextStyle(
                color: const Color(0xFF64748B).withValues(alpha: 0.6),
                fontSize: 12,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w500,
                fontFamily: 'Inter', // Direct generic font family fallback
              ),
            ),
          ),
        ],
      ),
    );
  }
}
