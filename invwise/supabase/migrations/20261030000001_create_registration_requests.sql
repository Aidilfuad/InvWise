create table public.registration_requests (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  employee_id text not null,
  email text not null,
  department text,
  requested_role public.user_role not null,
  status text not null default 'pending',
  created_at timestamptz not null default now(),
  constraint registration_requests_status_check
    check (status in ('pending', 'approved', 'rejected')),
  constraint registration_requests_requested_role_check
    check (requested_role::text in ('Warehouse Supervisor', 'Storekeeper'))
);

alter table public.registration_requests enable row level security;

grant insert on public.registration_requests to anon, authenticated;

create policy "Public can submit pending registration requests"
  on public.registration_requests
  for insert
  to anon, authenticated
  with check (status = 'pending');
