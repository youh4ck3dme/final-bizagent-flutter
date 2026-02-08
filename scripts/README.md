# BizAgent Production Toolkit Scripts

This directory contains essential scripts for production deployment of the BizAgent Flutter app.

## 📋 Available Scripts

### 1. 🔐 Keystore Setup (`setup_keystore.sh`)

Interactive wizard for creating and configuring Android keystore for production releases.

**Usage:**
```bash
./scripts/setup_keystore.sh
```

**Features:**
- Validates Java keytool availability
- Creates secure keystore with RSA 2048-bit keys
- Generates `android/key.properties` configuration
- Validates `.gitignore` to prevent credential leaks
- Provides detailed security instructions
- Backs up existing keystores automatically

**Requirements:**
- Java JDK 8 or higher (for keytool command)

**Output:**
- Keystore file: `~/.android/keystores/bizagent-release.keystore`
- Configuration: `android/key.properties`

---

### 2. ✅ Keystore Verification (`verify_keystore.sh`)

Verifies keystore setup and signing configuration before building releases.

**Usage:**
```bash
./scripts/verify_keystore.sh
```

**Checks:**
- ✓ `key.properties` exists and is properly configured
- ✓ Keystore file exists and is valid
- ✓ Passwords are correct
- ✓ `.gitignore` includes sensitive files
- ✓ `build.gradle` has signing configuration

**Exit Codes:**
- `0` - All checks passed
- `1` - Errors found (must fix before release build)

---

### 3. 🎨 Asset Validation (`validate_assets.sh`)

Validates Google Play Store assets meet all requirements.

**Usage:**
```bash
./scripts/validate_assets.sh
```

**Validates:**
- **App Icon** (512×512 PNG, max 1MB)
- **Feature Graphic** (1024×500 PNG, max 1MB)
- **Screenshots** (2-8 phone screenshots, 16:9 or 9:16 aspect ratio)
- **Store Listings** (Slovak & English text files with character limits)

**Requirements:**
- ImageMagick (optional, for detailed validation)
  - macOS: `brew install imagemagick`
  - Ubuntu: `apt-get install imagemagick`

**Directory Structure:**
```
google_play_assets/
├── icons/
│   └── app_icon_512.png
├── feature_graphic/
│   └── feature_graphic.png
├── screenshots/
│   └── phone/
│       ├── screenshot_1.png
│       └── screenshot_2.png
└── store_listings/
    ├── sk_SK/
    │   ├── title.txt (max 50 chars)
    │   ├── short_description.txt (max 80 chars)
    │   └── full_description.txt (max 4000 chars)
    └── en_US/
        ├── title.txt
        ├── short_description.txt
        └── full_description.txt
```

---

### 4. 🧪 Complete Test Suite (`test_full_suite.sh`)

Runs full test suite including cleaning, analysis, formatting, and tests.

**Usage:**
```bash
./scripts/test_full_suite.sh
```

**Steps:**
1. `flutter clean` - Clean build artifacts
2. `flutter pub get` - Install dependencies
3. `flutter analyze` - Static code analysis
4. `dart format --set-exit-if-changed` - Check code formatting
5. `flutter test` - Run unit & widget tests
6. `flutter test integration_test/` - Run integration tests (optional)

**Exit Codes:**
- `0` - All tests passed (ready for production)
- `1` - Some tests failed (fix before deploying)

---

## 🚀 Production Deployment Workflow

### Step 1: Setup Keystore (First Time Only)
```bash
./scripts/setup_keystore.sh
```

### Step 2: Verify Setup
```bash
./scripts/verify_keystore.sh
```

### Step 3: Run Full Test Suite
```bash
./scripts/test_full_suite.sh
```

### Step 4: Validate Assets
```bash
./scripts/validate_assets.sh
```

### Step 5: Build Release
```bash
flutter clean
flutter build appbundle --release
```

### Step 6: Upload to Google Play Console
1. Go to [Google Play Console](https://play.google.com/console)
2. Upload the AAB file from: `build/app/outputs/bundle/release/app-release.aab`
3. Upload assets from: `google_play_assets/`
4. Fill in store listing details
5. Submit for review

---

## 🔒 Security Best Practices

### ⚠️ Never Commit These Files:
- `android/key.properties`
- `*.keystore`
- `*.jks`

These are already in `.gitignore` but always verify!

### ✅ Backup Your Keystore:
```bash
# Backup location
~/.android/keystores/bizagent-release.keystore

# Recommended backup methods:
- Encrypted cloud storage (Google Drive, OneDrive)
- Password manager (1Password, LastPass)
- Encrypted USB drive
- Multiple secure locations
```

**⚠️ WARNING:** If you lose your keystore, you **CANNOT** update your app on Google Play!

---

## 🛠️ Troubleshooting

### "keytool not found"
Install Java JDK:
- **Ubuntu/Debian:** `sudo apt-get install openjdk-17-jdk`
- **macOS:** `brew install openjdk@17`
- **Windows:** Download from [Adoptium](https://adoptium.net/)

### "ImageMagick not found" in validate_assets.sh
The script will still work but with limited validation. To enable full validation:
- **macOS:** `brew install imagemagick`
- **Ubuntu:** `sudo apt-get install imagemagick`

### "Invalid keystore password"
Run `./scripts/setup_keystore.sh` again and use the correct password, or restore from backup.

### Build fails with signing errors
1. Verify keystore setup: `./scripts/verify_keystore.sh`
2. Check `android/key.properties` exists and has correct values
3. Ensure `android/app/build.gradle.kts` has proper signing configuration

---

## 📚 Additional Resources

- [Flutter Android Deployment Guide](https://flutter.dev/docs/deployment/android)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer/)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)

---

## 📞 Support

Need help? Contact: **support@bizagent.app**
