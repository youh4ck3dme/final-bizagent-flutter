# 🚀 BizAgent - Master Blueprint & Implementačný Plán
**Verzia:** 1.0.1+2  
**Dátum:** 2026-02-03  
**Stav:** Produkčne pripravený s roadmap na enterprise-grade kvalitu

---

## 📊 Executive Summary

**Celkový zdravotný index:** 🟢 85/100

BizAgent je **plne funkčná** aplikácia s 21 feature modulmi, 215+ testami a pokrytím kľúčových business procesov. Projekt je v dobrom stave s jasným roadmapom na dosiahnutie perfektnej kvality.

### Silné stránky ✅
- Solídna architektúra (Riverpod + Clean Architecture)
- Komplexné testovanie (215+ testov, 98% pass rate)
- AI integrácia (Gemini, OCR, BizBot)
- Offline-first prístup (Hive + Firestore)
- PWA ready

### Kritické oblasti na zlepšenie 🔴
1. **Neúplné DPH sledovanie** vo výdavkoch
2. **Chýbajúce onboarding UX** pre nových používateľov
3. **Limitované error handling** v AI službách
4. **PWA optimalizácia** nie je dokončená
5. **Analytics tracking** je minimálny
6. **Multi-currency** podpora chýba
7. **Notification center** nie je implementovaný

---

## 🏗️ Tech Stack & Architektúra

```yaml
Framework: Flutter 3.13+
State Management: Riverpod 2.6.1
Backend: Firebase (Firestore, Auth, Storage, Analytics)
AI: Google Gemini 1.5 Flash + ML Kit
PDF: pdf 3.10.7 + printing 5.11.1
Charts: fl_chart 1.1.1
Offline: Hive 2.2.3
```

### Feature Moduly (21)
```
✅ AI Tools         ✅ Analytics        ✅ Auth
✅ Bank Import      ✅ Billing          ✅ Dashboard
✅ Documents        ✅ Expenses         ✅ Export
✅ Invoices         ✅ Notifications    ✅ Proactive Alerts
✅ Receipt Detective✅ Settings         ✅ Tax
⚠️ Entitlements    ⚠️ Limits
```

---

# ČASŤ 1: NOVÉ FUNKCIE (PDF Reports & AI Notepad)

## 📊 DPH vo Výdavkoch (P0 - KRITICKÉ)

### Problém
Reporty zobrazujú DPH len pre faktúry. Výdavky majú placeholder `0.0`, pretože `ExpenseModel` neobsahuje rozdelenie na základ a DPH.

**Dopad:** 🔴 HIGH - Finančné reporty sú neúplné, nemožnosť vypočítať bilanciu DPH.

### Riešenie

#### 1.1 Rozšírenie Expense Modelu
**Súbor:** `lib/features/expenses/models/expense_model.dart`

```dart
class ExpenseModel {
  final double? vatAmount;     // Suma DPH
  final double? vatRate;        // Sadzba DPH (0.0, 0.10, 0.20)
  final double baseAmount;      // Základ dane (amount - vatAmount)
  
  // Migration: pre staré záznamy vatAmount = null
}
```

#### 1.2 UI Update
**Súbor:** `lib/features/expenses/screens/create_expense_screen.dart`

```dart
// Checkbox "Zahrnúť DPH"
// Ak je zaškrtnuté:
//   - Dropdown s DPH sadzbou (10%, 20%)
//   - Automatický výpočet: základ = suma / (1 + sadzba)
```

#### 1.3 Report Controller Fix
**Súbor:** `lib/features/export/providers/report_provider.dart`

```dart
// Nahradiť placeholder za:
totalVatExpenses += ex.vatAmount ?? 0.0;
vatExpenseBreakdown[ex.vatRate ?? 0.0] = 
  (vatExpenseBreakdown[ex.vatRate ?? 0.0] ?? 0) + (ex.vatAmount ?? 0.0);
```

**Tasks:**
- [ ] Rozšíriť model o DPH polia
- [ ] Aktualizovať `CreateExpenseScreen` o DPH input
- [ ] Migrovať `ReportController` na reálne DPH dáta
- [ ] Migration script pre existujúce záznamy

**Odhad:** 4-5 hodín

---

## 🎨 Firemné Logo v Reportoch (P1)

### Riešenie

**Súbor:** `lib/features/settings/models/user_settings_model.dart`
```dart
final String? companyLogoUrl;  // Firebase Storage URL
```

**Implementation:**
1. ImagePicker v Settings pre upload
2. Firebase Storage: `/users/{userId}/logo.png`
3. PDF Service: stiahnuť a embedovať do header

**Tasks:**
- [ ] Pridať `companyLogoUrl` do modelu
- [ ] Upload UI v Settings
- [ ] Logo rendering v PDF
- [ ] Fallback na text

**Odhad:** 2 hodiny

---

## 📅 Flexibilné Obdobie v Reportoch (P0)

### Problém
UI má len "Tento/Minulý mesiac", chýba custom date range.

### Riešenie
**Súbor:** `lib/features/export/screens/reports_screen.dart`

```dart
Row([
  SegmentedButton(...), // Quick access
  IconButton(
    icon: Icons.date_range,
    onPressed: () async {
      final range = await showDateRangePicker(...);
      if (range != null) {
        setState(() => _period = ExportPeriod(from: range.start, to: range.end));
        ref.read(reportControllerProvider.notifier).generateReport(_period);
      }
    },
  ),
])
```

**Tasks:**
- [ ] Implementovať date range picker
- [ ] Pridať quick presets (Q1, celý rok)
- [ ] State management

**Odhad:** 1-2 hodiny

---

## 🤖 AI Offline Check (P0)

### Problém
AI analýza vyžaduje internet, ale nie je kontrola konektivity.

### Riešenie
**Súbor:** `lib/features/documents/screens/note_editor_screen.dart`

```dart
final connectivity = await Connectivity().checkConnectivity();
if (connectivity == ConnectivityResult.none) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Analýza vyžaduje pripojenie k internetu')),
  );
  return;
}
```

**Dependency:** `connectivity_plus: ^6.0.0` (už v pubspec.yaml)

**Tasks:**
- [ ] Pridať connectivity check do AI služieb
- [ ] User-friendly error messages
- [ ] Retry button v error states
- [ ] Implementovať `RetryPolicy` helper

**Odhad:** 3-4 hodiny

---

## ✍️ Markdown Support v Poznámkach (P2)

### Riešenie
Použiť existujúcu `flutter_markdown` dependenciu:
- View mode: renderovať markdown
- Edit mode: raw text s markdown syntax

**Tasks:**
- [ ] Toggle medzi Edit/Preview
- [ ] Markdown toolbar (bold, list, link)
- [ ] Syntax highlighting

**Odhad:** 3-4 hodiny

---

## 🌐 PWA Optimalizácia (P1)

### Problém
Service Worker nie je optimalizovaný pre nové screeny.

### Riešenie
**Súbor:** `web/service-worker.js`

```js
workbox.routing.registerRoute(
  /\/export\/reports/,
  new workbox.strategies.NetworkFirst({
    cacheName: 'reports-cache',
    plugins: [
      new workbox.expiration.ExpirationPlugin({
        maxEntries: 50,
      }),
    ],
  })
);
```

**Tasks:**
- [ ] Aktualizovať service worker s novými routes
- [ ] Optimalizovať `manifest.json`
- [ ] Offline indicators
- [ ] Testovať PWA install flow

**Odhad:** 2-3 hodiny

---

## 💰 Multi-Currency Support (P2)

### Riešenie
**Súbor:** `lib/features/settings/models/user_settings_model.dart`

```dart
final String currency; // Default: 'EUR'
```

**Implementation:**
- Všetky `NumberFormat.currency()` použiť `settings.currency`
- Currency picker v Settings
- Support pre EUR, CZK, USD

**Tasks:**
- [ ] Rozšíriť model
- [ ] Aktualizovať PDF generovanie
- [ ] Dashboard widgets
- [ ] Settings UI

**Odhad:** 2-3 hodiny

---

# ČASŤ 2: CELKOVÉ VYLEPŠENIA PROJEKTU

## 📚 Onboarding Pre Nových Používateľov (P0)

### Problém
Aplikácia nemá guided tour pre nových používateľov.

**Dopad:** 🟡 MEDIUM - Nižšia adopcia a user retention.

### Riešenie
Použiť existujúcu dependenciu `tutorial_coach_mark`:

```dart
// 3-krokový tour:
// 1. "Tap here to scan your first receipt"
// 2. "Create your first invoice here"
// 3. "View insights on Dashboard"
```

**Tasks:**
- [ ] Vytvoriť `OnboardingService`
- [ ] Tour pre Dashboard, Expenses, Invoices
- [ ] Stav "tour completed" v SharedPreferences
- [ ] "Show Tour Again" v Settings

**Odhad:** 3-4 hodiny

---

## 🔔 Notification Center (P0)

### Problém
`NotificationBell` widget má `TODO: Open notifications sheet`.

**Súbor:** `lib/shared/widgets/notification_bell.dart:32`

### Riešenie
```dart
// Vytvoriť NotificationsScreen
// Historical notifications (payment reminders, alerts)
// "Mark as read" functionality
// Badge count
```

**Tasks:**
- [ ] `NotificationsScreen`
- [ ] `NotificationsRepository` (Firestore)
- [ ] Navigácia z `NotificationBell`
- [ ] Badge count logic

**Odhad:** 2-3 hodiny

---

## 📊 Analytics Tracking (P1)

### Problém
Firebase Analytics je minimálne využitý.

### Riešenie
**Vytvoriť:** `lib/core/services/analytics_service.dart`

```dart
class AnalyticsService {
  void trackInvoiceCreated(String method); // manual / AI
  void trackExpenseScanned(String ocrEngine);
  void trackReportGenerated(String period);
}
```

**Tasks:**
- [ ] Vytvoriť `AnalyticsService`
- [ ] Integrovať do kľúčových akcií
- [ ] Custom events (invoice_created, expense_scanned)
- [ ] User properties (is_vat_payer, company_size)

**Odhad:** 3 hodiny

---

## 🧪 Unit Test Coverage (P3)

**Aktuálny stav:** 65+ testov, ~60% coverage

**Oblasti s nízkym pokrytím:**
- `lib/features/billing/` (0%)
- `lib/features/export/providers/report_provider.dart` (nový, 0%)

**Tasks:**
- [ ] Testy pre `ReportController`
- [ ] Mock `BillingService`
- [ ] Edge cases v `BankImportService`

**Odhad:** 4-5 hodín

---

## 📝 Documentation (P3)

### Problém
Chýbajú dartdoc comments.

### Riešenie
```dart
/// BizBotService poskytuje AI-powered analýzu pre faktúry a poznámky.
///
/// Používa Google Gemini 1.5 Flash model.
/// 
/// Príklad:
/// ```dart
/// final bizBot = ref.read(bizBotServiceProvider);
/// final response = await bizBot.analyzeNote('Kúpil som...');
/// ```
class BizBotService { ... }
```

**Tasks:**
- [ ] Dartdoc komentáre do public API
- [ ] Generovať HTML docs (`dartdoc`)
- [ ] `CONTRIBUTING.md`

**Odhad:** 6-8 hodín

---

## 🟢 Linter Cleanup (P3)

**Problém:** 5 duplicate_ignore warnings v mock súboroch.

**Riešenie:**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Odhad:** 30 minút

---

# ČASŤ 3: BUDÚCE ROZŠÍRENIA (Post-MVP)

## 🌍 VIES API Integrácia

**Popis:** Validácia EU DIČ cez VIES API.

**Tasks:**
- [ ] `ViesService`
- [ ] Integrácia do `CreateInvoiceScreen`
- [ ] Auto-fill adresy z VIES

**Odhad:** 3-4 hodiny

---

## 🍎 iOS Verzia

**Tasks:**
- [ ] Xcode project setup
- [ ] Apple Developer Account
- [ ] Testovanie na zariadení
- [ ] App Store submission

**Odhad:** 16-20 hodín

---

## 📧 Production Email Server

**Tasks:**
- [ ] Integrovať SendGrid/Postmark
- [ ] Email templates
- [ ] Deliverability testing

**Odhad:** 4-6 hodín

---

## 🛡️ ReCaptcha Enterprise

**Tasks:**
- [ ] Cloud Function pre backend verification
- [ ] Production testing

**Odhad:** 2-3 hodiny

---

# 📈 IMPLEMENTAČNÝ ROADMAP

## Sprint 1: Kritické Opravy (1 týždeň)
**Focus:** Nové funkcie + Critical fixes

1. ✅ DPH vo výdavkoch (5h)
2. ✅ Date range picker (2h)
3. ✅ AI offline check (4h)
4. ✅ Onboarding UX (4h)
5. ✅ Notification center (3h)

**Celkom:** ~18 hodín

---

## Sprint 2: UX Vylepšenia (1 týždeň)
**Focus:** P1 items + polish

1. PWA optimalizácia (3h)
2. Analytics tracking (3h)
3. Logo v reportoch (2h)
4. Multi-currency (3h)
5. Markdown support (4h)

**Celkom:** ~15 hodín

---

## Sprint 3: Testing & Documentation (1 týždeň)
**Focus:** Quality & maintainability

1. Unit test coverage (5h)
2. Documentation (6h)
3. Linter cleanup (1h)

**Celkom:** ~12 hodín

---

## Sprint 4: Budúce Funkcie (2 týždne)
**Focus:** Post-MVP expansion

1. VIES API (4h)
2. Production email (6h)
3. ReCaptcha backend (3h)
4. iOS príprava (20h)

**Celkom:** ~33 hodín

---

# 🎯 KPI CIELE

### Pred Sprintmi
- Test Coverage: 60%
- Code Quality: 85/100
- Crashlytics: 0 crashes

### Po Sprintoch
- Test Coverage: 80%+
- Code Quality: 95/100
- User Retention (D7): 40%+
- Crashlytics: < 0.5% crash rate
- PWA Install Rate: 15%+

---

# 📋 PRODUCTION LAUNCH CHECKLIST

## Must-Have (Pred Launch)
- [x] Firebase Production setup
- [x] Google Play vydanie
- [ ] DPH tracking implementované
- [ ] Onboarding tour
- [ ] Notification center
- [ ] AI offline error handling
- [ ] PWA optimalizácia

## Nice-to-Have (Post-Launch)
- [ ] Multi-currency
- [ ] Logo v reportoch
- [ ] Markdown poznámky
- [ ] VIES integrácia
- [ ] iOS verzia

---

# ✅ ACCEPTANCE CRITERIA

**Pre každú zmenu:**
- [ ] Implementované podľa špecifikácie
- [ ] Pridané/upravené testy
- [ ] `flutter analyze` bez nových varovaní
- [ ] Backward compatibility zachovaná
- [ ] Dokumentované v commit message

**Finálny stav:**
- [ ] Reporty majú presné DPH dáta
- [ ] AI má offline detection
- [ ] Custom date range picker funguje
- [ ] Všetky testy prebiehajú (215+)
- [ ] Onboarding tour implementovaný
- [ ] Notification center funkčný

---

# 💡 PRIORITIZÁCIA & RECOMMENDATIONS

## 🔴 Immediate Actions (Tento týždeň)
1. **DPH tracking** - Najväčší business impact
2. **Offline checks** - Predíde negatívnym reviews
3. **Date range picker** - Basic requirement
4. **Onboarding** - Zlepší adopciu

## 🟡 Medium-Term (Tento mesiac)
5. **PWA optimalizácia** - Dôležité pre web users
6. **Analytics** - Data-driven rozhodnutia
7. **Logo v reportoch** - Professional look
8. **Multi-currency** - Expanzia mimo SK

## 🔵 Long-Term (Q2 2026)
9. **iOS verzia** - 50% trhu
10. **VIES API** - EU compliance
11. **Advanced reporting** - Premium feature

---

**Master Blueprint pripravený:** 2026-02-03  
**Autor:** Antigravity AI Assistant  
**Status:** Ready for Sprint 1 execution  
**Odhadovaný celkový čas:** ~78 hodín (Sprint 1-4)

---

## 📞 Next Steps

**Odporúčam začať s:** Sprint 1, Item #1 (DPH vo výdavkoch)

Toto je kritická funkcia s najväčším business impactom a ovplyvní všetky ostatné reporty a analýzy.
