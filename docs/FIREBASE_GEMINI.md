# Firebase & Gemini API - Kompletná Konfigurácia

## 🔥 Firebase Console Prístup

### Informácie o Projekte
- **Project ID**: `bizagent-pwa-1768727460`
- **Project Name**: BizAgent PWA
- **Firebase Console**: https://console.firebase.google.com/project/bizagent-pwa-1768727460/overview
- **Hosting URL**: https://bizagent-pwa-1768727460.web.app

### Ako sa Prihlásit
1. Otvorte: https://console.firebase.google.com
2. Prihláste sa účtom, ktorý ste použili pri `firebase login` (pravdepodobne váš GitHub email)
3. V zozname projektov kliknite na **bizagent-pwa-1768727460**

### Dôležité Sekcie v Console

#### Authentication (Používatelia)
- **URL**: https://console.firebase.google.com/project/bizagent-pwa-1768727460/authentication/users
- Tu vidíte všetkých registrovaných používateľov
- Môžete manuálne pridať/odstrániť používateľov
- Nastavenia sign-in metód (Email/Password je povolené)

#### Firestore Database (Dáta)
- **URL**: https://console.firebase.google.com/project/bizagent-pwa-1768727460/firestore
- Tu sú uložené všetky faktúry, výdavky a nastavenia
- Môžete prezerať a editovať dáta v real-time

#### Storage (Účtenky)
- **URL**: https://console.firebase.google.com/project/bizagent-pwa-1768727460/storage
- Tu sú nahrané fotky účteniek
- Štruktúra: `users/{userId}/receipts/{fileName}`

#### Hosting (Web Deployment)
- **URL**: https://console.firebase.google.com/project/bizagent-pwa-1768727460/hosting
- História deploymentov
- Možnosť rollback na predchádzajúcu verziu

---

## 🤖 Gemini API Konfigurácia

### 1. Získanie API Kľúča

1. Prejdite na: https://aistudio.google.com/app/apikey
2. Prihláste sa Google účtom
3. Kliknite **"Get API Key"** alebo **"Create API Key"**
4. Vyberte projekt (môžete vytvoriť nový alebo použiť existujúci)
5. Skopírujte vygenerovaný kľúč (začína `AIza...`)

### 2. Pridanie API Kľúča do Projektu

#### Metóda 1: Environment Variable (Odporúčané pre Development)

Vytvorte súbor `.env` v koreňovom priečinku projektu:

```bash
# .env
GEMINI_API_KEY=AIzaSy...váš_kľúč_tu
```

**DÔLEŽITÉ**: Pridajte `.env` do `.gitignore`:
```bash
echo ".env" >> .gitignore
```

#### Metóda 2: Firebase Remote Config (Odporúčané pre Production)

1. V Firebase Console prejdite na **Remote Config**
2. Pridajte parameter:
   - **Key**: `gemini_api_key`
   - **Value**: váš API kľúč
3. Publikujte zmeny

### 3. Implementácia v Kóde

Vytvorte nový súbor `lib/core/config/api_config.dart`:

```dart
class ApiConfig {
  // Pre development - načíta z environment
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
  
  static bool get hasGeminiKey => geminiApiKey.isNotEmpty;
}
```

### 4. Aktualizácia AI Email Service

Upravte `lib/features/ai_tools/providers/ai_email_service.dart` na použitie skutočného Gemini API:

```dart
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../core/config/api_config.dart';

class AiEmailService {
  late final GenerativeModel _model;
  
  AiEmailService() {
    if (ApiConfig.hasGeminiKey) {
      _model = GenerativeModel(
        model: 'gemini-pro',
        apiKey: ApiConfig.geminiApiKey,
      );
    }
  }
  
  Future<String> generateEmail({
    required String type,
    required String tone,
    required String context,
  }) async {
    if (!ApiConfig.hasGeminiKey) {
      return 'Gemini API kľúč nie je nakonfigurovaný. Pozrite dokumentáciu.';
    }
    
    final prompt = _buildPrompt(type, tone, context);
    final response = await _model.generateContent([Content.text(prompt)]);
    return response.text ?? 'Nepodarilo sa vygenerovať email.';
  }
  
  String _buildPrompt(String type, String tone, String context) {
    return '''
Vygeneruj profesionálny email v slovenčine.
Typ: $type
Tón: $tone
Kontext: $context

Požiadavky:
- Použij slovenský jazyk
- Dodržuj $tone tón komunikácie
- Email by mal byť stručný a jasný
- Nezabudni na zdvorilé oslovenie a podpis
''';
  }
}
```

### 5. Pridanie Gemini Package

Do `pubspec.yaml` pridajte:

```yaml
dependencies:
  google_generative_ai: ^0.2.0
```

Spustite:
```bash
flutter pub get
```

### 6. Spustenie s API Kľúčom

```bash
# Development (s .env súborom)
flutter run -d chrome --dart-define=GEMINI_API_KEY=AIzaSy...

# Alebo exportujte premennú
export GEMINI_API_KEY=AIzaSy...
flutter run -d chrome
```

### 7. Build pre Production

```bash
flutter build web --release --dart-define=GEMINI_API_KEY=AIzaSy...
```

---

## 🔒 Bezpečnostné Pravidlá

### Firestore Rules
V Firebase Console → Firestore → Rules nastavte:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users môžu čítať/písať len svoje dáta
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /invoices/{userId}/invoices/{invoiceId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /expenses/{userId}/expenses/{expenseId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### Storage Rules
V Firebase Console → Storage → Rules:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/receipts/{fileName} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## 📊 Monitoring & Limity

### Gemini API Limity (Free Tier)
- **60 requestov/minútu**
- **1,500 requestov/deň**
- Pre viac pozrite: https://ai.google.dev/pricing

### Firebase Spark Plan (Free)
- **Firestore**: 50K reads/day, 20K writes/day
- **Storage**: 1 GB
- **Hosting**: 10 GB/month transfer

---

## ✅ Checklist Pre Prvé Spustenie

- [ ] Prihlásenie do Firebase Console
- [ ] Overenie Authentication nastavení
- [ ] Nastavenie Firestore Rules
- [ ] Nastavenie Storage Rules
- [ ] Získanie Gemini API kľúča
- [ ] Vytvorenie `.env` súboru s API kľúčom
- [ ] Pridanie `google_generative_ai` package
- [ ] Test AI Email generátora
