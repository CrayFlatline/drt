---
phase: implementation
title: Implementation Notes
feature: fusion-ekf
date: 2026-10-10
description: Layered GPS-denied fusion + FusionLab dual-track
---

# Implementation · feature-fusion-ekf

## What shipped (code)

- `Features/Fusion/`: `FusionConfig`, `RouteGeometry`, protocols (`AHRSUpdating`, `INSPredicting`, `NavFiltering`), `SwiftAHRS`, `SwiftINS`, `SwiftNavFilter`, `AppSession`, `FusionSession`, `FusionLabView`
- LogStore: `appendEncodedLine`; encoder `dr_state` / `zupt` / `snap`
- MapLibre overlays: `gpsTrack` (green) / `drTrack` (orange) + `tapsEnabled`
- Map Routing writes `AppSession.lastRoute` on Build; Clear clears it
- Lab link «Fusion EKF»
- Tests: `RouteGeometryTests`, `FusionNavTests`, encoder extensions

## Design alignment

- Hard GPS-denied in NavFilter — GPS only log + overlay
- Always snap in corridor; σ grows; `snap` logged above residual threshold
- Protocols ready for later native core; Swift defaults only

## Deviations / notes

- Fixed `project.pbxproj` missing close of `PBXProject.attributes` (was breaking Xcode open)
- Simulator unit tests green (`CODE_SIGNING_ALLOWED=NO`)
- Device `/manual-testing` explicitly deferred (path C): Personal Team max devices / ineligible membership

## Open follow-ups

- Device manual checklist after paid team or free device slot
- Commit-after-review → PR → `/pr-review`
