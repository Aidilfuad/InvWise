alter table public.registration_requests
  add column provisioning_status text not null default 'not_started',
  add column provisioning_error text,
  add column provisioning_auth_user_id uuid references auth.users(id),
  add column provisioning_started_at timestamptz,
  add column invited_at timestamptz,
  add column completed_at timestamptz,
  add constraint registration_requests_provisioning_status_check
    check (
      provisioning_status in (
        'not_started',
        'in_progress',
        'invited',
        'completed',
        'failed'
      )
    );

grant select on public.registration_requests to authenticated;
grant select on public.registration_requests to service_role;
grant select on public.profiles to service_role;
grant update (
  provisioning_status,
  provisioning_error,
  provisioning_auth_user_id,
  provisioning_started_at,
  invited_at,
  completed_at
)
  on public.registration_requests to service_role;

create unique index registration_requests_provisioning_auth_user_id_key
  on public.registration_requests (provisioning_auth_user_id)
  where provisioning_auth_user_id is not null;

create or replace function public.claim_registration_provisioning(
  p_request_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_request public.registration_requests%rowtype;
begin
  if auth.role() is distinct from 'service_role' then
    raise exception 'service role required';
  end if;

  select *
    into v_request
    from public.registration_requests
   where id = p_request_id
   for update;

  if not found then
    raise exception 'registration request not found';
  end if;

  if v_request.status <> 'approved' then
    raise exception 'registration request is not approved';
  end if;

  if v_request.provisioning_status in ('invited', 'completed') then
    return to_jsonb(v_request) || jsonb_build_object('claimed', false);
  end if;

  if v_request.provisioning_status = 'in_progress'
     and v_request.provisioning_started_at > now() - interval '10 minutes' then
    return to_jsonb(v_request) || jsonb_build_object('claimed', false);
  end if;

  update public.registration_requests
     set provisioning_status = 'in_progress',
         provisioning_started_at = now(),
         provisioning_error = null
   where id = p_request_id
   returning * into v_request;

  return to_jsonb(v_request) || jsonb_build_object('claimed', true);
end;
$$;

revoke all on function public.claim_registration_provisioning(uuid)
  from public, anon, authenticated;
grant execute on function public.claim_registration_provisioning(uuid)
  to service_role;

create or replace function public.create_registration_profile(
  p_request_id uuid,
  p_auth_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_request public.registration_requests%rowtype;
  v_profile public.profiles%rowtype;
begin
  if auth.role() is distinct from 'service_role' then
    raise exception 'service role required';
  end if;

  select *
    into v_request
    from public.registration_requests
   where id = p_request_id
   for update;

  if not found
     or v_request.status <> 'approved'
     or v_request.provisioning_status <> 'in_progress' then
    raise exception 'registration request is not ready for provisioning';
  end if;

  if v_request.provisioning_auth_user_id is not null
     and v_request.provisioning_auth_user_id <> p_auth_user_id then
    raise exception 'registration request is linked to a different auth user';
  end if;

  select *
    into v_profile
    from public.profiles
   where auth_user_id = p_auth_user_id
   limit 1
   for update;

  if found then
    if v_profile.employee_id is distinct from v_request.employee_id
       or lower(v_profile.email) is distinct from lower(v_request.email)
       or v_profile.role::text is distinct from v_request.requested_role::text then
      raise exception 'existing profile does not match the approved request';
    end if;
  else
    if exists (
      select 1
        from public.profiles
       where employee_id = v_request.employee_id
    ) then
      raise exception 'employee ID is already assigned to another profile';
    end if;

    insert into public.profiles (
      auth_user_id,
      employee_id,
      full_name,
      email,
      department,
      role
    )
    values (
      p_auth_user_id,
      v_request.employee_id,
      v_request.full_name,
      v_request.email,
      v_request.department,
      v_request.requested_role
    )
    returning * into v_profile;
  end if;

  update public.registration_requests
     set provisioning_auth_user_id = p_auth_user_id,
         provisioning_status = 'invited',
         provisioning_error = null,
         provisioning_started_at = null,
         invited_at = coalesce(invited_at, now())
   where id = p_request_id
   returning * into v_request;

  return jsonb_build_object(
    'request_id', v_request.id,
    'profile_id', v_profile.id,
    'auth_user_id', p_auth_user_id,
    'provisioning_status', v_request.provisioning_status
  );
end;
$$;

revoke all on function public.create_registration_profile(uuid, uuid)
  from public, anon, authenticated;
grant execute on function public.create_registration_profile(uuid, uuid)
  to service_role;
