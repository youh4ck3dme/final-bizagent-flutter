#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(pwd)"

echo "[1/8] Fix PATH for flutterfire (current shell only)..."
export PATH="$PATH:$HOME/.pub-cache/bin"

echo "[2/8] Detect flutter binary..."
FLUTTER_CMD="flutter"
if ! command -v flutter >/dev/null 2>&1; then
  for p in "$HOME/flutter/bin/flutter" "/opt/homebrew/bin/flutter" "/usr/local/bin/flutter"; do
    if [[ -x "$p" ]]; then
      FLUTTER_CMD="$p"
      break
    fi
  done
fi
if [[ "$FLUTTER_CMD" == "flutter" ]] && ! command -v flutter >/dev/null 2>&1; then
  echo "ERROR: Flutter not found. Install Flutter first." >&2
  exit 1
fi
echo "Using flutter: $FLUTTER_CMD"

echo "[3/8] Ensure firebase CLI exists..."
if ! command -v firebase >/dev/null 2>&1; then
  echo "ERROR: firebase CLI not found. Install with: npm install -g firebase-tools" >&2
  exit 1
fi

echo "[4/8] Ensure flutterfire exists..."
if ! command -v flutterfire >/dev/null 2>&1; then
  echo "flutterfire not in PATH, trying to install/activate..."
  "$FLUTTER_CMD" --version >/dev/null
  command -v dart >/dev/null 2>&1 || { echo "ERROR: dart not found"; exit 1; }
  dart pub global activate flutterfire_cli
  export PATH="$PATH:$HOME/.pub-cache/bin"
fi
command -v flutterfire >/dev/null 2>&1 || { echo "ERROR: flutterfire still not found in PATH"; exit 1; }

echo "[5/8] Firebase login (interactive)..."
firebase login

echo "[6/8] flutterfire configure (interactive)..."
cd "$PROJECT_DIR"
flutterfire configure

echo "[7/8] Try to run on Chrome first (no Xcode required)..."
"$FLUTTER_CMD" run -d chrome

echo "[8/8] If you want macOS desktop run, check Xcode..."
if xcrun -f xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild found. You can run: $FLUTTER_CMD run -d macos"
else
  echo "WARNING: xcodebuild missing. Install Xcode from App Store, then run:"
  echo "  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
  echo "  sudo xcodebuild -license accept"
  echo "  $FLUTTER_CMD run -d macos"
fi
