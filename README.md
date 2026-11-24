# InvWise web

InvWise web is a React, Vite, Tailwind CSS, and Supabase client for the inventory workspace login and authentication flow.

## Local development

1. Install dependencies with `npm install`.
2. Copy `.env.example` to `.env` and set `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`.
3. Apply the Supabase migrations in `invwise/supabase/migrations` to the connected project.
4. Start Vite with `npm run dev`.

Run `npm run build` to create the production bundle and `npm run lint` to lint the workspace.

Email login uses Supabase Auth. Employee ID login resolves the account through the `resolve_login_email_by_employee_id` RPC used by the Flutter app. The `/dashboard` route verifies the linked profile is active before rendering.
