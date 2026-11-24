alter table public.profiles
  add column if not exists is_active boolean not null default true,
  add column if not exists last_login_at timestamptz;

update public.profiles
   set is_active = true
 where is_active is null;

alter table public.profiles
  alter column is_active set default true,
  alter column is_active set not null;

update public.profiles as profile
   set last_login_at = auth_user.last_sign_in_at
  from auth.users as auth_user
 where profile.auth_user_id = auth_user.id
   and profile.last_login_at is null
   and auth_user.last_sign_in_at is not null;

create or replace function public.sync_profile_last_login()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.last_sign_in_at is distinct from old.last_sign_in_at
     and new.last_sign_in_at is not null then
    update public.profiles
       set last_login_at = new.last_sign_in_at
     where auth_user_id = new.id;
  end if;
  return new;
end;
$$;

drop trigger if exists sync_profile_last_login on auth.users;
create trigger sync_profile_last_login
  after update of last_sign_in_at on auth.users
  for each row
  execute function public.sync_profile_last_login();

revoke all on function public.sync_profile_last_login() from public, anon,
  authenticated;
