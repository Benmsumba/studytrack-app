-- Performance: composite indexes for the most frequent multi-column query patterns.
-- Run this migration once against your Supabase project.

-- Topics filtered by user then sorted by next review date (dashboard / spaced-repetition).
-- Replaces separate single-column scans on user_id + next_review_at.
create index if not exists idx_topics_user_next_review
  on public.topics (user_id, next_review_at);

-- Study sessions filtered by user + date (timetable screen, daily agenda).
-- Replaces separate single-column scans on user_id + scheduled_date.
create index if not exists idx_study_sessions_user_date
  on public.study_sessions (user_id, scheduled_date);

-- Group messages ordered by group + time (chat screen, recent-message lookup).
-- Replaces separate single-column scans on group_id + created_at.
create index if not exists idx_group_messages_group_time
  on public.group_messages (group_id, created_at desc);

-- Topic rating history ordered by topic + time (rating-history chart).
create index if not exists idx_topic_ratings_topic_time
  on public.topic_ratings_history (topic_id, rated_at desc);
