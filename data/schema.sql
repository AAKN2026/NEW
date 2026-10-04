-- Tutor Match data model (ready for Supabase/Postgres)
create table if not exists parent_requests (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  parent_name text not null, whatsapp text not null,
  student_level text not null, subject text not null,
  lesson_format text, budget text, location text,
  preferred_schedule text, requirements text,
  status text not null default 'new'
    check (status in ('new','contacted','matching','shortlisted','trial','confirmed','rematch','closed'))
);

create table if not exists tutors (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  full_name text not null, whatsapp text not null,
  subjects text[] not null, levels text[] not null,
  experience_years numeric, lesson_formats text[],
  locations text[], hourly_rate text, availability text,
  qualifications text, profile text,
  status text not null default 'pending'
    check (status in ('pending','verified','active','paused','inactive'))
);

create table if not exists matches (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  request_id uuid not null references parent_requests(id) on delete cascade,
  tutor_id uuid not null references tutors(id) on delete cascade,
  match_score numeric,
  notes text,
  status text not null default 'shortlisted'
    check (status in ('shortlisted','contacted','accepted','declined','trial','confirmed','closed'))
);

create table if not exists placements (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  request_id uuid not null references parent_requests(id) on delete cascade,
  tutor_id uuid not null references tutors(id) on delete cascade,
  start_date date, lesson_format text, agreed_rate text,
  status text not null default 'active'
    check (status in ('active','paused','completed','rematch','cancelled')),
  follow_up_date date, notes text
);

create index if not exists idx_parent_requests_status on parent_requests(status);
create index if not exists idx_tutors_status on tutors(status);
create index if not exists idx_matches_request on matches(request_id);
create index if not exists idx_matches_tutor on matches(tutor_id);
