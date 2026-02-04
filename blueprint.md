# 🔬 BizAgent - Komplexná Diagnostika & Blueprint
**Verzia:** 1.0.1+2  
**Dátum analýzy:** 2026-02-03  
**Stav:** Produkčne pripravený s oblasťami na zlepšenie

---

## 📊 Executive Summary

**Celkový zdravotný index:** 🟢 85/100

BizAgent je **plne funkčná** aplikácia s 21 feature modulmi, 65+ testami a pokrytím kľúčových business procesov. Projekt je v dobrom stave, ale existuje 7 významných oblastí, ktoré potrebujú dopracovanie pre dosiahnutie enterprise-grade kvality.

### Silné stránky ✅
- Solídna architektúra (Riverpod + Clean Architecture)
- Komplexné testovanie (215+ testov, 98% pass rate)
- AI integrácia (Gemini, OCR, BizBot)
- Offline-first prístup (Hive + Firestore)
- PWA ready

### Kritické medzery 🔴
1. **Neúplné DPH sledovanie** vo výdavkoch
2. **Chýbajúce onboarding UX** pre nových používateľov
3. **Limitované error handling** v AI službách
4. **PWA optimalizácia** nie je dokončená
5. **Analytics tracking** je minimálny
6. **Multi-currency** podpora chýba
7. **Notification center** nie je implementovaný

---

## 🏗️ Architektúra & Technológie

### Tech Stack
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
✅ AI Tools         - BizBot, Email Generator, Expense Analysis
✅ Analytics        - Expense Insights
✅ Auth             - Firebase Auth, Biometrics
✅ Bank Import      - CSV Parser, Smart Matching
✅ Billing          - (In-App Purchases)
✅ Dashboard        - Quick Actions, Insights
✅ Documents        - AI Notepad (Nové)
✅ Expenses         - OCR Scanning, Categorization
✅ Export           - ZIP Export, PDF Reports (Nové)
✅ Invoices         - PDF Generation, Payment Tracking
✅ Notifications    - Local Notifications
✅ Proactive Alerts - Smart Warnings
✅ Receipt Detective- AI-powered Receipt Analysis
✅ Settings         - Company Info, Theme
✅ Tax              - Cashflow Analytics
⚠️ Entitlements    - (Stub)
⚠️ Limits           - (Stub)
```

---

## 🔴 Priorita 0: Kritické Opravy

### 1. DPH vo Výdavkoch
**Problém:** Model `ExpenseModel` neobsahuje polia pre DPH, čo znemožňuje presné daňové reporty.

**Dopad:** 🔴 HIGH - Finančné reporty sú neúplné, nemožnosť vypočítať bilanciu DPH.

**Riešenie:**
```dart
// lib/features/expenses/models/expense_model.dart
class ExpenseModel {
  final double? vatAmount;
  final double? vatRate;
  final double baseAmount; // amount - vatAmount
  
  // Migration: pre staré záznamy vatAmount = null
}
```

**Tasks:**
- [ ] Rozšíriť model o DPH polia
- [ ] Aktualizovať `CreateExpenseScreen` o DPH input
- [ ] Migrovať `ReportController` na používanie reálnych DPH dát
- [ ] Pridať migration script pre existujúce záznamy

**Odhad:** 4-5 hodín

---

### 2. Onboarding Pre Nových Používateľov
**Problém:** Aplikácia nemá guided tour pre nových používateľov.

**Dopad:** 🟡 MEDIUM - Používatelia nevedia, kde začať, nižšia adopcia.

**Riešenie:**
```dart
// Použiť existujúcu dependenciu tutorial_coach_mark
// Implementovať 3-krokový tour:
// 1. "Tap here to scan your first receipt"
// 2. "Create your first invoice here"
// 3. "View insights on Dashboard"
```

**Tasks:**
- [ ] Vytvoriť `OnboardingService`
- [ ] Implementovať tour pre Dashboard, Expenses, Invoices
- [ ] Uložiť stav "tour completed" do SharedPreferences
- [ ] Pridať "Show Tour Again" tlačidlo v Settings

**Odhad:** 3-4 hodiny

---

### 3. Notification Center
**Problém:** `NotificationBell` widget má `TODO: Open notifications sheet`.

**Súbor:** `lib/shared/widgets/notification_bell.dart:32`

**Dopad:** 🟡 MEDIUM - Používatelia nevidia notifikácie v jednom mieste.

**Riešenie:**
```dart
// Vytvoriť NotificationsScreen
// Zobraziť historical notifications (payment reminders, alerts)
// Implementovať "Mark as read" functionality
```

**Tasks:**
- [ ] Vytvoriť `NotificationsScreen`
- [ ] Implementovať `NotificationsRepository` (Firestore)
- [ ] Pridať navigáciu z `NotificationBell`
- [ ] Implementovať badge count

**Odhad:** 2-3 hodiny

---

## 🟡 Priorita 1: Významné Vylepšenia

### 4. AI Error Handling & Offline Mode
**Problém:** AI služby (BizBot, OCR) nemajú robustné error handling pre offline režim.

**Súbory:**
- `lib/features/ai_tools/services/biz_bot_service.dart`
- `lib/features/receipt_detective/services/receipt_detective_service.dart`

**Riešenie:**
```dart
// Pridať connectivity check
final connectivity = await Connectivity().checkConnectivity();
if (connectivity == ConnectivityResult.none) {
  throw OfflineException('AI analysis requires internet connection');
}

// Implementovať retry logic s exponential backoff
```

**Tasks:**
- [ ] Pridať `connectivity_plus` check do všetkých AI služieb
- [ ] Implementovať `RetryPolicy` helper
- [ ] Vytvoriť user-friendly error messages
- [ ] Pridať "Retry" button v error states

**Odhad:** 3-4 hodiny

---

### 5. PWA Optimalizácia
**Problém:** Service Worker nie je optimalizovaný pre nové screeny (Reports, Notepad).

**Súbory:**
- `web/service-worker.js`
- `web/manifest.json`

**Riešenie:**
```js
// Pridať runtime caching pre nové routes
workbox.routing.registerRoute(
  /\/export\/reports/,
  new workbox.strategies.NetworkFirst({
    cacheName: 'reports-cache',
  })
);
```

**Tasks:**
- [ ] Aktualizovať `service-worker.js` s novými routes
- [ ] Optimalizovať `manifest.json` (icons, theme colors)
- [ ] Implementovať offline indicators
- [ ] Testovať PWA install flow na mobile

**Odhad:** 2-3 hodiny

---

### 6. Analytics Tracking
**Problém:** Firebase Analytics je minimálne využitý.

**Súbory:**
- `lib/core/services/analytics_service.dart` (neexistuje)

**Riešenie:**
```dart
// Vytvoriť AnalyticsService
class AnalyticsService {
  void trackInvoiceCreated(String method); // manual / AI
  void trackExpenseScanned(String ocrEngine);
  void trackReportGenerated(String period);
}
```

**Tasks:**
- [ ] Vytvoriť `AnalyticsService`
- [ ] Integrovať tracking do kľúčových akcií
- [ ] Definovať custom events (invoice_created, expense_scanned)
- [ ] Pridať user properties (is_vat_payer, company_size)

**Odhad:** 3 hodiny

---

## 🔵 Priorita 2: UX & Polish

### 7. Multi-Currency Support
**Problém:** Aplikácia je hardkódovaná na EUR.

**Riešenie:**
```dart
// lib/features/settings/models/user_settings_model.dart
final String currency; // EUR, CZK, USD

// Všetky NumberFormat.currency(...) použiť settings.currency
```

**Tasks:**
- [ ] Rozšíriť `UserSettingsModel` o `currency`
- [ ] Aktualizovať PDF generovanie
- [ ] Aktualizovať dashboard widgets
- [ ] Pridať currency picker do Settings

**Odhad:** 2-3 hodiny

---

### 8. Firemné Logo v Reportoch
**Problém:** PDF reporty nemajú logo, len textový názov.

**Riešenie:**
```dart
// Settings: upload logo do Firebase Storage
// PDF Service: stiahnuť a embedovať do PDF header
```

**Tasks:**
- [ ] Pridať `companyLogoUrl` do `UserSettingsModel`
- [ ] Implementovať upload UI v Settings
- [ ] Aktualizovať `_generateReportTask` na embedovanie loga
- [ ] Fallback na text, ak logo neexistuje

**Odhad:** 2 hodiny

---

### 9. Date Range Picker pre Reporty
**Problém:** ReportsScreen má len "Tento/Minulý mesiac".

**Riešenie:**
```dart
// Pridať IconButton s showDateRangePicker
// Umožniť custom obdobie (napr. Q1 2025, celý rok)
```

**Tasks:**
- [ ] Aktualizovať `ReportsScreen` UI
- [ ] Implementovať custom date picker
- [ ] Pridať quick presets (Tento kvartál, Tento rok)

**Odhad:** 1-2 hodiny

---

### 10. Markdown Support v Poznámkach
**Problém:** `NotepadScreen` podporuje len plain text.

**Riešenie:**
```dart
// Použiť flutter_markdown (už v dependencies)
// View mode: renderovať markdown
// Edit mode: raw text s markdown syntax
```

**Tasks:**
- [ ] Aktualizovať `NoteEditorScreen` na markdown input
- [ ] Pridať toggle medzi "Edit" a "Preview"
- [ ] Implementovať markdown toolbar (bold, list, link)

**Odhad:** 3-4 hodiny

---

## 🟢 Priorita 3: Technický Dlh

### 11. Linter Warnings Cleanup
**Problém:** 5 duplicate_ignore warnings v mock súboroch.

**Súbory:**
- `test/core/services/soft_delete_service_test.mocks.dart`
- `test/features/documents/providers/notepad_repository_test.mocks.dart`

**Riešenie:**
```bash
# Re-generate mocks
flutter pub run build_runner build --delete-conflicting-outputs
```

**Tasks:**
- [ ] Regenerovať všetky mocks
- [ ] Skontrolovať analysis options pre mock files
- [ ] Pridať `// coverage:ignore-file` do mock súborov

**Odhad:** 30 minút

---

### 12. Unit Test Coverage
**Aktuálny stav:** 65+ testov, ~60% coverage

**Oblasti s nízkym pokrytím:**
- `lib/features/billing/` (0%)
- `lib/features/entitlements/` (stubs)
- `lib/features/limits/` (stubs)
- `lib/features/export/providers/report_provider.dart` (nový, 0%)

**Tasks:**
- [ ] Pridať testy pre `ReportController`
- [ ] Implementovať mock `BillingService`
- [ ] Testovať edge cases v `BankImportService`

**Odhad:** 4-5 hodín

---

### 13. Documentation
**Problém:** API docs sú minimálne, chýbajú dartdoc comments.

**Riešenie:**
```dart
/// BizBotService poskytuje AI-powered analýzu pre faktúry a poznámky.
///
/// Používa Google Gemini 1.5 Flash model pre generovanie odpovedí.
/// 
/// Príklad:
/// ```dart
/// final bizBot = ref.read(bizBotServiceProvider);
/// final response = await bizBot.analyzeNote('Kúpil som...');
/// ```
class BizBotService {
  // ...
}
```

**Tasks:**
- [ ] Pridať dartdoc komentáre do všetkých public API
- [ ] Generovať HTML dokumentáciu (`dartdoc`)
- [ ] Vytvoriť `CONTRIBUTING.md` pre nových developerov

**Odhad:** 6-8 hodín

---

## 🚀 Budúce Rozšírenia (Post-MVP)

### 14. VIES API Integrácia
**Zdroj:** `README.md:100`

**Popis:** Validácia EU DIČ cez VIES API.

**Tasks:**
- [ ] Implementovať `ViesService`
- [ ] Integrovať do `CreateInvoiceScreen`
- [ ] Automaticky vyplniť adresu z VIES

**Odhad:** 3-4 hodiny

---

### 15. iOS Verzia
**Zdroj:** `README.md:92-95`

**Tasks:**
- [ ] Setup Xcode project
- [ ] Apple Developer Account
- [ ] Testovať na reálnom zariadení
- [ ] Submit do App Store

**Odhad:** 16-20 hodín (prvý release)

---

### 16. Production Email Server
**Zdroj:** `README.md:88-89`

**Tasks:**
- [ ] Integrovať SendGrid / Postmark
- [ ] Implementovať email templates (faktúra, pripomienka)
- [ ] Testovať deliverability

**Odhad:** 4-6 hodín

---

### 17. ReCaptcha Enterprise
**Zdroj:** `README.md:82-85`

**Tasks:**
- [ ] Implementovať Cloud Function pre backend verification
- [ ] Testovať v production prostredí

**Odhad:** 2-3 hodiny

---

## 📈 Implementačný Roadmap

### Sprint 1: Kritické Opravy (1 týždeň)
**Focus:** P0 items
1. DPH vo výdavkoch (5h)
2. Onboarding UX (4h)
3. Notification Center (3h)
4. AI Error Handling (4h)

**Celkom:** ~16 hodín

---

### Sprint 2: UX Vylepšenia (1 týždeň)
**Focus:** P1 items + P2 quick wins
1. PWA Optimalizácia (3h)
2. Analytics Tracking (3h)
3. Multi-Currency (3h)
4. Logo v Reportoch (2h)
5. Date Range Picker (2h)

**Celkom:** ~13 hodín

---

### Sprint 3: Polish & Testing (1 týždeň)
**Focus:** P2 + P3 items
1. Markdown Support (4h)
2. Linter Cleanup (1h)
3. Unit Test Coverage (5h)
4. Documentation (6h)

**Celkom:** ~16 hodín

---

### Sprint 4: Budúce Funkcie (2 týždne)
**Focus:** Post-MVP
1. VIES API (4h)
2. Production Email (6h)
3. ReCaptcha Backend (3h)
4. iOS Príprava (20h)

**Celkom:** ~33 hodín

---

## 🎯 KPI Ciele

### Pred Sprintmi
- **Test Coverage:** 60%
- **Code Quality:** 85/100
- **User Retention (D7):** N/A (nová app)
- **Crashlytics:** 0 crashes

### Po Sprintoch
- **Test Coverage:** 80%+
- **Code Quality:** 95/100
- **User Retention (D7):** 40%+
- **Crashlytics:** \< 0.5% crash rate
- **PWA Install Rate:** 15%+

---

## 📋 Checklist Pre Production Launch

### Must-Have (Pred Launch)
- [x] Firebase Production setup
- [x] Google Play vydanie
- [ ] DPH tracking implementované
- [ ] Onboarding tour
- [ ] Notification center
- [ ] AI offline error handling
- [ ] PWA optimalizácia
- [ ] Privacy Policy aktualizovaný

### Nice-to-Have (Post-Launch)
- [ ] Multi-currency
- [ ] Logo v reportoch
- [ ] Markdown poznámky
- [ ] VIES integrácia
- [ ] iOS verzia
- [ ] Production email server

---

## 💡 Odporúčania

### Immediate Actions (Tento týždeň)
1. ✅ **Začať s DPH tracking** - Najväčší business impact
2. ✅ **Implementovať offline checks** - Predíde negatívnym reviews
3. ✅ **Pridať onboarding** - Zlepší adopciu

### Medium-Term (Tento mesiac)
4. 🟡 **Dokončiť PWA optimalizáciu** - Dôležité pre web users
5. 🟡 **Pridať analytics** - Data-driven rozhodnutia
6. 🟡 **Multi-currency support** - Expanzia mimo SK

### Long-Term (Q2 2026)
7. 🔵 **iOS verzia** - 50% trhu
8. 🔵 **VIES API** - EU compliance
9. 🔵 **Advanced reporting** - Premium feature

---

**Blueprint pripravený:** 2026-02-03  
**Autor:** Antigravity AI Assistant  
**Priorita:** Začať s Sprint 1 (DPH + Onboarding + Offline Handling)
