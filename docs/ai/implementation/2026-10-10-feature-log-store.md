---
phase: implementation
title: Implementation Guide
feature: log-store
date: 2026-10-10
description: GPS-gated JSONL LogStore implementation notes
---

# Implementation · feature-log-store

## Code Structure

- `Features/LogStore/LogEventEncoder.swift` — pure JSONL builders
- `Features/LogStore/LogSessionPolicy.swift` — start / GPS-loss gates
- `Features/LogStore/LogStore.swift` — file IO + hub subscriptions
- `Features/LogStore/LogLabView.swift` — Start/Stop, list, ShareLink
- Lab link in `LabPlaceholderView`

## Notes

- Writer queue for append; sync write for `end` before close.
- Stop log does not stop `SensorHub`.
- Manual lab verify deferred (no Xcode on agent host).
