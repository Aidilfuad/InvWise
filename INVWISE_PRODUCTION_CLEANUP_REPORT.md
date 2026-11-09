# InvWise Production Cleanup Report

## Result

The requested source-code cleanup and documentation updates are implemented.
The GitHub update resilience work is already in commit `6e2ea67` (`Fix GitHub
update rate limit handling and caching`). The archive RPC repair migration is
also present in that commit. This task adds the permanent-delete safety
migration, removes the alternate dashboard mode, standardizes authenticated
page layout, and updates the documentation suite.

The production database was inspected read-only. Neither the archive repair
migration nor the permanent-delete migration was applied to production as part
of this work.

## Update system

The update service uses GitHub JSON `Accept` and identifying `User-Agent`
headers. Latest release and release-history responses have separate
persistent one-hour caches; history cache keys include the requested limit.
Fresh cache entries avoid requests. HTTP 403/429 rate limiting falls back to
cached data when available, with a stale-data notice. Without a cached
response, the service presents a retry-later message rather than the raw HTTP
exception. Semantic version comparison, force-update detection, APK asset
discovery, release notes, and history remain covered by tests.

## Inventory archive and permanent deletion

The archive/restore RPCs are defined in
`supabase/migrations/20261109203000_inventory_archive_rpc_repair.sql`.
`supabase/migrations/20261109210000_permanent_inventory_delete_safety.sql`
adds a safe-by-default one-argument delete RPC and a two-argument overload
that permits Force Delete only for an active Super Admin.

- Safe Delete requires an archived item and blocks when movements or counts
  exist. It removes stock levels and the item while retaining activity history.
- Force Delete additionally removes linked stock movements, counts, levels,
  and only activity-log rows of the matching `inventory_item` /
  `inventory_movement` entity types. It records a new deletion audit event.
- The item row is locked during deletion. PostgreSQL transaction semantics
  roll back all changes if an operation fails.
- The app requires typing `DELETE` and password confirmation. The service and
  database enforce Super Admin access independently.

The new migration has not been applied to production. RPC behavior, permissions,
and data impact must be tested in staging before rollout.

## Dashboard and authenticated layout

The former dashboard preference service, storage, settings UI, alternate
rendering, and dedicated tests were removed. The full Dashboard is the only
dashboard. Authenticated routes now share a responsive page wrapper with a
1600 px maximum content width and responsive gutters. Login and registration
routes remain outside the wrapper.

The removed-feature search found no stale references in application source,
tests, or the `about_invwise/` documentation suite.

## Files changed

### Updated documentation

- `about_invwise/INVWISE_00_EXECUTIVE_OVERVIEW.md`
- `about_invwise/INVWISE_01_SYSTEM_BLUEPRINT.md`
- `about_invwise/INVWISE_02_DEVELOPER_PLAYBOOK.md`
- `about_invwise/INVWISE_03_PROJECT_STATE_V2_0_0.md`
- `about_invwise/INVWISE_05_SERVICE_AND_API_REFERENCE.md`
- `about_invwise/INVWISE_06_UI_AND_SCREEN_DOCUMENTATION.md`
- `about_invwise/INVWISE_07_SECURITY_ARCHITECTURE.md`
- `about_invwise/INVWISE_09_UPDATE_AND_DEPLOYMENT_ARCHITECTURE.md`
- `about_invwise/INVWISE_10_TESTING_QUALITY_AND_TECHNICAL_DEBT.md`
- `about_invwise/INVWISE_11_SYSTEM_WORKFLOWS_AND_BUSINESS_PROCESSES.md`
- `about_invwise/INVWISE_12_DEVELOPER_GUIDE_AND_MAINTENANCE_MANUAL.md`
- `about_invwise/INVWISE_13_API_AND_EDGE_FUNCTION_SPECIFICATION.md`
- `about_invwise/INVWISE_15_ROLE_PERMISSION_MATRIX.md`
- `about_invwise/INVWISE_17_FINAL_SYSTEM_AUDIT_REPORT.md`

### Updated application and test files

- `lib/features/alerts_page/alerts_page.dart`
- `lib/features/dashboard/dashboard_page.dart`
- `lib/features/dashboard/telemetry_history_page.dart`
- `lib/features/dashboard/widgets/attention_required_card.dart`
- `lib/features/dashboard/widgets/dashboard_section_header.dart`
- `lib/features/dashboard/widgets/inventory_health_card.dart`
- `lib/features/dashboard/widgets/inventory_overview_card.dart`
- `lib/features/dashboard/widgets/kpi_grid.dart`
- `lib/features/dashboard/widgets/monthly_insights_card.dart`
- `lib/features/dashboard/widgets/quick_actions_grid.dart`
- `lib/features/dashboard/widgets/recent_activity_card.dart`
- `lib/features/dashboard/widgets/recent_system_activity_card.dart`
- `lib/features/dashboard/widgets/sensor_monitoring_card.dart`
- `lib/features/dashboard/widgets/system_alerts_card.dart`
- `lib/features/dashboard/widgets/system_health_summary_card.dart`
- `lib/features/inventory/inventory_page.dart`
- `lib/features/inventory/item_details_page.dart`
- `lib/features/reports/reports_page.dart`
- `lib/features/settings/app_version_page.dart`
- `lib/features/settings/backup_restore_page.dart`
- `lib/features/settings/currency_settings_page.dart`
- `lib/features/settings/settings_page.dart`
- `lib/features/stock_adjustment/stock_adjustment_page.dart`
- `lib/features/system_information/system_information_page.dart`
- `lib/main.dart`
- `lib/services/inventory_service.dart`
- `lib/services/settings_backup_service.dart`
- `test/features/dashboard/widgets/sensor_monitoring_card_test.dart`
- `test/services/inventory_management_permissions_test.dart`

### Added

- `INVWISE_PRODUCTION_CLEANUP_REPORT.md`
- `PERMANENT_DELETE_INVENTORY_ITEM_REVIEW.md`
- `lib/widgets/authenticated_page_layout.dart`
- `supabase/migrations/20261109210000_permanent_inventory_delete_safety.sql`
- `test/widgets/authenticated_page_layout_test.dart`

### Deleted

- The former dashboard preference service and its dedicated settings and
  alternate-rendering tests.

## Validation

- `flutter analyze`: passed; no issues found.
- `flutter test`: passed; all 81 tests passed across 22 test files.
- Flutter hot restart: succeeded; no runtime errors were reported.
- `git diff --check`: passed.
- Removed-dashboard reference search: no matches.
- Production schema inspection: read-only inspection confirmed expected inventory
  item UUID references and restrictive stock movement/count/level foreign keys.
  Migration execution and RPC behavior have not been verified against production.

## Risks

| Risk | Level | Mitigation / remaining action |
|---|---|---|
| Force Delete irreversibly removes movement, count, level, and linked audit rows | High | Restrict to active Super Admins; require `DELETE` and password confirmation; preserve a deletion audit event; obtain retention approval. |
| New RPC signature may not be present in environments until migration rollout | High | Apply and test migrations before publishing the updated client; refresh PostgREST schema cache and verify both signatures. |
| Foreign keys or activity patterns may differ between environments | Medium | Confirm target schema and execute staging tests using disposable records. |
| Shared page viewport may need physical-device visual adjustments | Medium | Perform mobile, tablet, and desktop QA before release. |
| GitHub anonymous API limits can recur | Medium | One-hour response caching and cached fallback reduce requests; uncached failures show a retry-later message. |

## Deployment checklist

1. Back up the target database and review inventory/audit retention requirements.
2. Compare the target migration ledger and schema to the repository. Do not
   blindly replay historical migrations or run an uncontrolled production
   `db push`.
3. In staging, apply any missing archive repair migration and then
   `20261109210000_permanent_inventory_delete_safety.sql`.
4. Verify both delete RPC signatures, active Super Admin authorization, safe
   deletion with no movement/count rows, safe-mode blocking with references,
   Force Delete cleanup, and the retained deletion audit record.
5. Verify the app's typed and password-confirmation flows, then confirm
   PostgREST has refreshed its schema cache.
6. After staging sign-off, deploy the migration to production before the
   client version that sends `p_force_delete`. Run a controlled smoke test.
7. Perform physical-device layout checks and monitor update checks and delete
   RPC errors after release.

## Commit recommendation

Recommended commit message:

```text
feat: standardize dashboard and harden inventory deletion
```

Include the required Copilot co-author trailer when creating the commit.

## Readiness

**Code validation is green; production deployment readiness is conditional.**
The migration has not been applied, staging RPC/data-loss tests remain
outstanding, and physical-device responsive QA remains outstanding. Do not
enable production Force Delete until those checks and retention approval are
complete.
