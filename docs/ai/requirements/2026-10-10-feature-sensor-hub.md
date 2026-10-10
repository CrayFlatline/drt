---
phase: requirements
title: Requirements & Problem Understanding
feature: sensor-hub
date: 2026-10-10
description: Max-rate Core Motion hub + separate GPS stream + lab meters
---

# Requirements · feature-sensor-hub

## Problem Statement

Без стабільного IMU @ high rate і окремого GPS-потоку неможливі dead reckoning і dual-track lab. Зараз є лише usage strings і shell UI.

**Хто:** розробник Lab M0 (device з Xcode на іншій машині для manual).  
**Контекст:** [`docs/ai/feature-map.md`](../feature-map.md); design brief 2026-10-10.

## Goals & Objectives

**Primary**

- `SensorHub`: CMMotionManager device motion ~100 Hz → `IMUSample`.
- Окремий `CLLocationManager` → `GPSSample` (ніколи не зліплювати з IMU без source tags).
- Mag soft-gate → `magTrusted`.
- While running: `isIdleTimerDisabled = true`; on stop restore.
- Lab UI: Start/Stop, Hz, live meters; entry from Lab list.
- Expose `gpsAvailable` / fix age for later log-store gate.

**Lab log policy (product rule for later log-store / session)**

- GPS present → road tracking + **write log** (dual-track vs GPS).
- No GPS → still track road (IMU); **do not write log** (no ground truth).

**Non-goals**

- File logging implementation (log-store).
- EKF, map overlay, background location entitlements, Android.

## User Stories

- As a developer, I want ~100 Hz IMU samples so that fusion can run like a flight-controller loop.
- As a developer, I want GPS as a separate stream so that dual-track logging stays honest.
- As a developer, I want the screen to stay on during a lab run so that foreground capture does not sleep.

## Success Criteria

- [ ] Device motion updates at approximately 100 Hz when started on a physical iPhone.
- [ ] GPS samples arrive on a separate type/stream when authorized.
- [ ] Location denied → IMU-only + visible banner; hub still runs.
- [ ] Idle timer disabled while running; restored on stop.
- [ ] `magTrusted` false when heading accuracy is poor.
- [ ] No file I/O for session logs in this feature.
- [ ] `ai-devkit lint --feature sensor-hub` passes.

## Constraints & Assumptions

- Foreground-only v1; background modes documented as follow-up.
- Usage strings already in infrastructure Info.plist.
- Manual verification on another computer with Xcode (waived on this agent host).

## Questions & Open Items

None blocking. Heading reference frame (true vs magnetic) — use Core Motion default; document in design.
