---
phase: testing
title: Testing Strategy
feature: sensor-hub
date: 2026-10-10
description: Unit mag-trust + manual device sensor lab
---

# Testing · feature-sensor-hub

## Test Coverage Goals

- Unit: `magTrusted` helper + any pure mappers.
- Manual on physical iPhone (other computer): rates, idle timer, permissions.
- Simulator: limited (no real IMU); optional compile-only.

## Unit Tests

- [ ] `magTrusted` true when accuracy in range
- [ ] `magTrusted` false when accuracy negative or above threshold
- [ ] Sample mapping from fixture numbers (if mapper extracted)

## Manual / Lab (Xcode machine)

- [ ] Start → IMU Hz approximately 100
- [ ] With Location allowed → GPS samples update; separate from IMU
- [ ] Screen does not auto-lock while running
- [ ] Stop → idle timer restored; streams stop
- [ ] Location denied → IMU runs + banner; no crash
- [ ] Lab entry from Lab list works

## Notes

- Manual gate waived on agent host; run on other Mac/iPhone.
- File log absence: confirm no new log files created by this feature alone.
