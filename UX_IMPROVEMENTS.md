# BizAgent - 10 najväčších UX/Quality zlepšení

Analýza Flutter projektu BizAgent identifikovala tieto konkrétne zlepšenia s minimálnymi zmenami kódu.

---

## 1. Pull-to-refresh na Dashboard a zoznamoch
**Problém**: Používateľ nemá jednoduchý spôsob, ako obnoviť dáta na dashboarde, zoznamoch faktúr a výdavkov.

**Súbory na zmenu**:
- `lib/features/dashboard/screens/dashboard_screen.dart`
- `lib/features/invoices/screens/invoices_screen.dart`
- `lib/features/expenses/screens/expenses_screen.dart`

**Náročnosť**: S (Small)

**Riešenie**: Obaliť `SingleChildScrollView` / `ListView` s `RefreshIndicator` widgetom.

```dart
RefreshIndicator(
  onRefresh: () async {
    ref.invalidate(invoicesProvider);
    await ref.read(invoicesProvider.future);
  },
  child: ListView.builder(...),
)
```

**Test coverage**:
```dart
testWidgets('Dashboard pull-to-refresh invalidates providers', (tester) async {
  await tester.pumpWidget(TestApp(child: DashboardScreen()));
  await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
  await tester.pumpAndSettle();
  // Verify providers were invalidated
});
```

---

## 2. Undo akcia po zmazaní výdavku (Dismissible)
**Problém**: Keď používateľ swipne výdavok a omylom ho zmaže, nemá možnosť vrátiť akciu.

**Súbory na zmenu**:
- `lib/features/expenses/screens/expenses_screen.dart`

**Náročnosť**: S (Small)

**Riešenie**: Pridať SnackBar s undo akciou pred finálnym zmazaním.

```dart
onDismissed: (_) {
  final deletedExpense = expense;
  ref.read(expensesControllerProvider.notifier).deleteExpense(expense.id);
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Výdavok zmazaný'),
      action: SnackBarAction(
        label: 'VRÁTIŤ',
        onPressed: () {
          ref.read(expensesControllerProvider.notifier).addExpense(deletedExpense);
        },
      ),
      duration: Duration(seconds: 3),
    ),
  );
},
```

**Test coverage**:
```dart
testWidgets('Expense dismissible shows undo snackbar', (tester) async {
  await tester.pumpWidget(TestApp(child: ExpensesScreen()));
  await tester.drag(find.byType(Dismissible).first, const Offset(-500, 0));
  await tester.pumpAndSettle();
  expect(find.text('VRÁTIŤ'), findsOneWidget);
});
```

---

## 3. Email validácia v reálnom čase na Login
**Problém**: Používateľ vidí chybu až po kliknutí na tlačidlo, nie počas písania.

**Súbory na zmenu**:
- `lib/features/auth/screens/login_screen.dart`

**Náročnosť**: S (Small)

**Riešenie**: Pridať `autovalidateMode` a lepší email validator.

```dart
Form(
  key: _formKey,
  autovalidateMode: AutovalidateMode.onUserInteraction,
  child: Column(...),
)

// V TextFormField pre email
validator: (value) {
  if (value == null || value.isEmpty) {
    return 'Prosím zadajte email';
  }
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  if (!emailRegex.hasMatch(value)) {
    return 'Neplatný email formát';
  }
  return null;
},
```

**Test coverage**:
```dart
testWidgets('Email validator shows error for invalid format', (tester) async {
  await tester.pumpWidget(TestApp(child: LoginScreen()));
  await tester.enterText(find.byType(TextFormField).first, 'invalid-email');
  await tester.pump();
  expect(find.text('Neplatný email formát'), findsOneWidget);
});
```

---

## 4. Vizuálny feedback pri pridávaní položky do faktúry
**Problém**: Po kliknutí na ikonu "add" pri pridávaní položky faktúry nie je žiadny vizuálny feedback.

**Súbory na zmenu**:
- `lib/features/invoices/screens/create_invoice_screen.dart`

**Náročnosť**: S (Small)

**Riešenie**: Animovaný icon button alebo micro-animácia pri pridaní.

```dart
IconButton(
  onPressed: () {
    if (_itemDescController.text.isEmpty || _itemPriceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vyplňte popis a cenu'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }
    _addItem(isVatPayer);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Položka pridaná: ${_itemDescController.text}'),
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
      ),
    );
  },
  icon: const Icon(Icons.add_circle, color: Colors.blue, size: 32),
),
```

**Test coverage**:
```dart
testWidgets('Adding invoice item shows feedback snackbar', (tester) async {
  await tester.pumpWidget(TestApp(child: CreateInvoiceScreen()));
  await tester.enterText(find.byType(TextField).first, 'Test položka');
  await tester.enterText(find.byType(TextField).at(2), '100');
  await tester.tap(find.byIcon(Icons.add_circle));
  await tester.pump();
  expect(find.textContaining('Položka pridaná'), findsOneWidget);
});
```

---

## 5. Potvrdenie pred opustením formuláru s neuloženými zmenami
**Problém**: Používateľ môže stlačiť back button na vytváraní faktúry/výdavku a stratiť rozpracované dáta.

**Súbory na zmenu**:
- `lib/features/invoices/screens/create_invoice_screen.dart`
- `lib/features/expenses/screens/create_expense_screen.dart`
- `lib/features/settings/screens/settings_screen.dart`

**Náročnosť**: M (Medium)

**Riešenie**: Implementovať `WillPopScope` (alebo `PopScope` pre Flutter 3.16+) s dialógom.

```dart
return PopScope(
  canPop: false,
  onPopInvoked: (didPop) async {
    if (didPop) return;
    
    final hasData = _clientNameController.text.isNotEmpty || _items.isNotEmpty;
    if (!hasData) {
      Navigator.of(context).pop();
      return;
    }
    
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Neuložené zmeny'),
        content: const Text('Chcete odísť bez uloženia?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ZOSTAŤ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ODÍSŤ'),
          ),
        ],
      ),
    );
    
    if (shouldPop == true && context.mounted) {
      Navigator.of(context).pop();
    }
  },
  child: Scaffold(...),
);
```

**Test coverage**:
```dart
testWidgets('Shows confirmation dialog when leaving form with data', (tester) async {
  await tester.pumpWidget(TestApp(child: CreateInvoiceScreen()));
  await tester.enterText(find.byType(TextFormField).first, 'Test Client');
  await tester.pageBack();
  await tester.pumpAndSettle();
  expect(find.text('Neuložené zmeny'), findsOneWidget);
});
```

---

## 6. Loading skeleton namiesto prázdneho CircularProgressIndicator
**Problém**: Počas načítavania dát sa zobrazuje len krutiaci sa indikátor, čo vyzerá lacno.

**Súbory na zmenu**:
- `lib/features/dashboard/screens/dashboard_screen.dart`
- `lib/features/invoices/screens/invoices_screen.dart`
- `lib/features/expenses/screens/expenses_screen.dart`

**Náročnosť**: M (Medium)

**Riešenie**: Použiť Shimmer efekt pre lepšiu UX (balík už je v dependencies).

```dart
loading: () => ListView.builder(
  itemCount: 3,
  padding: const EdgeInsets.all(16),
  itemBuilder: (context, index) => Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Card(
      child: ListTile(
        leading: CircleAvatar(backgroundColor: Colors.grey[300]),
        title: Container(height: 16, color: Colors.grey[300]),
        subtitle: Container(height: 12, color: Colors.grey[300]),
        trailing: Container(width: 60, height: 16, color: Colors.grey[300]),
      ),
    ),
  ),
),
```

**Test coverage**:
```dart
testWidgets('Shows shimmer loading state', (tester) async {
  await tester.pumpWidget(TestApp(child: InvoicesScreen()));
  expect(find.byType(Shimmer), findsWidgets);
});
```

---

## 7. Inline editácia položiek faktúry
**Problém**: Po pridaní položky do faktúry ju nemožno upraviť - len zmazať a vytvoriť znova.

**Súbory na zmenu**:
- `lib/features/invoices/screens/create_invoice_screen.dart`

**Náročnosť**: M (Medium)

**Riešenie**: Pridať onTap na ListTile položky, ktorý otvorí edit dialog.

```dart
ListTile(
  contentPadding: EdgeInsets.zero,
  title: Text(item.description),
  subtitle: Text('${item.quantity} x ${item.unitPrice} €  (DPH ${(item.vatRate * 100).toInt()}%)'),
  onTap: () => _editItem(idx, item),
  trailing: Row(...),
)

Future<void> _editItem(int index, InvoiceItemModel item) async {
  final controllers = {
    'desc': TextEditingController(text: item.description),
    'qty': TextEditingController(text: item.quantity.toString()),
    'price': TextEditingController(text: item.unitPrice.toString()),
  };
  
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Upraviť položku'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: controllers['desc'], decoration: InputDecoration(labelText: 'Popis')),
          TextField(controller: controllers['qty'], decoration: InputDecoration(labelText: 'Množstvo')),
          TextField(controller: controllers['price'], decoration: InputDecoration(labelText: 'Cena')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('ZRUŠIŤ')),
        TextButton(
          onPressed: () {
            setState(() {
              _items[index] = InvoiceItemModel(
                title: controllers['desc']!.text,
                amount: (double.tryParse(controllers['qty']!.text) ?? 1.0) * 
                        (double.tryParse(controllers['price']!.text) ?? 0.0),
                vatRate: item.vatRate,
              );
            });
            Navigator.pop(context, true);
          },
          child: Text('ULOŽIŤ'),
        ),
      ],
    ),
  );
}
```

**Test coverage**:
```dart
testWidgets('Can edit invoice item inline', (tester) async {
  await tester.pumpWidget(TestApp(child: CreateInvoiceScreen()));
  // Add item first, then tap to edit
  await tester.tap(find.byType(ListTile).first);
  await tester.pumpAndSettle();
  expect(find.text('Upraviť položku'), findsOneWidget);
});
```

---

## 8. Vyhľadávanie a filtrovanie v zoznamoch
**Problém**: Pri veľkom množstve faktúr/výdavkov používateľ nemá možnosť vyhľadávať alebo filtrovať.

**Súbory na zmenu**:
- `lib/features/invoices/screens/invoices_screen.dart`
- `lib/features/expenses/screens/expenses_screen.dart`

**Náročnosť**: M (Medium)

**Riešenie**: Pridať SearchBar do AppBar a filtrovať lokálne.

```dart
class InvoicesScreen extends ConsumerStatefulWidget {
  const InvoicesScreen({super.key});

  @override
  ConsumerState<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends ConsumerState<InvoicesScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(invoicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: InputDecoration(
            hintText: 'Hľadať faktúry...',
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
      ),
      body: invoicesAsync.when(
        data: (invoices) {
          final filtered = invoices.where((inv) {
            final query = _searchQuery.toLowerCase();
            return inv.clientName.toLowerCase().contains(query) ||
                   inv.number.toLowerCase().contains(query);
          }).toList();
          
          if (filtered.isEmpty) {
            return BizEmptyState(
              title: 'Žiadne výsledky',
              body: 'Skúste iný výraz',
              icon: Icons.search_off,
            );
          }
          
          return ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final invoice = filtered[index];
              // ... existing ListTile code
            },
          );
        },
        // ... error and loading states
      ),
    );
  }
}
```

**Test coverage**:
```dart
testWidgets('Filters invoices based on search query', (tester) async {
  await tester.pumpWidget(TestApp(child: InvoicesScreen()));
  await tester.enterText(find.byType(TextField), 'Test Client');
  await tester.pump();
  expect(find.text('Test Client'), findsWidgets);
  expect(find.text('Other Client'), findsNothing);
});
```

---

## 9. Automatické ukladanie draft faktúry
**Problém**: Ak používateľ rozpracuje faktúru a aplikácia spadne alebo ju zabije systém, všetky dáta sa stratia.

**Súbory na zmenu**:
- `lib/features/invoices/screens/create_invoice_screen.dart`
- `lib/features/invoices/providers/invoice_draft_provider.dart` (použiť existujúci provider)

**Náročnosť**: M (Medium)

**Riešenie**: Použiť SharedPreferences na auto-save každých 10 sekúnd.

```dart
class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    _loadDraft();
    _autoSaveTimer = Timer.periodic(Duration(seconds: 10), (_) => _saveDraft());
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  Future<void> _saveDraft() async {
    if (_clientNameController.text.isEmpty && _items.isEmpty) return;
    
    final draft = {
      'clientName': _clientNameController.text,
      'clientAddress': _clientAddressController.text,
      'items': _items.map((i) => i.toJson()).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('invoice_draft', jsonEncode(draft));
  }

  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draftStr = prefs.getString('invoice_draft');
    if (draftStr == null) return;
    
    final shouldRestore = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Obnoviť rozpracovanú faktúru?'),
        content: Text('Našli sme neuloženú faktúru.'),
        actions: [
          TextButton(
            onPressed: () {
              prefs.remove('invoice_draft');
              Navigator.pop(context, false);
            },
            child: Text('ZAHODIŤ'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('OBNOVIŤ'),
          ),
        ],
      ),
    );
    
    if (shouldRestore == true) {
      final draft = jsonDecode(draftStr);
      setState(() {
        _clientNameController.text = draft['clientName'] ?? '';
        _clientAddressController.text = draft['clientAddress'] ?? '';
        // Restore items...
      });
    }
  }
}
```

**Test coverage**:
```dart
testWidgets('Auto-saves draft invoice periodically', (tester) async {
  await tester.pumpWidget(TestApp(child: CreateInvoiceScreen()));
  await tester.enterText(find.byType(TextFormField).first, 'Draft Client');
  await tester.pump(Duration(seconds: 11));
  
  final prefs = await SharedPreferences.getInstance();
  expect(prefs.getString('invoice_draft'), isNotNull);
});
```

---

## 10. Stav úspechu po uložení faktúry/výdavku
**Problém**: Po úspešnom uložení faktúry/výdavku sa screen len zatvorí bez vizuálneho feedbacku.

**Súbory na zmenu**:
- `lib/features/invoices/screens/create_invoice_screen.dart`
- `lib/features/expenses/screens/create_expense_screen.dart`

**Náročnosť**: S (Small)

**Riešenie**: Pridať success screen s animáciou pred zatvorením.

```dart
Future<void> _saveInvoice() async {
  if (!_formKey.currentState!.validate()) return;
  if (_items.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pridajte aspoň jednu položku')),
    );
    return;
  }

  // ... existing invoice creation code

  try {
    await ref.read(invoicesControllerProvider.notifier).addInvoice(invoice);
    
    if (mounted) {
      // Show success overlay
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 64),
                SizedBox(height: 16),
                Text(
                  'Faktúra vytvorená!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('Číslo: ${invoice.number}'),
              ],
            ),
          ),
        ),
      );
      
      // Auto-close after 1.5 seconds
      await Future.delayed(Duration(milliseconds: 1500));
      if (mounted) Navigator.of(context).pop();
      if (mounted) Navigator.of(context).pop();
    }
  } catch (e) {
    // ... existing error handling
  }
}
```

**Test coverage**:
```dart
testWidgets('Shows success dialog after saving invoice', (tester) async {
  await tester.pumpWidget(TestApp(child: CreateInvoiceScreen()));
  // Fill in required fields and save
  await tester.tap(find.text('Uložiť'));
  await tester.pumpAndSettle();
  expect(find.text('Faktúra vytvorená!'), findsOneWidget);
  expect(find.byIcon(Icons.check_circle), findsOneWidget);
});
```

---

## Prioritizácia implementácie

### Rýchle víťazstvá (Quick wins - implementovať najskôr):
1. Pull-to-refresh (S)
2. Undo pre Dismissible (S)  
3. Email validácia (S)
4. Feedback pri pridaní položky (S)
5. Success screen po uložení (S)

### Stredná priorita:
6. Loading skeleton (M)
7. Potvrdenie pred opustením formulára (M)

### Nižšia priorita (ale vysoký dopad):
8. Inline editácia položiek (M)
9. Vyhľadávanie (M)
10. Auto-save draft (M)

---

## Testovacia stratégia

Pre každé zlepšenie vytvoriť:
1. **Widget test** - testuje UI interakciu
2. **Integration test** - testuje flow end-to-end
3. **Manual test checklist** - pre QA

### Príklad manuálneho test checklistu pre #1 (Pull-to-refresh):

```
☐ Dashboard - potiahni dole a uvoľni
  ☐ Zobrazí sa refresh indikátor
  ☐ Dáta sa aktualizujú
  ☐ Indikátor zmizne po načítaní
☐ Faktúry - potiahni dole a uvoľni
  ☐ Zobrazí sa refresh indikátor
  ☐ Dáta sa aktualizujú
☐ Výdavky - potiahni dole a uvoľni
  ☐ Dáta sa aktualizujú
```

---

## Metriky úspechu

Po implementácii merať:
- **Crash rate** - malo by klesnúť vďaka lepšej validácii
- **Time to create invoice** - malo by sa skrátiť vďaka UX vylepšeniam
- **User retention** - lepšia UX = viac vracajúcich sa používateľov
- **Support tickets** - menej otázok o tom, ako niečo urobiť

---

## Záver

Všetky navrhované zlepšenia:
- ✅ Minimálne zmeny kódu (1 súbor až 3 súbory)
- ✅ Jasná testovateľnosť
- ✅ Konkrétne riešenia, nie všeobecné rady
- ✅ Vysoký dopad na UX
- ✅ Rýchla implementácia (S/M náročnosť)
