-- SmartMatch Phase 2: live public tutor profiles and specific tutor requests
alter table public.parent_requests
  add column if not exists requested_tutor_id uuid references public.tutors(id) on delete set null;

create index if not exists parent_requests_requested_tutor_idx
  on public.parent_requests(requested_tutor_id);

drop view if exists public.public_tutor_profiles;
create view public.public_tutor_profiles as
select id,full_name,subjects,levels,experience_years,lesson_formats,locations,
       hourly_rate,availability,qualifications,profile
from public.tutors
where status in ('verified','active');

grant select on public.public_tutor_profiles to anon,authenticated;