# Update Button Not Appearing - Troubleshooting Guide

## Status
✅ APK successfully built and deployed to Supabase
✅ Metadata file (`latest.json`) uploaded with correct versionCode
❌ Update button/notification not appearing on user's phone

## What I Did to Help

### 1. Enhanced Debug Logging (Commit 1363b87)
Added comprehensive logging to the update check process:

#### In `update_provider.dart` (`checkForUpdate()` method):
- Logs current app's versionCode and buildNumber
- Logs the updateCheckUrl being used
- Logs if update is rejected (and why)
- Logs any errors with full stack trace

#### In `app_update_service.dart` (`checkForUpdate()` method):
- Logs the exact URL being fetched
- Logs HTTP response status code
- Logs the raw JSON manifest received
- Logs parsed version information
- Logs version comparison results

### 2. Added Manual Update Check Button in Settings
**Location**: Settings screen → New "Update Check" section (between Sync and Support)

**Features**:
- Manual "Check" button to trigger update check without restarting app
- Displays current update status
- Shows version information if update is available

## 🔍 How to Diagnose

### Step 1: Get Latest Build with Debug Logging
```bash
# The debug logging is already committed (1363b87)
# The next APK build will include these logs
```

### Step 2: Rebuild and Deploy APK
Run the GitHub Actions workflow to build a new APK:
1. Go to GitHub → StudyTrack Actions
2. Select "Deploy Release APK" workflow
3. Click "Run workflow" → "Run workflow"
4. Wait for completion

### Step 3: Install Updated APK on Phone
1. Download the built APK from GitHub Actions artifacts
2. Uninstall previous version (or allow overwrite during install)
3. Install new APK with debug logging

### Step 4: Check for Update Manually
1. Open StudyTrack app
2. Go to Settings screen
3. Scroll down to "Update Check" section (new)
4. Tap the "Check" button
5. Observe what happens:
   - Should show "Update Status: UpdateStatus.available" if new version detected
   - Should show "Version Available: Code 10... (v1.0.0)"

### Step 5: Capture Logs
**Option A: Use logcat (Android Studio)**
```bash
adb logcat | grep -E "\[Update\]|\[AppUpdateService\]"
```

**Option B: Use Flutter DevTools**
1. Connect device
2. Open DevTools: `flutter pub global run devtools`
3. Go to Logging tab
4. Filter for `[Update]` or `[AppUpdateService]`

**Option C: Check system logs on phone**
1. Open "Developer Options" (tap Build Number 7 times in About)
2. Use system log viewer app

### Step 6: Share Logs
Share the relevant log lines showing:
- Platform check  ✓ Android only
- Current version comparison
- URL being requested
- HTTP response status
- Manifest content
- Version comparison result

## 📋 Expected vs Actual Behavior

### If Working Correctly:
1. App starts → automatically calls `checkForUpdate()` (line 168 in main.dart)
2. `checkForUpdate()` fetches `latest.json` from Supabase
3. Compares: `remoteVersionCode (10000+N) > currentVersionCode (1)` → NEW VERSION!
4. Sets `UpdateStatus.available`
5. `UpdateOverlay()` widget shows on screen with:
   - "Update Available" title
   - Version badge showing new version
   - "Update Now" button
   - Release notes section

### Current Issue:
- UpdateOverlay never appears
- No notification/banner shown to user

## 🔧 Possible Root Causes (in order of likelihood)

### 1. **Network/Connectivity Issue**
- App can't reach Supabase Storage
- Firewall/proxy blocking request
- **Test**: Manual "Check" button should fail silently or show error

### 2. **URL Misconfiguration**
- `AppConstants.updateCheckUrl` is empty or wrong
- `SUPABASE_URL` environment variable not set during build
- **Test**: Check logs for `Check URL: https://YOUR_UPDATE_CHECK_URL` (bad) vs real URL (good)

### 3. **Version Comparison Not Detecting Update**
- Phone's `PackageInfo.buildNumber` != "1"
- Remote `versionCode` in `latest.json` ≤ current version
- **Test**: Logs should show current vs remote: `Current app: versionCode=X ... Remote: versionCode=Y`

### 4. **Supabase Storage Permissions**
- `app-updates` bucket not public
- `latest.json` file not readable
- **Test**: Try accessing file directly in browser: `https://xidpslwjxnyiptebwdff.supabase.co/storage/v1/object/public/app-updates/latest.json`

### 5. **App Never Calls Update Check**
- Exception before line 168
- Android-only check failing (platform != Android)
- **Test**: Logs should show `Starting update check...` immediately

## 🛠️ Immediate Verification Steps

### Verify latest.json Exists and Has Correct Content
```bash
curl https://xidpslwjxnyiptebwdff.supabase.co/storage/v1/object/public/app-updates/latest.json
```

Should return:
```json
{
  "versionCode": 10123,
  "versionName": "1.0.0",
  "downloadUrl": "https://...",
  "..." 
}
```

### Check Phone's Installed Version
1. Settings → About phone → App info → StudyTrack
2. Note the version number and build number
3. This is what's being compared against `latest.json`

### Verify Supabase Bucket Permissions
In Supabase Console:
1. Storage → app-updates bucket
2. Check if bucket is "Public" (toggle should be ON)
3. Check if both `studytrack-latest.apk` and `latest.json` are visible

## 📝 Logs Format Reference

### Prefix Meanings:
- `[Update]` = from `update_provider.dart` / UpdateProvider class
- `[AppUpdateService]` = from `app_update_service.dart` / AppUpdateService class
- `debugPrint()` output visible in Flutter logs and logcat

### Example Good Flow:
```
[Update] Starting update check...
[Update] Current app: versionCode=1, buildNumber="1"
[Update] Check URL: https://xidpslwjxnyiptebwdff.supabase.co/storage/v1/object/public/app-updates/latest.json
[AppUpdateService] Fetching update manifest from: https://...
[AppUpdateService] HTTP response status: 200
[AppUpdateService] Manifest body: {"versionCode": 10123, ...}
[AppUpdateService] Parsed manifest: versionCode=10123, versionName=1.0.0
[AppUpdateService] Update available! versionCode: 10123, downloadUrl: https://...
[Update] New version found!
[Update] Remote: versionCode=10123, versionName=1.0.0
[Update] Download URL: https://...
```

### Example Bad Flow (no network):
```
[Update] Starting update check...
[Update] Current app: versionCode=1, buildNumber="1"
[Update] Check URL: https://...
[AppUpdateService] Fetching update manifest from: https://...
[AppUpdateService] Update check failed: SocketException: Connection refused
[AppUpdateService] Exception type: SocketException
[Update] Update check failed: SocketException: Connection refused
[Update] Stack trace: #0 ...
```

## 🎯 Next Actions

1. **Capture Debug Logs**: Run the manual update check and capture output
2. **Compare with Expected**: Check if logs match "Example Good Flow" above
3. **Identify Failure Point**: Find where the chain breaks
4. **Fix and Retry**: Address the specific issue
5. **Report Findings**: Share logs for further investigation

## 📞 Support

If still stuck after following these steps:
1. Share the debug logs (filtered by `[Update]` and `[AppUpdateService]`)
2. Include: current installed version, phone model, OS version
3. Include: error message from logs

---

**Last Updated**: After commit 1363b87  
**Debug Features Added**: Log statements, Settings UI button  
**Ready to Use**: Yes - the next APK build will have debug output
