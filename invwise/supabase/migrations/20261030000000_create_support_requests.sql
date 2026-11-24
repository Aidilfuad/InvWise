create table public.support_requests (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id),
  subject text not null,
  message text not null,
  status text not null default 'open',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index support_requests_profile_created_at_idx
  on public.support_requests (profile_id, created_at desc);

alter table public.support_requests enable row level security;

grant insert on public.support_requests to authenticated;

create policy "Users can create support requests for their own profile"
  on public.support_requests
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.profiles
      where profiles.id = support_requests.profile_id
        and profiles.auth_user_id = (select auth.uid())
    )
  );
