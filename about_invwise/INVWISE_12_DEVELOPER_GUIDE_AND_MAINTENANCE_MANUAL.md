# INVWISE_12_DEVELOPER_GUIDE_AND_MAINTENANCE_MANUAL
## Developer Handover, System Maintenance & Operational Procedures
### Version 2.0.0
### Source: Complete Project Discovery Documentation

---

# PURPOSE OF THIS DOCUMENT

This document answers:

> "If the original developer disappears tomorrow, can another developer maintain InvWise successfully?"

This document serves as:

```text
Developer Handover Guide

Maintenance Manual

Operational Playbook

Knowledge Transfer Document

Future Development Guide
```

This document should always be delivered together with:

```text
INVWISE_01_SYSTEM_OVERVIEW

INVWISE_04_DATABASE_REFERENCE

INVWISE_05_SERVICE_AND_API_REFERENCE

INVWISE_06_UI_AND_SCREEN_DOCUMENTATION

INVWISE_07_SECURITY_ARCHITECTURE

INVWISE_11_SYSTEM_WORKFLOWS_AND_BUSINESS_PROCESSES
```

---

# SYSTEM OWNERSHIP OVERVIEW

System Name:

```text
InvWise
```

Primary Purpose:

```text
Inventory Management

Warehouse Operations

User Administration

Telemetry Monitoring

Reporting

Audit Logging
```

Technology Stack:

```text
Flutter

Supabase

PostgreSQL

Edge Functions

GitHub Releases
```

References:
- Database Architecture
- Service Architecture
- Security Architecture
- Telemetry Architecture

---

# SYSTEM ARCHITECTURE SUMMARY

```text
Flutter Application
        │
        ▼

Service Layer
        │
        ▼

Supabase Platform
        │
        ├── Authentication
        ├── PostgreSQL
        ├── Storage
        └── Edge Functions

        ▼

Users
```

---

# PROJECT STRUCTURE OVERVIEW

Major project areas:

```text
lib/
│
├── features/
├── services/
├── models/
├── core/
├── widgets/
└── main.dart

supabase/
│
├── migrations/
└── functions/

test/
```

Based on repository structure discovery. 【1-2dfd6a】【2-423ce2】

---

# DEVELOPER ONBOARDING CHECKLIST

A new developer should read documents in this order:

```text
01 System Overview

04 Database Reference

05 Service Layer Reference

06 UI Documentation

07 Security Architecture

08 Hardware & Telemetry

11 Workflow Documentation
```

Estimated familiarisation time:

```text
8–16 Hours
```

depending on Flutter and Supabase experience.

---

# LOCAL DEVELOPMENT SETUP

---

## Required Software

```text
Flutter SDK

Dart SDK

Android Studio

VS Code

Git

Supabase CLI
```

---

## Repository Setup

```bash
git clone <repository>

cd invwise

flutter pub get
```

---

## Verify Flutter

```bash
flutter doctor
```

All critical checks should pass before continuing.

---

# ENVIRONMENT CONFIGURATION

---

## Critical Environment Variables

Examples:

```text
SUPABASE_URL

SUPABASE_ANON_KEY

SUPABASE_SERVICE_ROLE_KEY
```

Environment-specific values should never be committed publicly.

---

## Development Environment

Used For:

```text
Feature Development

Testing

Debugging
```

---

## Production Environment

Used For:

```text
Live Users

Live Inventory

Telemetry

Reporting
```

---

# APPLICATION STARTUP FLOW

Understanding startup is important for debugging.

```text
main.dart
       ↓

App Initialization
       ↓

Supabase Initialization
       ↓

Authentication Check
       ↓

Profile Retrieval
       ↓

Dashboard
```

---

# MAJOR SYSTEM MODULES

---

## Authentication

Responsible Services:

```text
AuthService

LoginPreferencesService

LoginTrackingService
```

Purpose:

```text
User Access

Session Management

Authentication Logging
```

---

## User Management

Responsible Services:

```text
UserManagementService

ProfileService

RoleAccessService
```

Purpose:

```text
Role Changes

Activation

Deactivation

Profile Management
```

---

## Inventory

Responsible Services:

```text
InventoryService

CategoryService

UnitService

WarehouseLocationService

StockMovementService
```

Purpose:

```text
Inventory Operations
```

---

## Telemetry

Responsible Services:

```text
SensorMonitoringService
```

Purpose:

```text
Energy Monitoring

Switch Monitoring

Alerting
```

---

# DATABASE MAINTENANCE

---

## Most Important Rule

Never directly modify:

```text
stock_levels
```

without understanding:

```text
stock_movements
```

relationship.

Stock levels are derived operational values.

Inventory history must remain consistent.

---

## Second Most Important Rule

Never update:

```text
stock_movements
```

directly.

Database protections were intentionally added.

History must remain immutable.

---

## User Administration

Never:

```text
DELETE profiles
```

without impact analysis.

Tables reference user records extensively.

---

# MIGRATION MANAGEMENT

---

## Current Situation

Local migrations:

```text
14
```

Known remote ledger versions:

```text
7 Applied
```

Discovery identified migration drift requiring review. 【3-7b51a2】

---

## Before Adding New Migration

Checklist:

```text
Review Existing Schema

Review Related Functions

Review Related RLS

Review Related Triggers
```

---

## Migration Naming Standard

```text
YYYYMMDDHHMMSS_description.sql
```

Example:

```text
20270101000000_inventory_expiry_tracking.sql
```

---

## Migration Validation

Always verify:

```text
Development

Staging

Production
```

before deployment.

---

# EDGE FUNCTION MAINTENANCE

---

## Current Production Functions

```text
complete-registration-setup

manage-users

notify-support-request

provision-approved-registration

login-with-employee-id
```

【4-26ed8d】

---

## Critical Functions

Highest-risk functions:

```text
manage-users

provision-approved-registration

complete-registration-setup
```

because they affect:

```text
Authentication

User Accounts

Permissions
```

---

## Change Procedure

Before modifying any Edge Function:

```text
Review Caller

Review RPC

Review Database Changes

Review Security Impact
```

---

# SECURITY MAINTENANCE

---

## Rule 1

Never trust client-side permissions.

Real security must come from:

```text
RLS

RPC Validation

Edge Functions
```

---

## Rule 2

Review RLS whenever:

```text
New Table

New Feature

New API
```

is introduced.

---

## Rule 3

Do not remove protection inside:

```text
manage_user_account()
```

that prevents removal of the last active Super Admin.

---

# TELEMETRY MAINTENANCE

---

## Current Supported Devices

```text
DDS669 Energy Meter

Toggle Switch
```

【5-5a1107】

---

## Current Limitation

Application:

```text
Consumes Telemetry
```

but does not contain:

```text
MQTT Client

Serial Driver

Node-RED Client
```

【5-5a1107】

---

## Before Adding New Sensor Types

Verify:

```text
Database Enum

Sensor Registry

Dashboard Widget

History Storage

Alert Rules

Export Logic
```

---

# UPDATE SYSTEM MAINTENANCE

---

## Current Update Source

```text
GitHub Releases
```

【6-5553cc】

---

## Release Procedure

```text
Update Version

Create Tag

Create Release

Upload APK

Publish Notes
```

---

## Force Update

Enable:

```text
force_update: true
```

inside release metadata.

【6-5553cc】

---

# TESTING PROCEDURE

---

## Before Every Release

Run:

```bash
flutter test
```

---

## Verify Manually

```text
Login

Registration

Inventory Creation

Stock Receipt

Stock Issue

Reports

Updates

Telemetry
```

---

## High-Risk Areas

Require manual verification:

```text
Registration Approval

Provisioning

User Management

Telemetry Alerts

Update System
```

---

# BACKUP PROCEDURE

---

## Database Backup

Recommended:

```text
Daily

Weekly Archive

Monthly Archive
```

---

## Critical Data

```text
profiles

inventory_items

stock_movements

stock_levels

registration_requests

sensor_history

activity_logs
```

---

# INCIDENT RESPONSE GUIDE

---

## User Cannot Login

Check:

```text
profiles.is_active

Supabase Auth User

login_events

device_sessions
```

---

## Inventory Quantity Wrong

Check:

```text
stock_movements

stock_levels

Adjustment History
```

Never modify quantities blindly.

---

## Registration Not Completing

Check:

```text
registration_requests

Provisioning Status

Activation Status

Edge Function Logs
```

---

## Telemetry Missing

Check:

```text
sensors

sensor_status

energy_readings

switch_events

sensor_history
```

Then verify upstream producers.

---

## Updates Not Working

Check:

```text
GitHub Release

APK Asset

HTTPS URL

Version Number
```

---

# COMMON FUTURE ENHANCEMENTS

---

## Inventory Roadmap

```text
Expiry Tracking

Batch Tracking

Barcode Integration

RFID Integration
```

---

## Telemetry Roadmap

```text
MQTT

Node-RED

PLC

Advanced Analytics
```

---

## Administration Roadmap

```text
SSO

Microsoft Entra ID

Advanced Auditing

Workflow Automation
```

---

## Mobile Roadmap

```text
Offline Inventory Sync

Push Notifications

Camera Scanning
```

---

# DO NOT TOUCH WITHOUT REVIEW

The following require architecture review before modification:

```text
manage_user_account()

claim_registration_provisioning()

create_registration_profile()

apply_stock_movement()

prevent_stock_movement_mutation()

Auth Flow

RoleAccessService
```

---

# DEVELOPER SUCCESS CRITERIA

A new developer is considered ready when able to:

```text
Run Application

Authenticate

Create Inventory

Process Stock Movement

Approve Registration

Deploy Migration

Publish Release

Investigate Audit Logs
```

without assistance.

---

# PROJECT MAINTAINABILITY ASSESSMENT

Current state:

```text
Well Structured

Service Based

Documented

Tested

Extensible

Suitable For Long-Term Maintenance
```

Known concerns:

```text
Migration Drift

Legacy Components

Unimplemented Employee Login

Telemetry Expansion Gap
```

These are manageable and non-critical.

---

# FINAL HANDOVER CHECKLIST

Before transferring ownership provide:

```text
Source Code

Supabase Access

GitHub Access

Environment Variables

Database Documentation

Service Documentation

Security Documentation

Workflow Documentation

Deployment Guide
```

---

# DOCUMENT SET COMPLETION STATUS

```text
01 System Overview                     ✅

02 Functional Requirements             ✅

03 Architecture Overview               ✅

04 Database Reference                  ✅

05 Service & API Reference             ✅

06 UI & Screen Documentation           ✅

07 Security Architecture               ✅

08 Hardware & Telemetry                ✅

09 Update & Deployment                 ✅

10 Testing & Technical Debt            ✅

11 Workflows & Business Processes      ✅

12 Developer Guide & Maintenance       ✅
```

---

END OF DOCUMENT

INVWISE_12_DEVELOPER_GUIDE_AND_MAINTENANCE_MANUAL.md

Version 2.0.0

Project Documentation Suite Complete

---

# CURRENT MAINTENANCE NOTES — 2026-11-09

## GitHub Update Cache

`AppUpdateService` stores latest-release and history responses separately in
`OfflineCacheService`, scoped to the updater and retained as fresh for one
hour. History is keyed by page size. Cache hits suppress network calls; an
HTTP 403/429 uses stale cached data with a clear notice. If no cache is
available, return an unavailable status with retry guidance. Keep the GitHub
JSON `Accept` and `User-Agent` headers on every API request. Do not replace the
friendly UI handling with raw `ClientException` text.

## Permanent Inventory Deletion

Archive/restore use their UUID RPCs. The safe permanent-delete overload is
`permanently_delete_inventory_item(p_item_id uuid)`; the explicit mode is
`permanently_delete_inventory_item(p_item_id uuid, p_force_delete boolean)`.
Both require an archived item and an active Super Admin for deletion. The UI
requires typing `DELETE` and password re-confirmation. Safe mode blocks on
stock movements/counts and preserves history. Force mode purges linked
movement/count/level and plural activity-log records while writing a distinct
deletion audit event. It is irreversible; prefer archiving and obtain retention
approval before force deletion.

## Required Migration and Deployment Order

1. Review and reconcile remote/local Supabase migration history.
2. Verify the archive and permanent-delete RPC setup is present in staging.
   Apply `20261109213000_force_delete_stock_movement_bypass.sql` as the
   forward-only trigger/RPC repair.
3. Run
   `supabase db query --db-url $env:INVWISE_STAGING_DB_URL --file supabase/tests/permanent_inventory_force_delete.sql`
   using a disposable staging connection. Do not use the linked production
   project for this test. It verifies normal delete/update denial, item-scoped
   and Super Admin bypass checks, the safe RPC block, and successful Force
   Delete cleanup, then rolls the fixture back.
4. Verify both RPC overloads, grants, audit entry, and unauthorized-role
   rejection on disposable data.
5. Refresh PostgREST schema cache and deploy the Flutter client only after the
   two-argument RPC and trigger update are present.
6. Repeat verification in production under the approved change window.

Do not use a bulk migration push until older migration-ledger discrepancies
have been resolved.

## Profile Photo Development and Deployment

The profile photo flow is implemented by `ProfilePhotoService`,
`ProfileService.updateCurrentAvatar`, `ProfileAvatar`,
`ProfilePhotoCropScreen`, and `ProfilePhotoEditor`. After picker selection,
the crop screen enforces a fixed square 1:1 crop with zoom/pan and circular
preview. The crop is resized to 512 × 512 and encoded as JPEG at quality 85.
`ProfilePhotoService.upload` accepts only bytes with a valid JPEG signature
that decode to exactly 512 × 512; original picker files and other dimensions
are rejected. Objects use a fresh UUID filename under the current auth-user
UUID and upload with `upsert: false`. The profile RPC runs before old-object
cleanup so a failed update does not remove the active avatar. The Flutter crop
widget has no platform-native crop dependency and works on Windows, Android,
and iOS; `image_picker` provides platform-native file/gallery and camera
selection.

Before deploying the client, review and apply
`supabase/migrations/20261109214000_profile_photo_management.sql` to staging.
Verify the `avatar_url` column, public bucket size/MIME settings, owner-only
insert/delete policies, `authenticated`-only RPC grant, wrong-user path
rejection, and activity-log actions for upload/replacement/removal. Test
gallery selection on Windows/Android/iOS, camera capture on iOS/Android,
square crop gestures, 512 × 512 JPEG output, image load failure fallback, and
cleanup-failure messaging. Only after staging
verification should the migration and client be promoted to production.

Run the database authorization/configuration assertions in
`supabase/tests/profile_photo_management.sql` against the disposable staging
database after migration. It verifies the RPC grant, bucket settings, owner
policies, and foreign-folder rejection, then rolls back its transaction.

The bucket is public-read. This enables avatars in dashboard and user lists but
means anyone with an object URL can view the image. Never upload confidential
images. No migration has been applied to the linked production database for
this feature.
