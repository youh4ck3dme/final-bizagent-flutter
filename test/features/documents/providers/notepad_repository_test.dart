import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bizagent/features/documents/providers/notepad_repository.dart';
import 'package:bizagent/features/documents/models/notepad_model.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  QuerySnapshot,
  DocumentSnapshot,
  QueryDocumentSnapshot,
])
import 'notepad_repository_test.mocks.dart';

void main() {
  late MockFirebaseFirestore firestore;
  late NotepadRepository repository;
  late MockCollectionReference<Map<String, dynamic>> usersCollection;
  late MockDocumentReference<Map<String, dynamic>> userDoc;
  late MockCollectionReference<Map<String, dynamic>> notepadCollection;

  setUp(() {
    firestore = MockFirebaseFirestore();
    repository = NotepadRepository(firestore);
    usersCollection = MockCollectionReference<Map<String, dynamic>>();
    userDoc = MockDocumentReference<Map<String, dynamic>>();
    notepadCollection = MockCollectionReference<Map<String, dynamic>>();

    when(firestore.collection('users')).thenReturn(usersCollection);
    when(usersCollection.doc(any)).thenReturn(userDoc);
    when(userDoc.collection('notepad')).thenReturn(notepadCollection);
  });

  group('NotepadRepository Tests', () {
    test('addNote calls Firestore set', () async {
      final mockDoc = MockDocumentReference<Map<String, dynamic>>();
      when(notepadCollection.doc('note123')).thenReturn(mockDoc);

      final note = NotepadItemModel(
        id: 'note123',
        userId: 'user1',
        createdAt: DateTime.now(),
        title: 'Test Note',
        content: 'Content',
        type: NotepadItemType.note,
        lastModified: DateTime.now(),
      );

      await repository.addNote('user1', note);

      verify(mockDoc.set(any)).called(1);
    });

    test('deleteNote calls Firestore delete', () async {
      final mockDoc = MockDocumentReference<Map<String, dynamic>>();
      when(notepadCollection.doc('note123')).thenReturn(mockDoc);

      await repository.deleteNote('user1', 'note123');

      verify(mockDoc.delete()).called(1);
    });

    test('getNote returns model if exists', () async {
      final mockDoc = MockDocumentReference<Map<String, dynamic>>();
      final mockSnap = MockDocumentSnapshot<Map<String, dynamic>>();

      when(notepadCollection.doc('note123')).thenReturn(mockDoc);
      when(mockDoc.get()).thenAnswer((_) async => mockSnap);
      when(mockSnap.exists).thenReturn(true);
      when(mockSnap.id).thenReturn('note123');
      when(mockSnap.data()).thenReturn({
        'userId': 'user1',
        'createdAt': DateTime.now().toIso8601String(),
        'title': 'Test',
        'content': 'Test content',
        'type': 'note',
        'lastModified': DateTime.now().toIso8601String(),
      });

      final result = await repository.getNote('user1', 'note123');

      expect(result, isNotNull);
      expect(result?.title, 'Test');
    });
  });
}
