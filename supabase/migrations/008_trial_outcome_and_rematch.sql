-- SmartMatch Phase 3 transaction flow
alter table public.matches add column if not exists trial_outcome text;
alter table public.matches add column if not exists trial_notes text;
alter table public.matches add column if not exists trial_completed_at timestamptz;
create index if not exists matches_trial_outcome_idx on public.matches(request_id,trial_outcome);

-- generate_matches() is deployed with:
-- 1) requested-tutor priority
-- 2) declined-tutor exclusion
-- 3) prior accepted/trial/confirmed/closed tutor exclusion
-- 4) ranked backup generation
