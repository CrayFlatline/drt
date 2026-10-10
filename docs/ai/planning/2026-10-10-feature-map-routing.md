---
phase: planning
title: Project Planning & Task Breakdown
feature: map-routing
date: 2026-10-10
description: Implementation tasks for MapLibre + OSRM
---

# Planning · feature-map-routing

## Milestones

- [x] M1: Docs gate approved
- [x] M2: SPM MapLibre + config + empty map screen wired from Lab
- [x] M3: Tap A/B + Clear + markers
- [x] M4: RoutingClient + Route model + overlay + alerts
- [ ] M5: Unit fixtures + manual-testing gate (unit code landed; run + manual awaits Xcode)

## Task Breakdown

### Phase 1: Map shell
- [x] Task 1.1: Add SPM `maplibre/maplibre-gl-native-distribution`
- [x] Task 1.2: `MapRoutingConfig` (OSRM URL, OpenFreeMap liberty, Kyiv center)
- [x] Task 1.3: `MapLibre` UIViewRepresentable + `MapRoutingView` skeleton
- [x] Task 1.4: Navigate from Lab / root to map screen

### Phase 2: Pins & route
- [x] Task 2.1: Tap gesture → A then B; Clear; Build disabled until both
- [x] Task 2.2: `Route` / `RouteLeg` / `RouteStep` + polyline decoder
- [x] Task 2.3: `RoutingClient` async (steps=true, overview=full)
- [x] Task 2.4: Draw polyline + fit bounds; show distance/duration
- [x] Task 2.5: Error alerts; cancel/ignore stale responses

### Phase 3: Verify
- [x] Task 3.1: Unit tests with OSRM/polyline fixtures (sources + fixture; run blocked without Xcode)
- [ ] Task 3.2: Manual-testing discovery (map, taps, success, fail, Clear)

## Dependencies

1.x → 2.x → 3.x  
Depends on merged `feature-project-infrastructure` (app shell).

## Risks & Mitigation

| Risk | Mitigation |
|---|---|
| Public OSRM rate-limit/down | Alert; config URL swappable |
| MapLibre SPM / Xcode missing on agent | Implement; verify on machine with Xcode |
| Polyline precision | Use standard precision 5 decode; fixture test |

## Progress summary

Docs filled from approved brief; waiting docs gate OK before implementation.
