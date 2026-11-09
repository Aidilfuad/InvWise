alter table public.profiles
  add column if not exists is_deletion_pending boolean not null default false,
  add column if not exists deletion_operation_id uuid;

alter table public.profiles
  drop constraint if exists profiles_auth_user_id_fkey;
alter table public.profiles
  add constraint profiles_auth_user_id_fkey
  foreign key (auth_user_id) references auth.users(id) on delete cascade;

alter table public.user_settings
  drop constraint if exists user_settings_profile_id_fkey;
alter table public.user_settings
  add constraint user_settings_profile_id_fkey
  foreign key (profile_id) references public.profiles(id) on delete cascade;

alter table public.support_requests
  alter column profile_id drop not null,
  drop constraint if exists support_requests_profile_id_fkey;
alter table public.support_requests
  add constraint support_requests_profile_id_fkey
  foreign key (profile_id) references public.profiles(id) on delete set null;

alter table public.registration_requests
  drop constraint if exists registration_requests_approved_by_fkey,
  drop constraint if exists registration_requests_provisioning_auth_user_id_fkey;
alter table public.registration_requests
  add constraint registration_requests_approved_by_fkey
    foreign key (approved_by) references public.profiles(id) on delete set null,
  add constraint registration_requests_provisioning_auth_user_id_fkey
    foreign key (provisioning_auth_user_id) references auth.users(id)
    on delete set null;

alter table public.inventory_items
  drop constraint if exists inventory_items_archived_by_fkey;
alter table public.inventory_items
  add constraint inventory_items_archived_by_fkey
  foreign key (archived_by) references auth.users(id) on delete set null;

create table if not exists public.user_deletion_operations (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  profile_id uuid not null,
  auth_user_id uuid not null,
  actor_auth_user_id uuid not null,
  target_name text not null,
  target_email text not null,
  target_role text not null,
  actor_name text not null,
  status text not null default 'pending'
    check (status in ('pending', 'completed')),
  created_at timestamptz not null default now(),
  completed_at timestamptz
);

alter table public.user_deletion_operations enable row level security;
revoke all on public.user_deletion_operations from public, anon, authenticated;
revoke all on public.user_deletion_operations from service_role;

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
  v_other_super_admins bigint;
begin
  if auth.role() is distinct from 'service_role' then
    raise exception 'service role required';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(918273645);

  select *
    into v_actor
    from public.profiles
   where auth_user_id = p_actor_auth_user_id
   for update;
  if not found or v_actor.role::text <> 'Super Admin'
     or v_actor.is_active is not true then
    raise exception 'only an active Super Admin can manage users';
  end if;

  select *
    into v_target
    from public.profiles
   where id = p_target_profile_id
   for update;
  if not found or v_target.auth_user_id is null then
    raise exception 'user account not found';
  end if;
  if v_target.is_deletion_pending then
    raise exception 'user deletion is already in progress';
  end if;

  if p_action = 'change_role' then
    if p_role is null or p_role not in (
      'Super Admin',
      'Inventory Administrator',
      'Warehouse Supervisor',
      'Storekeeper'
    ) then
      raise exception 'unsupported user role';
    end if;
    if v_target.auth_user_id = p_actor_auth_user_id
       and p_role <> 'Super Admin' then
      raise exception 'you cannot remove your own Super Admin role';
    end if;

    if v_target.is_active
       and v_target.role::text = 'Super Admin'
       and p_role <> 'Super Admin' then
      select count(*)
        into v_other_super_admins
        from public.profiles
       where id <> v_target.id
         and role::text = 'Super Admin'
         and is_active is true;
      if v_other_super_admins = 0 then
        raise exception 'at least one active Super Admin must remain';
      end if;
    end if;

    update public.profiles
       set role = p_role::public.user_role
     where id = v_target.id;
  elsif p_action = 'set_active' then
    if p_is_active is null then
      raise exception 'an account status is required';
    end if;
    if v_target.auth_user_id = p_actor_auth_user_id
       and p_is_active is false then
      raise exception 'you cannot deactivate your own account';
    end if;

    if v_target.is_active
       and v_target.role::text = 'Super Admin'
       and p_is_active is false then
      select count(*)
        into v_other_super_admins
        from public.profiles
       where id <> v_target.id
         and role::text = 'Super Admin'
         and is_active is true;
      if v_other_super_admins = 0 then
        raise exception 'at least one active Super Admin must remain';
      end if;
    end if;

    update public.profiles
       set is_active = p_is_active
     where id = v_target.id;
  else
    raise exception 'unsupported user management action';
  end if;
end;
$$;

revoke all on function public.manage_user_account(uuid, uuid, text, text, boolean)
  from public, anon, authenticated;
grant execute on function public.manage_user_account(uuid, uuid, text, text, boolean)
  to service_role;

create or replace function public.prepare_permanent_user_deletion(
  p_actor_auth_user_id uuid,
  p_target_profile_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor public.profiles%rowtype;
  v_target public.profiles%rowtype;
  v_other_same_role bigint;
  v_operation_id uuid := pg_catalog.gen_random_uuid();
  v_actor_name text;
  v_target_name text;
begin
  if auth.role() is distinct from 'service_role' then
    raise exception 'service role required';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(918273645);

  select *
    into v_actor
    from public.profiles
   where auth_user_id = p_actor_auth_user_id
   for update;
  if not found or v_actor.role::text not in ('Super Admin', 'Super User')
     or v_actor.is_active is not true then
    raise exception 'only an active Super Admin can permanently delete users';
  end if;

  select *
    into v_target
    from public.profiles
   where id = p_target_profile_id
   for update;
  if not found or v_target.auth_user_id is null then
    raise exception 'user account not found';
  end if;
  if v_target.auth_user_id = p_actor_auth_user_id then
    raise exception 'you cannot permanently delete your own account';
  end if;
  if v_target.is_active then
    raise exception 'deactivate the account before permanently deleting it';
  end if;
  if v_target.is_deletion_pending then
    raise exception 'user deletion is already in progress';
  end if;

  if v_target.role::text in ('Super Admin', 'Super User') then
    select count(*)
      into v_other_same_role
      from public.profiles
     where id <> v_target.id
       and role::text = v_target.role::text;
    if v_other_same_role = 0 then
      raise exception 'the last remaining % cannot be deleted',
        v_target.role::text;
    end if;
  end if;

  v_actor_name := coalesce(
    nullif(btrim(v_actor.full_name), ''),
    nullif(btrim(v_actor.email), ''),
    'Super Admin'
  );
  v_target_name := coalesce(
    nullif(btrim(v_target.full_name), ''),
    nullif(btrim(v_target.email), ''),
    'Unnamed user'
  );

  insert into public.user_deletion_operations (
    id,
    profile_id,
    auth_user_id,
    actor_auth_user_id,
    target_name,
    target_email,
    target_role,
    actor_name
  ) values (
    v_operation_id,
    v_target.id,
    v_target.auth_user_id,
    p_actor_auth_user_id,
    v_target_name,
    coalesce(v_target.email, ''),
    v_target.role::text,
    v_actor_name
  );

  update public.profiles
     set is_deletion_pending = true,
         deletion_operation_id = v_operation_id
   where id = v_target.id;

  return jsonb_build_object(
    'operation_id', v_operation_id,
    'profile_id', v_target.id,
    'auth_user_id', v_target.auth_user_id,
    'target_name', v_target_name,
    'target_email', coalesce(v_target.email, ''),
    'target_role', v_target.role::text
  );
end;
$$;

revoke all on function public.prepare_permanent_user_deletion(uuid, uuid)
  from public, anon, authenticated;
grant execute on function public.prepare_permanent_user_deletion(uuid, uuid)
  to service_role;

create or replace function public.cancel_permanent_user_deletion(
  p_operation_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.role() is distinct from 'service_role' then
    raise exception 'service role required';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(918273645);

  update public.profiles
     set is_deletion_pending = false,
         deletion_operation_id = null
   where deletion_operation_id = p_operation_id
     and is_deletion_pending is true;

  delete from public.user_deletion_operations
   where id = p_operation_id
     and status = 'pending';
end;
$$;

revoke all on function public.cancel_permanent_user_deletion(uuid)
  from public, anon, authenticated;
grant execute on function public.cancel_permanent_user_deletion(uuid)
  to service_role;

create or replace function public.finish_permanent_user_deletion(
  p_operation_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_operation public.user_deletion_operations%rowtype;
  v_deleted_at timestamptz := now();
begin
  if auth.role() is distinct from 'service_role' then
    raise exception 'service role required';
  end if;

  select *
    into v_operation
    from public.user_deletion_operations
   where id = p_operation_id
   for update;
  if not found then
    raise exception 'user deletion operation not found';
  end if;
  if v_operation.status = 'completed' then
    return jsonb_build_object('deleted', true, 'already_completed', true);
  end if;

  if exists (
    select 1 from auth.users where id = v_operation.auth_user_id
  ) then
    raise exception 'the Supabase Auth account has not been deleted';
  end if;

  delete from public.user_settings
   where profile_id = v_operation.profile_id;
  delete from public.profiles
   where id = v_operation.profile_id
     and auth_user_id = v_operation.auth_user_id;

  insert into public.activity_logs (
    occurred_at,
    actor_user_id,
    actor_name,
    category,
    action,
    description,
    entity_type,
    entity_id,
    metadata
  ) values (
    v_deleted_at,
    v_operation.actor_auth_user_id,
    v_operation.actor_name,
    'User Management',
    'User Permanently Deleted',
    pg_catalog.format(
      'Permanently deleted %s (%s).',
      v_operation.target_name,
      v_operation.target_email
    ),
    'profile',
    v_operation.profile_id::text,
    pg_catalog.jsonb_build_object(
      'deleted_user',
      pg_catalog.jsonb_build_object(
        'profile_id', v_operation.profile_id,
        'auth_user_id', v_operation.auth_user_id,
        'full_name', v_operation.target_name,
        'email', v_operation.target_email,
        'role', v_operation.target_role
      ),
      'deleted_by',
      pg_catalog.jsonb_build_object(
        'auth_user_id', v_operation.actor_auth_user_id,
        'name', v_operation.actor_name
      ),
      'deleted_at', v_deleted_at,
      'deletion_operation_id', v_operation.id
    )
  );

  update public.user_deletion_operations
     set status = 'completed',
         completed_at = v_deleted_at
   where id = v_operation.id;

  return pg_catalog.jsonb_build_object(
    'deleted', true,
    'operation_id', v_operation.id,
    'deleted_at', v_deleted_at
  );
end;
$$;

revoke all on function public.finish_permanent_user_deletion(uuid)
  from public, anon, authenticated;
grant execute on function public.finish_permanent_user_deletion(uuid)
  to service_role;
