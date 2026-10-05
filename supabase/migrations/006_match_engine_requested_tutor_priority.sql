-- SmartMatch Phase 3: requested tutor priority, ranked backups, and decline handoff
alter table public.matches add column if not exists match_rank integer;
alter table public.matches add column if not exists source text not null default 'engine';
create index if not exists matches_request_rank_idx on public.matches(request_id, match_rank);

-- generate_matches() is deployed in the database with requested-tutor priority and
-- declined-tutor exclusion. The Edge Function tutor-response promotes the next
-- shortlisted backup when a tutor declines.
