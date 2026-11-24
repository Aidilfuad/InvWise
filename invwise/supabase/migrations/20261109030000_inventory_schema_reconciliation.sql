alter table public.inventory_items
  add column if not exists is_archived boolean not null default false,
  add column if not exists archived_at timestamptz,
  add column if not exists archived_by uuid;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.inventory_items'::regclass
      and conname = 'inventory_items_archived_by_fkey'
  ) then
    alter table public.inventory_items
      add constraint inventory_items_archived_by_fkey
      foreign key (archived_by) references auth.users(id)
      on delete set null;
  end if;
end;
$$;

create index if not exists inventory_items_archived_idx
  on public.inventory_items (is_archived, is_active);

alter table public.app_versions
  alter column release_notes set default '',
  alter column force_update set default false,
  alter column created_at set default now();

update public.app_versions
set release_notes = coalesce(release_notes, ''),
    force_update = coalesce(force_update, false),
    created_at = coalesce(created_at, now());

alter table public.app_versions
  alter column release_notes set not null,
  alter column force_update set not null,
  alter column created_at set not null;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.app_versions'::regclass
      and conname = 'app_versions_version_format'
  ) then
    alter table public.app_versions
      add constraint app_versions_version_format
      check (version ~ '^v?[0-9]+\.[0-9]+\.[0-9]+(\+[0-9]+)?$');
  end if;
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.app_versions'::regclass
      and conname = 'app_versions_apk_url_https'
  ) then
    alter table public.app_versions
      add constraint app_versions_apk_url_https
      check (apk_url ~ '^https://');
  end if;
end;
$$;

create index if not exists app_versions_created_at_idx
  on public.app_versions (created_at desc);

revoke all on public.app_versions from anon, authenticated;
grant select on public.app_versions to authenticated;
alter table public.app_versions enable row level security;
drop policy if exists "Authenticated users can read app versions"
  on public.app_versions;
create policy "Authenticated users can read app versions"
  on public.app_versions for select to authenticated using (true);

revoke all on public.inventory_items from anon, authenticated;
grant select, insert, update on public.inventory_items to authenticated;
alter table public.inventory_items enable row level security;

drop policy if exists "Active users can read inventory items"
  on public.inventory_items;
create policy "Active users can read inventory items"
  on public.inventory_items for select to authenticated
  using (
    exists (
      select 1 from public.profiles p
      where p.auth_user_id = auth.uid()
        and p.is_active
        and p.role::text in (
          'Super Admin',
          'Inventory Administrator',
          'Warehouse Supervisor',
          'Storekeeper'
        )
    )
  );

drop policy if exists "Inventory administrators can create inventory items"
  on public.inventory_items;
create policy "Inventory administrators can create inventory items"
  on public.inventory_items for insert to authenticated
  with check (
    exists (
      select 1 from public.profiles p
      where p.auth_user_id = auth.uid()
        and p.is_active
        and p.role::text in ('Super Admin', 'Inventory Administrator')
    )
  );

drop policy if exists "Active users can update inventory items"
  on public.inventory_items;
create policy "Active users can update inventory items"
  on public.inventory_items for update to authenticated
  using (
    exists (
      select 1 from public.profiles p
      where p.auth_user_id = auth.uid()
        and p.is_active
        and p.role::text in (
          'Super Admin',
          'Inventory Administrator',
          'Warehouse Supervisor',
          'Storekeeper'
        )
    )
  )
  with check (
    exists (
      select 1 from public.profiles p
      where p.auth_user_id = auth.uid()
        and p.is_active
        and p.role::text in (
          'Super Admin',
          'Inventory Administrator',
          'Warehouse Supervisor',
          'Storekeeper'
        )
    )
  );

create or replace function public.guard_inventory_archive_fields()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if (
    new.is_archived is distinct from old.is_archived
    or new.archived_at is distinct from old.archived_at
    or new.archived_by is distinct from old.archived_by
  ) and current_setting('invwise.inventory_archive_rpc', true) is distinct from 'on' then
    raise exception 'Archive state must be changed through the authorized inventory RPC.'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

drop trigger if exists inventory_items_guard_archive_fields
  on public.inventory_items;
create trigger inventory_items_guard_archive_fields
  before update of is_archived, archived_at, archived_by
  on public.inventory_items
  for each row execute function public.guard_inventory_archive_fields();

create or replace function public.archive_inventory_item(p_item_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_item record;
  v_actor_name text;
begin
  if not exists (
    select 1 from public.profiles
    where auth_user_id = auth.uid()
      and role::text in ('Super Admin', 'Inventory Administrator')
      and is_active = true
  ) then
    raise exception 'Only an active Inventory Administrator or Super Admin can archive inventory.'
      using errcode = '42501';
  end if;

  select id, name, sku, is_active, is_archived
    into v_item
    from public.inventory_items
    where id = p_item_id
    for update;
  if not found then
    raise exception 'Inventory item not found.';
  end if;
  if not v_item.is_active or v_item.is_archived then
    raise exception 'Only an active, unarchived item can be archived.';
  end if;

  select coalesce(nullif(full_name, ''), 'User')
    into v_actor_name
    from public.profiles
    where auth_user_id = auth.uid();

  perform set_config('invwise.inventory_archive_rpc', 'on', true);
  update public.inventory_items
  set is_active = false,
      is_archived = true,
      archived_at = now(),
      archived_by = auth.uid(),
      updated_at = now()
  where id = p_item_id;

  insert into public.activity_logs (
    actor_user_id, actor_name, category, action, description,
    entity_type, entity_id, metadata
  ) values (
    auth.uid(),
    coalesce(v_actor_name, 'User'),
    'Inventory',
    'Archive Item',
    format('Archived %s (SKU %s).', v_item.name, v_item.sku),
    'inventory_item',
    p_item_id::text,
    jsonb_build_object('item_name', v_item.name, 'sku', v_item.sku)
  );

  return jsonb_build_object('id', p_item_id, 'name', v_item.name, 'sku', v_item.sku);
end;
$$;

create or replace function public.restore_inventory_item(p_item_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_item record;
  v_actor_name text;
begin
  if not exists (
    select 1 from public.profiles
    where auth_user_id = auth.uid()
      and role::text in ('Super Admin', 'Inventory Administrator')
      and is_active = true
  ) then
    raise exception 'Only an active Inventory Administrator or Super Admin can restore inventory.'
      using errcode = '42501';
  end if;

  select id, name, sku, is_archived
    into v_item
    from public.inventory_items
    where id = p_item_id
    for update;
  if not found then
    raise exception 'Inventory item not found.';
  end if;
  if not v_item.is_archived then
    raise exception 'Only an archived item can be restored.';
  end if;

  select coalesce(nullif(full_name, ''), 'User')
    into v_actor_name
    from public.profiles
    where auth_user_id = auth.uid();

  perform set_config('invwise.inventory_archive_rpc', 'on', true);
  update public.inventory_items
  set is_active = true,
      is_archived = false,
      archived_at = null,
      archived_by = null,
      updated_at = now()
  where id = p_item_id;

  insert into public.activity_logs (
    actor_user_id, actor_name, category, action, description,
    entity_type, entity_id, metadata
  ) values (
    auth.uid(),
    coalesce(v_actor_name, 'User'),
    'Inventory',
    'Restore Item',
    format('Restored %s (SKU %s).', v_item.name, v_item.sku),
    'inventory_item',
    p_item_id::text,
    jsonb_build_object('item_name', v_item.name, 'sku', v_item.sku)
  );

  return jsonb_build_object('id', p_item_id, 'name', v_item.name, 'sku', v_item.sku);
end;
$$;

create or replace function public.permanently_delete_inventory_item(p_item_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_item record;
  v_actor_name text;
begin
  if not exists (
    select 1 from public.profiles
    where auth_user_id = auth.uid()
      and role::text = 'Super Admin'
      and is_active = true
  ) then
    raise exception 'Only an active Super Admin can permanently delete inventory.'
      using errcode = '42501';
  end if;

  select id, name, sku, is_archived
    into v_item
    from public.inventory_items
    where id = p_item_id
    for update;
  if not found then
    raise exception 'Inventory item not found.';
  end if;
  if not v_item.is_archived then
    raise exception 'Archive the item before permanently deleting it.';
  end if;

  select coalesce(nullif(full_name, ''), 'Super Admin')
    into v_actor_name
    from public.profiles
    where auth_user_id = auth.uid();

  delete from public.inventory_items where id = p_item_id;

  insert into public.activity_logs (
    actor_user_id, actor_name, category, action, description,
    entity_type, entity_id, metadata
  ) values (
    auth.uid(),
    coalesce(v_actor_name, 'Super Admin'),
    'Inventory',
    'Permanent Delete',
    format('Permanently deleted %s (SKU %s).', v_item.name, v_item.sku),
    'inventory_item',
    p_item_id::text,
    jsonb_build_object(
      'item_name', v_item.name,
      'sku', v_item.sku,
      'deleted_by', auth.uid(),
      'deleted_at', now()
    )
  );

  return jsonb_build_object('id', p_item_id, 'name', v_item.name, 'sku', v_item.sku);
end;
$$;

revoke all on function public.guard_inventory_archive_fields() from public, anon;
revoke all on function public.archive_inventory_item(uuid) from public, anon;
revoke all on function public.restore_inventory_item(uuid) from public, anon;
revoke all on function public.permanently_delete_inventory_item(uuid) from public, anon;
grant execute on function public.archive_inventory_item(uuid) to authenticated;
grant execute on function public.restore_inventory_item(uuid) to authenticated;
grant execute on function public.permanently_delete_inventory_item(uuid) to authenticated;
