# INVWISE_13_API_AND_EDGE_FUNCTION_SPECIFICATION
## Complete API, RPC & Edge Function Reference
### Version 2.0.0
### Source: Edge Function Discovery + Database Discovery + Security Discovery

---

# PURPOSE OF THIS DOCUMENT

This document answers:

> "How do backend operations communicate with InvWise?"

This document provides:

```text
Edge Function Specifications

Database RPC Specifications

Authentication Requirements

Security Boundaries

Request Flows

Response Models

Error Handling

Integration Contracts
```

This document is intended for:

```text
Backend Developers

Flutter Developers

Future API Integrators

System Maintainers
```

---

# API ARCHITECTURE OVERVIEW

Current Backend Architecture:

```text
Flutter App
       │
       ▼

Service Layer
       │
       ▼

Supabase Client
       │
       ├─ Direct Database Access
       │
       ├─ RPC Functions
       │
       └─ Edge Functions
```

Current production edge functions discovered:

```text
complete-registration-setup

manage-users

notify-support-request

provision-approved-registration

login-with-employee-id
```

EDGE_FUNCTION_DISCOVERY.md confirms these functions as the active edge-function inventory. 【1-aaab99】

---

# AUTHENTICATION MODEL

InvWise uses:

```text
Bearer JWT Tokens
```

issued through:

```text
Supabase Authentication
```

---

# Authentication Header

```http
Authorization: Bearer <jwt-token>
```

Required for:

```text
manage-users

notify-support-request

complete-registration-setup

provision-approved-registration
```

【1-aaab99】

---

# AUTHORIZATION MODEL

Authentication verifies:

```text
WHO
```

Authorization verifies:

```text
WHAT THEY CAN DO
```

Enforcement layers:

```text
Supabase Auth

Edge Function Validation

RPC Validation

Database Policies

RoleAccessService
```

【2-83617c】【1-aaab99】

---

# EDGE FUNCTION
# complete-registration-setup

---

## Purpose

Finalizes approved user activation.

---

## Function Name

```text
complete-registration-setup
```

---

## Authentication

Required:

```text
YES
```

JWT Verification:

```text
true
```

【1-aaab99】

---

## Primary Responsibilities

```text
Validate User

Finalize Registration

Complete Setup

Update Registration State
```

---

## Tables Affected

```text
registration_requests
```

【1-aaab99】

---

## Typical Request

```json
{
  "registrationId": "uuid",
  "password": "********",
  "confirmPassword": "********"
}
```

---

## Typical Process

```text
Receive Request
        ↓

Validate JWT
        ↓

Validate User
        ↓

Validate Registration
        ↓

Update Registration
        ↓

Complete Setup
```

---

## Success Response

```json
{
  "success": true,
  "message": "Registration completed"
}
```

---

## Failure Conditions

```text
Invalid Token

Registration Missing

Expired Activation

Validation Failure
```

---

# EDGE FUNCTION
# provision-approved-registration

---

## Purpose

Create system account after approval.

---

## Function Name

```text
provision-approved-registration
```

---

## Authentication

Required:

```text
YES
```

JWT Verification:

```text
true
```

【1-aaab99】

---

## Risk Classification

```text
HIGH
```

because it creates user accounts. 【1-aaab99】

---

## Responsibilities

```text
Provision Account

Create User Profile

Allocate Role

Generate Activation Flow
```

---

## RPC Dependencies

```text
claim_registration_provisioning()

create_registration_profile()
```

【1-aaab99】【3-430bb1】

---

## Tables Accessed

```text
profiles

registration_requests
```

【1-aaab99】

---

## Workflow

```text
Approved Request
          ↓

Claim Provisioning
          ↓

Create Auth User
          ↓

Create Profile
          ↓

Update Registration
          ↓

Return Success
```

---

## Request Example

```json
{
  "requestId": "uuid"
}
```

---

## Success Response

```json
{
  "success": true,
  "provisioned": true,
  "userId": "uuid"
}
```

---

## Failure Response

```json
{
  "success": false,
  "error": "Provisioning failed"
}
```

---

## Security Controls

```text
JWT Validation

Request Ownership Validation

Provisioning Lock

Race Condition Protection
```

---

# EDGE FUNCTION
# manage-users

---

## Purpose

Administrative user management operations.

---

## Function Name

```text
manage-users
```

---

## Authentication

Required:

```text
YES
```

【1-aaab99】

---

## Risk Classification

```text
HIGH
```

because it modifies user accounts. 【1-aaab99】

---

## Flutter Caller

```text
UserManagementService
```

【1-aaab99】【4-a8eda4】

---

## RPC Dependency

```text
manage_user_account()
```

【1-aaab99】【3-430bb1】

---

## Supported Operations

```text
Activate User

Deactivate User

Change Role
```

---

## Request Example

```json
{
  "action": "deactivate",
  "userId": "uuid"
}
```

---

## Alternative Request

```json
{
  "action": "change_role",
  "userId": "uuid",
  "role": "Warehouse Supervisor"
}
```

---

## Success Response

```json
{
  "success": true,
  "message": "User updated"
}
```

---

## Security Rules

```text
Admin Validation

Role Validation

RPC Validation

Last Super Admin Protection
```

---

## Important Protection

System must always retain:

```text
At Least One Active
Super Admin
```

The underlying RPC enforces this protection. 【3-430bb1】【2-83617c】

---

# EDGE FUNCTION
# notify-support-request

---

## Purpose

Send support notifications.

---

## Function Name

```text
notify-support-request
```

---

## Authentication

Required:

```text
YES
```

JWT Verification:

```text
true
```

【1-aaab99】

---

## Risk Classification

```text
HIGH
```

because external communication is involved. 【1-aaab99】

---

## Tables Accessed

```text
profiles

support_requests
```

【1-aaab99】

---

## Responsibilities

```text
Read Support Ticket

Build Notification

Send Email

Update Notification Status
```

---

## Typical Workflow

```text
Create Ticket
       ↓

Function Triggered
       ↓

Load Request
       ↓

Send Notification
       ↓

Update Status
```

---

## Request Example

```json
{
  "supportRequestId": "uuid"
}
```

---

## Success Response

```json
{
  "success": true,
  "notificationSent": true
}
```

---

## Failure Conditions

```text
Request Missing

Email Provider Error

Permission Failure
```

---

# EDGE FUNCTION
# login-with-employee-id

---

## Purpose

Employee ID login endpoint.

---

## Current Status

```text
NOT IMPLEMENTED
```

Discovery indicates this edge function contains:

```text
Starter Code

Greeting Endpoint
```

and does not currently provide actual Employee ID authentication. 【1-aaab99】

---

## Authentication

JWT Verification:

```text
false
```

【1-aaab99】

---

## Current Recommendation

Do not use as a production login API until implemented and security-reviewed.

---

# DATABASE RPC REFERENCE

---

# RPC
# manage_user_account()

---

## Purpose

Administrative profile operations.

---

## Security Model

```text
SECURITY DEFINER
```

【3-430bb1】

---

## Supported Operations

```text
Role Updates

Activation

Deactivation
```

---

## Business Rules

```text
Prevent Last Super Admin Removal

Role Validation

Status Validation
```

---

## Called By

```text
manage-users
```

Edge Function.

---

# RPC
# claim_registration_provisioning()

---

## Purpose

Claim provisioning ownership.

---

## Security Model

```text
SECURITY DEFINER
```

【3-430bb1】

---

## Main Goal

Prevent:

```text
Duplicate Provisioning

Parallel Processing

Race Conditions
```

---

## Workflow

```text
Request Claimed
        ↓

Provisioning Locked
        ↓

Processing Allowed
```

---

# RPC
# create_registration_profile()

---

## Purpose

Create user profile.

---

## Security Model

```text
SECURITY DEFINER
```

【3-430bb1】

---

## Responsibilities

```text
Create Profile

Apply Role

Create User Metadata
```

---

## Validations

```text
Approved Request

Unique User

Allowed Role
```

---

# RPC
# apply_stock_movement()

---

## Purpose

Process inventory transactions.

---

## Invoked When

```text
Receipt

Issue

Transfer

Adjustment

Return
```

---

## Tables Updated

```text
stock_movements

stock_levels
```

【3-430bb1】

---

## Workflow

```text
Movement Created
         ↓

Function Executes
         ↓

Stock Updated
```

---

# RPC
# prevent_stock_movement_mutation()

---

## Purpose

Protect inventory history.

---

## Blocks

```text
UPDATE stock_movements

DELETE stock_movements
```

【3-430bb1】

---

## Business Value

Guarantees:

```text
Auditability

Traceability

Inventory Integrity
```

---

# RPC
# fn_process_energy_reading()

---

## Purpose

Telemetry processing.

---

## Trigger Source

```text
energy_readings
```

【3-430bb1】【5-373113】

---

## Updates

```text
sensor_status

sensor_history
```

---

## Generated Outputs

```text
Voltage

Current

Power

Energy Metrics
```

---

# RPC
# fn_process_switch_event()

---

## Purpose

Switch telemetry processing.

---

## Trigger Source

```text
switch_events
```

【3-430bb1】【5-373113】

---

## Updates

```text
sensor_status

sensor_history
```

---

# RPC
# prune_telemetry_history()

---

## Purpose

Telemetry retention management.

---

## Responsibilities

```text
Remove Old Data

Maintain Capacity

Improve Performance
```

【3-430bb1】

---

# ERROR RESPONSE STANDARD

Recommended response structure:

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable description"
  }
}
```

---

# SUCCESS RESPONSE STANDARD

Recommended response structure:

```json
{
  "success": true,
  "data": {},
  "message": "Operation successful"
}
```

---

# API SECURITY CHECKLIST

Every new API should implement:

```text
JWT Validation

Role Validation

Input Validation

Audit Logging

Error Handling

Permission Enforcement
```

---

# CURRENT API FACTS

```text
5 Edge Functions

15 Database Functions

JWT Authentication

Role-Based Authorization

Provisioning APIs

Activation APIs

User Management APIs

Support Notification APIs

Telemetry Processing APIs

Inventory Processing APIs
```

Sources:
- EDGE_FUNCTION_DISCOVERY.md 【1-aaab99】
- DATABASE_DISCOVERY.md 【3-430bb1】
- SECURITY_DISCOVERY.md 【2-83617c】

---

END OF DOCUMENT

INVWISE_13_API_AND_EDGE_FUNCTION_SPECIFICATION.md

Version 2.0.0

---

# CURRENT INVENTORY RPC CONTRACTS — 2026-11-09

All routines below are in schema `public` and return `jsonb`. Authorization
uses the authenticated user’s active profile in the database.

| RPC signature | Authorization | Contract |
|---|---|---|
| `archive_inventory_item(p_item_id uuid)` | Active Inventory Administrator or Super Admin | Archives an active item, returns item ID/name/SKU, and writes an activity event. |
| `restore_inventory_item(p_item_id uuid)` | Active Inventory Administrator or Super Admin | Restores an archived item, returns item ID/name/SKU, and writes an activity event. |
| `permanently_delete_inventory_item(p_item_id uuid)` | Active Super Admin | Safe mode. Blocks if `stock_movements` or `stock_counts` exist; reports both counts. |
| `permanently_delete_inventory_item(p_item_id uuid, p_force_delete boolean)` | Active Super Admin | `false` is safe mode; `true` deletes related movements/counts/levels and linked plural `activity_logs`, then the item. |

Permanent delete requires `is_archived = true`. The two-argument function
returns the deleted item identity, mode, and removed-row counts. It appends a
deletion audit event with the item ID in metadata. Failures abort the complete
transaction. The one-argument RPC remains a safe-mode wrapper for existing
callers.

## GitHub Releases API

`AppUpdateService` performs unauthenticated GETs against `/releases/latest` and
`/releases?per_page={limit}`, with `Accept: application/vnd.github+json` and
`User-Agent: InvWise-App-Updater`. Each response has a separate one-hour
persistent cache; history keys include the requested limit. On 403/429 the
service uses stale cached data when present; otherwise the update result is
unavailable with user-friendly retry guidance.
