# Tutor Match production backend setup

The repository contains the Supabase schema, Edge Functions, public forms and authenticated admin UI.

## One-time connection
1. Create or connect a Supabase project.
2. Run supabase/migrations/001_tutor_match.sql in the SQL editor.
3. Enable Email/Password authentication.
4. Create the admin user in Supabase Auth.
5. Insert that user's UUID into public.admin_users.
6. Deploy create-parent-request, create-tutor and generate-matches.
7. Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY as server-side secrets for the functions.
8. Put the public project URL and public anon key into root config.js.
9. Open admin/login.html and sign in.

## Live workflow
Parent form -> create-parent-request -> parent_requests -> Admin -> Generate Matches -> matches -> WhatsApp parent/tutor -> Trial -> Confirmed -> placements -> Follow-up -> Rematch.

## Security
Never place the service-role key in config.js, HTML or GitHub. Public pages can submit but cannot read parent/tutor records. Admin reads and updates are protected by is_admin(). Keep real parent/tutor data out of public HTML.
