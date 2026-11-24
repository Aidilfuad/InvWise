alter table public.support_requests
  add column notification_status text not null default 'not_sent'
    check (notification_status in ('not_sent', 'sending', 'sent', 'failed')),
  add column notification_error text,
  add column notification_sent_at timestamptz;

grant select on public.support_requests to authenticated;

create policy "Users can view their own support requests"
  on public.support_requests
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.profiles
      where profiles.id = support_requests.profile_id
        and profiles.auth_user_id = (select auth.uid())
    )
  );
