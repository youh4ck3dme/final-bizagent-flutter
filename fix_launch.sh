#!/bin/bash
echo "🚀 Starting Robust Fix & Launch Script (Local Cache Mode)"

# clean up
echo "🧹 Cleaning project..."
flutter clean
rm -rf .dart_tool
rm -rf build
rm -rf .local_pub_cache

# set local pub cache to bypass global issues
echo "🔧 Setting local PUB_CACHE..."
export PUB_CACHE=$(pwd)/.local_pub_cache
mkdir -p "$PUB_CACHE"
echo "  -> PUB_CACHE set to: $PUB_CACHE"

echo "📦 Getting dependencies..."
flutter pub get

echo "🌐 Launching Chrome..."
# Ensure we pass the env var to the run command as well, though export handles it for this shell
flutter run -d chrome --web-port=3000
