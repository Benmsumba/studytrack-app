# AGENTS — Guidance for AI coding agents

Purpose: Help AI coding agents become productive quickly in this repository. Keep changes minimal, link to authoritative docs, and avoid exposing secrets.

Quick Actions
- Install deps: `flutter pub get`
- Analyze: `flutter analyze`
- Run tests: `flutter test`
- Run app locally: `flutter run`
- Build release APK: `flutter build apk --release`

Where to look (high-value files)
- Project README: [README.md](README.md)
- Flutter app docs: [studytrack/README.md](studytrack/README.md)
- App entry: [lib/main.dart](lib/main.dart)
- Core code: [lib/core/](lib/core/)
- Features: [lib/features/](lib/features/)
- Models: [lib/models/](lib/models/)
- Android config: [studytrack/android/](studytrack/android/)
- Release keystore (encoded): [studytrack/android/release-keystore.b64](studytrack/android/release-keystore.b64)
- Scripts: [scripts/](scripts/)
- Supabase setup & migrations: [SUPABASE_SETUP.md](SUPABASE_SETUP.md), [supabase/migrations/](supabase/migrations/)
- Contribution & deployment guides: [CONTRIBUTING.md](CONTRIBUTING.md), [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)

Agent Rules (short, actionable)
- Do not add or commit secrets, keys, or credentials. If a change requires secrets, request guidance.
- Prefer linking to existing docs instead of copying them.
- Run `flutter test` and `flutter analyze` before proposing code changes that affect behavior.
- Use existing scripts in `/scripts` for build/release automation when available.
- For database or backend changes, reference `supabase/` and migrations; do not modify production SQL without human review.

If you need more context
- Ask which platform or CI to target (Android/iOS/web) and whether you should run tests locally.

Suggested next agent customizations
- Create a short skill for "run-tests-and-analyze" that executes `flutter pub get && flutter analyze && flutter test` and reports failures.
- Create an agent prompt for safely handling Supabase or keystore changes that enforces human review.
