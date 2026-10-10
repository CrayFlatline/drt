---
phase: requirements
title: Requirements & Problem Understanding
feature: project-infrastructure
date: 2026-10-10
description: Xcode/SwiftUI app shell, signing, permissions for Lab M0
---

# Requirements · feature-project-infrastructure

## Problem Statement

Немає runnable iOS-проєкту: не можна ставити на телефон, підключати Core Motion / Location, ні нарощувати lab-модулі (карта, fusion, логи).

**Хто:** розробник Lab M0 (особистий iPhone, free Apple ID).  
**Зараз:** порожній git-репо з AI DevKit docs і feature-map.

## Goals & Objectives

**Primary**

- Створити iOS App target (SwiftUI) у репозиторії.
- Збірка й Run на симуляторі та на фізичному iPhone (Personal Team / free provisioning).
- Каркас навігації екранів під наступні фічі (placeholder Home / Lab stub).
- Info.plist usage strings для Location і Motion (потрібні наступним фічам; без зайвих runtime-запитів у цій фічі, якщо сенсори ще не стартують).
- Коротка нотатка в репо: Developer Mode + Trust developer (free Apple ID, 7 днів).

**Secondary**

- Мінімальний `.gitignore` / структура каталогів під Swift/Xcode.
- Bundle ID унікальний (напр. `ua.deadrecon.taxi` або узгоджений).

**Non-goals**

- MapLibre, OSRM, EKF, логи сесій, prompts — інші фічі.
- Android, App Store, платний Developer Program.
- Повний Waze-UX, офлайн-карти.
- Background location modes (можна задекларувати пізніше в sensor-hub).

## User Stories & Use Cases

- As a developer, I want an Xcode project that builds so that I can iterate on lab features.
- As a developer, I want to Run on my iPhone with a free Apple ID so that I can test sensors later.
- As a developer, I want a simple root UI shell so that later features have a place to plug screens.

**Edge cases**

- Free provisioning expiry (7 days) — документувати re-Run з Xcode.
- Simulator vs device: shell працює на обох; сенсори — на device (наступні фічі).

## Success Criteria

- [ ] `DeadReconTaxi` (або узгоджена назва) відкривається в Xcode без помилок підпису з Personal Team.
- [ ] Run на Simulator → бачимо root SwiftUI screen.
- [ ] Run на фізичному iPhone (free Apple ID) → app launches; Trust/Developer Mode задокументовані.
- [ ] Usage descriptions для Location і Motion присутні в Info.plist / target settings.
- [ ] Немає залежностей MapLibre/OSRM у цій фічі.
- [ ] `ai-devkit lint --feature project-infrastructure` проходить.

## Constraints & Assumptions

- macOS + Xcode; iOS deployment target сучасний LTS-подібний (напр. iOS 17+), якщо не вирішено інакше при scaffold.
- Підпис: Personal Team, не Organization.
- Мова UI lab: українська або нейтральний англійський stub — **припущення:** українські рядки на root screen («DeadReconTaxi», «Lab»).
- Feature-map: [`docs/ai/feature-map.md`](../feature-map.md); design brief затверджений у чаті 2026-10-10.

## Questions & Open Items

| # | Item | Status |
|---|---|---|
| 1 | Точний Bundle ID | **Assumption:** `ua.deadrecon.taxi` — підтвердити при implementation |
| 2 | Min iOS version | **Assumption:** iOS 17.0 — підтвердити при scaffold |
| 3 | Чи створювати Swift Package модулі вже зараз | **Deferred:** плоский app target у M0; модулі з наступних фіч |

Немає блокуючих відкритих питань для старту design/plan.
