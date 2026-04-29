<div align="center">

# StudyTrack

**AI-powered academic productivity — built with Flutter & Supabase**

[![Build APK](https://github.com/Benmsumba/studytrack-app/actions/workflows/build_apk.yml/badge.svg)](https://github.com/Benmsumba/studytrack-app/actions/workflows/build_apk.yml)
[![Backend Deploy](https://github.com/Benmsumba/studytrack-app/actions/workflows/deploy_backend.yml/badge.svg)](https://github.com/Benmsumba/studytrack-app/actions/workflows/deploy_backend.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.29+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-22c55e.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)](https://android.com)

*Track modules · Run study sessions · Get AI tutoring · Collaborate with groups*

</div>

---

## Overview

StudyTrack is a **feature-complete Android productivity app** built for university and college students. It brings together spaced-repetition topic tracking, a Pomodoro-style study timer, AI tutoring powered by Google Gemini, real-time study group collaboration, and detailed academic analytics — all in a single, offline-first mobile experience.

Built with **Flutter 3.29**, **Supabase** (PostgreSQL + Auth + Realtime), and a **Material 3 dark theme**, StudyTrack is designed for daily use on Android 5.0+ devices.

---

## Features

| Category | What it does |
|---|---|
| **Modules & Topics** | CRUD course modules, rate topics 1–10, automatic spaced-repetition scheduling |
| **Study Sessions** | Pomodoro-style timer, session logging, daily goals, streak tracking |
| **Timetable** | Weekly class schedule, exam countdown, study slot planner |
| **AI Tutor** | Gemini-powered chat, quiz generation, mnemonics, topic summaries |
| **Progress Analytics** | Charts, study heatmaps, weekly wrapped reports, shareable cards |
| **Study Groups** | Create/join via invite code, real-time group chat, topic discussion threads |
| **Notifications** | Daily briefing, study reminders, exam alerts, spaced-repetition nudges |
| **Voice Notes** | In-app lecture recording and playback |
| **Offline-First** | SQLite local cache, sync queue, automatic reconnect synchronisation |
| **Home Widget** | Android home-screen widget for a quick session overview |
| **Achievements** | Badge system for streaks, session counts, and milestones |
| **Export** | PDF study summaries and shareable progress cards |

---

## Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter 3.29 · Dart 3.11 |
| **Backend** | Supabase (PostgreSQL, Auth, Realtime, Storage) |
| **AI** | Google Gemini 1.5 Flash (`google_generative_ai`) |
| **State Management** | Provider 6 |
| **Navigation** | GoRouter 17 (deep linking, stateful shell) |
| **Local Storage** | SQLite3 |
| **Charts** | fl_chart 1.2 |
| **Notifications** | flutter_local_notifications 21 |
| **Animations** | flutter_animate · Lottie |
| **Audio** | `record` · `audioplayers` |
| **Offline Sync** | `connectivity_plus` + custom sync queue |
| **CI/CD** | GitHub Actions |

---

## Architecture

```
studytrack/lib/
├── core/
│   ├── constants/       # Theme, colors, typography
│   ├── services/        # Supabase, offline sync, Gemini AI, notifications
│   ├── utils/           # Helpers, validators, snackbar
│   └── widgets/         # Shared UI components
├── features/
│   ├── auth/            # Login, signup, onboarding (6 steps)
│   ├── home/            # Shell, dashboard, timetable
│   ├── modules/         # Course module management
│   ├── timetable/       # Class schedule, study timer, exam countdown
│   ├── progress/        # Analytics, charts, weekly wrapped
│   ├── groups/          # Collaborative groups, real-time chat
│   ├── ai_tutor/        # Gemini chat, quiz generation
│   ├── notifications/   # Notification centre
│   ├── profile/         # User profile, avatar, stats
│   └── voice_notes/     # Recording & playback
├── models/              # 13 typed data models
└── main.dart            # Bootstrap, providers, error handling
```

**Offline-first data flow:**

```
User Action → Provider → SupabaseService
                         ├─ [online]  → Supabase DB → update local cache
                         └─ [offline] → SQLite queue → auto-sync on reconnect
```

---

## Prerequisites

| Requirement | Version |
|---|---|
| Flutter | 3.29+ |
| Dart | 3.11+ |
| Java | 17 (Android builds) |
| Android SDK | API 34, min API 21 |
| Supabase project | Free tier is sufficient |
| Gemini API key | [Google AI Studio](https://aistudio.google.com) (free) |

---

## Quick Start

### 1. Clone and install

```bash
git clone https://github.com/Benmsumba/studytrack-app.git
cd studytrack-app/studytrack
flutter pub get
```

### 2. Configure environment

```bash
cp .env.example .env
# Fill in your values
```

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
GEMINI_API_KEY=your-gemini-api-key
```

> **Never commit `.env`.** It is excluded by `.gitignore`.

### 3. Apply the database schema

Open your Supabase project → **SQL Editor**, then paste and run the contents of [`supabase/schema.sql`](supabase/schema.sql).

### 4. Run

```bash
flutter run --dart-define-from-file=../.env
```

---

## Building a Release APK

### Option A — GitHub Actions (recommended)

1. Add the secrets below to **Settings → Secrets and variables → Actions**:

   | Secret | Description |
   |---|---|
   | `SUPABASE_URL` | Supabase project URL |
   | `SUPABASE_ANON_KEY` | Supabase public anon key |
   | `GEMINI_API_KEY` | Google AI Studio key |
   | `KEYSTORE_BASE64` | Base64-encoded release keystore |
   | `KEY_ALIAS` | Keystore key alias |
   | `KEY_PASSWORD` | Key password |
   | `STORE_PASSWORD` | Keystore store password |

2. Go to **Actions → Build and Release APK → Run workflow**.

3. Download the signed APKs from the workflow artifacts.

### Option B — Local build

```bash
# 1. Generate a release keystore (one-time)
keytool -genkey -v -keystore release-keystore.jks \
  -alias studytrack -keyalg RSA -keysize 2048 -validity 10000

# 2. Create key.properties from the template
cp studytrack/android/key.properties.template studytrack/android/key.properties
# Fill in your keystore path and passwords

# 3. Build split-ABI release APKs
cd studytrack
flutter build apk --release --split-per-abi \
  --dart-define-from-file=../.env

# Signed APKs are output to:
# studytrack/build/app/outputs/flutter-apk/
```

---

## Database Schema

14 PostgreSQL tables with Row Level Security enabled on all user-facing tables:

| Table | Purpose |
|---|---|
| `profiles` | User profile, streaks, avatar |
| `modules` | Course units |
| `topics` | Topics with spaced-repetition ratings |
| `topic_ratings_history` | Rating change log |
| `uploaded_notes` | PDF/PPT file references |
| `note_chunks` | AI-processed content chunks |
| `class_timetable` | Weekly class schedule |
| `study_sessions` | Pomodoro session records |
| `exams` | Exam countdown entries |
| `study_groups` | Collaborative groups with invite codes |
| `group_members` | Membership and roles |
| `group_messages` | Real-time chat messages |
| `badges` | Achievement records |
| `weekly_reports` | Study statistics snapshots |

Full schema: [`supabase/schema.sql`](supabase/schema.sql)

---

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `SUPABASE_URL` | Yes | Supabase project URL |
| `SUPABASE_ANON_KEY` | Yes | Public anon key (safe for client use) |
| `GEMINI_API_KEY` | Yes | Google AI Studio key |

All variables are injected at build time via `--dart-define` and are never stored in source code.

---

## Running Tests

```bash
cd studytrack
flutter analyze          # static analysis
flutter test             # unit and widget tests
```

---

## Roadmap to Play Store

Outstanding work before a public Play Store release:

- [ ] Generate and securely store a release keystore
- [ ] Configure all GitHub Actions secrets (see [Building a Release APK](#building-a-release-apk))
- [ ] Add crash reporting (Firebase Crashlytics or Sentry)
- [ ] Write Privacy Policy and Terms of Service
- [ ] Create a Google Play Console listing with screenshots and store description
- [ ] Add ProGuard rules for `supabase_flutter` and `google_generative_ai`
- [ ] Expand test coverage with auth and sync integration tests
- [ ] Set up Firebase App Distribution for beta testing
- [ ] Complete Spotify OAuth integration (currently a stub)

---

## Contributing

Contributions are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.

1. Fork the repository and create a feature branch.
2. Make your changes and run `flutter analyze && flutter test`.
3. Open a pull request with a clear description of the change and its motivation.

---

## Project Policies

| Document | |
|---|---|
| [CONTRIBUTING.md](CONTRIBUTING.md) | Development workflow and code style |
| [CHANGELOG.md](CHANGELOG.md) | Version history |
| [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) | Community standards |
| [SECURITY.md](SECURITY.md) | Security policy and vulnerability reporting |
| [LICENSE](LICENSE) | MIT License |

---

## License

MIT © [Benmsumba](https://github.com/Benmsumba)
