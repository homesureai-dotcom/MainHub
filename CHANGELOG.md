# HomeSure AI - Changelog

All notable changes to the HomeSure AI platform will be documented in this file.

This project follows a sprint-based development model.

---

# Sprint 1 - Project Foundation

## Added

- Flutter project initialized
- Project architecture established
- Design system created
- Home dashboard
- Onboarding flow

---

# Sprint 2 - Property Assessment

## Added

- Property Assessment flow
- Property Health Standard (PHS)
- Assessment questions
- Assessment state management
- Question navigation

---

# Sprint 3 - Dashboard & Reports

## Added

- Property dashboard
- Score cards
- Property timeline
- Risk Center
- Report framework

---

# Sprint 4 - Property Health Engine

## Added

- Property Health models
- Score calculator
- Risk engine
- Recommendation engine
- Property Health Engine

---

# Sprint 5 - Rule Engine

## Added

- Question rules
- Rule registry
- Question evaluation
- Generic rule architecture

## Changed

- Migrated from hardcoded logic to rule-based evaluation

---

# Sprint 6 - Property Intelligence Engine

## Added

### Engine

- Property Intelligence Engine
- Generic Rule Evaluator
- Rule Registry
- Engine Playground

### Configuration

- AnswerConfig
- RiskConfig
- RecommendationConfig
- QuestionRuleConfig

### Rules

- LEGAL_OC configuration
- Generic rule execution

### Models

- PropertyHealthResult
- QuestionEvaluation

## Changed

- Migrated from rule classes toward configuration-driven intelligence.
- Engine architecture separated from business rules.
- Introduced engine facade (`PropertyIntelligenceEngine`).

## Technical Improvements

- Added developer playground for testing engine rules.
- Introduced configuration-first architecture.

---

# Upcoming - Sprint 7

## Planned

- Evaluate complete assessment
- Dynamic Property Health Result
- Dashboard integration
- Dynamic Risk Center
- Recommendation Center
- Assessment → Engine integration
- Score Reveal