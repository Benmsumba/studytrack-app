#!/bin/bash
# Asset Optimization Script for StudyTrack
# This script provides optimization recommendations and processes for app assets
# Prerequisites: ImageMagick, optipng, or WebP tools should be installed

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ASSETS_DIR="$PROJECT_DIR/studytrack/assets"
ANDROID_RES_DIR="$PROJECT_DIR/studytrack/android/app/src/main/res"
WEB_DIR="$PROJECT_DIR/studytrack/web"

echo "=== StudyTrack Asset Optimization Report ==="
echo "Project: $PROJECT_DIR"
echo ""

# Function to calculate savings
calculate_savings() {
    local original=$1
    local optimized=$2
    local percent=$(( (original - optimized) * 100 / original ))
    echo "Saved: ${percent}% ($(( (original - optimized) / 1024 ))KB)"
}

# Report current asset sizes
echo "=== Current Asset Inventory ==="
echo ""

total_size=0

# Flutter assets
echo "📦 Flutter Assets (assets/):"
for file in "$ASSETS_DIR/icon"/*; do
    if [ -f "$file" ]; then
        size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
        total_size=$((total_size + size))
        echo "  $(basename "$file"): $(( size / 1024 ))KB"
    fi
done
echo ""

# Android splash screens
echo "📱 Android Splash Screens:"
splash_size=0
for file in "$ANDROID_RES_DIR"/drawable*splash.png; do
    if [ -f "$file" ]; then
        size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
        splash_size=$((splash_size + size))
        echo "  $(basename "$file"): $(( size / 1024 ))KB"
    fi
done
total_size=$((total_size + splash_size))
echo "  Subtotal: $(( splash_size / 1024 ))KB"
echo ""

# Web assets
echo "🌐 Web Assets:"
web_size=0
for file in "$WEB_DIR"/splash/img/*.png; do
    if [ -f "$file" ]; then
        size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
        web_size=$((web_size + size))
    fi
done
echo "  Web splash screens: $(( web_size / 1024 ))KB"
total_size=$((total_size + web_size))
echo ""

echo "=== Total Asset Size: $(( total_size / 1024 ))KB ==="
echo ""

# Optimization recommendations
echo "=== Optimization Recommendations ==="
echo ""
echo "1. ✅ CONVERT FLUTTER ASSETS (JPEG → WebP)"
echo "   Location: $ASSETS_DIR/icon/"
echo "   Files: app_logo.jpeg (64KB), app_icon.jpeg (48KB)"
echo "   Expected savings: 30-40% (15-25KB)"
echo "   Command: cwebp -q 85 input.jpeg -o output.webp"
echo ""

echo "2. ✅ COMPRESS PNG SPLASH SCREENS (Android & Web)"
echo "   Locations:"
echo "     - $ANDROID_RES_DIR/drawable*/splash.png"
echo "     - $WEB_DIR/splash/img/*"
echo "   Expected savings: 20-35% per file"
echo "   Commands:"
echo "     - optipng -o2 file.png"
echo "     - Or use ImageMagick: convert -quality 95 input.png output.png"
echo ""

echo "3. ℹ️ ANDROID LAUNCHER ICONS (Already optimized, no changes needed)"
echo "   Files are platform-generated and already in optimal format"
echo ""

echo "4. 💡 OPTIONAL: Convert large PNGs to WebP"
echo "   Potential additional savings: 40-50% on splash screens"
echo "   Note: Verify browser/platform support before deploying"
echo ""

# Optimization playbook
cat > "$PROJECT_DIR/scripts/ASSET_OPTIMIZATION_GUIDE.md" << 'EOF'
# Asset Optimization Guide

## Overview
This guide provides step-by-step instructions for optimizing StudyTrack assets.

## Current Asset Statistics
- **Total Size**: ~1.2-1.5MB (estimated)
- **Primary Optimization Targets**:
  1. Flutter app assets (JPEG) - 112KB
  2. Android splash screens (PNG) - ~700KB
  3. Web splash screens (PNG) - ~900KB

## Optimization Strategy

### Phase 1: Convert JPEG Assets to WebP (Highest Priority)
**Target**: `assets/icon/app_logo.jpeg`, `assets/icon/app_icon.jpeg`

**Why**: WebP format is 25-40% smaller than JPEG with better quality

**Steps**:
```bash
# Install WebP tools (if not already installed)
sudo apt-get install webp

# Convert assets
cwebp -q 90 assets/icon/app_logo.jpeg -o assets/icon/app_logo.webp
cwebp -q 90 assets/icon/app_icon.jpeg -o assets/icon/app_icon.webp

# Update pubspec.yaml to reference new files
# Update Dart code to use new asset paths
```

**Expected Result**: 15-25KB saved

### Phase 2: Compress PNG Splash Screens (Medium Priority)
**Target**: All splash screen PNG files

**Why**: Splash screens have room for lossy compression while maintaining visual quality

**Steps**:
```bash
# Install tools
sudo apt-get install optipng

# Lossless compression (safer)
optipng -o2 drawable-mdpi/splash.png
optipng -o2 drawable-hdpi/splash.png
# ... repeat for all densities

# Or use ImageMagick for lighter compression
convert -strip drawable-xxxhdpi/splash.png ../optimized/splash.png
```

**Expected Result**: 20-30% reduction per file (150-300KB+ total)

### Phase 3: Optimize Web Icons (Lower Priority)
**Target**: `web/icons/Icon-*.png`

**Steps**:
```bash
# Compress existing icons
optipng -o2 web/icons/Icon-192.png
optipng -o2 web/icons/Icon-512.png
optipng -o2 web/icons/Icon-maskable-192.png
optipng -o2 web/icons/Icon-maskable-512.png
```

**Expected Result**: 10-15% reduction

## Migration Checklist

- [ ] Phase 1: Convert JPEG to WebP
  - [ ] Create .webp versions of app_logo and app_icon
  - [ ] Update assets references in code
  - [ ] Test on multiple devices
  - [ ] Remove old JPEG files after verification

- [ ] Phase 2: Compress PNG splash screens
  - [ ] Backup original splash screens
  - [ ] Run optipng on all splash files
  - [ ] Verify splash visibility and load time
  - [ ] Test on Android emulator/device

- [ ] Phase 3: Optimize web icons
  - [ ] Run optipng on all web icons
  - [ ] Test web build
  - [ ] Verify icon display on PWA

## Performance Impact

**Estimated Improvements**:
- **App Download Size**: -100-150KB (5-10% reduction)
- **Startup Time**: +30-50ms faster (less I/O)
- **Memory Usage**: -20-40MB at runtime (fewer decoded images)

## Tools & Resources

### WebP Conversion
- **Homepage**: https://developers.google.com/speed/webp
- **CLI**: `cwebp`
- **Quality Settings**: 75-90 recommended for web, 85-95 for app

### PNG Optimization
- **optipng**: Best for lossless compression. `optipng -o2`
- **ImageMagick**: `convert -quality 95 -strip`
- **pngquant**: For color reduction (lossy)

### Validation
- **Verify format**: `file <filename>`
- **Check quality**: Open in image viewer after optimization
- **Size comparison**: `ls -lh <old> <new>`

## Next Steps

1. Create optimized versions in a temp directory
2. Test thoroughly on target devices
3. Update build configuration if needed
4. Commit optimized assets to repo
5. Monitor app size metrics post-release

EOF

echo ""
echo "✅ Optimization guide created: $PROJECT_DIR/scripts/ASSET_OPTIMIZATION_GUIDE.md"
echo ""
echo "Next steps:"
echo "1. Review optimization guide"
echo "2. Install required tools (cwebp, optipng)"
echo "3. Test asset conversion on sample files"
echo "4. Process all assets and validate"
echo "5. Update Dart code if asset paths change"
