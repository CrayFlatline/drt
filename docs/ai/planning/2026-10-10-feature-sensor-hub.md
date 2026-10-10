---
phase: planning
title: Project Planning & Task Breakdown
feature: sensor-hub
date: 2026-10-10
description: Tasks for SensorHub + SensorLabView
---

# Planning · feature-sensor-hub

## Milestones

- [x] M1: Docs gate approved
- [x] M2: Models + MagTrust + SensorHub start/stop/streams
- [x] M3: Idle timer + location permission handling
- [x] M4: SensorLabView + Lab navigation link
- [ ] M5: Unit tests; manual checklist for other machine (sources landed; run deferred)

## Task Breakdown

### Phase 1: Core
- [x] Task 1.1: `IMUSample`, `GPSSample`
- [x] Task 1.2: `MagTrust` helper + unit tests
- [x] Task 1.3: `SensorHub` (CMMotionManager + CLLocationManager, publishers)
- [x] Task 1.4: Idle timer on start / restore on stop
- [x] Task 1.5: Location denied → IMU-only path + `gpsAuthorized` flag

### Phase 2: UI
- [x] Task 2.1: `SensorLabView` meters (Hz, last samples, banner)
- [x] Task 2.2: Lab list NavigationLink
- [x] Task 2.3: Doxygen/STE100 on public API

### Phase 3: Verify
- [x] Task 3.1: Unit test sources (run when Xcode available)
- [ ] Task 3.2: Manual on other computer (deferred)

## Dependencies

Infrastructure (merged). Map-routing not required. Log-store consumes hub later + GPS gate for writing.

## Risks

| Risk | Mitigation |
|---|---|
| Simulator weak IMU | Document device-required for rate checks |
| Free team / permissions | Existing usage strings; When-In-Use only |
| 100 Hz battery/heat | Lab-only short runs |

## Progress summary

Docs filled from approved brief (incl. no-log-without-GPS lab policy for later store). Waiting docs gate OK.
