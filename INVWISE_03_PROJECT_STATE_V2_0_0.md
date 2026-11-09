# INVWISE_03_PROJECT_STATE_V2_0_0
## Current System State Snapshot
### The Truth About InvWise Right Now
### Version 2.0.0
### Last Updated: November 2026

---

# PURPOSE OF THIS DOCUMENT

This document is not a technical blueprint.

This document is not a handbook.

This document is a snapshot.

It answers:

> "If I take over InvWise right now, what is the exact state of the project?"

Think of this file as:

```text
Checkpoint Save File
```

for the entire project.

---

# CURRENT PROJECT STATUS

## Project Name

```text
Industrial Inventory Intelligence

(InvWise)
```

---

## Current Release

```text
v2.0.0
```

---

## Current Build

```text
2.0.0+2
```

---

## Current Repository Status

```text
GitHub Repository:
Active

Source Code:
Available

APK:
Published

GitHub Release:
Published
```

---

## Production Status

```text
Release Ready
```

The software is no longer considered:

```text
Prototype

Concept

Demo Only
```

It is now:

```text
Working Inventory System
```

---

# PROJECT COMPLETION ESTIMATE

## Software

```text
98%
```

---

## Hardware Validation

```text
70%
```

---

## FYP Documentation

```text
60%-80%
```

(depending on report completion)

---

# WHAT EXISTS TODAY

## Authentication

Status:

```text
Complete
```

Supports:

```text
Employee ID Login

Email Login

Password Authentication

Session Tracking
```

---

## Registration System

Status:

```text
Complete
```

Supports:

```text
Registration Requests

Approval Workflow

Rejection Workflow

Activation Workflow
```

---

## Inventory System

Status:

```text
Complete
```

Supports:

```text
Create

Edit

Search

Filter

Archive

Restore

Permanent Delete
```

---

## Category Module

Status:

```text
Complete
```

---

## Unit Module

Status:

```text
Complete
```

---

## Warehouse Module

Status:

```text
Complete
```

Supports:

```text
Create

Edit

Deactivate
```

---

## Reports

Status:

```text
Complete
```

Supports:

```text
CSV Export

Excel Export

Inventory Reports

Valuation Reports
```

---

## Activity Logs

Status:

```text
Complete
```

---

## Alerts & Tasks

Status:

```text
Complete
```

---

## Dashboard

Status:

```text
Complete
```

Supports:

```text
Full Dashboard

Compact Dashboard
```

---

## Update System

Status:

```text
Complete
```

Now powered by:

```text
GitHub Releases
```

---

## Telemetry

Status:

```text
Operational
```

Current Devices:

```text
DDS669

Toggle Switch
```

---

# HARDWARE REALITY CHECK

The following hardware is ACTUALLY used.

---

## DDS669

Status:

```text
Used
```

Metrics:

```text
Voltage

Current

Power

Energy
```

---

## Toggle Switch

Status:

```text
Used
```

Metrics:

```text
ON/OFF

Status

Last Updated
```

---

# HARDWARE THAT DOES NOT EXIST

These devices are not part of the project.

```text
IRIV Sensor

RFID

Barcode Scanner

Receipt Counter

Proximity Sensor
```

---

# IMPORTANT DASHBOARD DECISIONS

---

# FULL DASHBOARD

Purpose:

```text
Managers

Lecturers

Project Demonstration

Presentation
```

Contains:

```text
Sync Status

Greeting

Inventory Overview

KPI Grid

Attention Required

Recent Activity

Live Inventory Summary

Sensor Monitoring

System Health
```

---

# COMPACT DASHBOARD

Purpose:

```text
Daily Operations
```

Contains:

```text
Condensed Information

Reduced Whitespace

Faster Navigation
```

---

# DASHBOARD CHANGES MADE IN V2.0

Added:

```text
Full Dashboard Mode

Compact Dashboard Mode
```

Removed:

```text
Inventory Alerts Widget
```

Removed:

```text
Inventory Alerts Page
```

New Navigation:

```text
Attention Required

↓

Alerts & Tasks
```

---

# SENSOR MONITORING CHANGES

---

## Current Dashboard Sensors

```text
DDS669

Toggle Switch
```

---

## Removed

```text
IRIV Sensor

Receipt Count

Trigger Count

Last Detection
```

Reason:

```text
Hardware does not exist.
```

---

# ACTIVITY LOGS CHANGES

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

User Dropdown
```

Reason:

```text
Duplicate functionality.
```

Search already supports usernames.

---

# UPDATE SYSTEM CHANGES

---

# OLD METHOD

```text
Supabase

app_versions table

Manual updates required
```

---

# NEW METHOD

```text
GitHub Releases

Automatic Release Detection
```

Workflow:

```text
Publish Release

↓

GitHub Release

↓

InvWise Detects Version

↓

User Downloads APK
```

---

# UPDATE DIALOG STATUS

Current Behaviour:

---

Before opening update URL:

```text
No Close Button

Cannot Dismiss
```

---

After update URL opens successfully:

```text
Close Button Appears

Dialog Can Be Closed

Button Text:

✓ Download Started
```

---

# ARCHIVE SYSTEM STATUS

Inventory archive system exists.

---

## New Fields

```sql
is_archived

archived_at

archived_by
```

---

## Functions

```text
Archive

Restore

Permanent Delete
```

---

# DATABASE STATUS

Current database is stable.

Critical tables:

```text
profiles

inventory_items

stock_levels

stock_movements

warehouse_locations

categories

units

activity_logs

login_events

device_sessions
```

---

# KNOWN DATABASE HISTORY

One major issue occurred during V2.0 development.

Problem:

```text
inventory_items.is_archived

did not exist
```

Fix:

```sql
is_archived

archived_at

archived_by
```

were added.

The archive system now functions correctly.

---

# CURRENT RELEASE HISTORY

---

## Release 1

```text
v1.0.0
```

Original Final Release.

---

## Release 2

```text
v2.0.0
```

Current Production Release.

Changes:

```text
Archive System

GitHub Updater

Dashboard Redesign

Sensor Cleanup

Activity Log Improvements

System Information Module

Alert System Cleanup
```

---

# CURRENT GITHUB STATUS

Repository:

```text
Operational
```

Latest Release:

```text
v2.0.0
```

APK:

```text
InvWise-v2.0.0.apk
```

Release published successfully.

---

# CURRENT TECHNICAL DEBT

These are not bugs.

These are unfinished enhancements.

---

## Technical Debt 1

Physical DDS669 Validation

Current State:

```text
Telemetry integrated.

Physical verification still required.
```

---

## Technical Debt 2

Toggle Switch Validation

Current State:

```text
Implemented.

Needs real-world testing.
```

---

## Technical Debt 3

Dashboard Analytics

Potential future additions:

```text
Trend Charts

Stock Forecasting

Usage Trends
```

---

## Technical Debt 4

Pagination

Some screens still rely on client-side filtering.

Future:

```text
Database-side pagination
```

would improve performance.

---

# THINGS FUTURE DEVELOPERS SHOULD NOT CHANGE

---

## Do Not Remove RLS

Reason:

```text
Security Foundation
```

---

## Do Not Use Service Role In Flutter

Reason:

```text
Critical Security Risk
```

---

## Do Not Modify Stock Movement History

Reason:

```text
Audit Integrity
```

---

## Do Not Store Quantity In inventory_items

Use:

```text
stock_levels
```

instead.

---

## Do Not Hard Delete Warehouses

Use:

```text
Deactivate Warehouse
```

instead.

---

# HIGHEST PRIORITY NEXT TASKS

These tasks should be completed before major new features are added.

---

## Priority 1

DDS669 Physical Verification

Verify:

```text
Voltage

Current

Power

Energy
```

against actual device readings.

---

## Priority 2

Toggle Switch Physical Verification

Verify:

```text
Real ON/OFF behaviour
```

through complete system flow.

---

## Priority 3

FYP Report Completion

Produce:

```text
Chapter 1

Chapter 2

Chapter 3

Chapter 4

Chapter 5
```

---

## Priority 4

Presentation Slides

Create:

```text
Proposal Slides

Final Presentation Slides

Demonstration Slides
```

---

## Priority 5

Viva Preparation

Prepare:

```text
Architecture

Database

Security

Telemetry

Inventory Logic
```

questions.

---

# IF THE ORIGINAL DEVELOPER RETURNS IN 6 MONTHS

Read in this order:

```text
INVWISE_00_EXECUTIVE_OVERVIEW.md

↓

INVWISE_01_SYSTEM_BLUEPRINT.md

↓

INVWISE_02_DEVELOPER_PLAYBOOK.md

↓

INVWISE_03_PROJECT_STATE_V2_0_0.md
```

This should restore complete project context within a few hours.

---

# CURRENT BOTTOM LINE

Software Status:

```text
Stable
```

Current Release:

```text
v2.0.0
```

Current Hardware:

```text
DDS669

Toggle Switch
```

Current Update Method:

```text
GitHub Releases
```

Main Remaining Work:

```text
Hardware Validation

Documentation

Presentation

Viva
```

The project has moved beyond feature-building.

The greatest value now comes from:

```text
Verification

Documentation

Demonstration

Deployment Stability
```

---

END OF DOCUMENT

INVWISE_03_PROJECT_STATE_V2_0_0.md

Version 2.0.0
