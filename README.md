<div align="center">

# StudyTrack

Student productivity app built with Flutter, Supabase, and a clean offline-first architecture.

[![Flutter](https://img.shields.io/badge/Flutter-3.29+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-22c55e.svg)](LICENSE)
[![Latest Release](https://img.shields.io/github/v/release/Benmsumba/studytrack-app?include_prereleases&label=release)](https://github.com/Benmsumba/studytrack-app/releases)
[![Build & Test](https://github.com/Benmsumba/studytrack-app/actions/workflows/build.yml/badge.svg)](https://github.com/Benmsumba/studytrack-app/actions/workflows/build.yml)
[![Backend Deploy](https://github.com/Benmsumba/studytrack-app/actions/workflows/deploy_backend.yml/badge.svg)](https://github.com/Benmsumba/studytrack-app/actions/workflows/deploy_backend.yml)

</div>

StudyTrack is an offline-first student productivity app for tracking modules, study sessions, exams, groups, notes, and AI-assisted revision from one mobile experience.

## What It Does

StudyTrack combines spaced-repetition topic tracking, a Pomodoro-style study timer, AI tutoring, weekly analytics, real-time study groups, voice notes, and offline sync. The app is built for Android, uses Supabase for backend services, and keeps the codebase organized around feature modules and shared UI components.

## Key Capabilities

| Area | Highlights |
|---|---|
| Modules & topics | Course tracking, ratings, and spaced-repetition scheduling |
| Study sessions | Pomodoro timer, goals, streaks, and session history |
| Timetable | Weekly classes, exam countdowns, and study slots |
| AI tutor | Gemini-powered chat, quizzes, summaries, and mnemonics |
| Progress | Reports, charts, and weekly study insights |
| Groups | Invite-based groups, chat, and collaborative discussion |
| Offline support | Local caching, queued sync, and reconnect handling |
| Notifications | Study reminders, exam alerts, and daily briefings |

## Recent Release Notes

The current branch includes security, performance, and polish updates that are also reflected in the changelog:

- encrypted query-cache payloads at rest
- encrypted local voice-note recordings with on-demand decryption
- shared logger usage in the core service layer
- topic cache batching and centralized config values
- refreshed repository-facing docs and templates

## Tech Stack

| Layer | Stack |
|---|---|
| Frontend | Flutter 3.29, Dart 3.11 |
| Backend | Supabase (PostgreSQL, Auth, Realtime, Storage) |
| State management | Provider |
| Navigation | GoRouter |
| Local data | SQLite |
| Charts | fl_chart |
| Notifications | flutter_local_notifications |
| CI/CD | GitHub Actions |

## Project Structure

```
studytrack/lib/
├── core/        # constants, services, utils, widgets
├── features/    # auth, home, modules, timetable, progress, groups, ai_tutor, profile
├── models/      # typed data models
└── main.dart    # app bootstrap
```

## Getting Started

### Prerequisites

- Flutter 3.29+
- Dart 3.11+
- Java 17 for Android builds
- A Supabase project
- A Gemini API key from Google AI Studio

### Install

```bash
git clone https://github.com/Benmsumba/studytrack-app
cd studytrack-app/studytrack
flutter pub get
```

### Configure Environment

Create your local environment file and add the required values:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
GEMINI_API_KEY=your-gemini-api-key
```

Do not commit secrets. The repository already ignores local environment files.

### Set Up Supabase

Run the schema in [`supabase/schema.sql`](supabase/schema.sql) from the Supabase SQL editor, or follow the steps in [`SUPABASE_SETUP.md`](SUPABASE_SETUP.md).

### Run the App

```bash
flutter run --dart-define-from-file=../.env
```

## Build And Release

For release and deployment details, see [`DEPLOYMENT_GUIDE.md`](DEPLOYMENT_GUIDE.md).

The repository includes GitHub Actions for:

- app and backend validation on push and pull requests
- release APK generation
- Supabase backend deployment
- update notification publishing

The release workflow builds and uploads the APK artifact with the standard app secrets, and publishes to Supabase Storage only when a service-role key is configured.

## Testing

```bash
cd studytrack
flutter analyze
flutter test
```

## Data Model

The Supabase schema includes tables for profiles, modules, topics, study sessions, exams, groups, chat messages, badges, weekly reports, and uploaded notes. The full schema lives in [`supabase/schema.sql`](supabase/schema.sql).

## Documentation

- [`CONTRIBUTING.md`](CONTRIBUTING.md)
- [`DEPLOYMENT_GUIDE.md`](DEPLOYMENT_GUIDE.md)
- [`SUPABASE_SETUP.md`](SUPABASE_SETUP.md)
- [`SECURITY.md`](SECURITY.md)
- [`CHANGELOG.md`](CHANGELOG.md)

Release notes for maintainers live in [`CHANGELOG.md`](CHANGELOG.md); release artifacts and tags are published from the repository’s GitHub Actions workflow.

## Contributing

Contributions are welcome. Please read [`CONTRIBUTING.md`](CONTRIBUTING.md) before opening a pull request and make sure `flutter analyze` and `flutter test` pass locally.
