# INVWISE_11_SYSTEM_WORKFLOWS_AND_BUSINESS_PROCESSES
## End-to-End Operational Workflow Documentation
### Version 2.0.0
### Source: Database Discovery + Service Discovery + UI Discovery + Security Discovery

---

# PURPOSE OF THIS DOCUMENT

This document answers:

> "How does InvWise actually operate from beginning to end?"

This document focuses on:

```text
Business Processes

User Flows

Inventory Flows

Registration Flows

Security Flows

Telemetry Flows

Support Flows

Administrative Operations
```

Unlike previous documents, this document describes:

```text
What happens

Who performs it

Which screens are used

Which services are involved

Which database objects are updated
```

---

# SYSTEM WORKFLOW MAP

```text
User Registration
        │
        ▼

Account Approval
        │
        ▼

Account Activation
        │
        ▼

Authentication
        │
        ▼

Dashboard Access
        │
        ▼

Inventory Operations
        │
        ▼

Reporting
        │
        ▼

Audit Logging
```

---

# WORKFLOW 1
# USER REGISTRATION

---

## Objective

Allow a new staff member to request access.

---

## Actor

```text
Future User
```

---

## Entry Point

```text
RegistrationRequestPage
```

---

## Flow

```text
User Opens Registration Page
                ↓

Enter Personal Information
                ↓

Select Requested Role
                ↓

Submit Request
                ↓

Validation Performed
                ↓

registration_requests Record Created
                ↓

Status = pending
```

---

## Services

```text
RegistrationRequestService
```

---

## Database Tables

```text
registration_requests
```

---

## Result

Request enters approval queue.

---

# WORKFLOW 2
# REGISTRATION APPROVAL

---

## Objective

Authorize new user creation.

---

## Actors

```text
Super Admin

Inventory Administrator
```

---

## Entry Point

```text
RegistrationApprovalsPage
```

---

## Flow

```text
Administrator Opens Queue
                 ↓

Review Registration
                 ↓

Approve Request
                 ↓

Status Updated
                 ↓

Provisioning Started
```

---

## Services

```text
RegistrationApprovalService
```

---

## Database Objects

```text
registration_requests
```

---

## Result

Account becomes eligible for provisioning.

---

# WORKFLOW 3
# ACCOUNT PROVISIONING

---

## Objective

Create authenticated system account.

---

## Flow

```text
Approved Request
          ↓

provision-approved-registration
          ↓

claim_registration_provisioning()
          ↓

create_registration_profile()
          ↓

Supabase Auth User Created
          ↓

Profile Created
          ↓

Invitation Generated
```

---

## Edge Function

```text
provision-approved-registration
```

---

## Functions

```text
claim_registration_provisioning()

create_registration_profile()
```

---

## Tables Updated

```text
registration_requests

profiles
```

---

## Security

Uses:

```text
SECURITY DEFINER

Service Role
```

operations.

---

# WORKFLOW 4
# ACCOUNT ACTIVATION

---

## Objective

Allow approved user to create login credentials.

---

## Entry Point

```text
RegistrationSetupPage
```

---

## Flow

```text
User Opens Invitation
          ↓

Activation Link
          ↓

Set Password
          ↓

Validation
          ↓

complete-registration-setup
          ↓

Account Activated
          ↓

Registration Completed
```

---

## Edge Function

```text
complete-registration-setup
```

---

## Result

User becomes active.

---

# WORKFLOW 5
# USER LOGIN

---

## Objective

Authenticate existing user.

---

## Flow

```text
User Opens Login Screen
          ↓

Enter Credentials
          ↓

Supabase Authentication
          ↓

Session Created
          ↓

Profile Loaded
          ↓

Dashboard Opened
```

---

## Services

```text
AuthService

LoginTrackingService

LoginPreferencesService
```

---

## Tables Updated

```text
login_events

device_sessions

profiles
```

---

## Outputs

```text
JWT Session

Device Tracking

Login Audit Record
```

---

# WORKFLOW 6
# DASHBOARD INITIALIZATION

---

## Objective

Load application summary view.

---

## Flow

```text
Successful Login
          ↓

Profile Retrieval
          ↓

Permission Evaluation
          ↓

Dashboard Service
          ↓

KPI Aggregation
          ↓

Dashboard Rendering
```

---

## Services

```text
DashboardService

RoleAccessService

ProfileService
```

---

## Dashboard Displays

```text
Inventory Summary

Telemetry Summary

Recent Activity

System Alerts

Quick Actions
```

---

# WORKFLOW 7
# INVENTORY CREATION

---

## Objective

Create a new inventory item.

---

## Actor

```text
Inventory Administrator
```

---

## Flow

```text
Inventory Item Page
          ↓

Input Details
          ↓

Validation
          ↓

Save Item
          ↓

inventory_items Record Created
```

---

## Services

```text
InventoryService
```

---

## Related Tables

```text
inventory_items

categories

units
```

---

## Result

Inventory item becomes available.

---

# WORKFLOW 8
# STOCK RECEIPT

---

## Objective

Increase inventory quantity.

---

## Flow

```text
Stock Adjustment Page
            ↓

Receive Stock
            ↓

Quantity Entered
            ↓

Stock Movement Created
            ↓

apply_stock_movement()
            ↓

stock_levels Updated
```

---

## Movement Type

```text
receipt
```

---

## Tables Updated

```text
stock_movements

stock_levels
```

---

## Auditability

Movement permanently stored.

---

# WORKFLOW 9
# STOCK ISSUE

---

## Objective

Remove stock from inventory.

---

## Flow

```text
Issue Stock
        ↓

Movement Created
        ↓

apply_stock_movement()
        ↓

Quantity Reduced
```

---

## Movement Type

```text
issue
```

---

## Tables Updated

```text
stock_movements

stock_levels
```

---

# WORKFLOW 10
# STOCK TRANSFER

---

## Objective

Move stock between locations.

---

## Flow

```text
Select Item
       ↓

Source Warehouse
       ↓

Destination Warehouse
       ↓

Transfer Movement
       ↓

Stock Updated
```

---

## Movement Type

```text
transfer
```

---

## Tables

```text
stock_movements

stock_levels

warehouse_locations
```

---

# WORKFLOW 11
# STOCK ADJUSTMENT

---

## Objective

Correct inventory discrepancies.

---

## Flow

```text
Inventory Check
         ↓

Discrepancy Found
         ↓

Adjustment Created
         ↓

Inventory Updated
```

---

## Movement Type

```text
adjustment
```

---

## Audit Requirement

Adjustment reason required.

---

# WORKFLOW 12
# INVENTORY ARCHIVING

---

## Objective

Retire inventory items.

---

## Flow

```text
Archive Command
         ↓

Permission Check
         ↓

is_archived = true
         ↓

Archive Metadata Stored
```

---

## Updated Fields

```text
is_archived

archived_at

archived_by
```

---

## No Physical Deletion

Inventory remains recoverable.

---

# WORKFLOW 13
# INVENTORY RESTORATION

---

## Objective

Restore archived inventory.

---

## Flow

```text
Archived Item Selected
          ↓

Restore Action
          ↓

Archive Flags Removed
          ↓

Item Available Again
```

---

# WORKFLOW 14
# USER MANAGEMENT

---

## Objective

Manage existing users.

---

## Actor

```text
Super Admin

Inventory Administrator
```

---

## Entry Point

```text
UserManagementPage
```

---

## Operations

```text
Role Change

Activation

Deactivation
```

---

## Flow

```text
Select User
       ↓

Choose Action
       ↓

manage-users
       ↓

manage_user_account()
       ↓

Database Updated
```

---

## Critical Protection

```text
Last Active Super Admin
Cannot Be Removed
```

---

# WORKFLOW 15
# TELEMETRY INGESTION

---

## Objective

Receive telemetry information.

---

## Flow

```text
Telemetry Producer
         ↓

Supabase Insert
         ↓

energy_readings
or
switch_events
         ↓

Database Trigger
         ↓

History Updated
         ↓

Status Updated
```

---

## Tables

```text
energy_readings

switch_events

sensor_status

sensor_history
```

---

# WORKFLOW 16
# ENERGY MONITORING

---

## Objective

Monitor electrical consumption.

---

## Device

```text
DDS669_01
```

---

## Process

```text
Reading Created
         ↓

Voltage Recorded
         ↓

Current Recorded
         ↓

Power Recorded
         ↓

Energy Recorded
         ↓

Dashboard Updated
```

---

## Metrics

```text
Voltage

Current

Power

Energy
```

---

# WORKFLOW 17
# TOGGLE SWITCH MONITORING

---

## Device

```text
SW_01
```

---

## Flow

```text
Switch State Change
          ↓

switch_events Insert
          ↓

fn_process_switch_event()
          ↓

sensor_status Updated
          ↓

Dashboard Updated
```

---

# WORKFLOW 18
# ALERT GENERATION

---

## Objective

Detect abnormal telemetry.

---

## Trigger Conditions

```text
High Voltage

High Current

Sensor Offline
```

---

## Flow

```text
Threshold Exceeded
            ↓

Alert Created
            ↓

sensor_alerts Record
            ↓

Telemetry Alert Screen
            ↓

Dashboard Notification
```

---

# WORKFLOW 19
# REPORT EXPORT

---

## Objective

Export operational reports.

---

## Entry Point

```text
ReportsPage
```

---

## Flow

```text
Choose Report
         ↓

Choose Format
         ↓

Generate Report
         ↓

CSV / XLSX Export
```

---

## Services

```text
ReportsService

ReportExportService
```

---

## Supported Formats

```text
CSV

Excel
```

---

# WORKFLOW 20
# APPLICATION UPDATE

---

## Objective

Deliver new application versions.

---

## Flow

```text
Application Startup
         ↓

AppUpdateService
         ↓

GitHub Releases
         ↓

Compare Versions
         ↓

Update Available
         ↓

User Downloads APK
```

---

## Update Statuses

```text
latest

available

required

unavailable
```

---

## Force Update Path

```text
force_update = true
```

↓

```text
Mandatory Update Dialog
```

---

# WORKFLOW 21
# SUPPORT REQUEST

---

## Objective

Allow users to contact support.

---

## Entry Point

```text
SupportCenterPage
```

---

## Flow

```text
Create Ticket
       ↓

Submit Request
       ↓

support_requests Insert
       ↓

notify-support-request
       ↓

Support Team Notification
```

---

## Tables

```text
support_requests
```

---

## Edge Function

```text
notify-support-request
```

---

# WORKFLOW 22
# AUDIT LOGGING

---

## Objective

Maintain traceability.

---

## Sources

```text
Inventory Actions

User Actions

System Events

Telemetry Actions
```

---

## Flow

```text
Action Occurs
       ↓

Audit Record Generated
       ↓

activity_logs
       ↓

Activity Log Screen
```

---

## Benefits

```text
Compliance

Troubleshooting

Accountability
```

---

# COMPLETE BUSINESS PROCESS MAP

```text
Registration
      ↓

Approval
      ↓

Provisioning
      ↓

Activation
      ↓

Login
      ↓

Dashboard
      ↓

Inventory Operations
      ↓

Telemetry Monitoring
      ↓

Reporting
      ↓

Audit Logging
      ↓

Support & Maintenance
```

---

# CRITICAL BUSINESS RULES

---

## Rule 1

```text
Inventory Quantity
Lives In stock_levels
```

---

## Rule 2

```text
Stock Movements
Cannot Be Edited
```

---

## Rule 3

```text
Registration Must Be Approved
Before Provisioning
```

---

## Rule 4

```text
Provisioning Must Complete
Before Activation
```

---

## Rule 5

```text
At Least One Active
Super Admin Must Exist
```

---

## Rule 6

```text
Telemetry Alerts
Are Threshold Driven
```

---

## Rule 7

```text
GitHub Releases
Is The Active Update Source
```

---

# CURRENT WORKFLOW SUMMARY

```text
22 Documented Workflows

Registration Lifecycle

Authentication Lifecycle

Inventory Lifecycle

Telemetry Lifecycle

Reporting Lifecycle

Support Lifecycle

Update Lifecycle

Audit Lifecycle
```

---

END OF DOCUMENT

INVWISE_11_SYSTEM_WORKFLOWS_AND_BUSINESS_PROCESSES.md

Version 2.0.0
