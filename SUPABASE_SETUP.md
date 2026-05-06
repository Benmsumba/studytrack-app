# Supabase Setup Guide for StudyTrack

## Step 1: Get Your Supabase Credentials

1. Go to [app.supabase.com](https://app.supabase.com)
2. Sign in or create a free account
3. Select your StudyTrack project (or create one)
4. Navigate to **Settings → API**
5. Copy these two values:
   - **Project URL** (looks like: `https://xxxxxxxxxxxx.supabase.co`)
   - **anon public** key (a long encoded string starting with `eyJ...`)

## Step 2: Apply Credentials to the App

### Option A: Use dart-define (Recommended)
```bash
cd /workspaces/studytrack-app/studytrack
flutter run -d web-server \
  --web-hostname 0.0.0.0 \
  --web-port 8080 \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY_HERE
```

### Option B: Copy the local example file
Copy `studytrack/.env.example` to your own local environment file and replace the placeholder values before building release APKs.

## Step 3: Verify Setup

1. Navigate to: `https://stunning-acorn-4qr6j5q7774fqr7w-8080.app.github.dev/signup`
2. Try creating an account
3. If successful → onboarding screen appears ✅
4. If error → check that Supabase credentials are correct

## Troubleshooting

- **"Supabase is not configured"**: Your credentials are still placeholder values. Update them using Option A or B above.
- **"Unable to create account"**: Check that Email provider is enabled in Supabase:
  - Go to **Authentication → Providers → Email → Enable**
- **Network error**: Verify your Supabase project is active and not paused.

## Notes for Production

- **Never commit real credentials** to git (use `.gitignore`)
- Store secrets in GitHub Actions secrets or environment variables
- The app supports reading from `--dart-define` for CI/CD pipelines
- The release APK workflow builds with `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `GEMINI_API_KEY`, and optionally publishes to Supabase Storage when `SUPABASE_SERVICE_ROLE_KEY` is configured

## Emergency (exposed credentials)

If any keys have been committed to git history, rotate them immediately and follow the repo remediation steps in SECURITY.md. After rotation, add the new values to GitHub Actions secrets rather than committing them to the repository.

See SECURITY.md for step-by-step commands and history-scrub guidance.
