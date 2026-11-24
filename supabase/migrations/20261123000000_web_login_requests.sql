alter table public.registration_requests
  add column if not exists reason text;

alter table public.support_requests
  alter column profile_id drop not null,
  add column if not exists name text,
  add column if not exists email text;

grant insert on public.support_requests to anon;

drop policy if exists "Public can submit support requests"
  on public.support_requests;

create policy "Public can submit support requests"
  on public.support_requests
  for insert
  to anon
  with check (
    profile_id is null
    and status = 'open'
    and length(trim(name)) between 1 and 160
    and email ~* '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'
    and length(trim(subject)) between 1 and 160
    and length(trim(message)) between 1 and 5000
  );
