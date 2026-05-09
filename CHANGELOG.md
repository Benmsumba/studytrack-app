# Changelog

All notable changes to StudyTrack are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versions follow [Semantic Versioning](https://semver.org/).

---

## [Unreleased]

### Changed
- Added Sentry crash reporting bootstrap in `main.dart` with a shared crash reporter fallback
- Switched OTA update manifests to `latest.json` and added APK hash verification before install
- Hardened offline sync queue deduplication and exposed clearer sync status/error messaging
- Added app-wide `ThemeMode` support (`system`/`light`/`dark`) with persisted settings and legacy migration
- Improved settings accessibility semantics and made settings cards adapt to active theme
- Added shared loading, empty, and error state components with shimmer placeholders on major screens
- Extended the shared loading and retry states to exam countdown, weekly wrap, notifications, timetable, module/topic detail, group detail/chat, and AI tutor/quiz screens
- **Security:** Upgraded user ID anonymization from weak truncation to SHA-256 hashing for group members
- **Security:** Encrypted cached query payloads at rest in the offline data store
- **Security:** Encrypted local voice-note recordings before they are stored on disk
- **Reliability:** Added a shared logger for the core service layer and tightened error reporting paths
- **Performance:** Optimized topic cache writes by batching per-module instead of per-item writes
- **Config:** Extracted hardcoded configuration values (cache TTL, rate limits, error history size) to `AppConfig` class
- **UI:** Enhanced home screen and progress screen with glass cards, ambient glows, and improved visual hierarchy
- **Router:** Added missing analytics and voice notes screens to navigation routes
- **Docs:** Updated repository clone commands in CONTRIBUTING.md and README.md

### Planned
- Privacy Policy and Terms of Service pages
- Google Play Store listing and screenshots
- ProGuard rules for `supabase_flutter` and `google_generative_ai`
- Expanded integration tests (auth flow, offline sync)
- Firebase App Distribution for beta testing
- Spotify OAuth integration (currently a stub)
- Certificate pinning for HTTPS connections
- Implement soft-delete pattern for historical data preservation

---

## [1.0.0] — 2024

### Added
- **Auth** — email/password sign-up and login with Supabase Auth; 6-step onboarding flow
- **Modules** — create, edit, and delete course modules with colour labels
- **Topics** — topic management with 1–10 self-assessment rating and automatic spaced-repetition scheduling
- **Topic Rating History** — per-topic progress chart over time
- **Study Sessions** — Pomodoro-style timer with session logging and daily goal tracking
- **Timetable** — weekly class schedule with add/edit/delete class slots
- **Exam Countdown** — upcoming exam tracker with day-by-day countdown
- **Progress Analytics** — study heatmap, streak counter, module completion charts (fl_chart)
- **Weekly Wrapped** — shareable weekly summary card with study hours and highlights
- **AI Tutor** — Gemini 1.5 Flash chat interface for topic explanations, quiz generation, and mnemonics
- **Study Groups** — create or join groups via invite code; role-based membership
- **Group Chat** — real-time messaging within study groups (Supabase Realtime)
- **Topic Chat** — topic-specific discussion threads within groups
- **Notifications** — daily briefing, study reminders, exam countdown alerts, spaced-repetition nudges (5 channels)
- **Voice Notes** — in-app audio recording and playback for lecture notes
- **Uploaded Notes** — PDF/PPT file upload to Supabase Storage with processing status
- **Home Widget** — Android home-screen widget showing daily session summary
- **Achievements** — badge system awarded for streaks, session counts, and module milestones
- **PDF Export** — generate study note PDFs from within the app
- **Offline-First** — SQLite local cache, sync queue, automatic reconnect synchronisation
- **Dark Material 3 theme** — purple/cyan accent palette, Google Fonts (Inter, Outfit)
- **CI/CD** — GitHub Actions workflows for APK build/release and Supabase backend deployment
- **Database** — 14 Supabase PostgreSQL tables with Row Level Security on all user tables

---

[Unreleased]: https://github.com/Benmsumba/studytrack-app/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/Benmsumba/studytrack-app/releases/tag/v1.0.0
