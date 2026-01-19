import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/services/export_service.dart';
import '../../export/models/export_models.dart';
import '../../invoices/models/invoice_model.dart';
import '../../expenses/models/expense_model.dart';

class FirestoreExportDataSource implements ExportDataSource {
  final FirebaseFirestore _firestore;
  final String userId;
  final Dio _dio = Dio();

  FirestoreExportDataSource(this._firestore, this.userId);

  @override
  Future<List<InvoiceExportItem>> loadInvoices(ExportPeriod period) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('invoices')
        .where('dateIssued', isGreaterThanOrEqualTo: period.from.toIso8601String())
        .where('dateIssued', isLessThanOrEqualTo: period.to.toIso8601String())
        .get();

    final invoices = snapshot.docs
        .map((doc) => InvoiceModel.fromMap(doc.data(), doc.id))
        .toList();

    final exportItems = <InvoiceExportItem>[];
    for (final inv in invoices) {
      String? localPath;
      if (inv.pdfUrl != null && inv.pdfUrl!.isNotEmpty) {
        localPath = await _downloadFile(inv.pdfUrl!, 'inv_${inv.number}.pdf');
      }
      exportItems.add(InvoiceExportItem(
        id: inv.id,
        number: inv.number,
        issuedAt: inv.dateIssued,
        clientName: inv.clientName,
        totalEur: inv.totalAmount,
        vatEur: inv.totalVat,
        pdfLocalPath: localPath,
      ));
    }
    return exportItems;
  }

  @override
  Future<List<ExpenseExportItem>> loadExpenses(ExportPeriod period) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .where('date', isGreaterThanOrEqualTo: period.from.toIso8601String())
        .where('date', isLessThanOrEqualTo: period.to.toIso8601String())
        .get();

    final expenses = snapshot.docs
        .map((doc) => ExpenseModel.fromMap(doc.data(), doc.id))
        .toList();

    final exportItems = <ExpenseExportItem>[];
    for (final ex in expenses) {
      final localPaths = <String>[];
      for (int i = 0; i < ex.receiptUrls.length; i++) {
        final path = await _downloadFile(
          ex.receiptUrls[i], 
          'exp_${ex.id}_$i${_ext(ex.receiptUrls[i])}'
        );
        if (path != null) localPaths.add(path);
      }
      exportItems.add(ExpenseExportItem(
        id: ex.id,
        date: ex.date,
        vendor: ex.vendorName,
        totalEur: ex.amount,
        category: ex.category?.name ?? 'Other',
        attachmentLocalPaths: localPaths,
      ));
    }
    return exportItems;
  }

  @override
  Future<Map<String, dynamic>> loadRawDump(ExportPeriod period) async {
    // Simplified raw dump for now
    return {
      'metadata': {
        'userId': userId,
        'periodFrom': period.from.toIso8601String(),
        'periodTo': period.to.toIso8601String(),
        'exportedAt': DateTime.now().toIso8601String(),
      }
    };
  }

  Future<String?> _downloadFile(String url, String fileName) async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final downloadDir = Directory(p.join(cacheDir.path, 'export_tmp'));
      if (!await downloadDir.exists()) await downloadDir.create(recursive: true);
      
      final savePath = p.join(downloadDir.path, fileName);
      await _dio.download(url, savePath);
      return savePath;
    } catch (e) {
      return null;
    }
  }

  String _ext(String url) {
    if (url.contains('.png')) return '.png';
    if (url.contains('.jpg')) return '.jpg';
    if (url.contains('.jpeg')) return '.jpeg';
    if (url.contains('.pdf')) return '.pdf';
    return '.img';
  }
}
