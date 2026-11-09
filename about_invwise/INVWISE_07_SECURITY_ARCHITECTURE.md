# INVWISE_07_SECURITY_ARCHITECTURE
## Authentication, Authorization & Security Design
### Version 2.0.0
### Source: Live Security Discovery + Supabase Analysis

---

# PURPOSE OF THIS DOCUMENT

This document answers:

> "How is InvWise secured and how is user access controlled?"

This document covers:

```text
Authentication

Authorization

Role Hierarchy

RLS

Edge Function Security

Registration Security

Session Security

Audit Logging

Database Protection
```

---

# SECURITY PHILOSOPHY

InvWise uses a layered security model:

```text
User
 ↓

Flutter UI
 ↓

RoleAccessService
 ↓

Edge Functions
 ↓

Supabase Auth
 ↓

Row Level Security
 ↓

Database
```

No single layer is trusted.

Every critical operation should pass through:

```text
Authentication

Authorization

Validation

Database Constraints
```

Security information derived from the live implementation. 【1-87c6a8】

---

# SECURITY LAYERS

---

## Layer 1

### Flutter UI

Purpose:

```text
User Experience Layer
```

Responsibilities:

```text
Hide Unauthorized UI

Disable Restricted Actions

Navigation Protection

Role-Based Menus
```

Implemented through:

```text
RoleAccessService

RoleAccessGuard
```

---

## Important Warning

UI security is:

```text
Convenience Security
```

NOT:

```text
Real Security
```

A hidden button does not secure data.

Real protection must exist elsewhere. 【1-87c6a8】

---

# Layer 2

### Supabase Authentication

Purpose:

```text
Identity Verification
```

Implemented By:

```text
Supabase Auth
```

Database Link:

```text
profiles.auth_user_id
```

Every active user is linked to:

```text
auth.users
```

through:

```sql
profiles.auth_user_id
```

【2-b7b938】

---

# Layer 3

### Edge Functions

Purpose:

```text
Secure Business Operations
```

Examples:

```text
User Provisioning

Account Activation

User Management

Support Notifications
```

Protected functions currently include:

```text
complete-registration-setup

manage-users

notify-support-request

provision-approved-registration
```

【3-85f4bf】

---

# Layer 4

### Database Security

Purpose:

```text
Final Security Boundary
```

Includes:

```text
RLS

Constraints

Triggers

RPC Validation

Foreign Keys
```

The database remains the ultimate source of truth. 【1-87c6a8】【2-b7b938】

---

# AUTHENTICATION FLOW

---

## Standard Login Process

```text
User Opens App
         ↓

Login Page
         ↓

Supabase Authentication
         ↓

Session Created
         ↓

Profile Retrieved
         ↓

Dashboard Access
```

Implemented through:

```text
AuthService
```

【1-87c6a8】

---

# SESSION FLOW

```text
Login
 ↓

Auth Session

 ↓

Profile Session

 ↓

Device Session

 ↓

Activity Tracking

 ↓

Logout
```

Supporting tables:

```text
device_sessions

login_events

profiles
```

【2-b7b938】

---

# DEVICE SESSION SECURITY

---

## device_sessions

Purpose:

```text
Track authenticated devices.
```

Stores:

```text
Device Name

Platform

IP Address

User Agent

Started At

Last Active At

Revoked At
```

Database protections:

```text
Profile Relationship

Timestamp Validation

Activity Validation
```

【2-b7b938】

---

# LOGIN HISTORY

---

## login_events

Purpose:

```text
Authentication Auditing
```

Stores:

```text
Employee ID

Success Status

Failure Reason

User Agent

IP Address

Timestamp
```

Helps:

```text
Security Review

Incident Investigation

Auth Auditing
```

【2-b7b938】

---

# ROLE SYSTEM

---

## Current Roles

```text
Super Admin

Inventory Administrator

Warehouse Supervisor

Storekeeper
```

Source:

```text
profiles.role
```

【2-b7b938】【1-87c6a8】

---

# ROLE HIERARCHY

```text
Super Admin
      │
      ▼
Inventory Administrator
      │
      ▼
Warehouse Supervisor
      │
      ▼
Storekeeper
```

---

# SUPER ADMIN

Highest authority role.

Capabilities include:

```text
User Management

Registration Approval

Warehouse Management

Category Management

Unit Management

Inventory Management

Security Management

Configuration Control
```

【1-87c6a8】

---

# INVENTORY ADMINISTRATOR

Purpose:

```text
Operational Administration
```

Controls:

```text
Inventory

Reports

Warehouses

Categories

Units

Registration Approvals
```

【1-87c6a8】

---

# WAREHOUSE SUPERVISOR

Purpose:

```text
Warehouse Operations Oversight
```

Controls:

```text
Inventory Monitoring

Adjustments

Warehouse Operations

Reporting
```

【1-87c6a8】

---

# STOREKEEPER

Purpose:

```text
Day-To-Day Inventory Operations
```

Controls:

```text
Receive Stock

Issue Stock

Inventory Viewing

Support Access
```

【1-87c6a8】

---

# PERMISSION MODEL

Permissions are checked through:

```text
RoleAccessService
```

Examples:

```text
viewDashboard

viewInventory

viewReports

manageUsers

manageCategories

manageUnits

manageWarehouses

manageRegistrationRequests

accessPersonalSecurity
```

【1-87c6a8】

---

# REGISTRATION SECURITY

---

## Registration Flow

```text
Public User
       ↓

Registration Request
       ↓

Pending Status
       ↓

Admin Review
       ↓

Approved
       ↓

Provisioning
       ↓

Activation
       ↓

Active User
```

【1-87c6a8】【2-b7b938】

---

# registration_requests Security

Public User Can:

```text
Create Pending Request
```

Administrators Can:

```text
View Requests

Approve Requests

Reject Requests
```

Only:

```text
Inventory Administrator

Super Admin
```

can process approvals. 【1-87c6a8】

---

# ACCOUNT PROVISIONING SECURITY

---

## claim_registration_provisioning()

Purpose:

```text
Prevent Provisioning Race Conditions
```

Features:

```text
Single Claim Ownership

Lock Request

Prevent Duplicate Processing
```

Uses:

```text
SECURITY DEFINER
```

【2-b7b938】

---

## create_registration_profile()

Purpose:

```text
Create Approved User Profiles
```

Validation:

```text
Approved Request Required

Unique Employee ID

Matching Email

Role Validation
```

Uses:

```text
SECURITY DEFINER
```

【2-b7b938】

---

# USER MANAGEMENT SECURITY

---

## manage_user_account()

Purpose:

```text
Administrative User Operations
```

Supports:

```text
Role Changes

Activation

Deactivation
```

Uses:

```text
SECURITY DEFINER
```

【2-b7b938】

---

# CRITICAL SUPER ADMIN PROTECTION

InvWise prevents:

```text
Removing The Last Active
Super Admin
```

Protection exists for:

```text
Role Changes

Account Deactivation
```

This is enforced inside:

```text
manage_user_account()
```

【2-b7b938】

---

# EDGE FUNCTION SECURITY

---

## complete-registration-setup

Security:

```text
Bearer Token Validation

Supabase Auth Validation

Service Role Operations
```

verify_jwt:

```text
true
```

Risk Level:

```text
High
```

because it performs account activation. 【3-85f4bf】

---

## provision-approved-registration

Security:

```text
Bearer Token Validation

Role Verification

Service Role Access
```

RPCs Used:

```text
claim_registration_provisioning()

create_registration_profile()
```

Risk:

```text
High
```

【3-85f4bf】

---

## manage-users

Security:

```text
Bearer Token Validation

Administrative Validation

Protected RPC Invocation
```

Risk:

```text
High
```

【3-85f4bf】

---

## notify-support-request

Security:

```text
Bearer Token Validation

Email Delivery Controls

Service Role Operations
```

Risk:

```text
High
```

【3-85f4bf】

---

# EMPLOYEE LOGIN SECURITY

Current Status:

```text
NOT IMPLEMENTED
```

Function:

```text
login-with-employee-id
```

is currently only:

```text
Starter Template Code
```

and should not be considered a login system. 【3-85f4bf】【1-87c6a8】

---

# ROW LEVEL SECURITY

---

## Current Status

Live Database:

```text
25 Tables
```

Tables With RLS Enabled:

```text
10 Tables
```

【1-87c6a8】

---

# RLS Enabled Areas

Examples:

```text
registration_requests

activity_logs

telemetry_settings

sensor_alerts

sensor_history

sensor_status

sensors

energy_readings
```

【1-87c6a8】

---

# TELEMETRY SECURITY

Tables:

```text
sensors

sensor_status

sensor_history

energy_readings

switch_events

sensor_alerts

telemetry_settings
```

Support:

```text
Authenticated Policies

Anonymous Ingestion Policies
```

for telemetry ingestion. 【1-87c6a8】

---

# AUDIT LOGGING

---

## activity_log

Purpose:

```text
Legacy Audit Store
```

Tracks:

```text
Inventory Events

Movement History
```

【2-b7b938】

---

## activity_logs

Purpose:

```text
Enterprise Audit Store
```

Tracks:

```text
Actor

Action

Entity

Metadata

Timestamp
```

Current direction:

```text
Preferred Audit Table
```

【2-b7b938】【4-29dbc6】

---

# DATABASE HARDENING

---

## Constraints

Examples:

```text
Unique Employee IDs

Unique Emails

Unique SKUs

Positive Stock Rules

Movement Rules

Task State Rules
```

【2-b7b938】

---

# Trigger-Based Protection

Examples:

```text
set_updated_at()

prevent_stock_movement_mutation()

apply_stock_movement()
```

【2-b7b938】

---

# STOCK MOVEMENT SECURITY

Most critical inventory protection.

Rules:

```text
Cannot Update

Cannot Delete
```

Existing records are immutable.

Corrections require:

```text
New Compensating Movement
```

This creates complete auditability. 【2-b7b938】

---

# IDENTIFIED SECURITY RISKS

Based on live discovery.

---

## Risk 1

RLS disabled on important tables:

```text
profiles

inventory_items

stock_movements

device_sessions

app_versions
```

Requires review before production deployment. 【1-87c6a8】

---

## Risk 2

Broad authenticated access exists on some telemetry tables.

Requires validation against final production requirements. 【1-87c6a8】

---

## Risk 3

All authenticated users can read:

```text
activity_logs
```

Policy review recommended. 【1-87c6a8】

---

## Risk 4

Employee ID login not implemented despite endpoint name. 【3-85f4bf】【1-87c6a8】

---

# SECURITY DESIGN RULES

---

## Rule 1

```text
Never Trust The Client
```

---

## Rule 2

```text
Always Verify Roles
Server Side
```

---

## Rule 3

```text
Critical Operations
Require Edge Functions
```

---

## Rule 4

```text
Database Is Final Authority
```

---

## Rule 5

```text
Inventory Audit Trail
Must Remain Immutable
```

---

## Rule 6

```text
At Least One
Active Super Admin
Must Always Exist
```

---

# CURRENT SECURITY FACTS

```text
Supabase Authentication

Role-Based Authorization

Registration Approval Workflow

Provisioning Protection

Activation Workflow

Session Tracking

Device Tracking

Audit Logging

Telemetry Security

Edge Function Validation

Immutable Inventory Ledger
```

---

END OF DOCUMENT

INVWISE_07_SECURITY_ARCHITECTURE.md

Version 2.0.0

---

# INVENTORY DELETION SECURITY UPDATE — 2026-11-09

The archive and restore RPCs authorize an active Inventory Administrator or
Super Admin. Permanent deletion and Force Delete require an active Super Admin
inside the `SECURITY DEFINER` database function; client-side visibility and
permissions are not trusted as the enforcement boundary.

The archived-item UI requires the operator to type `DELETE` and pass the
existing password re-confirmation flow. The safe RPC path blocks deletion when
`stock_movements` or `stock_counts` reference the item, reports both counts, and
retains existing activity history. Force Delete is an explicit boolean mode
and removes the item’s stock movements, levels, counts, and item/movement
`activity_logs` rows. The transaction writes a new deletion audit event with
the operator, item ID, mode, and removal counts; PostgreSQL rolls back the
entire operation on failure.

Force Delete is high-risk and irreversible. Use it only after confirming
business retention requirements and approval. Prefer archiving whenever
historical reporting requirements are unclear. The legacy singular
`activity_log` table is not purged by this RPC; its current foreign keys set
item/movement references to null, retaining that legacy audit record.
