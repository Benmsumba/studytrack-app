# StudyTrack Schema Permissions Fix

The backend upload endpoint is still returning:

`permission denied for schema public` (code `42501`)

That means the database is missing the schema/table grants needed for the API role.

## Run this SQL in Supabase
Open the SQL Editor and run:

- `/workspaces/studytrack-app/supabase/schema_grants_fix.sql`

## Then verify
Run this query:

```sql
SELECT n.nspname AS schema_name, r.rolname AS role_name, has_schema_privilege(r.rolname, 'public', 'USAGE') AS can_use_public
FROM pg_roles r
CROSS JOIN (SELECT 'public'::text AS nspname) n
WHERE r.rolname IN ('anon', 'authenticated', 'service_role');
```

You want `can_use_public = true` for `service_role`.

## After that
Restart the backend and retry the upload endpoint.
