import 'package:flutter/material.dart';
import '../../features/expenses/models/expense_model.dart';
import '../../features/expenses/models/expense_category.dart';
import '../../features/invoices/models/invoice_model.dart';
import '../../features/proactive/models/proactive_alert_model.dart';
import '../../features/receipt_detective/models/reconstructed_suggestion_model.dart';
import 'demo_scenarios.dart';

/// Profil demo užívateľa (podľa špecu).
class DemoUserProfile {
  final String name;
  final String ico;
  final String dic;
  final String businessType;
  final double monthlyRevenue;
  final bool registeredForVat;

  const DemoUserProfile({
    required this.name,
    required this.ico,
    required this.dic,
    required this.businessType,
    required this.monthlyRevenue,
    this.registeredForVat = false,
  });
}

/// Orphan transakcia pre Receipt Detective (transakcia bez bločku).
class DemoOrphanTransaction {
  final String id;
  final DateTime date;
  final double amount;
  final String merchantHint;

  const DemoOrphanTransaction({
    required this.id,
    required this.date,
    required this.amount,
    required this.merchantHint,
  });
}

/// Záznam GPS pre rekonštrukciu (špec: generateLocationHistory).
class DemoLocationEntry {
  final String placeName;
  final double lat;
  final double lng;
  final DateTime timestamp;

  const DemoLocationEntry({
    required this.placeName,
    required this.lat,
    required this.lng,
    required this.timestamp,
  });
}

/// Fake email pre rekonštrukciu (špec: generateEmails).
class DemoFakeEmail {
  final String subject;
  final String sender;
  final String body;
  final DateTime date;

  const DemoFakeEmail({
    required this.subject,
    required this.sender,
    required this.body,
    required this.date,
  });
}

/// Fake kalendárová udalosť (špec: generateCalendarEvents).
class DemoFakeCalendarEvent {
  final String title;
  final String location;
  final DateTime date;
  final List<String> attendees;

  const DemoFakeCalendarEvent({
    required this.title,
    required this.location,
    required this.date,
    this.attendees = const [],
  });
}

/// Generátor realistických demo dát pre BizAgent AI (Proaktívny účtovník, Bloček Detective).
class DemoDataGenerator {
  DemoDataGenerator._();

  static const String demoUserId = 'demo-user';

  /// Profil demo užívateľa (špec: demoUser).
  static final DemoUserProfile demoUser = const DemoUserProfile(
    name: 'Ján Novák',
    ico: '12345678',
    dic: '1234567890',
    businessType: 'IT Konzultant',
    monthlyRevenue: 4500,
    registeredForVat: false,
  );

  /// Generuje výdavky podľa scenára (6 mesiacov typických pohybov + scenárové dáta).
  static List<ExpenseModel> generateExpenses(DemoScenario scenario) {
    final now = DateTime.now();
    final list = <ExpenseModel>[];

    // Opakované mesačné
    for (var m = 0; m < 6; m++) {
      final base = DateTime(now.year, now.month - m, 1);
      list.add(
        _expense(
          'exp-rent-$m',
          base.add(const Duration(days: 0)),
          450,
          'Nájom kancelária',
          ExpenseCategory.rent,
          hasReceipt: true,
        ),
      );
      list.add(
        _expense(
          'exp-inet-$m',
          base.add(const Duration(days: 4)),
          29.99,
          'Internet Telekom',
          ExpenseCategory.internet,
          hasReceipt: true,
        ),
      );
      list.add(
        _expense(
          'exp-mobil-$m',
          base.add(const Duration(days: 9)),
          35,
          'Mobil O2',
          ExpenseCategory.phone,
          hasReceipt: true,
        ),
      );
      list.add(
        _expense(
          'exp-uct-$m',
          base.add(const Duration(days: 14)),
          150,
          'Účtovník',
          ExpenseCategory.accounting,
          hasReceipt: true,
        ),
      );
      list.add(
        _expense(
          'exp-soft-$m',
          base.add(const Duration(days: 0)),
          89,
          'Software subscriptions',
          ExpenseCategory.software,
          hasReceipt: true,
        ),
      );
    }

    // Premenné mesačné (PHM, kancelária, reštaurácie)
    for (var m = 0; m < 6; m++) {
      final base = DateTime(now.year, now.month - m, 1);
      list.add(
        _expense(
          'exp-phm-$m-1',
          base.add(const Duration(days: 2)),
          180,
          'PHM Shell',
          ExpenseCategory.fuel,
          hasReceipt: true,
        ),
      );
      list.add(
        _expense(
          'exp-phm-$m-2',
          base.add(const Duration(days: 12)),
          210,
          'PHM OMV',
          ExpenseCategory.fuel,
          hasReceipt: true,
        ),
      );
      list.add(
        _expense(
          'exp-kanc-$m',
          base.add(const Duration(days: 8)),
          45,
          'Kancelárske potreby',
          ExpenseCategory.officeSupplies,
          hasReceipt: true,
        ),
      );
      list.add(
        _expense(
          'exp-rest-$m',
          base.add(const Duration(days: 16)),
          38,
          'Reštaurácia',
          ExpenseCategory.meals,
          hasReceipt: false,
        ),
      ); // bez účtenky
    }

    // Kvartálne (poisťovne)
    for (var q = 0; q < 2; q++) {
      final base = DateTime(now.year, now.month - q * 3, 15);
      list.add(
        _expense(
          'exp-sp-$q',
          base,
          180,
          'Sociálna poisťovňa',
          ExpenseCategory.other,
          hasReceipt: true,
        ),
      );
      list.add(
        _expense(
          'exp-zp-$q',
          base,
          80,
          'Zdravotná poisťovňa',
          ExpenseCategory.healthInsurance,
          hasReceipt: true,
        ),
      );
    }

    // Scenárové: výdavky bez účtenky pre Receipt Detective
    if (scenario == DemoScenario.receiptMissing ||
        scenario == DemoScenario.standard) {
      list.add(
        _expense(
          'exp-orphan-1',
          now.subtract(const Duration(days: 2)),
          47.80,
          'CARD PAYMENT POS',
          ExpenseCategory.other,
          hasReceipt: false,
        ),
      );
      list.add(
        _expense(
          'exp-orphan-2',
          now.subtract(const Duration(days: 5)),
          156.30,
          'SEPA TRANSFER',
          ExpenseCategory.other,
          hasReceipt: false,
        ),
      );
    }

    // Anomálie (podozrivé)
    if (scenario == DemoScenario.anomalyDetection) {
      list.add(
        _expense(
          'exp-anom-1',
          now.subtract(const Duration(days: 3)),
          499.99,
          'UNKNOWN VENDOR',
          ExpenseCategory.other,
          hasReceipt: false,
        ),
      );
      list.add(
        _expense(
          'exp-anom-2a',
          now.subtract(const Duration(days: 1)),
          45.50,
          'Tesco',
          ExpenseCategory.other,
          hasReceipt: false,
        ),
      );
      list.add(
        _expense(
          'exp-anom-2b',
          now.subtract(const Duration(days: 1)),
          45.50,
          'Tesco',
          ExpenseCategory.other,
          hasReceipt: false,
        ),
      );
    }

    list.sort((a, b) => b.date.compareTo(a.date));

    // For Tax Optimization scenario, we want FEWER expenses to trigger the "Missing expenses" alert
    if (scenario == DemoScenario.taxOptimization) {
      list.removeWhere((e) => e.category == ExpenseCategory.fuel);
    }

    return list;
  }

  static ExpenseModel _expense(
    String id,
    DateTime date,
    double amount,
    String vendor,
    ExpenseCategory category, {
    bool hasReceipt = true,
  }) {
    return ExpenseModel(
      id: id,
      userId: demoUserId,
      vendorName: vendor,
      description: '',
      amount: amount,
      date: date,
      category: category,
      receiptUrls: hasReceipt ? ['https://demo/receipt/$id'] : [],
      thumbnailUrl: hasReceipt ? 'https://demo/thumb/$id' : null,
      isOcrVerified: hasReceipt,
    );
  }

  /// Generuje faktúry podľa scenára (nezaplatené = prediktívne alerty, obrat pre DPH).
  static List<InvoiceModel> generateInvoices(DemoScenario scenario) {
    final now = DateTime.now();
    final list = <InvoiceModel>[];

    // Odoslané / po splatnosti – spúšťa prediktívny alert
    final dueSoon = now.add(const Duration(days: 3));
    list.add(
      _invoice(
        'inv-1',
        'F-2025-001',
        'Klient Alpha s.r.o.',
        now.subtract(const Duration(days: 20)),
        dueSoon,
        2200,
        InvoiceStatus.sent,
      ),
    );

    if (scenario == DemoScenario.cashflowCrisis) {
      list.add(
        _invoice(
          'inv-2',
          'F-2025-002',
          'Klient Beta a.s.',
          now.subtract(const Duration(days: 10)),
          now.add(const Duration(days: 1)),
          1800,
          InvoiceStatus.sent,
        ),
      );
    }

    // Zaplatené (zvyšujú obrat pre daňový teplomer)
    for (var i = 0; i < 12; i++) {
      final d = DateTime(now.year, now.month - i, 15);
      list.add(
        _invoice(
          'inv-paid-$i',
          'F-${now.year}-${100 + i}',
          'Klient ${i + 1}',
          d,
          d.add(const Duration(days: 14)),
          3500 + i * 100,
          InvoiceStatus.paid,
        ),
      );
    }

    if (scenario == DemoScenario.approachingVat) {
      // Vysoký obrat → DPH warning
      for (var i = 0; i < 5; i++) {
        list.add(
          _invoice(
            'inv-vat-$i',
            'F-VAT-$i',
            'Veľký klient $i',
            now.subtract(Duration(days: 30 * (i + 1))),
            now,
            8000,
            InvoiceStatus.paid,
          ),
        );
      }
    }

    return list;
  }

  static InvoiceModel _invoice(
    String id,
    String number,
    String clientName,
    DateTime dateIssued,
    DateTime dateDue,
    double totalAmount,
    InvoiceStatus status,
  ) {
    return InvoiceModel(
      id: id,
      userId: demoUserId,
      createdAt: dateIssued,
      number: number,
      clientName: clientName,
      dateIssued: dateIssued,
      dateDue: dateDue,
      items: [
        InvoiceItemModel(title: 'Služby', amount: totalAmount, vatRate: 0.0),
      ],
      totalAmount: totalAmount,
      status: status,
    );
  }

  /// Návrhy Bloček Detective z výdavkov (bez účtenky) + voliteľné „bankové“ kandidáty.
  static List<ReconstructedExpenseSuggestion> generateReconstructedSuggestions(
    DemoScenario scenario,
  ) {
    final expenses = generateExpenses(scenario);
    final withoutReceipt = expenses
        .where(
          (e) =>
              e.receiptUrls.isEmpty &&
              (e.thumbnailUrl == null || e.thumbnailUrl!.isEmpty),
        )
        .toList();
    final list = withoutReceipt
        .map(
          (e) => ReconstructedExpenseSuggestion(
            id: 'no-receipt-${e.id}',
            amount: e.amount,
            date: e.date,
            vendorHint: e.vendorName,
            description: e.description.isNotEmpty ? e.description : null,
            source: ReconstructedSource.noReceipt,
            confidence:
                e.vendorName.contains('POS') || e.vendorName.contains('SEPA')
                    ? 72
                    : 70,
            expenseId: e.id,
          ),
        )
        .toList();
    // Pridaj „bankové“ kandidáty pre scenár receipt_missing
    if (scenario == DemoScenario.receiptMissing) {
      list.add(
        ReconstructedExpenseSuggestion(
          id: 'orphan-bank-1',
          amount: 47.80,
          date: DateTime.now().subtract(const Duration(days: 2)),
          vendorHint: 'CARD PAYMENT POS',
          source: ReconstructedSource.bank,
          confidence: 85,
          bankTxId: 'tx-1',
        ),
      );
      list.add(
        ReconstructedExpenseSuggestion(
          id: 'orphan-bank-2',
          amount: 156.30,
          date: DateTime.now().subtract(const Duration(days: 5)),
          vendorHint: 'SEPA TRANSFER',
          source: ReconstructedSource.bank,
          confidence: 78,
          bankTxId: 'tx-2',
        ),
      );
    }
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  /// Generuje proaktívne alerty pre demo (prediktívne, daňový stratég, anomália).
  static List<ProactiveAlert> generateProactiveAlerts(DemoScenario scenario) {
    final now = DateTime.now();
    final alerts = <ProactiveAlert>[];

    switch (scenario) {
      case DemoScenario.standard:
        alerts.add(
          ProactiveAlert(
            id: 'demo-pred-1',
            type: ProactiveAlertType.predictive,
            title: 'O 3 dní splatnosť faktúry',
            body: 'Faktúra F-2025-001 (~€2200) splatná o 3 dni.',
            actionLabel: 'Detail faktúry',
            actionRoute: '/invoices',
            dueDate: now.add(const Duration(days: 3)),
            amount: 2200,
            icon: Icons.notifications_active,
            color: Colors.orange,
            createdAt: now,
          ),
        );
        break;
      case DemoScenario.taxOptimization:
        alerts.add(
          ProactiveAlert(
            id: 'demo-tax-1',
            type: ProactiveAlertType.taxStrategist,
            title: 'Daňový stratég',
            body:
                'Do konca kvartálu ti chýba €500 vo výdavkoch. Kúp teraz potreby – ušetríš cca €95 na daniach.',
            actionLabel: 'Pridať výdavok',
            actionRoute: '/create-expense',
            amount: 500,
            secondaryAmount: 95,
            icon: Icons.savings_outlined,
            color: Colors.green,
            createdAt: now,
          ),
        );
        break;
      case DemoScenario.approachingVat:
        alerts.add(
          ProactiveAlert(
            id: 'demo-vat-1',
            type: ProactiveAlertType.taxStrategist,
            title: 'Blížiš sa k limitu DPH',
            body:
                'Obrat za 12 mesiacov je 85% limitu (49 790 €). Zváž pripravu na registráciu DPH.',
            actionLabel: 'Daňový prehľad',
            actionRoute: '/analytics',
            amount: 42000,
            secondaryAmount: 49790,
            icon: Icons.warning_amber_rounded,
            color: Colors.amber,
            createdAt: now,
          ),
        );
        break;
      case DemoScenario.anomalyDetection:
        alerts.add(
          ProactiveAlert(
            id: 'demo-anom-1',
            type: ProactiveAlertType.anomaly,
            title: 'Podozrivá transakcia',
            body: 'Platba 499,99 € pre "UNKNOWN VENDOR" – overte si doklad.',
            amount: 499.99,
            icon: Icons.warning,
            color: Colors.red,
            createdAt: now,
          ),
        );
        break;
      case DemoScenario.cashflowCrisis:
        alerts.add(
          ProactiveAlert(
            id: 'demo-cf-1',
            type: ProactiveAlertType.predictive,
            title: 'Nízky cashflow',
            body: 'Dve splatné faktúry (~€4000). Odporúčam presun z rezervy.',
            amount: 4000,
            icon: Icons.account_balance_wallet,
            color: Colors.orange,
            createdAt: now,
          ),
        );
        break;
      case DemoScenario.receiptMissing:
        break;
    }
    return alerts;
  }

  /// Veľký dataset pre performance testy (počet výdavkov).
  static List<ExpenseModel> generateLargeExpenseDataset(int count) {
    final now = DateTime.now();
    return List.generate(count, (i) {
      final d = now.subtract(Duration(days: i % 180));
      return _expense(
        'perf-exp-$i',
        d,
        50.0 + (i % 200),
        'Vendor $i',
        ExpenseCategory.values[i % ExpenseCategory.values.length],
        hasReceipt: i % 3 != 0,
      );
    });
  }
}
