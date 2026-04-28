# StudyTrack

StudyTrack is a Flutter app for student planning, study tracking, and academic productivity. It combines modules, timetables, study sessions, analytics, AI tutoring, and lightweight collaboration into a single mobile-first workflow.

[![Build APK](https://github.com/Benmsumba/studytrack-app/actions/workflows/build_apk.yml/badge.svg)](https://github.com/Benmsumba/studytrack-app/actions/workflows/build_apk.yml)
[![Backend Deploy](https://github.com/Benmsumba/studytrack-app/actions/workflows/deploy_backend.yml/badge.svg)](https://github.com/Benmsumba/studytrack-app/actions/workflows/deploy_backend.yml)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## Highlights

- Study sessions, topic tracking, and daily goals
- Module progress, quizzes, and analytics
- AI tutor and study support flows
- Timetable and reminders
- Cross-platform Flutter structure with CI checks

## Getting Started

1. Install Flutter 3.29+ and Dart 3.11+.
2. From the app root, run `flutter pub get`.
3. Configure the required runtime values with the repository guidance in [SECURITY.md](SECURITY.md).
4. Launch the app with your preferred Flutter target, for example `flutter run`.

## Repository Layout

- `studytrack/lib/` app code, features, widgets, models, and services
- `studytrack/android/`, `studytrack/linux/`, `studytrack/web/` platform targets
- `studytrack/test/` unit and widget tests
- `studytrack/UI/` reference design material and screen documentation
- `.github/workflows/` CI and release automation

## Quality Checks

- `flutter analyze`
- `flutter test`
- GitHub Actions build and deployment workflows

## Release Notes

Releases follow the tag-based workflow already used by GitHub Actions.

## Project Policies

- [Contributing guide](CONTRIBUTING.md)
- [Code of conduct](CODE_OF_CONDUCT.md)
- [Security guidance](SECURITY.md)
- [License](LICENSE)