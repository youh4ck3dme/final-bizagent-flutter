import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/invoice_model.dart';

final invoicesRepositoryProvider = Provider<InvoicesRepository>((ref) {
  return InvoicesRepository(FirebaseFirestore.instance);
});

class InvoicesRepository {
  final FirebaseFirestore _firestore;

  InvoicesRepository(this._firestore);

  Future<List<InvoiceModel>> getInvoices(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('invoices')
        .orderBy('dateIssued', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => InvoiceModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Stream<List<InvoiceModel>> watchInvoices(String userId) async* {
    final stream = _firestore
        .collection('users')
        .doc(userId)
        .collection('invoices')
        .orderBy('dateIssued', descending: true)
        .snapshots();

    await for (final snapshot in stream) {
      final invoices = snapshot.docs
          .map((doc) => InvoiceModel.fromMap(doc.data(), doc.id))
          .toList();

      yield invoices;
    }
  }

  Future<void> addInvoice(String userId, InvoiceModel invoice) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('invoices')
        .add(invoice.toMap());
  }

  Future<void> updateInvoice(String userId, InvoiceModel invoice) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('invoices')
        .doc(invoice.id)
        .update(invoice.toMap());
  }

  Future<void> updateInvoiceStatus(
      String userId, String invoiceId, InvoiceStatus status) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('invoices')
        .doc(invoiceId)
        .update({'status': status.name});
  }

  Future<void> deleteInvoice(String userId, String invoiceId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('invoices')
        .doc(invoiceId)
        .delete();
  }
}
