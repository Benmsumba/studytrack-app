# Update Button Debug - Quick Start

## TL;DR
✅ Build succeeded and APK deployed  
❌ Update button not showing on phone

## What Was Added
- **Debug Logging**: `[Update]` and `[AppUpdateService]` prefix in logcat
- **Manual Trigger**: Settings screen → "Update Check" section → "Check" button

## 5-Minute Test

### 1. Get Latest APK (with debug logs)
- GitHub Actions: Run "Deploy Release APK" workflow
- Wait for build completion
- Download APK from artifacts

### 2. Install on Phone
- Uninstall old version or allow overwrite
- Install new APK

### 3. Trigger Manual Check
1. Open Settings
2. Scroll down → Find "Update Check" section
3. Tap "Check" button
4. Capture logs: `adb logcat | grep "\[Update\]\|\[AppUpdateService\]"`

### 4. Expected Output

**If working:**
```
[Update] Starting update check...
[Update] Current app: versionCode=1, buildNumber="1"
[AppUpdateService] Fetching update manifest from: https://xidpslwjxnyiptebwdff.supabase.co/storage/v1/object/public/app-updates/latest.json
[AppUpdateService] HTTP response status: 200
[Update] New version found!
[Update] Remote: versionCode=10123, versionName=1.0.0
```

**If not working:**
- No logs → App never calls checkForUpdate()
- HTTP 404 → latest.json doesn't exist
- HTTP 403 → Permission denied (bucket not public)
- No new version detected → Version comparison logic issue

## 🔧 Quick Fixes

| Symptom | Check |
|---------|-------|
| No logs at all | Is app running on Android? Check line 168 in main.dart |
| 404 error | Does `app-updates/latest.json` exist in Supabase? |
| 403 error | Is `app-updates` bucket public? (Settings → Bucket policies) |
| "No update" log | Is deployed versionCode > current? Check workflow build number |
| No overlay shows | Is UpdateOverlay in app.dart? (Line 549) |

## Reference

**Update Check URL:**
```
https://xidpslwjxnyiptebwdff.supabase.co/storage/v1/object/public/app-updates/latest.json
```

**Latest.json Format:**
```json
{
  "versionCode": 10123,           // Must be > current (1)
  "versionName": "1.0.0",         // Display version
  "downloadUrl": "https://...",   // APK download link
  "releaseNotes": "..."           // Change notes
}
```

---
See [UPDATE_BUTTON_TROUBLESHOOTING.md](UPDATE_BUTTON_TROUBLESHOOTING.md) for detailed diagnosis.
