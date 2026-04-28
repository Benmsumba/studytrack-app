# Security Policy

## Supported Versions

Only the latest release on the `main` branch receives security fixes.

| Version | Supported |
|---|---|
| Latest (`main`) | Yes |
| Older tags | No |

---

## Reporting a Vulnerability

**Do not open a public GitHub issue for security vulnerabilities.**

To report a vulnerability, open a [GitHub Security Advisory](https://github.com/Benmsumba/studytrack-app/security/advisories/new) on this repository. You will receive an acknowledgement within 48 hours. If you do not hear back within that window, follow up by mentioning it in a private message.

Please include:

- A clear description of the vulnerability and its potential impact.
- Steps to reproduce or a proof-of-concept (if safe to share).
- The affected component (auth, offline sync, AI tutor, etc.) and version.

We will work with you to validate and address the issue before any public disclosure.

---

## Sensitive Files

The following files must never be committed to the repository. They are excluded by `.gitignore`:

| File | Why |
|---|---|
| `.env` | Contains Supabase URL, anon key, and Gemini API key |
| `studytrack/android/key.properties` | Contains Android signing keystore path and passwords |
| `*.jks`, `*.keystore` | Android release signing keystores |
| `studytrack/android/keystore/` | Keystore directory |

If any of these are accidentally committed, follow the remediation steps below immediately.

---

## Secret Rotation (Emergency Remediation)

If a secret is exposed in the git history, take these steps:

### 1. Rotate the secret immediately (before cleaning history)

| Secret | Where to rotate |
|---|---|
| `SUPABASE_URL` / `SUPABASE_ANON_KEY` | Supabase Dashboard → Settings → API → Regenerate keys |
| `GEMINI_API_KEY` | [Google AI Studio](https://aistudio.google.com) → Manage API keys |
| Android keystore | Generate a new keystore with `keytool`; old APKs cannot be updated under the old key |

### 2. Remove the file from the working tree

```bash
git rm --cached path/to/.env || true
git rm --cached studytrack/android/key.properties || true
git rm --cached -r studytrack/keystore || true
git commit -m "chore: remove sensitive files from tracking"
```

### 3. Scrub the secret from git history

**Option A — BFG Repo-Cleaner (recommended):**

```bash
# List secrets to remove, one per line
echo "YOUR_EXPOSED_SECRET" > secrets.txt

bfg --replace-text secrets.txt
git reflog expire --expire=now --all
git gc --prune=now --aggressive
git push --force
```

**Option B — git-filter-repo:**

```bash
pip install git-filter-repo
# Create a replacements file, then:
git filter-repo --replace-text replacements.txt
git push --force
```

### 4. Verify the history is clean

```bash
git log --all -p -G "SUPABASE_URL\|SUPABASE_ANON_KEY\|GEMINI_API_KEY\|storePassword\|keyPassword"
```

### 5. Re-add rotated secrets to GitHub Actions

Go to **Settings → Secrets and variables → Actions** and update:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `GEMINI_API_KEY`
- `KEYSTORE_BASE64`, `KEY_ALIAS`, `KEY_PASSWORD`, `STORE_PASSWORD`

---

## Security Best Practices for Contributors

- Pass API keys via `--dart-define` or `--dart-define-from-file`. Never hardcode them in source.
- Use `const String.fromEnvironment(...)` to read build-time values in Dart; these are not included in debug builds unless explicitly passed.
- Row Level Security (RLS) is enabled on all user-facing Supabase tables. Do not disable RLS without a documented justification and a reviewed PR.
- The Supabase `anon` key is safe to ship in the client. The `service_role` key must never leave the server/CI environment.
- All Android permissions declared in `AndroidManifest.xml` must have corresponding runtime permission handling in Dart code.
