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

      if (invoices.isEmpty) {
        // Return mock data for a better "first impression"
        yield [
          InvoiceModel(
            id: 'mock-1',
            userId: userId,
            number: 'Faktúra 2026001',
            clientName: 'Google Slovakia s.r.o.',
            dateIssued: DateTime(2026, 1, 10),
            dateDue: DateTime(2026, 1, 24),
            totalAmount: 1500.0,
            items: [],
            status: InvoiceStatus.paid,
          ),
          InvoiceModel(
            id: 'mock-2',
            userId: userId,
            number: 'Faktúra 2026002',
            clientName: 'Freelance Hub s.r.o.',
            dateIssued: DateTime(2026, 1, 15),
            dateDue: DateTime(2026, 1, 29),
            totalAmount: 850.50,
            items: [],
            status: InvoiceStatus.sent,
          ),
        ];
      } else {
        yield invoices;
      }
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
