# 🚀 BizAgent Implementation Master Plan

> **Status:** 🚧 Planning Phase  
> **Last Updated:** January 17, 2026

## 📋 Current State Assessment (Poradok)

### ✅ What Works (Functional)
*   **Authentication**: Login/Register with Firebase Auth.
*   **Invoicing**: Create, List, Detail view. PDF generation works.
*   **Expenses**: Basic CRUD. OCR scanning extracts amount/date/vendor.
*   **Dashboard**: Basic financial overview (Income vs Expense).
*   **Settings**: Company profile saving.

### ❌ What Is Missing (To Be Implemented)
*   **Smart Categorization**: Expenses are uncategorized. No auto-tagging.
*   **Advanced Analytics**: No deep insights, trends, or predictions.
*   **Monetization**: No paywall, subscription model, or limits.
*   **Production Readiness**: Security rules, rigorous testing, optimization.
*   **AI Assistant**: The `ai_tools` feature is currently empty.

---

## 📅 Implementation Roadmap

We will proceed in the following order:

### Phase 1: Expense Intelligence (PROMPT 2) 🧠
**Goal**: Make expense tracking smart and automated.
1.  Define `ExpenseCategory` enum (25+ SK categories).
2.  Build `CategorizationService` with regex rules.
3.  Update `CreateExpenseScreen` with category selector.
4.  Create `ExpenseAnalyticsScreen` (charts, trends).
5.  Implement Advanced Filtering & Receipt Management.

### Phase 2: Business Insights Dashboard (PROMPT 3) 📊
**Goal**: Provide actionable real-time business metrics.
1.  Implement `RevenueMetrics` & `ProfitMetrics` providers.
2.  Build 6 Dashboard Widgets (Revenue, Expense, Profit, Alerts, Trends, Quick Actions).
3.  Add Payment Tracking to Invoices.
4.  Implement Local Notifications for deadlines.

### Phase 3: Monetization & Onboarding (PROMPT 4) 💰
**Goal**: Convert users to paid subscribers.
1.  Design 3-Step Onboarding Wizard.
2.  Define `SubscriptionPlan` models (Free vs Premium vs Pro).
3.  Implement `UsageLimits` provider (Paywall logic).
4.  Integrate In-App Purchases (`iap_service.dart`).
5.  Create Upgrade Prompts & Subscription Screen.

### Phase 4: Production Launch (PROMPT 5) 🚀
**Goal**: Secure and polish for Google Play Store.
1.  Deploy Firestore Security Rules.
2.  Optimize Performance (Queries, Image Compression).
3.  Execute Comprehensive Testing Suite (90% coverage).
4.  Finalize Firebase Setup (Crashlytics, Analytics).
5.  Prepare Store Listing (Metadata, Screenshots, Privacy Policy).

---

## 📝 Detailed Prompts

### 💰 PROMPT 2: EXPENSE INTELLIGENCE & CATEGORY SYSTEM

```markdown
Implementuješ SMART expense tracking s AI-powered categorization pre BizAgent.

AKTUÁLNY STAV:
- OCR funguje (extracts amount, date, vendor)
- Chýba: category system, filtering, analytics

POŽIADAVKY:

1. EXPENSE CATEGORY SYSTEM
   Vytvor 25+ SK-relevant categories:
   ```dart
   enum ExpenseCategory {
     // Transportation
     fuel('Palivo', Icons.local_gas_station, Colors.red),
     parking('Parkovanie', Icons.local_parking, Colors.orange),
     carMaintenance('Údržba auta', Icons.car_repair, Colors.deepOrange),
     
     // Office
     officeSupplies('Kancelárske potreby', Icons.business_center, Colors.blue),
     software('Software', Icons.computer, Colors.indigo),
     equipment('Vybavenie', Icons.devices, Colors.cyan),
     
     // Communication
     phone('Telefón', Icons.phone, Colors.green),
     internet('Internet', Icons.wifi, Colors.teal),
     
     // Travel
     accommodation('Ubytovanie', Icons.hotel, Colors.purple),
     food('Strava', Icons.restaurant, Colors.amber),
     flights('Letenky', Icons.flight, Colors.lightBlue),
     
     // Insurance & Health
     healthInsurance('Zdravotné poistenie', Icons.health_and_safety, Colors.pink),
     liability('Poistenie zodpovednosti', Icons.shield, Colors.brown),
     
     // Professional Services
     accounting('Účtovníctvo', Icons.calculate, Colors.deepPurple),
     legal('Právne služby', Icons.gavel, Colors.blueGrey),
     marketing('Marketing', Icons.campaign, Colors.lime),
     
     // Utilities
     rent('Nájom', Icons.home, Colors.brown),
     electricity('Elektrina', Icons.electric_bolt, Colors.yellow),
     
     // Other
     education('Vzdelávanie', Icons.school, Colors.indigo),
     other('Ostatné', Icons.more_horiz, Colors.grey);
     
     final String label;
     final IconData icon;
     final Color color;
     
     const ExpenseCategory(this.label, this.icon, this.color);
   }
   ```

2. AUTO-CATEGORIZATION ENGINE
   Vytvor `lib/features/expenses/services/categorization_service.dart`:
   ```dart
   class CategorizationService {
     ExpenseCategory predictCategory(String vendor, String description) {
       final text = '$vendor $description'.toLowerCase();
       
       // Rule-based matching
       if (text.contains('shell') || text.contains('slovnaft') || text.contains('benzín')) {
         return ExpenseCategory.fuel;
       }
       if (text.contains('hotel') || text.contains('booking')) {
         return ExpenseCategory.accommodation;
       }
       if (text.contains('orange') || text.contains('telekom') || text.contains('o2')) {
         return ExpenseCategory.phone;
       }
       // Add 50+ more rules
       
       return ExpenseCategory.other;
     }
   }
   ```

3. EXPENSE ANALYTICS DASHBOARD
   Vytvor `lib/features/expenses/screens/expense_analytics_screen.dart`:
   - Monthly trend chart (fl_chart line graph)
   - Category breakdown pie chart
   - Top 5 vendors (spending)
   - Average expense per day
   - Comparison: This month vs last month
   
   Widgets:
   - ExpenseTrendChart (6-month view)
   - CategoryPieChart (tap to filter by category)
   - VendorLeaderboard (top spenders)
   - MonthlyComparisonCard

4. ADVANCED FILTERING
   Update ExpenseListScreen:
   - Filter by category (multi-select)
   - Filter by date range (date picker)
   - Filter by amount range (min/max)
   - Search by vendor name
   - Sort by: date, amount, category

5. RECEIPT MANAGEMENT
   Upgrade OCR workflow:
   - Store original receipt image (Firebase Storage)
   - Display receipt thumbnail in expense list
   - Full-screen receipt viewer
   - Re-run OCR if needed (edit button)

DELIVERABLES:
1. ExpenseCategory enum (25+ categories)
2. CategorizationService s regex rules
3. Updated CreateExpenseScreen (category selector)
4. ExpenseAnalyticsScreen (charts + insights)
5. Advanced filtering UI
6. Receipt storage service
7. Unit tests pre auto-categorization
8. Widget tests pre analytics screen
```

### 📊 PROMPT 3: BUSINESS INSIGHTS DASHBOARD (DATA-DRIVEN UI)

```markdown
Vytváraš INTELLIGENT dashboard s real-time business metrics pre BizAgent.

AKTUÁLNY STAV:
- Dashboard existuje ale je základný
- Chýba: aggregations, trends, actionable insights

POŽIADAVKY:

1. REVENUE ANALYTICS
   Vytvor `lib/features/dashboard/providers/revenue_provider.dart`:
   ```dart
   @riverpod
   Future<RevenueMetrics> revenueMetrics(ref) async {
     final uid = ref.watch(authStateProvider).value!.uid;
     final invoices = await ref.watch(invoiceRepositoryProvider)
       .getInvoices(uid);
     
     final now = DateTime.now();
     final thisMonth = invoices.where((inv) => 
       inv.createdAt.month == now.month && 
       inv.createdAt.year == now.year
     );
     
     final lastMonth = invoices.where((inv) =>
       inv.createdAt.month == now.month - 1 &&
       inv.createdAt.year == now.year
     );
     
     return RevenueMetrics(
       totalRevenue: invoices.fold(0.0, (sum, inv) => sum + inv.grandTotal),
       thisMonthRevenue: thisMonth.fold(0.0, (sum, inv) => sum + inv.grandTotal),
       lastMonthRevenue: lastMonth.fold(0.0, (sum, inv) => sum + inv.grandTotal),
       unpaidAmount: invoices.where((inv) => inv.status == InvoiceStatus.sent)
         .fold(0.0, (sum, inv) => sum + inv.grandTotal),
       overdueCount: invoices.where((inv) => 
         inv.status == InvoiceStatus.sent && 
         inv.dueDate.isBefore(now)
       ).length,
       averageInvoiceValue: invoices.isEmpty ? 0 : 
         invoices.fold(0.0, (sum, inv) => sum + inv.grandTotal) / invoices.length,
     );
   }
   ```

2. PROFIT CALCULATOR
   ```dart
   @riverpod
   Future<ProfitMetrics> profitMetrics(ref) async {
     final revenue = await ref.watch(revenueMetricsProvider.future);
     final expenses = await ref.watch(expenseRepositoryProvider).getTotalExpenses();
     
     return ProfitMetrics(
       profit: revenue.totalRevenue - expenses.totalAmount,
       profitMargin: revenue.totalRevenue == 0 ? 0 :
         (revenue.totalRevenue - expenses.totalAmount) / revenue.totalRevenue,
       thisMonthProfit: revenue.thisMonthRevenue - expenses.thisMonthAmount,
     );
   }
   ```

3. DASHBOARD WIDGETS (6 CARDS)
   a) RevenueCard:
      - Total revenue (large number)
      - This month vs last month (% change, green/red arrow)
      - Tap to see details
   
   b) ExpenseCard:
      - Total expenses
      - This month trend
      - Top category
   
   c) ProfitCard:
      - Net profit
      - Profit margin %
      - Color: green (>20%), yellow (10-20%), red (<10%)
   
   d) UnpaidInvoicesAlert:
      - Number of unpaid invoices
      - Total unpaid amount
      - Overdue count (red badge)
      - Tap to see list
   
   e) TrendChart:
      - 6-month revenue vs expense line chart
      - Interactive (tap to see month details)
   
   f) QuickActions:
      - "Vytvoriť faktúru" button
      - "Pridať výdavok" button
      - "Nastaviť pripomienku" button

4. PAYMENT TRACKING
   Add to Invoice model:
   - Payment status: unpaid, partial, paid
   - Payment date
   - Payment method
   - Average days to payment (analytics)

5. NOTIFICATIONS & REMINDERS
   Vytvor `lib/features/notifications/services/notification_service.dart`:
   - Invoice due in 3 days
   - Invoice overdue
   - Tax deadline in 7 days
   - Monthly summary (1st of month)

DELIVERABLES:
1. RevenueMetrics provider
2. ProfitMetrics provider
3. 6 dashboard widgets (fully implemented)
4. Updated Invoice model (payment tracking)
5. NotificationService (local notifications)
6. Unit tests pre metrics calculations
7. Widget tests pre dashboard cards
```

### 🎯 PROMPT 4: ONBOARDING & FREEMIUM MONETIZATION

```markdown
Implementuješ CONVERSION-OPTIMIZED onboarding + freemium model pre BizAgent.

AKTUÁLNY STAV:
- Auth funguje
- Chýba: guided onboarding, paywall, in-app purchases

POŽIADAVKY:

1. ONBOARDING FLOW (3-STEP WIZARD)
   Vytvor `lib/features/onboarding/screens/onboarding_screen.dart`:
   
   Step 1: Welcome
   - "Vitajte v BizAgent!"
   - "Automatizujte faktúry a účtenky za 2 minúty"
   - Illustration (use Flutter assets)
   - "Začať" button
   
   Step 2: Business Setup
   - Form fields:
     * Názov firmy (required)
     * ICO (8 digits, validated)
     * DIČ (optional)
     * Logo upload (optional, skip button)
   - "Pokračovať" button
   
   Step 3: First Invoice Tutorial
   - Guided walkthrough:
     * "Skúsme vytvoriť prvú faktúru"
     * Pre-filled demo 
       - Client: "Demo Klient"
       - Item: "Konzultácia - 100 EUR"
     * "Vygenerovať PDF" button
     * Show PDF preview
     * "Hotovo! Teraz môžete začať používať BizAgent"

2. FREEMIUM PLAN LOGIC
   Vytvor `lib/features/subscription/models/subscription_plan.dart`:
   ```dart
   enum SubscriptionPlan {
     free(
       name: 'Free',
       monthlyInvoiceLimit: 5,
       monthlyExpenseLimit: 20,
       features: ['Základné faktúry', 'OCR účtenky', 'Manuálne záznamy'],
     ),
     premium(
       name: 'Premium',
       price: 9.99,
       monthlyInvoiceLimit: null, // unlimited
       monthlyExpenseLimit: null,
       features: [
         'Neobmedzené faktúry',
         'Neobmedzené výdavky',
         'Pokročilé reporty',
         'AI insights',
         'Prioritná podpora',
       ],
     ),
     pro(
       name: 'Pro',
       price: 19.99,
       monthlyInvoiceLimit: null,
       monthlyExpenseLimit: null,
       features: [
         'Všetko z Premium',
         'Email automation',
         'Opakované faktúry',
         'API prístup',
         'White-label',
       ],
     );
     
     final String name;
     final double? price;
     final int? monthlyInvoiceLimit;
     final int? monthlyExpenseLimit;
     final List<String> features;
   }
   ```

3. PAYWALL ENFORCEMENT
   Vytvor `lib/features/subscription/providers/usage_limiter_provider.dart`:
   ```dart
   @riverpod
   Future<UsageLimits> usageLimits(ref) async {
     final uid = ref.watch(authStateProvider).value!.uid;
     final subscription = await ref.watch(subscriptionProvider(uid).future);
     final invoiceCount = await ref.watch(invoiceCountThisMonthProvider.future);
     final expenseCount = await ref.watch(expenseCountThisMonthProvider.future);
     
     return UsageLimits(
       canCreateInvoice: subscription.plan.monthlyInvoiceLimit == null ||
         invoiceCount < subscription.plan.monthlyInvoiceLimit!,
       canCreateExpense: subscription.plan.monthlyExpenseLimit == null ||
         expenseCount < subscription.plan.monthlyExpenseLimit!,
       invoicesRemaining: subscription.plan.monthlyInvoiceLimit == null ? null :
         subscription.plan.monthlyInvoiceLimit! - invoiceCount,
       expensesRemaining: subscription.plan.monthlyExpenseLimit == null ? null :
         subscription.plan.monthlyExpenseLimit! - expenseCount,
     );
   }
   ```

4. IN-APP PURCHASE INTEGRATION
   Setup `in_app_purchase` plugin:
   ```dart
   // lib/features/subscription/services/iap_service.dart
   class IAPService {
     final InAppPurchase _iap = InAppPurchase.instance;
     
     Future<void> initializeStore() async {
       final available = await _iap.isAvailable();
       if (!available) throw Exception('Store not available');
       
       const productIds = {
         'bizagent_premium_monthly',
         'bizagent_premium_yearly',
         'bizagent_pro_monthly',
       };
       
       final products = await _iap.queryProductDetails(productIds);
       // Store products in state
     }
     
     Future<void> purchaseProduct(ProductDetails product) async {
       final purchaseParam = PurchaseParam(productDetails: product);
       await _iap.buyConsumable(purchaseParam: purchaseParam);
     }
   }
   ```

5. UPGRADE PROMPT UI
   Show paywall when limit reached:
   ```dart
   // When user tries to create 6th invoice
   showModalBottomSheet(
     context: context,
     builder: (context) => UpgradePrompt(
       title: 'Dosiahli ste limit free plánu',
       message: 'Vytvorili ste 5/5 faktúr tento mesiac.',
       features: [
         'Neobmedzené faktúry',
         'Pokročilé reporty',
         'AI insights',
       ],
       price: '9.99 EUR/mesiac',
       onUpgrade: () => ref.read(iapServiceProvider).purchaseProduct(...),
     ),
   );
   ```

DELIVERABLES:
1. Onboarding flow (3 screens)
2. SubscriptionPlan models
3. UsageLimiter provider
4. IAPService (in_app_purchase integration)
5. Paywall UI components
6. Upgrade prompt dialogs
7. Subscription management screen (Settings)
8. Integration tests pre paywall logic
```

### 🚀 PROMPT 5: PRODUCTION LAUNCH READINESS

```markdown
Finalizuješ BizAgent na PUBLIC LAUNCH v Google Play Store.

AKTUÁLNY STAV:
- Core features implementované
- Chýba: testing, optimization, store submission

POŽIADAVKY:

1. FIRESTORE SECURITY RULES (CRITICAL!)
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{uid} {
         allow read, write: if request.auth.uid == uid;
         
         match /invoices/{invoiceId} {
           allow read, write: if request.auth.uid == uid;
         }
         match /expenses/{expenseId} {
           allow read, write: if request.auth.uid == uid;
         }
         match /settings/{document=**} {
           allow read, write: if request.auth.uid == uid;
         }
       }
     }
   }
   ```

2. PERFORMANCE OPTIMIZATION
   Audit všetky Firestore queries:
   ```dart
   // ❌ BAD
   final invoices = await FirebaseFirestore.instance
     .collection('users/$uid/invoices')
     .get(); // Loads ALL invoices!
   
   // ✅ GOOD
   final invoices = await FirebaseFirestore.instance
     .collection('users/$uid/invoices')
     .orderBy('createdAt', descending: true)
     .limit(50)
     .get();
   ```
   
   Image compression:
   ```dart
   import 'package:flutter_image_compress/flutter_image_compress.dart';
   
   Future<Uint8List> compressReceipt(File image) async {
     return await FlutterImageCompress.compressWithFile(
       image.path,
       quality: 85,
       minWidth: 1024,
     );
   }
   ```

3. COMPREHENSIVE TESTING
   a) Unit tests (90%+ coverage):
      - InvoiceModel calculations
      - OcrService regex patterns
      - AuthRepository logic
      - CategorizationService rules
   
   b) Widget tests:
      - DashboardScreen
      - CreateInvoiceScreen
      - ExpenseListScreen
      - OnboardingFlow
   
   c) Integration tests:
      - Auth flow (signup → verify → login)
      - Invoice flow (create → view → edit → delete)
      - Expense flow with OCR

4. FIREBASE SETUP
   - Enable Email Verification (Auth settings)
   - Configure password requirements (min 8 chars)
   - Set up Crashlytics
   - Enable Analytics
   - Deploy security rules
   - Create composite indexes:
     * invoices: (userId, createdAt)
     * expenses: (userId, category, date)

5. GOOGLE PLAY STORE SUBMISSION
   a) Build release APK:
      ```bash
      flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
      ```
   
   b) App meta
      - Title: "BizAgent - Faktúry & Účtenky"
      - Short desc: "Faktúry a účtenky za sekundy. OCR, PDF, offline."
      - Keywords: faktúry, účtenky, OCR, SZČO, podnikateľ, DPH
      - Category: Business
      - Content rating: Everyone
   
   c) Screenshots (5x):
      - Dashboard view
      - Invoice creation
      - OCR scanning
      - PDF preview
      - Analytics charts
   
   d) Privacy Policy (required!):
      - What data you collect
      - How you use it
      - User rights (GDPR)
      - Contact info

6. MONITORING & ANALYTICS
   Firebase Analytics events:
   ```dart
   // Track key user actions
   FirebaseAnalytics.instance.logEvent(
     name: 'invoice_created',
     parameters: {'amount': invoice.grandTotal},
   );
   
   FirebaseAnalytics.instance.logEvent(
     name: 'ocr_scan_completed',
     parameters: {'success': true},
   );
   ```

DELIVERABLES:
1. Firestore security rules (deployed)
2. Performance optimization audit
3. Complete test suite (90%+ coverage)
4. Firebase configuration (Analytics, Crashlytics)
5. Release build scripts
6. App store metadata (SK + EN)
7. Privacy policy document
8. 5 screenshots (designed)
9. Launch checklist (100 items)
10. Post-launch monitoring dashboard
```

### 🇸🇰 PROMPT 6: SLOVAK LOCALIZATION & ADVANCED FEATURES

```markdown
Si senior Flutter dev. Do BizAgent (Flutter+Riverpod+Firebase+offline+OCR) pridaj 5 features pre SR:

POŽIADAVKY:

1. DPH & NUMBERING SYSTEM
   - Support for DPH rates: 0%, 10%, 20%
   - Invoice numbering format: YYYY/NNN (auto-increment)
   - Tax reminders (notification 3 days before deadline)
   - SPD (Súhrnný výkaz) summary screen

2. QR PLATBA (PAY BY SQUARE)
   - Generate PAY by square payload (LZString/Base64)
   - Embed QR code into the Invoice PDF
   - Use `qr_flutter` or similar package

3. EXPORT PRE ÚČTOVNÍKA
   - Generate ZIP archive containing:
     - All Invoice PDFs for selected period
     - CSV summary of invoices
     - JSON data export
     - Expense attachments
   - Share sheet integration

4. BANK CSV IMPORT
   - Wizard to upload CSV (Tatra banka, SLSP, etc.)
   - Parser for common formats
   - Auto-match logic: Match transaction amount & VS (Variable Symbol) to Invoice
   - Update Invoice status to 'Paid'

5. VALIDATIONS & CLIENT CARDS
   - Validate ICO (checksum), DIC, ICDPH formats
   - 'Client Card' widget with validation badges (Green/Red)
   - Warning if invoicing a non-payer of VAT if you are a payer (and vice versa logic)

DELIVERABLES:
1. File tree for new features
2. Source code for:
   - `VatCalculator` & `InvoiceNumberingService`
   - `QrCodeGenerator`
   - `AccountantExportService` (ZIP generation)
   - `BankCsvParser`
3. Unit tests for VAT, Numbering, QR payload, and CSV parsing.
```
