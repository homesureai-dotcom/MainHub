# HomeSure AI MVP Product Requirements Document (PRD)

**Version:** 1.0  
**Status:** Draft  
**Owner:** Product Team  
**Target Release:** MVP v1.0

---

# 1. Objective

The objective of HomeSure AI MVP is to enable apartment buyers and homeowners to assess the health of a residential property using the HomeSure Property Health Standard (PHS).

The MVP must provide an explainable Property Health Score, actionable recommendations, and a downloadable Property Health Certificate.

The MVP is considered successful when users can confidently answer:

> **"Should I buy this property?"**

or

> **"What should I improve in my property?"**

---

# 2. Problem Statement

Buying a property is one of the largest financial decisions in a person's life.

Today there is no trusted, standardized, and explainable way to evaluate the overall health of a residential property.

Users rely on:

- Builder claims
- Broker opinions
- WhatsApp groups
- Friends and family
- Personal assumptions

HomeSure AI solves this problem by introducing a structured Property Health Assessment.

---

# 3. Target Users

## Primary Users

- Apartment Buyers
- Apartment Owners

---

## Secondary Users

- Apartment Associations
- Builders

Future versions will support:

- Banks
- Insurance Companies

---

# 4. User Journey

```
Launch App
      │
      ▼
Select Property
      │
      ▼
View Dashboard
      │
      ▼
Start Assessment
      │
      ▼
Answer Questions
      │
      ▼
Property Health Score
      │
      ▼
Recommendations
      │
      ▼
Download Certificate
```

---

# 5. Functional Requirements

## Property Module

The user shall be able to:

- Add a property
- Select a property
- View property details

---

## Assessment Module

The user shall be able to:

- Start an assessment
- Resume an assessment
- View progress
- Complete an assessment

---

## Assessment Engine

The system shall:

- Calculate category scores
- Apply category weights
- Generate Property Health Score
- Assign Property Health Grade

---

## Dashboard

The user shall see:

- Property Health Score
- Category Scores
- Recommendations
- Recent Assessments

---

## Recommendations

The system shall:

- Explain missing items
- Prioritize improvements
- Estimate score improvements

---

## Property Health Certificate

The system shall generate:

- Property Summary
- HomeSure Score
- Category Breakdown
- Recommendations
- Assessment Date
- PHS Version

---

## SureBot AI

The AI assistant shall:

- Explain assessment results
- Explain recommendations
- Answer assessment-related questions
- Guide users through the assessment

---

# 6. Non-Functional Requirements

The MVP shall be:

- Fast
- Explainable
- Reliable
- Offline-friendly where possible
- Easy to use
- Responsive

---

# 7. Out of Scope

The following are not part of MVP:

- OCR
- Government Verification
- Builder Portal
- Association Dashboard
- PCI
- Bank APIs
- Insurance APIs
- Commercial Properties

---

# 8. Success Metrics

The MVP is successful if:

- Users complete assessments
- Users understand their score
- Users act on recommendations
- Users download certificates
- Users return to reassess properties

---

# 9. Risks

Potential risks include:

- Users abandoning assessments
- Incorrect or incomplete answers
- Lack of supporting evidence
- Complex scoring logic
- Low trust in recommendations

Mitigation:

- Explainable scoring
- Guided assessment
- Simple language
- Future evidence verification

---

# 10. MVP Definition of Done

The MVP is complete when:

✅ Property Selection works

✅ Assessment works

✅ HomeSure Score is calculated

✅ Dashboard updates dynamically

✅ Recommendations are generated

✅ Property Health Certificate can be downloaded

✅ SureBot explains results

No critical bugs remain.

---

# 11. Future Enhancements

Version 1.5

- Document Vault
- OCR
- Property Confidence Index

Version 2.0

- AI Property Advisor
- Property Timeline
- Risk Prediction

Version 3.0

- Builder Portal
- Association Dashboard
- Bank Integration

---

# 12. Launch Checklist

Before release, verify:

- All PHS categories implemented
- Scoring engine validated
- Dashboard tested
- Certificate generated correctly
- AI recommendations reviewed
- Documentation completed
- User acceptance testing completed

---

# Version History

| Version | Date | Description |
|----------|------|-------------|
| 1.0 | August 2026 | Initial MVP PRD |