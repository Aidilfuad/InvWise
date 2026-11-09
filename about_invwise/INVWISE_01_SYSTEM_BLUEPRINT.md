# INVWISE_01_SYSTEM_BLUEPRINT
## Complete System Blueprint, Architecture, Workflow & Replication Guide
### Version 2.0.0
### Source of Truth for Rebuilding InvWise From Zero

---

# DOCUMENT PURPOSE

This document exists to answer one question:

> "If all source code disappeared tomorrow, could a developer rebuild InvWise from this document alone?"

The answer should be:

```text
YES
```

This document explains:

- What every major component does
- Why each component exists
- How all systems communicate
- How data flows through the platform
- How another developer could recreate InvWise

This is the core architectural document.

---

# DOCUMENT RELATIONSHIP

Read documents in this order:

```text
INVWISE_00_EXECUTIVE_OVERVIEW.md
↓
INVWISE_01_SYSTEM_BLUEPRINT.md
↓
INVWISE_02_DEVELOPER_PLAYBOOK.md
↓
INVWISE_03_PROJECT_STATE_V2_0_0.md
```

---

# SYSTEM OVERVIEW

InvWise is an industrial inventory intelligence platform.

It combines:

```text
Inventory Management
Warehouse Management
Audit Tracking
User Provisioning
Security Controls
Telemetry Monitoring
GitHub-Based Updating
```

into a single system.

---

# COMPLETE SYSTEM ARCHITECTURE

```text
────────────────────────────────────

                USER

────────────────────────────────────
                    │
                    ▼

          FLUTTER APPLICATION

                    │

────────────────────────────────────

            BUSINESS LOGIC

────────────────────────────────────

                    │
                    ▼

             SERVICE LAYER

                    │

────────────────────────────────────

             SUPABASE API

────────────────────────────────────

                    │
                    ▼

             POSTGRESQL

                    │

────────────────────────────────────

             HARDWARE

────────────────────────────────────

                    │
                    ▼

                 DDS669

                    +

             TOGGLE SWITCH

────────────────────────────────────
```

---

# SYSTEM MODULES

The platform consists of eight major subsystems.

```text
1. Authentication

2. User Provisioning

3. Inventory Management

4. Warehouse Management

5. Audit & Activity Tracking

6. Dashboard & Analytics

7. Telemetry Monitoring

8. Update Management
```

Each subsystem is explained below.

---

# MODULE 1
# AUTHENTICATION SYSTEM

---

## PURPOSE

Authentication determines:

```text
Who the user is

What the user can access

What permissions the user receives
```

---

## LOGIN METHODS

InvWise supports:

### Method 1

```text
Employee ID + Password
```

Example:

```text
EMP-1001
password123
```

---

### Method 2

```text
Email + Password
```

Example:

```text
aidil@company.com
password123
```

---

## AUTHENTICATION FLOW

```text
User enters Employee ID

↓

Flutter App

↓

Edge Function

↓

Lookup Email

↓

Supabase Auth

↓

JWT Access Token

↓

Dashboard
```

---

## WHY EMPLOYEE ID LOGIN EXISTS

Industrial users often do not remember:

```text
Long Email Addresses
```

but always know:

```text
Employee IDs
```

Example:

```text
EMP-1001
EMP-1002
EMP-1003
```

This is why InvWise supports Employee ID login.

---

# MODULE 2
# USER PROVISIONING SYSTEM

---

## PURPOSE

Control who is allowed into the system.

InvWise is intentionally designed so that:

```text
Users CANNOT create accounts themselves.
```

---

## REGISTRATION FLOW

### Step 1

User submits:

```text
Name
Email
Employee ID
Department
Role Request
```

---

### Step 2

Record stored as:

```text
Pending Request
```

---

### Step 3

Admin reviews request.

Options:

```text
Approve

Reject
```

---

### Step 4

If approved:

```text
Provision Approved Registration
```

Edge Function executes.

Creates:

```text
Auth User

Profile

Activation Token
```

---

### Step 5

User receives:

```text
Activation Link
```

---

### Step 6

User sets password.

---

### Step 7

Account becomes active.

---

# MODULE 3
# INVENTORY MANAGEMENT SYSTEM

---

## PURPOSE

Manage all inventory items.

---

## CORE INVENTORY RULE

The most important inventory rule in InvWise is:

```text
Quantity does NOT belong inside inventory_items.
```

---

### WRONG DESIGN

```text
inventory_items

id
sku
name
quantity
```

This was intentionally avoided.

---

### CORRECT DESIGN

InvWise separates inventory into:

```text
inventory_items

stock_levels

stock_movements
```

---

# INVENTORY TRIAD

---

## Table 1

### inventory_items

Defines:

```text
What the item is.
```

Example:

```text
PLC Module

SKU:
PLC-OMRON-001
```

Contains:

```text
Name

SKU

Description

Category

Unit

Minimum Stock

Price
```

---

## Table 2

### stock_levels

Defines:

```text
Where inventory currently exists.
```

Example:

```text
Warehouse A
Quantity = 40

Warehouse B
Quantity = 20
```

---

## Table 3

### stock_movements

Defines:

```text
How inventory changed.
```

Example:

```text
+50

-10

+100

-5
```

---

# INVENTORY ACTIONS

Current actions:

```text
Create Item

Edit Item

Archive Item

Restore Item

Permanent Delete

Search

Filtering
```

---

# ARCHIVE SYSTEM

Introduced in V2.0

Additional fields:

```sql
is_archived

archived_at

archived_by
```

---

## Archive

Moves item out of active inventory.

Item remains stored.

History preserved.

---

## Restore

Returns archived item to active inventory.

---

## Permanent Delete

Removes item completely.

Only for privileged users.

---

# MODULE 4
# WAREHOUSE MANAGEMENT

---

## PURPOSE

Track physical storage locations.

---

## INVENTORY PHILOSOPHY

Knowing:

```text
50 Relay Modules
```

is useless.

Need to know:

```text
Warehouse A

Shelf B

Rack C

Bin D
```

---

## SUPPORTED ACTIONS

```text
Create Warehouse

Edit Warehouse

Deactivate Warehouse
```

---

# DEACTIVATION RULE

Warehouse may contain historical records.

Deleting it could break:

```text
Reports

History

Stock Movements
```

Therefore:

```text
Deactivate

NOT

Delete
```

---

# MODULE 5
# AUDIT & ACTIVITY TRACKING

---

## PURPOSE

Provide traceability.

Answer:

```text
Who did something?

What happened?

When?

Why?
```

---

## ACTIVITY LOGS

Track:

```text
Inventory Actions

User Actions

System Events
```

---

## CURRENT FILTERS

```text
Search

Category

Date Range
```

---

## REMOVED

```text
User Filter
```

Removed in V2.0.

Search still supports usernames.

---

# STOCK MOVEMENTS

This table is treated as:

```text
Immutable Ledger
```

Meaning:

```text
Never Edit

Never Delete

Only Add
```

---

# MODULE 6
# DASHBOARD SYSTEM

---

# FULL DASHBOARD

Purpose:

```text
Managers

Presentations

FYP Demonstrations
```

Contains:

```text
Greeting

Sync Status

Inventory Overview

KPI Cards

Attention Required

Recent Activity

Inventory Summary

Sensor Monitoring

System Health
```

---

# ATTENTION REQUIRED

Replaced older alert flow.

Current:

```text
Dashboard

↓

Attention Required

↓

Alerts & Tasks
```

---

# REMOVED

```text
Inventory Alerts Widget

Inventory Alerts Page
```

---

# MODULE 7
# TELEMETRY MONITORING

---

## PURPOSE

Monitor external devices.

---

# ACTUAL DEVICES

Current production hardware:

```text
DDS669

Toggle Switch
```

Only.

---

# DDS669

Current metrics:

```text
Voltage

Current

Power

Energy
```

---

# TOGGLE SWITCH

Current metrics:

```text
ON

OFF

Status

Last Updated
```

---

# DATA FLOW

```text
DDS669

↓

Node-RED

↓

Supabase

↓

InvWise Dashboard
```

---

# DATA FLOW

```text
Toggle Switch

↓

Node-RED

↓

Supabase

↓

InvWise Dashboard
```

---

# REMOVED SENSOR SUPPORT

The following were removed:

```text
IRIV

Receipt Count

Trigger Count

Last Detection
```

Reason:

Hardware does not exist.

---

# MODULE 8
# UPDATE MANAGEMENT

---

# OLD SYSTEM

Version 1.x used:

```text
Supabase

app_versions table
```

Manual release updates required.

---

# NEW SYSTEM

Version 2.0 uses:

```text
GitHub Releases
```

---

## RELEASE FLOW

Developer:

```text
Build APK

↓

Upload Release

↓

GitHub Release
```

Users:

```text
Open App

↓

Check Updates

↓

Compare Versions

↓

Download New APK
```

---

# FORCE UPDATE SYSTEM

Current behaviour:

Before launching update URL:

```text
No Dismiss

No Close Button
```

After launch succeeds:

```text
X Button Available

Dismiss Allowed

Download Started
```

---

# DATABASE OVERVIEW

Major entities:

```text
profiles

inventory_items

stock_levels

stock_movements

warehouse_locations

categories

units

activity_logs

device_sessions

login_events
```

---

# RELATIONSHIP OVERVIEW

```text
profiles

↓

inventory_items

↓

stock_levels

↓

stock_movements

↓

warehouse_locations
```

---

# SERVICE LAYER OVERVIEW

Major services:

```text
AuthService

InventoryService

DashboardService

ActivityLogService

ProfileService

WarehouseLocationService

StockMovementService

ReportsService

AppUpdateService

SensorMonitoringService
```

Rule:

```text
UI

↓

Services

↓

Supabase

↓

Database
```

Never allow pages to directly access database logic.

---

# CURRENT RELEASE ARCHITECTURE

Release:

```text
v2.0.0
```

Capabilities:

```text
Authentication

Registration

Provisioning

Inventory

Warehouses

Reports

Activity Logs

Archive System

Dashboard

Telemetry

GitHub Updates
```

Status:

```text
Production Ready
```

---

# WHAT MUST NEVER BE CHANGED

1.

```text
RLS must remain enabled.
```

2.

```text
Service Role Key
must never enter Flutter code.
```

3.

```text
Stock movements
must remain immutable.
```

4.

```text
Warehouse history
must remain preserved.
```

5.

```text
Inventory quantities
must remain derived from stock_levels.
```

---

# REBUILD CHECKLIST

A developer recreating InvWise from zero should build these systems in order:

```text
1. Supabase Project

2. Database Schema

3. RLS Policies

4. Authentication

5. Registration Workflow

6. Inventory System

7. Warehouses

8. Stock Movements

9. Activity Logs

10. Dashboard

11. DDS669 Integration

12. Toggle Switch Integration

13. GitHub Update System

14. Reports

15. Final Testing
```

---

END OF DOCUMENT

INVWISE_01_SYSTEM_BLUEPRINT.md

Version 2.0.0
