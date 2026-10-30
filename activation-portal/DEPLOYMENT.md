# InvWise Account Activation Portal

## Local development

1. Copy `.env.example` to `.env.local`.
2. Set `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY` to the public
   Supabase project URL and publishable key. Never use a service-role key in
   this app.
3. From this directory, run:

   ```powershell
   npm install
   npm run dev
   ```

4. For local invitation testing, set the Supabase Auth redirect allowlist and
   the Edge Function `INVITE_REDIRECT_URL` to the Vite URL shown in the
   terminal (normally `http://localhost:5173`).

## Deploy to Vercel

1. Push the repository to the Git provider connected to Vercel.
2. Create a Vercel project and select this repository.
3. Set **Root Directory** to `activation-portal`.
4. Use the Vite defaults, or specify:
   - Framework preset: **Vite**
   - Build command: `npm run build`
   - Output directory: `dist`
   - Install command: `npm install`
5. Add these Vercel environment variables for Production (and Preview if
   desired):
   - `VITE_SUPABASE_URL` — the Supabase project URL
   - `VITE_SUPABASE_PUBLISHABLE_KEY` — the public publishable key
6. Deploy and assign the stable production domain
   `https://invwise-activation.vercel.app` to the Vercel project. If you choose a
   different domain, use that exact URL in the next steps.
7. In Supabase **Authentication → URL Configuration**:
   - Set **Site URL** to `https://invwise-activation.vercel.app`.
   - Add `https://invwise-activation.vercel.app` to **Redirect URLs**.
   - Remove obsolete `http://localhost:3000` entries when they are no longer
     needed. Keep local development URLs only if you still test locally.
8. Set the provisioning Edge Function redirect secret to the same activation
   URL:

   ```powershell
   supabase secrets set INVITE_REDIRECT_URL='https://invwise-activation.vercel.app' --project-ref avpgjbhgiuhowsdpwbms
   ```

   Replace the URL if the Vercel production domain differs. The deployed
   `provision-approved-registration` function uses this secret as `redirectTo`
   when it sends invitation emails.
9. Redeploy the provisioning function if needed, then trigger a new test
   invitation. Old invitation emails keep their original redirect URL; send a
   new invitation to test the updated destination.

## Invitation flow

Supabase verifies the invitation link and redirects its session tokens to this
portal. The portal accepts either the standard Supabase invitation URL fragment
or a `token_hash` invitation URL, lets the invitee choose and confirm a strong
password, signs in with that password, and calls the JWT-protected
`complete-registration-setup` function. That function marks the request
completed. The portal then displays:

> Account activated successfully. You may now log in to InvWise.

The portal does not use or expose a Supabase service-role key and does not
modify registration or approval records directly.
