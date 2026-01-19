# BizAgent 🚀

**AI Business Assistant pre SZČO a malé firmy na Slovensku**

[![Flutter](https://img.shields.io/badge/Flutter-3.10.7-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Cloud-FFCA28?logo=firebase)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Tests](https://img.shields.io/badge/Tests-17%2F17%20passing-success)](https://github.com/youh4ck3dme/BizAgent/actions)

> Kompletné riešenie pre faktúry, výdavky a accounting - špeciálne navrhnuté pre slovenský trh.

## ✨ Features (Elite Release 2026)

### 🚀 Production Ready PWA
- ✅ **Offline-First:** Práca bez internetu s automatickou synchronizáciou.
- ✅ **Installable:** Podpora pre PWA inštaláciu (Manifest, Shortcuts).
- ✅ **Clean URLs:** Profesionálne URL bez hash fragmentov (`/dashboard` vs `/#/dashboard`).
- ✅ **Performance:** Start < 1s (CanvasKit + Asset Caching).

### 🔐 Bezpečnosť & Auth
- ✅ **Google Sign-In:** Oficiálna integrácia cez Firebase Auth (One-Tap ready).
- ✅ **Secure Data:** Strict Firestore Schema Validation rules.
- ✅ **Safe Storage:** Validácia nahrávaných súborov (Max 10MB, Images Only).

### 📄 Faktúry & Financie
- ✅ **Automatické číslovanie:** (YYYY/XXX formát)
- ✅ **Smart QR:** Generovanie EPC-QR kódov pre okamžitú platbu.
- ✅ **PDF Export:** Profesionálne PDF faktúry.
- ✅ **Dashboard:** Interaktívne grafy, "Magic Scan" a smart prehľady.

### 💰 Výdavky & Intelligence
- ✅ **Auto-kategorizácia:** AI priraďovanie kategórií.
- ✅ **Expense Analytics:** Vizualizácia výdavkov v čase.
- ✅ **OCR skenovanie:** Automatické vyčítanie dát z bločkov.

## 🛠️ Tech Stack & Architecture

- **Framework:** Flutter 3.x (Web: CanvasKit)
- **State Management:** Riverpod 2.6.1 (Architecture: Riverpod Generator)
- **Cloud:** Firebase (Auth, Firestore, Storage, Hosting, Functions)
- **UI:** Custom "Elite" Design System (Pulse animations, Shimmers)

## 🚀 Deployment (Elite PWA)

Aplikácia je optimalizovaná pre **PWA** s rendererom CanvasKit pre maximálny výkon.

**1. Production Build:**
```bash
flutter build web --release \
  --web-renderer canvaskit \
  --pwa-strategy offline-first \
  --dart-define=FLUTTER_WEB_USE_SKIA=true
```

**2. Deploy to Firebase:**
```bash
firebase deploy --only hosting
```

**3. Verification:**
- Skontrolujte `LightHouse` skóre (Current target: >90).
- Overte offline funkčnosť cez Chrome DevTools.

## 📱 Platform Support

- ✅ **Web (PWA):** Elite Production Ready (Chrome, Safari, Edge)
- 🚧 **Mobile (Native):** Android/iOS ready (via Capacitor/Flutter Native)
- 🔜 **Desktop:** Planned

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

**Made with ❤️ for Slovak entrepreneurs**
