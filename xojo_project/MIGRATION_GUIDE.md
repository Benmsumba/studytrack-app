# StudyTrack → Xojo Migration Guide

## Prerequisites

- Xojo Pro (2023r4 or later recommended)
- Xojo account with active Pro license
- Access to your existing Supabase project credentials

---

## Opening the Project

1. Launch Xojo IDE
2. **File → Open** → navigate to `xojo_project/StudyTrack.xojo_project`
3. Xojo will import all `.xojo_code` files automatically from the same folder

> If Xojo asks about the project format, choose **Desktop Application**.

---

## First-Time Setup

### 1. Add Your Supabase Credentials

Open `App.xojo_code` and replace the placeholder values:

```xojo
Dim supabaseUrl As String = "https://YOUR_PROJECT.supabase.co"
Dim supabaseKey As String = "YOUR_ANON_KEY"
```

For production, store these in a config file or environment variable rather than hard-coding them.

### 2. Design the Window Layouts

The `.xojo_code` files contain **logic only**. You must build the visual layout in the Xojo IDE designer for each window:

| File | Controls needed |
|------|----------------|
| `LoginWindow` | EmailField, PasswordField, SignInButton, SignUpButton, ErrorLabel, BusySpinner, ToggleModeButton |
| `DashboardWindow` | MainPagePanel (4 pages), OfflineBanner, SyncStatusLabel, UserNameLabel, SignOutButton |
| `PomodoroWindow` | TimerLabel, StartPauseButton, StopButton, ModulePopupMenu, DurationSlider, DurationLabel, SessionNotesField |

Each control name in the designer must match exactly what the code references.

---

## Project Structure

```
xojo_project/
├── StudyTrack.xojo_project   ← open this in Xojo IDE
├── App.xojo_code             ← app startup, global service access
│
├── Services/
│   ├── SupabaseService.xojo_code   ← all HTTP calls to Supabase REST/Auth/Storage
│   ├── AuthService.xojo_code       ← sign in / sign up / sign out
│   ├── OfflineSyncService.xojo_code← SQLite queue, flush on reconnect
│   └── GeminiService.xojo_code     ← AI tutor via Supabase Edge Function proxy
│
├── Models/
│   ├── UserModel.xojo_code
│   ├── ModuleModel.xojo_code
│   ├── TopicModel.xojo_code
│   └── StudySessionModel.xojo_code
│
└── Windows/
    ├── LoginWindow.xojo_code
    ├── DashboardWindow.xojo_code
    └── PomodoroWindow.xojo_code
```

---

## Feature Migration Roadmap

Work through these in order — each builds on the previous.

### Phase 1 — Auth & Shell (Week 1)
- [ ] LoginWindow layout + connect SignIn/SignUp logic
- [ ] DashboardWindow layout with PagePanel (4 tabs)
- [ ] App startup flow (token restore → skip login)
- [ ] OfflineBanner and sync status label

### Phase 2 — Modules & Topics (Week 2)
- [ ] Modules list page inside DashboardWindow (Listbox + load from Supabase)
- [ ] Add/edit Module dialog (title, color picker)
- [ ] Topics list window or sub-page
- [ ] Add/edit Topic dialog (title, notes, rating slider 1–10)
- [ ] Soft-delete (set `deleted_at` via PATCH)

### Phase 3 — Study Sessions (Week 3)
- [ ] PomodoroWindow layout and timer logic (already coded)
- [ ] Session history list
- [ ] Daily goal progress bar on Dashboard

### Phase 4 — Timetable & Exams (Week 4)
- [ ] TimetableWindow — weekly grid showing class slots
- [ ] Add/edit class slot dialog
- [ ] Exam countdown list (days remaining per exam)

### Phase 5 — Progress & Analytics (Week 5-6)
- [ ] Study hours per week (bar chart — use Canvas with custom drawing)
- [ ] Streak counter (query `study_sessions` grouped by date)
- [ ] Module completion rings (Canvas arc drawing)

### Phase 6 — AI Tutor (Week 7)
- [ ] AITutorWindow — chat-style UI (Listbox as message list)
- [ ] Wire GeminiService.Chat()
- [ ] Quiz generation (call GenerateText with JSON prompt, parse Q&A)

### Phase 7 — Groups & Chat (Week 8-9)
- [ ] Study groups list + join via invite code
- [ ] Group chat window — poll Supabase every few seconds (no native Realtime in Xojo)

### Phase 8 — Settings & Profile (Week 10)
- [ ] SettingsWindow (theme, daily goal, Pomodoro length)
- [ ] ProfileWindow (name, course, year, stats)
- [ ] Password change

---

## Key Differences from Flutter

| Flutter | Xojo Equivalent |
|---------|----------------|
| `Provider` / `ChangeNotifier` | Instance variables + UI refresh calls (`Listbox.DeleteAllRows` etc.) |
| `GoRouter` navigation | `Window.Show` / `Window.Close` |
| `supabase_flutter` SDK | `SupabaseService` (hand-rolled HTTP) |
| `Supabase Realtime` | Timer-based polling (Xojo has no WebSocket Realtime SDK) |
| `SQLite3` package | Built-in `SQLiteDatabase` class |
| `SharedPreferences` | `Preferences` class (built-in, cross-platform) |
| `flutter_secure_storage` | `Keychain` (macOS/iOS) or encrypt + store in Preferences |
| `fl_chart` | `Canvas` control with custom drawing |
| `flutter_local_notifications` | `Notification` class (macOS/iOS) or `Shell` for desktop |
| Material 3 dynamic color | Xojo's built-in control styles + `Color` class |
| `record` + `audioplayers` | `Sound` class (playback) — recording needs `Declares` or a plugin |
| Dart `Future` / `async` | `Thread` class or timer-driven callbacks |

---

## Supabase REST Quick Reference

All calls go through `SupabaseService`. Common patterns:

```xojo
// Fetch all modules for current user
Dim raw As String = App.Supabase.Get("modules", "select=*&deleted_at=is.null&order=created_at.desc")

// Insert a new module
Dim m As New ModuleModel
m.UserID = App.Auth.CurrentUser.ID
m.Title = "Physics"
m.ColorHex = "#4A90D9"
App.Supabase.Post("modules", m.ToJSON)

// Update a module title
App.Supabase.Patch("modules", "id=eq." + m.ID, "{""title"":""New Title""}")

// Soft-delete
App.Supabase.Patch("modules", "id=eq." + m.ID, "{""deleted_at"":""" + Format(Now,"yyyy-MM-ddTHH:mm:ss") + "Z""}")
```

---

## Limitations to be Aware Of

1. **No Supabase Realtime** — Group chat will need periodic polling (e.g., every 3 s via Timer). This increases server load; consider upgrading to WebSocket Declares if real-time UX is critical.
2. **Audio recording** — Xojo's `Sound` class plays audio but does not record. You need a plugin (e.g., MBS Xojo Plugin) or `Declare` to the OS audio APIs for the voice notes feature.
3. **Push notifications** — Only available on macOS (via Notification class) and iOS. Not available on Windows/Linux desktop.
4. **Android target** — Xojo's Android support is limited. Test early on a real device; avoid complex custom drawing on Canvas as GPU acceleration on Android in Xojo is basic.
5. **PDF generation** — Use the MBS Xojo Plugin (PDFDocumentMBS) or generate HTML and print to PDF via a hidden HTMLViewer.
6. **Charts** — No built-in chart widget. Draw on `Canvas` using `DrawLine`, `FillArc`, `DrawRect`, or use the MBS Chart plugin.

---

## Recommended Plugins (MBS Xojo Plugin — free trial, then ~€99/yr)

| Feature | MBS class |
|---------|-----------|
| PDF generation | `PDFDocumentMBS` |
| AES-256 encryption | `CipherMBS` |
| Audio recording | `CoreAudioMBS` (macOS) |
| Advanced charts | `NSViewMBS` + CorePlot bridge |

MBS is the de-facto standard Xojo plugin library and well worth the cost for a production app.
