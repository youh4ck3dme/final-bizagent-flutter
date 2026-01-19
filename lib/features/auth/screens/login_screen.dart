import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/biz_fullscreen_loader.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;

  late AnimationController _pulseController;
  late Animation<double> _glowAnimation;

  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _glowAnimation = Tween<double>(begin: 2.0, end: 12.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  // ... existing code ...

                    const SizedBox(height: 16),
                    // Google Sign In with Neon Orbit Effect
                    Center(
                      child: SizedBox(
                        height: 54, // Slightly larger than button for the glow
                        width: double.infinity,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 1. Rotating Neon Gradient
                            AnimatedBuilder(
                              animation: _rotationController,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: _rotationController.value * 2 * 3.14159,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      gradient: const SweepGradient(
                                        colors: [
                                          Color(0xFF4285F4), // Google Blue
                                          Color(0xFFDB4437), // Google Red
                                          Color(0xFFF4B400), // Google Yellow
                                          Color(0xFF0F9D58), // Google Green
                                          Color(0xFF4285F4), // Closing Loop
                                        ],
                                        stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF4285F4).withOpacity(0.4),
                                          blurRadius: 12,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            // 2. The Button (White Overlay)
                            Container(
                              margin: const EdgeInsets.all(2), // 2px border width
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10), // Slightly smaller radius
                              ),
                              child: OutlinedButton(
                                onPressed: authState.isLoading
                                    ? null
                                    : () async {
                                        await ref
                                            .read(authControllerProvider.notifier)
                                            .signInWithGoogle();
                                      },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  side: BorderSide.none, // Hide default border
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  backgroundColor: Colors.transparent, // Let Container color show
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: Image.asset('assets/icons/google_g.png'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Prihlásiť sa cez Google',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: authState.isLoading
                          ? null
                          : () {
                              setState(() {
                                _isLogin = !_isLogin;
                              });
                            },
                      child: Text(
                        _isLogin
                            ? 'Nemáte účet? Registrujte sa'
                            : 'Už máte účet? Prihláste sa',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (authState.isLoading)
            const BizFullscreenLoader(label: 'Prihlasujem...'),
        ],
      ),
    );
  }
}
