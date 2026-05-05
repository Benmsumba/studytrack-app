# Update Button Investigation Summary

## Problem
The StudyTrack app built and deployed successfully, but the in-app update button/notification is not appearing on the user's phone even though the APK and metadata file (`latest.json`) are correctly uploaded to Supabase.

## Root Cause Analysis
The exact reason is unknown without logs, but likely causes include:
1. Network connectivity issue (app can't reach Supabase)
2. URL misconfiguration (SUPABASE_URL env var not set)
3. Version comparison logic not detecting newer version
4. Supabase bucket not public or file not accessible
5. App not calling update check on startup

## Solution: Added Comprehensive Debugging

### Code Changes (Commit 1363b87)
Added enhanced logging to identify the exact failure point:

#### File: `studytrack/lib/features/update/controllers/update_provider.dart`
```dart
// Now logs:
// - Platform check (web vs android)
// - Current app version & buildNumber
// - Update check URL
// - Whether new version detected
// - Error details with stack trace
```

#### File: `studytrack/lib/core/services/app_update_service.dart`
```dart
// Now logs:
// - URL being fetched
// - HTTP response status
// - Raw manifest JSON received
// - Parsed version info
// - Version comparison results
// - Exact reason update rejected
```

#### File: `studytrack/lib/features/settings/screens/settings_screen.dart`
```dart
// New UI section: Settings → "Update Check"
// - Manual "Check" button to trigger update check
// - Displays current update status
// - Shows available version info if detected
```

### How It Helps
1. **Settings Manual Button** → Test update check without restarting app
2. **Debug Logs** → Identify exact step where process fails
3. **Comprehensive Output** → Traces full flow from network request to version comparison

## How to Use

### Step 1: Rebuild APK (with debug logging)
```bash
# Run GitHub Actions workflow:
# Actions → Deploy Release APK → Run workflow
```

### Step 2: Install on Phone
- Download built APK
- Install on your test phone

### Step 3: Manual Update Check
1. Open Settings
2. Scroll to "Update Check" section
3. Tap "Check" button
4. Capture logs

### Step 4: Analyze Output
Compare logs to **expected output** in [UPDATE_DEBUG_QUICK_START.md](UPDATE_DEBUG_QUICK_START.md)

### Step 5: Identify Issue
Location of first failure in log chain tells you the problem:
- **No logs** = App not calling check
- **404 error** = latest.json doesn't exist
- **403 error** = Bucket not public
- **No new version detected** = Version comparison issue
- **Other HTTP error** = Network/configuration issue

## Documentation Files
1. **[UPDATE_DEBUG_QUICK_START.md](UPDATE_DEBUG_QUICK_START.md)** ← Start here for quick diagnosis
2. **[UPDATE_BUTTON_TROUBLESHOOTING.md](UPDATE_BUTTON_TROUBLESHOOTING.md)** ← Detailed troubleshooting guide
3. **This file** ← Summary of changes

## Key Implementation Details

### Version Comparison Logic
Located in `app_update_service.dart` lines 71-73:
```dart
if (info.versionCode <= currentVersionCode) {
  return null;  // No update needed
}
```

### Current Versions
- **App's currentVersionCode** = 1 (from AppConstants)
- **Deployed APK versionCode** = 10000 + GITHUB_RUN_NUMBER
- **Version must satisfy**: `deployed > current` (e.g., 10123 > 1) ✓

### Update Check Trigger
In `main.dart` line 168:
```dart
unawaited(updateProvider.checkForUpdate());
```
Runs on app startup without blocking.

## Next Steps for User

1. **Run GitHub workflow** to build APK with debug logging
2. **Install on phone**
3. **Check Settings → Update Check → tap Check button**
4. **Capture logs** using: `adb logcat | grep "\[Update\]\|\[AppUpdateService\]"`
5. **Compare to expected output** in quick start guide
6. **Identify failure point** and share logs for further diagnosis

## Expected Behavior After Fix

1. App starts → runs `checkForUpdate()` automatically
2. Fetches `latest.json` from Supabase → should get HTTP 200
3. Parses JSON and detects newer version
4. Sets status to `UpdateStatus.available`
5. `UpdateOverlay` widget appears showing:
   - Update icon with gradient background
   - "Update Available" title
   - Version badge (e.g., "Version 1.0.0")
   - Release notes
   - "Update Now" button
   - "Remind me later" link
6. User taps "Update Now" → starts download/install

## Files Modified
- `studytrack/lib/features/update/controllers/update_provider.dart` (enhanced logging)
- `studytrack/lib/core/services/app_update_service.dart` (enhanced logging)
- `studytrack/lib/features/settings/screens/settings_screen.dart` (manual check UI)

## Commits
- **1363b87**: Add comprehensive update check debugging logs and manual Settings UI button
- **7666aa0**: Add comprehensive update button troubleshooting guide
- **150041a**: Add quick start guide for update button debugging

---

**Status**: Ready for next build. All debug infrastructure in place. Waiting for logs from test run to diagnose exact issue.
