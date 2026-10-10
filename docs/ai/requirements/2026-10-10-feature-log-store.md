---
phase: requirements
title: Requirements & Problem Understanding
feature: log-store
date: 2026-10-10
description: Dual-track JSONL session logs gated on GPS
---

# Requirements · feature-log-store

## Problem Statement

Research lab needs on-device dual-track logs (IMU + GPS) for offline evaluation. Without a GPS-gated writer, sessions are useless for position metrics or get corrupted when GPS drops.

**Depends on:** `feature-sensor-hub` (merged).  
**Brief:** approved in chat 2026-10-10.

## Goals & Objectives

**Primary**

- Write session logs as JSON Lines under Documents/`Logs/`.
- Start recording only when `SensorHub.gpsAvailable`.
- On GPS loss mid-run: stop recording, write `end.reason=gps_lost`, show banner.
- Lab UI: Start/Stop, status, file list, Share sheet.
- Subscribe to SensorHub IMU/GPS streams; Stop log does not stop hub.

**Non-goals**

- SQLite, iCloud, IMU-only debug dump, DR/EKF lines in file, background recording.

## Success Criteria

- [ ] No file created when GPS is unavailable at start.
- [ ] Recording writes interleaved `imu` and `gps` JSONL lines while GPS is fresh.
- [ ] GPS age beyond threshold stops recording with `gps_lost`.
- [ ] User can list and share `.jsonl` files from Lab.
- [ ] `ai-devkit lint --feature log-store` passes.

## Constraints & Assumptions

- GPS freshness threshold: 5 seconds (align with SensorHub `gpsAvailable`).
- Optional `route` snapshot if a route is supplied at start (may be nil in v1 UI).
- Manual verify on Xcode machine (deferred on agent host).
