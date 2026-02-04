import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/tax_calculation_service.dart';
import '../models/invoice_model.dart';

final taxServiceProvider = Provider((_) => TaxCalculationService());

final invoiceDraftProvider =
    NotifierProvider<InvoiceDraftNotifier, InvoiceModel>(() {
  return InvoiceDraftNotifier();
});

class InvoiceDraftNotifier extends Notifier<InvoiceModel> {
  @override
  InvoiceModel build() => InvoiceModel.empty();

  TaxTotals get totals {
    final tax = ref.read(taxServiceProvider);
    final lines = state.items.map((it) => it.toTaxLine(tax));
    return tax.calcTotals(lines);
  }

  void updateDraft(InvoiceModel invoice) {
    state = invoice;
  }

  void resetDraft() {
    state = InvoiceModel.empty();
  }

  void addItem(InvoiceItemModel item) {
    state = state.copyWith(
      items: [...state.items, item],
    );
  }

  void removeItem(int index) {
    final newItems = List<InvoiceItemModel>.from(state.items)..removeAt(index);
    state = state.copyWith(items: newItems);
  }

  void updateItemVat(int index, double vatRate) {
    final items = [...state.items];
    final old = items[index];
    items[index] = InvoiceItemModel(
      title: old.title,
      amount: old.amount,
      vatRate: vatRate,
    );
    state = state.copyWith(items: items);
  }

  void updateItemAmount(int index, double amount) {
    final items = [...state.items];
    final old = items[index];
    items[index] = InvoiceItemModel(
      title: old.title,
      amount: amount,
      vatRate: old.vatRate,
    );
    state = state.copyWith(items: items);
  }
}
