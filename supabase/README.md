# Supabase Database

## Directory structure

```
supabase/
├── migrations/          # Run these in order against your Supabase project
│   ├── 20240101000000_initial_schema.sql         — Full schema, tables, RLS, indexes
│   ├── 20240201000000_onboarding_complete.sql    — Adds onboarding_complete column
│   ├── 20240301000000_storage_setup.sql          — Creates studytrack-notes storage bucket
│   ├── 20240401000000_schema_grants.sql          — Grants privileges to anon/authenticated roles
│   ├── 20240501000000_rls_service_role_bypass.sql — RLS bypass policies for service_role
│   ├── 20260429000000_performance_indexes.sql    — Composite indexes for hot query paths
│   └── 20260509000001_soft_delete_and_cleanup.sql — Soft-delete columns + orphan cleanup triggers
│
├── dev/                 # Development helpers — NEVER run in production
│   ├── quick_unblock.sql          — Opens all permissions (local testing only)
│   └── rls_disable_for_backend.sql — Disables RLS entirely (local testing only)
│
├── config.toml          — Supabase CLI project configuration
└── README.md            — This file
```

## Applying migrations

Run each file in the `migrations/` folder **in filename order** via the Supabase SQL editor
or the Supabase CLI:

```bash
supabase db push
# or manually:
psql "$DATABASE_URL" -f supabase/migrations/20240101000000_initial_schema.sql
psql "$DATABASE_URL" -f supabase/migrations/20240201000000_onboarding_complete.sql
# ... and so on
```

All migration files use `create … if not exists` and `create or replace`, so they are
safe to re-run.

## Notes

- The numbered files in `migrations/` are the single source of truth for the schema.
- Files in `dev/` are for local development only and must not be applied to staging or
  production databases.
