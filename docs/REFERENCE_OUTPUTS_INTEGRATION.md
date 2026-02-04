# Integrácia referenčných výstupov do BizAgent

Tento dokument mapuje obsah z **local-agent-mode-sessions outputs** na aktuálny BizAgent a navrhuje konkrétne kroky na vylepšenie.

**Zdroj:**  
`.../local_e4f603f5-31f4-4c0a-9201-98e0153c1e6b/outputs/`

---

## 1. Čo je v referenčných výstupoch

### 1.1 Bloček Detective (bizagent_receipt_detective)

| Súbor / modul | Popis | Stav v BizAgent |
|---------------|--------|------------------|
| **data/models/data_fragment.dart** | Jeden fragment z zdroja (bank, GPS, photo, email, calendar), reliability, timestamp | Chýba – máme len `ReconstructedSource` enum |
| **data/models/confidence_score.dart** | Celková + poľová spoľahlivosť, konflikty, odporúčania, `isAcceptableForTax` (≥85%) | Čiastočne – máme `confidence` 0–100 v `ReconstructedExpenseSuggestion` |
| **data/models/reconstructed_receipt.dart** | Plný rekonštruovaný doklad, `ReconstructedReceiptBuilder`, `VerificationStatus`, kategórie | Rovná sa našim návrhom – môžeme rozšíriť model |
| **data/models/legal_declaration.dart** | Čestné prehlásenie (SK), PDF export, GDPR | Chýba |
| **data/datasources/geolocation_datasource.dart** | Získanie GPS v čase transakcie | Chýba |
| **data/datasources/photo_gallery_datasource.dart** | Fotky z galérie, OCR kontext | Chýba |
| **data/repositories/receipt_reconstruction_repository.dart** | Orchesterácia rekonštrukcie z viacerých zdrojov | Čiastočne – máme `ReceiptDetectiveService` (len výdavky bez účtenky) |
| **presentation/widgets/confidence_meter.dart** | UI pre zobrazenie spoľahlivosti | Chýba |
| **presentation/widgets/evidence_card.dart** | Karta „dôkazov“ (zdroje) | Chýba |
| **presentation/pages/detective_home_page.dart** | Hlavná stránka Detective (BLoC) | Máme `ReceiptDetectiveScreen` (Riverpod) |

### 1.2 Testing & Demo (bizagent_testing)

| Súbor | Popis | Stav v BizAgent |
|-------|--------|------------------|
| **demo_mode_service.dart** | Triple-tap na logo → demo mód, scenáre, demo transakcie/anomálie | Chýba |
| **demo_data_generator.dart** | Generátor demo transakcií a orphan transakcií | Chýba |
| **demo_scenarios.dart** | Scenáre (standard, freelancer, …) | Chýba |
| **e2e/ai_accountant_e2e_test.dart** | E2E pre AI účtovníka | Máme unit/widget, E2E len integration_test/app_test |
| **e2e/receipt_detective_e2e_test.dart** | E2E pre Bloček Detective | Chýba |
| **e2e/mock_models.dart** | Mock modely pre E2E | Čiastočne v testoch |

### 1.3 HTML dokumenty

- **BizAgent_Recommendations.html** – stratégia, roadmap (už máme ROADMAP_2026.md, MARKETING_STRATEGY.md).
- **BizAgent_AI_Implementation_Prompts.html** – AI implementačné prompty (môžu slúžiť pri ďalšom rozšírení AI).
- **BizAgent_Analysis_Report.html** / **BizAgent_AI_Innovations.html** – analýzy a inovácie.

---

## 2. Odporúčaný poriadok integrácie

### Fáza 1 – UI a spoľahlivosť (Bloček Detective)

1. **Confidence v UI**
   - V `ReconstructedExpenseSuggestion` pridať getter `confidenceLabel` (Veľmi vysoká / Vysoká / Stredná / Nízka) podľa referenčného `ReconstructedReceipt.confidenceLabel`.
   - V `ReceiptDetectiveScreen` (karta návrhu) zobraziť pásik alebo badge spoľahlivosti (napr. podľa `confidence_meter` z referencie – bez BLoC, len widget).

2. **Evidence card**
   - Skopírovať/adaptovať `evidence_card.dart` ako widget, ktorý zobrazí zdroje návrhu („Bankový výpis“, „Výdavok bez účtenky“) – dátami z `ReconstructedExpenseSuggestion.source` a `sourceLabel`.

3. **Daňová prijateľnosť**
   - Ak `confidence >= 85`, v UI zobraziť napr. „Vhodné pre daňové účely“ (podľa referenčného `isAcceptableForTax`).

### Fáza 2 – Dátové zdroje a rekonštrukcia

4. **DataFragment (voliteľne)**
   - Zaviesť zjednodušený model „fragment“ (napr. `ReceiptDataFragment`) – zdroj, timestamp, reliability, kľúčové polia – ak plánujete fusiu z banky + GPS + foto.
   - Alternatíva: nechať zatiaľ len rozšírenie `ReconstructedExpenseSuggestion` o `usedSourceTypes` (zoznam zdrojov).

5. **Geolocation datasource**
   - Portovať `geolocation_datasource.dart` do `lib/features/receipt_detective/services/` alebo `data/datasources/`.
   - V `ReceiptDetectiveService` (alebo novom „reconstruction“ servise) volať geolocation pri rekonštrukcii z bankovej transakcie (kde je čas a suma).

6. **Photo gallery datasource**
   - Podobne portovať `photo_gallery_datasource.dart` – získať fotky z obdobia transakcie pre kontext (OCR už máte inde).

7. **Receipt reconstruction repository / orchesterácia**
   - Buď rozšíriť `ReceiptDetectiveService` o:
     - vstup: banková transakcia alebo výdavok bez účtenky,
     - volanie geolocation + photo (ak sú k dispozícii),
     - zostavenie jedného návrhu s viacerými zdrojmi a výpočet confidence (podľa referenčného `ConfidenceScore` alebo zjednodušene).

### Fáza 3 – Právna súladnosť

8. **Čestné prehlásenie**
   - Portovať `legal_declaration.dart` do BizAgent.
   - V Bloček Detective flow: po potvrdení rekonštruovaného dokladu ponúknuť „Vygenerovať čestné prehlásenie“ a export (PDF ak máte knižnicu).

### Fáza 4 – Demo mód a E2E

9. **Demo mode**
   - Portovať `DemoModeService`, `DemoDataGenerator`, `DemoScenarios` do BizAgent (napr. `lib/core/demo_mode/`).
   - Zapojenie: triple-tap na logo (Splash alebo Dashboard) → aktivácia demo módu, prepínanie scenárov.
   - V demo móde používať demo dáta namiesto reálnych (invoices, expenses, alerty).

10. **E2E testy**
    - Prevziať scenáre z `receipt_detective_e2e_test.dart` a `ai_accountant_e2e_test.dart` do `integration_test/` BizAgent.
    - Adaptovať na existujúce stránky a Riverpod (nie BLoC).

---

## 3. Rýchle úlohy (môžu sa robiť hneď)

- Pridať do `ReconstructedExpenseSuggestion` gettery: `confidenceLabel`, `isAcceptableForTax` (confidence >= 85).
- V kartách na `ReceiptDetectiveScreen` zobraziť `confidenceLabel` a malý indikátor farby (zelená / oranžová / červená).
- Vytvoriť widget `EvidenceSourceChip` alebo `EvidenceCard` – zobrazí `sourceLabel` a ikonu zdroja.
- Do `docs/` skopírovať alebo odkázať README z `bizagent_receipt_detective` ako referenčnú špecifikáciu Bloček Detective.

---

## 4. Súbory na kopírovanie / inšpiráciu

| Z referencie | Cieľ v BizAgent |
|--------------|------------------|
| `confidence_score.dart` (logika) | Rozšíriť `receipt_detective` o výpočet confidence z viacerých zdrojov |
| `confidence_meter.dart` | `lib/features/receipt_detective/widgets/confidence_meter.dart` |
| `evidence_card.dart` | `lib/features/receipt_detective/widgets/evidence_card.dart` |
| `data_fragment.dart` | Pri fáze 2 – `lib/features/receipt_detective/models/data_fragment.dart` |
| `legal_declaration.dart` | `lib/features/receipt_detective/models/legal_declaration.dart` + service |
| `demo_mode_service.dart` + scenáre | `lib/core/demo_mode/` |
| E2E testy | `integration_test/receipt_detective_e2e_test.dart` atď. |

---

*Dokument vytvorený na základe analýzy local-agent-mode-sessions outputs. Pri implementácii treba adaptovať BLoC → Riverpod a závislosti projektu (napr. equatable, uuid).*
