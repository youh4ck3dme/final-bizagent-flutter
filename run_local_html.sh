#!/bin/bash

# 1. Definícia cesty ku Chrome
export CHROME_EXECUTABLE="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# 2. Spustenie Flutteru na porte 3333
echo "🚀 Spúšťam BizAgent lokálne na porte 3333..."
flutter run -d chrome --web-port=3333 --web-hostname=localhost
