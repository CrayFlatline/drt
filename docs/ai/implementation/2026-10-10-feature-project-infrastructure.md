---
phase: implementation
title: Implementation Guide
feature: project-infrastructure
date: 2026-10-10
description: Notes from scaffold implementation
---

# Implementation · feature-project-infrastructure

## Done

- SwiftUI app shell: `DeadReconTaxiApp`, `RootView`, `HomeView`, `LabPlaceholderView`, `SigningNotesView`
- `DeadReconTaxi.xcodeproj` — bundle `ua.deadrecon.taxi`, iOS 17+, auto Info.plist keys for Location/Motion
- `Assets.xcassets` (AccentColor + empty AppIcon slot)
- `docs/dev/ios-device-setup.md`
- `.gitignore` includes `.worktrees/`

## Blocked / follow-up

- **No Xcode.app** on agent machine (`xcode-select` → Command Line Tools only). Cannot run `xcodebuild` / Simulator / device verify here.
- After installing Xcode: open project, set Personal Team, Run Simulator + device; tick testing checklist.

## How to open

```bash
open /Users/maestro/Projects/DeadReconTaxi/.worktrees/feature-project-infrastructure/DeadReconTaxi.xcodeproj
```
