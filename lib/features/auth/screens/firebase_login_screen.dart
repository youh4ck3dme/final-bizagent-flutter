import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_repository.dart';
import '../../../core/ui/biz_theme.dart';
import '../../../core/demo_mode/demo_mode_service.dart';
import '../../../core/demo_mode/demo_scenarios.dart';
import '../../../core/ui/biz_logo_mark.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

class FirebaseLoginScreen extends ConsumerStatefulWidget {
  const FirebaseLoginScreen({super.key});

  @override
  ConsumerState<FirebaseLoginScreen> createState() =>
      _FirebaseLoginScreenState();
}

class _FirebaseLoginScreenState extends ConsumerState<FirebaseLoginScreen> {
  bool _isSignIn = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Force light status bar for consistent design
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Vyplňte všetky polia');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .signIn(_emailController.text.trim(), _passwordController.text);
    } on FirebaseAuthException catch (e) {
      _showError(_getFirebaseErrorMessage(e.code));
    } catch (e) {
      _showError('Došlo k chybe: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUpWithEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Vyplňte všetky polia');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Heslá sa nezhodujú');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showError('Heslo musí mať aspoň 6 znakov');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .signUp(_emailController.text.trim(), _passwordController.text);
    } on FirebaseAuthException catch (e) {
      _showError(_getFirebaseErrorMessage(e.code));
    } catch (e) {
      _showError('Došlo k chybe: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: BizTheme.nationalRed),
    );
  }

  void _startDemoMode() {
    DemoModeService.instance.activateDemoMode(DemoScenario.standard);
    context.go('/dashboard');
  }

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Používateľ s týmto emailom neexistuje';
      case 'wrong-password':
        return 'Nesprávne heslo';
      case 'email-already-in-use':
        return 'Tento email je už registrovaný';
      case 'weak-password':
        return 'Heslo je príliš slabé';
      case 'invalid-email':
        return 'Neplatný email';
      case 'too-many-requests':
        return 'Príliš veľa pokusov. Skúste neskôr';
      default:
        return 'Došlo k chybe. Skúste znovu';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background (removed image with the "5")
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [BizTheme.gray50, BizTheme.silverMist],
              ),
            ),
          ),

          // Centered Login Card
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo Section (Brand logo - centralized widget)
                    const BizLogoMark(size: 120),

                    const SizedBox(height: 24),

                    // Title
                    Text(
                      'BizAgent',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      _isSignIn
                          ? 'Vitajte späť!\nPrihláste sa do svojho účtu'
                          : 'Začnite svoju\npodnikateľskú cestu',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: const Color(0xFF6B7280),
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Email Field
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.withValues(alpha: 0.05),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Password Field
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Heslo',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.withValues(alpha: 0.05),
                      ),
                    ),

                    // Confirm Password (only for sign up)
                    if (!_isSignIn) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Potvrďte heslo',
                          prefixIcon: const Icon(Icons.lock_reset_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.withValues(alpha: 0.05),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Sign In/Sign Up Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : (_isSignIn ? _signInWithEmail : _signUpWithEmail),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BizTheme.slovakBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          shadowColor: BizTheme.slovakBlue.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                _isSignIn ? 'Prihlásiť sa' : 'Vytvoriť účet',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // PILIER #2: Demo Button – bez registrácie
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => _startDemoMode(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: BizTheme.slovakBlue,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.play_circle_outline,
                              color: BizTheme.slovakBlue,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Vyskúšať bez registrácie',
                              style: GoogleFonts.inter(
                                color: BizTheme.slovakBlue,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'alebo',
                            style: TextStyle(
                              color: Colors.grey.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Google Sign In Button
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 56),
                      child: const GoogleSignInButton(
                        clientId:
                            '542280140779-c5m14rqpih1j9tmf9km52aq1684l9qjd.apps.googleusercontent.com',
                        loadingIndicator: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Toggle Sign In/Sign Up
                    TextButton(
                      onPressed: () => setState(() => _isSignIn = !_isSignIn),
                      child: Text(
                        _isSignIn
                            ? 'Nemáte účet? Vytvorte si ho'
                            : 'Už máte účet? Prihláste sa',
                        style: GoogleFonts.inter(
                          color: BizTheme.slovakBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // Dev Bypass (Only for debugging localhost)
                    if (kDebugMode) ...[
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () async {
                          await ref
                              .read(authRepositoryProvider)
                              .signInAnonymously();
                          if (!context.mounted) return;
                          context.go('/ai-tools/ico-lookup');
                        },
                        child: const Text(
                          'Preskočiť na overenie (Real Anon Login)',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Terms
                    Text(
                      'Používaním aplikácie súhlasíte s našimi podmienkami používania.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Top Promo Badge (same as onboarding)
          Positioned(
            top: 50,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    "7 Dní Zdarma",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
