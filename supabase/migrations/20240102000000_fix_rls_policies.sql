-- Fix three RLS policies that break the groups feature, and add a
-- security-definer RPC so non-members can join a group via invite code
-- without needing a direct SELECT on study_groups first.
--
-- Bugs fixed:
--   1. study_groups SELECT: was creator-only → members cannot see joined groups
--   2. group_messages SELECT: was sender-only → members cannot read others' messages
--   3. group_members SELECT: was own-row-only → members list always shows only yourself
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- 1. study_groups — allow any member (not just creator) to see the group
-- ---------------------------------------------------------------------------

drop policy if exists study_groups_select_own on public.study_groups;

create policy study_groups_select_member
on public.study_groups
for select
using (
  created_by = auth.uid()
  or exists (
    select 1
    from public.group_members gm
    where gm.group_id = study_groups.id
      and gm.user_id = auth.uid()
  )
);

-- ---------------------------------------------------------------------------
-- 2. group_messages — allow any group member to read all messages in the group
-- ---------------------------------------------------------------------------

drop policy if exists group_messages_select_own on public.group_messages;

create policy group_messages_select_member
on public.group_messages
for select
using (
  -- own messages always visible
  sender_id = auth.uid()
  -- group messages: readable by all members of that group
  or (
    group_id is not null
    and exists (
      select 1
      from public.group_members gm
      where gm.group_id = group_messages.group_id
        and gm.user_id = auth.uid()
    )
  )
  -- topic messages: readable by the topic owner
  or (
    topic_id is not null
    and exists (
      select 1
      from public.topics t
      where t.id = group_messages.topic_id
        and t.user_id = auth.uid()
    )
  )
);

-- ---------------------------------------------------------------------------
-- 3. group_members — allow a member to see all other members of their groups
-- ---------------------------------------------------------------------------

drop policy if exists group_members_select_own on public.group_members;

create policy group_members_select_shared_group
on public.group_members
for select
using (
  user_id = auth.uid()
  or exists (
    select 1
    from public.group_members gm2
    where gm2.group_id = group_members.group_id
      and gm2.user_id = auth.uid()
  )
);

-- ---------------------------------------------------------------------------
-- 4. RPC: join_group_by_invite_code
--
-- Runs as SECURITY DEFINER (bypasses RLS) so the caller can look up the
-- group row before they are a member — which the fixed SELECT policy above
-- would still block. Returns the study_groups row as JSON on success, or
-- raises an exception on invalid code / unauthenticated call.
-- ---------------------------------------------------------------------------

create or replace function public.join_group_by_invite_code(p_invite_code text)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_group  public.study_groups%rowtype;
  v_uid    uuid;
begin
  v_uid := auth.uid();
  if v_uid is null then
    raise exception 'Not authenticated'
      using errcode = 'UNAUTHENTICATED', hint = 'Sign in before joining a group.';
  end if;

  select * into v_group
  from public.study_groups
  where invite_code = upper(p_invite_code);

  if not found then
    raise exception 'Invalid invite code'
      using errcode = 'INVALID_CODE', hint = 'Check the code and try again.';
  end if;

  insert into public.group_members (group_id, user_id, role, joined_at)
  values (v_group.id, v_uid, 'member', now())
  on conflict (group_id, user_id) do nothing;

  return row_to_json(v_group);
end;
$$;

-- Grant execute to authenticated users only.
revoke execute on function public.join_group_by_invite_code(text) from public;
grant  execute on function public.join_group_by_invite_code(text) to authenticated;

-- ---------------------------------------------------------------------------
-- 5. Enable Realtime on group_messages and group_members
--    (idempotent — safe to run multiple times)
-- ---------------------------------------------------------------------------

do $$
begin
  -- group_messages
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'group_messages'
  ) then
    alter publication supabase_realtime add table public.group_messages;
  end if;

  -- group_members
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'group_members'
  ) then
    alter publication supabase_realtime add table public.group_members;
  end if;
end;
$$;
