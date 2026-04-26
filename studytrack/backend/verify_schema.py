#!/usr/bin/env python3
import os
from dotenv import load_dotenv
from supabase import create_client

# Load env from current dir
load_dotenv(override=True)

url = os.getenv("SUPABASE_URL")
key = os.getenv("SUPABASE_SERVICE_KEY")

if not url or not key:
    print("Error: Missing Supabase credentials")
    exit(1)

print(f"URL: {url[:50]}...")
print(f"Key: {key[:30]}...\n")

try:
    client = create_client(url, key)
except Exception as e:
    print(f"Failed to create client: {e}")
    exit(1)

# Check all tables exist
tables_to_check = [
    'profiles', 'modules', 'topics', 'topic_ratings_history',
    'uploaded_notes', 'note_chunks', 'class_timetable', 
    'study_sessions', 'exams', 'study_groups', 'group_members',
    'group_messages', 'badges', 'weekly_reports'
]

print("Checking core tables...")
missing_tables = []
for table in tables_to_check:
    try:
        response = client.table(table).select("*", count="exact").limit(1).execute()
        print(f"✓ {table}")
    except Exception as e:
        error_msg = str(e)
        if "not found" in error_msg.lower() or "does not exist" in error_msg.lower():
            missing_tables.append(table)
            print(f"✗ {table}: MISSING")
        else:
            print(f"✗ {table}: {error_msg[:60]}")

# Check storage bucket
print("\nChecking storage bucket...")
try:
    buckets = client.storage.list_buckets()
    bucket_names = [b.name for b in buckets]
    if 'studytrack-notes' in bucket_names:
        print(f"✓ studytrack-notes bucket exists")
    else:
        print(f"✗ studytrack-notes bucket missing. Available: {bucket_names}")
except Exception as e:
    print(f"✗ Storage error: {str(e)[:80]}")

if missing_tables:
    print(f"\n⚠️  Missing tables: {', '.join(missing_tables)}")
else:
    print("\n✅ All schema tables verified successfully!")
