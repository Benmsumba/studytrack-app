#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# StudyTrack — Production Release Build Script
#
# Usage:
#   ./scripts/build_release.sh [--apk] [--aab] [--env /path/to/.env]
#
# Options:
#   --apk          Build a split-per-ABI debug-installable APK   (default: both)
#   --aab          Build an Android App Bundle for the Play Store (default: both)
#   --env FILE     Path to dart-define env file (default: .env in repo root)
#   --skip-tests   Skip unit tests (not recommended for production)
#   --skip-analyze Skip static analysis
#
# Prerequisites:
#   1. Flutter SDK on PATH (run `flutter doctor` to verify)
#   2. Java 17+ on PATH (required by Gradle)
#   3. android/key.properties pointing at a valid release keystore  -OR-
#      KEYSTORE_PATH, KEYSTORE_PASSWORD, KEY_ALIAS, KEY_PASSWORD env vars set
#   4. .env file (or --env flag) with SUPABASE_URL, SUPABASE_ANON_KEY, etc.
#
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

# ── Colours ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

info()    { echo -e "${CYAN}▶${NC} $*"; }
success() { echo -e "${GREEN}✓${NC} $*"; }
warn()    { echo -e "${YELLOW}⚠${NC} $*"; }
error()   { echo -e "${RED}✗ ERROR:${NC} $*" >&2; exit 1; }

# ── Argument parsing ──────────────────────────────────────────────────────────
BUILD_APK=true; BUILD_AAB=true; SKIP_TESTS=false; SKIP_ANALYZE=false
ENV_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apk)           BUILD_AAB=false ;;
    --aab)           BUILD_APK=false ;;
    --env)           shift; ENV_FILE="$1" ;;
    --skip-tests)    SKIP_TESTS=true ;;
    --skip-analyze)  SKIP_ANALYZE=true ;;
    *) warn "Unknown flag: $1" ;;
  esac
  shift
done

# ── Locate project root ───────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
FLUTTER_PROJECT="$REPO_ROOT/studytrack"
OUTPUT_DIR="$REPO_ROOT/release_output"

cd "$FLUTTER_PROJECT"

echo -e "\n${BOLD}═══════════════════════════════════════════════${NC}"
echo -e "${BOLD}   StudyTrack Production Release Builder       ${NC}"
echo -e "${BOLD}═══════════════════════════════════════════════${NC}\n"

# ── Locate .env file ──────────────────────────────────────────────────────────
if [[ -z "$ENV_FILE" ]]; then
  ENV_FILE="$REPO_ROOT/.env"
fi

if [[ ! -f "$ENV_FILE" ]]; then
  error ".env file not found at '$ENV_FILE'.\n  Copy .env.example → .env and fill in your values.\n  Or pass --env /path/to/.env"
fi
success "Using env file: $ENV_FILE"

# ── Verify required vars in .env ──────────────────────────────────────────────
check_env_var() {
  local key="$1"
  local value
  value=$(grep "^${key}=" "$ENV_FILE" | cut -d= -f2- | tr -d '"' | tr -d "'" | xargs)
  if [[ -z "$value" || "$value" == "https://your-project-ref"* || "$value" == "eyJhbG"*"..." ]]; then
    error "Required variable $key is missing or still a placeholder in $ENV_FILE"
  fi
  success "$key is configured"
}

info "Verifying environment variables…"
check_env_var "SUPABASE_URL"
check_env_var "SUPABASE_ANON_KEY"

# Warn (not fail) for optional keys
SENTRY_DSN=$(grep "^SENTRY_DSN=" "$ENV_FILE" | cut -d= -f2- | xargs || true)
if [[ -z "$SENTRY_DSN" ]]; then
  warn "SENTRY_DSN not set — crash reporting will be disabled in this build."
fi

# ── Verify signing config ─────────────────────────────────────────────────────
info "Verifying signing configuration…"
KEY_PROPS="$FLUTTER_PROJECT/android/key.properties"
if [[ -f "$KEY_PROPS" ]]; then
  STORE_FILE=$(grep "^storeFile=" "$KEY_PROPS" | cut -d= -f2-)
  if [[ ! -f "$FLUTTER_PROJECT/android/$STORE_FILE" ]]; then
    error "key.properties references '$STORE_FILE' but file does not exist.\n  Run the keystore generation command first — see scripts/build_release.sh header."
  fi
  success "key.properties found and keystore file exists"
elif [[ -n "${KEYSTORE_PATH:-}" ]]; then
  [[ -f "$KEYSTORE_PATH" ]] || error "KEYSTORE_PATH='$KEYSTORE_PATH' does not exist"
  success "CI keystore env vars detected"
else
  error "No signing config found.\n  Either:\n  1. Create android/key.properties (copy from android/key.properties.template)\n  2. Set KEYSTORE_PATH, KEYSTORE_PASSWORD, KEY_ALIAS, KEY_PASSWORD env vars"
fi

# ── Flutter doctor quick check ────────────────────────────────────────────────
info "Checking Flutter installation…"
flutter doctor -v 2>&1 | grep -E "^\[|Flutter|Dart|Android" | head -10 || true

# ── Clean + get deps ──────────────────────────────────────────────────────────
info "Cleaning previous build artefacts…"
flutter clean

info "Fetching dependencies…"
flutter pub get

# ── Static analysis ───────────────────────────────────────────────────────────
if [[ "$SKIP_ANALYZE" == false ]]; then
  info "Running static analysis (dart analyze)…"
  flutter analyze lib/ --no-fatal-infos || error "Static analysis failed — fix issues before shipping."
  success "Static analysis passed"
fi

# ── Tests ─────────────────────────────────────────────────────────────────────
if [[ "$SKIP_TESTS" == false ]]; then
  info "Running test suite…"
  flutter test || error "Tests failed — fix before building a release."
  success "All tests passed"
fi

# ── Derive version from pubspec ───────────────────────────────────────────────
VERSION=$(grep "^version:" pubspec.yaml | awk '{print $2}')
BUILD_NUM="${VERSION##*+}"
VERSION_NAME="${VERSION%%+*}"
info "Building version: $VERSION_NAME (build $BUILD_NUM)"

mkdir -p "$OUTPUT_DIR"

DART_DEFINE_FLAG="--dart-define-from-file=$ENV_FILE"

# ── Build AAB ─────────────────────────────────────────────────────────────────
if [[ "$BUILD_AAB" == true ]]; then
  echo ""
  info "Building Android App Bundle (AAB) for Play Store…"
  flutter build appbundle \
    --release \
    $DART_DEFINE_FLAG \
    --obfuscate \
    --split-debug-info="$OUTPUT_DIR/debug-info-aab"

  AAB_SRC="build/app/outputs/bundle/release/app-release.aab"
  AAB_DEST="$OUTPUT_DIR/studytrack-v${VERSION_NAME}-build${BUILD_NUM}.aab"
  [[ -f "$AAB_SRC" ]] || error "AAB not found at $AAB_SRC"
  cp "$AAB_SRC" "$AAB_DEST"
  success "AAB → $AAB_DEST"
  echo -e "       Size: $(du -sh "$AAB_DEST" | cut -f1)"
fi

# ── Build APK ─────────────────────────────────────────────────────────────────
if [[ "$BUILD_APK" == true ]]; then
  echo ""
  info "Building universal APK (for direct sideload / QA testing)…"
  flutter build apk \
    --release \
    $DART_DEFINE_FLAG \
    --obfuscate \
    --split-debug-info="$OUTPUT_DIR/debug-info-apk"

  APK_SRC="build/app/outputs/apk/release/app-release.apk"
  APK_DEST="$OUTPUT_DIR/studytrack-v${VERSION_NAME}-build${BUILD_NUM}.apk"
  [[ -f "$APK_SRC" ]] || error "APK not found at $APK_SRC"
  cp "$APK_SRC" "$APK_DEST"
  success "APK → $APK_DEST"
  echo -e "       Size: $(du -sh "$APK_DEST" | cut -f1)"
fi

# ── Checksums ─────────────────────────────────────────────────────────────────
echo ""
info "Generating SHA-256 checksums…"
(cd "$OUTPUT_DIR" && sha256sum studytrack-v"${VERSION_NAME}"-* > checksums-v"${VERSION_NAME}".txt)
cat "$OUTPUT_DIR/checksums-v${VERSION_NAME}.txt"

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}═══════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}   BUILD SUCCESSFUL — v${VERSION_NAME} (build ${BUILD_NUM})${NC}"
echo -e "${BOLD}═══════════════════════════════════════════════${NC}"
echo ""
echo -e "${BOLD}Output directory:${NC} $OUTPUT_DIR"
ls -lh "$OUTPUT_DIR"/studytrack-v"${VERSION_NAME}"-* 2>/dev/null || true
echo ""
echo -e "${BOLD}Debug symbols:${NC} Keep the debug-info-* folders safe."
echo "  Upload them to Sentry: https://docs.sentry.io/platforms/flutter/"
echo "  They are required to de-obfuscate crash stack traces."
echo ""
echo -e "${BOLD}Next steps:${NC}"
echo "  1. Install APK on a test device:"
echo "     adb install $APK_DEST"
echo "  2. Upload AAB to Google Play Console:"
echo "     https://play.google.com/console"
echo "  3. Tag this release in git:"
echo "     git tag -a v${VERSION_NAME} -m 'Release v${VERSION_NAME}'"
echo "     git push origin v${VERSION_NAME}"
echo ""
echo -e "${YELLOW}⚠  KEYSTORE WARNING:${NC}"
echo "   Back up your keystore file and key.properties to a SECURE location"
echo "   (password manager, encrypted drive). If you lose them you CANNOT"
echo "   publish future updates to the same Play Store listing."
echo ""
