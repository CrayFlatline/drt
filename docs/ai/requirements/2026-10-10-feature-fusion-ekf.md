---
phase: requirements
title: Requirements & Problem Understanding
feature: fusion-ekf
date: 2026-10-10
description: Route-constrained fusion (AHRS/INS/Nav) with GPS-denied EKF and dual-track lab
---

# Requirements · feature-fusion-ekf

## Problem Statement

Lab M0 needs an on-device **route-constrained dead-reckoning filter** so that when GPS is withheld from the estimator, position still tracks the planned OSRM route using max-rate IMU. Without a live fusion path that logs `dr_*` separately from GPS, dual-track evaluation and later replay/metrics cannot start.

**Depends on:** `feature-map-routing`, `feature-log-store` (both merged).  
**Brief:** approved in chat 2026-10-10 (`/bake-feature`).

## Goals & Objectives

**Primary**

- Swift fusion stack with layered modules and public protocols ready for a later native core:
  - `AHRS` — attitude / heading + mag soft-reject
  - `INS` — accel integration → planar velocity / pose
  - `NavFilter` — route project/snap, ZUPT, covariance growth
- **Hard GPS-denied in the filter:** GPS samples never enter `update_*` for position; GPS remains only in the session log.
- State is **2D** with a **hard project** onto the route polyline after each step (corridor snap).
- Init at route point A; heading from Core Motion when `magTrusted`, else first polyline segment direction; large initial σ along route progress.
- Full ZUPT (tuned thresholds) + log `zupt` events; mag soft-reject on heading path.
- Off-route: always snap within forward/back corridor; grow σ; log `snap` residual; **do not** stop the session.
- Extend LogStore / encoder with JSONL types `dr_state`, `zupt`, `snap` (plus existing `meta` / `route` / `imu` / `gps` / `end`).
- `predict` on every IMU sample; throttle `dr_state` log + map overlay to ~5–10 Hz.
- Lab UX: `FusionLab` screen; `AppSession` holds last `Route` from Map Routing; Start blocked with banner if no route.
- Overlay: route + `gps_track` + `dr_track` (never a single mixed track).

**Non-goals**

- Landmarks / traffic lights (`feature-landmarks-osm`)
- User prompts (`feature-prompt-policy`)
- Soft GPS updates inside the EKF (optional later)
- Full `feature-lab-session-ui` product shell
- C++/Rust FFI implementation in this feature (protocols only)
- Offline maps / Android

## User Stories & Use Cases

- As a lab driver, I build A→B in Map Routing, open Fusion Lab, Start, and see GPS and DR tracks diverge under GPS-denied filtering while both write to one JSONL.
- As a researcher, I export the session and see interleaved `imu` / `gps` / `dr_state` / `zupt` / `snap` for offline analysis.
- As a developer, I unit-test AHRS/INS/NavFilter via protocols with synthetic fixtures without a device.

**Edge cases**

- No route in `AppSession` → Start disabled + clear banner.
- Mag untrusted → heading falls back to segment tangent / last trusted policy (documented in design).
- Large snap residual → session continues; σ increases; `snap` logged.
- GPS lost mid-session → LogStore end rules apply for recording; NavFilter already ignores GPS.

## Success Criteria

- [ ] Public protocols exist for AHRS / INS / NavFilter with Swift default implementations; `FusionSession` depends on protocols.
- [ ] With a valid route, Start runs live predict@IMU; UI/log emit throttled `dr_state`; GPS lines appear in log but never feed NavFilter position updates.
- [ ] ZUPT fires under low motion and writes `zupt`; snap residual events write `snap`.
- [ ] FusionLab shows route + distinct `gps_track` and `dr_track`.
- [ ] Unit tests cover project/snap corridor, ZUPT detect, one predict step, new encoder types; ≥1 synthetic fixture (monotonic `s` / residual bounds on a straight route).
- [ ] `ai-devkit lint --feature fusion-ekf` passes for filled phase docs used in this cycle.

## Constraints & Assumptions

- Pure iOS Swift/SwiftUI; MapLibre already in app for map views.
- Route geometry comes from existing `Route` model (OSRM polyline).
- LogStore GPS gate at session start remains as today; fusion does not relax that for v1 unless design explicitly says otherwise.
- Manual on-device verify may be deferred on agent hosts without Xcode (same pattern as prior Lab features).
- Tunable ZUPT / snap / throttle constants live in one config type (exact numbers in design).

## Questions & Open Items

- None material for requirements — locked in design brief 2026-10-10. Residual numeric tunings (ZUPT thresholds, corridor half-width, throttle Hz) → design doc defaults, adjustable in lab later.
