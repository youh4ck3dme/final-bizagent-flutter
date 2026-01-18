import 'package:flutter_test/flutter_test.dart';
import 'package:bizagent/features/invoices/services/invoice_numbering_service.dart';
import 'package:bizagent/features/invoices/data/invoice_numbering_repository.dart';

class FakeRepo implements InvoiceNumberingRepository {
  LocalPool? pool;
  int remoteSeq = 0;

  @override
  Future<LocalPool?> loadLocalPool(int year) async =>
      pool?.year == year ? pool : null;

  @override
  Future<void> saveLocalPool(LocalPool p) async => pool = p;

  @override
  Future<ReservedBlock> reserveBlock({
    required String uid,
    required int year,
    required int blockSize,
  }) async {
    final start = remoteSeq + 1;
    final end = remoteSeq + blockSize;
    remoteSeq = end;
    return ReservedBlock(start: start, end: end);
  }
}

void main() {
  test('allocates from reserved block pool', () async {
    final repo = FakeRepo();
    final svc = InvoiceNumberingService(repo: repo, blockSize: 3);

    final a = await svc.nextNumber(uid: 'u', now: DateTime(2026, 1, 1));
    final b = await svc.nextNumber(uid: 'u', now: DateTime(2026, 1, 2));
    final c = await svc.nextNumber(uid: 'u', now: DateTime(2026, 1, 3));

    expect(a.number, '2026/001');
    expect(b.number, '2026/002');
    expect(c.number, '2026/003');
    expect(a.isProvisional, false);
  });

  test('formats padded numbering', () {
    final repo = FakeRepo();
    final svc = InvoiceNumberingService(repo: repo);
    expect(svc.formatNumber(2026, 1), '2026/001');
    expect(svc.formatNumber(2026, 12), '2026/012');
    expect(svc.formatNumber(2026, 123), '2026/123');
  });
}
