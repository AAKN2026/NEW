-- Tutor Match production schema for Supabase/Postgres
create extension if not exists pgcrypto;

create table if not exists public.parent_requests (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  parent_name text not null,
  whatsapp text not null,
  student_level text not null,
  subject text not null,
  lesson_format text,
  budget text,
  location text,
  preferred_schedule text,
  requirements text,
  consent boolean not null default false,
  status text not null default 'new' check (status in ('new','contacted','matching','shortlisted','trial','confirmed','follow-up','rematch','closed'))
);

create table if not exists public.tutors (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  full_name text not null,
  whatsapp text not null,
  subjects text[] not null default '{}',
  levels text[] not null default '{}',
  experience_years numeric,
  lesson_formats text[] not null default '{}',
  locations text[] not null default '{}',
  hourly_rate text,
  availability text,
  qualifications text,
  profile text,
  status text not null default 'pending' check (status in ('pending','verified','active','paused','inactive'))
);

create table if not exists public.matches (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  request_id uuid not null references public.parent_requests(id) on delete cascade,
  tutor_id uuid not null references public.tutors(id) on delete cascade,
  match_score numeric not null default 0,
  score_breakdown jsonb not null default '{}'::jsonb,
  notes text,
  status text not null default 'shortlisted' check (status in ('shortlisted','contacted','accepted','declined','trial','confirmed','closed'))
);

create table if not exists public.placements (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  request_id uuid not null references public.parent_requests(id) on delete cascade,
  tutor_id uuid not null references public.tutors(id) on delete cascade,
  start_date date,
  lesson_format text,
  agreed_rate text,
  status text not null default 'active' check (status in ('active','paused','completed','rematch','cancelled')),
  follow_up_date date,
  notes text
);

create index if not exists idx_parent_requests_status on public.parent_requests(status);
create index if not exists idx_parent_requests_created on public.parent_requests(created_at desc);
create index if not exists idx_tutors_status on public.tutors(status);
create index if not exists idx_matches_request on public.matches(request_id);
create index if not exists idx_matches_tutor on public.matches(tutor_id);

alter table public.parent_requests enable row level security;
alter table public.tutors enable row level security;
alter table public.matches enable row level security;
alter table public.placements enable row level security;

-- Public visitors may submit a request, but may not read existing requests.
drop policy if exists "public_create_parent_request" on public.parent_requests;
create policy "public_create_parent_request" on public.parent_requests
for insert to anon, authenticated with check (consent = true);

-- Public visitors may submit tutor applications, but tutor records are not public.
drop policy if exists "public_create_tutor" on public.tutors;
create policy "public_create_tutor" on public.tutors
for insert to anon, authenticated with check (status = 'pending');

-- Admin users: add their UUIDs to this table after enabling Supabase Auth.
create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.admin_users enable row level security;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path=public
as $$ select exists(select 1 from public.admin_users where user_id=auth.uid()); $$;

drop policy if exists "admins_read_requests" on public.parent_requests;
create policy "admins_read_requests" on public.parent_requests for select to authenticated using (public.is_admin());
drop policy if exists "admins_update_requests" on public.parent_requests;
create policy "admins_update_requests" on public.parent_requests for update to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "admins_read_tutors" on public.tutors;
create policy "admins_read_tutors" on public.tutors for select to authenticated using (public.is_admin());
drop policy if exists "admins_update_tutors" on public.tutors;
create policy "admins_update_tutors" on public.tutors for update to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "admins_matches" on public.matches;
create policy "admins_matches" on public.matches for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "admins_placements" on public.placements;
create policy "admins_placements" on public.placements for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "admins_admin_users" on public.admin_users;
create policy "admins_admin_users" on public.admin_users for select to authenticated using (public.is_admin());

-- Matching score: subject 35, level 20, format 15, location 15, budget 10, availability 5.
create or replace function public.calculate_match_score(
  p_subject text, p_level text, p_format text, p_location text,
  p_budget text, p_schedule text, t_subjects text[], t_levels text[],
  t_formats text[], t_locations text[], t_rate text, t_availability text
) returns numeric language plpgsql immutable as $$
declare score numeric := 0;
begin
  if exists(select 1 from unnest(coalesce(t_subjects,'{}')) x where lower(x)=lower(p_subject)) then score:=score+35; end if;
  if exists(select 1 from unnest(coalesce(t_levels,'{}')) x where lower(x)=lower(p_level)) then score:=score+20; end if;
  if p_format is null or p_format='' or exists(select 1 from unnest(coalesce(t_formats,'{}')) x where lower(x)=lower(p_format) or lower(x)='both') then score:=score+15; end if;
  if p_location is null or p_location='' or exists(select 1 from unnest(coalesce(t_locations,'{}')) x where lower(p_location) like '%'||lower(x)||'%' or lower(x) like '%'||lower(p_location)||'%') then score:=score+15; end if;
  if p_budget is null or p_budget='' or t_rate is null or t_rate='' or lower(t_rate) like '%'||lower(p_budget)||'%' then score:=score+10; end if;
  if p_schedule is null or p_schedule='' or t_availability is null or lower(t_availability) like '%'||lower(p_schedule)||'%' then score:=score+5; end if;
  return score;
end; $$;

create or replace function public.generate_matches(p_request_id uuid)
returns table(match_id uuid,tutor_id uuid,tutor_name text,match_score numeric,score_breakdown jsonb)
language sql security definer set search_path=public as $$
  insert into public.matches(request_id,tutor_id,match_score,score_breakdown)
  select r.id,t.id,
    public.calculate_match_score(r.subject,r.student_level,r.lesson_format,r.location,r.budget,r.preferred_schedule,t.subjects,t.levels,t.lesson_formats,t.locations,t.hourly_rate,t.availability),
    jsonb_build_object('subject',case when exists(select 1 from unnest(t.subjects) x where lower(x)=lower(r.subject)) then 35 else 0 end,
      'level',case when exists(select 1 from unnest(t.levels) x where lower(x)=lower(r.student_level)) then 20 else 0 end,
      'format',case when r.lesson_format is null or r.lesson_format='' or exists(select 1 from unnest(t.lesson_formats) x where lower(x)=lower(r.lesson_format) or lower(x)='both') then 15 else 0 end,
      'location',case when r.location is null or r.location='' then 15 else 0 end)
  from public.parent_requests r cross join public.tutors t
  where r.id=p_request_id and t.status in ('verified','active')
    and public.calculate_match_score(r.subject,r.student_level,r.lesson_format,r.location,r.budget,r.preferred_schedule,t.subjects,t.levels,t.lesson_formats,t.locations,t.hourly_rate,t.availability) >= 40
    and not exists(select 1 from public.matches m where m.request_id=r.id and m.tutor_id=t.id);
  return query
  select m.id,m.tutor_id,t.full_name,m.match_score,m.score_breakdown
  from public.matches m join public.tutors t on t.id=m.tutor_id
  where m.request_id=p_request_id order by m.match_score desc, m.created_at desc;
$$;
