import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _p = 0.06;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    // Fake progress: rýchlo do 90%, potom drží
    _t = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!mounted) return;
      setState(() {
        if (_p < 0.90) {
          _p += (0.90 - _p) * 0.06;
        } else {
          _t?.cancel();
          // GoRouter handles redirection based on auth & onboarding state
          // so we just trigger a refresh of the router location
          context.go('/dashboard'); 
        }
      });
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                      side: BorderSide(
                        color: cs.outlineVariant.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    color: cs.surfaceContainerLowest,
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: SvgPicture.asset(
                              'assets/icons/bizagent_logo.svg',
                              semanticsLabel: 'BizAgent logo',
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'BizAgent',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'AI Business Assistant pre SZČO',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 32),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: _p,
                                  minHeight: 8,
                                  backgroundColor: cs.surfaceContainerHigh,
                                  valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Center(
                                child: Text(
                                  'Pripravujeme vaše dáta...',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 32,
              child: Text(
                'v1.0.0',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
