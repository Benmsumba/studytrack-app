# StudyTrack Deployment Guide

Production-ready deployment procedures for StudyTrack v2026+

## Table of Contents

1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Local Build Process](#local-build-process)
3. [Automated CI/CD Pipeline](#automated-cicd-pipeline)
4. [Play Store Deployment](#play-store-deployment)
5. [Beta Testing & Staged Rollout](#beta-testing--staged-rollout)
6. [Release Monitoring](#release-monitoring)
7. [Rollback Procedures](#rollback-procedures)
8. [Security & Code Signing](#security--code-signing)

---

## Pre-Deployment Checklist

Before any release:

- [ ] All unit tests pass (`flutter test`)
- [ ] Static analysis passes (`flutter analyze`)
- [ ] Code coverage meets minimum threshold (>80%)
- [ ] No compiler warnings in lib/ directory
- [ ] Security audit completed
- [ ] Dependencies audited for vulnerabilities
- [ ] Database migrations rehearsed
- [ ] Crash reporting configured
- [ ] Error monitoring initialized
- [ ] Analytics tracking verified
- [ ] Release notes written
- [ ] Version number bumped in pubspec.yaml
- [ ] Changelog updated

### Quick Check Script

```bash
#!/bin/bash
cd studytrack

echo "📋 Running pre-deployment checks..."
flutter analyze lib/ && echo "✓ Analysis passed"
flutter test && echo "✓ Tests passed"
echo "✓ Pre-deployment checklist complete"
```

---

## Local Build Process

### Prerequisites

```bash
flutter --version  # Should be 3.22.0 or higher
java -version      # Should be 17 or higher
```

### Generate Signed APK/AAB

1. **Ensure key store exists:**

```bash
cd studytrack/android/app
keytool -list -v -keystore release-key.jks
```

2. **Build release APK:**

```bash
cd studytrack
flutter build apk --release
```

3. **Build Play Store AAB:**

```bash
cd studytrack
flutter build appbundle --release
```

Output locations:
- APK: `build/app/outputs/apk/release/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

### Automated Release Script

```bash
./scripts/build_release.sh 1.0.0 production
```

This will:
- Run all checks (analysis, tests)
- Build APK and AAB
- Generate release notes template
- Create checksums
- Organize artifacts

---

## Automated CI/CD Pipeline

The `.github/workflows/build.yml` pipeline automatically:

1. **Analyzes** code on every push/PR
2. **Tests** code with coverage reporting
3. **Builds** APK/AAB on main/tag pushes
4. **Creates releases** on version tags

### Triggering a Release

```bash
# Create release tag
git tag -a v1.0.0 -m "Release version 1.0.0"

# Push tag to trigger CI/CD
git push origin v1.0.0
```

GitHub Actions will automatically:
- Build APK and AAB
- Create GitHub Release
- Upload artifacts with checksums

---

## Play Store Deployment

### Initial Setup

1. **Developer Account:** https://play.google.com/console
2. **Create Application:** Set up new app entry
3. **Target Audience:** Configure in Play Console
4. **Rating Questionnaire:** Complete contentrating questionnaire
5. **Privacy Policy:** Upload to website
6. **Store Listing:** Complete with screenshots, description

### Upload to Play Store

1. **Via Play Console WebUI:**
   - Go to "Release" → "Production"
   - Upload AAB file
   - Review release notes
   - Submit for review

2. **Via Command Line (require fastlane setup):**

```bash
# Install fastlane
gem install fastlane

# Initialize fastlane
cd studytrack && fastlane init

# Upload to Play Store
fastlane supply --aab build/app/outputs/bundle/release/app-release.aab
```

### Review & Approval

- Play Store review typically takes 24-48 hours
- Review status available in Play Console
- Common rejection reasons:
  - Crashes on device
  - Privacy policy issues
  - Permissions not justified
  - Malware detection

---

## Beta Testing & Staged Rollout

### Google Play Beta Track

1. **Create Beta Release:**
   - Upload AAB to "Internal testing" track first
   - Test with internal team (QA)
   - Move to "Closed beta" for wider testing
   - Gather feedback for 1-2 weeks

2. **Configure Beta Testers:**
   - Create testing group in Play Console
   - Provide opt-in link to testers
   - Monitor crash reports and reviews

3. **Staged Rollout:**

```
Week 1: 10% of users
Week 2: 50% of users
Week 3: 100% rollout
```

Configure in Play Console:
- Release → Production → Manage release
- Set % of users to receive update
- Monitor crash rate and ratings

### Monitor Beta Metrics

- Crash rate (should stay < 0.5%)
- ANR (Application Not Responding) rate
- Release-to-install time
- User ratings and feedback

---

## Release Monitoring

### After Release Goes Live

1. **Monitor Crash Reports:**

```bash
# View recent crashes
flutter pub global run crash_reporter_cli view
```

2. **Check Metrics Dashboard:**
   - Error rate
   - User session duration
   - Feature usage patterns
   - Geographic distribution

3. **Monitor Performance:**
   ```
   - Startup time
   - Memory usage
   - Battery drain
   - Network efficiency
   ```

4. **Review in Play Console:**
   - Crash/ANR rates
   - User ratings
   - Review sentiment
   - Version adoption

### Alerts & Escalation

Set up alerts for:
- Crash rate > 1%
- ANR rate > 0.5%
- Rating drop below 4.0 stars
- 404 API downtime

---

## Rollback Procedures

### If Critical Issue Detected

**Immediate Actions:**

1. **Halt rollout** (if staged):
   ```
   Play Console → Release → Manage → Pause
   ```

2. **Investigate root cause:**
   - Check error logs
   - Review recent changes
   - Verify database migrations

3. **Decide rollback path:**

   **Option A: Roll back to previous version**
   ```bash
   git revert v1.0.0 -m 1
   ```

   **Option B: Hotfix and redeploy**
   ```bash
   # Create hotfix branch
   git checkout -b hotfix/critical-bug
   # Apply fixes
   # Test thoroughly
   # Create new tag v1.0.1
   ```

4. **Communicate:**
   - Notify users in app (if safe)
   - Post status on social media
   - Update support docs

### Database Rollback

If database migration caused issues:

```sql
-- Connect to production database
-- Run rollback migration (backup FIRST!)
-- Verify data integrity
```

---

## Security & Code Signing

### Code Signing Configuration

```bash
cd studytrack/android

# Key store location
KEY_STORE_PATH=~/studytrack-release.jks
KEY_ALIAS=studytrack-key
KEY_STORE_PASSWORD=*** (from secure storage)
KEY_PASSWORD=*** (from secure storage)
```

### Signing Configuration (gradle.properties)

```gradle
android.useNewApkSigningScheme=true
android.enableDynamicFeature=true

# Signing config
RELEASE_KEY_STORE_PATH=${KEY_STORE_PATH}
RELEASE_KEY_STORE_PASSWORD=${KEY_STORE_PASSWORD}
RELEASE_KEY_ALIAS=${KEY_ALIAS}
RELEASE_KEY_PASSWORD=${KEY_PASSWORD}
```

### ProGuard/R8 Obfuscation

Located in `android/app/build.gradle`:

```gradle
buildTypes {
  release {
    minifyEnabled true
    shrinkResources true
    proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
  }
}
```

Sensitive rules in `android/app/proguard-rules.pro`:
- Keep crash reporter code readable
- Keep database schema intact
- Keep API method signatures

### Secret Management

**Store in GitHub Secrets (for CI/CD):**
- `RELEASE_KEYSTORE_B64` - Base64-encoded keystore
- `RELEASE_KEYSTORE_PASSWORD` - Keystore password
- `RELEASE_KEY_PASSWORD` - Key password
- `RELEASE_KEY_ALIAS` - Key alias

**Access in workflow:**

```yaml
- name: Prepare signing key
  run: |
    echo "${{ secrets.RELEASE_KEYSTORE_B64 }}" | base64 --decode > $RUNNER_TEMP/release.jks
    echo "RELEASE_KEY_STORE_PATH=$RUNNER_TEMP/release.jks" >> $GITHUB_ENV
    echo "RELEASE_KEY_STORE_PASSWORD=${{ secrets.RELEASE_KEYSTORE_PASSWORD }}" >> $GITHUB_ENV
    echo "RELEASE_KEY_PASSWORD=${{ secrets.RELEASE_KEY_PASSWORD }}" >> $GITHUB_ENV
    echo "RELEASE_KEY_ALIAS=${{ secrets.RELEASE_KEY_ALIAS }}" >> $GITHUB_ENV
```

---

## Troubleshooting

### Common Build Issues

| Issue | Solution |
|-------|----------|
| "Certificate not valid" | Regenerate signing key |
| "APK too large" | Check for unused assets; enable ProGuard |
| "Gradle build failed" | Run `flutter clean` and rebuild |
| "Play Store upload fails" | Verify AAB signature; check version code |

### Version Management

- Version format: `MAJOR.MINOR.PATCH` (e.g., 1.2.3)
- Build number: Auto-incremented (Android: versionCode)
- Play Store release: Use semantic versioning
- Release branch naming: `release/v1.2.3`

---

## References

- [Flutter Documentation](https://flutter.dev/docs)
- [Android App Bundle](https://developer.android.com/guide/app-bundle)
- [Google Play Deployment](https://developer.android.com/studio/publish)
- [Store Listing Checklist](https://developer.android.com/distribute/play/launch/launch-checklist)

---

**Last Updated:** 2026-05-04
**Document Version:** 1.0.0
