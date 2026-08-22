# HomeSure AI Product Architecture

**Version:** 1.0  
**Status:** Draft  
**Last Updated:** August 2026

---

# Purpose

This document defines the product architecture of HomeSure AI.

Rather than viewing HomeSure AI as a collection of screens or features, the platform is organized into a suite of integrated products that work together to deliver a complete Property Intelligence experience.

Each product has a clearly defined purpose, ownership, and set of capabilities while sharing a common technology platform.

---

# Product Vision

HomeSure AI is a Property Intelligence Platform.

The platform consists of multiple products that work together to help homeowners understand, improve, protect, and manage their properties throughout their lifecycle.

Every product contributes to one or more of the following goals:

- Improve Property Health™
- Reduce Property Risk
- Increase Property Value
- Simplify Property Ownership
- Enable Better Decision Making

---

# Product Suite

The HomeSure platform consists of the following products.

## 1. Property Health™

Purpose

Measure the overall health of a residential property.

Primary Capabilities

- Property Health Index™ (PHI™)
- Health Dashboard
- Category Scores
- Confidence Score
- Trends
- AI Recommendations

Primary User

Homeowners

---

## 2. Property Assessment™

Purpose

Collect evidence required to calculate the Property Health Index™.

Primary Capabilities

- Guided Assessment
- Dynamic Questions
- Evidence Collection
- Photo Uploads
- Document Verification
- Progress Tracking

Primary User

Homeowners

---

## 3. Property Vault™

Purpose

Organize and understand every document related to a property.

Primary Capabilities

- Secure Document Storage
- AI Document Understanding
- Expiry Tracking
- Search
- Categorization

Primary User

Homeowners

---

## 4. SureBot™

Purpose

Provide AI-powered guidance throughout the property lifecycle.

Primary Capabilities

- Property Q&A
- Recommendation Engine
- PHI Explanation
- Document Explanation
- Next Best Actions

Primary User

All Users

---

## 5. Portfolio™

Purpose

Manage multiple properties from a single dashboard.

Primary Capabilities

- Portfolio Dashboard
- Portfolio PHI
- Portfolio Trends
- Portfolio Analytics

Primary User

Property Investors

---

## 6. Reports™

Purpose

Generate professional reports that summarize property health and readiness.

Primary Capabilities

- PDF Reports
- Health Certificates
- Builder Reports
- Bank Reports

Primary User

Homeowners and Professionals

---

## 7. Builder Intelligence™

Purpose

Provide transparency into builder performance and project quality.

Primary Capabilities

- Builder Profile
- Project History
- Compliance Score
- Reputation Index

Primary User

Property Buyers

---

## 8. Property Value™

Purpose

Help users understand and improve the market value of their property.

Primary Capabilities

- Estimated Property Value
- Value Drivers
- Improvement Suggestions
- Market Comparison

Primary User

Homeowners

---

# Shared Platform Services

Every product uses the same shared platform.

Shared Services include:

- Authentication
- User Profiles
- Property Profiles
- AI Engine
- Notification Engine
- Reporting Engine
- File Storage
- Analytics
- Audit Logs

---

# Shared Packages

All applications consume shared packages.

- homesure_design_system
- homesure_models
- homesure_api (future)
- homesure_utils (future)

---

# Product Relationships

```
                    HomeSure Platform

                         │

        ┌────────────────┼────────────────┐

        ▼                ▼                ▼

 Property Health™   Property Vault™   SureBot™

        │                │                │

        └────────────┬───┘

                     ▼

           Property Assessment™

                     │

                     ▼

                PHI™ Engine

                     │

        ┌────────────┼────────────┐

        ▼                         ▼

Portfolio™               Property Value™

                     │

                     ▼

                 Reports™
```

---

# User Journey

The recommended user journey is:

1. Register
2. Add Property
3. Complete Assessment
4. Upload Documents
5. Generate PHI™
6. Review AI Recommendations
7. Improve Property Health
8. Track Progress
9. Generate Reports

---

# Guiding Principles

Every product within HomeSure AI should:

- Solve a real homeowner problem
- Integrate with PHI™
- Be explainable
- Share common models
- Share common design language
- Share common AI capabilities

---

# Roadmap

Current Priority

✅ Property Health™

Next

- Property Assessment™
- Property Vault™
- SureBot™

Future

- Portfolio™
- Builder Intelligence™
- Property Value™
- Reports™

---

# Success Criteria

The HomeSure platform succeeds when users can:

- Understand their property's health
- Identify and reduce risks
- Improve compliance
- Increase long-term value
- Manage all property information in one trusted platform