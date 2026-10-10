---
phase: planning
title: Project Planning & Task Breakdown
feature: project-infrastructure
date: 2026-10-10
description: Task plan for iOS app shell scaffold
---

# Planning · feature-project-infrastructure

## Milestones

- [x] M1: Docs (requirements/design/testing + plan)
- [x] M2: Xcode/SwiftUI shell in repo (sources + `.xcodeproj`)
- [x] M3: Device setup notes + gitignore polish
- [ ] M4: Verify build (blocked until Xcode.app installed) + manual checklist

## Task Breakdown

### Phase 1: Foundation
- [x] Task 1.1: Requirements / design / testing docs (approved 2026-10-10)
- [x] Task 1.2: Fill planning; keep `.worktrees/` ignored

### Phase 2: Core scaffold
- [x] Task 2.1: Create SwiftUI app sources (`App`, `HomeView`, `LabPlaceholderView`, `SigningNotesView`)
- [x] Task 2.2: Create `DeadReconTaxi.xcodeproj` (bundle `ua.deadrecon.taxi`, iOS 17+, usage strings Location/Motion)
- [x] Task 2.3: Minimal `Assets.xcassets` (AccentColor + AppIcon placeholder)
- [x] Task 2.4: `docs/dev/ios-device-setup.md` (Developer Mode, Trust, 7-day renew)

### Phase 3: Verification
- [ ] Task 3.1: `xcodebuild` Simulator build — **blocked:** no Xcode.app (only CLT)
- [ ] Task 3.2: Manual Simulator Home + Lab navigation (when Xcode available)
- [ ] Task 3.3: Manual device Run with Personal Team (when Xcode + iPhone available)

## Dependencies

1.1 → 1.2 → 2.x → 3.x  
External: **Xcode.app** required for Task 3.1–3.3.

## Timeline & Estimates

- Scaffold (2.x): ~1–2 h  
- Verify (3.x): after Xcode install

## Risks & Mitigation

| Risk | Mitigation |
|---|---|
| No Xcode on agent machine | Commit valid project; verify locally when Xcode installed |
| pbxproj hand-written errors | Keep target minimal; open in Xcode once to refresh if needed |
| Free signing quirks | Document in ios-device-setup.md |

## Resources Needed

- Xcode from Mac App Store  
- Apple ID (free) for device  
- iPhone with Developer Mode

## Progress summary

Scaffold committed in feature worktree. Task 3.x open until Xcode.app is installed and Personal Team Run succeeds.
