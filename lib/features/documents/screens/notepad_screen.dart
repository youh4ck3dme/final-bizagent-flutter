import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../models/notepad_model.dart';
import '../providers/notepad_provider.dart';
import '../../../core/ui/biz_theme.dart';

class NotepadScreen extends ConsumerStatefulWidget {
  const NotepadScreen({super.key});

  @override
  ConsumerState<NotepadScreen> createState() => _NotepadScreenState();
}

class _NotepadScreenState extends ConsumerState<NotepadScreen> {
  String _searchQuery = '';
  bool _isSearching = false;
  NotepadItemType? _filterType;

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notepadProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Hľadať v poznámkach...',
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (val) => setState(() => _searchQuery = val),
              )
            : const Text('Moje Poznámky'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) _searchQuery = '';
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: notesAsync.when(
              data: (notes) {
                final filteredNotes = notes.where((n) {
                  final matchesSearch = n.title.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) ||
                      n.content.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          );
                  final matchesFilter =
                      _filterType == null || n.type == _filterType;
                  return matchesSearch && matchesFilter;
                }).toList();

                if (filteredNotes.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildNotesGrid(filteredNotes);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, __) => Center(child: Text('Chyba: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/documents/notepad/new'),
        icon: const Icon(Icons.note_add),
        label: const Text('Nová poznámka'),
        backgroundColor: BizTheme.slovakBlue,
        foregroundColor: Colors.white,
      ).animate().scale(delay: 400.ms),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Všetko'),
            selected: _filterType == null,
            onSelected: (_) => setState(() => _filterType = null),
          ),
          const SizedBox(width: 8),
          ...NotepadItemType.values.map(
            (type) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(type.toSlovak()),
                selected: _filterType == type,
                onSelected: (_) => setState(() => _filterType = type),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesGrid(List<NotepadItemModel> notes) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return _buildNoteCard(note, index);
      },
    );
  }

  Widget _buildNoteCard(NotepadItemModel note, int index) {
    return GestureDetector(
      onTap: () => context.push('/documents/notepad/edit', extra: note),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        color: _getNoteColor(note.type),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    _getNoteIcon(note.type),
                    size: 16,
                    color: Colors.blueGrey,
                  ),
                  Text(
                    DateFormat('dd.MM.').format(note.lastModified),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.blueGrey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                note.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  note.content,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[800],
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_alt_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Žiadne poznámky',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Kliknite na + pre vytvorenie prvej poznámky.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  Color _getNoteColor(NotepadItemType type) {
    switch (type) {
      case NotepadItemType.note:
        return const Color(0xFFFFF9C4); // Light yellow
      case NotepadItemType.receipt:
        return const Color(0xFFE1F5FE); // Light blue
      case NotepadItemType.memo:
        return const Color(0xFFF3E5F5); // Light purple
      case NotepadItemType.reminder:
        return const Color(0xFFFFF3E0); // Light orange
      case NotepadItemType.other:
        return const Color(0xFFF1F8E9); // Light green
    }
  }

  IconData _getNoteIcon(NotepadItemType type) {
    switch (type) {
      case NotepadItemType.note:
        return Icons.edit_note;
      case NotepadItemType.receipt:
        return Icons.receipt_long;
      case NotepadItemType.memo:
        return Icons.psychology_outlined;
      case NotepadItemType.reminder:
        return Icons.notifications_active_outlined;
      case NotepadItemType.other:
        return Icons.more_horiz;
    }
  }
}
