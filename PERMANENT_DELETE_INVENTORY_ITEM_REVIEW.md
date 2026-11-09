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
[`supabase/migrations/20261109210000_permanent_inventory_delete_safety.sql`](./supabase/migrations/20261109210000_permanent_inventory_delete_safety.sql)
as a new migration. Do not edit or replay earlier migrations that may already
be recorded in an environment's migration history.

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
7. Repeat the checks in production only after staging passes and the data-loss
   implications have been approved.

Production data has not been changed by this migration.
