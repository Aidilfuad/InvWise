# Permanent Inventory Deletion Review

## Finding

The current `permanently_delete_inventory_item(uuid)` RPC deletes the inventory
row directly and only records an activity event afterward. Existing
`stock_movements` or `stock_counts` foreign-key references therefore prevent the
delete. Its `23503` database error is currently replaced in Flutter with a
generic message, which hides the reason.

The existing one-argument RPC contract remains available. A new
`permanently_delete_inventory_item(uuid, boolean)` overload implements the
behavior, while the one-argument RPC delegates to it with `false`.

## New behavior

- **Default/safe mode:** requires an archived item and an active Super Admin.
  It blocks deletion when stock movement or stock count rows exist, returning
  the counts and explaining that the history would be lost. If neither exists,
  it removes operational `stock_levels`, then the inventory item. Existing
  `activity_logs` are retained.
- **Force Delete:** requires the same server-side Super Admin authorization
  and explicit `p_force_delete = true`. It removes item-related activity-log
  rows, movement rows, stock-count rows, stock-level rows, and the inventory
  row, in that order. The transaction then writes a new permanent-deletion
  audit record with counts of the removed records. The new record is retained
  intentionally; it documents that Force Delete was used and is not one of the
  deleted historical item/movement logs. Its item ID is stored in metadata
  rather than `entity_id`, so no item-linked activity-log row remains.
- **Compatibility:** a caller sending only `p_item_id` continues through the
  safe one-argument RPC. Updated clients can pass `p_force_delete` explicitly.
- **Atomicity:** PostgreSQL runs the RPC as one transaction. If a constraint,
  policy, or unexpected reference blocks any operation, all deletions roll
  back.

The force path removes `activity_logs` rows where `entity_type` is
`inventory_item` and `entity_id` is the item's ID, plus rows where
`entity_type` is `inventory_movement` and `entity_id` matches one of the
item's movement IDs. It does not truncate or delete unrelated activity
history.

## Migration

Apply
[`supabase/migrations/20261109213000_force_delete_stock_movement_bypass.sql`](./supabase/migrations/20261109213000_force_delete_stock_movement_bypass.sql)
as a new forward migration after reviewing the environment's migration
history. Do not edit or replay earlier migrations that may already be recorded.

The existing `stock_movements_immutable` trigger remains in place. Its trigger
function still rejects every update and every delete by default. It permits
only a `DELETE` whose item ID matches the transaction-local
`invwise.inventory_force_delete` setting, when the current request belongs to
an active Super Admin and is executing with the owner identity of the
two-argument permanent-delete RPC. That RPC sets the marker only around its
movement-delete statement and clears it immediately afterward.

The regression suite is
[`supabase/tests/permanent_inventory_force_delete.sql`](./supabase/tests/permanent_inventory_force_delete.sql).
Run it only against a disposable local or staging database with the project
schema and seed data, for example:

```powershell
supabase db query --db-url $env:INVWISE_STAGING_DB_URL --file supabase/tests/permanent_inventory_force_delete.sql
```

Never point this test at production. It requires an active Super Admin profile,
a unit, and a warehouse location. The test runs in a transaction and rolls its
fixture back.

The SQL follows the current repository contracts for
`stock_movements.item_id`, `stock_movements.id`, `stock_levels.item_id`,
`stock_counts.item_id`, and the `activity_logs` entity fields. Before applying
to production, confirm these names and the existence of all four tables in the
target project's live schema; the migration deliberately does not create or
alter those tables.

## Risk assessment

| Mode | Risk | Data impact |
|---|---|---|
| Safe (default) | Low | Blocks when movement or count history exists; removes current stock-level rows and item only. Keeps existing activity history. |
| Force Delete | High / irreversible | Removes the item's movement, count, level, and linked activity-log rows. External exports, reports, or integrations may lose historical references. A new deletion audit event is retained. |

Additional safeguards: the item must already be archived; the database checks
the current active Super Admin profile rather than trusting a client-side role;
the item row is locked during the operation; and all operations roll back
together on failure. Force Delete still bypasses history-retention safeguards
by design, so it should not be used to resolve ordinary FK errors without
approval.

## Recommended production option

Deploy the safe default and use it for routine cleanup. Keep Force Delete
available only to active Super Admins, require a distinct destructive
confirmation in the application, and use it only after confirming that the
movement/count/audit history is no longer required under business retention
rules. Prefer archiving whenever historical reporting or audit requirements
are uncertain.

## Rollback plan

If staging validation or production monitoring fails, restore the trigger
function to its unconditional immutable behavior with a new approved rollback
change. Keep `stock_movements_immutable` installed and do not drop it. With the
trigger restored, `p_force_delete = true` will fail and roll back atomically;
the safe (`false`) RPC path remains available and continues to block when
movement or count history exists.

```sql
create or replace function public.prevent_stock_movement_mutation()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  raise exception 'Stock movements are immutable; insert a correcting movement instead';
end;
$$;
```

This rollback disables Force Delete but does not restore any records already
deleted by a successful Force Delete. Restoring deleted history requires a
separate database backup/point-in-time recovery process.

## Deployment and verification

1. Verify the migration history before applying the new forward migration.
2. In staging, test an archived item with no movements/counts: safe delete
   succeeds, removes levels, retains prior activity logs, and writes the delete
   audit event.
3. Test an archived item with movement rows and/or count rows: safe delete
   fails with the record counts and a Force Delete/archiving explanation; no
   rows change.
4. As a non-Super Admin, call both RPC signatures and verify both are denied.
5. As a Super Admin, call the two-argument RPC with `true` on disposable test
   data. Verify the item's movement/count/level rows and matching activity
   history are removed and the new deletion audit record reports the deleted
   row counts.
6. Verify a one-argument call still uses safe mode and PostgREST has refreshed
   its function schema cache.
7. Run the new SQL regression suite in staging and confirm ordinary movement
   delete/update remains blocked while authorized Force Delete succeeds.
8. Repeat the checks in production only after staging passes and the data-loss
   implications have been approved.

Production data has not been changed by this migration.
