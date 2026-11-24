# INVWISE_14_DATABASE_ERD_AND_RELATIONSHIP_GUIDE
## Complete Entity Relationship Diagram & Database Relationship Documentation
### Version 2.0.0
### Source: Database Discovery + Migration Analysis
### Database Platform: Supabase PostgreSQL

---

# PURPOSE OF THIS DOCUMENT

This document answers:

> "How are all InvWise database tables connected?"

This document provides:

```text
Database ERD

Table Relationships

Primary Keys

Foreign Keys

Parent-Child Dependencies

Module Boundaries

Data Flow Relationships
```

This document should be read together with:

```text
INVWISE_04_DATABASE_REFERENCE
```

---

# DATABASE OVERVIEW

Current Production Schema:

```text
25 Tables

2 Views

9 ENUMS

15 Functions
```

Source: DATABASE_DISCOVERY.md and migration analysis. 【1-aad882】【2-3a24e4】

---

# HIGH LEVEL ERD

```text
                 ┌───────────────┐
                 │   profiles    │
                 └───────┬───────┘
                         │
         ┌───────────────┼───────────────────┐
         │               │                   │
         ▼               ▼                   ▼

 device_sessions   login_events     user_settings

         │
         │
         ▼

 support_requests



                 ┌────────────────────┐
                 │ registration_requests │
                 └──────────┬─────────┘
                            │
                            ▼

                       profiles



 ┌─────────────┐
 │ categories  │
 └──────┬──────┘
        │
        ▼

 ┌─────────────┐
 │inventory_items│
 └──────┬──────┘
        │
        │
        ├───────────┐
        │           │
        ▼           ▼

 stock_levels   stock_movements
        │           │
        │           │
        ▼           ▼

 warehouse_locations

        │
        ▼

 stock_counts



      sensors
         │
         │
 ┌───────┼───────────────┬───────────┐
 │       │               │           │
 ▼       ▼               ▼           ▼

sensor_status   sensor_history
energy_readings switch_events

         │
         ▼

sensor_alerts
```

---

# DOMAIN RELATIONSHIP MAP

The database can be divided into:

```text
Authentication Domain

Registration Domain

Inventory Domain

Telemetry Domain

Reporting Domain

System Domain
```

---

# AUTHENTICATION DOMAIN

---

## PROFILES

Central user table.

```text
profiles
```

Acts as parent table for:

```text
device_sessions

login_events

user_settings

support_requests

tasks

inventory ownership

audit records
```

【1-aad882】

---

# AUTHENTICATION ERD

```text
profiles
   │
   ├── device_sessions
   │
   ├── login_events
   │
   ├── user_settings
   │
   ├── support_requests
   │
   ├── tasks
   │
   └── activity_logs
```

---

# PROFILE RELATIONSHIPS

---

## profiles → device_sessions

Relationship:

```text
One To Many
```

Meaning:

```text
One User

Can Have

Many Devices
```

Example:

```text
Phone

Tablet

Laptop
```

---

## profiles → login_events

Relationship:

```text
One To Many
```

Meaning:

```text
One User

Can Have

Many Login Attempts
```

---

## profiles → user_settings

Relationship:

```text
One To One
```

Meaning:

```text
One User

One Preference Record
```

---

## profiles → support_requests

Relationship:

```text
One To Many
```

Meaning:

```text
One User

Many Support Tickets
```

---

# REGISTRATION DOMAIN

---

## registration_requests

Purpose:

```text
Stores users before becoming profiles.
```

---

# REGISTRATION ERD

```text
registration_requests
            │
            ▼
       profiles
```

---

## Relationship

```text
Registration Request
         ↓
Provisioning
         ↓
Profile
```

Relationship Type:

```text
One registration request

creates

One profile
```

through provisioning workflow. 【1-aad882】【3-28b30f】

---

# INVENTORY DOMAIN

---

# INVENTORY MASTER ERD

```text
categories
      │
      ▼

inventory_items
      │
      │
      ├──────────────┐
      │              │
      ▼              ▼

stock_levels   stock_movements
      │              │
      │              │
      ▼              ▼

warehouse_locations

      │
      ▼

stock_counts
```

---

# CATEGORY RELATIONSHIP

---

## categories → inventory_items

Relationship:

```text
One To Many
```

Meaning:

```text
One Category

Many Inventory Items
```

Example:

```text
Electrical
        ↓

Motor

Contactor

Relay

Sensor
```

---

# UNIT RELATIONSHIP

---

## units → inventory_items

Relationship:

```text
One To Many
```

Meaning:

```text
One Unit

Many Inventory Items
```

Example:

```text
pcs
```

used by many items.

---

# INVENTORY ITEM RELATIONSHIPS

---

## inventory_items → stock_levels

Relationship:

```text
One To Many
```

Meaning:

```text
One Item

Stored At

Multiple Locations
```

Example:

```text
Motor

Warehouse A

Warehouse B

Warehouse C
```

---

## inventory_items → stock_movements

Relationship:

```text
One To Many
```

Meaning:

```text
One Inventory Item

Can Have

Unlimited Movements
```

---

## inventory_items → stock_counts

Relationship:

```text
One To Many
```

Meaning:

```text
One Item

Counted Multiple Times
```

---

## inventory_items → tasks

Relationship:

```text
One To Many
```

Meaning:

```text
Inventory Item

Can Generate

Multiple Tasks
```

---

# WAREHOUSE RELATIONSHIPS

---

## warehouse_locations → stock_levels

Relationship:

```text
One To Many
```

Meaning:

```text
One Warehouse

Contains

Many Items
```

---

## warehouse_locations → stock_movements

Relationship:

```text
One To Many
```

Meaning:

```text
Warehouse Participates In

Many Movements
```

---

## warehouse_locations → stock_counts

Relationship:

```text
One To Many
```

Meaning:

```text
Warehouse

Can Have

Many Count Sessions
```

---

# STOCK LEVEL RELATIONSHIP

---

## Composite Relationship

```text
inventory_items
       +
warehouse_locations
       ↓

stock_levels
```

---

Logical Key:

```text
(item_id, location_id)
```

Meaning:

```text
One Stock Quantity

Per Item

Per Location
```

---

# STOCK MOVEMENT RELATIONSHIP

---

## Core Inventory Ledger

```text
inventory_items
         │
         ▼

stock_movements

         ▲
         │

warehouse_locations
```

---

Movement Types:

```text
receipt

issue

transfer

return

adjustment
```

【1-aad882】

---

# STOCK COUNT RELATIONSHIP

---

## Physical Verification Relationship

```text
inventory_items
           │
           ▼

stock_counts

           ▲
           │

warehouse_locations
```

---

Purpose:

```text
Physical Count

vs

System Quantity
```

---

# TASK DOMAIN

---

# TASK ERD

```text
profiles
      │
      ▼

tasks

      ▲
      │

inventory_items

      ▲
      │

warehouse_locations
```

---

Meaning:

A task may reference:

```text
Person

Inventory Item

Warehouse
```

simultaneously.

---

# TELEMETRY DOMAIN

---

# TELEMETRY MASTER ERD

```text
sensors
   │
   │
   ├───────────────┐
   │               │
   ▼               ▼

sensor_status   sensor_history

   ▲               ▲
   │               │

energy_readings switch_events

   │
   ▼

sensor_alerts

   │
   ▼

telemetry_settings
```

---

# SENSOR RELATIONSHIPS

---

## sensors → sensor_status

Relationship:

```text
One To One
```

Meaning:

```text
One Device

One Current State
```

---

## sensors → sensor_history

Relationship:

```text
One To Many
```

Meaning:

```text
One Sensor

Many Historical Readings
```

---

## sensors → energy_readings

Relationship:

```text
One To Many
```

Used By:

```text
DDS669
```

Telemetry. 【4-bd5acc】

---

## sensors → switch_events

Relationship:

```text
One To Many
```

Used By:

```text
Toggle Switch
```

Telemetry. 【4-bd5acc】

---

## sensors → sensor_alerts

Relationship:

```text
One To Many
```

Meaning:

```text
One Device

Many Alerts
```

---

# TELEMETRY PROCESS RELATIONSHIP

---

## DDS669 Data Flow

```text
DDS669 Device
        │
        ▼

energy_readings
        │
        ▼

fn_process_energy_reading()
        │
        ├────► sensor_status
        │
        └────► sensor_history
```

【1-aad882】【4-bd5acc】

---

## Toggle Switch Data Flow

```text
Toggle Switch
      │
      ▼

switch_events
      │
      ▼

fn_process_switch_event()
      │
      ├────► sensor_status
      │
      └────► sensor_history
```

【1-aad882】【4-bd5acc】

---

# SUPPORT DOMAIN

---

# SUPPORT ERD

```text
profiles
      │
      ▼

support_requests
```

---

Relationship:

```text
One User

Many Support Requests
```

---

# AUDIT DOMAIN

---

# AUDIT ERD

```text
profiles
      │
      ▼

activity_logs
```

---

Current Audit System:

```text
activity_logs
```

Legacy Audit System:

```text
activity_log
```

Both exist in the database and require future review. 【5-d6a843】【1-aad882】

---

# SETTINGS DOMAIN

---

# SETTINGS ERD

```text
profiles
      │
      ▼

user_settings


app_settings
```

---

Relationship:

```text
User-Specific Settings

and

Global Application Settings
```

---

# VIEW RELATIONSHIPS

---

## inventory_items_with_quantity

Derived From:

```text
inventory_items

stock_levels
```

Purpose:

```text
Inventory

+

Aggregated Quantity
```

【1-aad882】

---

## inventory_alerts

Derived From:

```text
inventory_items

stock_levels

warehouse_locations
```

Purpose:

```text
Low Stock

Critical Stock

Inventory Warnings
```

【1-aad882】

---

# MOST IMPORTANT TABLES

Priority Ranking:

```text
1. profiles

2. inventory_items

3. stock_levels

4. stock_movements

5. warehouse_locations

6. registration_requests

7. sensors

8. sensor_history

9. activity_logs

10. support_requests
```

These tables represent most core business functionality.

---

# DATABASE RELATIONSHIP SUMMARY

```text
Profiles = User Hub

Inventory Items = Inventory Hub

Warehouse Locations = Storage Hub

Stock Movements = Audit Ledger

Sensors = Telemetry Hub

Registration Requests = User Lifecycle Hub

Activity Logs = Audit Hub
```

---

# ERD COMPLETENESS CHECK

```text
Authentication Domain           ✅

Registration Domain            ✅

Inventory Domain               ✅

Warehouse Domain               ✅

Task Domain                    ✅

Telemetry Domain               ✅

Support Domain                 ✅

Audit Domain                   ✅

Settings Domain                ✅

Reporting Views                ✅
```

---

## Profile Photo Storage Relationship

`profiles.avatar_url` stores the object path in the `profile-photos` Supabase
Storage bucket. It is an application-level reference, not a PostgreSQL foreign
key to `storage.objects`. Object paths are scoped under the authenticated
user’s UUID, and owner-only Storage policies govern upload/deletion. The
bucket is public-read so avatar images render in user lists.

This relationship is provided by migration
`20261109214000_profile_photo_management.sql`, which has not been applied to
the live database.

---

END OF DOCUMENT

INVWISE_14_DATABASE_ERD_AND_RELATIONSHIP_GUIDE.md

Version 2.0.0
