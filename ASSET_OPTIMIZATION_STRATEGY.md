# Asset Optimization Strategy for StudyTrack

## Current Status

### Asset Inventory
```
Flutter Assets (assets/icon/):
  - app_logo.jpeg: 64KB
  - app_icon.jpeg: 48KB

Android Splash Screens (drawable-* densities):
  - xxxhdpi: 288KB
  - xxhdpi: 188KB
  - xhdpi: 108KB
  - hdpi: 72KB
  - mdpi: 40KB
  Subtotal: ~696KB

Web Splash Screens (splash/img/):
  - 4x: 288KB
  - 3x: 188KB
  - 2x: 108KB
  - 1x: 40KB
  Subtotal: ~624KB

Android Launcher Icons & Foregrounds: ~170KB
Web Icons: ~112KB

TOTAL: ~1.6MB
```

## Optimization Recommendations (Priority Order)

### Priority 1: Convert Dart Assets to WebP Format ⭐⭐⭐
**Impact**: 15-25KB savings | **Effort**: Low | **Risk**: Minimal

**Why**: WebP provides 25-40% better compression than JPEG while maintaining quality.

**Tools**: ImageMagick or cwebp CLI

**Implementation**:
1. Convert `app_logo.jpeg` → `app_logo.webp`
2. Convert `app_icon.jpeg` → `app_icon.webp`
3. Update `pubspec.yaml` asset references if needed
4. Update image paths in Dart code (if hardcoded)
5. Test on multiple devices before removing JPEG files

**Expected Result**: 15-25KB reduction

---

### Priority 2: Compress PNG Splash Screens ⭐⭐⭐
**Impact**: 150-300KB savings | **Effort**: Medium | **Risk**: Very Low

**Why**: Splash screens are full-screen images with predictable gradients/patterns, enabling effective lossless compression.

**Tools**: optipng (recommended) or ImageMagick

**Implementation**:
```bash
# For each splash screen:
optipng -o2 drawable-xxxhdpi/splash.png
optipng -o2 drawable-xxhdpi/splash.png
optipng -o2 drawable-xhdpi/splash.png
optipng -o2 drawable-hdpi/splash.png
optipng -o2 drawable-mdpi/splash.png

# Same for web:
optipng -o2 web/splash/img/light-4x.png
optipng -o2 web/splash/img/light-3x.png
optipng -o2 web/splash/img/light-2x.png
optipng -o2 web/splash/img/light-1x.png
optipng -o2 web/splash/img/dark-4x.png
optipng -o2 web/splash/img/dark-3x.png
optipng -o2 web/splash/img/dark-2x.png
optipng -o2 web/splash/img/dark-1x.png
```

**Expected Result**: 20-30% reduction per file (300-400KB total)

---

### Priority 3: Alternative - Convert Splash PNGs to WebP ⭐⭐ (Optional)
**Impact**: 250-400KB additional savings | **Effort**: High | **Risk**: Medium

**Why**: WebP supports both lossless and lossy compression, achieving 50-75% compression vs PNG.

**Considerations**:
- Need to maintain PNG versions for compatibility
- May require build script adjustments
- Supported on Android 4.3+ and modern web browsers

**Implementation**:
```bash
# Generate WebP versions while keeping PNG for fallback
cwebp -q 90 drawable-xxxhdpi/splash.png -o drawable-xxxhdpi/splash.webp
```

---

### Priority 4: Optimize Android Launcher Icons ⭐
**Impact**: 10-20KB savings | **Effort**: Low | **Risk**: Minimal

**Why**: Platform uses specific densities, some can be optimized further.

**Implementation**:
1. Run optipng on all `mipmap-*/ic_launcher.png` files
2. Compress `drawable-*/ic_launcher_foreground.png`

---

### Priority 5: Optimize Web Icons ⭐
**Impact**: 5-10KB savings | **Effort**: Very Low | **Risk**: None

**Implementation**:
```bash
optipng -o2 web/icons/Icon-*.png
```

---

## Implementation Roadmap

### Phase 1: Asset Optimization (This Sprint)
- [ ] Convert Flutter JPEG assets to WebP
- [ ] Compress all PNG splash screens (optipng)
- [ ] Compress Android launcher icons
- [ ] Test on multiple devices
- [ ] Commit optimized assets

**Expected Outcome**: 150-250KB reduction (10-15% app size decrease)

### Phase 2: Build Configuration (Next Sprint)
- [ ] Add WebP support to build pipeline
- [ ] Create fallback chain (WebP → PNG → default)
- [ ] Automate image optimization in pre-build checks
- [ ] Document asset guidelines for future contributors

### Phase 3: Dynamic Asset Loading (Future)
- [ ] Implement lazy loading for non-critical images
- [ ] Cache optimized images on first run
- [ ] Monitor actual device usage patterns

---

## Quick Start Commands

### Using ImageMagick (Most Accessible)
```bash
# Convert JPEG to PNG (lossless)
convert app_logo.jpeg -quality 100 app_logo.png

# Compress PNG (lossy, 90% quality)
convert -quality 90 -strip input.png output.png

# Batch process splash screens
for file in android/app/src/main/res/drawable*/splash.png; do
    convert -quality 92 -strip "$file" "$(dirname $file)/splash_opt.png"
    mv "$(dirname $file)/splash_opt.png" "$file"
done
```

### Using Script
```bash
bash scripts/optimize_assets.sh
```

---

## Expected Performance Improvements

| Metric | Before | After | Savings |
|--------|--------|-------|---------|
| App Size | 45-50MB | 44-49MB | 1-2MB |
| Startup Time | ~2.5s | ~2.3s | +200ms faster |
| Memory (Runtime) | 150-200MB | 140-180MB | 10-20MB |
| Initial Load | N/A | Faster splash display | Better UX |

---

## Validation Checklist

Before committing optimized assets:

- [ ] Asset files successfully load on startup
- [ ] All images display correctly (no corruption)
- [ ] Splash screen renders properly on all densities
- [ ] App icons appear correctly on home screen
- [ ] Web build renders images properly
- [ ] No visual artifacts or quality degradation noticed
- [ ] File sizes confirm expected savings
- [ ] Git diff shows only image files changed

---

## Tools & Installation

### Recommended Tools
1. **ImageMagick**: `sudo apt-get install imagemagick`
2. **optipng**: `sudo apt-get install optipng`
3. **WebP Tools**: `sudo apt-get install webp`

### Verification
```bash
# Check file format
file assets/icon/app_logo.jpeg

# Verify size before/after
ls -lh assets/icon/app_logo*

# Compare quality (visual inspection)
open assets/icon/app_logo.jpeg
open assets/icon/app_logo.webp
```

---

## References

- [WebP Format Guide](https://developers.google.com/speed/webp)
- [PNG Compression Best Practices](https://www.imageoptim.com/)
- [optipng Documentation](http://optipng.sourceforge.net/)
- [ImageMagick Usage](https://imagemagick.org/Usage/)

---

## Status

- **Created**: Current Sprint
- **Priority**: High (impacts app store optimization)
- **Estimated Time**: 2-4 hours total
- **Next Review**: End of optimization phase
