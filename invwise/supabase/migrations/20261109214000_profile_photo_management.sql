alter table public.profiles
  add column if not exists avatar_url text;

insert into storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
values (
  'profile-photos',
  'profile-photos',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Users upload their own profile photos"
  on storage.objects;
create policy "Users upload their own profile photos"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'profile-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and coalesce(array_length(storage.foldername(name), 1), 0) = 1
    and storage.filename(name) ~*
      '^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}[.](jpg|png|webp)$'
  );

drop policy if exists "Users delete their own profile photos"
  on storage.objects;
create policy "Users delete their own profile photos"
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'profile-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and coalesce(array_length(storage.foldername(name), 1), 0) = 1
  );

create or replace function public.update_current_profile_avatar(
  p_object_path text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_user_id uuid := auth.uid();
  v_profile_id uuid;
  v_full_name text;
  v_previous_avatar_url text;
  v_action text;
begin
  if v_user_id is null then
    raise exception 'Sign in before changing a profile photo'
      using errcode = '28000';
  end if;

  select profile.id, profile.full_name, profile.avatar_url
    into v_profile_id, v_full_name, v_previous_avatar_url
    from public.profiles as profile
    where profile.auth_user_id = v_user_id
      and profile.is_active is true
    for update;

  if v_profile_id is null then
    raise exception 'An active profile was not found for the signed-in user'
      using errcode = '42501';
  end if;

  if p_object_path is not null then
    if p_object_path !~
      ('^' || v_user_id::text ||
       '/[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}([.]jpg|[.]png|[.]webp)$') then
      raise exception 'The profile photo must be stored in your own photo folder'
        using errcode = '42501';
    end if;

    if not exists (
      select 1
      from storage.objects as object
      where object.bucket_id = 'profile-photos'
        and object.name = p_object_path
    ) then
      raise exception 'The uploaded profile photo was not found'
        using errcode = 'P0002';
    end if;
  end if;

  v_action := case
    when p_object_path is null then 'Remove Profile Photo'
    when v_previous_avatar_url is null then 'Upload Profile Photo'
    else 'Update Profile Photo'
  end;

  update public.profiles
     set avatar_url = p_object_path
   where id = v_profile_id;

  insert into public.activity_logs (
    actor_user_id,
    actor_name,
    category,
    action,
    description,
    entity_type,
    entity_id,
    metadata
  )
  values (
    v_user_id,
    coalesce(nullif(v_full_name, ''), 'Inventory User'),
    'Profile',
    v_action,
    case v_action
      when 'Remove Profile Photo' then 'Removed the profile photo.'
      when 'Update Profile Photo' then 'Updated the profile photo.'
      else 'Uploaded a profile photo.'
    end,
    'profile',
    v_profile_id::text,
    jsonb_build_object(
      'avatar_url', p_object_path,
      'previous_avatar_url', v_previous_avatar_url
    )
  );

  return jsonb_build_object(
    'avatar_url', p_object_path,
    'previous_avatar_url', v_previous_avatar_url,
    'action', v_action
  );
end;
$function$;

revoke all on function public.update_current_profile_avatar(text)
  from public, anon;
grant execute on function public.update_current_profile_avatar(text)
  to authenticated;

comment on column public.profiles.avatar_url is
  'Object path for the profile photo in the public-read profile-photos bucket.';
