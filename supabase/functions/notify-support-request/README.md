# Support request email notifications

The Flutter client inserts a support request, then invokes this authenticated
Edge Function with its request ID. The function verifies that the request
belongs to the caller, sends an email through Resend, and records the
notification status. Email failure does not undo the saved support request.

Configure these Supabase Edge Function secrets:

- `RESEND_API_KEY`: API key for the Resend account.
- `SUPPORT_ADMIN_EMAIL`: administrator recipient (for example,
  `aidrusaidil@gmail.com`).
- `SUPPORT_FROM_EMAIL`: sender address verified with Resend.

`SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are provided by Supabase for
Edge Functions. Never put the service-role key or Resend key in Flutter.

Deploy after applying the database migration:

```powershell
supabase secrets set RESEND_API_KEY="re_your_key" SUPPORT_ADMIN_EMAIL="aidrusaidil@gmail.com" SUPPORT_FROM_EMAIL="InvWise Support <support@your-verified-domain.com>"
supabase functions deploy notify-support-request
```
