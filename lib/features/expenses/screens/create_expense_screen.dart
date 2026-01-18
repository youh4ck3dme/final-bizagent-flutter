import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/services/ocr_service.dart';
import '../models/expense_model.dart';
import '../models/expense_category.dart';
import '../providers/expenses_provider.dart';
import '../services/categorization_service.dart';
import '../services/receipt_storage_service.dart';
import '../widgets/category_selector.dart';

class CreateExpenseScreen extends ConsumerStatefulWidget {
  final String? initialText;

  const CreateExpenseScreen({super.key, this.initialText});

  @override
  ConsumerState<CreateExpenseScreen> createState() =>
      _CreateExpenseScreenState();
}

class _CreateExpenseScreenState extends ConsumerState<CreateExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _vendorController;
  late TextEditingController _descController;
  late TextEditingController _amountController;
  DateTime _date = DateTime.now();
  
  // Kategorizácia
  ExpenseCategory? _selectedCategory;
  ExpenseCategory? _suggestedCategory;
  int? _suggestionConfidence;
  final _categorizationService = CategorizationService();
  String? _scannedReceiptPath;

  @override
  void initState() {
    super.initState();
    _vendorController = TextEditingController();
    _descController = TextEditingController(text: widget.initialText);
    _amountController = TextEditingController();

    // Try to extract amount from initial text if present
    if (widget.initialText != null) {
      _tryExtractAmount(widget.initialText!);
    }
    
    // Listen to vendor changes for auto-categorization
    _vendorController.addListener(_onVendorChanged);
  }
  
  void _onVendorChanged() {
    if (_vendorController.text.length >= 3) {
      final (category, confidence) = _categorizationService.suggestCategory(_vendorController.text);
      setState(() {
        _suggestedCategory = category;
        _suggestionConfidence = confidence;
        
        // Auto-select if confidence is high and no category selected yet
        if (confidence >= 85 && _selectedCategory == null) {
          _selectedCategory = category;
        }
      });
    }
  }

  void _tryExtractAmount(String text) {
    // Simple regex for currency like "12.50" or "12,50"
    final regex = RegExp(r'(\d+[.,]\d{2})');
    final match = regex.firstMatch(text);
    if (match != null) {
      String amountStr = match.group(0)!.replaceAll(',', '.');
      _amountController.text = amountStr;
    }
  }

  @override
  void dispose() {
    _vendorController.dispose();
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _scanReceipt() async {
    final ocrService = ref.read(ocrServiceProvider);
    final result = await ocrService.scanReceipt(ImageSource.camera);

    if (result != null && mounted) {
      setState(() {
        _scannedReceiptPath = result.imagePath; // Save image path
        _descController.text = result.originalText;
        if (result.totalAmount != null) {
          _amountController.text = result.totalAmount!;
        }
        if (result.vendorId != null) {
          _vendorController.text = result.vendorId!;
          // Trigger auto-categorization
          _onVendorChanged();
        }
        if (result.date != null) {
          // Try parsing the date string from OCR
          try {
            if (result.date!.contains('.')) {
              final parts = result.date!.split('.');
              if (parts.length == 3) {
                _date = DateTime(int.parse(parts[2]), int.parse(parts[1]),
                    int.parse(parts[0]));
              }
            } else if (result.date!.contains('-')) {
              _date = DateTime.parse(result.date!);
            }
          } catch (e) {
            debugPrint('Failed to parse OCR date: ${result.date}');
          }
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Údaje načítané z bločku')),
      );
    }
  }
  
  void _showCategorySelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: CategorySelector(
            selectedCategory: _selectedCategory,
            suggestedCategory: _suggestedCategory,
            suggestionConfidence: _suggestionConfidence,
            onCategorySelected: (category) {
              setState(() {
                _selectedCategory = category;
              });
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }

  bool _isSaving = false;

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSaving = true;
    });

    try {
      List<String> receiptUrls = [];
      
      // Upload receipt if exists
      if (_scannedReceiptPath != null) {
        final storageService = ref.read(receiptStorageServiceProvider);
        
        // Check if it's already a remote URL (unlikely here but good practice)
        if (_scannedReceiptPath!.startsWith('http')) {
          receiptUrls.add(_scannedReceiptPath!);
        } else {
          final url = await storageService.uploadReceipt(_scannedReceiptPath!);
          if (url != null) {
            receiptUrls.add(url);
          }
        }
      }

      final expense = ExpenseModel(
        id: '',
        userId: '',
        vendorName: _vendorController.text,
        description: _descController.text,
        amount:
            double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0,
        date: _date,
        category: _selectedCategory,
        categorizationConfidence: _selectedCategory == _suggestedCategory 
            ? _suggestionConfidence 
            : null,
        isOcrVerified: widget.initialText != null || _scannedReceiptPath != null,
        receiptUrls: receiptUrls,
        receiptScannedAt: _scannedReceiptPath != null ? DateTime.now() : null,
      );

      await ref.read(expensesControllerProvider.notifier).addExpense(expense);

      if (mounted) {
        // Show success dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Výdavok pridaný!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(expense.vendorName),
                  Text(
                    NumberFormat.currency(symbol: '€').format(expense.amount),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (_selectedCategory != null) ...[
                    const SizedBox(height: 8),
                    Chip(
                      avatar: Icon(_selectedCategory!.icon, size: 16),
                      label: Text(_selectedCategory!.displayName),
                      backgroundColor: _selectedCategory!.color.withOpacity(0.2),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );

        // Auto-close after delay
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) Navigator.of(context).pop();
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nový výdavok'),
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _saveExpense,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Scan Button
            ElevatedButton.icon(
              onPressed: _scanReceipt,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Skenovať bloček'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.orange.shade100,
                foregroundColor: Colors.orange.shade900,
              ),
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: _vendorController,
              decoration:
                  const InputDecoration(labelText: 'Obchod / Dodávateľ'),
              validator: (v) => v!.isEmpty ? 'Povinné pole' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Suma (€)'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Povinné pole';
                if (double.tryParse(v.replaceAll(',', '.')) == null) {
                  return 'Neplatná suma';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            InputDecorator(
              decoration: const InputDecoration(labelText: 'Dátum'),
              child: InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _date = picked);
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('dd.MM.yyyy').format(_date)),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Category Selector
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Kategória'),
              child: InkWell(
                onTap: _showCategorySelector,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_selectedCategory != null)
                      Row(
                        children: [
                          Icon(
                            _selectedCategory!.icon,
                            color: _selectedCategory!.color,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(_selectedCategory!.displayName),
                          if (_selectedCategory == _suggestedCategory && _suggestionConfidence != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Icon(
                                Icons.auto_awesome,
                                size: 16,
                                color: _selectedCategory!.color,
                              ),
                            ),
                        ],
                      )
                    else
                      Text(
                        'Vybrať kategóriu',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    const Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Popis / Text bločku',
                alignLabelWithHint: true,
              ),
              maxLines: 5,
            ),
          ],
        ),
      ),
    );
  }
}
