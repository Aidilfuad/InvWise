-- Run only against a disposable local or staging database after applying
-- 20261109214000_profile_photo_management.sql. No database rows are mutated.
begin;

do $$
declare
  v_function regprocedure :=
    'public.update_current_profile_avatar(text)'::regprocedure;
  v_actor_auth_user_id uuid;
  v_bucket_public boolean;
  v_bucket_size bigint;
  v_allowed_mime_types text[];
begin
  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'profiles'
      and column_name = 'avatar_url'
      and data_type = 'text'
  ) then
    raise exception 'profiles.avatar_url is missing or has the wrong type';
  end if;

  if has_function_privilege('anon', v_function, 'EXECUTE') then
    raise exception 'Anonymous users can execute the profile photo RPC';
  end if;
  if not has_function_privilege('authenticated', v_function, 'EXECUTE') then
    raise exception 'Authenticated users cannot execute the profile photo RPC';
  end if;

  select bucket.public, bucket.file_size_limit, bucket.allowed_mime_types
    into v_bucket_public, v_bucket_size, v_allowed_mime_types
    from storage.buckets as bucket
    where bucket.id = 'profile-photos';
  if v_bucket_public is distinct from true
     or v_bucket_size is distinct from 5242880
     or v_allowed_mime_types is distinct from
       array['image/jpeg', 'image/png', 'image/webp'] then
    raise exception 'Profile photo bucket visibility or size limit is incorrect';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_policies as policy
    where policy.schemaname = 'storage'
      and policy.tablename = 'objects'
      and policy.policyname = 'Users upload their own profile photos'
      and policy.cmd = 'INSERT'
      and 'authenticated'::name = any(policy.roles)
      and policy.with_check ilike '%auth.uid%'
      and policy.with_check ilike '%foldername%'
  ) then
    raise exception 'Owner-scoped profile photo upload policy is missing';
  end if;
  if not exists (
    select 1
    from pg_catalog.pg_policies as policy
    where policy.schemaname = 'storage'
      and policy.tablename = 'objects'
      and policy.policyname = 'Users delete their own profile photos'
      and policy.cmd = 'DELETE'
      and 'authenticated'::name = any(policy.roles)
      and policy.qual ilike '%auth.uid%'
      and policy.qual ilike '%foldername%'
  ) then
    raise exception 'Owner-scoped profile photo delete policy is missing';
  end if;

  select profile.auth_user_id
    into v_actor_auth_user_id
    from public.profiles as profile
    where profile.is_active is true
      and profile.auth_user_id is not null
    limit 1;
  if v_actor_auth_user_id is null then
    raise exception
      'Test requires at least one active profile linked to Supabase Auth';
  end if;

  perform pg_catalog.set_config(
    'request.jwt.claim.sub',
    v_actor_auth_user_id::text,
    true
  );
end;
$$;

set local role authenticated;
do $$
declare
  v_rejected boolean := false;
begin
  begin
    perform public.update_current_profile_avatar(
      '00000000-0000-4000-8000-000000000000/'
      '00000000-0000-4000-8000-000000000001.jpg'
    );
  exception when sqlstate '42501' then
    v_rejected := true;
  end;
  if not v_rejected then
    raise exception 'The RPC accepted a photo path owned by another user';
  end if;
end;
$$;
reset role;

rollback;
