create or replace function public.resolve_login_email_by_employee_id(
  p_employee_id text
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_profile_count bigint;
  v_email text;
begin
  if nullif(btrim(p_employee_id), '') is null then
    return null;
  end if;

  select count(*), min(auth_user.email)
    into v_profile_count, v_email
    from public.profiles as profile
    join auth.users as auth_user
      on auth_user.id = profile.auth_user_id
   where profile.employee_id = btrim(p_employee_id)
     and profile.is_active = true
     and auth_user.email is not null;

  if v_profile_count <> 1 then
    return null;
  end if;

  return v_email;
end;
$$;

revoke all on function public.resolve_login_email_by_employee_id(text)
  from public, anon, authenticated;
grant execute on function public.resolve_login_email_by_employee_id(text)
  to anon, authenticated;
