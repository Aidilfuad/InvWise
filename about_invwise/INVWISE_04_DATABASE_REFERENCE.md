# INVWISE_04_DATABASE_REFERENCE
## Complete Database Reference
### Live Production Schema Documentation
### Version 2.0.0
### Source: Live Supabase Database
### Last Updated: November 2026

---

# PURPOSE OF THIS DOCUMENT

This document exists to answer one question:

> "If the database disappeared today, could another developer rebuild it correctly?"

The answer should be:

```text
YES
```

---

# DATABASE OVERVIEW

InvWise currently operates on:

```text
Supabase PostgreSQL
```

Production schema contains:

```text
25 Tables

2 Database Views

9 ENUM Types

15 Functions / RPCs

Multiple Triggers

Row Level Security Policies
```

Database design follows:

```text
Inventory Integrity

Auditability

Traceability

Role-Based Access

Telemetry Integration
```

---

# DATABASE DOMAINS

The database can be divided into:

```text
Authentication

User Management

Registration

Inventory

Warehouses

Stock Movement

Tasks

Activity Logs

Security

Telemetry

System Settings

Application Updates

Support Requests
```

---

# DATABASE RELATIONSHIP OVERVIEW

```text
profiles
│
├── device_sessions
├── login_events
├── user_settings
├── registration_requests
├── tasks
├── stock_counts
├── stock_movements
├── inventory_items
└── support_requests

inventory_items
│
├── stock_levels
├── stock_movements
├── stock_counts
└── tasks

warehouse_locations
│
├── stock_levels
├── stock_movements
├── stock_counts
└── tasks

sensors
│
├── sensor_status
├── sensor_history
├── energy_readings
├── switch_events
└── sensor_alerts
```

---

# USER MANAGEMENT MODULE

---

## profiles

Purpose:

```text
Primary user table.

Represents all InvWise users.
```

---

### Important Columns

```sql
id UUID PK

auth_user_id UUID

employee_id TEXT UNIQUE

full_name TEXT

email TEXT UNIQUE

phone TEXT

department TEXT

avatar_url TEXT NULL -- pending forward migration; not live yet

role USER_ROLE

access_level ACCESS_LEVEL

is_active BOOLEAN

last_login_at TIMESTAMPTZ

created_at

updated_at
```

---

### Role Values

```text
Super Admin

Inventory Administrator

Warehouse Supervisor

Storekeeper
```

---

### Access Levels

```text
Admin

Supervisor

User
```

---

### Relationships

```text
profiles
↓
inventory_items.created_by

profiles
↓
tasks.created_by

profiles
↓
stock_movements.performed_by

profiles
↓
device_sessions.profile_id

profiles
↓
login_events.profile_id
```

---

### Important Notes

```text
Every user must have:

Employee ID
Email
Role
```

Employee ID is unique.

Email is unique.

Auth User ID maps directly to:

Supabase Auth
```

---

# USER SETTINGS

---

## user_settings

Purpose:

```text
Stores per-user preferences.
```

---

### Columns

```sql
profile_id UUID PK

language_code TEXT

theme_mode THEME_MODE

currency_code TEXT

created_at

updated_at
```

---

### Theme Modes

```text
light

dark

system
```

---

### Currency

```text
MYR

USD
```

---

# DEVICE SECURITY

---

## device_sessions

Purpose:

```text
Tracks active devices.
```

---

### Tracks

```text
Device Name

Platform

IP Address

User Agent

Session Start

Last Activity

Revocation State
```

---

## login_events

Purpose:

```text
Tracks authentication activity.
```

---

### Tracks

```text
Employee ID

Success

Failure Reason

IP

User Agent

Timestamp
```

---

# REGISTRATION SYSTEM

---

## registration_requests

Purpose:

```text
Stores pending account requests.
```

---

### Lifecycle

```text
pending
↓
approved
↓
provisioned
↓
activated
```

---

### Important Fields

```sql
full_name

employee_id

email

department

requested_role

status

approved_at

approved_by

provisioning_status

provisioning_auth_user_id

invited_at

completed_at
```

---

### Requested Roles

```text
Warehouse Supervisor

Storekeeper
```

---

### Provisioning States

```text
not_started

in_progress

invited

completed

failed
```

---

# INVENTORY MODULE

---

## inventory_items

Purpose:

```text
Master inventory catalog.
```

---

### Core Fields

```sql
id UUID PK

sku UNIQUE

name

description

category_id

unit_id

minimum_stock

unit_price

notes
```

---

### Archive Fields

```sql
is_archived BOOLEAN

archived_at TIMESTAMPTZ

archived_by UUID
```

---

### Important Rule

Quantity is NOT stored here.

Never put stock quantity in:

```text
inventory_items
```

Quantity belongs in:

```text
stock_levels
```

---

### Relationships

```text
inventory_items
↓
stock_levels

inventory_items
↓
stock_movements

inventory_items
↓
stock_counts

inventory_items
↓
tasks
```

---

# CATEGORIES

---

## categories

Purpose:

```text
Inventory categorization.
```

Examples:

```text
Electrical

Mechanical

Consumables

Tools
```

---

### Key Fields

```sql
name UNIQUE

description

is_active
```

---

# UNITS

---

## units

Purpose:

```text
Measurement units.
```

Examples:

```text
pcs

box

kg

meter
```

---

### Fields

```sql
name

abbreviation UNIQUE

description

is_active
```

---

# WAREHOUSES

---

## warehouse_locations

Purpose:

```text
Physical storage locations.
```

---

### Fields

```sql
code UNIQUE

name

description

address

capacity

is_active
```

---

### Important Rule

Never hard delete locations with history.

Use:

```text
is_active = false
```

instead.

---

# STOCK MANAGEMENT

---

## stock_levels

Purpose:

```text
Current inventory quantities.
```

---

### Primary Key

```sql
(item_id, location_id)
```

Composite key.

---

### Fields

```sql
item_id

location_id

quantity

updated_at
```

---

### Golden Rule

```text
Current Quantity

Lives Here
```

not in inventory_items.

---

## stock_movements

Purpose:

```text
Permanent inventory transaction ledger.
```

---

### Movement Types

```text
receipt

issue

adjustment

transfer

return
```

---

### Trigger

```sql
stock_movements_apply_stock
```

Automatically updates:

```text
stock_levels
```

---

### Important Protection

```sql
prevent_stock_movement_mutation()
```

Blocks:

```text
UPDATE

DELETE
```

---

### Therefore

Stock history is:

```text
IMMUTABLE
```

---

# STOCK COUNT SYSTEM

---

## stock_counts

Purpose:

```text
Physical stock verification.
```

---

### Workflow

```text
draft
↓
submitted
↓
approved
```

---

### Generated Field

```sql
variance_quantity
```

Automatically calculated.

---

### Approval Trigger

Approving variance can create:

```text
stock_movements
```

automatically.

---

# TASK MANAGEMENT

---

## tasks

Purpose:

```text
Operational task management.
```

---

### Status

```text
open

in_progress

completed

cancelled
```

---

### Priority

```text
low

normal

high

urgent
```

---

### Relationships

```text
Profiles

Inventory

Warehouses
```

---

# ACTIVITY LOGGING

---

## activity_log

Purpose:

```text
Legacy audit table.
```

Stores:

```text
Inventory Events

Location Events

Movement Events
```

---

## activity_logs

Purpose:

```text
New Enterprise Audit System.
```

Stores:

```text
Category

Action

Entity

Metadata

Actor

Timestamp
```

---

### Current Recommendation

Prefer:

```text
activity_logs
```

for future development.

Legacy:

```text
activity_log
```

requires review before removal.

---

# TELEMETRY MODULE

---

## sensors

Purpose:

```text
Registered telemetry devices.
```

---

### Current Active Devices

```text
DDS669_01

SW_01
```

---

### Supported Types

```text
energy_meter

toggle_switch

plc_counter

rfid_reader

barcode_scanner

generic_sensor
```

---

## sensor_status

Purpose:

```text
Latest sensor state.
```

Current value.

Current status.

Last seen.

---

## sensor_history

Purpose:

```text
Historical telemetry values.
```

---

## energy_readings

Purpose:

```text
DDS669 Energy Data
```

Fields:

```text
Voltage

Current

Power

Energy
```

---

### Processing Trigger

```sql
fn_process_energy_reading()
```

Updates:

```text
sensor_status

sensor_history
```

automatically.

---

## switch_events

Purpose:

```text
Toggle Switch Events
```

---

### Processing Trigger

```sql
fn_process_switch_event()
```

Updates:

```text
sensor_status

sensor_history
```

automatically.

---

## sensor_alerts

Purpose:

```text
Telemetry Alert Management
```

---

### Alert Types

```text
high_voltage

high_current

sensor_offline
```

---

### Severity

```text
warning

critical
```

---

## telemetry_settings

Purpose:

```text
Telemetry configuration.
```

---

### Stores

```text
Voltage Threshold

Current Threshold

Offline Timeout

Realtime Enabled
```

---

# APPLICATION SETTINGS

---

## app_settings

Purpose:

```text
Global system settings.
```

---

### Current Fields

```text
Exchange Rate

Updated Timestamp
```

---

## app_versions

Purpose:

```text
Legacy update table.
```

---

### Status

```text
Deprecated
```

Current update system uses:

```text
GitHub Releases
```

instead.

Keep table for compatibility until officially removed.

---

# SUPPORT SYSTEM

---

## support_requests

Purpose:

```text
Built-in helpdesk requests.
```

---

### Fields

```text
Subject

Message

Status

Profile
```

---

### Linked Edge Function

```text
notify-support-request
```

---

# DATABASE VIEWS

---

## inventory_alerts

Purpose:

```text
Low Stock

Out Of Stock
```

Generated automatically from:

```text
stock_levels

inventory_items

warehouse_locations
```

---

## inventory_items_with_quantity

Purpose:

```text
Inventory + Total Quantity
```

Provides:

```text
inventory item

aggregated stock quantity
```

in a single query.

---

# CRITICAL DATABASE FUNCTIONS

---

## apply_stock_delta()

Updates stock quantity safely.

---

## apply_stock_movement()

Processes stock transactions.

---

## manage_user_account()

Handles:

```text
Role changes

Activation

Deactivation
```

Includes protection:

```text
At least one active
Super Admin
must remain.
```

---

## claim_registration_provisioning()

Claims provisioning task.

Prevents race conditions.

---

## create_registration_profile()

Creates approved account.

---

## prevent_stock_movement_mutation()

Protects audit integrity.

---

## prune_telemetry_history()

Telemetry cleanup.

---

## set_updated_at()

Universal update timestamp trigger.

Used throughout system.

---

# CURRENT DATABASE FACTS

```text
25 Tables

2 Views

9 ENUMS

15 Functions

DDS669 Supported

Toggle Switch Supported

Archive System Enabled

Task System Enabled

Stock Count System Enabled

Support Request System Enabled

GitHub Updater Active

app_versions Legacy

Stock Movement Immutable
```

---

## Profile Photo Forward Migration

`supabase/migrations/20261109214000_profile_photo_management.sql` adds the
nullable `profiles.avatar_url` column, provisions the public-read
`profile-photos` bucket (5 MiB limit; JPEG, PNG, and WebP), owner-folder
Storage INSERT/DELETE policies, and
`public.update_current_profile_avatar(p_object_path text)`.

The migration has not been applied to the live database. Until it is deployed,
the live `profiles` table and Storage bucket do not have these additions.
The RPC requires an authenticated active profile, accepts only a photo object
under that user’s UUID folder, updates only that profile row, and writes the
upload/update/removal activity event.

---

END OF DOCUMENT

INVWISE_04_DATABASE_REFERENCE.md

Version 2.0.0
