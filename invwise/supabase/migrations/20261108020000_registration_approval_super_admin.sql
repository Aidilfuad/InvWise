drop policy if exists "Inventory administrators can view registration requests"
  on public.registration_requests;
create policy "Administrators can view registration requests"
  on public.registration_requests
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.profiles
      where profiles.auth_user_id = (select auth.uid())
        and profiles.role::text in (
          'Inventory Administrator',
          'Super Admin'
        )
        and profiles.is_active is true
    )
  );

drop policy if exists "Inventory administrators can update pending requests"
  on public.registration_requests;
create policy "Administrators can update pending requests"
  on public.registration_requests
  for update
  to authenticated
  using (
    status = 'pending'
    and exists (
      select 1
      from public.profiles
      where profiles.auth_user_id = (select auth.uid())
        and profiles.role::text in (
          'Inventory Administrator',
          'Super Admin'
        )
        and profiles.is_active is true
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
        and profiles.role::text in (
          'Inventory Administrator',
          'Super Admin'
        )
        and profiles.is_active is true
    )
  );
