#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/studytrack"
RELEASE_DIR="$ROOT_DIR/release"

"$ROOT_DIR/scripts/pre_build_check.sh"

cd "$APP_DIR"
flutter clean
flutter pub get
flutter build apk --release --split-per-abi

mkdir -p "$RELEASE_DIR"
cp -f build/app/outputs/apk/release/*.apk "$RELEASE_DIR"/

echo
echo "Generated APK files:"
ls -lh "$RELEASE_DIR"/*.apk

echo
echo "APK ready! Share app-arm64-v8a-release.apk with friends"
