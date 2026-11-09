# INVWISE_10_TESTING_QUALITY_AND_TECHNICAL_DEBT
## Testing Strategy, Code Quality Assessment & Technical Debt Register
### Version 2.0.0
### Source: Test Discovery + Technical Debt Discovery + Project Analysis

---

# PURPOSE OF THIS DOCUMENT

This document answers:

> "How reliable is InvWise today, what has been tested, and what technical risks remain?"

This document covers:

```text
Testing Coverage

Quality Assurance

Unit Testing

Widget Testing

Business Logic Validation

Known Technical Debt

Legacy Components

Risk Assessment

Future Refactoring Plan
```

Based on source discovery and available test inventory. 【1-612cf6】【2-f622a2】

---

# QUALITY OVERVIEW

Current test inventory:

```text
23 Flutter Test Files
```

identified within the project. 【1-612cf6】

Test coverage percentage:

```text
UNKNOWN
```

No coverage report was generated during discovery. 【1-612cf6】

---

# TESTING PHILOSOPHY

InvWise currently follows:

```text
Service Testing

Widget Testing

Business Rule Testing

Permission Testing

Telemetry Testing

Export Testing
```

Stronger coverage exists in:

```text
Inventory

Telemetry

Updates

Registration

Role Access

Reporting
```

【1-612cf6】

---

# TEST INVENTORY SUMMARY

Test Categories:

```text
Authentication

Registration

Inventory

Dashboard

Telemetry

Updates

Currency

Reporting

Permissions

Activity Logging

Caching

User Management
```

【1-612cf6】

---

# DASHBOARD TESTING

---

## Dashboard Full Mode

File:

```text
dashboard_full_mode_test.dart
```

Validates:

```text
Phone Layout

Tablet Layout

Desktop Layout
```

Discovery confirms responsiveness across form factors. 【1-612cf6】

---

# INVENTORY TESTING

---

## Inventory Filters

File:

```text
inventory_filter_test.dart
```

Validates:

```text
Status Filters

Filter Matching

Stock Classification Rules
```

【1-612cf6】

---

## Inventory Layout

File:

```text
inventory_layout_test.dart
```

Validates:

```text
Responsive Behaviour

Bulk Selection

Cache Refresh Logic
```

【1-612cf6】

---

## Inventory Summary Card

File:

```text
inventory_summary_card_test.dart
```

Validates:

```text
Inventory Metrics

MYR Formatting

Responsive Layout
```

【1-612cf6】

---

## Inventory Value Logic

File:

```text
inventory_item_value_test.dart
```

Validates:

```text
Current Stock × Unit Price
```

calculation logic. 【1-612cf6】

---

# TELEMETRY TESTING

---

## Telemetry Module

File:

```text
telemetry_module_test.dart
```

Validates:

```text
Daily Energy Analytics

Cumulative Energy

Threshold Evaluation

Alert Storage

CSV Export
```

【1-612cf6】

---

## Sensor Monitoring Card

File:

```text
sensor_monitoring_card_test.dart
```

Validates:

```text
Online Detection

Offline Detection

Timestamp Formatting

Manual Refresh

Error Recovery
```

【1-612cf6】

---

# IMPORTANT TELEMETRY LIMITATION

The discovered tests verify:

```text
Application Logic
```

but not:

```text
Actual DDS669 Hardware

Actual Toggle Switch Hardware

Node-RED Connectivity

MQTT Connectivity
```

No physical integration tests were found. 【1-612cf6】【3-929fc2】

---

# UPDATE SYSTEM TESTING

---

## App Update Service

File:

```text
app_update_service_test.dart
```

Validates:

```text
Version Parsing

Semantic Version Comparison

URL Validation

State Calculation

HTTPS Enforcement
```

【1-612cf6】【4-4b1014】

---

## Update Dialog

File:

```text
update_available_dialog_test.dart
```

Validates:

```text
Dismissable Updates

Force Updates

Locked Dialog Behaviour

Launch Failure Handling
```

【1-612cf6】

---

# AUTHENTICATION TESTING

---

## Registration Validation

File:

```text
registration_request_validation_test.dart
```

Validates:

```text
Required Fields

Email Format

Password Confirmation
```

【1-612cf6】

---

## Login Preferences

File:

```text
login_preferences_service_test.dart
```

Validates:

```text
Remember Me

Session Persistence

Session Expiry

Logout Cleanup
```

【1-612cf6】

---

# USER MANAGEMENT TESTING

---

## User Management Service

File:

```text
user_management_service_test.dart
```

Validates:

```text
User Parsing

Filtering

Role Search

Status Search
```

【1-612cf6】

---

## Role Access Service

File:

```text
role_access_service_test.dart
```

Validates:

```text
Permission Evaluation

Unknown Role Rejection

Admin Access

Super Admin Access
```

【1-612cf6】

---

# ACTIVITY LOG TESTING

---

## System Activity Logs

File:

```text
system_activity_log_service_test.dart
```

Validates:

```text
Audit Creation

Audit Retrieval

Filtering

Metadata Support
```

【1-612cf6】

---

# REPORTING TESTING

---

## Report Export Service

File:

```text
report_export_service_test.dart
```

Validates:

```text
CSV Export

Excel Export

Fallback File Writing
```

【1-612cf6】

---

# CURRENCY TESTING

---

## Currency Service

File:

```text
currency_service_test.dart
```

Validates:

```text
Preference Persistence

Offline Behaviour

Retry Logic

Exchange Rate Validation
```

【1-612cf6】

---

# OFFLINE TESTING

---

## Offline Cache Service

File:

```text
offline_cache_service_test.dart
```

Validates:

```text
User-Scoped Cache

Background Synchronisation

Immediate Retrieval
```

【1-612cf6】

---

# TEST COVERAGE BY SERVICE

---

## Services With Matching Tests

Examples include:

```text
AppUpdateService

CurrencyService

InventoryService

LoginPreferencesService

OfflineCacheService

RegistrationApprovalService

ReportsService

RoleAccessService

SensorMonitoringService

SystemActivityLogService

UserManagementService
```

Discovery found matching references between source and tests. 【1-612cf6】

---

# SERVICES WITHOUT MATCHING TESTS

The following services had no matching test discovered by filename/class heuristic:

```text
DashboardService

LoginTrackingService

PasswordConfirmationService

RegistrationRequestService

SecurityHistoryService

SecuritySessionTracker

SettingsBackupService

StockMovementService

SupportRequestService

TelemetryCsvExportService

UnitService
```

This is not proof they are untested elsewhere, only that no direct matching test was discovered. 【1-612cf6】

---

# TECHNICAL DEBT OVERVIEW

During discovery:

```text
No TODO

No FIXME

No HACK
```

markers were found. 【2-f622a2】

---

# TECHNICAL DEBT CATEGORY 1

## Legacy Update Architecture

Problem:

```text
app_versions table exists
```

while:

```text
GitHub Releases
```

is the active update source. 【2-f622a2】【4-4b1014】

Risk:

```text
Dead Schema

Maintenance Overhead
```

Priority:

```text
Medium
```

---

# TECHNICAL DEBT CATEGORY 2

## Dual Audit Systems

Current Database Contains:

```text
activity_log

activity_logs
```

Potential duplication exists. Future review should determine whether both remain necessary. 【2-f622a2】【5-f1c6a9】

Priority:

```text
Medium
```

---

# TECHNICAL DEBT CATEGORY 3

## Employee Login Endpoint

Function:

```text
login-with-employee-id
```

exists but discovery classified it as starter code rather than a complete login implementation. 【6-deb48d】【2-f622a2】

Priority:

```text
Medium
```

---

# TECHNICAL DEBT CATEGORY 4

## Telemetry Expansion Mismatch

Database supports:

```text
RFID

Barcode

PLC Counter
```

Current live implementation supports:

```text
DDS669

Toggle Switch
```

only. 【3-929fc2】【5-f1c6a9】

Priority:

```text
Low
```

---

# TECHNICAL DEBT CATEGORY 5

## Widget Candidates

Discovery identified multiple widget classes with no discovered external reference.

Examples:

```text
RecentActivityLogCard

InfoGridCard

SensorMonitoringCardState

SystemAlertsCardState
```

and additional widget helper classes. 【2-f622a2】

Important:

```text
Not Proven Dead Code
```

Dynamic references may still exist. 【2-f622a2】

Priority:

```text
Low
```

---

# CODE QUALITY STRENGTHS

---

## Strength 1

Strong separation of:

```text
UI

Services

Database
```

architecture. 【7-6147a1】【1-612cf6】

---

## Strength 2

Comprehensive inventory business rules protected through:

```text
Triggers

Functions

RPCs
```

【5-f1c6a9】

---

## Strength 3

Telemetry subsystem includes:

```text
Analytics

Alerts

Exports

History
```

with dedicated tests. 【1-612cf6】【3-929fc2】

---

## Strength 4

User administration protected by:

```text
Role Logic

RPC Validation

Edge Functions
```

【6-deb48d】【8-9a445f】

---

# QUALITY RISKS

---

## Risk 1

No discovered test coverage for:

```text
Edge Functions
```

【1-612cf6】【6-deb48d】

---

## Risk 2

No discovered test coverage for:

```text
RLS Policies
```

【1-612cf6】【8-9a445f】

---

## Risk 3

No discovered end-to-end tests for:

```text
Approval Workflow

Provisioning Workflow

Activation Workflow
```

【1-612cf6】

---

## Risk 4

No discovered hardware integration tests. 【1-612cf6】【3-929fc2】

---

# RECOMMENDED QUALITY ROADMAP

---

## Phase 1

Add tests for:

```text
StockMovementService

SupportRequestService

SettingsBackupService
```

---

## Phase 2

Add:

```text
Edge Function Tests

RLS Validation Tests
```

---

## Phase 3

Add:

```text
End-To-End Workflow Tests
```

for:

```text
Registration

Provisioning

Activation

Inventory Lifecycle
```

---

## Phase 4

Add:

```text
Hardware Integration Tests
```

for:

```text
DDS669

Toggle Switch
```

when hardware environment becomes available.

---

# CURRENT QUALITY FACTS

```text
22 Test Files

Inventory Tested

Telemetry Tested

Update System Tested

Permissions Tested

Export Logic Tested

No Coverage Report

No Edge Function Tests

No RLS Tests

No Hardware Tests

Manageable Technical Debt
```

【1-612cf6】【2-f622a2】

---

END OF DOCUMENT

INVWISE_10_TESTING_QUALITY_AND_TECHNICAL_DEBT.md

Version 2.0.0

---

# CURRENT QUALITY UPDATE — 2026-11-09

The former dashboard-preference implementation and its preference/height
tests have been removed. Dashboard tests now cover the single full Dashboard;
the sensor card test retains reading, status, synchronization, history, and
responsive-width coverage without a second dashboard presentation.

New/updated focused checks cover: GitHub request headers, latest/history
one-hour cache reuse and rate-limit fallback, release parsing and force-update
detection; safe/force permanent-delete RPC arguments and database-provided
history-block errors; and shared authenticated-page layout behavior at phone,
tablet, and desktop widths with authentication-route exclusion.

The permanent-delete migration still requires staging execution and live
post-deployment verification. The live database reference names were inspected,
but SQL behavior has not been applied to production. Responsive visual QA on
physical mobile/tablet devices remains a deployment checklist item.

## Profile Photo Quality Update

The new Flutter tests cover initials fallback, the gallery-selection control,
profile/cache serialization, square-only crop encoding, 512 × 512 JPEG output,
the crop screen’s 1:1 circular interactive configuration, and the complete
crop-screen return path. The full
`flutter analyze` run completed without issues and `flutter test` passed all
87 tests. The active Flutter application hot-restarted successfully with no
runtime errors.

The current tests do not exercise a live Storage upload or camera hardware. A
database authorization/configuration regression script is available at
`supabase/tests/profile_photo_management.sql`, but it has not been run. The
forward migration
`20261109214000_profile_photo_management.sql` has not been applied to the live
database. Staging verification and iOS/Android camera testing remain required.
Public-read bucket URLs are a privacy tradeoff and should only be used for
non-sensitive profile images.

## Final Implementation Validation

After these changes, `flutter analyze` completed with no issues and the full
`flutter test` suite passed all 82 tests. The active Flutter application
hot-restarted successfully with no reported runtime errors. A SQL regression
suite now covers the stock-movement trigger bypass, but was not run because no
local Supabase Docker/Podman runtime is available. Run it in staging before
deployment; these checks do not replace physical-device responsive QA.
