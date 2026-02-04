import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:bizagent/features/invoices/providers/invoices_repository.dart';
import 'package:bizagent/features/invoices/models/invoice_model.dart';
import 'package:bizagent/core/services/local_persistence_service.dart';

// Mocking LocalPersistenceService since we are testing integration with Firestore primarily
class FakeLocalPersistenceService extends LocalPersistenceService {
  @override
  List<Map<String, dynamic>> getInvoices() => [];
  @override
  Future<void> saveInvoice(String id, Map<String, dynamic> data) async {}
  @override
  Future<void> deleteInvoice(String id) async {}
}

void main() {
  group('Full Invoice Lifecycle Integration Test', () {
    late FakeFirebaseFirestore fakeFirestore;
    late InvoicesRepository repository;
    const userId = 'integration-user-1';

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repository = InvoicesRepository(
        fakeFirestore,
        FakeLocalPersistenceService(),
      );
    });

    test('Complete flow: Create -> Mark Paid -> Verify -> Delete', () async {
      // 1. CREATE INVOICE
      final newInvoice = InvoiceModel(
        id: 'inv-001',
        userId: userId,
        createdAt: DateTime.now(),
        number: '2026001',
        clientName: 'Integration Client Ltd.',
        clientIco: '12345678',
        dateIssued: DateTime(2026, 1, 31),
        dateDue: DateTime(2026, 2, 14),
        items: [
          InvoiceItemModel(
            title: 'Consulting',
            amount: 1000,
            vatRate: 0.2,
          ), // 1000 + 200 = 1200
          InvoiceItemModel(
            title: 'License',
            amount: 500,
            vatRate: 0.0,
          ), // 500 + 0 = 500
        ],
        totalAmount: 1700,
        status: InvoiceStatus.sent,
      );

      await repository.addInvoice(userId, newInvoice);

      // Verify it exists in "backend"
      var snapshots = await repository.getInvoices(userId);
      expect(snapshots.length, 1);
      expect(snapshots.first.clientName, 'Integration Client Ltd.');
      expect(snapshots.first.status, InvoiceStatus.sent);
      expect(snapshots.first.grandTotal, 1700.0);

      // 2. MARK AS PAID (Update)
      final paidInvoice = newInvoice.copyWith(
        status: InvoiceStatus.paid,
        paymentDate: DateTime(2026, 2, 1),
        paymentMethod: 'Transfer',
      );

      await repository.updateInvoice(userId, paidInvoice);

      // Verify update
      snapshots = await repository.getInvoices(userId);
      expect(snapshots.first.status, InvoiceStatus.paid);
      expect(snapshots.first.paymentDate, isNotNull);

      // 3. VERIFY STATS (Simulation)
      // In a real app this would call DashboardRepository, but here we verify data integrity
      // that the dashboard would consume.
      final paidInvoices =
          snapshots.where((i) => i.status == InvoiceStatus.paid).toList();
      final totalIncome = paidInvoices.fold(
        0.0,
        (sum, i) => sum + i.grandTotal,
      );
      expect(totalIncome, 1700.0);

      // 4. DELETE INVOICE
      await repository.deleteInvoice(userId, newInvoice.id);

      // Verify deletion
      snapshots = await repository.getInvoices(userId);
      expect(snapshots.isEmpty, true);
    });
  });
}
