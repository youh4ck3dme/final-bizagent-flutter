# 🚀 Bezpečný Backend pre Gemini AI

Aby bola aplikácia **"Tip Top"** pripravená pre Google Play/App Store a API kľúč bol v bezpečí, používame **Firebase Cloud Functions**. Kľúč nie je v aplikácii, ale na zabezpečenom serveri Google.

## 📋 Predpoklady

1. **Blaze Plan (Pay as you go)**
   - Musíte prepnúť projekt na **Blaze Plan** v [Firebase Console](https://console.firebase.google.com/project/bizagent-pwa-1768727460/overview) (vľavo dole).
   - *Prečo?* Cloud Functions vyžadujú Blaze pre prístup k externým sieťam a Google API.
   - *Cena?* Prvých 2 milióny volaní mesačne je zadarmo. Reálne nebudete platiť nič.

## 🔐 1. Nastavenie API Kľúča (Secret Manager)

Namiesto vkladania kľúča do súborov ho bezpečne uložíme do cloudu:

1. Otvorte terminál v projekte.
2. Spustite príkaz:
   ```bash
   firebase functions:secrets:set GEMINI_API_KEY
   ```
3. Keď vás vyzve (Enter a value...), vložte váš **Gemini API Key**.

## 🚀 2. Nasadenie Backendu (Funkcie)

1. Nasadenie funkcie na server:
   ```bash
   firebase deploy --only functions
   ```
   *(Tento proces môže trvať pár minút, inštaluje Node.js závislosti).*

## 🌐 3. Nasadenie Web Aplikácie

1. Vybuildujte a nasaďte frontend (už bez kľúča):
   ```bash
   flutter build web --release
   firebase deploy --only hosting
   ```

## ✅ Hotovo!
Teraz aplikácia pošle požiadavku na server → server bezpečne zavolá Gemini API s tajným kľúčom → a vráti výsledok.
Toto je najbezpečnejší "Enterprise" spôsob.
