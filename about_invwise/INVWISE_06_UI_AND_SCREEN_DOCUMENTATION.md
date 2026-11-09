# INVWISE_06_UI_AND_SCREEN_DOCUMENTATION
## Complete User Interface & Screen Documentation
### Version 2.0.0
### Source: Live Screen Discovery + Source Code Analysis

---

# PURPOSE OF THIS DOCUMENT

This document answers:

> "What does every screen in InvWise do?"

This document is intended for:

```text
Developers

Lecturers

Project Assessors

Future Maintainers

Successor Teams
```

---

# UI ARCHITECTURE OVERVIEW

Current Screen Count:

```text
30+ Screens
```

Architecture:

```text
Login
    ↓

Dashboard
    ↓

Inventory
├── Categories
├── Units
├── Warehouses
├── Stock Movement
└── Reports

Settings
├── Security
├── User Management
├── Registration Approvals
├── System Information
└── Version Information

Telemetry
├── Monitoring
├── Alerts
├── History
├── Analytics
└── Settings
```

Based on live route discovery. 【1-1647fe】

---

# APPLICATION ENTRY FLOW

```text
Application Launch
        ↓

Session Validation
        ↓

Login Page
        ↓

Dashboard
```

For approved users:

```text
Application Launch
        ↓

Existing Session
        ↓

Dashboard
```

---

# AUTHENTICATION MODULE

---

## LoginPage

Route:

```text
/login
```

Purpose:

```text
Primary system authentication.
```

Services:

```text
AuthService

LoginPreferencesService
```

Features:

```text
Email Login

Password Login

Remember Me

Forgot Password

Registration Request Access
```

Navigation:

```text
Dashboard

Registration Request
```

---

## RegistrationRequestPage

Route:

```text
/ register
```

Purpose:

```text
User account request submission.
```

Services:

```text
RegistrationRequestService
```

Collects:

```text
Full Name

Employee ID

Email

Department

Requested Role
```

Result:

```text
registration_requests
```

record created.

---

## RegistrationApprovalsPage

Route:

```text
/registration-approvals
```

Permission:

```text
manageRegistrationRequests
```

Purpose:

```text
Approve or reject user registrations.
```

Services:

```text
RegistrationApprovalService

RoleAccessService
```

User Types:

```text
Inventory Administrator

Super Admin
```

---

## RegistrationSetupPage

Route:

```text
/registration-setup
```

Purpose:

```text
Final account activation.
```

Functions:

```text
Password Creation

Account Finalization

Registration Completion
```

Connected To:

```text
complete-registration-setup
```

Edge Function.

---

## AuthDiagnosticsPage

Purpose:

```text
Authentication Testing

Diagnostic Validation
```

Status:

```text
Developer Utility
```

---

## AuthTestPage

Purpose:

```text
Authentication Verification
```

Status:

```text
Internal Testing Screen
```

---

# DASHBOARD MODULE

---

## DashboardPage

Route:

```text
/dashboard
```

Permission:

```text
viewDashboard
```

Purpose:

```text
Main application home screen.
```

Services:

```text
DashboardService

ProfileService

RoleAccessService

OfflineCacheService
```

---

### Major Widgets

```text
Dashboard Header

KPI Grid

Inventory Overview

Inventory Health

System Alerts

Recent Activity

Recent System Activity

Quick Actions

Sensor Monitoring

Monthly Insights
```

---

### Dashboard Navigation Sources

Dashboard is the central entry point to:

```text
Inventory

Reports

Activity Logs

Alerts

Settings

Telemetry Screens
```

---

# TELEMETRY MODULE

---

## TelemetryDetailsPage

Purpose:

```text
Detailed sensor visualization.
```

Service:

```text
SensorMonitoringService
```

Supports:

```text
DDS669

Toggle Switch
```

---

## TelemetryHistoryPage

Purpose:

```text
Historical telemetry review.
```

Services:

```text
SensorMonitoringService

ReportsService

TelemetryCsvExportService
```

Capabilities:

```text
History Query

Historical Analysis

CSV Export
```

---

## TelemetryAnalyticsPage

Purpose:

```text
Telemetry KPI Analysis
```

Service:

```text
SensorMonitoringService
```

Displays:

```text
Power Metrics

Energy Metrics

Usage Trends
```

---

## TelemetryEnergyReportsPage

Purpose:

```text
Energy Consumption Reporting
```

Focused On:

```text
DDS669 Data
```

---

## TelemetryAlertsPage

Purpose:

```text
Telemetry Alarm Management
```

Services:

```text
SensorMonitoringService

ReportsService

TelemetryCsvExportService
```

Displays:

```text
Voltage Alerts

Current Alerts

Offline Alerts
```

---

## TelemetrySettingsPage

Purpose:

```text
Telemetry Configuration
```

Database:

```text
telemetry_settings
```

Settings:

```text
Voltage Threshold

Current Threshold

Realtime Enabled

Offline Timeout
```

---

# INVENTORY MODULE

---

## InventoryPage

Purpose:

```text
Inventory Management Hub
```

Services:

```text
InventoryService

CategoryService

CurrencyService

StockMovementService

RoleAccessService
```

---

### Major Functions

```text
Search Inventory

Archive Inventory

Restore Inventory

Bulk Operations

Category Filtering

Stock Overview
```

---

### Permissions

```text
viewInventory

createInventory

adjustStock

bulkArchiveInventory

bulkChangeCategory

bulkChangeWarehouse

restoreArchivedInventory
```

---

### Dialogs

```text
Permanent Delete

Category Change

Archive Item

Bulk Actions
```

---

## ItemDetailsPage

Purpose:

```text
Detailed Item View
```

Displays:

```text
Item Information

Inventory Metrics

Activity History

Stock Records
```

Services:

```text
InventoryService

ActivityLogService

CurrencyService
```

---

## InventoryItemPage

Purpose:

```text
Create or Edit Inventory Item
```

Permissions:

```text
createInventory

editInventory
```

Services:

```text
InventoryService

CategoryService

UnitService
```

---

### Editable Areas

```text
SKU

Name

Description

Category

Unit

Minimum Stock

Price
```

---

# CATEGORY MODULE

---

## InventoryCategoriesPage

Purpose:

```text
Category Administration
```

Permission:

```text
manageCategories
```

Services:

```text
CategoryService

RoleAccessService
```

Operations:

```text
Create

Edit

Deactivate

Search
```

---

# UNIT MODULE

---

## StockUnitsPage

Purpose:

```text
Unit Administration
```

Permission:

```text
manageUnits
```

Services:

```text
UnitService
```

Operations:

```text
Create Unit

Edit Unit

Deactivate Unit
```

---

# WAREHOUSE MODULE

---

## WarehouseLocationsPage

Purpose:

```text
Warehouse Administration
```

Permission:

```text
manageWarehouses
```

Services:

```text
WarehouseLocationService
```

Operations:

```text
Create Location

Edit Location

Deactivate Location
```

---

# STOCK OPERATIONS MODULE

---

## StockAdjustmentPage

Purpose:

```text
Inventory Adjustment Processing
```

Permissions:

```text
adjustStock

issueStock

receiveStock
```

Services:

```text
InventoryService

RoleAccessService
```

Functions:

```text
Stock Receipt

Stock Issue

Stock Adjustment
```

---

# ACTIVITY LOGGING

---

## ActivityLogPage

Purpose:

```text
Inventory Activity Tracking
```

Services:

```text
ActivityLogService

InventoryService

StockMovementService
```

Widgets:

```text
Search

Filtering

Movement Creation

Activity Cards
```

---

## ActivityLogsPage

Route:

```text
/activity-logs
```

Permission:

```text
viewActivityLog
```

Purpose:

```text
Enterprise Audit Logging
```

Service:

```text
SystemActivityLogService
```

Displays:

```text
Audit Feed

User Actions

System Events
```

---

# ALERT MODULE

---

## AlertsPage

Purpose:

```text
Inventory Alerts Dashboard
```

Permission:

```text
viewInventory
```

Capabilities:

```text
Low Stock Alerts

Critical Stock Alerts

Inventory Exceptions
```

Service:

```text
RoleAccessService
```

---

# REPORTING MODULE

---

## ReportsPage

Purpose:

```text
Reporting Center
```

Permission:

```text
exportReports
```

Services:

```text
ReportsService

ReportExportService
```

Capabilities:

```text
CSV Export

Excel Export

Inventory Reports

Telemetry Reports
```

---

# SETTINGS MODULE

---

## SettingsPage

Purpose:

```text
System Configuration Hub
```

Services:

```text
AuthService

ProfileService

CurrencyService

RoleAccessService

LoginPreferencesService
```

---

### Access Points

```text
Security

Language

User Management

Registration Approvals

System Information

Currency Settings

Backup & Restore

Version Information

Support Center
```

---

## CurrencySettingsPage

Purpose:

```text
Currency Configuration
```

Permissions:

```text
manageExchangeRate

viewCurrencySettings
```

Services:

```text
CurrencyService

RoleAccessService

PasswordConfirmationService
```

Functions:

```text
Exchange Rate

Currency Conversion
```

---

## BackupRestorePage

Route:

```text
/settings/backup
```

Purpose:

```text
Preference Backup
```

Service:

```text
SettingsBackupService
```

Operations:

```text
Export Settings

Import Settings

Reset Settings
```

---

## AppVersionPage

Route:

```text
/system/version
```

Purpose:

```text
Application Version Information
```

Service:

```text
AppUpdateService
```

Capabilities:

```text
Check Updates

Read Release Notes

Download Updates
```

Source:

```text
GitHub Releases
```

---

## SystemInformationPage

Route:

```text
/system/information
```

Purpose:

```text
System Diagnostics
```

Services:

```text
AppUpdateService

ProfileService

OfflineCacheService

SensorMonitoringService
```

Displays:

```text
Application Version

Cache Status

Telemetry Status

System Health
```

---

# SECURITY MODULE

---

## SecurityPage

Purpose:

```text
Personal Security Dashboard
```

Permission:

```text
accessPersonalSecurity
```

Services:

```text
AuthService

SecurityHistoryService
```

Widgets:

```text
Current Device

Password

Biometric

Account Protection

Login Activity
```

---

## LoginHistoryPage

Purpose:

```text
Authentication History
```

Service:

```text
SecurityHistoryService
```

Displays:

```text
Login Success

Login Failure

History Timeline
```

---

## ActiveSessionsPage

Purpose:

```text
Active Device Monitoring
```

Service:

```text
SecurityHistoryService
```

Displays:

```text
Current Sessions

Known Devices

Login Locations
```

---

# USER MANAGEMENT MODULE

---

## UserManagementPage

Route:

```text
/user-management
```

Permission:

```text
manageUsers
```

Services:

```text
UserManagementService

RoleAccessService

PasswordConfirmationService
```

Operations:

```text
Role Change

Activation

Deactivation

User Search
```

---

# SUPPORT MODULE

---

## SupportCenterPage

Purpose:

```text
IT Support Portal
```

Functions:

```text
Help Requests

Support Search

Quick Help
```

Related Backend:

```text
support_requests

notify-support-request
```

---

# LANGUAGE MODULE

---

## LanguagePage

Purpose:

```text
Language Management
```

Stores:

```text
User Language Preference
```

Supported By:

```text
UserSettingsService
```

---

# PERSONAL PROFILE MODULE

---

## PersonalInformationPage

Purpose:

```text
User Profile Information
```

Services:

```text
ProfileService
```

Displays:

```text
Employee ID

Role

Department

Contact Information
```

---

# SCREEN PERMISSION MATRIX

```text
Dashboard                 → viewDashboard

Inventory                 → viewInventory

Activity Logs             → viewActivityLog

Reports                   → exportReports

Categories                → manageCategories

Units                     → manageUnits

Warehouses                → manageWarehouses

Users                     → manageUsers

Registration Approval     → manageRegistrationRequests

Security                  → accessPersonalSecurity

Currency Settings         → viewCurrencySettings
```

---

# UI DESIGN PRINCIPLES

```text
Role-Based Visibility

Minimal Navigation Levels

Dashboard-Centric Workflow

Mobile-First Layout

Offline-Aware Components

Telemetry Integration

Enterprise Auditability
```

---

# CURRENT UI FACTS

```text
30+ Screens

Authentication Module

Registration Workflow

Inventory Management

Stock Control

Warehouse Management

Category Management

Unit Management

Task Infrastructure

Security Management

User Management

Telemetry Monitoring

Reporting Suite

Support Center

GitHub Update Manager
```

---

END OF DOCUMENT

INVWISE_06_UI_AND_SCREEN_DOCUMENTATION.md

Version 2.0.0

---

# CURRENT UI IMPLEMENTATION UPDATE — 2026-11-09

## Archived Inventory Deletion

An archived item exposes separate **Delete Safely** and **Force Delete**
actions to Super Admins. Both actions are disabled until `DELETE` is typed and
both require the account password confirmation dialog. Safe Delete is the
default behavior and the database blocks it if stock movements or stock counts
exist, showing the record counts and preserving history. Force Delete warns
that it removes stock movements, stock counts, stock levels, and related
`activity_logs`; it is enforced again by the server-side Super Admin check.
Inventory Administrators can archive and restore but cannot permanently delete.

The client sends `p_item_id` and an explicit `p_force_delete` boolean to the
two-argument RPC. The database retains a separate deletion audit event after
the Force Delete cleanup.

## Authenticated Page Layout

Authenticated routes share `AuthenticatedPageLayout`: maximum content width
1600 px, 12 px mobile gutters below 600 px, 20 px tablet gutters below 1200 px,
and 32 px desktop gutters. The login, registration-request, and
registration-setup routes retain their existing layouts. The Dashboard,
Inventory, Telemetry, Settings, Reports, User Management, registration
approvals, Version, Security, Support, and other authenticated routes receive
the shared layout.

## Dashboard

The full Dashboard is the only dashboard implementation. The settings toggle,
saved preference, and condensed dashboard rendering have been removed.
