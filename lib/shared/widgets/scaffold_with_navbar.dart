import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ui/biz_theme.dart';
import '../../features/ai_tools/screens/biz_bot_screen.dart';
import '../../core/services/security_service.dart';
import '../../features/settings/models/user_settings_model.dart';
import '../../features/settings/providers/settings_provider.dart';
import '../../features/auth/screens/pin_auth_screen.dart';

class ScaffoldWithNavBar extends ConsumerStatefulWidget {
  const ScaffoldWithNavBar({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends ConsumerState<ScaffoldWithNavBar> {
  void _goBranch(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  void initState() {
    super.initState();
    _checkSecurity();
  }

  Future<void> _checkSecurity() async {
    // Wait for settings to load
    final settings = await ref.read(settingsProvider.future);
    final isUnlocked = ref.read(sessionUnlockedProvider);
    
    if (isUnlocked) return;

    if (settings.biometricEnabled || settings.pinEnabled) {
      _showSecurityChallenge(settings);
    } else {
      // No security enabled, unlock session automatically
      ref.read(sessionUnlockedProvider.notifier).state = true;
    }
  }

  Future<void> _showSecurityChallenge(UserSettingsModel settings) async {
    if (!mounted) return;

    if (settings.biometricEnabled) {
      final security = ref.read(securityServiceProvider);
      final success = await security.authenticateWithBiometrics();
      if (success) {
        ref.read(sessionUnlockedProvider.notifier).state = true;
        return;
      }
    }

    if (settings.pinEnabled) {
      final success = await showGeneralDialog<bool>(
        context: context,
        barrierDismissible: false,
        pageBuilder: (context, _, __) => const PinAuthScreen(initialMode: PinMode.verify),
      );
      
      if (success == true) {
        ref.read(sessionUnlockedProvider.notifier).state = true;
      } else {
        // If cancelled or failed, we stay locked.
        // User is effectively stuck on the locked screen until they authenticate.
      }
    } else if (!settings.biometricEnabled) {
       // Only reach here if biometric failed but PIN is not enabled
       // In a real app, we might fallback to login or similar.
       ref.read(sessionUnlockedProvider.notifier).state = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);
    final isUnlocked = ref.watch(sessionUnlockedProvider);

    if (!isUnlocked) {
      // Locked State - Premium "Original" Minimalist Look
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: BizTheme.slovakBlue),
              const SizedBox(height: 24),
              const Text(
                'BizAgent je uzamknutý',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _checkSecurity,
                icon: const Icon(Icons.lock_open),
                label: const Text('ODOMKNÚŤ'),
              ),
            ],
          ),
        ),
      );
    }

    // Breakpoints
    final isDesktop = width >= 1240;
    final isTablet = width >= 600 && width < 1240;
    final isMobile = width < 600;

    final destinations = [
      const NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      const NavigationDestination(
        icon: Icon(Icons.receipt_long_outlined),
        selectedIcon: Icon(Icons.receipt_long),
        label: 'Faktúry',
      ),
      const NavigationDestination(
        icon: Icon(Icons.attach_money),
        selectedIcon: Icon(Icons.attach_money),
        label: 'Výdavky',
      ),
      const NavigationDestination(
        icon: Icon(Icons.auto_awesome_outlined),
        selectedIcon: Icon(Icons.auto_awesome),
        label: 'AI Tools',
      ),
      const NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: 'Nastavenia',
      ),
    ];

    if (isMobile) {
      return Scaffold(
        body: widget.navigationShell,
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BizBotScreen()),
            );
          },
          backgroundColor: BizTheme.slovakBlue,
          child: const Icon(Icons.smart_toy_outlined, color: Colors.white),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: widget.navigationShell.currentIndex,
          onDestinationSelected: _goBranch,
          destinations: destinations,
          backgroundColor: theme.colorScheme.surface,
          elevation: 3,
          indicatorColor: theme.colorScheme.primaryContainer,
        ),
      );
    }
    
    return Scaffold(
      body: Row(
        children: [
          if (isTablet)
            NavigationRail(
              selectedIndex: widget.navigationShell.currentIndex,
              onDestinationSelected: _goBranch,
              labelType: NavigationRailLabelType.all,
              backgroundColor: theme.colorScheme.surface,
              indicatorColor: theme.colorScheme.primaryContainer,
              destinations: destinations.map((d) => NavigationRailDestination(
                icon: d.icon,
                selectedIcon: d.selectedIcon,
                label: Text(d.label),
              )).toList(),
            ),
            
          if (isDesktop)
            NavigationDrawer(
              selectedIndex: widget.navigationShell.currentIndex,
              onDestinationSelected: _goBranch,
              backgroundColor: theme.colorScheme.surface,
              indicatorColor: theme.colorScheme.primaryContainer,
              children: [
                 Padding(
                   padding: const EdgeInsets.all(BizTheme.spacingLg),
                   child: Text(
                     'BizAgent',
                     style: theme.textTheme.headlineSmall?.copyWith(
                       color: theme.colorScheme.primary, 
                       fontWeight: FontWeight.bold
                     ),
                   ),
                 ),
                 ...destinations.map((d) => NavigationDrawerDestination(
                  icon: d.icon,
                  selectedIcon: d.selectedIcon,
                  label: Text(d.label),
                )),
              ],
            ),
            
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: widget.navigationShell),
        ],
      ),
    );
  }
}
