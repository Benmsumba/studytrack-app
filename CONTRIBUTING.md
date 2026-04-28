# Contributing to StudyTrack

Thanks for taking the time to contribute. This document covers everything you need to get set up, the development workflow, and the standards applied to all contributions.

---

## Table of Contents

- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Commit Messages](#commit-messages)
- [Code Style](#code-style)
- [Testing](#testing)
- [Pull Request Checklist](#pull-request-checklist)
- [Reporting Issues](#reporting-issues)
- [Security Vulnerabilities](#security-vulnerabilities)

---

## Getting Started

1. **Fork** the repository and clone your fork.

   ```bash
   git clone https://github.com/<your-username>/studytrack-app.git
   cd studytrack-app/studytrack
   ```

2. **Install dependencies.**

   ```bash
   flutter pub get
   ```

3. **Configure your environment.** Copy `.env.example` to `.env` and fill in your own Supabase and Gemini API credentials.

   ```bash
   cp .env.example .env
   ```

4. **Apply the database schema** to your own Supabase project using `supabase/schema.sql`.

5. **Run the app** to verify everything works.

   ```bash
   flutter run --dart-define-from-file=../.env
   ```

---

## Development Workflow

Use a branch-per-feature model. Branch names should be short and descriptive:

| Type | Pattern | Example |
|---|---|---|
| Feature | `feature/<name>` | `feature/exam-reminders` |
| Bug fix | `fix/<name>` | `fix/offline-sync-crash` |
| Documentation | `docs/<name>` | `docs/supabase-setup` |
| Refactor | `refactor/<name>` | `refactor/auth-provider` |

```bash
# Create and switch to a new branch
git checkout -b feature/your-feature

# Make your changes, then verify
flutter analyze
flutter test

# Push and open a pull request
git push origin feature/your-feature
```

Keep changes focused. A pull request should address one concern. If you find an unrelated bug while working, open a separate issue or branch for it.

---

## Commit Messages

Follow the [Conventional Commits](https://www.conventionalcommits.org/) format:

```
<type>(<scope>): <short summary>
```

| Type | When to use |
|---|---|
| `feat` | A new feature |
| `fix` | A bug fix |
| `refactor` | Code change that does not add a feature or fix a bug |
| `test` | Adding or updating tests |
| `docs` | Documentation changes only |
| `chore` | Build process, dependency updates, config changes |
| `ci` | Changes to GitHub Actions workflows |

**Examples:**

```
feat(ai-tutor): add mnemonic generation for topic summaries
fix(offline-sync): resolve duplicate queuing on rapid disconnect
docs(readme): add Play Store roadmap section
chore(deps): upgrade supabase_flutter to 2.13.0
```

---

## Code Style

- Follow existing Flutter and Dart patterns in the repository.
- Use `lowerCamelCase` for variables and methods, `UpperCamelCase` for types.
- Prefer `const` constructors wherever possible.
- Keep widgets small and composable. Extract sub-widgets when a build method exceeds ~60 lines.
- State belongs in providers (`core/services/` or `features/*/controllers/`), not in widgets.
- Do not add comments that restate what the code already says. Only comment to explain a non-obvious constraint, workaround, or invariant.
- Run `flutter analyze` before every commit. Do not suppress lint warnings without a comment explaining why.

### File organisation

New features go in `lib/features/<feature-name>/` following the existing structure:

```
features/your-feature/
├── controllers/
│   └── your_feature_provider.dart
└── screens/
    └── your_feature_screen.dart
```

Shared widgets go in `lib/core/widgets/`. Models go in `lib/models/`.

---

## Testing

All pull requests must pass `flutter analyze` and `flutter test` with no new failures.

```bash
cd studytrack
flutter analyze
flutter test
```

When adding new features, include tests for:
- Unit logic in services and providers.
- Widget smoke tests for new screens.

Tests live in `studytrack/test/`.

---

## Pull Request Checklist

Before marking your PR as ready for review, confirm the following:

- [ ] `flutter analyze` passes with no new warnings or errors.
- [ ] `flutter test` passes.
- [ ] No secrets, API keys, keystores, or `.env` files are committed.
- [ ] Documentation is updated if behaviour changes.
- [ ] The PR description explains **what** changed and **why**.
- [ ] The PR is scoped to a single concern.

---

## Reporting Issues

Use the issue templates on GitHub:

- **[Bug report](.github/ISSUE_TEMPLATE/bug_report.yml)** — for crashes, incorrect behaviour, or unexpected UI.
- **[Feature request](.github/ISSUE_TEMPLATE/feature_request.yml)** — for new functionality or improvements.

Please search existing issues before opening a new one.

---

## Security Vulnerabilities

Do **not** open a public GitHub issue for security vulnerabilities. Follow the process described in [SECURITY.md](SECURITY.md).
