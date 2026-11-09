-- Keep the existing one-argument RPC contract safe by default while adding an
-- explicit Super Admin-only force-delete path.

create or replace function public.permanently_delete_inventory_item(
  p_item_id uuid,
  p_force_delete boolean
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_item record;
  v_actor_name text;
  v_movement_count bigint;
  v_stock_count_count bigint;
  v_deleted_movement_count bigint := 0;
  v_deleted_stock_count_count bigint := 0;
  v_deleted_stock_level_count bigint := 0;
  v_deleted_activity_log_count bigint := 0;
begin
  if not exists (
    select 1
    from public.profiles as profile
    where profile.auth_user_id = (select auth.uid())
      and profile.role::text = 'Super Admin'
      and profile.is_active is true
  ) then
    raise exception 'Only an active Super Admin can permanently delete inventory.'
      using errcode = '42501';
  end if;

  select item.id, item.name, item.sku, item.is_archived
    into v_item
    from public.inventory_items as item
    where item.id = p_item_id
    for update;
  if not found then
    raise exception 'Inventory item not found.';
  end if;
  if not v_item.is_archived then
    raise exception 'Archive the item before permanently deleting it.';
  end if;

  if p_force_delete is not true then
    select count(*)
      into v_movement_count
      from public.stock_movements as movement
      where movement.item_id = p_item_id;

    select count(*)
      into v_stock_count_count
      from public.stock_counts as stock_count
      where stock_count.item_id = p_item_id;

    if v_movement_count > 0 or v_stock_count_count > 0 then
      raise exception using
        errcode = '23503',
        message = pg_catalog.format(
          'Cannot permanently delete %s (SKU %s): it has %s stock movement record(s) and %s stock count record(s). These records preserve inventory history. Archive the item instead, or explicitly choose Force Delete as a Super Admin if removing this history is approved.',
          v_item.name,
          v_item.sku,
          v_movement_count,
          v_stock_count_count
        );
    end if;
  end if;

  select coalesce(nullif(profile.full_name, ''), 'Super Admin')
    into v_actor_name
    from public.profiles as profile
    where profile.auth_user_id = (select auth.uid());

  if p_force_delete is true then
    delete from public.activity_logs as activity_log
      where (
        activity_log.entity_type = 'inventory_item'
        and activity_log.entity_id = p_item_id::text
      )
        or (
          activity_log.entity_type = 'inventory_movement'
          and exists (
          select 1
          from public.stock_movements as movement
          where movement.item_id = p_item_id
            and activity_log.entity_id = movement.id::text
          )
        );
    get diagnostics v_deleted_activity_log_count = row_count;

    delete from public.stock_movements as movement
      where movement.item_id = p_item_id;
    get diagnostics v_deleted_movement_count = row_count;

    delete from public.stock_counts as stock_count
      where stock_count.item_id = p_item_id;
    get diagnostics v_deleted_stock_count_count = row_count;
  end if;

  delete from public.stock_levels as stock_level
    where stock_level.item_id = p_item_id;
  get diagnostics v_deleted_stock_level_count = row_count;

  delete from public.inventory_items as item
    where item.id = p_item_id;

  -- Preserve an audit record of the deletion, including what Force Delete removed.
  insert into public.activity_logs (
    actor_user_id, actor_name, category, action, description,
    entity_type, entity_id, metadata
  ) values (
    (select auth.uid()),
    coalesce(v_actor_name, 'Super Admin'),
    'Inventory',
    'Permanent Delete',
    pg_catalog.format(
      'Permanently deleted %s (SKU %s)%s.',
      v_item.name,
      v_item.sku,
      case when p_force_delete is true then ' using Force Delete' else '' end
    ),
    'inventory_item_deletion',
    null,
    pg_catalog.jsonb_build_object(
      'item_id', p_item_id,
      'item_name', v_item.name,
      'sku', v_item.sku,
      'deleted_by', (select auth.uid()),
      'deleted_at', pg_catalog.now(),
      'force_delete', p_force_delete is true,
      'deleted_stock_movements', v_deleted_movement_count,
      'deleted_stock_counts', v_deleted_stock_count_count,
      'deleted_stock_levels', v_deleted_stock_level_count,
      'deleted_activity_logs', v_deleted_activity_log_count
    )
  );

  return pg_catalog.jsonb_build_object(
    'id', p_item_id,
    'name', v_item.name,
    'sku', v_item.sku,
    'force_delete', p_force_delete is true,
    'deleted_stock_movements', v_deleted_movement_count,
    'deleted_stock_counts', v_deleted_stock_count_count,
    'deleted_stock_levels', v_deleted_stock_level_count,
    'deleted_activity_logs', v_deleted_activity_log_count
  );
end;
$$;

-- Existing clients that send only p_item_id remain on the safe path.
create or replace function public.permanently_delete_inventory_item(
  p_item_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
begin
  return public.permanently_delete_inventory_item(p_item_id, false);
end;
$$;

revoke all on function public.permanently_delete_inventory_item(uuid)
  from public, anon, authenticated;
revoke all on function public.permanently_delete_inventory_item(uuid, boolean)
  from public, anon, authenticated;
grant execute on function public.permanently_delete_inventory_item(uuid)
  to authenticated;
grant execute on function public.permanently_delete_inventory_item(uuid, boolean)
  to authenticated;

notify pgrst, 'reload schema';
