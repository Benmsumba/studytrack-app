#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/studytrack"

PASS_COUNT=0
TOTAL_COUNT=10

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
if [[ -f "$APP_DIR/lib/.env" || -f "$APP_DIR/.env" ]]; then
  pass ".env file exists"
else
  fail ".env file missing"
fi

# 3. Supabase connection vars present
if grep -q "SUPABASE_URL" "$APP_DIR/pubspec.yaml"; then
  pass "Supabase config wiring present"
else
  fail "Supabase config wiring missing"
fi

# 4. Gemini key wiring
if grep -q "GEMINI_API_KEY" "$ROOT_DIR/.github/workflows/build_apk.yml" 2>/dev/null; then
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

# 9. backend Dockerfile or supabase-only mode
if [[ -f "$ROOT_DIR/backend/Dockerfile" ]]; then
  pass "Backend Dockerfile exists"
else
  warn "Backend Dockerfile absent (Supabase-only mode assumed)"
  pass "Backend check (Supabase-only)"
fi

# 10. GitHub actions workflows
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
