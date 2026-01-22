import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/ui/biz_theme.dart';
import '../../../core/services/icoatlas_service.dart';
import '../../../core/models/ico_lookup_result.dart';

final icoLookupProvider = StateParametersProvider<AsyncValue<IcoLookupResult?>, String>((ref, ico) async {
  if (ico.length < 8) return const AsyncValue.data(null);
  
  final service = ref.read(icoAtlasServiceProvider);
  final result = await service.publicLookup(ico);
  return AsyncValue.data(result);
});

// Since StateParametersProvider doesn't exist in standard Riverpod, I'll use a simple StateProvider + FutureProvider approach
final icoSearchQueryProvider = StateProvider<String>((ref) => '');

final icoLookupFutureProvider = FutureProvider<IcoLookupResult?>((ref) async {
  final query = ref.watch(icoSearchQueryProvider);
  if (query.length < 8) return null;
  
  final service = ref.read(icoAtlasServiceProvider);
  return await service.publicLookup(query);
});

class IcoLookupScreen extends ConsumerStatefulWidget {
  const IcoLookupScreen({super.key});

  @override
  ConsumerState<IcoLookupScreen> createState() => _IcoLookupScreenState();
}

class _IcoLookupScreenState extends ConsumerState<IcoLookupScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isSearching = false;

  void _handleSearch() {
    final query = _controller.text.trim();
    if (query.length == 8) {
      ref.read(icoSearchQueryProvider.notifier).state = query;
      setState(() => _isSearching = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zadajte platné 8-miestne IČO')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lookupAsync = ref.watch(icoLookupFutureProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Overenie Firmy', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, BizTheme.fusionAzure.withValues(alpha: 0.05)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'IČO Register',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: BizTheme.slovakBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Okamžitá kontrola rizikovosti a stavu firmy.',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              
              // Search Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  decoration: InputDecoration(
                    hintText: 'Zadajte IČO (napr. 35742364)',
                    counterText: '',
                    prefixIcon: const Icon(Icons.search, color: BizTheme.slovakBlue),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_forward, color: BizTheme.slovakBlue),
                      onPressed: _handleSearch,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(20),
                  ),
                  onSubmitted: (_) => _handleSearch(),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Result Area
              lookupAsync.when(
                data: (result) {
                  if (result == null) {
                    return _buildEmptyState();
                  }
                  if (result.isRateLimited) {
                    return _buildRateLimitedState(result.resetIn);
                  }
                  return _buildResultCard(result);
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(color: BizTheme.slovakBlue),
                  ),
                ),
                error: (e, _) => _buildErrorState(e.toString()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(IcoLookupResult result) {
    final isReliable = result.status.toLowerCase().contains('aktív') || result.status.toLowerCase().contains('pôsob');
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: BizTheme.slovakBlue.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: BizTheme.slovakBlue.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isReliable ? Colors.green[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  result.status.toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: isReliable ? Colors.green[700] : Colors.orange[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              Icon(
                isReliable ? Icons.verified : Icons.warning_amber_rounded,
                color: isReliable ? Colors.green : Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            result.name,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                result.city,
                style: GoogleFonts.outfit(color: Colors.grey[600]),
              ),
            ],
          ),
          if (result.riskHint != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BizTheme.richCrimson.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: BizTheme.richCrimson.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt, color: BizTheme.richCrimson, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      result.riskHint!,
                      style: GoogleFonts.outfit(
                        color: BizTheme.richCrimson,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Future: Generate full report
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: BizTheme.slovakBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Zobraziť detailný report'),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildRateLimitedState(int? resetIn) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        children: [
          const Icon(Icons.timer_outlined, size: 48, color: Colors.orange),
          const SizedBox(height: 16),
          Text(
            'Limit dosiahnutý',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.orange[900],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bezplatný limit pre verejné vyhľadávanie je 10 dopytov za 10 minút.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: Colors.orange[800]),
          ),
          if (resetIn != null) ...[
            const SizedBox(height: 16),
            Text(
              'Skúste to znova o ${resetIn ~/ 60} minút.',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.orange[900]),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // CTA to upgrade
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Prejsť na PREMIUM (bez limitov)'),
          ),
        ],
      ),
    ).animate().shake();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.business_search, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 16),
          Text(
            'Zadajte IČO pre okamžité overenie',
            style: GoogleFonts.outfit(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          'Vyskytla sa chyba: $error',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(color: Colors.red[400]),
        ),
      ),
    );
  }
}
