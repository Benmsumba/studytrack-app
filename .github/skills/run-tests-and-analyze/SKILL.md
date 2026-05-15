# run-tests-and-analyze

Short: Run dependency install, static analysis, and unit tests.

Purpose
- Provide a concise, repeatable skill for agents to verify repository health before proposing changes.

When to use
- Before making code changes that affect behavior.
- As a quick CI-local check when validating PRs.

What it does
- Runs `flutter pub get` to install dependencies.
- Runs `flutter analyze` to catch static analysis issues.
- Runs `flutter test` to execute unit and widget tests.

Commands
```bash
flutter pub get
flutter analyze
flutter test
```

Agent guidance
- Run these commands in the repository root (`studytrack-app`).
- Capture and surface failures (non-zero exit codes) and the first failing test or analyzer error.
- If tests or analysis fail, do not propose code changes that hide or suppress the underlying issues; instead report the failures and suggest targeted fixes.

Safety and secrets
- Do not attempt to read or write secret files (keystores, encoded credentials). If a missing secret prevents a step (e.g., Android signing), report the blocker and the file that needs human-provided values.

Suggested output format
- Summary: pass/fail for each step.
- On failure: first 10 lines of relevant error output and file paths to the failing tests or analyzer errors.

Notes
- This skill intentionally keeps scope small to be safe and deterministic.
