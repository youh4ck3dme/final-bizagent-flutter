import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/ocr_service.dart';
import '../../../core/ui/biz_theme.dart';

class AiToolsScreen extends ConsumerStatefulWidget {
  const AiToolsScreen({super.key});

  @override
  ConsumerState<AiToolsScreen> createState() => _AiToolsScreenState();
}

class _AiToolsScreenState extends ConsumerState<AiToolsScreen> {
  ParsedReceipt? _receipt;
  bool _isScanning = false;

  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final _vendorController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    _vendorController.dispose();
    super.dispose();
  }

  Future<void> _scan(ImageSource source) async {
    setState(() {
      _isScanning = true;
      _receipt = null;
      _amountController.clear();
      _dateController.clear();
      _vendorController.clear();
    });

    final ocrService = ref.read(ocrServiceProvider);
    final receipt = await ocrService.scanReceipt(source);

    if (mounted) {
      setState(() {
        _isScanning = false;
        _receipt = receipt;
        if (receipt != null) {
          _amountController.text = receipt.totalAmount ?? '';
          _dateController.text = receipt.date ?? '';
          _vendorController.text = receipt.vendorId ?? '';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.document_scanner, size: 48, color: BizTheme.slovakBlue),
                    SizedBox(height: 16),
                    Text(
                      'Skener Bločkov',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Odfote bloček a AI automaticky vyčíta údaje.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: InkWell(
                onTap: () => context.go('/ai-tools/email-generator'),
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 48, color: Colors.purple),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Email Generátor',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Vytvorte profesionálne e-maily (upomienky, ponuky) za pár sekúnd.',
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: InkWell(
                onTap: () => context.go('/ai-tools/expense-analysis'),
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.receipt_long, size: 48, color: BizTheme.successGreen),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DPH Asistent',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Overenie daňovej uznateľnosti a rizík pred zaúčtovaním.',
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: InkWell(
                onTap: () => context.go('/ai-tools/reminder-generator'),
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.notifications_active, size: 48, color: Colors.orange),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Generátor Upomienok',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Vytvorte citlivé alebo prísne upomienky jediným kliknutím.',
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shadowColor: BizTheme.slovakBlue.withValues(alpha: 0.2),
              child: InkWell(
                onTap: () => context.go('/ai-tools/ico-lookup'),
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.business_search, size: 48, color: BizTheme.slovakBlue),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Overenie Firmy',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Rýchla kontrola IČO cez zabezpečený register.',
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _isScanning ? null : () => _scan(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Kamera'),
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _isScanning ? null : () => _scan(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galéria'),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_isScanning)
              const Center(child: CircularProgressIndicator())
            else if (_receipt != null)
              Card(
                color: Colors.grey.shade50,
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Rozpoznané údaje:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const Divider(),
                      TextField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'Suma',
                          suffixText: 'EUR',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _dateController,
                        decoration: const InputDecoration(
                          labelText: 'Dátum',
                          hintText: 'DD.MM.YYYY',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _vendorController,
                        decoration: const InputDecoration(
                          labelText: 'IČO / ID',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ExpansionTile(
                        title: const Text('Zobraziť celý text'),
                        children: [SelectableText(_receipt!.originalText)],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            context.push('/create-expense',
                                extra: _receipt!.originalText);
                          },
                          child: const Text('Vytvoriť výdavok'),
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
    );
  }
}
