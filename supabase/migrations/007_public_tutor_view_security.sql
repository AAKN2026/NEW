-- SmartMatch Phase 3 security hardening
drop view if exists public.public_tutor_profiles;
create view public.public_tutor_profiles
with (security_invoker=true)
as
select id,full_name,subjects,levels,experience_years,lesson_formats,locations,
       hourly_rate,availability,profile
from public.tutors
where status in ('verified','active');
grant select on public.public_tutor_profiles to anon,authenticated;
