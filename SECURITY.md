SECURITY and Emergency Remediation

Immediate actions (must be done now by a human with console access):

- Rotate Supabase service-role and anon keys using the Supabase dashboard.
- Rotate the Gemini API key in the provider console (for example Google Cloud).
- Replace any compromised Android signing keystore and passwords; generate a new keystore if needed.

Repository-side remediation steps (do these after rotating keys):

1) Remove sensitive files from the current branch (if present):

   git rm --cached path/to/.env || true
   git rm --cached studytrack/android/key.properties || true
   git rm --cached -r studytrack/keystore || true
   git commit -m "chore: remove sensitive files from repo" || true

2) Scrub secrets from git history. Recommended approaches (run AFTER rotation):

   Option A - BFG Repo-Cleaner:
   - Create a file named secrets-to-remove.txt listing secrets or patterns (one per line).
   - Run: bfg --delete-lines secrets-to-remove.txt
   - Then: git reflog expire --expire=now --all
   - Then: git gc --prune=now --aggressive
   - Finally: git push --force

   Option B - git-filter-repo (advanced):
   - Install: pip install git-filter-repo
   - Create a replace file and run: git filter-repo --replace-text secrets-to-replace.txt
   - Then force-push the cleaned history

3) Re-add rotated secrets to GitHub Actions Secrets (Repository Settings) not to repository files.

Verification:

   git log --all -p -G "SUPABASE_URL|SUPABASE_ANON_KEY|GEMINI_API_KEY|storePassword|keyPassword|release-keystore|\\.env"

Notes:

- I cannot rotate provider-side keys or force-push cleaned history for you. These steps need console access and a human operator.
- I added repo protections and CI changes in the repository to avoid future accidental exposure. Follow the steps above to complete remediation.
