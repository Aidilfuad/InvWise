# INVWISE_02_DEVELOPER_PLAYBOOK
## Complete Developer Survival Guide
### Everything A Developer Must Know Before Modifying InvWise
### Version 2.0.0

---

# PURPOSE OF THIS DOCUMENT

This document exists to answer:

> "I have the source code. Now what?"

This guide is written for:

```text
Future Aidil

New Developers

FYP Successors

AI Assistants

Software Engineers

Consultants

Maintenance Teams
```

The goal is simple:

A completely new person should be able to:

```text
Run the system

Understand the project

Safely modify the code

Deploy updates

Fix bugs

Add new modules
```

without destroying existing functionality.

---

# BEFORE YOU TOUCH THE CODE

Read this first.

InvWise is not a normal CRUD application.

Many developers make mistakes because they assume:

```text
Inventory System = Create + Read + Update + Delete
```

InvWise does not work that way.

The system was built around:

```text
Data Integrity

Auditability

Security

Traceability
```

If convenience and integrity conflict:

```text
Integrity wins.
```

Every time.

---

# GOLDEN RULES

These rules should never be violated.

---

## RULE 1

Never disable RLS.

```sql
ALTER TABLE ...

ENABLE ROW LEVEL SECURITY;
```

must remain active.

If a feature stops working:

```text
Fix the RLS.

Do NOT disable RLS.
```

---

## RULE 2

Never expose service_role.

Never put:

```text
Service Role Key
```

inside:

```text
Flutter

React

GitHub
```

The service role belongs only in:

```text
Edge Functions
```

---

## RULE 3

Never edit stock history.

This table:

```text
stock_movements
```

must remain:

```text
Immutable
```

Meaning:

```text
INSERT = Allowed

UPDATE = Forbidden

DELETE = Forbidden
```

---

## RULE 4

Never store inventory quantity inside:

```text
inventory_items
```

Quantity belongs to:

```text
stock_levels
```

Always.

---

## RULE 5

Never hard-delete warehouses with history.

Instead:

```text
Deactivate Warehouse
```

---

# DEVELOPMENT ENVIRONMENT

---

## Required Software

### Flutter

Recommended:

```text
Flutter 3.x or newer
```

---

### Dart

```text
Latest Stable
```

---

### Android Studio

Required for:

```text
Android SDK

Emulator

Build Tools
```

---

### VS Code

Recommended IDE.

Extensions:

```text
Flutter

Dart

GitHub Copilot

Error Lens

SQLTools

Markdown Preview
```

---

### Node.js

Required for:

```text
Activation Portal

Build Scripts

Tooling
```

Recommended:

```text
18+
```

---

### Supabase CLI

Required for:

```text
Functions

Migrations

Database Management
```

---

# PROJECT STRUCTURE

---

## Root

```text
InvWise/

android/

ios/

linux/

macos/

web/

windows/

lib/

supabase/

activation-portal/

test/
```

---

# FLUTTER STRUCTURE

---

## lib/

This contains the application.

```text
lib/
```

Everything important lives here.

---

# APP FOLDER

```text
lib/app/
```

Contains:

```text
Theme

Routes

Constants

Configuration
```

---

### Main Files

```text
app_routes.dart

app_theme.dart

supabase_config.dart
```

---

# FEATURES FOLDER

```text
lib/features/
```

Each feature is isolated.

Example:

```text
auth/

dashboard/

inventory/

reports/

settings/

alerts/
```

---

# SERVICES FOLDER

```text
lib/services/
```

This is the heart of InvWise.

Business logic belongs here.

NOT inside UI.

---

# IMPORTANT SERVICES

---

## AuthService

Purpose:

```text
Authentication

Login

Logout

Session Control
```

Used by:

```text
Login Page

Registration
```

---

## InventoryService

Purpose:

```text
Create Item

Edit Item

Archive

Restore

Delete

Search
```

Most inventory work happens here.

---

## DashboardService

Purpose:

```text
KPIs

Inventory Overview

Statistics

Dashboard Data
```

---

## SensorMonitoringService

Purpose:

```text
DDS669

Toggle Switch

Telemetry
```

---

## ActivityLogService

Purpose:

```text
User Actions

Inventory Actions

System Events
```

---

## AppUpdateService

Purpose:

```text
GitHub Releases

Version Comparison

Update Detection
```

---

# HOW DATA FLOWS

---

## Wrong Way

```text
Page

↓

Database
```

Never do this.

---

## Correct Way

```text
Page

↓

Service

↓

Supabase

↓

Database
```

Always.

---

# DASHBOARD SYSTEM

InvWise contains:

```text
Full Dashboard
```

---

# FULL DASHBOARD

Purpose:

```text
Managers

Presentations

FYP Demonstration
```

Contains:

```text
Inventory Overview

KPI Grid

Attention Required

Recent Activity

Inventory Summary

System Health

Sensor Monitoring
```

---

# SENSOR SYSTEM

---

## Current Supported Hardware

```text
DDS669

Toggle Switch
```

---

## DDS669

Display:

```text
Voltage

Current

Power

Energy
```

---

## Toggle Switch

Display:

```text
Current State

Online Status

Last Updated
```

---

# DO NOT REINTRODUCE

These were intentionally removed:

```text
IRIV

Trigger Count

Receipt Count

Last Detection
```

unless the hardware actually exists.

---

# ALERT SYSTEM

Old architecture:

```text
Dashboard

↓

Inventory Alerts Widget

↓

Inventory Alerts Page
```

Removed.

---

Current architecture:

```text
Dashboard

↓

Attention Required

↓

Alerts & Tasks
```

This is now the only alert management workflow.

---

# ACTIVITY LOGS

---

## Current Filters

```text
Search

Category

Date Range
```

---

## Removed

```text
User Filter
```

This was intentionally removed.

Search already supports username searching.

---

# INVENTORY SYSTEM

---

# inventory_items

Stores:

```text
Name

SKU

Description

Unit

Category

Price

Minimum Stock
```

---

## New Archive Fields

Added in V2.0:

```sql
is_archived

archived_at

archived_by
```

---

# stock_levels

Stores:

```text
Current Quantity

Current Location
```

---

# stock_movements

Stores:

```text
History
```

Example:

```text
+ 50

- 20

+ 10

- 5
```

Never edit.

---

# USER REGISTRATION SYSTEM

---

## Registration Request

User submits:

```text
Name

Email

Employee ID

Department
```

---

## Approval

Admin decides:

```text
Approve

Reject
```

---

## Provisioning

Edge Function creates:

```text
Auth Account

Profile

Token
```

---

## Activation

User receives:

```text
Activation Portal Link
```

and creates a password.

---

# UPDATE SYSTEM

---

# OLD SYSTEM

Used:

```text
app_versions
```

inside Supabase.

Required manual updates.

---

# NEW SYSTEM

Uses:

```text
GitHub Releases
```

---

# RELEASE PROCESS

---

## Build APK

```bash
flutter build apk --release
```

---

## Rename

```text
InvWise-v2.0.0.apk
```

---

## Git Commit

```bash
git add .

git commit -m "release: InvWise v2.0.0"
```

---

## Push

```bash
git push origin main
```

---

## Create Release

GitHub:

```text
Create Release

Tag:
v2.0.0

Upload APK
```

---

## Publish

Done.

---

# DATABASE MIGRATIONS

Location:

```text
supabase/migrations/
```

---

## Rule

Never modify old migrations.

Create new migrations.

Example:

```text
20261109030000_add_supplier_module.sql
```

---

# WHEN ADDING NEW MODULES

Follow this process.

---

# Step 1

Database

Create migration.

---

# Step 2

Service

Create service.

Example:

```text
SupplierService
```

---

# Step 3

UI

Create:

```text
Page

Widgets

Dialogs
```

---

# Step 4

Routes

Update:

```text
app_routes.dart
```

---

# Step 5

Permissions

Update:

```text
Role Access

RLS

Navigation
```

---

# TESTING PROCESS

Always run:

```bash
flutter analyze
```

---

Then:

```bash
flutter test
```

---

Then:

```bash
flutter build apk --release
```

---

If these fail:

```text
Do not push.
```

---

# COMMON BUGS

---

## Bug 1

Inventory archive error.

Cause:

```text
Missing is_archived column.
```

Fix:

```sql
add column is_archived
```

---

## Bug 2

Update system detects nothing.

Check:

```text
GitHub Release

Tag Name
```

---

## Bug 3

Telemetry not appearing.

Check:

```text
Node-RED

Supabase

Sensor Table
```

---

## Bug 4

Dashboard widgets disappear.

Usually caused by:

```text
Null KPI data

Bad service response
```

---

# FUTURE DEVELOPMENT PRIORITIES

Not completed yet:

---

## Priority 1

Physical DDS669 Verification

---

## Priority 2

Physical Toggle Verification

---

## Priority 3

Production Stability Testing

---

## Priority 4

Documentation Expansion

---

## Priority 5

Web Version Expansion

---

# IF YOU ARE AN AI ASSISTANT

Before making changes:

Understand:

```text
Inventory

Stock Levels

Stock Movements

Archives

Activity Logs

Update System
```

Then verify:

```text
Will this change break auditability?

Will this change reduce security?

Will this change damage traceability?
```

If yes:

```text
Do not implement blindly.
```

---

# DEVELOPER CHECKLIST

Before every release:

```text
✅ flutter analyze

✅ flutter test

✅ Build APK

✅ Verify Login

✅ Verify Dashboard

✅ Verify Inventory

✅ Verify Alerts

✅ Verify Activity Logs

✅ Verify DDS669

✅ Verify Toggle Switch

✅ Verify Update Check

✅ Create GitHub Release
```

---

# FINAL ADVICE FROM THE ORIGINAL MAINTAINER

InvWise is not difficult because of the code.

InvWise is difficult because of the rules.

Anyone can rebuild screens.

Anyone can rewrite Flutter widgets.

The real value of InvWise is preserving:

```text
Security

Audit Trails

Inventory Integrity

User Accountability
```

If those remain intact, the platform can evolve indefinitely.

---

END OF DOCUMENT

INVWISE_02_DEVELOPER_PLAYBOOK.md

Version 2.0.0
