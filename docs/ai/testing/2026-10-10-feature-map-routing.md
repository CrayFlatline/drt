---
phase: testing
title: Testing Strategy
feature: map-routing
date: 2026-10-10
description: Unit parse/polyline + manual map/OSRM checklist
---

# Testing · feature-map-routing

## Test Coverage Goals

- Unit: parse + polyline decode + error mapping (~100% of `RoutingClient` pure helpers).
- Manual: map load, taps, success route, fail path, Clear.
- No E2E automation in M0.

## Unit Tests

### Polyline / parse
- [ ] Decode known encoded polyline → expected coordinates (fixture)
- [ ] Parse sample OSRM JSON with steps → `Route` non-empty legs/steps
- [ ] Empty `routes` → `RoutingError.emptyRoutes`
- [ ] Malformed JSON → decode error

### RoutingClient (optional URLProtocol mock)
- [ ] HTTP 500 → http error
- [ ] Success body → `Route`

## Integration Tests

- [ ] N/A beyond URLSession mock (optional)

## End-to-End / Manual

- [ ] Map loads (OpenFreeMap); attribution visible
- [ ] First tap = A, second = B; third tap ignored until Clear
- [ ] Build → polyline + distance/duration for a short Kyiv route
- [ ] Airplane mode / bad URL → alert; no fake line
- [ ] Clear removes pins and polyline
- [ ] Lab entry from root navigation works

## Test Data

- Fixture: truncated OSRM JSON (2 points, 1 leg, few steps) in test bundle.
- Manual: two taps in central Kyiv.

## Manual Testing

Після impl — `/manual-testing` по одному кейсу (`+` / баг). Потрібен Xcode + Simulator або device.

## Performance

- N/A beyond normal map tile load.
