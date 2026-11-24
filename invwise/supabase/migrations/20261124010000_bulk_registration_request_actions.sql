create or replace function public.delete_pending_registration_requests(
  p_request_ids uuid[]
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_profile public.profiles%rowtype;
  v_deleted_count integer := 0;
begin
  select *
    into v_profile
    from public.profiles
   where auth_user_id = auth.uid()
  for update;

  if not found
     or lower(trim(replace(coalesce(v_profile.role::text, ''), '_', ' '))) <> 'super admin'
     or v_profile.is_active is not true then
    raise exception 'only an active Super Admin can delete pending registration requests';
  end if;

  if p_request_ids is null or coalesce(array_length(p_request_ids, 1), 0) = 0 then
    return jsonb_build_object('deleted_count', 0);
  end if;

  delete from public.registration_requests
   where id = any(p_request_ids)
     and status = 'pending';

  get diagnostics v_deleted_count = row_count;
  return jsonb_build_object('deleted_count', v_deleted_count);
end;
$$;

revoke all on function public.delete_pending_registration_requests(uuid[])
  from public, anon, authenticated;
grant execute on function public.delete_pending_registration_requests(uuid[])
  to authenticated;
