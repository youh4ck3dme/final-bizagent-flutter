# 📱 Google Play Store Submission Guide

Tento dokument obsahuje **presné odpovede a texty**, ktoré budeš potrebovať pri vypĺňaní formulárov v **Google Play Console**. Postupuj krok za krokom, aby nám to nezamietli.

---

## 1. Store Listing (Záznam v obchode)

Toto vidia používatelia v obchode. Texty sú optimalizované pre ASO (App Store Optimization) a SK kľúčové slová.

*   **App Name (max 30 znakov):** `BizAgent - AI Účtovný Asistent`  
    *Alternatíva:* `BizAgent: Faktúry & Bločky AI`
*   **Short Description (max 80 znakov):** `Skenuj bločky, spravuj výdavky a faktúry s AI. Pre SZČO a firmy na Slovensku.`
*   **Full Description (max 4000 znakov):**
    ```text
    Skenuj bločky, spravuj výdavky a faktúry s AI. BizAgent je účtovný asistent pre SZČO a firmy na Slovensku.

    ✨ PREČO BIZAGENT?
    • Skenovanie bločkov pomocou AI – vyčítanie sumy, dátumu a obchodníka za sekundy
    • Evidencia výdavkov a faktúr na jednom mieste
    • Daňové priznanie a DPH prehľad – limit 49 790 €
    • Živnostníci a podnikanie bez zbytočnej papierovej práce

    📄 FAKTÚRY A ÚČTOVNÍCTVO
    • Vystavovanie faktúr do 10 sekúnd (PDF)
    • QR platba (PAY by square) na faktúrach
    • Export pre účtovníka – Pohoda, evidencia, daňové priznanie

    🤖 AI SKENOVANIE A OCR
    • Skener účteniek – foť bloček, AI vyčíta údaje
    • Automatická evidencia výdavkov
    • Podpora slovenských bločkov a faktúr

    📊 DASHBOARD A PREHĽAD
    • Príjmy, výdavky a zisk na jednom mieste
    • Upozornenia na splatnosť faktúr
    • Tmavý režim a prehľadné rozhranie

    🔒 BEZPEČNOSŤ A OCHRANA DÁT
    • Dáta šifrované v cloude
    • Prihlásenie cez Google, biometria (otlačok / Face ID)
    • Žiadne zdieľanie s tretími stranami – GDPR

    Kľúčové slová: účtovníctvo, faktúry, bločky, SZČO, výdavky, daňové priznanie, skener účteniek, OCR, živnostník, evidencia, DPH, podnikanie.

    Čo hovoria používatelia: Jednoduché, rýchle, špeciálne pre Slovensko.
    ```

*   **Graphics:**
    *   **App Icon:** 512x512 PNG (máš v `assets/icon/app_icon_1024.png` – zmenši na 512)
    *   **Feature Graphic:** 1024x500 PNG (logo na modrom pozadí, brand farby)
    *   **Screenshots (odporúčaných 5):** 1) Hero + hlavný benefit | 2) AI skenovanie bločkov | 3) Dashboard a prehľad | 4) Faktúry a export | 5) Bezpečnosť a biometria. Použi slovenské texty v UI – lokalizované screenshoty zvyšujú konverziu.

---

## 2. App Content (Povinné formuláre)

V menu vľavo dole nájdeš sekciu **"App Content"** (Obsah aplikácie). Toto musíš vyplniť:

### 2.1 Privacy Policy (Zásady ochrany súkromia)
Pokiaľ nemáš web, otvor súbor `docs/PRIVACY_POLICY.md`, skopíruj text a vlož ho na [Flycricket](https://www.flycricket.com/) alebo Firebase Hosting.
*   **ODPORÚČANIE:** Play Store vyžaduje funkčnú URL. Lokálny súbor neakceptujú.
*   **Obsah:** Použi pripravený text z `docs/PRIVACY_POLICY.md`. Obsahuje všetky potrebné klauzuly pre "Finance" a "Camera" permissions.

### 2.2 Ads (Reklamy)
*   Otázka: *Does your app contain ads?*
*   Odpoveď: **No, my app does not contain ads.**

### 2.3 App Access (Prístup k aplikácii)
Pretože máme prihlásenie, Google Reviewer sa **MUSÍ** vedieť prihlásiť.
*   Vyber: **All or some functionality is restricted.**
*   Pridaj inštrukcie:
    *   **Username:** `demo@bizagent.sk`
    *   **Password:** `Poklop1369###`
    *   **Notes:** `This is a test account strictly for review purposes. It comes with pre-populated dummy data.`

### 🛑 2.3.1 Krok naviac: VYTVORENIE DEMO ÚČTU (Overenie funkčnosti)
Aby sa Google vedel prihlásiť, tento účet **MUSÍ EXISTOVAŤ** a byť typu **Email/Password**.

1.  Choď do **Firebase Console** -> **Authentication** -> **Users**.
2.  Klikni **"Add User"**.
3.  Email: `demo@bizagent.sk`
4.  Heslo: `Poklop1369###`
5.  Klikni **"Add User"**.
6.  **Uisti sa**, že v stĺpci "Provider" vidíš ikonu obálky (Email), nie G (Google).
7.  **Hotovo.** Teraz je to na 100%.

### 2.4 Data Safety (Bezpečnosť údajov) - **KRITICKÉ**
Toto určuje, čo sa zobrazí v sekcii "Data Safety".

1.  **Data Collection:**
    *   *Does your app collect or share any of the required user data types?* -> **NEXT** (Áno, budeme špecifikovať).
2.  **Encryption:**
    *   *Is all of the user data collected by your app encrypted in transit?* -> **YES**.
3.  **Account Deletion:**
    *   *Do you provide a way for users to request that their data is deleted?* -> **YES** (zvyčajne cez email supportu v nastaveniach).

**Specific Data Types to Select:**

*   **Personal Info -> Email Address:**
    *   *Collected?* **Yes**
    *   *Shared?* **No**
    *   *Purpose:* **App functionality, Account management**
*   **Personal Info -> User IDs:**
    *   *Collected?* **Yes**
    *   *Shared?* **No** (ID v databáze sa neráta ako sharing 3. strane)
    *   *Purpose:* **App functionality**
*   **Financial Info -> Purchase History (Faktúry/Výdavky):**
    *   *Collected?* **Yes**
    *   *Shared?* **No**
    *   *Purpose:* **App functionality**
*   **Photos and Videos -> Photos:** (Pre skenovanie bločkov)
    *   *Collected?* **Yes**
    *   *Shared?* **No**
    *   *Purpose:* **App functionality**

### 2.5 Target Audience (Cieľová skupina)
*   Vyber: **18 and over**.
*   *Could your store listing appeal to children?* -> **No**.

### 2.6 News Apps (Spravodajstvo)
*   *Is your app a news app?* -> **No**.

### 2.7 COVID-19
*   *Is your app a COVID-19 app?* -> **My app is not a publicly available COVID-19 contact tracing or status app.**

---

## 3. Technické nastavenie (Release)

Keď vytvoríš **Production** alebo **Internal Testing** release:

1.  **Signing Key:** Ak sa pýta, zvoľ **Google Play App Signing** (odporúčané).
2.  **Upload:** Nahraj súbor `build/app/outputs/bundle/release/app-release.aab`.
3.  **Release Notes (SK):**
    ```text
    🎉 Prvé vydanie BizAgent!
    - Inteligentná správa faktúr a výdavkov
    - AI skenovanie bločkov
    - Daňové prehľady pre rok 2026
    ```

---

## 4. Čo ak to zamietnu? (Troubleshooting)

*   **"Login credentials missing":** Skontroluj sekciu 2.3 App Access. Heslo musí fungovať!
*   **"Broken Functionality":** Uisti sa, že backend (Firebase) má nastavené pravidlá (Firestore Rules) tak, aby review účet mohol čítať/zapisovať.
*   **"Data Safety mismatch":** Skontroluj sekciu 2.4. Zvyčajne zabudnú ľudia priznať "Photos" pre skenovanie.

