-- Run only against a disposable local or staging database after applying
-- 20261109213000_force_delete_stock_movement_bypass.sql.
-- Every fixture mutation is rolled back by the final ROLLBACK.
begin;

do $$
declare
  v_actor_auth_user_id uuid;
  v_actor_profile_id uuid;
  v_unit_id uuid;
  v_location_id uuid;
  v_item_id uuid := pg_catalog.gen_random_uuid();
  v_movement_id uuid := pg_catalog.gen_random_uuid();
  v_sku text := 'force-delete-test-' || pg_catalog.gen_random_uuid()::text;
begin
  select profile.auth_user_id, profile.id
    into v_actor_auth_user_id, v_actor_profile_id
    from public.profiles as profile
    where profile.role::text = 'Super Admin'
      and profile.is_active is true
      and profile.auth_user_id is not null
    limit 1;

  select unit.id
    into v_unit_id
    from public.units as unit
    limit 1;

  select location.id
    into v_location_id
    from public.warehouse_locations as location
    limit 1;

  if v_actor_auth_user_id is null
     or v_actor_profile_id is null
     or v_unit_id is null
     or v_location_id is null then
    raise exception
      'Force Delete regression test requires an active Super Admin, unit, and warehouse location';
  end if;

  insert into public.inventory_items (
    id, sku, name, unit_id, is_active, is_archived, archived_at, archived_by
  ) values (
    v_item_id,
    v_sku,
    'Force Delete regression fixture',
    v_unit_id,
    false,
    true,
    pg_catalog.now(),
    v_actor_auth_user_id
  );

  insert into public.stock_movements (
    id, item_id, movement_type, quantity, source_location_id, performed_by
  ) values (
    v_movement_id,
    v_item_id,
    'adjustment',
    1,
    v_location_id,
    v_actor_profile_id
  );

  perform pg_catalog.set_config(
    'invwise.force_delete_test_item_id',
    v_item_id::text,
    true
  );
  perform pg_catalog.set_config(
    'invwise.force_delete_test_movement_id',
    v_movement_id::text,
    true
  );
  perform pg_catalog.set_config(
    'request.jwt.claim.sub',
    v_actor_auth_user_id::text,
    true
  );
end;
$$;

-- A matching, caller-set GUC and an authenticated Super Admin are still not
-- sufficient: only the SECURITY DEFINER RPC owner context may bypass.
set local role authenticated;
do $$
declare
  v_state text;
  v_message text;
  v_blocked boolean := false;
begin
  perform pg_catalog.set_config(
    'invwise.inventory_force_delete',
    pg_catalog.current_setting('invwise.force_delete_test_item_id'),
    true
  );

  begin
    delete from public.stock_movements
    where id = pg_catalog.current_setting(
      'invwise.force_delete_test_movement_id'
    )::uuid;
  exception when others then
    get stacked diagnostics
      v_state = returned_sqlstate,
      v_message = message_text;
    v_blocked :=
      v_state = 'P0001'
      and v_message =
        'Stock movements are immutable; insert a correcting movement instead';
    if not v_blocked then
      raise;
    end if;
  end;

  if not v_blocked then
    raise exception
      'Authenticated direct DELETE with a matching marker unexpectedly succeeded';
  end if;
end;
$$;
reset role;
do $$
begin
  perform pg_catalog.set_config('invwise.inventory_force_delete', '', true);
end;
$$;

do $$
declare
  v_actor_auth_user_id uuid :=
    pg_catalog.current_setting('request.jwt.claim.sub')::uuid;
  v_item_id uuid :=
    pg_catalog.current_setting('invwise.force_delete_test_item_id')::uuid;
  v_movement_id uuid :=
    pg_catalog.current_setting('invwise.force_delete_test_movement_id')::uuid;
  v_sku text;
  v_state text;
  v_message text;
  v_blocked boolean;
  v_result jsonb;
begin
  select item.sku
    into v_sku
    from public.inventory_items as item
    where item.id = v_item_id;

  v_blocked := false;
  begin
    delete from public.stock_movements where id = v_movement_id;
  exception when others then
    get stacked diagnostics
      v_state = returned_sqlstate,
      v_message = message_text;
    v_blocked :=
      v_state = 'P0001'
      and v_message =
        'Stock movements are immutable; insert a correcting movement instead';
    if not v_blocked then
      raise;
    end if;
  end;
  if not v_blocked then
    raise exception 'Ordinary stock movement DELETE unexpectedly succeeded';
  end if;

  v_blocked := false;
  begin
    update public.stock_movements
       set notes = 'must remain immutable'
     where id = v_movement_id;
  exception when others then
    get stacked diagnostics
      v_state = returned_sqlstate,
      v_message = message_text;
    v_blocked :=
      v_state = 'P0001'
      and v_message =
        'Stock movements are immutable; insert a correcting movement instead';
    if not v_blocked then
      raise;
    end if;
  end;
  if not v_blocked then
    raise exception 'Stock movement UPDATE unexpectedly succeeded';
  end if;

  perform pg_catalog.set_config(
    'invwise.inventory_force_delete',
    pg_catalog.gen_random_uuid()::text,
    true
  );
  v_blocked := false;
  begin
    delete from public.stock_movements where id = v_movement_id;
  exception when others then
    get stacked diagnostics
      v_state = returned_sqlstate,
      v_message = message_text;
    v_blocked :=
      v_state = 'P0001'
      and v_message =
        'Stock movements are immutable; insert a correcting movement instead';
    if not v_blocked then
      raise;
    end if;
  end;
  if not v_blocked then
    raise exception 'A marker for another item unexpectedly authorized DELETE';
  end if;

  perform pg_catalog.set_config(
    'invwise.inventory_force_delete',
    v_item_id::text,
    true
  );
  perform pg_catalog.set_config(
    'request.jwt.claim.sub',
    pg_catalog.gen_random_uuid()::text,
    true
  );
  v_blocked := false;
  begin
    delete from public.stock_movements where id = v_movement_id;
  exception when others then
    get stacked diagnostics
      v_state = returned_sqlstate,
      v_message = message_text;
    v_blocked :=
      v_state = 'P0001'
      and v_message =
        'Stock movements are immutable; insert a correcting movement instead';
    if not v_blocked then
      raise;
    end if;
  end;
  if not v_blocked then
    raise exception 'A non-Super Admin context unexpectedly bypassed immutability';
  end if;

  perform pg_catalog.set_config('invwise.inventory_force_delete', '', true);
  perform pg_catalog.set_config(
    'request.jwt.claim.sub',
    v_actor_auth_user_id::text,
    true
  );

  v_blocked := false;
  begin
    perform public.permanently_delete_inventory_item(v_item_id);
  exception when others then
    get stacked diagnostics
      v_state = returned_sqlstate,
      v_message = message_text;
    v_blocked :=
      v_state = '23503'
      and v_message = pg_catalog.format(
        'Cannot permanently delete Force Delete regression fixture (SKU %s): it has 1 stock movement record(s) and 0 stock count record(s). These records preserve inventory history. Archive the item instead, or explicitly choose Force Delete as a Super Admin if removing this history is approved.',
        v_sku
      );
    if not v_blocked then
      raise;
    end if;
  end;
  if not v_blocked then
    raise exception 'Safe one-argument delete unexpectedly ignored movement history';
  end if;

  v_result :=
    public.permanently_delete_inventory_item(v_item_id, true);

  if v_result ->> 'deleted_stock_movements' is distinct from '1' then
    raise exception 'Force Delete did not report the removed movement count: %',
      v_result;
  end if;
  if pg_catalog.current_setting(
       'invwise.inventory_force_delete',
       true
     ) is distinct from '' then
    raise exception 'Force Delete did not clear its transaction-local marker';
  end if;
  if exists (
    select 1 from public.stock_movements where id = v_movement_id
  ) then
    raise exception 'Force Delete did not remove the selected stock movement';
  end if;
  if exists (
    select 1 from public.inventory_items where id = v_item_id
  ) then
    raise exception 'Force Delete did not remove the archived inventory item';
  end if;
end;
$$;

rollback;
