import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../auth/providers/auth_repository.dart';
import '../models/notepad_model.dart';
import 'notepad_repository.dart';
import '../../../core/services/soft_delete_service.dart';

final notepadProvider = StreamProvider<List<NotepadItemModel>>((ref) {
  final user = ref.watch(authStateProvider).asData?.value;
  if (user == null) return Stream.value([]);
  return ref.watch(notepadRepositoryProvider).watchNotes(user.id);
});

final notepadControllerProvider =
    NotifierProvider<NotepadController, AsyncValue<void>>(() {
  return NotepadController();
});

class NotepadController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> saveNote({
    String? id,
    required String title,
    required String content,
    required NotepadItemType type,
  }) async {
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(notepadRepositoryProvider);
      final now = DateTime.now();

      if (id != null) {
        final existing = await repo.getNote(user.id, id);
        if (existing != null) {
          final updated = existing.copyWith(
            title: title,
            content: content,
            type: type,
            lastModified: now,
          );
          await repo.updateNote(user.id, updated);
          return;
        }
      }

      // Create new note
      final newNote = NotepadItemModel(
        id: const Uuid().v4(),
        userId: user.id,
        createdAt: now,
        title: title,
        content: content,
        type: type,
        lastModified: now,
      );
      await repo.addNote(user.id, newNote);
    });
  }

  Future<void> softDeleteNote(String noteId) async {
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(notepadRepositoryProvider);
      final note = await repo.getNote(user.id, noteId);

      if (note != null) {
        // 1. Move to Trash
        await ref.read(softDeleteServiceProvider).moveToTrash(
              SoftDeleteCollections.notepadItems,
              user.id,
              noteId,
              note.toFirestore(),
              originalCollectionPath: 'users/${user.id}/notepad',
            );

        // 2. Delete Original
        await repo.deleteNote(user.id, noteId);
      }
    });
  }
}
