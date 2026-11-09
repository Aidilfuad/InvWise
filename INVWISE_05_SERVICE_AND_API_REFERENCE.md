# INVWISE_05_SERVICE_AND_API_REFERENCE
## Complete Service Layer Documentation
### Business Logic, Data Access & Application Services
### Version 2.0.0
### Source: Live Source Code Discovery

---

# PURPOSE OF THIS DOCUMENT

This document answers:

> "How does InvWise actually work internally?"

The database stores data.

The UI displays data.

The service layer contains:

```text
Business Logic

Permission Logic

Validation Logic

Workflow Logic

API Communication

Supabase Communication
```

This is the most important part of the application.

---

# SERVICE LAYER OVERVIEW

Current Service Count:

```text
≈30 Services
```

Service Architecture:

```text
Flutter UI
        │
        ▼
Service Layer
        │
        ▼
Supabase
        │
        ▼
Database
```

No page should communicate directly with the database.

All data access should pass through services.

---

# SERVICE GROUPING

---

## Authentication Services

```text
AuthService

LoginPreferencesService

LoginTrackingService

SecuritySessionTracker
```

---

## User Management Services

```text
ProfileService

UserManagementService

RoleAccessService
```

---

## Registration Services

```text
RegistrationRequestService

RegistrationApprovalService
```

---

## Inventory Services

```text
InventoryService

CategoryService

UnitService

WarehouseLocationService

StockMovementService
```

---

## Dashboard Services

```text
DashboardService

DashboardPreferencesService
```

---

## Reporting Services

```text
ReportsService

ReportExportService

TelemetryCsvExportService
```

---

## Telemetry Services

```text
SensorMonitoringService
```

---

## Settings Services

```text
CurrencyService

UserSettingsService

SettingsBackupService

AppUpdateService
```

---

## Security Services

```text
SecurityHistoryService

PasswordConfirmationService
```

---

## Activity Services

```text
ActivityLogService

SystemActivityLogService
```

---

# AUTHENTICATION MODULE

---

# AuthService

Purpose:

```text
Primary authentication service.
```

Responsible For:

```text
Login

Logout

Session Validation

Session Refresh

Current User Retrieval
```

Dependencies:

```text
Supabase Auth
```

Used By:

```text
LoginPage

SecurityPage

SettingsPage

Application Startup
```

Critical Functions:

```text
signIn()

signOut()

currentUser()

refreshSession()
```

---

# LoginPreferencesService

Purpose:

```text
Remember Me Logic
```

Stores:

```text
Remembered Email

Remember Me Flag

Session Expiry
```

Used By:

```text
LoginPage

Application Startup
```

Tests:

```text
Remember Me persistence
Session restoration
Session expiry validation
```

---

# LoginTrackingService

Purpose:

```text
Security event logging.
```

Tracks:

```text
Login Success

Login Failure

Device Information

Time
```

Database:

```text
login_events
```

---

# SecuritySessionTracker

Purpose:

```text
Device session monitoring.
```

Database:

```text
device_sessions
```

Tracks:

```text
Current Device

Last Active

Session Revocation
```

---

# ROLE & ACCESS CONTROL

---

# RoleAccessService

Purpose:

```text
Authorization Engine
```

Determines:

```text
Who can access what.
```

---

## Supported Roles

```text
Super Admin

Inventory Administrator

Warehouse Supervisor

Storekeeper
```

---

## Main Responsibilities

```text
Permission Evaluation

Role Checks

UI Protection

Navigation Protection
```

---

## Important Note

RoleAccessService:

```text
DOES NOT provide security
```

Actual security is enforced by:

```text
Database RLS

Edge Functions
```

---

# ProfileService

Purpose:

```text
Current User Profile Management
```

Database:

```text
profiles
```

Handles:

```text
Profile Retrieval

Profile Updates

Role Information

Department Information
```

---

# UserManagementService

Purpose:

```text
Enterprise User Administration
```

Used By:

```text
UserManagementPage
```

Edge Function:

```text
manage-users
```

RPC:

```text
manage_user_account()
```

Supports:

```text
Change Role

Deactivate User

Activate User
```

---

## Critical Protection

Prevents:

```text
Last Active
Super Admin

from being removed.
```

---

# REGISTRATION WORKFLOW

---

# RegistrationRequestService

Purpose:

```text
Create Registration Requests
```

Database:

```text
registration_requests
```

Supports:

```text
Submit New Request

Validation

Status Tracking
```

---

# RegistrationApprovalService

Purpose:

```text
Approve User Registrations
```

Used By:

```text
RegistrationApprovalsPage
```

Edge Function:

```text
provision-approved-registration
```

RPCs:

```text
claim_registration_provisioning()

create_registration_profile()
```

Workflow:

```text
Request Submitted
       ↓
Request Approved
       ↓
Account Provisioned
       ↓
Activation Link
       ↓
Password Setup
       ↓
User Activated
```

---

# INVENTORY MODULE

---

# InventoryService

Purpose:

```text
Core Inventory Business Logic
```

Database:

```text
inventory_items

stock_levels

stock_movements
```

Supports:

```text
Create Item

Edit Item

Archive Item

Restore Item

View Item

Inventory Search
```

---

## Important Business Rule

Quantity is never stored in:

```text
inventory_items
```

Quantity comes from:

```text
stock_levels
```

---

# CategoryService

Purpose:

```text
Category Management
```

Database:

```text
categories
```

Supports:

```text
Create

Edit

Deactivate
```

---

# UnitService

Purpose:

```text
Unit Management
```

Database:

```text
units
```

Supports:

```text
Create

Edit

Deactivate
```

---

# WarehouseLocationService

Purpose:

```text
Warehouse Management
```

Database:

```text
warehouse_locations
```

Supports:

```text
Create

Edit

Deactivate
```

---

# StockMovementService

Purpose:

```text
Inventory Transaction Processing
```

Database:

```text
stock_movements
```

Movement Types:

```text
Receipt

Issue

Transfer

Adjustment

Return
```

---

## Important Rule

Never:

```text
UPDATE stock_movements
```

Never:

```text
DELETE stock_movements
```

The database blocks this through:

```text
prevent_stock_movement_mutation()
```

---

# DASHBOARD MODULE

---

# DashboardService

Purpose:

```text
Dashboard Data Aggregation
```

Collects:

```text
Inventory Metrics

Stock Health

Recent Activities

Alerts

Reports
```

---

# DashboardPreferencesService

Purpose:

```text
Dashboard Mode Configuration
```

Supports:

```text
Full Dashboard

Compact Dashboard
```

Used By:

```text
DashboardPage

SettingsPage
```

---

# TELEMETRY MODULE

---

# SensorMonitoringService

Purpose:

```text
Telemetry Engine
```

Database:

```text
sensors

sensor_status

sensor_history

energy_readings

switch_events

sensor_alerts

telemetry_settings
```

---

## Current Hardware Support

```text
DDS669 Energy Meter

Toggle Switch
```

Verified Live Sensors:

```text
DDS669_01

SW_01
```

Source discovery confirms active telemetry records exist. 【1-6aae4c】

---

## DDS669 Metrics

```text
Voltage

Current

Power

Energy
```

---

## Toggle Switch Metrics

```text
ON

OFF

Last Seen
```

---

## Current Limitations

No discovered implementation for:

```text
RFID

Barcode

MQTT

Node-RED Client

IRIV
```

Current evidence suggests these are:

```text
Legacy

Future

Unused
```

rather than active integrations. 【1-6aae4c】

---

# REPORTING MODULE

---

# ReportsService

Purpose:

```text
Report Generation
```

Supports:

```text
Inventory Reports

Valuation Reports

Telemetry Reports
```

---

# ReportExportService

Purpose:

```text
File Export Engine
```

Supports:

```text
CSV

Excel
```

Verified By Tests:

```text
CSV Export

XLSX Export
```

---

# TelemetryCsvExportService

Purpose:

```text
Telemetry Report Export
```

Exports:

```text
Energy Data

Sensor History

Telemetry Analytics
```

---

# ACTIVITY LOGGING

---

# ActivityLogService

Purpose:

```text
Inventory Activity Tracking
```

Tables:

```text
activity_log
```

Tracks:

```text
Inventory Events

Movement Events

Warehouse Events
```

---

# SystemActivityLogService

Purpose:

```text
Enterprise Audit Logging
```

Tables:

```text
activity_logs
```

Tracks:

```text
Actor

Action

Category

Entity

Metadata
```

---

# SECURITY SERVICES

---

# SecurityHistoryService

Purpose:

```text
Security Audit Retrieval
```

Retrieves:

```text
Login History

Session History

Security Events
```

Used By:

```text
SecurityPage

LoginHistoryPage

ActiveSessionsPage
```

---

# PasswordConfirmationService

Purpose:

```text
High-Risk Action Validation
```

Used Before:

```text
Delete Inventory

User Management

Currency Changes

Administration Actions
```

---

# SETTINGS MODULE

---

# CurrencyService

Purpose:

```text
Currency Conversion Logic
```

Databases:

```text
user_settings

app_settings
```

Supports:

```text
MYR

USD
```

---

# UserSettingsService

Purpose:

```text
User Preferences
```

Stores:

```text
Theme

Language

Currency
```

---

# SettingsBackupService

Purpose:

```text
Backup & Restore User Settings
```

Supports:

```text
Export Preferences

Import Preferences

Reset Settings
```

---

# APP UPDATE MODULE

---

# AppUpdateService

Purpose:

```text
Application Update Management
```

Current Source:

```text
GitHub Releases
```

Not:

```text
Supabase
```

Confirmed by discovery. 【2-c8aaa0】

---

## Supports

```text
Version Check

Semantic Comparison

Force Update

Release Notes

APK Downloads
```

---

## Force Update Rules

Release can contain:

```text
force_update: true
```

which blocks dismissal of update dialog. 【2-c8aaa0】

---

## Legacy Component

Database table:

```text
app_versions
```

still exists.

Current implementation:

```text
does not use it.
```

【2-c8aaa0】【3-f549a1】

---

# SUPPORT MODULE

---

# SupportRequestService

Purpose:

```text
Helpdesk Ticket Submission
```

Database:

```text
support_requests
```

Edge Function:

```text
notify-support-request
```

Supports:

```text
Create Ticket

Notify Support Team

Track Status
```

---

# EDGE FUNCTION INTERACTION MAP

---

## complete-registration-setup

Used For:

```text
Account Activation
```

---

## provision-approved-registration

Used For:

```text
Account Provisioning
```

---

## manage-users

Used For:

```text
User Management
```

---

## notify-support-request

Used For:

```text
Support Notifications
```

---

## login-with-employee-id

Status:

```text
Not Implemented
```

Current code is a starter template. 【4-e4b71d】【5-b6b67c】

---

# SERVICE LAYER DESIGN RULES

---

## Rule 1

```text
UI Never Talks Directly To Database
```

Use services.

---

## Rule 2

```text
Critical Operations
Must Flow Through Edge Functions
```

Examples:

```text
User Management

Provisioning

Activation
```

---

## Rule 3

```text
Inventory History
Must Remain Immutable
```

Never modify:

```text
stock_movements
```

---

## Rule 4

```text
RoleAccessService
Provides UI Control

NOT Security
```

Real security:

```text
RLS

Database Functions

Edge Functions
```

---

# CURRENT SERVICE LAYER FACTS

```text
≈30 Services

Authentication Layer

Registration Workflow

Inventory Engine

Telemetry Engine

Reporting Engine

Security Layer

GitHub Release Updater

Edge Function Integration

Support Ticket System
```

---

END OF DOCUMENT

INVWISE_05_SERVICE_AND_API_REFERENCE.md

Version 2.0.0
