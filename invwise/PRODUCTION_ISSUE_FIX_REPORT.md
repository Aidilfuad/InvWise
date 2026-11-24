# Production issue investigation and fix

Investigation date: 2026-11-09. The live Supabase findings below came from read-only queries against the linked `InvWise` project; no production database changes were made.

## Issue 1 — GitHub update API returns HTTP 403

### Root cause

`AppUpdateService` makes two unauthenticated GitHub REST API requests:

- Latest: `GET /repos/Aidilfuad/InvWise/releases/latest`
- History: `GET /repos/Aidilfuad/InvWise/releases?per_page=<limit>`

The shared request headers already included both `User-Agent: InvWise-App-Updater` and `Accept: application/vnd.github+json`; these are now explicitly covered by tests. They do not raise GitHub's unauthenticated core API quota. The supplied/live rate-limit evidence (`core.remaining = 0`) explains the 403.

Previously, every non-200 response except a latest-release 404 became a generic `http.ClientException`. The settings page awaited latest and history together, so either 403 caused the whole screen load to fail and displayed a raw exception.

### Fix

- [app_update_service.dart](./lib/services/app_update_service.dart) persists the latest-release JSON and each requested history page in the existing Hive-backed `OfflineCacheService`.
- Entries are reused for one hour. Expired entries are retained so a 403/429 can still fall back to the last saved payload.
- Both release endpoints continue to use the GitHub JSON `Accept` and app `User-Agent` headers.
- Rate limiting is detected from HTTP 429, `X-RateLimit-Remaining: 0`, and GitHub rate-limit response text. Any 403/429 uses available cache; without cache, a `GitHubReleaseException` gives a user-friendly retry message.
- [app_version_page.dart](./lib/features/settings/app_version_page.dart) loads latest and history independently, shows cached-data notices, and retains available information if one request fails.
- Existing semantic-version, APK asset, force-update, release-note, URL-validation, and dialog behavior is preserved.

## Issue 2 — Inventory archive RPCs are missing in production

### Root cause and database comparison

Flutter expects these exact PostgREST RPC names and signatures in [inventory_service.dart](./lib/services/inventory_service.dart):

| RPC | Flutter argument | Result used by Flutter |
|---|---|---|
| `archive_inventory_item(p_item_id uuid)` | `{'p_item_id': id}` | Response ignored; errors surfaced per item |
| `restore_inventory_item(p_item_id uuid)` | `{'p_item_id': id}` | Response ignored; errors surfaced per item |
| `permanently_delete_inventory_item(p_item_id uuid)` | `{'p_item_id': id}` | `jsonb` result; errors surfaced per item |

The live database inspection confirmed:

- `inventory_items.is_archived boolean NOT NULL DEFAULT false`, `archived_at timestamptz NULL`, and `archived_by uuid NULL` exist.
- **None of the three RPC functions exists** in `public`; no signature mismatch exists because the live routines are absent.
- `archived_by` did not have the expected FK, the inventory archive guard trigger did not exist, and RLS was disabled on `inventory_items`. Its ACL also granted excessive direct privileges to `anon` and `authenticated`.
- The live migration ledger does not contain `20261109020000` or `20261109030000`.

The local [20261109030000_inventory_schema_reconciliation.sql](./supabase/migrations/20261109030000_inventory_schema_reconciliation.sql) already defines all three UUID-argument RPCs, archive-field guard, and grants. [20261109020000_enterprise_inventory_and_app_management.sql](./supabase/migrations/20261109020000_enterprise_inventory_and_app_management.sql) defines only `permanently_delete_inventory_item(p_item_id uuid)`. The signatures in the 090300 migration match Flutter. The likely deployment cause is that the reconciliation migration was not applied to production; the archive columns appear to have been created separately or partially.

No Flutter change to `InventoryService` is needed: its `p_item_id` parameter names and UUID arguments match the required SQL signatures exactly.

### Migration fix

[20261109203000_inventory_archive_rpc_repair.sql](./supabase/migrations/20261109203000_inventory_archive_rpc_repair.sql) is a forward-only, idempotent migration for the archive workflow. It:

- Ensures the three archive columns and `archived_by → auth.users(id)` FK exist.
- Adds the archive index and archive-field guard trigger.
- Restricts direct inventory table grants, enables RLS, and installs the active-role read/write policies expected by the app.
- Creates the exact three `p_item_id uuid` RPC signatures, with active-role authorization, row locks, archive-state checks, and activity-log entries.
- Restricts archive/restore to an active Inventory Administrator or Super Admin; permanent delete to an active Super Admin. Permanent deletion still requires the item to be archived and does not cascade through stock history.

The RPC bodies use a pinned empty `search_path` and schema-qualified objects. The permanent-delete FK error for inventory still referenced by stock/activity history is expected and is already translated by the Flutter service.

## Files modified

- [lib/services/app_update_service.dart](./lib/services/app_update_service.dart)
- [lib/features/settings/app_version_page.dart](./lib/features/settings/app_version_page.dart)
- [test/services/app_update_service_test.dart](./test/services/app_update_service_test.dart)
- [supabase/migrations/20261109203000_inventory_archive_rpc_repair.sql](./supabase/migrations/20261109203000_inventory_archive_rpc_repair.sql)
- This report.

## Deployment instructions

1. Deploy the Flutter changes through the normal app release process.
2. Test the SQL migration on a production-like Supabase project and take/verify a production backup before applying it.
3. **Do not run `supabase db push` blindly.** `supabase migration list --linked` currently shows seven local migrations absent from the production ledger: `20261030000000`, `20261030000001`, `20261030000002`, `20261030000003`, `20261031000000`, `20261109020000`, and `20261109030000`. Reconcile these against the live schema before a push; do not mark them applied without verifying their complete effects.
4. After change approval and migration-history reconciliation, apply the dedicated migration through the approved production migration workflow. To execute only this SQL file with the linked Supabase CLI:

   ```powershell
   supabase db query --linked --file supabase/migrations/20261109203000_inventory_archive_rpc_repair.sql
   ```

   This command changes the linked database. Confirm the linked project ref and approval before running it.
5. After successful execution and verification, record the migration version in the Supabase migration ledger only through the team's approved process. If using `supabase migration repair --linked --status applied 20261109203000`, do so only after the SQL committed and the live objects were verified. This does **not** resolve the seven older pending versions; keep future `db push` deployments blocked until those are reconciled.
6. Rebuild/publish the app and confirm its target Supabase environment is the repaired project.

Read-only post-deployment checks:

```sql
select p.proname, pg_get_function_identity_arguments(p.oid) as arguments,
       pg_get_function_result(p.oid) as result
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    'archive_inventory_item',
    'restore_inventory_item',
    'permanently_delete_inventory_item'
  )
order by p.proname;

select c.relrowsecurity,
       exists (
         select 1 from pg_trigger t
         where t.tgrelid = c.oid
           and t.tgname = 'inventory_items_guard_archive_fields'
           and not t.tgisinternal
       ) as archive_guard_installed
from pg_class c
where c.oid = 'public.inventory_items'::regclass;
```

## Risk assessment

- **Update checker — Low:** cache may be stale during a GitHub outage/rate limit; the UI identifies cached data. Once the one-hour freshness period expires, the checker attempts GitHub again.
- **Archive migration — Medium/high data-access impact:** it enables RLS and revokes direct `anon`/authenticated inventory privileges, so existing clients bypassing active-profile policies may lose access. Verify all app roles and any external clients first.
- Permanent deletion is irreversible for the item row and can be blocked by foreign keys; do not use it as an archive operation. Validate archive/restore with test records before production.
- The production migration has not been executed in this task.

## Verification checklist

- [x] Latest and history API requests send `User-Agent` and `Accept`.
- [x] Fresh latest/history cache is reused for less than one hour.
- [x] Stale cache is used for GitHub 403 rate-limit responses.
- [x] No-cache 403 reports a user-friendly message; history and latest failures do not blank the entire update screen.
- [x] Semantic version, APK discovery, release-note/force-update parsing, update-dialog tests remain in place.
- [x] Flutter RPC call names/argument match all three forward migration definitions (`p_item_id uuid`).
- [x] Live database confirms archive columns exist and all three functions, the archive trigger, and archived-by FK are missing.
- [x] Live migration ledger confirms 090300 is not recorded as applied.
- [x] Full Flutter suite passed (79 tests); targeted Dart analysis passed; Windows debug hot restart completed.
- [ ] Apply the new database migration in staging, then approved production deployment.
- [ ] Verify each RPC with authorized and unauthorized users; test archive → list archived → restore and permanent delete of a disposable archived record.
