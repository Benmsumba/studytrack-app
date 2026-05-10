<div align="center">

<img src="studytrack/assets/icon/app_logo.jpeg" alt="StudyTrack" width="128" height="128" style="border-radius: 24px;" />

# StudyTrack

**The all-in-one study companion for serious students.**
Plan, track, learn, and connect — fully offline-capable, AI-augmented, and built for Android.

[![Flutter](https://img.shields.io/badge/Flutter-3.29+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Android](https://img.shields.io/badge/Android-21%2B-3DDC84?logo=android&logoColor=white)](https://www.android.com)
[![Supabase](https://img.shields.io/badge/Supabase-3FCF8E?logo=supabase&logoColor=white)](https://supabase.com)
[![Material 3](https://img.shields.io/badge/Material%203-757575?logo=materialdesign&logoColor=white)](https://m3.material.io)
[![License: MIT](https://img.shields.io/badge/License-MIT-22c55e.svg)](LICENSE)

[![CI](https://github.com/Benmsumba/studytrack-app/actions/workflows/build.yml/badge.svg)](https://github.com/Benmsumba/studytrack-app/actions/workflows/build.yml)
[![Release APK Builder](https://github.com/Benmsumba/studytrack-app/actions/workflows/deploy_release.yml/badge.svg)](https://github.com/Benmsumba/studytrack-app/actions/workflows/deploy_release.yml)
[![Backend Deploy](https://github.com/Benmsumba/studytrack-app/actions/workflows/deploy_backend.yml/badge.svg)](https://github.com/Benmsumba/studytrack-app/actions/workflows/deploy_backend.yml)
[![Latest Release](https://img.shields.io/github/v/release/Benmsumba/studytrack-app?include_prereleases&label=release)](https://github.com/Benmsumba/studytrack-app/releases)

</div>

---

## Overview

StudyTrack is a production-grade Android app that brings every part of a student's workflow into a single, focused experience. It pairs a clean Material 3 interface with a robust offline-first architecture, an embedded AI tutor, and real-time study groups — all built on Flutter and Supabase.

The app is engineered around four principles:

1. **Offline-first.** Every screen works without a network. Mutations are queued locally and synchronised transparently when connectivity returns.
2. **Privacy by design.** Sensitive data (voice recordings, cached query payloads) is encrypted at rest. The Supabase service-role key never ships to clients.
3. **Resilient by default.** Crash reporting, error boundaries, certificate pinning, and a full update channel ship out of the box.
4. **Pleasant to use.** Smooth animations, dynamic colour, dark-mode-first design, and a glass-morphic visual language built specifically for focus.

<div align="center">

> _Screenshots and architecture diagrams will land here as the v1.1.0 release ships._
>
> _`docs/screenshots/home.png` · `docs/screenshots/modules.png` · `docs/screenshots/ai-tutor.png`_

</div>

---

## Features

A complete tour of what's inside the app — every screen wired, every button connected.

### Core productivity

| Module | What it does |
|---|---|
| **Onboarding** | 6-step guided setup capturing course, year, daily study target, and study preference |
| **Dashboard** | Today's plan, active streak, daily goal progress, quick actions, and motivational nudges |
| **Modules** | Create, edit, archive course modules with colour labels and progress rings |
| **Topics** | Per-module topic tracking with 1–10 self-rating and automatic spaced-repetition scheduling |
| **Topic Detail** | Rating history charts, AI tutor entry point, quiz launcher, attached notes |
| **Timetable** | Weekly class scheduler with add/edit/delete slots |
| **Study Session** | Pomodoro-style timer with goal binding, session rating, and badge celebrations |
| **Exam Countdown** | Day-by-day countdown for upcoming exams with one-tap "Start Prep" |

### Insights & growth

| Module | What it does |
|---|---|
| **Progress** | Heatmaps, streak counter, study-hours-per-week, and module completion charts |
| **Analytics** | Trend reports, weekly comparisons, peak focus windows |
| **Weekly Wrapped** | Shareable weekly summary card — Spotify-style highlight reel |
| **Achievements** | Badges for streaks, session counts, milestones, and consistency |

### AI & content

| Module | What it does |
|---|---|
| **AI Tutor** | Gemini-powered chat: explain topics, generate mnemonics, summarise notes |
| **Quiz** | Auto-generated topic quizzes with instant grading |
| **Voice Notes** | Encrypted local audio capture and on-demand decrypted playback |
| **Uploaded Notes** | PDF/PPT upload to Supabase Storage with processing status tracking |
| **PDF Export** | Generate study-note PDFs from any topic |

### Social & collaboration

| Module | What it does |
|---|---|
| **Groups** | Create or join study groups via invite code |
| **Group Chat** | Real-time messaging powered by Supabase Realtime |
| **Topic Chat** | Per-topic discussion threads inside groups |

### System & user

| Module | What it does |
|---|---|
| **Notifications** | Daily briefings, study reminders, exam alerts, spaced-repetition nudges (5 channels) |
| **Profile** | Edit name, course, year, study preference; view stats |
| **Settings** | Theme, daily goal, Pomodoro length, password change, data export, legal links |
| **Privacy & Terms** | In-app Privacy Policy and Terms of Service screens |
| **Update Overlay** | OTA update prompt driven by `latest.json` with SHA-256 verification |
| **Offline Banner** | Animated connectivity / sync status indicator |

---

## Tech Stack

| Layer | Technology |
|---|---|
| **Mobile framework** | Flutter 3.29 · Dart 3.11 |
| **Design system** | Material 3 · Dynamic Color · custom glass components |
| **State management** | `provider` |
| **Routing** | `go_router` (StatefulShellRoute, redirect guards, navigator observers) |
| **Backend** | Supabase (PostgreSQL · Auth · Realtime · Storage · Edge Functions) |
| **AI** | Google Gemini via `google_generative_ai` (proxied through a Supabase Edge Function) |
| **Local data** | `sqlite3` · `shared_preferences` · `flutter_secure_storage` |
| **Offline sync** | Custom queue with deduplication, retry, and reconnect handling |
| **Charts** | `fl_chart` · `percent_indicator` |
| **Notifications** | `flutter_local_notifications` (5 channels) |
| **Crash reporting** | Sentry (`sentry_flutter`) — also used as analytics breadcrumb sink |
| **Audio** | `record` (capture) · `audioplayers` (playback) — encrypted at rest |
| **PDF / files** | `pdf` · `file_picker` · `share_plus` · `open_file` |
| **CI/CD** | GitHub Actions · Dependabot · Dependency Review |
| **Build tooling** | Gradle (Kotlin DSL) · ProGuard/R8 · `--obfuscate --split-debug-info` |

---

## Architecture

```
studytrack/lib/
├── core/
│   ├── constants/        App-wide constants and config
│   ├── services/         Analytics, crash reporter, notifications, offline sync, update, Spotify
│   ├── theme/            Material 3 theme + dark/light schemes
│   ├── utils/            Logger, service locator, helpers
│   └── widgets/          AppErrorBoundary, OfflineStatusBanner, shared UI primitives
├── features/
│   ├── ai_tutor/         Tutor chat + quiz screens
│   ├── auth/             Login, signup, OTP, splash, AuthProvider
│   ├── groups/           Groups list, detail, chat, topic chat
│   ├── home/             Dashboard, MainShell with bottom nav
│   ├── legal/            Privacy Policy, Terms of Service
│   ├── modules/          Modules list, module detail, topic detail
│   ├── notifications/    Notification list, NotificationProvider
│   ├── onboarding/       6-step onboarding flow
│   ├── profile/          Profile screen with editable bottom sheet
│   ├── progress/         Progress, Analytics, Exam Countdown, Weekly Wrapped
│   ├── settings/         Settings + persisted SettingsProvider
│   ├── timetable/        Timetable, Study Session, providers
│   ├── update/           OTA update overlay + UpdateProvider
│   └── voice_notes/      Recording + encrypted playback
├── models/               Typed data models
├── app.dart              Router setup, theme wiring, error boundary
└── main.dart             Bootstrap: Sentry init → Supabase init → service locator → providers
```

> _A full architecture diagram lives at `docs/architecture.png` (placeholder for v1.1.0)._

---

## Getting Started

### Prerequisites

- **Flutter** 3.29+ ([install](https://flutter.dev/docs/get-started/install))
- **Dart** 3.11+
- **JDK 17** for Android builds
- **Android SDK** with API 35 platform
- A **Supabase** project ([create one](https://supabase.com/dashboard))
- A **Google Gemini** API key ([Google AI Studio](https://aistudio.google.com))

### 1. Clone the repository

```bash
git clone https://github.com/Benmsumba/studytrack-app.git
cd studytrack-app/studytrack
```

### 2. Configure environment

Copy the template and fill in your own values:

```bash
cp ../.env.example ../.env
```

Required variables (see [`.env.example`](.env.example)):

| Variable | Description |
|---|---|
| `SUPABASE_URL` | Your Supabase project URL |
| `SUPABASE_ANON_KEY` | Public anon key (safe to ship) |
| `GEMINI_API_KEY` | Google AI Studio key |
| `SENTRY_DSN` | _Optional_ — enables crash reporting |
| `SPOTIFY_CLIENT_ID` | _Optional_ — enables Spotify integration |

> ⚠️ Never commit `.env`. Only `.env.example` is tracked.

### 3. Install dependencies

```bash
flutter pub get
```

### 4. Apply the database schema

Run [`supabase/schema.sql`](supabase/schema.sql) against your project from the Supabase SQL editor, or follow [`SUPABASE_SETUP.md`](SUPABASE_SETUP.md) for the full setup including Edge Functions.

### 5. Run the app

```bash
flutter run --dart-define-from-file=../.env
```

---

## Testing

```bash
cd studytrack
flutter analyze
flutter test
```

CI runs the same commands plus a formatting check on every PR. See [`.github/workflows/build.yml`](.github/workflows/build.yml).

---

## Build & Release

The project ships with a hardened release build script:

```bash
./scripts/build_release.sh --apk             # Sign + obfuscate + tree-shake
./scripts/build_release.sh --aab             # Play Store bundle
./scripts/build_release.sh --apk --skip-tests
```

The script validates `.env`, verifies the keystore, runs `flutter analyze` and `flutter test`, builds with `--obfuscate --split-debug-info`, and produces SHA-256 checksums.

For full release procedure, signing setup, and Play Store submission, see [`DEPLOYMENT_GUIDE.md`](DEPLOYMENT_GUIDE.md).

The repository's GitHub Actions automate:

- **CI** — analyze + test on every push and PR (`build.yml`)
- **Release APK Builder** — builds signed release APK, uploads to Supabase Storage, publishes `latest.json` (`deploy_release.yml`)
- **Manual Debug APK Build** — on-demand debug builds (`build_apk.yml`)
- **Backend Deploy** — pushes schema migrations and Edge Functions on `supabase/**` changes (`deploy_backend.yml`)
- **OTA Metadata** — manual publish of `latest.json` for in-app update prompts (`trigger_update.yml`)
- **Dependency Review** — flags vulnerable dependencies on every PR
- **Dependabot** — monthly updates for Pub, Gradle, and GitHub Actions

---

## Security

StudyTrack treats security as a release blocker, not a feature. Please review [`SECURITY.md`](SECURITY.md) before contributing — it covers:

- The vulnerability disclosure process
- Sensitive files and what's gitignored
- Emergency secret rotation runbook
- Best practices for contributors (RLS, `--dart-define`, certificate pinning, etc.)

For vulnerabilities, open a [GitHub Security Advisory](https://github.com/Benmsumba/studytrack-app/security/advisories/new) — **never** a public issue.

---

## Documentation

| Document | Purpose |
|---|---|
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | How to contribute, branch model, commit style |
| [`SECURITY.md`](SECURITY.md) | Disclosure policy, secret rotation runbook |
| [`DEPLOYMENT_GUIDE.md`](DEPLOYMENT_GUIDE.md) | Release procedure, signing, Play Store submission |
| [`SUPABASE_SETUP.md`](SUPABASE_SETUP.md) | Database schema, Edge Functions, RLS setup |
| [`CHANGELOG.md`](CHANGELOG.md) | Version history (Keep a Changelog format) |

---

## Contributing

Contributions are welcome. Read [`CONTRIBUTING.md`](CONTRIBUTING.md) first. Every PR must pass `flutter analyze` and `flutter test`, follow Conventional Commits, and stay scoped to a single concern.

---

## License

Released under the [MIT License](LICENSE). © 2026 Benmsumba.

---

## Author

**Benmsumba** — [@Benmsumba](https://github.com/Benmsumba)

Built with care for students who want a single place to plan, study, and grow.
