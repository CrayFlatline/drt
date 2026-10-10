---
phase: requirements
title: Requirements & Problem Understanding
feature: map-routing
date: 2026-10-10
description: MapLibre map, A/B taps, OSRM route with steps model
---

# Requirements · feature-map-routing

## Problem Statement

Після shell (`feature-project-infrastructure`) немає карти й маршруту A→B. Без полілінії та `Route` (з steps) неможливі snap, landmarks і lab-сесія.

**Хто:** розробник Lab M0.  
**Контекст:** [`docs/ai/feature-map.md`](../feature-map.md); design brief затверджений у чаті 2026-10-10.

## Goals & Objectives

**Primary**

- Показати MapLibre карту з OpenFreeMap (liberty).
- Тапами задати A і B; Clear; Build маршруту через public OSRM.
- Нормалізована модель `Route`: coordinates, distance, duration, legs/steps.
- Overlay полілінії + маркери; fit bounds; алерт при fail OSRM/мережі.

**Secondary**

- Старт камери ≈ Київ; URL OSRM/style винесені в конфіг.

**Non-goals**

- Nominatim, офлайн-тайли, self-hosted OSRM, turn-by-turn UX, EKF, dual-track, fetch світлофорів, Android.

## User Stories & Use Cases

- As a developer, I want to tap A and B on a map so that I can request a driving route in Ukraine.
- As a developer, I want a typed `Route` with steps so that later features can snap and place landmarks.
- As a developer, I want a clear error when OSRM fails so that I never trust an empty/fake route.

**Edge cases:** timeout; empty `routes`; Build без A/B (disabled); Clear mid-request (cancel or ignore stale response).

## Success Criteria

- [ ] Map loads with OpenFreeMap style (attribution visible via MapLibre).
- [ ] Tap flow A→B; Clear resets; Build only with both points.
- [ ] Successful OSRM response draws polyline and shows distance/duration.
- [ ] `Route` includes decoded coordinates and at least one leg with steps when OSRM provides them.
- [ ] Network/OSRM failure → Ukrainian alert; no fake polyline.
- [ ] No Nominatim / offline / EKF in this feature.
- [ ] `ai-devkit lint --feature map-routing` passes.

## Constraints & Assumptions

- Online lab; public `router.project-osrm.org` (rate-limit risk accepted).
- MapLibre via SPM (`maplibre-gl-native-distribution`).
- iOS 17+ app from infrastructure.
- Verify build/manual may require local Xcode (agent may lack Xcode.app).

## Questions & Open Items

Немає блокуючих. Assumption: profile `driving`; geometry polyline в OSRM response декодиться в coordinates.
