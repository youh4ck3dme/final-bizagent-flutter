# BizAgent 🚀

**Skenuj bločky, spravuj výdavky a faktúry s AI. Účtovný asistent pre SZČO a firmy na Slovensku.**

[![Flutter](https://img.shields.io/badge/Flutter-3.13.0+-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Cloud-FFCA28?logo=firebase)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/Tests-Passing-success)](https://github.com/youh4ck3dme/BizAgent/actions)

> Kompletné riešenie pre faktúry, výdavky a účtovníctvo – špeciálne navrhnuté pre slovenský trh a legislatívu.

---

## 📚 Dokumentácia

*   **[Google Play Submission Guide](docs/GOOGLE_PLAY_SUBMISSION.md):** Podrobný návod, ako vyplniť formuláre (Data Safety, App Access) v Play Console. Obsahuje ASO-optimalizované texty (názov, krátky/dlhý popis, kľúčové slová).
*   **[Play Store Checklist](docs/PLAY_STORE.md):** Release checklist, ASO kľúčové slová, screenshot stratégia.
*   **[Roadmap 2026](docs/ROADMAP_2026.md):** Feature roadmap (Q1–Q4), Quick Wins, budúce AI inovácie.
*   **[Marketingová stratégia](docs/MARKETING_STRATEGY.md):** Kanály, materiály, partnerstvá, promo video.
*   **[ASO Screenshots & Quick Wins](docs/ASO_SCREENSHOTS_AND_QUICK_WINS.md):** 5 screenshotov pre Play Store, promo video, Quick Wins.
*   **[Privacy Policy Template](docs/PRIVACY_POLICY.md):** Pripravený text pre Zásady ochrany súkromia (potrebné pre Play Store).

---

## 🚀 Rýchly Štart (Development)

1.  **Prerekvizity:**
    *   Flutter SDK (3.13+)
    *   Firebase CLI (`npm install -g firebase-tools`)
    *   Melos (voliteľné pre monorepo, tu stačí `flutter pub get`)

2.  **Inštalácia:**
    ```bash
    flutter pub get
    ```

3.  **Spustenie (Web PWA):**
    ```bash
    flutter run -d chrome --web-renderer canvaskit
    ```

4.  **Spustenie (Android):**
    ```bash
    flutter run -d android
    ```

---

## 📦 Build & Release (Production)

### 🤖 Android (Google Play)

Toto vytvorí optimalizovaný, obfuskovaný `.aab` balíček pripravený na upload.

```bash
flutter build appbundle \
  --release \
  --obfuscate \
  --split-debug-info=build/symbols
```

*   **Výstup:** `build/app/outputs/bundle/release/app-release.aab`
*   **Next Step:** Upload do [Google Play Console](https://play.google.com/console). Pozri [Submission Guide](docs/GOOGLE_PLAY_SUBMISSION.md).

### 🌐 Web (PWA)

```bash
flutter build web --release \
  --web-renderer canvaskit \
  --pwa-strategy offline-first \
  --dart-define=FLUTTER_WEB_USE_SKIA=true
```

*   **Deploy:** `firebase deploy --only hosting`

---

## ✅ TODO: Čo treba ešte dokončiť? (Post-Release)

Tieto kroky sú potrebné pre plnú produkčnú prevádzku, ale aplikácia funguje aj bez nich (v obmedzenom alebo testovacom režime).

### 1. 🛡️ ReCaptcha Enterprise (Security)
*   **[Setup Guide](docs/RECAPTCHA_SETUP.md):** Podrobné inštrukcie a API kľúče pre tvoj projekt (`bizagent-live-2026`).
*   Configurované v `web/index.html`.
*   [ ] **Backend Verification:** Implementuj Cloud Function podľa návodu v `docs/RECAPTCHA_SETUP.md` (ak nepoužívaš Firebase App Check).

### 2. 📧 Production Mail Server (SendGrid/Postmark)
Momentálne emaily (faktúry) chodia cez predvolený Firebase/Google SMTP alebo testovací server.
*   [ ] Integrovať dedikovanú službu (napr. SendGrid) pre vyššiu doručiteľnosť faktúr klientom.

### 3. 🍎 iOS Verzia (Apple App Store)
Android (`.aab`) je hotový. Pre iOS treba:
*   [ ] Mac s Xcode.
*   [ ] Apple Developer Account (99$/rok).
*   [ ] Spustiť `flutter build ipa`.

### 4. 💳 Validácia IČO/DIČ/IČ DPH (Unified)
Súčasné overovanie je zjednotené cez BizAgent Gateway (Contract v1.0.0). napojené na Slovensko.Digital a IcoAtlas.
* [x] **Unifikovaný Register:** Všetky klientské lookupy sú proxované cez serverless gateway.
* [ ] **VIES API:** Pre obchodovanie s EU pridať validáciu cez VIES (EU Commission API) pre automatické overenie DPH.

---

## ✨ Kľúčové Funkcie (Features)

### 📄 Faktúry
*   Generovanie **PDF** v reálnom čase.
*   **QR kódy (PAY by square)** pre slovenské banky.
*   Automatické číslovanie a sledovanie splatnosti.

### 🤖 AI Magic Scan
*   Skenovanie bločkov kamerou.
*   Vyčítanie sumy, dátumu a firmy cez Google ML Kit / Gemini.

### 📊 Daňový Teplomer
*   Sledovanie obratu za 12 mesiacov vs. limit **49 790 €**.
*   Upozornenie na povinnosť registrácie DPH.

### 🔒 Bezpečnosť
*   Dáta uložené v **Cloud Firestore** (Google Cloud).
*   Šifrovaný prenos (SSL).
*   Prihlásenie cez Google / Apple / Email.

---

**Made with ❤️ for Slovak entrepreneurs**
