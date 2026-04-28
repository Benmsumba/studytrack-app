#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/studytrack"
RELEASE_DIR="$ROOT_DIR/release"

REQUIRED_ENV_VARS=(
	SUPABASE_URL
	SUPABASE_ANON_KEY
	GEMINI_API_KEY
)

"$ROOT_DIR/scripts/pre_build_check.sh"

for env_var in "${REQUIRED_ENV_VARS[@]}"; do
	if [[ -z "${!env_var:-}" || "${!env_var}" == YOUR_* ]]; then
		echo "Missing required release environment variable: $env_var"
		echo "Set it before running this script."
		exit 1
	fi
done

cd "$APP_DIR"
flutter clean
flutter pub get
flutter build apk --release --split-per-abi \
	--tree-shake-icons \
	--obfuscate \
	--split-debug-info="$RELEASE_DIR/symbols" \
	--dart-define="SUPABASE_URL=$SUPABASE_URL" \
	--dart-define="SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY" \
	--dart-define="GEMINI_API_KEY=$GEMINI_API_KEY"

mkdir -p "$RELEASE_DIR"
cp -f build/app/outputs/flutter-apk/*.apk "$RELEASE_DIR"/

echo
echo "Generated APK files:"
ls -lh "$RELEASE_DIR"/*.apk

echo
echo "APK ready! Share app-arm64-v8a-release.apk with friends"
