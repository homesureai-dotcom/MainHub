# HomeSure K-RERA — Phase 3D Catalogue Reconciliation Report

- **Generated At (UTC):** `2026-11-09T09:03:17.930400+00:00`
- **Source Catalogue:** `data/k_rera_extraction.sqlite` (`4,459` records across `446` pages)

## 1. Explicit Catalogue Classification Breakdown

| Classification State | Count | Notes |
|---|---:|---|
| `eligible_unprocessed` | `3,719` | Complete identity, `APPROVED` status, valid `vpd_id`, unprocessed in Phases 3A/3B/3C |
| `already_processed` | `375` | `25` Phase 3A + `100` Phase 3B + `250` Phase 3C (`375` total) |
| `non_approved` | `365` | `265` REJECTED + `63` WITHDRAWN + `31` TRANSFERED + `6` REVOKED |
| `identity_incomplete` | `0` | `0` among `APPROVED` rows |
| `detail_link_unavailable` | `0` | `0` among `APPROVED` rows (`27` non-APPROVED rows lack detail links) |
| `duplicate_catalogue_record` | `0` | `0` duplicate `registration_number` or `vpd_id` among `APPROVED` rows |
| `status_changed` | `0` | `0` status changes observed |
| `manual_review_required` | `0` | `0` unresolved `APPROVED` rows (`365` non-APPROVED rows logged in exclusion report) |
| **Total** | **`4,459`** | **100% of catalogue rows accounted for** |

## 2. Remaining Eligible Inventory by Page Band & Project Type (`3,719` Projects)

| Page Band & Project Type | Remaining Eligible Count |
|---|---:|
| `Early (Pages 1-100) | Mixed Development` | `18` |
| `Early (Pages 1-100) | Plotted Development` | `35` |
| `Early (Pages 1-100) | Residential/Group Housing` | `739` |
| `Late (Pages 301-446) | Mixed Development` | `8` |
| `Late (Pages 301-446) | Plotted Development` | `340` |
| `Late (Pages 301-446) | Residential/Group Housing` | `953` |
| `Middle (Pages 101-300) | Commercial` | `24` |
| `Middle (Pages 101-300) | Mixed Development` | `41` |
| `Middle (Pages 101-300) | Plotted Development` | `276` |
| `Middle (Pages 101-300) | Residential/Group Housing` | `1,285` |
