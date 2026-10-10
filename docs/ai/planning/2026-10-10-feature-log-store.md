---
phase: planning
title: Project Planning & Task Breakdown
feature: log-store
date: 2026-10-10
description: Tasks for GPS-gated JSONL LogStore
---

# Planning · feature-log-store

## Milestones

- [ ] M1: Docs gate approved
- [ ] M2: Encoder + LogStore start/stop/gps_lost
- [ ] M3: LogLabView list + share
- [ ] M4: Lab link + unit tests

## Task Breakdown

### Phase 1: Core
- [ ] Task 1.1: `LogEventEncoder` + unit tests
- [ ] Task 1.2: `LogStore` directory + JSONL writer
- [ ] Task 1.3: Subscribe to SensorHub; gpsAvailable gate
- [ ] Task 1.4: Mid-run GPS loss → end + stop

### Phase 2: UI
- [ ] Task 2.1: `LogLabView` Start/Stop/status/banner
- [ ] Task 2.2: Session list + Share
- [ ] Task 2.3: Lab NavigationLink
- [ ] Task 2.4: Doxygen/STE100

### Phase 3: Verify
- [ ] Task 3.1: Unit tests (when Xcode)
- [ ] Task 3.2: Manual on other computer (deferred)

## Dependencies

`feature-sensor-hub` on master. Route snapshot optional (nil OK).

## Progress summary

Implementation done in worktree. Manual verify deferred. Awaiting commit-after-review OK.
