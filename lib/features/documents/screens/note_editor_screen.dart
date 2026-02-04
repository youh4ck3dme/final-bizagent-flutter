import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../widgets/markdown_toolbar.dart';
import '../models/notepad_model.dart';
import '../providers/notepad_provider.dart';
import '../../ai_tools/services/biz_bot_service.dart';
import '../../../core/ui/biz_theme.dart';
import '../../../shared/utils/biz_snackbar.dart';
import '../../../core/services/analytics_service.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final NotepadItemModel? note;

  const NoteEditorScreen({super.key, this.note});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late NotepadItemType _selectedType;
  bool _isSaving = false;
  bool _isAnalyzing = false;
  bool _isPreviewMode = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );
    _selectedType = widget.note?.type ?? NotepadItemType.note;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.isEmpty && _contentController.text.isEmpty) {
      context.pop();
      return;
    }

    setState(() => _isSaving = true);

    String title = _titleController.text;
    if (title.isEmpty) {
      // Auto-generate title from content
      final lines = _contentController.text.split('\n');
      title = lines.first.length > 30
          ? '${lines.first.substring(0, 30)}...'
          : lines.first;
    }

    await ref.read(notepadControllerProvider.notifier).saveNote(
          id: widget.note?.id,
          title: title,
          content: _contentController.text,
          type: _selectedType,
        );

    if (mounted) {
      context.pop();
    }
  }

  Future<void> _analyzeWithBizBot() async {
    if (_contentController.text.length < 10) {
      BizSnackbar.showInfo(context, 'Zadajte aspoň kúsok textu pre analýzu.');
      return;
    }

    // Check connectivity before AI call
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) {
        if (mounted) {
          BizSnackbar.showError(
            context,
            'AI analýza vyžaduje pripojenie k internetu. Skontrolujte svoje pripojenie a skúste znova.',
          );
        }
        return;
      }
    } catch (e) {
      // Connectivity check failed, proceed anyway
      debugPrint('Connectivity check failed: $e');
    }

    setState(() => _isAnalyzing = true);

    ref.read(analyticsServiceProvider).logAiAnalysisStarted('note_analysis');

    try {
      final bizBot = ref.read(bizBotServiceProvider);
      final results = await bizBot.analyzeNote(_contentController.text);

      ref
          .read(analyticsServiceProvider)
          .logAiAnalysisCompleted('note_analysis', success: true);

      if (mounted) {
        setState(() => _isAnalyzing = false);
        _showAiActions(results);
      }
    } catch (e) {
      ref
          .read(analyticsServiceProvider)
          .logAiAnalysisCompleted('note_analysis', success: false);
      if (mounted) {
        setState(() => _isAnalyzing = false);
        // Provide more user-friendly error message
        final message = e.toString().contains('Connection')
            ? 'Nepodarilo sa spojiť s AI serverom. Skontrolujte pripojenie k internetu.'
            : 'Chyba pri analýze: $e';
        BizSnackbar.showError(context, message);
      }
    }
  }

  void _showAiActions(List<Map<String, dynamic>> actions) {
    if (actions.isEmpty) {
      BizSnackbar.showInfo(
        context,
        'BizBot nenašiel žiadne konkrétne akcie pre tento text.',
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: BizTheme.slovakBlue,
                ),
                const SizedBox(width: 12),
                Text(
                  'BizBot Analyzoval Poznámku',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Na základe vášho textu odporúčam tieto akcie:',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ...actions.map(
              (action) => _buildAiActionTile(
                icon: _getIconForAction(action['type']),
                title: action['label'] ?? 'Akcia',
                subtitle: action['description'] ?? '',
                onTap: () {
                  Navigator.pop(context);
                  _handleAction(action);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  IconData _getIconForAction(String? type) {
    switch (type) {
      case 'create_invoice':
        return Icons.receipt_outlined;
      case 'create_reminder':
        return Icons.notifications_active_outlined;
      case 'summarize':
        return Icons.summarize_outlined;
      default:
        return Icons.bolt;
    }
  }

  void _handleAction(Map<String, dynamic> action) {
    final type = action['type'];
    if (type == 'create_invoice') {
      context.push(
        '/create-invoice',
        extra: {
          'clientName': 'Zákazník z poznámky',
          'items': [
            {'description': _contentController.text, 'amount': 0.0},
          ],
        },
      );
    } else {
      BizSnackbar.showInfo(
        context,
        'Akcia ${action['label']} bude pridaná v ďalšej verzii.',
      );
    }
  }

  Widget _buildAiActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: BizTheme.slovakBlue.withValues(alpha: 0.1),
        child: Icon(icon, color: BizTheme.slovakBlue),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'Nová poznámka' : 'Upraviť poznámku'),
        actions: [
          IconButton(
            icon: Icon(_isPreviewMode ? Icons.edit : Icons.visibility),
            tooltip: _isPreviewMode ? 'Upraviť' : 'Náhľad',
            onPressed: () => setState(() => _isPreviewMode = !_isPreviewMode),
          ),
          if (widget.note != null)
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: BizTheme.nationalRed,
              ),
              onPressed: () async {
                await ref
                    .read(notepadControllerProvider.notifier)
                    .softDeleteNote(widget.note!.id);
                if (context.mounted) context.pop();
              },
            ),
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded, color: Colors.green),
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTypeSelector(),
          Expanded(
            child: Column(
              children: [
                if (!_isPreviewMode)
                  MarkdownToolbar(
                    controller: _contentController,
                    onStateChanged: () => setState(() {}),
                  ),
                Expanded(
                  child: _isPreviewMode ? _buildPreview() : _buildEditor(),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isAnalyzing ? null : _analyzeWithBizBot,
        backgroundColor: BizTheme.slovakBlue,
        child: _isAnalyzing
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.auto_awesome_rounded, color: Colors.white),
      ).animate().shake(delay: 3.seconds, duration: 500.ms),
    );
  }

  Widget _buildEditor() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TextField(
          controller: _titleController,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            hintText: 'Názov poznámky',
            border: InputBorder.none,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _contentController,
          maxLines: null,
          style: const TextStyle(fontSize: 16, height: 1.5),
          decoration: const InputDecoration(
            hintText: 'Začnite písať... (Markdown podporovaný)',
            border: InputBorder.none,
          ),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          _titleController.text.isEmpty ? 'Bez názvu' : _titleController.text,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const Divider(),
        MarkdownBody(
          data: _contentController.text,
          selectable: true,
          styleSheet: MarkdownStyleSheet.fromTheme(
            Theme.of(context),
          ).copyWith(p: const TextStyle(fontSize: 16, height: 1.5)),
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: NotepadItemType.values
            .map(
              (type) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(type.toSlovak()),
                  selected: _selectedType == type,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedType = type);
                  },
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
