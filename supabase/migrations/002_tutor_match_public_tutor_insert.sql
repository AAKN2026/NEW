create policy "public can submit tutor applications" on public.tutors for insert to anon with check (status = 'pending');
grant insert on public.tutors to anon;

create or replace function public.set_updated_at() returns trigger language plpgsql set search_path=public as $$ begin new.updated_at=now(); return new; end $$;
create index matches_tutor_id_idx on public.matches(tutor_id);
create index placements_request_id_idx on public.placements(request_id);
create index placements_tutor_id_idx on public.placements(tutor_id);