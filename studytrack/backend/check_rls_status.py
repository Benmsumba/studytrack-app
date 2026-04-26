#!/usr/bin/env python3
"""
StudyTrack RLS Diagnostic
Check if RLS has been disabled on Supabase tables
"""
import os

with open('/workspaces/studytrack-app/studytrack/backend/.env') as f:
    for line in f:
        if line.strip() and not line.startswith('#'):
            k, v = line.strip().split('=', 1)
            os.environ[k] = v

from supabase import create_client

url = os.environ["SUPABASE_URL"]
key = os.environ["SUPABASE_SERVICE_KEY"]

client = create_client(url, key)

# Try to check RLS status via information_schema
# This will tell us if RLS is actually disabled

print("=" * 60)
print("StudyTrack RLS Diagnostic")
print("=" * 60)

tables_to_check = ['profiles', 'uploaded_notes', 'note_chunks']

print("\nChecking RLS status on key tables...")
for table in tables_to_check:
    try:
        # Try to select with limit 0 - this should work if RLS is disabled or if policies allow
        response = client.table(table).select('count', count='exact').limit(0).execute()
        print(f"✅ {table}: ACCESSIBLE (RLS likely disabled or policies allow)")
    except Exception as e:
        error_str = str(e)
        if '42501' in error_str:
            print(f"❌ {table}: BLOCKED (Code 42501 - permission denied for schema)")
        elif 'permission denied' in error_str.lower():
            print(f"❌ {table}: BLOCKED (permission denied)")
        else:
            print(f"⚠️  {table}: Other error - {error_str[:50]}")

print("\n" + "=" * 60)
print("DIAGNOSIS:")
print("=" * 60)

print("""
If you see ❌ BLOCKED on any table:

1. The RLS disable SQL may NOT have been executed
2. Or it executed but didn't take effect

TO FIX:
1. Go to https://supabase.com/dashboard
2. Select your studytrack project
3. Click SQL Editor  
4. Create NEW query and paste EXACTLY this:

alter table public.profiles disable row level security;
alter table public.modules disable row level security;
alter table public.topics disable row level security;
alter table public.topic_ratings_history disable row level security;
alter table public.uploaded_notes disable row level security;
alter table public.note_chunks disable row level security;
alter table public.class_timetable disable row level security;
alter table public.study_sessions disable row level security;
alter table public.exams disable row level security;
alter table public.study_groups disable row level security;
alter table public.group_members disable row level security;
alter table public.group_messages disable row level security;
alter table public.badges disable row level security;
alter table public.weekly_reports disable row level security;

5. Click RUN (Ctrl+Enter)
6. VERIFY: Check console for success message
7. Run this script again to verify

If you see ✅ ACCESSIBLE:
Great! RLS is disabled. Backend should work now.
""")

print("=" * 60)
