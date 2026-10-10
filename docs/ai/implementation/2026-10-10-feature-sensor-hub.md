---
phase: implementation
title: Implementation Guide
feature: sensor-hub
date: 2026-10-10
description: SensorHub + SensorLabView delivery notes
---

# Implementation · feature-sensor-hub

## Shipped

- `IMUSample` / `GPSSample` (separate types)
- `MagTrust` (degree + CMMagneticFieldCalibrationAccuracy)
- `SensorHub`: device motion ~100 Hz, CLLocation, idle timer, IMU-only banner, `gpsAvailable`
- `SensorLabView` meters; Lab list entry
- `MagTrustTests`

## Lab policy note (UI)

Banner states that without GPS the session log will not be written (log-store later).

## Verify

Manual on Xcode machine (deferred). Unit tests need Xcode `test` destination.
