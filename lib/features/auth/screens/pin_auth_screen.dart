import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import '../../../core/services/security_service.dart';
import '../../../core/ui/biz_theme.dart';
import '../../../shared/utils/biz_snackbar.dart';

enum PinMode { setup, verify, confirm }

class PinAuthScreen extends ConsumerStatefulWidget {
  final PinMode initialMode;
  final String? setupFirstPin; // For confirmation mode

  const PinAuthScreen({
    super.key,
    this.initialMode = PinMode.verify,
    this.setupFirstPin,
  });

  @override
  ConsumerState<PinAuthScreen> createState() => _PinAuthScreenState();
}

class _PinAuthScreenState extends ConsumerState<PinAuthScreen> {
  String _currentPin = '';
  late PinMode _mode;
  String? _tempPin;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _tempPin = widget.setupFirstPin;
  }

  void _onDigitPress(String digit) {
    if (_currentPin.length < 4) {
      setState(() => _currentPin += digit);
      if (_currentPin.length == 4) {
        _handleComplete();
      }
    }
  }

  void _onDelete() {
    if (_currentPin.isNotEmpty) {
      setState(
        () => _currentPin = _currentPin.substring(0, _currentPin.length - 1),
      );
    }
  }

  Future<void> _handleComplete() async {
    final security = ref.read(securityServiceProvider);

    if (_mode == PinMode.verify) {
      final success = await security.verifyPin(_currentPin);
      if (success) {
        if (mounted) context.pop(true);
      } else {
        setState(() => _currentPin = '');
        if (mounted) BizSnackbar.showError(context, 'Nesprávny PIN kód');
      }
    } else if (_mode == PinMode.setup) {
      // First step of setup
      setState(() {
        _tempPin = _currentPin;
        _currentPin = '';
        _mode = PinMode.confirm;
      });
    } else if (_mode == PinMode.confirm) {
      if (_currentPin == _tempPin) {
        await security.savePin(_currentPin);
        if (mounted) {
          BizSnackbar.showSuccess(context, 'PIN kód úspešne nastavený');
          context.pop(_currentPin);
        }
      } else {
        setState(() {
          _currentPin = '';
          _tempPin = null;
          _mode = PinMode.setup;
        });
        if (mounted) {
          BizSnackbar.showError(
            context,
            'PIN kódy sa nezhodujú. Skúste znova.',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    String title = 'Zadajte PIN';
    if (_mode == PinMode.setup) title = 'Nastavte si PIN';
    if (_mode == PinMode.confirm) title = 'Potvrďte PIN';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Premium Blurry Background
          Positioned.fill(
            child: Container(color: isDark ? Colors.black87 : Colors.white70),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(color: Colors.transparent),
            ),
          ),

          // Floating animated orbs for "Originality"
          _buildFloatingOrb(context, 100, 100, Colors.blue, 4),
          _buildFloatingOrb(context, 300, 500, Colors.purple, 6),

          SafeArea(
            child: Column(
              children: [
                const Spacer(),

                // Header
                Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ).animate().fadeIn().slideY(begin: -0.2),

                const SizedBox(height: 8),
                Text(
                  _mode == PinMode.verify
                      ? 'Zadajte prístupový kód pre BizAgent'
                      : 'Zvoľte si 4-miestny kód pre zabezpečenie dát',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.6,
                    ),
                  ),
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 48),

                // PIN Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final isActive = index < _currentPin.length;
                    return Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? BizTheme.slovakBlue
                            : (isDark ? Colors.white24 : Colors.black12),
                        border: Border.all(
                          color: isActive
                              ? BizTheme.slovakBlue
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ).animate(target: isActive ? 1 : 0).scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1.2, 1.2),
                        );
                  }),
                ),

                const Spacer(),

                // Numeric Keypad
                _buildKeypad(isDark),

                const SizedBox(height: 24),

                // Cancel
                TextButton(
                  onPressed: () => context.pop(null),
                  child: Text(
                    'ZRUŠIŤ',
                    style: TextStyle(
                      color: (isDark ? Colors.white : Colors.black87)
                          .withValues(alpha: 0.5),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypad(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['1', '2', '3'].map(_buildKey).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['4', '5', '6'].map(_buildKey).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['7', '8', '9'].map(_buildKey).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 72),
              _buildKey('0'),
              _buildDeleteKey(isDark),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildKey(String digit) {
    return InkWell(
      onTap: () => _onDigitPress(digit),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Text(
          digit,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.normal,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteKey(bool isDark) {
    return InkWell(
      onTap: _onDelete,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        child: Icon(
          Icons.backspace_outlined,
          color: (isDark ? Colors.white : Colors.black87).withValues(
            alpha: 0.7,
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingOrb(
    BuildContext context,
    double x,
    double y,
    Color color,
    int duration,
  ) {
    return Positioned(
      left: x,
      top: y,
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: 0.3),
              color.withValues(alpha: 0.01),
            ],
          ),
        ),
      ).animate(onPlay: (c) => c.repeat(reverse: true)).move(
            begin: const Offset(-20, -20),
            end: const Offset(20, 20),
            duration: duration.seconds,
            curve: Curves.easeInOut,
          ),
    );
  }
}
