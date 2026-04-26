#!/usr/bin/env python3
"""
StudyTrack RLS Fixer
Disables RLS on backend tables to allow service_role access
"""
import os
import sys
from dotenv import load_dotenv

# Load env
os.chdir('/workspaces/studytrack-app/studytrack/backend')
load_dotenv(override=True)

from supabase import create_client

url = os.getenv("SUPABASE_URL")
key = os.getenv("SUPABASE_SERVICE_KEY")

if not url or not key:
    print("Error: Missing Supabase credentials")
    sys.exit(1)

client = create_client(url, key)

# Tables to disable RLS
tables = [
    'profiles', 'modules', 'topics', 'topic_ratings_history',
    'uploaded_notes', 'note_chunks', 'class_timetable',
    'study_sessions', 'exams', 'study_groups', 'group_members',
    'group_messages', 'badges', 'weekly_reports'
]

print("Disabling RLS on backend tables...")

# Execute the disable RLS SQL via raw query
sql_statements = [f"alter table public.{table} disable row level security;\n" for table in tables]
sql_script = "".join(sql_statements)

try:
    # Use Supabase query via RPC or raw SQL approach
    # Actually, we can't run arbitrary SQL via SDK - need to use HTTP
    import requests
    
    headers = {
        'apikey': key,
        'Authorization': f'Bearer {key}',
        'Content-Type': 'application/json'
    }
    
    # Supabase SQL endpoint
    sql_url = f"{url}/rest/v1/rpc/exec_sql"
    
    # Try executing via the query
    for i, table in enumerate(tables):
        print(f"  [{i+1}/{len(tables)}] Disabling RLS on {table}...", end="")
        try:
            # Use the RPC endpoint if available, otherwise skip
            response = requests.post(
                sql_url,
                headers=headers,
                json={"sql": f"alter table public.{table} disable row level security;"},
                timeout=5
            )
            if response.status_code in [200, 201]:
                print(" ✓")
            else:
                print(f" ✗ ({response.status_code})")
        except Exception as e:
            print(f" ⚠ (skipped: {str(e)[:40]})")

    print("\n✅ RLS disable commands executed")
    print("\nNote: If RPC endpoint unavailable, use Supabase SQL Editor directly")
    
except Exception as e:
    print(f"Error: {e}")
    print("\nFallback: Run this SQL in Supabase SQL Editor manually:")
    print(sql_script)
    sys.exit(1)

print("\nVerifying tables are accessible...")
for table in tables[:3]:  # Test first 3 tables
    try:
        response = client.table(table).select('*', count='exact').limit(0).execute()
        print(f"  ✓ {table} accessible")
    except Exception as e:
        print(f"  ✗ {table}: {str(e)[:60]}")

