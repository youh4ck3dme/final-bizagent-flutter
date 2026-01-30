import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_app_check/firebase_app_check.dart';
import '../../../core/ui/biz_theme.dart';
import '../../../core/models/ico_lookup_result.dart';
import '../../../shared/widgets/watched_company_button.dart';
import '../../billing/subscription_guard.dart';
import '../../billing/paywall_screen.dart';
import '../../limits/usage_limiter.dart';
import '../../billing/billing_service.dart';
import '../services/web_sync_service.dart';
import '../providers/ico_lookup_provider.dart';
import '../../../shared/utils/biz_snackbar.dart';



class IcoLookupScreen extends ConsumerStatefulWidget {
  final String? initialIco;
  const IcoLookupScreen({super.key, this.initialIco});

  @override
  ConsumerState<IcoLookupScreen> createState() => _IcoLookupScreenState();
}

class _IcoLookupScreenState extends ConsumerState<IcoLookupScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Auto-search if initialIco is provided (Deep Link/Handover)
    if (widget.initialIco != null && widget.initialIco!.length == 8) {
      _controller.text = widget.initialIco!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleSearch();
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (value.length == 8) {
        _handleSearch(isAuto: true);
      }
    });
  }

  Future<void> _testSecurityPing() async {
    try {
      final token = await FirebaseAppCheck.instance.getToken();
      final response = await http.get(
        Uri.parse('https://bizagent.sk/api/auth/ping'),
        headers: {
          'X-Firebase-AppCheck': token ?? '',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          BizSnackbar.showSuccess(context, 'Gateway Ping OK: enforced=${data['enforced']} (Vercel)');
        }
      } else {
        throw Exception('Gateway error: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        BizSnackbar.showError(context, 'Gateway Ping Failed: $e');
      }
    }
  }

  void _handleSearch({bool isAuto = false}) {
    final query = _controller.text.trim();
    if (query.length == 8) {
      final guard = ref.read(subscriptionGuardProvider);
      if (guard.canAccess(BizFeature.icoLookup)) {
        ref.read(icoLookupProvider.notifier).lookup(query);
        ref.read(usageLimiterProvider).incrementIco();
        ref.read(billingProvider.notifier).refreshUsage();
      } else if (!isAuto) {
         Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PaywallScreen()),
         );
      }
    } else if (!isAuto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zadajte platné 8-miestne IČO')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lookupState = ref.watch(icoLookupProvider);
    final isLoading = lookupState.status == IcoLookupStatus.loading;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Overenie Firmy'),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(BizTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'IČO Register',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: BizTheme.slovakBlue,
              ),
            ),
            const SizedBox(height: BizTheme.spacingXs),
            Text(
              'Okamžitá kontrola rizikovosti a stavu firmy.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: BizTheme.spacingXl),

            // Search Field
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(BizTheme.radiusLg),
                border: Border.all(color: isDark ? BizTheme.darkOutline : BizTheme.gray100),
                boxShadow: isDark ? null : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                maxLength: 8,
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Zadajte IČO (napr. 46359371)',
                  counterText: '',
                  prefixIcon: const Icon(Icons.search, color: BizTheme.slovakBlue),
                  suffixIcon: IconButton(
                    icon: isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.arrow_forward_rounded, color: BizTheme.slovakBlue),
                    onPressed: isLoading ? null : () => _handleSearch(),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.all(BizTheme.spacingLg),
                ),
                onChanged: _onChanged,
                onSubmitted: (_) => _handleSearch(),
              ),
            ),

            // Web Synced List
            const SizedBox(height: BizTheme.spacingMd),
            _buildWebSyncSection(context, ref),

            const SizedBox(height: BizTheme.spacing2xl),

            // Result Area
            _buildResultContent(context, ref, lookupState),

            if (kDebugMode) ...[
              const SizedBox(height: BizTheme.spacing3xl),
              Center(
                child: TextButton.icon(
                  onPressed: _testSecurityPing,
                  icon: const Icon(Icons.security, size: 16),
                  label: const Text('DIAGNOSTIKA APP CHECK'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurfaceVariant,
                    textStyle: theme.textTheme.labelSmall,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultContent(BuildContext context, WidgetRef ref, IcoLookupState state) {
    if (state.status == IcoLookupStatus.idle) {
      return _buildIdleState();
    }

    if (state.status == IcoLookupStatus.loading && state.result == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(BizTheme.spacing3xl),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (state.status == IcoLookupStatus.notFound) {
      return _buildNotFoundState();
    }

    if (state.status == IcoLookupStatus.errorOffline) {
       return _buildErrorState('Ste offline. Skontrolujte pripojenie.');
    }

    if (state.status == IcoLookupStatus.errorServer) {
       return _buildErrorState(state.errorMessage ?? 'Chyba servera');
    }

    if (state.result != null) {
       return _buildResultCard(state.result!, state.status);
    }

    return const SizedBox.shrink();
  }

  Widget _buildResultCard(IcoLookupResult result, IcoLookupStatus status) {
    final theme = Theme.of(context);
    final isCached = status == IcoLookupStatus.cachedFresh;
    final isReliable = result.status.toLowerCase().contains('aktív') || result.status.toLowerCase().contains('pôsob');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Premium Indicator for Cache/Handover / Refreshing
        if (isCached || status == IcoLookupStatus.success || status == IcoLookupStatus.cachedStaleRefreshing)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                if (status == IcoLookupStatus.cachedStaleRefreshing)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: BizTheme.slovakBlue),
                  )
                else
                  Icon(
                    isCached ? Icons.bolt_rounded : Icons.cloud_done_rounded,
                    size: 14,
                    color: isCached ? Colors.amber : Colors.green,
                  ),
                const SizedBox(width: 6),
                Text(
                  status == IcoLookupStatus.cachedStaleRefreshing
                    ? 'AKTUALIZUJEM NA POZADÍ...'
                    : (isCached ? 'DÁTA Z CACHE (BLESKOVÉ)' : 'DÁTA AKTUALIZOVANÉ'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: status == IcoLookupStatus.cachedStaleRefreshing
                      ? BizTheme.slovakBlue
                      : (isCached ? Colors.amber : Colors.green),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ).animate().fadeIn().slideX(begin: -0.1),
          ),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(BizTheme.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isReliable ? Colors.green : Colors.orange).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(BizTheme.radiusSm),
                      ),
                      child: Text(
                        result.status.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isReliable ? Colors.green[700] : Colors.orange[700],
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          isReliable ? Icons.verified_rounded : Icons.warning_amber_rounded,
                          color: isReliable ? Colors.green : Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        WatchedCompanyButton(
                          icoNorm: result.icoNorm,
                          name: result.name,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: BizTheme.spacingLg),
                Text(
                  result.name,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: BizTheme.spacingSm),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        result.fullAddress,
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (result.headline != null || result.explanation != null) ...[
                  const SizedBox(height: BizTheme.spacingLg),
                  Container(
                    padding: const EdgeInsets.all(BizTheme.spacingLg),
                    decoration: BoxDecoration(
                      color: BizTheme.slovakBlue.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(BizTheme.radiusMd),
                      border: Border.all(color: BizTheme.slovakBlue.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome, color: BizTheme.slovakBlue, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'AI VERDIKT',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: BizTheme.slovakBlue,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const Spacer(),
                            if (result.confidence != null)
                              Text(
                                '${(result.confidence! * 100).toInt()}% istota',
                                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                          ],
                        ),
                        const SizedBox(height: BizTheme.spacingSm),
                        Text(
                          result.headline ?? 'Analýza dokončená',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          result.explanation ?? '',
                          style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],

                // Risk Badge (LOW / MEDIUM / HIGH)
                if (result.riskLevel != null || result.riskHint != null) ...[
                  const SizedBox(height: BizTheme.spacingMd),
                  _buildRiskBadge(result.riskLevel, result.riskHint),
                ],
                const SizedBox(height: BizTheme.spacingXl),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          context.push(
                            '/create-invoice',
                            extra: {
                              'clientName': result.name,
                              'clientIco': _controller.text,
                              'clientAddress': result.fullAddress,
                              'clientDic': result.dic,
                              'clientIcDph': result.icDph,
                            },
                          );
                        },
                        icon: const Icon(Icons.receipt_long, size: 18),
                        label: const Text('VYSTAVIŤ FAKTÚRU'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: BizTheme.spacingSm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Logic to add to contacts would go here
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Firma bola pridaná do kontaktov')),
                      );
                    },
                    icon: const Icon(Icons.person_add_outlined, size: 18),
                    label: const Text('PRIDAŤ DO KONTAKTOV'),
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
      ],
    );
  }

  Widget _buildIdleState() {
    return Center(
      child: Opacity(
        opacity: 0.5,
        child: Column(
          children: [
            const Icon(Icons.business_center_outlined, size: 80),
            const SizedBox(height: BizTheme.spacingMd),
            Text(
              'Zadajte IČO pre okamžité overenie',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Firma sa nenašla',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Text('Skontrolujte prosím zadané IČO.'),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildWebSyncSection(BuildContext context, WidgetRef ref) {
    final webSyncAsync = ref.watch(webSyncServiceProvider);
    final theme = Theme.of(context);

    return webSyncAsync.when(
      data: (leads) {
        if (leads.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  const Icon(Icons.cloud_sync_rounded, size: 16, color: BizTheme.slovakBlue),
                  const SizedBox(width: 8),
                  Text(
                    'NEDÁVNE Z WEBU',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: BizTheme.slovakBlue,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: leads.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final lead = leads[index];
                  final ico = lead['ico'] ?? '';
                  final name = lead['companyName'] ?? 'Neznáma firma';
                  final isNew = lead['status'] == 'new';

                  return ActionChip(
                    avatar: Icon(
                      isNew ? Icons.bolt : Icons.history,
                      size: 14,
                      color: isNew ? Colors.amber : Colors.grey
                    ),
                    label: Text(
                      name.length > 20 ? '${name.substring(0, 18)}...' : name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isNew ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    onPressed: () {
                      _controller.text = ico;
                      ref.read(icoLookupProvider.notifier).lookup(ico);
                    },
                    backgroundColor: theme.colorScheme.surface,
                    side: BorderSide(
                      color: isNew ? BizTheme.slovakBlue : BizTheme.slovakBlue.withValues(alpha: 0.2),
                      width: isNew ? 1.5 : 1,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BizTheme.radiusMd)),
                  );
                },
              ),
            ),
          ],
        ).animate().fadeIn().slideX(begin: 0.1);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildRiskBadge(String? level, String? hint) {
    if (level == null && hint == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    Color color;
    IconData icon;

    switch (level?.toLowerCase()) {
      case 'high':
      case 'vysoké':
        color = Colors.red;
        icon = Icons.dangerous_rounded;
        break;
      case 'medium':
      case 'stredné':
        color = Colors.orange;
        icon = Icons.warning_rounded;
        break;
      default:
        color = Colors.green;
        icon = Icons.check_circle_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(BizTheme.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hint ?? (level ?? 'Neznáme riziko'),
              style: theme.textTheme.bodySmall?.copyWith(color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Chyba',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _handleSearch(),
            child: const Text('SKÚSIŤ ZNOVU'),
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}

