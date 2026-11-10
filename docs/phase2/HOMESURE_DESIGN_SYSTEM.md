# HomeSure — Design System Specification (`v2.0`)

**Document Version:** 2.0  
**Phase:** Phase 2 — Complete Application UI/UX Redesign & Design System Implementation  
**Design Philosophy:** Serious, calm, structured, evidence-first property intelligence (fintech / regulatory dossier aesthetic).

---

## 1. Brand Positioning & Visual Principles

- **Core Positioning**: *"Know the project you have chosen. Understand what is behind it."*
- **Visual Character**: Trustworthy, institutional, high-density, and transparent about regulatory evidence states.
- **No Speculative Chrome**: Zero fake stock photography, zero decorative marketing carousels, and zero fabricated compliance scores.

---

## 2. Color Token System (`HomeSureColors` / `AppColors`)

### 2.1 Core Brand & Surface Tokens

| Token Name | Hex Value | Role & Usage |
| :--- | :--- | :--- |
| `primaryNavy` / `primary` | `#172B4D` | Primary brand actions, active navigation indicators, executive headers, primary CTAs. |
| `primaryDarkNavy` | `#10213A` | Deep navy anchor for hero intelligence surfaces and high-contrast containers. |
| `accentTeal` / `accent` | `#168C83` | Secondary brand accent, verified intelligence highlights, interactive focus states, progress bars. |
| `accentTealTint` | `#E6F4F2` | Subtle surface tint for teal badges, active filter pills, and regulatory intelligence callouts. |
| `backgroundWarm` / `background` | `#F7F8FA` | Primary application scaffold background (warm off-white). |
| `surfaceWhite` / `surface` | `#FFFFFF` | Elevated cards, sheets, dialogs, and navigation bar surface. |
| `surfaceSubtle` | `#F1F4F9` | Secondary container fill for metadata cells, chips, and subtle groupings. |
| `textPrimary` | `#17212F` | High-contrast ink for project titles, metrics, and primary body copy. |
| `textSecondary` | `#687386` | Muted slate for subtitles, field labels, and supporting metadata. |
| `textMuted` | `#8C96A6` | Caption text, timestamps, and non-emphasized hints. |
| `borderDivider` / `border` | `#E7EAF0` | Hairline `1px` card borders, table dividers, and section separators. |

### 2.2 Semantic Status Tokens

| Status Category | Foreground / Text | Background Tint | Border Token | Usage |
| :--- | :--- | :--- | :--- | :--- |
| **Positive / Verified** | `#16794B` | `#EAF6F0` | `#BFE5D1` | K-RERA `APPROVED`, verified documents, `present_with_data` state. |
| **Warning / Attention** | `#B86E00` | `#FFF6E5` | `#F5D9A6` | Pending assessments, `present_empty` portal tabs, moderate risk items. |
| **Critical / Risk** | `#C43B3B` | `#FDF0F0` | `#F3C2C2` | Regulatory complaints, critical priority actions, `extraction_failed`, revoked/expired status. |
| **Neutral / Info** | `#42526E` | `#F1F4F9` | `#D8E0EC` | `not_present`, `not_applicable`, `not_available`, general metadata pills. |
| **Disabled** | `#9AA4B2` | `#EEF1F6` | `#E2E7F0` | Inactive controls and unassessed placeholder states. |

### 2.3 Six-State `ObservationState` Visual Mapping

Every K-RERA field and tab observation uses an explicit semantic visual treatment via `ObservationStateStyle`:

| `ObservationState` Enum | Badge Label | Foreground | Background | Icon |
| :--- | :--- | :--- | :--- | :--- |
| `presentWithData` | `Available in K-RERA` | `#16794B` | `#EAF6F0` | `Icons.verified_outlined` |
| `presentEmpty` | `Published Empty in K-RERA` | `#B86E00` | `#FFF6E5` | `Icons.info_outline_rounded` |
| `notPresent` | `Not Shown on K-RERA` | `#5E6C84` | `#F1F4F9` | `Icons.remove_circle_outline` |
| `notApplicable` | `Not Applicable` | `#687386` | `#F4F5F7` | `Icons.block_flipped` |
| `notAvailable` | `Not Available` | `#687386` | `#F1F4F9` | `Icons.help_outline_rounded` |
| `extractionFailed` | `Verification Needed` | `#C43B3B` | `#FDF0F0` | `Icons.warning_amber_rounded` |

---

## 3. Typography System (`HomeSureTypography` / `AppTextStyles`)

Designed around crisp, high-legibility geometric sans-serif proportions (`Inter` / `Manrope` metrics with system fallback):

| Token | Size | Weight | Line Height | Letter Spacing | Usage |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `screenTitle` (`h1`) | `24sp` | `700` (Bold) | `1.25` | `-0.4` | Primary screen headers (`Find Your Property`, Dashboard title). |
| `sectionTitle` (`h2`) | `18sp` | `700` (Bold) | `1.30` | `-0.2` | Card headers, intelligence section headers. |
| `cardTitle` (`h3`) | `16sp` | `600` (SemiBold) | `1.35` | `-0.1` | Builder names, project titles, priority titles. |
| `bodyPrimary` (`body`) | `14sp` | `400` / `500` | `1.45` | `0.0` | Primary readable content and metric values. |
| `bodySecondary` (`bodySmall`) | `13sp` | `400` | `1.40` | `0.0` | Supporting descriptions, locality strings, field labels. |
| `caption` | `11.5sp` | `500` | `1.35` | `0.2` | RERA numbers, ACK numbers, provenance footnotes. |
| `badge` (`label`) | `11sp` | `600` (SemiBold) | `1.20` | `0.3` | Status pills, project count badges, observation chips. |

---

## 4. Spacing, Radius & Elevation Scale

- **Spacing Scale (`HomeSureSpacing` / `AppSpacing`)**:
  - `xxs`: `4px`, `xs`: `8px`, `sm`: `12px`, `md`: `16px`, `lg`: `20px`, `xl`: `24px`, `xxl`: `32px`
- **Corner Radius Scale (`HomeSureRadius` / `AppRadius`)**:
  - `xs`: `6px` (inline tags)
  - `sm`: `8px` (compact chips, inventory badges)
  - `md`: `12px` (inputs, buttons, inner panels)
  - `lg`: `16px` (standard intelligence cards, builder cards, property cards)
  - `xl`: `20px` (executive hero cards, modal sheets)
  - `pill`: `999px` (filter pills, count badges)
- **Elevation & Borders (`HomeSureShadows` / `AppShadows`)**:
  - Cards use a crisp `1px` border (`#E7EAF0`) on `#FFFFFF` surfaces with ultra-subtle ambient shadow (`color: Color(0x0710213A), blurRadius: 10, offset: Offset(0, 3)`), avoiding heavy drop shadows.

---

## 5. Reusable Design System Components (`lib/core/theme/homesure_components.dart`)

1. **`HomeSureSectionHeader`**: Standardized section header with title, optional subtitle, and trailing count badge or action link.
2. **`HomeSureStatusBadge`**: Semantic pill badge supporting `HomeSureBadgeTone` (`navy`, `teal`, `positive`, `warning`, `critical`, `neutral`) and optional leading icon.
3. **`HomeSureObservationBadge`**: Renders any `ObservationState` with its canonical label, icon, and semantic color tokens.
4. **`HomeSureMetricTile`**: Compact intelligence cell displaying a metric label, prominent value, and optional status/subtext for overview grids.
5. **`HomeSureInfoRow`**: Structured key-value disclosure row for K-RERA project metrics with built-in `ObservationState` badge rendering.
6. **`HomeSureEmptyState` / `HomeSureErrorState`**: Consistent institutional empty and error panels with optional retry/action button.
