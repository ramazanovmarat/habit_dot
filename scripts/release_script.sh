#!/usr/bin/env bash

set -e

echo "==> flutter clean"
flutter clean

echo "==> flutter pub get"
flutter pub get

echo "==> flutter build apk --release"
flutter build apk --release

echo "Готово. APK ищи в: build/app/outputs/apk/release/"

