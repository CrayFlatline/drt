---
phase: planning
title: Project Planning & Task Breakdown
feature: fusion-ekf
date: 2026-10-10
description: Tasks for GPS-denied layered fusion + FusionLab
---

# Planning · feature-fusion-ekf

## Milestones

- [x] M0: Docs gate approved (requirements / design / testing / planning)
- [x] M1: Geometry + protocols + SwiftAHRS/INS/NavFilter + unit/fixtures
- [x] M2: LogStore encoder extensions (`dr_state` / `zupt` / `snap`)
- [x] M3: `AppSession` + MapRouting handoff + `FusionSession` wiring
- [x] M4: `FusionLabView` dual-track overlay + Lab link
- [ ] M5: Manual lab (`/manual-testing`) → commit review → PR → `/pr-review`

## Task Breakdown

### Phase 0: Docs
- [x] Task 0.1: User OK on filled requirements/design/testing/planning

### Phase 1: Core math (TDD-friendly)
- [x] Task 1.1: `FusionConfig` defaults
- [x] Task 1.2: `RouteGeometry` (ENU, cumulative `s`, windowed project) + unit tests
- [x] Task 1.3: Protocols `AHRSUpdating` / `INSPredicting` / `NavFiltering`
- [x] Task 1.4: `SwiftAHRS` (gyro integrate + mag soft-reject) + tests
- [x] Task 1.5: `SwiftINS` planar predict + tests
- [x] Task 1.6: `SwiftNavFilter` project/snap/σ + ZUPT + tests
- [x] Task 1.7: Synthetic straight-route fixture (monotonic `s`, residual bound)

### Phase 2: Logging
- [x] Task 2.1: `LogEventEncoder` lines for `dr_state` / `zupt` / `snap` + tests
- [x] Task 2.2: `LogStore` append API for fusion lines while recording

### Phase 3: Session orchestration
- [x] Task 3.1: `AppSession` + inject into app; MapRouting sets `lastRoute` on Build
- [x] Task 3.2: `FusionSession` start/stop: hub + log + predict@IMU + 10 Hz throttle
- [x] Task 3.3: Publish `gpsTrack` / `drTrack` / banners; GPS never into NavFilter

### Phase 4: UI
- [x] Task 4.1: `FusionLabView` Start/Stop, status, MapLibre overlays
- [x] Task 4.2: Lab list link + footnote update
- [x] Task 4.3: Doxygen / ASD-STE100 on new public API

### Phase 5: Verify / ship
- [x] Task 5.1: Unit tests on Simulator (`CODE_SIGNING_ALLOWED=NO`) — green 2026-10-10
- [ ] Task 5.2: `/manual-testing` FusionLab — **deferred path C** (Personal Team device limit)
- [ ] Task 5.3: Commit-after-review → PR → `/pr-review` until merge verdict

## Dependencies

- Merged: `feature-map-routing`, `feature-log-store`, `feature-sensor-hub`
- Non-goals this branch: landmarks, prompts, GPS-in-EKF, FFI bodies

## Risks

| Risk | Mitigation |
|---|---|
| IMU integration drift on curves | Corridor snap + σ growth; prompts later |
| LogStore GPS gate blocks Start without GPS | Keep gate; lab needs GPS for dual-track file |
| Protocol over-abstraction | Keep three protocols thin; one Swift impl each |
| Agent cannot xcodebuild | Manual verify on other Mac |

## Progress summary

Implementation complete. Simulator unit tests green. Manual device lab deferred (path C — provisioning). Next: commit-after-review → PR.
