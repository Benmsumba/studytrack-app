# StudyTrack Phase 0-9 Complete Schema Setup Guide

## Status Summary
✅ **Schema Tables:** All created successfully  
✅ **Storage Bucket:** Created successfully  
✅ **Backend API:** Running and healthy  
⏳ **RLS Policies:** Need to be updated for service_role bypass

## What You Need to Do

### Step 1: Run Schema Fixes SQL
If you haven't already, run this in your Supabase SQL Editor:

```sql
alter table if exists public.profiles
add column if not exists onboarding_complete boolean not null default false;
```

### Step 2: Update RLS Policies for Backend API (CRITICAL)
The backend API is blocked by RLS policies. Run the complete file:
**Copy the entire content of:** `/workspaces/studytrack-app/supabase/rls_service_role_bypass.sql`

Paste it all into your Supabase SQL Editor and run it. This adds `auth.role() = 'service_role'` to all RLS policies, allowing the backend to:
- Insert uploaded notes
- Create note chunks
- Access all tables via service key

### Step 3: Restart Backend
After running the RLS SQL, restart the backend:

```bash
cd /workspaces/studytrack-app/studytrack/backend
# Kill any running process (Ctrl+C)
uvicorn main:app --host 0.0.0.0 --port 8000
```

### Step 4: Test Upload Endpoint
```bash
curl -X POST http://127.0.0.1:8000/process-document \
  -F "file=@test.pdf" \
  -F "topic_id=123e4567-e89b-12d3-a456-426614174000" \
  -F "user_id=123e4567-e89b-12d3-a456-426614174001"
```

Expected response: `{"url":"https://...","status":"..."}` (success)

## Files Created

1. **schema.sql** - Main schema with all 14 tables, functions, triggers, indexes, RLS
2. **storage_setup.sql** - Supabase Storage bucket initialization
3. **schema_fixes.sql** - Adds missing `onboarding_complete` column
4. **rls_service_role_bypass.sql** - **CRITICAL** - Updates all RLS policies for backend API

## Current Error
```
postgrest.exceptions.APIError: {'message': 'permission denied for schema public', 'code': '42501'}
```

This happens because the old RLS policies don't allow the service_role (backend API) to access tables. The fix is Step 2 above.

## Verification Queries (Run After RLS Update)

After running the RLS SQL, verify with these queries in Supabase:

```sql
-- Check all core tables exist
select table_name 
from information_schema.tables 
where table_schema = 'public' 
  and table_name in ('profiles','modules','topics','uploaded_notes','note_chunks','study_sessions','exams','study_groups','group_members','group_messages','badges','weekly_reports','class_timetable','topic_ratings_history')
order by table_name;

-- Verify storage bucket
select id, name, public from storage.buckets where id = 'studytrack-notes';

-- Check RLS is enabled
select tablename, rowsecurity 
from pg_tables 
where schemaname = 'public' 
  and rowsecurity = true
order by tablename;
```

Expected results:
- 14 tables listed ✓
- studytrack-notes bucket exists ✓
- All tables have rowsecurity = true ✓

## Architecture

**Database Schema:** PostgreSQL + Supabase Auth + Row Level Security
- 14 core tables covering profiles, modules, topics, notes, study sessions, exams, groups, analytics
- 3 triggers for automation (set_updated_at, invite_code generation, review scheduling)
- 40+ indexes for query performance
- RLS policies protecting user data with auth.uid() checks
- Service role bypass for backend API operations

**Storage:** Supabase Storage (replaced Azure Blob)
- Bucket: `studytrack-notes` (public)
- Files stored and served via CDN
- Public URL generation for document access

**Backend API:** FastAPI Python
- POST /health - System status
- POST /process-document - Upload and process PDFs/PPTs
  - Uploads file to Supabase Storage
  - Creates uploaded_notes record
  - Extracts text via PyMuPDF
  - Chunks content (500 words, 50-word overlap)
  - Stores chunks in note_chunks table

**Frontend:** Flutter Dart
- StorageService handles upload, monitoring, retrieval
- Supabase integration for all backend queries
- RLS ensures users only see their own data

## Next Steps After Verification

Once RLS policies are applied and upload endpoint works:
1. Test end-to-end with Flutter app
2. Verify document processing and chunk storage
3. Test context ranking and AI tutor integration
4. Phase 10 - Backend expansion (more AI features)
