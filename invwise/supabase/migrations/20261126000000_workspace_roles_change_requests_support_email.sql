insert into public.custom_roles (name, description, scope) values
  ('Director', 'Workspace-wide operational leadership and approvals', 'All warehouses'),
  ('Factory 1 Manager', 'Factory 1 operations and team approvals', 'Factory 1'),
  ('Factory 2 Manager', 'Factory 2 operations and team approvals', 'Factory 2'),
  ('Warehouse Manager', 'Warehouse operations and team approvals', 'Assigned warehouses'),
  ('Manager', 'Department operations and team approvals', 'Assigned department'),
  ('Supervisor', 'Frontline team supervision', 'Assigned team'),
  ('Production Supervisor', 'Production floor supervision', 'Production'),
  ('Quality Assurance / QC Supervisor', 'Quality assurance and quality control', 'Quality'),
  ('Maintenance & Automation Lead', 'Equipment maintenance and automation', 'Maintenance'),
  ('Inventory Controller', 'Inventory accuracy and stock control', 'Assigned warehouses'),
  ('Viewer', 'Read-only workspace access', 'Workspace')
on conflict (name) do update
set description = excluded.description,
    scope = excluded.scope,
    is_active = true,
    updated_at = now();

insert into public.departments (name, description) values
  ('Production', 'Production planning and factory operations'),
  ('Maintenance & Automation', 'Equipment maintenance and automation'),
  ('Security & Compliance', 'Security, quality, and regulatory compliance')
on conflict (name) do nothing;

insert into public.role_permissions (role_name, permission_key, granted)
select role.name, permission.permission_key, permission.granted
from (
  values
    ('Director', 'view_dashboard', true),
    ('Director', 'view_inventory', true),
    ('Director', 'view_activity', true),
    ('Director', 'view_alerts', true),
    ('Director', 'view_reports', true),
    ('Director', 'export_reports', true),
    ('Director', 'view_telemetry', true),
    ('Director', 'manage_users', true),
    ('Director', 'manage_registration_requests', true),
    ('Director', 'manage_settings', true),
    ('Director', 'manage_departments', true),
    ('Director', 'manage_roles', true),
    ('Factory 1 Manager', 'view_dashboard', true),
    ('Factory 1 Manager', 'view_inventory', true),
    ('Factory 1 Manager', 'create_inventory', true),
    ('Factory 1 Manager', 'edit_inventory', true),
    ('Factory 1 Manager', 'adjust_stock', true),
    ('Factory 1 Manager', 'receive_stock', true),
    ('Factory 1 Manager', 'issue_stock', true),
    ('Factory 1 Manager', 'view_activity', true),
    ('Factory 1 Manager', 'view_alerts', true),
    ('Factory 1 Manager', 'view_reports', true),
    ('Factory 1 Manager', 'export_reports', true),
    ('Factory 1 Manager', 'view_telemetry', true),
    ('Factory 1 Manager', 'manage_users', true),
    ('Factory 1 Manager', 'manage_registration_requests', true),
    ('Factory 1 Manager', 'manage_settings', true),
    ('Factory 1 Manager', 'manage_warehouses', true),
    ('Factory 2 Manager', 'view_dashboard', true),
    ('Factory 2 Manager', 'view_inventory', true),
    ('Factory 2 Manager', 'create_inventory', true),
    ('Factory 2 Manager', 'edit_inventory', true),
    ('Factory 2 Manager', 'adjust_stock', true),
    ('Factory 2 Manager', 'receive_stock', true),
    ('Factory 2 Manager', 'issue_stock', true),
    ('Factory 2 Manager', 'view_activity', true),
    ('Factory 2 Manager', 'view_alerts', true),
    ('Factory 2 Manager', 'view_reports', true),
    ('Factory 2 Manager', 'export_reports', true),
    ('Factory 2 Manager', 'view_telemetry', true),
    ('Factory 2 Manager', 'manage_users', true),
    ('Factory 2 Manager', 'manage_registration_requests', true),
    ('Factory 2 Manager', 'manage_settings', true),
    ('Factory 2 Manager', 'manage_warehouses', true),
    ('Warehouse Manager', 'view_dashboard', true),
    ('Warehouse Manager', 'view_inventory', true),
    ('Warehouse Manager', 'create_inventory', true),
    ('Warehouse Manager', 'edit_inventory', true),
    ('Warehouse Manager', 'adjust_stock', true),
    ('Warehouse Manager', 'receive_stock', true),
    ('Warehouse Manager', 'issue_stock', true),
    ('Warehouse Manager', 'view_activity', true),
    ('Warehouse Manager', 'view_alerts', true),
    ('Warehouse Manager', 'view_reports', true),
    ('Warehouse Manager', 'export_reports', true),
    ('Warehouse Manager', 'view_telemetry', true),
    ('Warehouse Manager', 'manage_users', true),
    ('Warehouse Manager', 'manage_registration_requests', true),
    ('Warehouse Manager', 'manage_settings', true),
    ('Warehouse Manager', 'manage_warehouses', true),
    ('Manager', 'view_dashboard', true),
    ('Manager', 'view_inventory', true),
    ('Manager', 'create_inventory', true),
    ('Manager', 'edit_inventory', true),
    ('Manager', 'adjust_stock', true),
    ('Manager', 'receive_stock', true),
    ('Manager', 'issue_stock', true),
    ('Manager', 'view_activity', true),
    ('Manager', 'view_alerts', true),
    ('Manager', 'view_reports', true),
    ('Manager', 'export_reports', true),
    ('Manager', 'view_telemetry', true),
    ('Manager', 'manage_users', true),
    ('Manager', 'manage_registration_requests', true),
    ('Manager', 'manage_settings', true),
    ('Supervisor', 'view_dashboard', true),
    ('Supervisor', 'view_inventory', true),
    ('Supervisor', 'adjust_stock', true),
    ('Supervisor', 'receive_stock', true),
    ('Supervisor', 'issue_stock', true),
    ('Supervisor', 'view_activity', true),
    ('Supervisor', 'view_alerts', true),
    ('Supervisor', 'view_reports', true),
    ('Supervisor', 'view_telemetry', true),
    ('Production Supervisor', 'view_dashboard', true),
    ('Production Supervisor', 'view_inventory', true),
    ('Production Supervisor', 'adjust_stock', true),
    ('Production Supervisor', 'receive_stock', true),
    ('Production Supervisor', 'issue_stock', true),
    ('Production Supervisor', 'view_activity', true),
    ('Production Supervisor', 'view_alerts', true),
    ('Production Supervisor', 'view_reports', true),
    ('Production Supervisor', 'view_telemetry', true),
    ('Quality Assurance / QC Supervisor', 'view_dashboard', true),
    ('Quality Assurance / QC Supervisor', 'view_inventory', true),
    ('Quality Assurance / QC Supervisor', 'view_activity', true),
    ('Quality Assurance / QC Supervisor', 'view_alerts', true),
    ('Quality Assurance / QC Supervisor', 'view_reports', true),
    ('Quality Assurance / QC Supervisor', 'export_reports', true),
    ('Quality Assurance / QC Supervisor', 'view_telemetry', true),
    ('Maintenance & Automation Lead', 'view_dashboard', true),
    ('Maintenance & Automation Lead', 'view_inventory', true),
    ('Maintenance & Automation Lead', 'view_activity', true),
    ('Maintenance & Automation Lead', 'view_alerts', true),
    ('Maintenance & Automation Lead', 'view_reports', true),
    ('Maintenance & Automation Lead', 'view_telemetry', true),
    ('Maintenance & Automation Lead', 'manage_telemetry_thresholds', true),
    ('Inventory Controller', 'view_dashboard', true),
    ('Inventory Controller', 'view_inventory', true),
    ('Inventory Controller', 'create_inventory', true),
    ('Inventory Controller', 'edit_inventory', true),
    ('Inventory Controller', 'adjust_stock', true),
    ('Inventory Controller', 'receive_stock', true),
    ('Inventory Controller', 'issue_stock', true),
    ('Inventory Controller', 'view_activity', true),
    ('Inventory Controller', 'view_alerts', true),
    ('Inventory Controller', 'view_reports', true),
    ('Inventory Controller', 'export_reports', true),
    ('Inventory Controller', 'view_telemetry', true),
    ('Warehouse Supervisor', 'view_dashboard', true),
    ('Warehouse Supervisor', 'view_inventory', true),
    ('Warehouse Supervisor', 'adjust_stock', true),
    ('Warehouse Supervisor', 'receive_stock', true),
    ('Warehouse Supervisor', 'issue_stock', true),
    ('Warehouse Supervisor', 'view_activity', true),
    ('Warehouse Supervisor', 'view_alerts', true),
    ('Warehouse Supervisor', 'view_reports', true),
    ('Warehouse Supervisor', 'export_reports', true),
    ('Warehouse Supervisor', 'view_telemetry', true),
    ('Warehouse Supervisor', 'manage_warehouses', true),
    ('Storekeeper', 'view_dashboard', true),
    ('Storekeeper', 'view_inventory', true),
    ('Storekeeper', 'adjust_stock', true),
    ('Storekeeper', 'receive_stock', true),
    ('Storekeeper', 'issue_stock', true),
    ('Storekeeper', 'view_activity', true),
    ('Storekeeper', 'view_alerts', true),
    ('Storekeeper', 'view_reports', true),
    ('Storekeeper', 'view_telemetry', true),
    ('Viewer', 'view_dashboard', true),
    ('Viewer', 'view_inventory', true),
    ('Viewer', 'view_activity', true),
    ('Viewer', 'view_alerts', true),
    ('Viewer', 'view_reports', true),
    ('Viewer', 'view_telemetry', true),
    ('Viewer', 'manage_settings', true)
) as permission(role_name, permission_key, granted)
join public.custom_roles as role on role.name = permission.role_name
on conflict (role_name, permission_key)
do update set granted = excluded.granted, updated_at = now();

alter table public.profiles
  add column if not exists department text;

alter table public.app_settings
  add column if not exists support_email text not null default 'aidrusaidil@gmail.com';

grant select on public.app_settings to authenticated;
grant update (support_email, updated_at)
  on public.app_settings to authenticated;

create table if not exists public.profile_change_requests (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  profile_name text not null,
  previous_role text not null,
  requested_role text not null,
  current_department text,
  requested_department text,
  reason text not null,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected')),
  created_at timestamptz not null default now(),
  reviewed_at timestamptz,
  reviewed_by uuid references public.profiles(id) on delete set null,
  review_note text,
  constraint profile_change_requests_reason_length
    check (length(btrim(reason)) between 1 and 1000)
);

create index if not exists profile_change_requests_profile_created_idx
  on public.profile_change_requests(profile_id, created_at desc);
create index if not exists profile_change_requests_pending_created_idx
  on public.profile_change_requests(created_at)
  where status = 'pending';

create or replace function public.can_review_profile_change_requests()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
      from public.profiles as profile
     where profile.auth_user_id = (select auth.uid())
       and profile.is_active is true
       and lower(trim(replace(coalesce(profile.role::text, ''), '_', ' '))) in (
         'manager',
         'factory 1 manager',
         'factory 2 manager',
         'warehouse manager',
         'director',
         'super admin'
       )
  );
$$;

alter table public.profile_change_requests enable row level security;
revoke all on public.profile_change_requests from public, anon, authenticated;
grant select on public.profile_change_requests to authenticated;

drop policy if exists "Users and managers can view profile change requests"
  on public.profile_change_requests;
create policy "Users and managers can view profile change requests"
  on public.profile_change_requests for select to authenticated
  using (
    exists (
      select 1
        from public.profiles as requester
       where requester.id = profile_change_requests.profile_id
         and requester.auth_user_id = (select auth.uid())
    )
    or public.can_review_profile_change_requests()
  );

create or replace function public.submit_profile_change_request(
  p_requested_role text default null,
  p_requested_department text default null,
  p_reason text default ''
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_profile public.profiles%rowtype;
  v_role text;
  v_department text;
  v_request_id uuid;
begin
  select *
    into v_profile
    from public.profiles
   where auth_user_id = (select auth.uid())
     and is_active is true
   for update;
  if not found then
    raise exception 'an active workspace profile is required';
  end if;

  v_role := coalesce(nullif(btrim(p_requested_role), ''), v_profile.role::text);
  v_department := coalesce(nullif(btrim(p_requested_department), ''), v_profile.department);
  if lower(trim(replace(v_role, '_', ' '))) = 'super admin' then
    raise exception 'Super Admin cannot be requested through this form';
  end if;
  if v_role is distinct from v_profile.role::text
     and not exists (
       select 1 from public.custom_roles
        where name = v_role and is_active is true
     ) then
    raise exception 'select an active workspace role';
  end if;
  if v_department is distinct from v_profile.department
     and not exists (
       select 1 from public.departments
        where name = v_department and is_active is true
     ) then
    raise exception 'select an active workspace department';
  end if;
  if v_role is not distinct from v_profile.role::text
     and v_department is not distinct from v_profile.department then
    raise exception 'select a different role or department';
  end if;
  if length(btrim(coalesce(p_reason, ''))) not between 1 and 1000 then
    raise exception 'provide a reason between 1 and 1000 characters';
  end if;

  insert into public.profile_change_requests (
    profile_id, profile_name, previous_role, requested_role, current_department,
    requested_department, reason
  ) values (
    v_profile.id, coalesce(v_profile.full_name, 'Workspace user'),
    v_profile.role::text, v_role, v_profile.department,
    v_department, btrim(p_reason)
  )
  returning id into v_request_id;
  return v_request_id;
end;
$$;

create or replace function public.review_profile_change_request(
  p_request_id uuid,
  p_decision text,
  p_review_note text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor public.profiles%rowtype;
  v_request public.profile_change_requests%rowtype;
begin
  select *
    into v_actor
    from public.profiles
   where auth_user_id = (select auth.uid())
     and is_active is true
   for update;
  if not found or not public.can_review_profile_change_requests() then
    raise exception 'Manager role or above is required to review profile changes';
  end if;
  if p_decision not in ('approved', 'rejected') then
    raise exception 'decision must be approved or rejected';
  end if;
  if length(coalesce(p_review_note, '')) > 1000 then
    raise exception 'review note must be 1000 characters or fewer';
  end if;

  select *
    into v_request
    from public.profile_change_requests
   where id = p_request_id
     and status = 'pending'
   for update;
  if not found then
    raise exception 'profile change request is no longer pending';
  end if;
  if v_request.profile_id = v_actor.id then
    raise exception 'you cannot review your own profile change request';
  end if;

  if p_decision = 'approved' then
    update public.profiles
       set role = v_request.requested_role,
           department = v_request.requested_department
     where id = v_request.profile_id
       and is_active is true;
    if not found then
      raise exception 'requesting profile is no longer active';
    end if;
  end if;

  update public.profile_change_requests
     set status = p_decision,
         reviewed_at = now(),
         reviewed_by = v_actor.id,
         review_note = nullif(btrim(coalesce(p_review_note, '')), '')
   where id = v_request.id;
end;
$$;

revoke all on function public.can_review_profile_change_requests()
  from public, anon;
grant execute on function public.can_review_profile_change_requests()
  to authenticated;
revoke all on function public.submit_profile_change_request(text, text, text)
  from public, anon;
grant execute on function public.submit_profile_change_request(text, text, text)
  to authenticated;
revoke all on function public.review_profile_change_request(uuid, text, text)
  from public, anon;
grant execute on function public.review_profile_change_request(uuid, text, text)
  to authenticated;

grant insert, update on public.registration_requests to service_role;
revoke insert on public.registration_requests from anon;

drop policy if exists "Authenticated users can submit pending registration requests"
  on public.registration_requests;
drop policy if exists "Public can submit pending registration requests"
  on public.registration_requests;
drop policy if exists "Workspace members can submit pending registration requests"
  on public.registration_requests;
create policy "Workspace members can submit pending registration requests"
  on public.registration_requests for insert to authenticated
  with check (
    status = 'pending'
    and approved_at is null
    and approved_by is null
    and exists (
      select 1
        from public.profiles as profile
       where profile.auth_user_id = (select auth.uid())
         and profile.is_active is true
    )
  );

notify pgrst, 'reload schema';
