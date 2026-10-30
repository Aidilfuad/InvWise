alter table public.registration_requests
  add column approved_at timestamptz,
  add column approved_by uuid references public.profiles(id);

grant select on public.registration_requests to authenticated;
grant update (status, approved_at, approved_by)
  on public.registration_requests to authenticated;

drop policy "Public can submit pending registration requests"
  on public.registration_requests;

create policy "Public can submit pending registration requests"
  on public.registration_requests
  for insert
  to anon, authenticated
  with check (
    status = 'pending'
    and approved_at is null
    and approved_by is null
  );

create policy "Inventory administrators can view registration requests"
  on public.registration_requests
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.profiles
      where profiles.auth_user_id = (select auth.uid())
        and profiles.role::text = 'Inventory Administrator'
    )
  );

create policy "Inventory administrators can update pending requests"
  on public.registration_requests
  for update
  to authenticated
  using (
    status = 'pending'
    and exists (
      select 1
      from public.profiles
      where profiles.auth_user_id = (select auth.uid())
        and profiles.role::text = 'Inventory Administrator'
    )
  )
  with check (
    status in ('approved', 'rejected')
    and approved_at is not null
    and approved_by is not null
    and exists (
      select 1
      from public.profiles
      where profiles.auth_user_id = (select auth.uid())
        and profiles.id = registration_requests.approved_by
        and profiles.role::text = 'Inventory Administrator'
    )
  );
