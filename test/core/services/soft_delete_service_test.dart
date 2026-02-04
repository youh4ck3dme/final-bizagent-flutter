import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bizagent/core/services/soft_delete_service.dart';

@GenerateMocks([
  FirebaseFirestore,
  CollectionReference,
  DocumentReference,
  Query,
  QuerySnapshot,
  DocumentSnapshot,
  WriteBatch,
])
import 'soft_delete_service_test.mocks.dart';

void main() {
  late MockFirebaseFirestore firestore;
  late SoftDeleteService service;

  setUp(() {
    firestore = MockFirebaseFirestore();
    service = SoftDeleteService(firestore);
  });

  group('SoftDeleteService Tests', () {
    test('moveToTrash correctly sets data in trash collection', () async {
      final mockCollection = MockCollectionReference<Map<String, dynamic>>();
      final mockDoc = MockDocumentReference<Map<String, dynamic>>();
      final mockSubCollection = MockCollectionReference<Map<String, dynamic>>();
      final mockSubDoc = MockDocumentReference<Map<String, dynamic>>();

      when(firestore.collection('trash_coll')).thenReturn(mockCollection);
      when(mockCollection.doc('user123')).thenReturn(mockDoc);
      when(mockDoc.collection('items')).thenReturn(mockSubCollection);
      when(mockSubCollection.doc('item456')).thenReturn(mockSubDoc);

      final testData = {'key': 'value'};

      await service.moveToTrash(
        'trash_coll',
        'user123',
        'item456',
        testData,
        reason: 'test',
        originalCollectionPath: 'org/path',
      );

      verify(
        mockSubDoc.set(
          argThat(
            predicate(
              (Map<String, dynamic> data) =>
                  data['key'] == 'value' &&
                  data['deleteReason'] == 'test' &&
                  data['originalCollectionPath'] == 'org/path' &&
                  data['originalId'] == 'item456' &&
                  data.containsKey('deletedAt'),
            ),
          ),
        ),
      ).called(1);
    });

    test('restoreItem moves data back and deletes from trash', () async {
      final mockTrashCollection =
          MockCollectionReference<Map<String, dynamic>>();
      final mockTrashUserDoc = MockDocumentReference<Map<String, dynamic>>();
      final mockTrashItemsCollection =
          MockCollectionReference<Map<String, dynamic>>();
      final mockTrashDoc = MockDocumentReference<Map<String, dynamic>>();
      final mockSnap = MockDocumentSnapshot<Map<String, dynamic>>();

      final mockOrgCollection = MockCollectionReference<Map<String, dynamic>>();
      final mockOrgDoc = MockDocumentReference<Map<String, dynamic>>();

      when(firestore.collection('trash_coll')).thenReturn(mockTrashCollection);
      when(mockTrashCollection.doc('user123')).thenReturn(mockTrashUserDoc);
      when(
        mockTrashUserDoc.collection('items'),
      ).thenReturn(mockTrashItemsCollection);
      when(mockTrashItemsCollection.doc('item456')).thenReturn(mockTrashDoc);
      when(mockTrashDoc.get()).thenAnswer((_) async => mockSnap);

      when(mockSnap.exists).thenReturn(true);
      when(mockSnap.data()).thenReturn({
        'name': 'Invoice X',
        'originalCollectionPath': 'invoices',
        'deletedAt': 'some-date',
      });

      when(firestore.collection('invoices')).thenReturn(mockOrgCollection);
      when(mockOrgCollection.doc('item456')).thenReturn(mockOrgDoc);

      await service.restoreItem('trash_coll', 'user123', 'item456');

      verify(
        mockOrgDoc.set(
          argThat(
            predicate(
              (Map<String, dynamic> data) =>
                  data['name'] == 'Invoice X' &&
                  !data.containsKey('deletedAt') &&
                  !data.containsKey('originalCollectionPath'),
            ),
          ),
        ),
      ).called(1);

      verify(mockTrashDoc.delete()).called(1);
    });
  });
}
