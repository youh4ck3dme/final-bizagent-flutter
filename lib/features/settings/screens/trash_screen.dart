import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/ui/biz_theme.dart';
import '../../../core/services/soft_delete_service.dart';
import '../../tools/providers/trash_provider.dart';
import '../../../shared/utils/biz_snackbar.dart';

class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final countAsync = ref.watch(trashCountProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: countAsync.when(
          data: (count) => Text('Kôš ($count)'),
          loading: () => const Text('Kôš'),
          error: (_, __) => const Text('Kôš'),
        ),
        actions: [
          countAsync.when(
            data: (count) => count > 0
                ? TextButton.icon(
                    onPressed: () => _confirmEmptyAllTrash(context, ref),
                    icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                    label: const Text('Vysypať kôš'),
                    style: TextButton.styleFrom(
                      foregroundColor: BizTheme.nationalRed,
                    ),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          _buildCategory(
            context,
            ref,
            'Faktúry',
            invoiceTrashProvider,
            SoftDeleteCollections.invoices,
            Icons.receipt_long,
          ),
          _buildCategory(
            context,
            ref,
            'BizBot Rozhovory',
            bizBotTrashProvider,
            SoftDeleteCollections.bizBotConversations,
            Icons.chat_bubble_outline,
          ),
          _buildCategory(
            context,
            ref,
            'Poznámky',
            notepadTrashProvider,
            SoftDeleteCollections.notepadItems,
            Icons.note_alt_outlined,
          ),
          // Empty state placeholder if all streams are empty
          SliverToBoxAdapter(
            child: countAsync.when(
              data: (count) => count == 0
                  ? _buildEmptyState(context)
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategory(
    BuildContext context,
    WidgetRef ref,
    String title,
    StreamProvider<List<Map<String, dynamic>>> provider,
    String collection,
    IconData icon,
  ) {
    final itemsAsync = ref.watch(provider);

    return itemsAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: BizTheme.slovakBlue,
                      ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = items[index];
                return _buildTrashItem(context, ref, item, collection, icon);
              }, childCount: items.length),
            ),
          ],
        );
      },
      loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
    );
  }

  Widget _buildTrashItem(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> item,
    String collection,
    IconData icon,
  ) {
    final data = item['data'] as Map<String, dynamic>;
    final id = item['id'] as String;
    final title = _getItemTitle(data, collection);
    final deletedAt = data['deletedAt'] != null
        ? (data['deletedAt'] as dynamic).toDate() as DateTime
        : DateTime.now();

    final daysLeft = 7 - DateTime.now().difference(deletedAt).inDays;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: BizTheme.gray50,
            child: Icon(icon, color: BizTheme.gray700, size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            'Zmazané: ${DateFormat('dd.MM.').format(deletedAt)} • ${daysLeft > 0 ? '$daysLeft dní do zmazania' : 'čoskoro zmazané'}',
            style: const TextStyle(fontSize: 12),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.restore_rounded, color: Colors.green),
                onPressed: () =>
                    _restoreItem(context, ref, collection, id, title),
                tooltip: 'Obnoviť',
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_forever_rounded,
                  color: BizTheme.nationalRed,
                ),
                onPressed: () =>
                    _confirmDeleteForever(context, ref, collection, id, title),
                tooltip: 'Zmazať navždy',
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.05);
  }

  String _getItemTitle(Map<String, dynamic> data, String collection) {
    switch (collection) {
      case SoftDeleteCollections.invoices:
        return data['clientName'] ?? data['number'] ?? 'Faktúra bez názvu';
      case SoftDeleteCollections.bizBotConversations:
        return data['title'] ?? 'BizBot Rozhovor';
      case SoftDeleteCollections.notepadItems:
        return data['title'] ??
            data['content']?.toString().substring(0, 20) ??
            'Poznámka';
      default:
        return 'Položka';
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      height: 400,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.auto_delete_outlined,
            size: 64,
            color: BizTheme.gray300,
          ),
          const SizedBox(height: 16),
          Text(
            'Kôš je prázdny',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: BizTheme.gray500),
          ),
          const SizedBox(height: 8),
          const Text(
            'Zmazané položky sa tu uchovávajú 7 dní.',
            style: TextStyle(color: BizTheme.gray400),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  void _restoreItem(
    BuildContext context,
    WidgetRef ref,
    String collection,
    String id,
    String title,
  ) async {
    await ref
        .read(trashControllerProvider.notifier)
        .restoreItem(collection, id);
    if (context.mounted) {
      BizSnackbar.showSuccess(context, '"$title" bolo obnovené.');
    }
  }

  void _confirmDeleteForever(
    BuildContext context,
    WidgetRef ref,
    String collection,
    String id,
    String title,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Zmazať natrvalo?'),
        content: Text('Položka "$title" bude nenávratne odstránená.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Zrušiť'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(trashControllerProvider.notifier)
                  .permanentDeleteItem(collection, id);
              if (context.mounted) {
                BizSnackbar.showInfo(context, 'Odstránené.');
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: BizTheme.nationalRed,
            ),
            child: const Text('Zmazať navždy'),
          ),
        ],
      ),
    );
  }

  void _confirmEmptyAllTrash(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vysypať celý kôš?'),
        content: const Text(
          'Všetky položky v koši budú natrvalo odstránené. Túto akciu nie je možné vrátiť späť.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Zrušiť'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(trashControllerProvider.notifier).emptyAllTrash();
              if (context.mounted) {
                BizSnackbar.showInfo(context, 'Kôš bol vysypaný.');
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: BizTheme.nationalRed,
            ),
            child: const Text('Vysypať všetko'),
          ),
        ],
      ),
    );
  }
}
