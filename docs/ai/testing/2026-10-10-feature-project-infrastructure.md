---
phase: testing
title: Testing Strategy
feature: project-infrastructure
date: 2026-10-10
description: Verify iOS shell builds and runs on simulator/device
---

# Testing · feature-project-infrastructure

## Test Coverage Goals

- Unit: мінімально (view model майже немає) — smoke compile + optional Swift Testing/XCTest placeholder.
- Integration: N/A (немає сервісів).
- E2E / manual: обовʼязково Simulator + device Launch.
- Alignment: success criteria з requirements.

## Unit Tests

### App shell
- [ ] Target compiles (`xcodebuild -scheme DeadReconTaxi -destination 'platform=iOS Simulator,name=iPhone 16' build` або актуальний симулятор)
- [ ] Якщо додано тест-таргет: app launches у unit host (опційно, не блокер)

## Integration Tests

- [ ] N/A для M0 shell — позначено свідомо

## End-to-End / Manual

- [ ] Simulator: Run → Home видно (назва DeadReconTaxi / Lab)
- [ ] Simulator: навігація на Lab placeholder і назад
- [ ] Device: Trust developer / Developer Mode за потреби → app opens
- [ ] Info.plist / settings містить `NSLocationWhenInUseUsageDescription` і `NSMotionUsageDescription` (або еквіваленти)
- [ ] Немає crash на cold start

## Test Data

- Немає fixtures.

## Test Reporting & Coverage

- Доказ: успішний `xcodebuild` + короткий manual checklist у implementation notes / PR.
- Coverage % не застосовується до чистого UI shell без логіки.

## Manual Testing

- Device matrix: один iPhone розробника (free Apple ID).
- Після expiry підпису (7 днів): re-Run з Xcode — перевірити за `docs/dev/ios-device-setup.md`.

## Performance Testing

- N/A.

## Bug Tracking

- Блокери підпису/схеми — фіксити в цій фічі до merge.
