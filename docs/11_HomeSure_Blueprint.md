# HomeSure AI Blueprint

Version: 1.0

Last Updated: August 2026

---

# Purpose

This document defines the ownership of every major package, application and module in HomeSure AI.

Before creating any new file, feature, widget or model, this blueprint should be consulted.

Our objective is simple:

> Build once.
> Reuse everywhere.

---

# HomeSure Ecosystem

HomeSure AI consists of four major projects.

```
                     HomeSure AI

                ┌───────────────────┐
                │ Shared Packages   │
                └───────────────────┘
                         ▲
                         │
        ┌────────────────┴────────────────┐
        │                                 │
        ▼                                 ▼

   homesure_ai                    homesure_web

        ▲                                 ▲
        │                                 │
        └──────── Future Backend ─────────┘
```

---

# Project Ownership

## 1. homesure_ai

Purpose

Consumer application for homeowners.

Responsibilities

- Property Dashboard
- Property Health
- Property Assessment
- SureBot
- Reports
- Property Timeline
- Onboarding
- Document Vault

This application should contain user journeys.

Business logic should be minimal.

---

## 2. homesure_web

Purpose

Web platform for administration and future SaaS.

Responsibilities

- Portfolio Dashboard
- Analytics
- Property Management
- Builder Dashboard
- Association Dashboard
- Reports
- Administration

The web application consumes shared packages.

It should not recreate UI components already available elsewhere.

---

## 3. homesure_design_system

Purpose

Single source of truth for reusable UI.

Examples

- Property Health Gauge
- Property Health Dashboard
- Dashboard Cards
- Buttons
- Chips
- Badges
- Timeline
- Recommendation Card

Rules

Every reusable widget belongs here.

Applications consume these widgets.

Applications never duplicate them.

---

## 4. homesure_models

Purpose

Single source of truth for domain models.

Examples

- Property
- PropertyHealth
- DashboardSummary
- Recommendation
- Assessment
- User
- Risk

Rules

Models should never be duplicated.

If multiple applications require the same model, it belongs here.

---

# Engineering Principles

## Rule 1

Inspect before building.

Always verify whether a feature, widget or model already exists.

---

## Rule 2

One owner.

Every component has exactly one owner.

---

## Rule 3

Build once.

Reuse everywhere.

---

## Rule 4

Shared packages first.

If multiple applications require the same functionality, it belongs in a shared package.

---

## Rule 5

No duplicate models.

Every business concept should have one canonical implementation.

---

## Rule 6

No duplicate widgets.

Reusable UI belongs inside the design system.

---

## Rule 7

Applications compose.

Packages provide.

---

# Mission Workflow

Every feature follows the same process.

Current State

↓

Reuse Existing Components

↓

Design Smallest Change

↓

Implement

↓

flutter analyze

↓

Demo

↓

Mission Complete

---

# Definition of Done

A mission is complete only when:

- flutter analyze passes
- UI is functional
- Code is reusable
- Documentation updated if required
- No duplicate implementation introduced

---

# Long-Term Vision

HomeSure AI is not a single application.

It is a Property Intelligence Platform.

Every engineering decision should move us closer to that vision.

---

# Founder Rule

Whenever a decision is unclear, ask one question:

"Are we reinventing the wheel?"

If the answer is yes,

stop,

inspect,

reuse,

then continue.