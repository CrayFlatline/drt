---
phase: testing
title: Testing Strategy
feature: fusion-ekf
date: 2026-10-10
description: Unit/fixture fusion layers + manual FusionLab dual-track
---

# Testing · feature-fusion-ekf

## Unit Tests

- [x] `RouteGeometry`: cumulative `s`, ENU conversion, nearest project inside along-track window (`RouteGeometryTests`)
- [x] Corridor project: residual computed; state snapped onto polyline; `s` monotonic on forward motion fixture
- [x] Mag soft-reject: untrusted heading does not jump to mag; trusted updates heading
- [x] ZUPT detect: low |a| + |ω| for `zuptMinDurationSec` → event
- [x] One `predict` step: INS + NavFilter move state with finite σ
- [x] Encoder: `dr_state` / `zupt` / `snap` lines are valid JSON with required fields
- [x] GPS-denied invariant (logic): NavFilter has no GPS update API; `FusionSession.handleGPS` only appends overlay

## Synthetic fixtures

- [x] Straight short route + constant accel/heading synthetic IMU → `s` increases; snap residual stays within bound
- [x] Stationary IMU → ZUPT fires and `v` damped

**Execution:** `xcodebuild test` on iOS Simulator (`CODE_SIGNING_ALLOWED=NO`) — all suites green 2026-10-10, including `RouteGeometryTests` / `FusionNavTests` / encoder extensions. Device install still blocked by Personal Team provisioning.

## Manual (Xcode machine) — `/manual-testing`

**Status: deferred (explicit path C, 2026-10-10)** — free Personal Team cannot install on device (max registered iPhones / ineligible membership). Manual gate waived for merge of this PR; run suite below after paid team or free slot.

- [ ] Map Routing Build → `AppSession` has route; FusionLab Start enabled
- [ ] No route → Start blocked + banner
- [ ] Start with GPS: JSONL grows with `imu`/`gps`/`dr_state`; optional `zupt`/`snap`
- [ ] Overlay shows route + distinct `gps_track` and `dr_track` (different colors)
- [ ] Stop → clean end; hub can remain running policy as implemented
- [ ] GPS loss mid-run: LogStore `gps_lost` behavior unchanged; no crash in FusionSession teardown

## Notes

- Unit/fixture target: `CODE_SIGNING_ALLOWED=NO` build-for-testing OK without device.
- Device manual remains required for Lab M0 confidence; tracked as follow-up, not a merge blocker for path C.
