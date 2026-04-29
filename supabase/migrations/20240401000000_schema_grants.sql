-- StudyTrack schema privilege fix
-- Run this in Supabase SQL Editor after schema.sql
-- Fixes schema-level permission denied errors for PostgREST/service role

-- Ensure API roles can use the public schema
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;

-- Grant full access to the backend service role on all existing tables
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO service_role;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO service_role;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO service_role;

-- Grant access to existing authenticated users for tables the app reads directly
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- If anon is used anywhere by the app, at least allow schema usage
GRANT USAGE ON SCHEMA public TO anon;

-- Default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO authenticated;

-- Verification
SELECT n.nspname AS schema_name, r.rolname AS role_name, has_schema_privilege(r.rolname, 'public', 'USAGE') AS can_use_public
FROM pg_roles r
CROSS JOIN (SELECT 'public'::text AS nspname) n
WHERE r.rolname IN ('anon', 'authenticated', 'service_role');
