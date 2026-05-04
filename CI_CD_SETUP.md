# CI/CD Configuration Guide

This guide explains how to set up the StudyTrack app for production releases with proper signing and crash reporting.

## Prerequisites

- GitHub repository with Actions enabled
- Android signing keystore (.jks file)
- Firebase/Sentry account for crash reporting
- Play Store Developer account for publishing

## Step 1: Generate or Obtain Android Signing Keystore

### Creating a new keystore:

```bash
keytool -genkey -v -keystore ~/study-track-key.jks \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -alias studytrack
```

### Required information for the keytool:
- **Keystore password**: Use a strong password
- **Key password**: Same as keystore password or different
- **Key alias**: `studytrack` (as defined above)
- **First and last name**: Your name or your organization
- **Organizational unit**: Optional
- **Organization**: Your company name
- **City/Locality**: Your city
- **State/Province**: Your state
- **Country code**: Your country (e.g., US)

## Step 2: Add GitHub Secrets

1. Navigate to your GitHub repository
2. Go to **Settings** → **Secrets and variables** → **Actions**
3. Add the following secrets:

### Android Signing Secrets

- **ANDROID_KEYSTORE_PASSWORD**: The password you set for the keystore
- **ANDROID_KEY_PASSWORD**: The password you set for the key (same as keystore if you used the same password)
- **ANDROID_KEY_ALIAS**: `studytrack` (the alias you set)
- **ANDROID_KEYSTORE_B64**: Base64-encoded keystore file

To encode the keystore file to base64:
```bash
base64 ~/study-track-key.jks | tr -d '\n' | tee /tmp/keystore-base64.txt
# Copy the output to the GitHub secret
```

**Important**: Never commit the keystore file to the repository!

### Crash Reporting Secrets

- **SENTRY_DSN**: Your Sentry project DSN

To get your Sentry DSN:
1. Create a Sentry account at https://sentry.io
2. Create a new project for Flutter/Dart
3. Copy the DSN, it should look like: `https://[key]@[organization].ingest.sentry.io/[project-id]`

## Step 3: Verify Workflow Configuration

The `.github/workflows/build.yml` file is pre-configured to:

1. **Analyze & Lint** all code on every push
2. **Run Unit Tests** on every push
3. **Build APK/AAB** on push to main or tags
4. **Create Release** on version tags
5. **Configure signing** for release builds using secrets

### Workflow Triggers

- **Pull Requests**: Code analysis and tests
- **Push to main**: Full build with signing
- **Push to develop**: Code analysis and tests only
- **Tags (v*)**: Full build + release creation

## Step 4: Setting Up App Store Distribution

### For Play Store Distribution

1. **Create a Service Account**:
   - Go to Google Play Console
   - Settings → API access → Create Service Account
   - Generate a JSON key file

2. **Store the Service Account Key**:
   - Add the key content to GitHub secret as `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`

3. **Manual Upload** (Recommended for first release):
   - Download the APK/AAB from the release artifacts
   - Sign in to Play Console
   - Go to Build → Releases
   - Upload the AAB file
   - Set release notes and rollout percentage
   - Submit for review

### For Internal Testing

The CI/CD pipeline automatically creates releases with:
- APK for direct testing
- AAB for Play Store submission
- SHA256 checksums for verification

## Step 5: Production Release Process

### Create a Release

```bash
git tag v1.0.0
git push origin v1.0.0
```

This will trigger:
1. Full code analysis
2. All unit tests
3. Signed APK generation
4. Signed AAB generation
5. GitHub release creation with artifacts

### Staged Rollout on Play Store

1. Download the AAB from the GitHub release
2. Upload to Play Console
3. Start with 5% staged rollout
4. Monitor crash metrics and user reviews
5. Gradually increase to 100%

## Step 6: Monitoring Crashes

### Sentry Dashboard

1. Log in to your Sentry account
2. Navigate to your StudyTrack project
3. Monitor:
   - Error trends
   - Affected users
   - Release comparison
   - Performance metrics

### Error Handler Integration

The app automatically sends crash reports via:
- `ErrorHandler` service for important errors
- `CrashReporter` for unhandled exceptions
- `Sentry` for all captured errors

## Step 7: Security Best Practices

### Protect Your Signing Keystore

- Never commit keystore files to the repository
- Use GitHub secrets for all sensitive data
- Rotate keystore passwords periodically
- Keep backup copies in a secure location

### Protect Your DSN

- Don't share DSN in public channels
- Rotate DSN if compromised
- Use environment-specific projects (staging vs. production)

### Version Strategy

- Use semantic versioning (MAJOR.MINOR.PATCH)
- Tag releases with v prefix: `v1.0.0`
- Keep version synchronized between code and Play Store

## Troubleshooting

### Build Failures

1. Check GitHub Actions logs
2. Verify all secrets are set correctly
3. Ensure keystore path is correct in Gradle

### Signing Errors

- Verify ANDROID_KEYSTORE_B64 is correctly encoded
- Check that key alias matches configuration
- Ensure passwords don't contain special characters that need escaping

### Play Store Upload Failures

- Verify AAB is properly signed
- Check that version code is incremented
- Ensure app signing certificate matches previous releases

### Sentry Connection Issues

- Verify SENTRY_DSN is correct
- Check internet connectivity
- Review Sentry project settings

## Additional Resources

- [Flutter Deployment Guide](https://docs.flutter.dev/deployment)
- [Sentry Flutter Documentation](https://docs.sentry.io/platforms/dart/)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [Android App Signing Guide](https://developer.android.com/studio/publish/app-signing)
