# INVWISE_09_UPDATE_AND_DEPLOYMENT_ARCHITECTURE
## Application Updates, Release Management & Deployment Design
### Version 2.0.0
### Source: Live Update Discovery + Project Analysis

---

# PURPOSE OF THIS DOCUMENT

This document answers:

> "How is InvWise deployed, updated, upgraded, and maintained in production?"

This document covers:

```text
Application Deployment

Version Management

Update Architecture

GitHub Releases

APK Distribution

Release Lifecycle

Update Security

Future CI/CD Strategy
```

Based on the current implementation discovered in the source code and update subsystem. 【1-4498c0】

---

# DEPLOYMENT OVERVIEW

InvWise currently follows:

```text
Flutter
        │
        ▼

GitHub Repository
        │
        ▼

GitHub Releases
        │
        ▼

APK Distribution
        │
        ▼

End Users
```

The application does not currently use:

```text
Google Play Store

Apple App Store

Microsoft Store
```

as the primary update source.

The current update source is:

```text
GitHub Releases
```

【1-4498c0】

---

# SYSTEM DEPLOYMENT ARCHITECTURE

```text
Flutter Application
        │
        ▼

Supabase Backend

        │

───────────────

Authentication

Database

Storage

Edge Functions

───────────────

        │
        ▼

Production Users
```

---

# DEPLOYMENT COMPONENTS

---

## Frontend

Technology:

```text
Flutter
```

Targets:

```text
Android

Web

Windows

Linux

macOS

iOS
```

Repository structure confirms multi-platform support exists in the project source tree. 【2-953d30】【3-f5fb73】

---

## Backend

Technology:

```text
Supabase
```

Services:

```text
Authentication

PostgreSQL Database

RLS Policies

Edge Functions
```

【4-a2b170】【5-abcb60】

---

## Edge Function Layer

Current Functions:

```text
complete-registration-setup

manage-users

notify-support-request

provision-approved-registration

login-with-employee-id
```

【6-92bc19】

---

# APPLICATION VERSIONING

---

## Current Version

Repository state indicates:

```text
2.0.0+2
```

Application uses semantic versioning.

Project state confirms:

```text
Flutter 2.0.0+2
```

【7-7b63e6】

---

# VERSION FORMAT

Supported format:

```text
major.minor.patch
```

Examples:

```text
1.0.0

1.2.0

2.0.0

2.0.1
```

---

# BUILD NUMBER

Optional metadata:

```text
2.0.0+2

2.0.0+15

2.0.0+25
```

Build metadata is ignored during release comparison. 【1-4498c0】

---

# UPDATE ARCHITECTURE

---

## Current Design

InvWise no longer uses:

```text
Supabase app_versions
```

for active update management.

Instead:

```text
GitHub Releases
```

is the source of truth. 【1-4498c0】【7-7b63e6】

---

# UPDATE FLOW

```text
Application Startup
         ↓

Authentication Success
         ↓

AppUpdateService
         ↓

GitHub Releases API
         ↓

Latest Release Retrieved
         ↓

Version Comparison
         ↓

Update Decision
```

【1-4498c0】

---

# UPDATE STATES

The application supports:

```text
latest

available

required

unavailable
```

【1-4498c0】

---

# UPDATE LOGIC

---

## Latest

Condition:

```text
Installed Version
=
Newest Version
```

Result:

```text
No Action Required
```

---

## Available

Condition:

```text
New Version Found
```

Result:

```text
User May Update
```

---

## Required

Condition:

```text
Force Update Enabled
```

Result:

```text
Update Required
```

【1-4498c0】

---

## Unavailable

Condition:

```text
Release Server Unreachable
```

Result:

```text
Cannot Verify Version
```

---

# UPDATE SERVICE

---

## AppUpdateService

Purpose:

```text
Version Detection

Version Comparison

Release Retrieval

APK Download Links

Release Notes
```

Source:

```text
GitHub Releases API
```

【1-4498c0】

---

# VERSION COMPARISON

Supported:

```text
v2.0.0

2.0.0

2.0.1

2.1.0

3.0.0
```

The comparison engine evaluates:

```text
Major

Minor

Patch
```

Build metadata is ignored. 【1-4498c0】

---

# GITHUB RELEASE PROCESS

---

## Release Creation

Developer Creates:

```text
Git Tag
```

↓

```text
GitHub Release
```

↓

```text
APK Upload
```

↓

```text
Release Notes
```

↓

```text
Users Receive Update
```

---

# APK DISCOVERY

AppUpdateService retrieves:

```text
Release Assets
```

and selects:

```text
First .apk Asset
```

from the release package.

【1-4498c0】

---

# RELEASE NOTES

Supported source:

```text
GitHub Release Body
```

Fallback:

```text
release_notes
```

field.

【1-4498c0】

---

# FORCE UPDATE SYSTEM

---

## Purpose

Protect users from:

```text
Critical Bugs

Security Vulnerabilities

Schema Mismatches

Breaking Changes
```

---

# Activation Method

A release becomes mandatory when:

```text
force_update = true
```

or release notes contain:

```text
force_update: true
```

【1-4498c0】

---

# Behaviour

Force update causes:

```text
Update Dialog Locked

Dismiss Disabled

Back Navigation Disabled
```

until update action is performed. 【1-4498c0】

---

# IMPORTANT LIMITATION

Current implementation provides:

```text
UI Enforcement
```

not:

```text
Server Enforcement
```

There is no discovered evidence that backend services reject older application versions. 【1-4498c0】

---

# DOWNLOAD PROCESS

---

## APK Download

Flow:

```text
User Selects Update
         ↓

Retrieve APK URL
         ↓

Validate URL
         ↓

Launch Download
```

【1-4498c0】

---

# URL SECURITY

Only accepted:

```text
HTTPS URLs
```

Rejected:

```text
User Credentials In URL

Non-HTTPS Links
```

【1-4498c0】

---

# URL VALIDATION

Validation Process:

```text
HTTPS Check
         ↓

HEAD Request
         ↓

Fallback GET
         ↓

Open External Application
```

【1-4498c0】

---

# VERSION INFORMATION SCREEN

---

## AppVersionPage

Route:

```text
/system/version
```

Displays:

```text
Current Version

Update Status

Available Version

Release Notes
```

Uses:

```text
AppUpdateService
```

【8-7865e6】【1-4498c0】

---

# SYSTEM INFORMATION SCREEN

---

## SystemInformationPage

Route:

```text
/system/information
```

Displays:

```text
System Version

Application Details

Telemetry Status

Cache Information
```

Uses:

```text
AppUpdateService
```

【8-7865e6】

---

# UPDATE AUDITING

All update activity is recorded through:

```text
SystemActivityLogService
```

Allowing:

```text
Update Attempts

Update Failures

Version Events
```

to be captured. 【1-4498c0】

---

# LEGACY UPDATE SYSTEM

---

## app_versions

Database table still exists.

Purpose:

```text
Previous Update Architecture
```

Fields include:

```text
Version

APK URL

Force Update

Release Notes
```

【4-a2b170】

---

# CURRENT STATUS

Live discovery indicates:

```text
Updater Does Not Use app_versions
```

Flutter source references were not found.

GitHub Releases is the active update mechanism. 【1-4498c0】

---

# RELEASE GOVERNANCE

Recommended release path:

```text
Development
      ↓

Testing
      ↓

Git Tag
      ↓

GitHub Release
      ↓

APK Upload
      ↓

Production Deployment
```

---

# DEPLOYMENT ENVIRONMENTS

Current repository supports:

```text
Development

Testing

Production
```

through configuration separation.

Environment values include:

```text
Supabase URL

Publishable Keys

GitHub Release Sources
```

---

# EDGE FUNCTION DEPLOYMENT

Deployment targets:

```text
Supabase Edge Runtime
```

Functions deployed:

```text
complete-registration-setup

manage-users

notify-support-request

provision-approved-registration
```

Production-critical business logic resides here. 【6-92bc19】

---

# DATABASE DEPLOYMENT

Current database evolution uses:

```text
Supabase Migrations
```

Local migration count:

```text
14 Migrations
```

Remote ledger contains a subset of those migrations and reconciliation remains a deployment concern. 【9-2b7de9】【7-7b63e6】

---

# DEPLOYMENT RISKS

---

## Risk 1

```text
Migration Drift
```

Local files and remote migration ledger are not fully aligned. 【9-2b7de9】

---

## Risk 2

```text
Legacy Update Table
```

app_versions still exists despite no active updater dependency. 【1-4498c0】【7-7b63e6】

---

## Risk 3

```text
Forced Update Is Client-Side
```

Backend version enforcement was not discovered. 【1-4498c0】

---

## Risk 4

```text
APK Installation Behaviour
```

Must be validated on target Android devices. 【7-7b63e6】【1-4498c0】

---

# FUTURE CI/CD ROADMAP

Potential future architecture:

```text
Git Push
     ↓

GitHub Actions

     ↓

Flutter Build

     ↓

APK Generation

     ↓

GitHub Release

     ↓

Automatic Deployment
```

(Note: roadmap suggestion, not current implementation.)

---

# CURRENT UPDATE FACTS

```text
GitHub Releases Active

Semantic Versioning

APK Distribution

Force Update Support

Release Note Support

HTTPS Validation

Update Auditing

Legacy app_versions Table

Migration-Based Deployment

Supabase Backend
```

---

END OF DOCUMENT

INVWISE_09_UPDATE_AND_DEPLOYMENT_ARCHITECTURE.md

Version 2.0.0

---

# UPDATE RESILIENCE AND DEPLOYMENT ADDENDUM — 2026-11-09

## Release API Cache and Rate Limits

The latest-release payload and release-history payload use separate persistent
cache keys in `OfflineCacheService`; release-history keys include the requested
limit. Entries are fresh for one hour. Fresh values avoid GitHub API calls.
HTTP 403/429 uses an available cached response and displays a stale-data
notice. With no cached payload, the update result is unavailable and presents a
retry-later message instead of a raw HTTP exception. Requests include GitHub's
JSON `Accept` header and an identifying `User-Agent`.

The parser still performs semantic version comparison, detects `.apk` assets,
extracts notes, and recognizes `force_update: true`. These paths remain covered
by the AppUpdateService test suite. Update history loads separately so it does
not break the latest-version view.

## Inventory RPC Deployment Sequence

The permanent-delete overload is introduced by
`supabase/migrations/20261109210000_permanent_inventory_delete_safety.sql`.
Apply and verify this migration in staging before publishing a Flutter client
that sends `p_force_delete`. The existing one-argument RPC delegates to safe
mode, but the updated Flutter client calls the two-argument overload.

Do not blindly run `supabase db push` against production where earlier
migrations are missing from the remote ledger. Reconcile migration history,
apply the reviewed forward migration through the controlled process, refresh
PostgREST's schema cache, and test safe/force behaviors on disposable records
before the production rollout. No production data was changed by preparing the
migration.
