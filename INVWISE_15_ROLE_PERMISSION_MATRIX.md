# INVWISE_15_ROLE_PERMISSION_MATRIX
## Complete Role-Based Access Control (RBAC) & Permission Governance Guide
### Version 2.0.0
### Source: Security Discovery + UI Discovery + Service Discovery + Workflow Analysis

---

# PURPOSE OF THIS DOCUMENT

This document answers:

> "Who can do what inside InvWise?"

This document defines:

```text
Role Hierarchy

Permission Matrix

Access Governance

Administrative Authority

Security Boundaries

Operational Responsibilities
```

This document serves as the authoritative reference for:

```text
Access Review

Auditing

Compliance

Security Assessment

Future Development
```

---

# ACCESS CONTROL OVERVIEW

InvWise uses:

```text
Role-Based Access Control (RBAC)
```

The permission engine is implemented through:

```text
RoleAccessService
```

while final security enforcement is performed through:

```text
Supabase Authentication

RLS Policies

Database Functions

Edge Functions
```

Supported roles are documented across the security and workflow architecture. 【1-9cd5b8】【2-e57a1f】【3-772e80】

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

# ROLE DEFINITIONS

---

## SUPER ADMIN

Purpose:

```text
Full System Administration
```

Responsibilities:

```text
User Governance

Security Governance

Inventory Governance

Registration Governance

System Configuration

Emergency Recovery
```

Highest authority level.

---

## INVENTORY ADMINISTRATOR

Purpose:

```text
Business Operations Administration
```

Responsibilities:

```text
Inventory Management

Warehouse Management

Reporting

Registration Approval

Operational Configuration
```

Cannot override:

```text
Super Admin Governance
```

rules.

---

## WAREHOUSE SUPERVISOR

Purpose:

```text
Warehouse Oversight
```

Responsibilities:

```text
Inventory Monitoring

Stock Verification

Warehouse Operations

Operational Reporting
```

Limited administrative authority.

---

## STOREKEEPER

Purpose:

```text
Daily Inventory Operations
```

Responsibilities:

```text
Receive Stock

Issue Stock

Inventory Lookup

Support Requests
```

Lowest operational role.

---

# ACCESS LEVEL CLASSIFICATION

The system uses four access levels:

```text
System Administration

Operational Administration

Operational Management

Operational Usage
```

---

# MODULE ACCESS MATRIX

Legend:

```text
✅ Allowed

⚠ Conditional

❌ Not Allowed
```

---

# DASHBOARD ACCESS

| Feature | Super Admin | Inventory Admin | Supervisor | Storekeeper |
|----------|------------|------------|------------|------------|
| View Dashboard | ✅ | ✅ | ✅ | ✅ |
| View KPI Cards | ✅ | ✅ | ✅ | ✅ |
| View Telemetry Summary | ✅ | ✅ | ✅ | ✅ |
| View Alerts | ✅ | ✅ | ✅ | ✅ |
| View Recent Activity | ✅ | ✅ | ✅ | ✅ |

---

# INVENTORY ACCESS

| Feature | Super Admin | Inventory Admin | Supervisor | Storekeeper |
|----------|------------|------------|------------|------------|
| View Inventory | ✅ | ✅ | ✅ | ✅ |
| Create Inventory | ✅ | ✅ | ❌ | ❌ |
| Edit Inventory | ✅ | ✅ | ⚠ | ❌ |
| Archive Inventory | ✅ | ✅ | ❌ | ❌ |
| Restore Inventory | ✅ | ✅ | ❌ | ❌ |
| Search Inventory | ✅ | ✅ | ✅ | ✅ |
| View Inventory Details | ✅ | ✅ | ✅ | ✅ |

---

# CATEGORY MANAGEMENT

| Feature | Super Admin | Inventory Admin | Supervisor | Storekeeper |
|----------|------------|------------|------------|------------|
| View Categories | ✅ | ✅ | ✅ | ✅ |
| Create Category | ✅ | ✅ | ❌ | ❌ |
| Edit Category | ✅ | ✅ | ❌ | ❌ |
| Deactivate Category | ✅ | ✅ | ❌ | ❌ |

---

# UNIT MANAGEMENT

| Feature | Super Admin | Inventory Admin | Supervisor | Storekeeper |
|----------|------------|------------|------------|------------|
| View Units | ✅ | ✅ | ✅ | ✅ |
| Create Unit | ✅ | ✅ | ❌ | ❌ |
| Edit Unit | ✅ | ✅ | ❌ | ❌ |
| Deactivate Unit | ✅ | ✅ | ❌ | ❌ |

---

# WAREHOUSE MANAGEMENT

| Feature | Super Admin | Inventory Admin | Supervisor | Storekeeper |
|----------|------------|------------|------------|------------|
| View Warehouse | ✅ | ✅ | ✅ | ✅ |
| Create Warehouse | ✅ | ✅ | ❌ | ❌ |
| Edit Warehouse | ✅ | ✅ | ⚠ | ❌ |
| Disable Warehouse | ✅ | ✅ | ❌ | ❌ |

---

# STOCK OPERATIONS

| Feature | Super Admin | Inventory Admin | Supervisor | Storekeeper |
|----------|------------|------------|------------|------------|
| Receive Stock | ✅ | ✅ | ✅ | ✅ |
| Issue Stock | ✅ | ✅ | ✅ | ✅ |
| Transfer Stock | ✅ | ✅ | ✅ | ⚠ |
| Adjust Stock | ✅ | ✅ | ✅ | ❌ |
| Approve Adjustment | ✅ | ✅ | ✅ | ❌ |
| View Movements | ✅ | ✅ | ✅ | ✅ |

---

# STOCK COUNT ACCESS

| Feature | Super Admin | Inventory Admin | Supervisor | Storekeeper |
|----------|------------|------------|------------|------------|
| Create Count | ✅ | ✅ | ✅ | ✅ |
| Submit Count | ✅ | ✅ | ✅ | ✅ |
| Approve Count | ✅ | ✅ | ✅ | ❌ |
| View Count History | ✅ | ✅ | ✅ | ✅ |

---

# TELEMETRY ACCESS

Current telemetry supports:

```text
DDS669

Toggle Switch
```

according to live telemetry discovery. 【4-348996】

| Feature | Super Admin | Inventory Admin | Supervisor | Storekeeper |
|----------|------------|------------|------------|------------|
| View Telemetry | ✅ | ✅ | ✅ | ✅ |
| View Sensor Details | ✅ | ✅ | ✅ | ✅ |
| View Analytics | ✅ | ✅ | ✅ | ✅ |
| View History | ✅ | ✅ | ✅ | ✅ |
| Export Telemetry | ✅ | ✅ | ✅ | ❌ |
| Configure Thresholds | ✅ | ✅ | ❌ | ❌ |

---

# REPORTING ACCESS

| Feature | Super Admin | Inventory Admin | Supervisor | Storekeeper |
|----------|------------|------------|------------|------------|
| View Reports | ✅ | ✅ | ✅ | ✅ |
| Export CSV | ✅ | ✅ | ✅ | ⚠ |
| Export Excel | ✅ | ✅ | ✅ | ⚠ |
| Telemetry Export | ✅ | ✅ | ✅ | ❌ |

---

# USER MANAGEMENT ACCESS

User management is implemented through:

```text
UserManagementService

manage-users Edge Function

manage_user_account() RPC
```

【3-772e80】【5-a3dce0】

| Feature | Super Admin | Inventory Admin | Supervisor | Storekeeper |
|----------|------------|------------|------------|------------|
| View Users | ✅ | ✅ | ❌ | ❌ |
| Edit Users | ✅ | ✅ | ❌ | ❌ |
| Activate User | ✅ | ✅ | ❌ | ❌ |
| Deactivate User | ✅ | ✅ | ❌ | ❌ |
| Change Role | ✅ | ✅ | ❌ | ❌ |
| Delete User | ❌ | ❌ | ❌ | ❌ |

---

# REGISTRATION ACCESS

| Feature | Super Admin | Inventory Admin | Supervisor | Storekeeper |
|----------|------------|------------|------------|------------|
| Submit Registration | ✅ | ✅ | ✅ | ✅ |
| Review Requests | ✅ | ✅ | ❌ | ❌ |
| Approve Requests | ✅ | ✅ | ❌ | ❌ |
| Reject Requests | ✅ | ✅ | ❌ | ❌ |
| Provision Accounts | ✅ | ✅ | ❌ | ❌ |

---

# SECURITY ACCESS

| Feature | Super Admin | Inventory Admin | Supervisor | Storekeeper |
|----------|------------|------------|------------|------------|
| Personal Security | ✅ | ✅ | ✅ | ✅ |
| Login History | ✅ | ✅ | ✅ | ✅ |
| Device Sessions | ✅ | ✅ | ✅ | ✅ |
| Security Audit Review | ✅ | ⚠ | ❌ | ❌ |
| Security Governance | ✅ | ❌ | ❌ | ❌ |

---

# ACTIVITY LOG ACCESS

| Feature | Super Admin | Inventory Admin | Supervisor | Storekeeper |
|----------|------------|------------|------------|------------|
| View Activity Log | ✅ | ✅ | ✅ | ✅ |
| Export Activity Log | ✅ | ✅ | ⚠ | ❌ |
| Review System Audit | ✅ | ✅ | ❌ | ❌ |

---

# SETTINGS ACCESS

| Feature | Super Admin | Inventory Admin | Supervisor | Storekeeper |
|----------|------------|------------|------------|------------|
| Personal Settings | ✅ | ✅ | ✅ | ✅ |
| Dashboard Preferences | ✅ | ✅ | ✅ | ✅ |
| Language Settings | ✅ | ✅ | ✅ | ✅ |
| Currency Settings | ✅ | ✅ | ❌ | ❌ |
| Backup & Restore | ✅ | ✅ | ❌ | ❌ |
| System Information | ✅ | ✅ | ✅ | ✅ |

---

# SUPPORT ACCESS

| Feature | Super Admin | Inventory Admin | Supervisor | Storekeeper |
|----------|------------|------------|------------|------------|
| Create Support Request | ✅ | ✅ | ✅ | ✅ |
| View Own Requests | ✅ | ✅ | ✅ | ✅ |
| View All Requests | ✅ | ✅ | ❌ | ❌ |
| Manage Requests | ✅ | ✅ | ❌ | ❌ |

---

# UPDATE SYSTEM ACCESS

The updater uses:

```text
GitHub Releases
```

as the active release source. 【6-bd9cb6】

| Feature | Super Admin | Inventory Admin | Supervisor | Storekeeper |
|----------|------------|------------|------------|------------|
| View Version | ✅ | ✅ | ✅ | ✅ |
| Check Updates | ✅ | ✅ | ✅ | ✅ |
| Download Update | ✅ | ✅ | ✅ | ✅ |
| Manage Release Process | ✅ | ❌ | ❌ | ❌ |

---

# CRITICAL SECURITY RESTRICTIONS

---

## Restriction 1

No role can:

```text
Delete Stock Movement History
```

Protection enforced by database logic. 【5-a3dce0】

---

## Restriction 2

No role can:

```text
Remove Final Active Super Admin
```

Protected by:

```text
manage_user_account()
```

【5-a3dce0】【1-9cd5b8】

---

## Restriction 3

Storekeepers cannot:

```text
Manage Users

Approve Registrations

Modify Configuration
```

---

## Restriction 4

Super Admin authority remains highest in the system hierarchy. 【1-9cd5b8】

---

# ROLE RESPONSIBILITY MATRIX

| Responsibility | Super Admin | Inventory Admin | Supervisor | Storekeeper |
|---------------|-------------|-----------------|------------|------------|
| Governance | ✅ | ⚠ | ❌ | ❌ |
| Security | ✅ | ⚠ | ❌ | ❌ |
| Inventory | ✅ | ✅ | ✅ | ✅ |
| Warehouses | ✅ | ✅ | ✅ | ⚠ |
| Users | ✅ | ✅ | ❌ | ❌ |
| Reporting | ✅ | ✅ | ✅ | ⚠ |
| Telemetry | ✅ | ✅ | ✅ | ✅ |
| Support | ✅ | ✅ | ✅ | ✅ |

---

# ACCESS GOVERNANCE RULES

---

## Rule 1

```text
Authentication Does Not Imply Authorization
```

---

## Rule 2

```text
Permissions Must Be Verified Server Side
```

---

## Rule 3

```text
RoleAccessService Is Not The Final Security Layer
```

Real enforcement exists in:

```text
Edge Functions

Database Policies

RPC Validation
```

【1-9cd5b8】【3-772e80】

---

## Rule 4

```text
Administrative Actions Must Be Auditable
```

through:

```text
activity_logs
```

【5-a3dce0】

---

# RBAC MATURITY ASSESSMENT

Current RBAC implementation provides:

```text
Role Hierarchy

Permission Segregation

Administrative Separation

Operational Separation

Telemetry Access Control

Registration Governance

Auditability
```

Assessment:

```text
RBAC Maturity: High
```

based on the discovered architecture and enforcement layers. 【1-9cd5b8】【3-772e80】

---

END OF DOCUMENT

INVWISE_15_ROLE_PERMISSION_MATRIX.md

Version 2.0.0
