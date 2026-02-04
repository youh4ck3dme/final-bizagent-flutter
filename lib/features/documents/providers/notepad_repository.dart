import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notepad_model.dart';

class NotepadRepository {
  final FirebaseFirestore _db;

  NotepadRepository(this._db);

  Stream<List<NotepadItemModel>> watchNotes(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('notepad')
        .orderBy('lastModified', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NotepadItemModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> addNote(String userId, NotepadItemModel note) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('notepad')
        .doc(note.id)
        .set(note.toFirestore());
  }

  Future<void> updateNote(String userId, NotepadItemModel note) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('notepad')
        .doc(note.id)
        .update(note.toFirestore());
  }

  Future<void> deleteNote(String userId, String noteId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('notepad')
        .doc(noteId)
        .delete();
  }

  Future<NotepadItemModel?> getNote(String userId, String noteId) async {
    final doc = await _db
        .collection('users')
        .doc(userId)
        .collection('notepad')
        .doc(noteId)
        .get();

    if (doc.exists) {
      return NotepadItemModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }
}

final notepadRepositoryProvider = Provider<NotepadRepository>((ref) {
  return NotepadRepository(FirebaseFirestore.instance);
});
