create table if not exists public.app_versions (
  id uuid primary key default gen_random_uuid(),
  version text not null,
  apk_url text not null,
  release_notes text not null default '',
  force_update boolean not null default false,
  created_at timestamptz not null default now(),
  constraint app_versions_version_format
    check (version ~ '^v?[0-9]+\.[0-9]+\.[0-9]+(\+[0-9]+)?$'),
  constraint app_versions_apk_url_https
    check (apk_url ~ '^https://')
);

create index if not exists app_versions_created_at_idx
  on public.app_versions (created_at desc);

alter table public.app_versions enable row level security;
grant select on public.app_versions to authenticated;
drop policy if exists "Authenticated users can read app versions"
  on public.app_versions;
create policy "Authenticated users can read app versions"
  on public.app_versions for select to authenticated using (true);

alter table public.inventory_items
  add column if not exists is_archived boolean not null default false,
  add column if not exists archived_at timestamptz,
  add column if not exists archived_by uuid references auth.users(id);

create index if not exists inventory_items_archived_idx
  on public.inventory_items (is_archived, is_active);

create or replace function public.permanently_delete_inventory_item(
  p_item_id uuid
)
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
    select 1
    from public.profiles
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

revoke all on function public.permanently_delete_inventory_item(uuid)
  from public, anon;
grant execute on function public.permanently_delete_inventory_item(uuid)
  to authenticated;
