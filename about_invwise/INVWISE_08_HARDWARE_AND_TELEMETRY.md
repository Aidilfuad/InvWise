# INVWISE_08_HARDWARE_AND_TELEMETRY
## Complete Hardware Integration & Telemetry Architecture
### Version 2.0.0
### Source: Live Telemetry Discovery + Database Analysis

---

# PURPOSE OF THIS DOCUMENT

This document answers:

> "How does telemetry work inside InvWise?"

This document covers:

```text
Hardware Architecture

Telemetry Database

Sensor Processing

Alert Generation

Dashboard Integration

Telemetry Security

Current Hardware Support

Future Hardware Expansion
```

Based on live telemetry discovery and the current production schema. 【1-2d735d】【2-71689a】

---

# TELEMETRY OVERVIEW

The telemetry module provides:

```text
Real-Time Monitoring

Energy Monitoring

Device Status Monitoring

Historical Analysis

Alert Generation

Dashboard Visualisation
```

Current implementation supports:

```text
DDS669 Energy Meter

Toggle Switch
```

with active configured sensor records present in the live database. 【1-2d735d】

---

# TELEMETRY ARCHITECTURE

## High-Level Design

```text
Physical Hardware
         │
         ▼

Data Producer
(Node-RED / External Source)

         │
         ▼

Supabase Tables

         │
         ▼

SensorMonitoringService

         │
         ▼

Dashboard Widgets

         │
         ▼

Telemetry Screens
```

---

# IMPORTANT DISCOVERY

Current repository contains:

```text
NO MQTT Client

NO Node-RED Client

NO Serial Driver

NO Bluetooth Driver

NO Hardware Communication Layer
```

The application consumes telemetry already written into:

```text
Supabase
```

The actual upstream producer is outside the Flutter application. 【1-2d735d】

---

# CURRENT TELEMETRY STATUS

Configured Live Devices:

```text
DDS669_01

SW_01
```

Status:

```text
Active
```

Observed from live telemetry records. 【1-2d735d】

---

# CURRENT LIVE SENSOR INVENTORY

---

## DDS669_01

Display Name:

```text
Main Energy Meter
```

Type:

```text
energy_meter
```

Status:

```text
Active
```

Recorded Data:

```text
Energy Records Present

History Records Present
```

Database Evidence:

```text
3 Energy Records

3 History Records
```

Captured during telemetry discovery. 【1-2d735d】

---

## SW_01

Display Name:

```text
Control Toggle Switch
```

Type:

```text
toggle_switch
```

Status:

```text
Active
```

Recorded Data:

```text
Switch Events Present

History Records Present
```

Database Evidence:

```text
1 Switch Event

1 History Record
```

Observed during live telemetry discovery. 【1-2d735d】

---

# HARDWARE CLASSIFICATION

## Active Hardware

Current evidence supports:

```text
DDS669 Energy Meter

Toggle Switch
```

Both are represented by:

```text
Database Records

Dashboard Screens

Services

Tests
```

【1-2d735d】

---

# LEGACY OR FUTURE HARDWARE

## RFID

Current Status:

```text
Not Implemented
```

Database enum exists:

```text
rfid_reader
```

No active integration discovered. 【1-2d735d】【2-71689a】

---

## Barcode Scanner

Current Status:

```text
Not Implemented
```

Database enum exists:

```text
barcode_scanner
```

No active implementation discovered. 【1-2d735d】【2-71689a】

---

## PLC Counter

Current Status:

```text
Not Active
```

Enum exists:

```text
plc_counter
```

No live device discovered. 【1-2d735d】【2-71689a】

---

## IRIV

Current Status:

```text
Legacy Reference
```

Observed only in:

```text
Tests

Old References

Sample Data
```

No active telemetry path discovered. 【1-2d735d】

---

## Proximity Sensor

Current Status:

```text
Test Fixture Only
```

Not found in active sensor records. 【1-2d735d】

---

# SENSOR REGISTRY

---

## sensors

Purpose:

```text
Master Sensor Registry
```

All telemetry devices start here.

Fields:

```text
Sensor Code

Sensor Name

Sensor Type

Location

Metadata

Active State
```

Supported Types:

```text
energy_meter

toggle_switch

plc_counter

rfid_reader

barcode_scanner

generic_sensor
```

【2-71689a】

---

# SENSOR STATUS SYSTEM

---

## sensor_status

Purpose:

```text
Current Sensor State
```

Stores:

```text
Latest Value

Current Status

Last Seen
```

Status Types:

```text
online

offline

maintenance

error
```

This table powers:

```text
Realtime Dashboard Display
```

【2-71689a】

---

# TELEMETRY HISTORY SYSTEM

---

## sensor_history

Purpose:

```text
Long-Term Sensor History
```

Stores:

```text
Metric Type

Numeric Values

Text Values

Metadata

Timestamp
```

Used By:

```text
History Screen

Analytics

Reports
```

【2-71689a】

---

# ENERGY METER ARCHITECTURE

---

## energy_readings

Purpose:

```text
Raw DDS669 Measurements
```

Stores:

```text
Voltage

Current

Power

Energy

Timestamp
```

Linked To:

```text
sensors
```

through:

```text
sensor_id
```

【2-71689a】

---

# ENERGY PROCESSING PIPELINE

When a new reading arrives:

```text
Insert Energy Reading
         ↓

fn_process_energy_reading()
         ↓

Update sensor_status
         ↓

Insert sensor_history
         ↓

Dashboard Refresh
```

This process is automatic through database triggers. 【2-71689a】

---

## Metrics Produced

DDS669 generates:

```text
Voltage

Current

Power

Energy (kWh)
```

【2-71689a】

---

# TOGGLE SWITCH ARCHITECTURE

---

## switch_events

Purpose:

```text
Switch State Tracking
```

Stores:

```text
ON

OFF

Timestamp
```

【2-71689a】

---

# SWITCH PROCESSING PIPELINE

When a switch event arrives:

```text
Insert Switch Event
         ↓

fn_process_switch_event()
         ↓

Update sensor_status
         ↓

Insert sensor_history
         ↓

Dashboard Refresh
```

【2-71689a】

---

# ALERT SYSTEM

---

## sensor_alerts

Purpose:

```text
Telemetry Alert Storage
```

Tracks:

```text
Alert Type

Severity

Status

Message

Detection Time

Resolution Time
```

【2-71689a】

---

# SUPPORTED ALERT TYPES

```text
high_voltage

high_current

sensor_offline
```

【2-71689a】

---

# ALERT SEVERITIES

```text
warning

critical
```

【2-71689a】

---

# ALERT LIFECYCLE

```text
Detected
     ↓

Active
     ↓

Acknowledged
     ↓

Resolved
```

Supported statuses:

```text
active

acknowledged

resolved
```

【2-71689a】

---

# TELEMETRY SETTINGS

---

## telemetry_settings

Purpose:

```text
Global Telemetry Configuration
```

Contains:

```text
Voltage Threshold

Current Threshold

Offline Timeout

Realtime Enabled Flag
```

【2-71689a】

---

## Default Controls

```text
Voltage Warning Threshold

Current Warning Threshold

Offline Timeout Minutes

Realtime Enabled
```

【2-71689a】

---

# DASHBOARD INTEGRATION

Telemetry data appears inside:

```text
Dashboard

Telemetry Details

Telemetry Analytics

Telemetry History

Hardware Alerts

Telemetry Energy Reports
```

Discovered through screen analysis. 【3-c85a2b】【1-2d735d】

---

# PRIMARY TELEMETRY SERVICE

## SensorMonitoringService

Purpose:

```text
Telemetry Business Logic Layer
```

Responsibilities:

```text
Sensor Retrieval

Current Status Retrieval

History Retrieval

Alert Retrieval

Analytics Processing

Dashboard Formatting
```

Referenced by all telemetry screens. 【3-c85a2b】【1-2d735d】

---

# TELEMETRY SECURITY

Current telemetry tables include:

```text
sensors

sensor_status

sensor_history

energy_readings

switch_events

sensor_alerts

telemetry_settings
```

【2-71689a】

---

# Current RLS State

RLS enabled on:

```text
sensors

sensor_status

sensor_history

energy_readings

sensor_alerts

telemetry_settings
```

Live policies generally allow authenticated telemetry access and telemetry management operations. 【4-6c4abd】

---

# DATA RETENTION

Telemetry cleanup is handled through:

```text
prune_telemetry_history()
```

and

```text
cleanup_old_sensor_logs()
```

Functions.

Default behaviour removes historical telemetry beyond retention limits. 【2-71689a】

---

# EXPANSION STRATEGY

Database design already supports:

```text
RFID Reader

Barcode Scanner

PLC Counter

Generic Sensor Types
```

No schema redesign is required to introduce these device categories. 【2-71689a】

---

# KNOWN LIMITATIONS

## Limitation 1

```text
No Physical Device Validation
```

Repository evidence cannot prove real hardware installation. 【1-2d735d】【5-af5f5f】

---

## Limitation 2

```text
No Node-RED Configuration Found
```

No Node-RED flows were discovered inside the repository. 【1-2d735d】

---

## Limitation 3

```text
No MQTT Integration Found
```

MQTT client implementation was not discovered. 【1-2d735d】

---

## Limitation 4

```text
Telemetry Depends On External Producer
```

Application expects telemetry data to already exist in Supabase. 【1-2d735d】

---

# CURRENT TELEMETRY FACTS

```text
DDS669 Supported

Toggle Switch Supported

2 Active Sensor Records

Realtime Status Tracking

Historical Telemetry

Alert Management

Analytics Support

CSV Export Support

Dashboard Integration

Threshold Configuration

Retention Management
```

【1-2d735d】【2-71689a】

---

END OF DOCUMENT

INVWISE_08_HARDWARE_AND_TELEMETRY.md

Version 2.0.0
