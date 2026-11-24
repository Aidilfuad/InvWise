-- Drop every existing RLS policy that reads profiles.role before changing
-- profiles.role (or registration_requests.requested_role) away from an enum.
do $$
begin
  if to_regclass('public.app_settings') is not null then
    execute 'drop policy if exists "Super Admins can update app currency settings" on public.app_settings';
  end if;
end
$$;

do $$
begin
  if to_regclass('public.registration_requests') is not null then
    execute 'drop policy if exists "Inventory administrators can view registration requests" on public.registration_requests';
    execute 'drop policy if exists "Inventory administrators can update pending requests" on public.registration_requests';
    execute 'drop policy if exists "Administrators can view registration requests" on public.registration_requests';
    execute 'drop policy if exists "Administrators can update pending requests" on public.registration_requests';
  end if;
end
$$;

do $$
begin
  if to_regclass('public.inventory_items') is not null then
    execute 'drop policy if exists "Active users can read inventory items" on public.inventory_items';
    execute 'drop policy if exists "Inventory administrators can create inventory items" on public.inventory_items';
    execute 'drop policy if exists "Active users can update inventory items" on public.inventory_items';
  end if;
end
$$;

create table if not exists public.departments (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint departments_name_check check (length(trim(name)) between 1 and 100),
  constraint departments_name_key unique (name)
);

create table if not exists public.custom_roles (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  scope text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint custom_roles_name_check check (length(trim(name)) between 1 and 100),
  constraint custom_roles_name_key unique (name)
);

create table if not exists public.role_permissions (
  role_name text not null,
  permission_key text not null,
  granted boolean not null default false,
  updated_at timestamptz not null default now(),
  primary key (role_name, permission_key)
);

insert into public.departments (name, description) values
  ('Warehouse Operations', 'Warehouse and receiving operations'),
  ('Inventory Control', 'Inventory accuracy and stock control'),
  ('Telemetry & Maintenance', 'Telemetry, equipment, and maintenance'),
  ('Logistics & Distribution', 'Logistics and distribution operations'),
  ('Quality & Compliance', 'Quality assurance and compliance'),
  ('Administration', 'Administrative operations')
on conflict (name) do nothing;

insert into public.custom_roles (name, description, scope) values
  ('Super Admin', 'Full system administration', 'All warehouses'),
  ('Inventory Administrator', 'Inventory and workspace administration', 'All warehouses'),
  ('Warehouse Supervisor', 'Warehouse supervision and operations', 'Assigned warehouses'),
  ('Storekeeper', 'Day-to-day stock handling', 'Assigned warehouses')
on conflict (name) do nothing;

do $$
declare
  v_profile_role_type text;
begin
  select data_type
    into v_profile_role_type
    from information_schema.columns
   where table_schema = 'public'
     and table_name = 'profiles'
     and column_name = 'role';
  if v_profile_role_type is not null
     and v_profile_role_type <> 'text' then
    execute 'alter table public.profiles alter column role type text using role::text';
  end if;
end
$$;

do $$
declare
  v_requested_role_type text;
begin
  select data_type
    into v_requested_role_type
    from information_schema.columns
   where table_schema = 'public'
     and table_name = 'registration_requests'
     and column_name = 'requested_role';
  if v_requested_role_type is not null
     and v_requested_role_type <> 'text' then
    execute 'alter table public.registration_requests alter column requested_role type text using requested_role::text';
  end if;
end
$$;
alter table public.registration_requests
  drop constraint if exists registration_requests_requested_role_check;

insert into public.role_permissions (role_name, permission_key, granted)
select r.name, p.permission_key, r.name = 'Super Admin'
from public.custom_roles r
cross join (
  values
    ('view_dashboard'), ('view_inventory'), ('create_inventory'), ('edit_inventory'),
    ('delete_inventory'), ('adjust_stock'), ('receive_stock'), ('issue_stock'),
    ('view_activity'), ('view_alerts'), ('view_reports'), ('export_reports'),
    ('view_telemetry'), ('manage_telemetry_thresholds'),
    ('manage_users'), ('manage_registration_requests'),
    ('manage_settings'), ('manage_departments'), ('manage_roles'),
    ('manage_categories'), ('manage_units'), ('manage_warehouses')
) as p(permission_key)
on conflict (role_name, permission_key) do nothing;

update public.role_permissions set granted = true
where (role_name = 'Inventory Administrator' and permission_key in (
  'view_dashboard','view_inventory','create_inventory','edit_inventory','adjust_stock',
  'receive_stock','issue_stock','view_activity','view_alerts','view_reports','export_reports',
  'view_telemetry','manage_users','manage_registration_requests','manage_settings',
  'manage_categories','manage_units','manage_warehouses'
))
or (role_name = 'Warehouse Supervisor' and permission_key in (
  'view_dashboard','view_inventory','adjust_stock','receive_stock','issue_stock',
  'view_activity','view_alerts','view_reports','export_reports','view_telemetry',
  'manage_warehouses'
))
or (role_name = 'Storekeeper' and permission_key in (
  'view_dashboard','view_inventory','adjust_stock','receive_stock','issue_stock','view_alerts'
));

alter table public.departments enable row level security;
alter table public.custom_roles enable row level security;
alter table public.role_permissions enable row level security;

grant select on public.departments to anon, authenticated;
grant select on public.custom_roles to anon, authenticated;
grant select on public.role_permissions to authenticated;

create or replace function public.is_active_super_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where auth_user_id = auth.uid()
      and lower(trim(replace(coalesce(role::text, ''), '_', ' '))) = 'super admin'
      and is_active is true
  );
$$;

revoke all on function public.is_active_super_admin() from public, anon, authenticated;
grant execute on function public.is_active_super_admin() to authenticated;

do $$
begin
  if to_regclass('public.app_settings') is not null then
    execute $policy$
      create policy "Super Admins can update app currency settings"
      on public.app_settings for update
      to authenticated
      using (
        exists (
          select 1
          from public.profiles
          where profiles.auth_user_id = (select auth.uid())
            and lower(trim(replace(coalesce(profiles.role::text, ''), '_', ' '))) = 'super admin'
            and profiles.is_active is true
        )
      )
      with check (
        exists (
          select 1
          from public.profiles
          where profiles.auth_user_id = (select auth.uid())
            and lower(trim(replace(coalesce(profiles.role::text, ''), '_', ' '))) = 'super admin'
            and profiles.is_active is true
        )
      )
    $policy$;
  end if;
end
$$;

do $$
begin
  if to_regclass('public.registration_requests') is not null then
    execute $policy$
      create policy "Administrators can view registration requests"
      on public.registration_requests
      for select
      to authenticated
      using (
        exists (
          select 1
          from public.profiles
          where profiles.auth_user_id = (select auth.uid())
            and profiles.is_active is true
            and (
              lower(trim(replace(coalesce(profiles.role::text, ''), '_', ' '))) in ('inventory administrator', 'super admin')
              or exists (
                select 1
                from public.role_permissions rp
                where rp.role_name = profiles.role::text
                  and rp.permission_key = 'manage_registration_requests'
                  and rp.granted is true
              )
            )
        )
      )
    $policy$;
    execute $policy$
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
            and profiles.is_active is true
            and (
              lower(trim(replace(coalesce(profiles.role::text, ''), '_', ' '))) in ('inventory administrator', 'super admin')
              or exists (
                select 1
                from public.role_permissions rp
                where rp.role_name = profiles.role::text
                  and rp.permission_key = 'manage_registration_requests'
                  and rp.granted is true
              )
            )
        )
      )
      with check (
        status in ('approved', 'rejected')
        and approved_at is not null
        and approved_by is not null
        and exists (
          select 1
          from public.profiles
          where profiles.id = registration_requests.approved_by
            and profiles.auth_user_id = (select auth.uid())
            and profiles.is_active is true
            and (
              lower(trim(replace(coalesce(profiles.role::text, ''), '_', ' '))) in ('inventory administrator', 'super admin')
              or exists (
                select 1
                from public.role_permissions rp
                where rp.role_name = profiles.role::text
                  and rp.permission_key = 'manage_registration_requests'
                  and rp.granted is true
              )
            )
        )
      )
    $policy$;
  end if;
end
$$;

do $$
begin
  if to_regclass('public.inventory_items') is not null then
    execute $policy$
      create policy "Active users can read inventory items"
      on public.inventory_items
      for select
      to authenticated
      using (
        exists (
          select 1
          from public.profiles p
          where p.auth_user_id = (select auth.uid())
            and p.is_active is true
            and (
              lower(trim(replace(coalesce(p.role::text, ''), '_', ' '))) in
                ('super admin', 'inventory administrator', 'warehouse supervisor', 'storekeeper')
              or exists (
                select 1
                from public.custom_roles cr
                where cr.name = p.role::text
                  and cr.is_active is true
              )
            )
        )
      )
    $policy$;
    execute $policy$
      create policy "Inventory administrators can create inventory items"
      on public.inventory_items
      for insert
      to authenticated
      with check (
        exists (
          select 1
          from public.profiles p
          where p.auth_user_id = (select auth.uid())
            and p.is_active is true
            and (
              lower(trim(replace(coalesce(p.role::text, ''), '_', ' '))) in ('super admin', 'inventory administrator')
              or exists (
                select 1
                from public.role_permissions rp
                where rp.role_name = p.role::text
                  and rp.permission_key = 'create_inventory'
                  and rp.granted is true
              )
            )
        )
      )
    $policy$;
    execute $policy$
      create policy "Active users can update inventory items"
      on public.inventory_items
      for update
      to authenticated
      using (
        exists (
          select 1
          from public.profiles p
          where p.auth_user_id = (select auth.uid())
            and p.is_active is true
            and (
              lower(trim(replace(coalesce(p.role::text, ''), '_', ' '))) in
                ('super admin', 'inventory administrator', 'warehouse supervisor', 'storekeeper')
              or exists (
                select 1
                from public.role_permissions rp
                where rp.role_name = p.role::text
                  and rp.permission_key in ('edit_inventory', 'adjust_stock')
                  and rp.granted is true
              )
            )
        )
      )
      with check (
        exists (
          select 1
          from public.profiles p
          where p.auth_user_id = (select auth.uid())
            and p.is_active is true
            and (
              lower(trim(replace(coalesce(p.role::text, ''), '_', ' '))) in
                ('super admin', 'inventory administrator', 'warehouse supervisor', 'storekeeper')
              or exists (
                select 1
                from public.role_permissions rp
                where rp.role_name = p.role::text
                  and rp.permission_key in ('edit_inventory', 'adjust_stock')
                  and rp.granted is true
              )
            )
        )
      )
    $policy$;
  end if;
end
$$;

drop policy if exists "Super Admins manage departments" on public.departments;
create policy "Super Admins manage departments"
  on public.departments for all to authenticated
  using (public.is_active_super_admin())
  with check (public.is_active_super_admin());

drop policy if exists "Anyone can read active departments" on public.departments;
create policy "Anyone can read active departments"
  on public.departments for select
  to anon, authenticated
  using (is_active is true);

drop policy if exists "Super Admins manage roles" on public.custom_roles;
create policy "Super Admins manage roles"
  on public.custom_roles for all to authenticated
  using (public.is_active_super_admin())
  with check (public.is_active_super_admin());

drop policy if exists "Anyone can read active roles" on public.custom_roles;
create policy "Anyone can read active roles"
  on public.custom_roles for select
  to anon, authenticated
  using (is_active is true);

drop policy if exists "Super Admins manage role permissions" on public.role_permissions;
create policy "Super Admins manage role permissions"
  on public.role_permissions for all to authenticated
  using (public.is_active_super_admin())
  with check (public.is_active_super_admin());

drop policy if exists "Authenticated users can read role permissions" on public.role_permissions;
create policy "Authenticated users can read role permissions"
  on public.role_permissions for select
  to authenticated
  using (true);

create or replace function public.upsert_workspace_role(
  p_name text,
  p_description text default null,
  p_scope text default null,
  p_is_active boolean default true
)
returns public.custom_roles
language plpgsql
security definer
set search_path = ''
as $$
declare v_role public.custom_roles%rowtype;
begin
  if not public.is_active_super_admin() then raise exception 'only an active Super Admin can manage roles'; end if;
  if length(trim(p_name)) not between 1 and 100 then raise exception 'role name is required'; end if;
  insert into public.custom_roles(name, description, scope, is_active)
  values (trim(p_name), nullif(trim(coalesce(p_description, '')), ''), nullif(trim(coalesce(p_scope, '')), ''), p_is_active)
  on conflict (name) do update set
    description = excluded.description,
    scope = excluded.scope,
    is_active = excluded.is_active,
    updated_at = now()
  returning * into v_role;
  insert into public.role_permissions(role_name, permission_key, granted)
  select v_role.name, p.permission_key, false
  from (values
    ('view_dashboard'), ('view_inventory'), ('create_inventory'), ('edit_inventory'),
    ('delete_inventory'), ('adjust_stock'), ('receive_stock'), ('issue_stock'),
    ('view_activity'), ('view_alerts'), ('view_reports'), ('export_reports'),
    ('view_telemetry'), ('manage_telemetry_thresholds'), ('manage_users'),
    ('manage_registration_requests'), ('manage_settings'), ('manage_departments'),
    ('manage_roles'), ('manage_categories'), ('manage_units'), ('manage_warehouses')
  ) p(permission_key)
  on conflict do nothing;
  return v_role;
end;
$$;

create or replace function public.upsert_workspace_department(
  p_name text,
  p_description text default null,
  p_is_active boolean default true
)
returns public.departments
language plpgsql
security definer
set search_path = ''
as $$
declare v_department public.departments%rowtype;
begin
  if not public.is_active_super_admin() then raise exception 'only an active Super Admin can manage departments'; end if;
  if length(trim(p_name)) not between 1 and 100 then raise exception 'department name is required'; end if;
  insert into public.departments(name, description, is_active)
  values (trim(p_name), nullif(trim(coalesce(p_description, '')), ''), p_is_active)
  on conflict (name) do update set
    description = excluded.description,
    is_active = excluded.is_active,
    updated_at = now()
  returning * into v_department;
  return v_department;
end;
$$;

create or replace function public.set_role_permission(
  p_role_name text,
  p_permission_key text,
  p_granted boolean
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.is_active_super_admin() then raise exception 'only an active Super Admin can manage permissions'; end if;
  if not exists (select 1 from public.custom_roles where name = p_role_name and is_active) then
    raise exception 'role not found';
  end if;
  insert into public.role_permissions(role_name, permission_key, granted)
  values (p_role_name, p_permission_key, p_granted)
  on conflict (role_name, permission_key) do update set granted = excluded.granted, updated_at = now();
end;
$$;

revoke all on function public.upsert_workspace_role(text,text,text,boolean),
  public.upsert_workspace_department(text,text,boolean),
  public.set_role_permission(text,text,boolean)
  from public, anon;
grant execute on function public.upsert_workspace_role(text,text,text,boolean),
  public.upsert_workspace_department(text,text,boolean),
  public.set_role_permission(text,text,boolean)
  to authenticated;

create or replace function public.manage_user_account(
  p_actor_auth_user_id uuid,
  p_target_profile_id uuid,
  p_action text,
  p_role text default null,
  p_is_active boolean default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$ 
declare
  v_actor public.profiles%rowtype;
  v_target public.profiles%rowtype;
  v_other_active_super_admins bigint;
begin
  if auth.role() is distinct from 'service_role' then raise exception 'service role required'; end if;
  select * into v_actor from public.profiles where auth_user_id = p_actor_auth_user_id for update;
  if not found
     or lower(trim(replace(coalesce(v_actor.role::text, ''), '_', ' '))) <> 'super admin'
     or v_actor.is_active is not true then
    raise exception 'only an active Super Admin can manage users';
  end if;
  select * into v_target from public.profiles where id = p_target_profile_id for update;
  if not found or v_target.auth_user_id is null then raise exception 'user account not found'; end if;
  if p_action = 'change_role' then
    if p_role is null or not exists (select 1 from public.custom_roles where name = p_role and is_active) then
      raise exception 'unsupported user role';
    end if;
    if v_target.auth_user_id = p_actor_auth_user_id
       and lower(trim(replace(coalesce(p_role, ''), '_', ' '))) <> 'super admin' then
      raise exception 'you cannot remove your own Super Admin role';
    end if;
    if v_target.is_active
       and lower(trim(replace(coalesce(v_target.role::text, ''), '_', ' '))) = 'super admin'
       and lower(trim(replace(coalesce(p_role, ''), '_', ' '))) <> 'super admin' then
      select count(*) into v_other_active_super_admins from public.profiles
      where id <> v_target.id
        and lower(trim(replace(coalesce(role::text, ''), '_', ' '))) = 'super admin'
        and is_active is true;
      if v_other_active_super_admins = 0 then raise exception 'at least one active Super Admin must remain'; end if;
    end if;
    update public.profiles set role = p_role where id = v_target.id;
  elsif p_action = 'set_active' then
    if p_is_active is null then raise exception 'an account status is required'; end if;
    if v_target.auth_user_id = p_actor_auth_user_id and p_is_active is false then
      raise exception 'you cannot deactivate your own account';
    end if;
    update public.profiles set is_active = p_is_active where id = v_target.id;
  else raise exception 'unsupported user management action'; end if;
end;
$$;
revoke all on function public.manage_user_account(uuid,uuid,text,text,boolean) from public, anon, authenticated;
grant execute on function public.manage_user_account(uuid,uuid,text,text,boolean) to service_role;
