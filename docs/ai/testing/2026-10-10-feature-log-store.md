---
phase: testing
title: Testing Strategy
feature: log-store
date: 2026-10-10
description: Unit encode/gate + manual log lab
---

# Testing · feature-log-store

## Unit Tests

- [ ] Encode `meta` / `imu` / `gps` / `end` lines as valid JSON
- [ ] Start refused when gpsAvailable is false (mock hub flag)
- [ ] GPS lost path writes `end.reason=gps_lost` (logic test with fake age)

## Manual (Xcode machine)

- [ ] With GPS: Start → file appears and grows; Stop → `user_stop`
- [ ] Simulate GPS loss / airplane after start → recording stops, banner, `gps_lost`
- [ ] Start without GPS → blocked, no file
- [ ] Share sheet opens for a listed file
- [ ] Stop log leaves SensorHub running if it was already up

## Notes

Manual deferred on agent host.
