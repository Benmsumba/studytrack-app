#!/bin/bash

# StudyTrack Production Release Build Script
# Automates Flutter APK/AAB build, versioning, and packaging

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

VERSION=${1:-}
FLAVOR=${2:-production}

if [ -z "$VERSION" ]; then
    echo -e "${RED}Error: Version not provided${NC}"
    echo "Usage: ./build_release.sh <version> [flavor]"
    echo "Example: ./build_release.sh 1.0.0 production"
    exit 1
fi

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( dirname "$SCRIPT_DIR" )"
BUILD_DIR="$PROJECT_ROOT/build_output"

echo -e "${YELLOW}=== StudyTrack Production Build ===${NC}"
echo "Version: $VERSION"
echo "Flavor: $FLAVOR"
echo "Project: $PROJECT_ROOT"
echo ""

# Pre-build checks
echo -e "${YELLOW}Running pre-build checks...${NC}"

# Check if running from correct directory
if [ ! -f "$PROJECT_ROOT/pubspec.yaml" ]; then
    echo -e "${RED}Error: pubspec.yaml not found. Run from project root. ${NC}"
    exit 1
fi

# Ensure clean build
echo -e "${YELLOW}Cleaning previous builds...${NC}"
cd "$PROJECT_ROOT"
flutter clean

# Get dependencies
echo -e "${YELLOW}Getting dependencies...${NC}"
flutter pub get

# Run analyzer
echo -e "${YELLOW}Running static analyzer...${NC}"
if ! flutter analyze lib/; then
    echo -e "${RED}Analyzer found issues. Please fix before building.${NC}"
    exit 1
fi

# Run tests
echo -e "${YELLOW}Running unit tests...${NC}"
if ! flutter test; then
    echo -e "${RED}Tests failed. Cannot proceed with build.${NC}"
    exit 1
fi

# Build AAB (Android App Bundle) for Play Store
echo -e "${YELLOW}Building Android App Bundle (AAB)...${NC}"
mkdir -p "$BUILD_DIR"

flutter build appbundle \
    --flavor "$FLAVOR" \
    --target lib/main.dart \
    --release \
    --split-per-abi=false

AAB_FILE="$PROJECT_ROOT/build/app/outputs/bundle/${FLAVOR}Release/app-${FLAVOR}-release.aab"
if [ -f "$AAB_FILE" ]; then
    cp "$AAB_FILE" "$BUILD_DIR/studytrack-v${VERSION}.aab"
    echo -e "${GREEN}✓ AAB built successfully: $BUILD_DIR/studytrack-v${VERSION}.aab${NC}"
else
    echo -e "${RED}Error: AAB file not found${NC}"
    exit 1
fi

# Build APK for direct installation/testing
echo -e "${YELLOW}Building APK...${NC}"
flutter build apk \
    --flavor "$FLAVOR" \
    --target lib/main.dart \
    --release \
    --split-per-abi

APK_FILE="$PROJECT_ROOT/build/app/outputs/apk/${FLAVOR}Release/app-${FLAVOR}-release.apk"
if [ -f "$APK_FILE" ]; then
    cp "$APK_FILE" "$BUILD_DIR/studytrack-v${VERSION}.apk"
    echo -e "${GREEN}✓ APK built successfully: $BUILD_DIR/studytrack-v${VERSION}.apk${NC}"
else
    echo -e "${RED}Error: APK file not found${NC}"
    exit 1
fi

# Generate release notes template
echo -e "${YELLOW}Generating release notes template...${NC}"
cat > "$BUILD_DIR/RELEASE_NOTES_v${VERSION}.md" << EOF
# StudyTrack v${VERSION}

Release Date: $(date +%Y-%m-%d)

## Features
- [ ] Add feature descriptions here

## Bugs Fixed
- [ ] List bug fixes

## Known Issues
- [ ] List any known issues

## Installation

### Play Store
Visit: https://play.google.com/store/apps/details?id=com.studytrack

### Direct APK Installation
Download: studytrack-v${VERSION}.apk
\`\`\`bash
adb install studytrack-v${VERSION}.apk
\`\`\`

## Changelog
See CHANGELOG.md for detailed change history.
EOF

# Create checksums  
echo -e "${YELLOW}Creating checksums...${NC}"
cd "$BUILD_DIR"
sha256sum studytrack-v${VERSION}.* > checksums.txt
cat checksums.txt

echo ""
echo -e "${GREEN}=== Build Complete ===${NC}"
echo ""
echo "Output files:"
ls -lh "$BUILD_DIR/studytrack-v${VERSION}".*
echo ""
echo "Release artifacts are ready in: $BUILD_DIR"
echo ""
echo "Next steps:"
echo "1. Review RELEASE_NOTES_v${VERSION}.md"
echo "2. Create git tag: git tag -a v${VERSION} -m \"Release v${VERSION}\""
echo "3. Push tag: git push origin v${VERSION}"
echo "4. Upload AAB to Play Store Developer Console"
echo "5. Create GitHub release with artifacts"
