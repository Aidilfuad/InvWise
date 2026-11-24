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
        into v_other_active_super_admins
        from public.profiles
       where id <> v_target.id
         and role::text = 'Super Admin'
         and is_active is true;
      if v_other_active_super_admins = 0 then
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
        into v_other_active_super_admins
        from public.profiles
       where id <> v_target.id
         and role::text = 'Super Admin'
         and is_active is true;
      if v_other_active_super_admins = 0 then
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
