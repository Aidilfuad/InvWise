# INVWISE 00 - EXECUTIVE OVERVIEW
## Complete Project Introduction & Business Understanding Guide
### Version 2.0.0
### Read This First Before Reading Any Other InvWise Documentation

---

# DOCUMENT PURPOSE

This document exists for one reason:

> If the original developer disappears tomorrow, a completely new developer, student, lecturer, auditor, AI assistant, system analyst, or future maintainer should be able to understand what InvWise is, why it exists, how it works, and where the project stands today.

This is **not** the technical blueprint.

This is **not** the database specification.

This is **not** a code walkthrough.

Those documents come later.

This document is the "big picture".

Read this document first.

Then continue with:

```text
INVWISE_01_SYSTEM_BLUEPRINT.md
INVWISE_02_DEVELOPER_PLAYBOOK.md
INVWISE_03_PROJECT_STATE_V2_0_0.md
```

This document explains the project in plain English.

---

# PROJECT IDENTITY

## Project Name

Industrial Inventory Intelligence

Short Name:

```text
InvWise
```

---

## Current Release

```text
Version:
2.0.0

Status:
Production Release

Deployment:
GitHub Releases

Current APK:
InvWise-v2.0.0.apk
```

---

## Developer

```text
Muhammad Aidil Fuad Bin Aidrus
```

---

## Institution

```text
Universiti Tun Hussein Onn Malaysia (UTHM)
```

---

## Project Category

```text
Industrial Inventory Management System

Warehouse Management System

Telemetry Monitoring System

Role-Based Enterprise System
```

---

# WHAT IS INVWISE?

InvWise is an industrial inventory management platform.

Most inventory systems are simple.

A user:

```text
Creates Item
Edits Item
Deletes Item
Views Item
```

InvWise was intentionally designed not to be that kind of system.

InvWise was designed around the challenges that exist inside real warehouses, factories, maintenance departments, and industrial environments.

The system focuses on four major areas:

```text
Inventory Integrity

Security

Auditability

Industrial Operations
```

---

# WHY INVWISE EXISTS

The project was created because many organisations still operate using:

```text
Excel sheets

Whiteboards

Paper forms

Manual stock recording
```

These methods create serious problems.

Example:

```text
Storekeeper says:
50 PLC Modules available.

Technician says:
Only 18 left.

Manager says:
System shows 72.
```

Nobody knows the actual quantity.

Inventory becomes unreliable.

---

Another common problem:

```text
Stock disappears.

Nobody knows:

Who took it.

When it was taken.

Why it was taken.
```

Traditional systems often allow direct stock changes without maintaining a complete history.

InvWise was designed specifically to solve this problem.

---

# PRIMARY GOALS OF INVWISE

The system was built around the following objectives.

---

## Goal 1

Inventory Visibility

Users should know:

```text
What exists.

How many exist.

Where it exists.
```

---

## Goal 2

Inventory Accountability

Every stock adjustment should be traceable.

The system should answer:

```text
Who changed stock?

When?

What was changed?

Why was it changed?
```

---

## Goal 3

Controlled User Access

Not every user should see everything.

Different users have different responsibilities.

Examples:

```text
Admin

Manager

Technician

Viewer
```

---

## Goal 4

Industrial Readiness

The system should support:

```text
Warehouses

Maintenance teams

Storekeepers

Technicians

Industrial operations
```

---

## Goal 5

Hardware Monitoring

The system should integrate with industrial telemetry devices.

Current implementation includes:

```text
DDS669 Energy Meter

Toggle Switch
```

---

# WHAT PROBLEMS DOES INVWISE SOLVE?

## Problem 1

Inventory Uncertainty

Without inventory visibility:

```text
Items get lost.

Items get overpurchased.

Items go out of stock.
```

InvWise provides:

```text
Inventory Tracking

Stock Levels

Warehouse Allocation

Stock Movements
```

---

## Problem 2

No Audit Trail

Many inventory systems allow:

```text
Quantity:
100

↓

Quantity:
40
```

without recording why.

InvWise records changes through:

```text
Stock Movements

Activity Logs

System Logs
```

---

## Problem 3

Uncontrolled User Creation

Many systems allow anyone to:

```text
Register

Login

Access Data
```

InvWise requires:

```text
Registration Request

Approval

Provisioning

Activation
```

before access is granted.

---

## Problem 4

Warehouse Confusion

Knowing that:

```text
50 units exist
```

is not enough.

InvWise answers:

```text
Warehouse A

Rack B

Shelf C

Bin D
```

allowing users to find physical inventory.

---

# WHO IS INVWISE FOR?

Primary users:

```text
Industrial companies

Factories

Warehouses

Maintenance Departments

Technical Stores
```

---

Secondary users:

```text
Educational institutions

FYP projects

Research demonstrations

Inventory training labs
```

---

# CURRENT SYSTEM FEATURES

## Authentication

Supports:

```text
Employee ID Login

Email Login
```

---

## Registration Workflow

Supports:

```text
Registration Request

Approval

Rejection

Activation
```

---

## Inventory Management

Supports:

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

## Categories

Supports:

```text
Category Creation

Category Editing

Category Management
```

---

## Units

Supports:

```text
PCS

KG

Meter

Custom Units
```

---

## Warehouse Management

Supports:

```text
Create Warehouse

Edit Warehouse

Deactivate Warehouse
```

Warehouses with historical data remain protected.

---

## Stock Adjustment

Supports:

```text
Stock In

Stock Out

Adjustment

Audit Correction
```

---

## Reporting

Supports:

```text
CSV Export

Excel Export

Inventory Reports

Valuation Reports
```

---

## Activity Logs

Supports:

```text
System Activity Tracking

Inventory Activity Tracking

User Activity Tracking
```

Current filters:

```text
Search

Category

Date Range
```

---

## System Information

Provides:

```text
Version

Build

Update Status

Release Information
```

---

# HARDWARE INTEGRATION

Current project hardware consists of:

---

## DDS669 Energy Meter

Used for:

```text
Voltage

Current

Power

Energy Consumption
```

---

## Toggle Switch

Used for:

```text
Digital ON/OFF State Monitoring
```

---

# HARDWARE NOT USED

The following devices are NOT part of the current deployment:

```text
RFID

Barcode Scanner

IRIV Sensor

Proximity Sensor

Receipt Counter
```

If these appear in future code, they were not part of the official V2.0 release.

---

# DASHBOARD MODES

InvWise currently contains two dashboard modes.

---

## Full Dashboard

Purpose:

```text
Management

Demonstrations

Presentations

FYP Showcase
```

Provides:

```text
Inventory Overview

KPIs

Attention Required

Recent Activity

Live Inventory Summary

Sensor Monitoring

System Health
```

---

## Compact Dashboard

Purpose:

```text
Daily Operations

Mobile Usage

Fast Overview
```

Designed to display more information within limited screen space.

---

# UPDATE SYSTEM

Originally the update system used:

```text
Supabase

app_versions table
```

which required manual updates.

---

Current V2.0 implementation uses:

```text
GitHub Releases
```

Workflow:

```text
Build APK

Publish GitHub Release

Users Detect Update

Users Download APK

Install Update
```

No manual Supabase update is intended for future releases.

---

# SECURITY PHILOSOPHY

InvWise follows a simple rule:

```text
Protect Data
Before
Providing Convenience
```

Important principles:

```text
Row Level Security

Server-side Privileged Operations

Audit Trails

Role-Based Access
```

---

# CURRENT PROJECT STATUS

## Software

```text
Authentication            Complete

Inventory                 Complete

Categories                Complete

Units                     Complete

Warehouses                Complete

Activity Logs             Complete

Archive System            Complete

Dashboard                 Complete

Update System             Complete

Reporting                 Complete

Telemetry                 Complete
```

---

## Hardware

```text
DDS669                    Needs Final Physical Validation

Toggle Switch             Needs Final Physical Validation
```

---

## Documentation

```text
Technical Handbook        Available

Developer Guide           Available

GitHub Release            Available

Source Code               Available
```

---

# WHAT HAS CHANGED SINCE V1.0?

The original V1.0 documentation does not fully represent the current release.

Major additions in V2.0:

```text
Archive / Restore

Permanent Delete

GitHub Release Updater

Dashboard Full Mode

Dashboard Compact Mode

DDS669 Monitoring

Toggle Switch Monitoring

System Information Module

Improved Activity Logs

Improved Update Management
```

Major removals:

```text
Inventory Alerts Page

Inventory Alerts Widget

IRIV Monitoring

User Dropdown Filter in Activity Logs
```

---

# WHAT SHOULD A NEW MAINTAINER DO FIRST?

If you inherit this project:

Step 1:

Read this document.

Step 2:

Read:

```text
INVWISE_01_SYSTEM_BLUEPRINT.md
```

Step 3:

Understand:

```text
Database

Authentication

Inventory

Stock Movements
```

Step 4:

Understand:

```text
DDS669

Toggle Switch

Node-RED

Supabase
```

Step 5:

Read:

```text
INVWISE_02_DEVELOPER_PLAYBOOK.md
```

before making changes.

---

# PROJECT MISSION STATEMENT

InvWise is not just an inventory application.

Its purpose is to demonstrate how industrial inventory operations, user management, security, telemetry monitoring, and auditability can be combined into a practical enterprise-grade system built on modern technologies.

The long-term goal is to evolve InvWise into a complete Industrial Inventory Intelligence Platform while retaining the principles that formed the foundation of V1.0 and V2.0:

```text
Integrity

Traceability

Security

Simplicity

Industrial Practicality
```

---

END OF DOCUMENT

INVWISE_00_EXECUTIVE_OVERVIEW.md
Version 2.0.0
