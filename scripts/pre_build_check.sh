#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/studytrack"

PASS_COUNT=0
TOTAL_COUNT=12

GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
NC="\033[0m"

pass() {
  echo -e "${GREEN}✓${NC} $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  echo -e "${RED}✗${NC} $1"
}

warn() {
  echo -e "${YELLOW}!${NC} $1"
}

# 1. flutter analyze
if (cd "$APP_DIR" && flutter analyze >/dev/null 2>&1); then
  pass "flutter analyze"
else
  fail "flutter analyze"
fi

# 2. env file exists
if [[ -f "$APP_DIR/.env.example" || -f "$APP_DIR/lib/.env.example" ]]; then
  pass "Example env file exists"
else
  fail "Example env file missing"
fi

# 3. Supabase connection wiring present
if grep -q "String.fromEnvironment('SUPABASE_URL')" "$APP_DIR/lib/core/constants/app_constants.dart" && \
  grep -q "String.fromEnvironment('SUPABASE_ANON_KEY')" "$APP_DIR/lib/core/constants/app_constants.dart"; then
  pass "Supabase config wiring present"
else
  fail "Supabase config wiring missing"
fi

# 4. Gemini key wiring
if grep -q "String.fromEnvironment('GEMINI_API_KEY')" "$APP_DIR/lib/core/services/gemini_service.dart"; then
  pass "Gemini API key wiring"
else
  fail "Gemini API key wiring missing"
fi

# 5. Android signing keystore template path
if [[ -f "$APP_DIR/android/key.properties" || -f "$APP_DIR/android/key.properties.template" ]]; then
  pass "Android signing properties present"
else
  fail "Android signing properties missing"
fi

# 6. AndroidManifest permissions baseline
if grep -q "android.permission.INTERNET" "$APP_DIR/android/app/src/main/AndroidManifest.xml"; then
  pass "AndroidManifest contains required permission"
else
  fail "AndroidManifest missing INTERNET permission"
fi

# 7. app icons generated
if [[ -d "$APP_DIR/android/app/src/main/res/mipmap-hdpi" ]] && compgen -G "$APP_DIR/android/app/src/main/res/mipmap-*/ic_launcher*" >/dev/null; then
  pass "App icons generated"
else
  fail "App icons not found"
fi

# 8. version set
if grep -qE '^version:\s*[0-9]+\.[0-9]+\.[0-9]+' "$APP_DIR/pubspec.yaml"; then
  pass "pubspec version configured"
else
  fail "pubspec version missing"
fi

# 9. Linux desktop native prerequisites
if command -v pkg-config >/dev/null 2>&1 && \
  pkg-config --exists gtk+-3.0 gstreamer-1.0 gstreamer-app-1.0 gstreamer-audio-1.0; then
  pass "Linux desktop native dependencies present"
else
  fail "Linux desktop native dependencies missing"
fi

# 10. Android SDK availability
if [[ -n "${ANDROID_HOME:-}" && -d "${ANDROID_HOME:-}" ]] || [[ -n "${ANDROID_SDK_ROOT:-}" && -d "${ANDROID_SDK_ROOT:-}" ]]; then
  pass "Android SDK path configured"
else
  fail "Android SDK path missing"
fi

# 11. backend Dockerfile or supabase-only mode
if [[ -f "$ROOT_DIR/backend/Dockerfile" ]]; then
  pass "Backend Dockerfile exists"
else
  warn "Backend Dockerfile absent (Supabase-only mode assumed)"
  pass "Backend check (Supabase-only)"
fi

# 12. GitHub actions workflows
if [[ -f "$ROOT_DIR/.github/workflows/build_apk.yml" ]]; then
  pass "GitHub Actions workflow exists"
else
  fail "GitHub Actions workflow missing"
fi

if [[ "$PASS_COUNT" -eq "$TOTAL_COUNT" ]]; then
  READY="YES"
else
  READY="NO"
fi

echo
printf "%s/%s checks passed. Ready to build: %s\n" "$PASS_COUNT" "$TOTAL_COUNT" "$READY"

if [[ "$READY" != "YES" ]]; then
  exit 1
fi
