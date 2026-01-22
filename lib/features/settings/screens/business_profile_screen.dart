import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_settings_model.dart';
import '../providers/settings_provider.dart';
import '../../../core/ui/biz_theme.dart';
import '../../../shared/utils/biz_snackbar.dart';
import '../../../core/services/company_lookup_service.dart';
import '../../../core/services/icoatlas_service.dart';

class BusinessProfileScreen extends ConsumerStatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  ConsumerState<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends ConsumerState<BusinessProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _icoController;
  late TextEditingController _dicController;
  late TextEditingController _icDphController;
  late TextEditingController _ibanController;
  late TextEditingController _swiftController;
  late TextEditingController _registerInfoController;
  bool _isLookingUp = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider).valueOrNull ?? UserSettingsModel.empty();
    _nameController = TextEditingController(text: settings.companyName);
    _addressController = TextEditingController(text: settings.companyAddress);
    _icoController = TextEditingController(text: settings.companyIco);
    _dicController = TextEditingController(text: settings.companyDic);
    _icDphController = TextEditingController(text: settings.companyIcDph);
    _ibanController = TextEditingController(text: settings.bankAccount);
    _swiftController = TextEditingController(text: settings.swift);
    _registerInfoController = TextEditingController(text: settings.registerInfo);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _icoController.dispose();
    _dicController.dispose();
    _icDphController.dispose();
    _ibanController.dispose();
    _swiftController.dispose();
    _registerInfoController.dispose();
    super.dispose();
  }

  Future<void> _lookupCompany() async {
    final ico = _icoController.text.trim();
    if (ico.isEmpty) {
      BizSnackbar.showInfo(context, 'Zadajte IČO');
      return;
    }

    setState(() => _isLookingUp = true);
    try {
      final service = ref.read(companyLookupServiceProvider);
      final company = await service.lookup(ico);

      if (mounted) {
        if (company != null) {
          setState(() {
            _nameController.text = company.name;
            _addressController.text = company.address;
            if (company.dic != null) _dicController.text = company.dic!;
            if (company.icDph != null) _icDphController.text = company.icDph!;
          });
          BizSnackbar.showSuccess(context, 'Údaje firmy boli aktualizované');
        } else {
          BizSnackbar.showError(context, 'Firmu s týmto IČO sme nenašli.');
        }
      }
    } catch (e) {
      if (mounted) {
        BizSnackbar.showError(context, 'Chyba pri hľadaní: $e');
      }
    } finally {
      if (mounted) setState(() => _isLookingUp = false);
    }
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final current = ref.read(settingsProvider).valueOrNull ?? UserSettingsModel.empty();
      final updated = current.copyWith(
        companyName: _nameController.text,
        companyAddress: _addressController.text,
        companyIco: _icoController.text,
        companyDic: _dicController.text,
        companyIcDph: _icDphController.text,
        bankAccount: _ibanController.text,
        swift: _swiftController.text,
        registerInfo: _registerInfoController.text,
      );

      await ref.read(settingsControllerProvider.notifier).updateSettings(updated);
      
      if (mounted) {
        BizSnackbar.showSuccess(context, 'Profil firmy bol úspešne uložený');
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? UserSettingsModel.empty();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil firmy'),
        actions: [
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader('Základné údaje'),
              const SizedBox(height: 16),
              Autocomplete<Map<String, dynamic>>(
                optionsBuilder: (TextEditingValue textEditingValue) async {
                  if (textEditingValue.text.length < 2) return [];
                  return await ref.read(icoAtlasServiceProvider).autocomplete(textEditingValue.text);
                },
                displayStringForOption: (option) => option['name'] ?? '',
                onSelected: (Map<String, dynamic> selection) {
                  setState(() {
                    _nameController.text = selection['name'] ?? '';
                    _icoController.text = selection['ico'] ?? selection['cin'] ?? '';
                    _addressController.text = selection['formatted_address'] ?? selection['address'] ?? '';
                    _dicController.text = selection['dic'] ?? selection['tin'] ?? '';
                    _icDphController.text = selection['v_tin'] ?? selection['ic_dph'] ?? '';
                  });
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  // Pre-fill if we have initial data
                  if (controller.text != _nameController.text && _nameController.text.isNotEmpty && controller.text.isEmpty) {
                    controller.text = _nameController.text;
                  }
                  
                  // Keep our _nameController in sync
                  controller.addListener(() {
                    _nameController.text = controller.text;
                  });

                  return _buildTextField(
                    controller: controller,
                    focusNode: focusNode,
                    label: 'Obchodné meno',
                    icon: Icons.business,
                    validator: (v) => v!.isEmpty ? 'Zadajte obchodné meno' : null,
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _addressController,
                label: 'Sídlo / Adresa',
                icon: Icons.location_on_outlined,
                maxLines: 2,
                validator: (v) => v!.isEmpty ? 'Zadajte adresu' : null,
              ),
              const SizedBox(height: 16),
               _buildTextField(
                controller: _registerInfoController,
                label: 'Registrácia (OR SR / ŽR SR)',
                icon: Icons.info_outline,
                placeholder: 'Zapísaná v OR OS Bratislava I...',
              ),
              const SizedBox(height: 24),
              
              _buildHeader('Identifikačné údaje'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _icoController,
                      label: 'IČO',
                      icon: Icons.numbers,
                      suffix: _isLookingUp
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              icon: const Icon(Icons.search, size: 20),
                              onPressed: _lookupCompany,
                            ),
                      validator: (v) => v!.isEmpty ? 'Povinné' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _dicController,
                      label: 'DIČ',
                      icon: Icons.tag,
                      validator: (v) => v!.isEmpty ? 'Povinné' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _icDphController,
                label: 'IČ DPH',
                icon: Icons.receipt_long,
                placeholder: 'SK1020304050',
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                 title: const Text('Platca DPH', style: TextStyle(fontSize: 14)),
                 value: settings.isVatPayer,
                 contentPadding: EdgeInsets.zero,
                 onChanged: (val) {
                   ref.read(settingsControllerProvider.notifier).updateVatPayer(val);
                 },
              ),
              const SizedBox(height: 24),

              _buildHeader('Bankové spojenie'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _ibanController,
                label: 'IBAN',
                icon: Icons.account_balance,
                validator: (v) => v!.isEmpty ? 'Zadajte IBAN' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _swiftController,
                label: 'SWIFT / BIC',
                icon: Icons.language,
              ),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BizTheme.slovakBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('ULOŽIŤ PROFIL', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: BizTheme.gray600,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? placeholder,
    int maxLines = 1,
    Widget? suffix,
    FocusNode? focusNode,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: placeholder,
        prefixIcon: Icon(icon, color: BizTheme.slovakBlue),
        suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BizTheme.gray200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BizTheme.slovakBlue, width: 2),
        ),
      ),
    );
  }
}
