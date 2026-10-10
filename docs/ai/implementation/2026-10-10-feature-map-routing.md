---
phase: implementation
title: Implementation Guide
feature: map-routing
date: 2026-10-10
description: What shipped for MapLibre + OSRM routing
---

# Implementation · feature-map-routing

## Shipped

- `MapRoutingConfig` — OpenFreeMap liberty style, public OSRM, Kyiv center
- `PolylineDecoder`, `OSRMResponseParser`, `RoutingClient`, `Route`/`RouteLeg`/`RouteStep`
- `MapLibreMapView` (UIViewRepresentable) + `MapRoutingView` (taps A/B, Clear, Build, alerts)
- Lab → NavigationLink to map screen
- SPM: `maplibre/maplibre-gl-native-distribution` (MapLibre product)
- Unit tests + `Fixtures/osrm_kyiv_sample.json`

## Verify (local Xcode required)

```bash
open DeadReconTaxi.xcodeproj
# Signing: Personal Team
xcodebuild -scheme DeadReconTaxi -destination 'platform=iOS Simulator,name=iPhone 16' test
```

Agent machine still has only Command Line Tools — no `xcodebuild` evidence here.

## Notes

- Third tap ignored until Clear (per brief).
- Stale route responses ignored via `requestGeneration`.
- Deployment/monitoring docs remain templates.
