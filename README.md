# BizAgent 🚀

**AI Business Assistant pre SZČO a malé firmy na Slovensku**

[![Flutter](https://img.shields.io/badge/Flutter-3.10.7-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Cloud-FFCA28?logo=firebase)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/Tests-17%2F17%20passing-success)](https://github.com/youh4ck3dme/BizAgent/actions)

> Kompletné riešenie pre faktúry, výdavky a accounting - špeciálne navrhnuté pre slovenský trh.

## ✨ Features

### 📄 Faktúry
- ✅ Automatické číslovanie (YYYY/XXX formát)
- ✅ QR platba na faktúre (EPC-QR kód)
- ✅ PDF export
- ✅ Podpora DPH (0%, 10%, 20%)
- ✅ Variabilný symbol z čísla faktúry
- ✅ Real-time sync (Firebase ready)

### 💰 Výdavky & Intelligence
- ✅ **Auto-kategorizácia**: Inteligentné priraďovanie kategórií (35+) s vysokou presnosťou.
- ✅ **Expense Analytics**: Vizualizácia výdavkov pomocou koláčových a stĺpcových grafov.
- ✅ **OCR skenovanie**: Automatické rozpoznávanie sumy a dodávateľa z bločkov (ML Kit).
- ✅ **Receipt Viewer**: Full-screen prehliadač s interaktívnym zoomom.
- ✅ **Pokročilé Filtre**: Filtrovanie podľa kategórií, dátumu a sumy + rôzne možnosti zoradenia.
- ✅ **Cloud Storage**: Bezpečné ukladanie účteniek do Firebase Storage.

### 🏦 Bank Import
- ✅ CSV import z banky
- ✅ Automatické párovanie faktúr
- ✅ Smart matching (VS + suma)
- ✅ Podpora SK bánk

## 🛠️ Tech Stack

- **Framework:** Flutter 3.x
- **State Management:** Riverpod 2.6.1
- **Navigation:** GoRouter 17.0.1
- **Backend:** Firebase (Auth, Firestore, Storage, Hosting)
- **Charts:** fl_chart 0.69.0
- **OCR:** google_mlkit_text_recognition
- **Architecture:** Clean Architecture

## 🚀 Run Dev

Ensure you have your environment set up and dependencies installed (`flutter pub get`).

```bash
# Web
flutter run -d chrome

# Android
flutter run -d android

# iOS
flutter run -d ios
```

## 🧪 Testing

Maintain code quality and verify functionality:

```bash
# Run unit and widget tests
flutter test

# Static analysis
flutter analyze
```

## 🔐 Auth & Cloud Sync

Aplikácia je plne integrovaná s **Firebase Auth**, čo umožňuje bezpečné ukladanie dát a synchronizáciu medzi zariadeniami. Dátumy, faktúry aj nahrané účtenky sú bezpečne uložené v Cloude, prioritne pre slovenský trh a legislatívu.

## 🚀 Deployment (Web)

Aplikácia je optimalizovaná pre **PWA** (Progressive Web App). Nasadenie na Firebase Hosting:

1. `flutterfire configure` (prepojenie s projektom)
2. `flutter build web --release`
3. `firebase deploy --only hosting`

Kompletný sprievodca nasadením je v [DEPLOYMENT.md](docs/DEPLOYMENT.md).

## ⚙️ Konfigurácia (Firebase & AI)

Pre plnú funkcionalitu (Auth, Cloud Storage, AI Tools) je potrebná konfigurácia:

1. **Firebase**: Nastavte pomocou `flutterfire configure`.
2. **Gemini API**: Pre AI generátor emailov.

👉 **[Detailný návod na nastavenie Firebase a Gemini API](docs/FIREBASE_GEMINI.md)**

## 📖 Documentation

| Document | Description |
|----------|-------------|
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Clean architecture & Riverpod patterns |
| [SETUP.md](docs/SETUP.md) | Dev environment setup |
| [DEPLOYMENT.md](docs/DEPLOYMENT.md) | Store release guides |
| [TESTING.md](docs/TESTING.md) | Test strategy & coverage |

## 🏗️ Project Structure

```
lib/
├── core/              # Core utilities, theme, router
├── features/         # Feature modules (auth, invoices, expenses, etc.)
├── shared/          # Shared widgets & models
└── main.dart        # Entry point
```

## 📱 Platform Support

- ✅ **Web:** Production ready (Primary)
- 🚧 **Android/iOS:** Beta (Mobile optimization in progress)
- 🔜 **Desktop:** Planned

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

**Made with ❤️ for Slovak entrepreneurs**
