# Network Analysis & API Reverse-Engineering — K-RERA Reconnaissance

This document logs network-level behavior and reverse-engineering findings on [K-RERA](https://rera.karnataka.gov.in/).

---

## Status Legend

- `[VERIFIED]`: Observed directly via network tooling with verifiable request/response payloads.
- `[UNVERIFIED]`: Anticipated API pattern or protocol behavior not yet validated.
- `[ASSUMPTION]`: Hypothesis regarding backend architecture or data serialization.
- `[BLOCKED]`: Inspection hindered by client-side restrictions, access controls, or technical blocks.

---

## Current Status: [BLOCKED] Direct In-Page DevTools Inspection

> [!CAUTION]
> **Network Inspection Blocked by Client-Side Control**
> In-page invocation of Chrome Developer Tools via `F12` triggers an explicit security restriction modal. Pursuant to project governance and technical restrictions, **no attempt will be made to bypass, circumvent, or suppress this mechanism**. Direct interactive Network inspection is marked as **BLOCKED** pending an authorized, passive alternative.

---

## Security & Anti-Bot Observations

### [BLOCKED] In-Page F12 Developer Tools Restriction
- **Date & Time:** 2026-11-04 23:30 IST
- **Portal Section:** `/projectViewDetails`
- **Trigger Action:** Pressing `F12` keyboard shortcut on the K-RERA project page.
- **Observed Behavior:**
  - An in-page white modal dialog is immediately rendered over the page content.
  - Modal text message:
    > *"Due to security reason, This function has been disabled!!"*
  - The modal appears directly within the webpage DOM (not a separate browser dialog or Chrome system alert).
- **Technical Hypothesis `[ASSUMPTION]`:**
  - Likely implemented via a client-side JavaScript keyboard event listener (e.g., `document.addEventListener('keydown', ...)` or `window.onkeydown`) trapping keycode 123 (`F12`), potentially along with `Ctrl+Shift+I` or right-click context menu prevention.
  - The exact implementation remains unverified.
- **Compliance & Protocol:**
  - **No circumvention:** We strictly adhere to our mandate not to defeat or bypass access controls or security mechanisms.
  - Direct Network tab logging via in-page F12 is officially categorized as `[BLOCKED]`.
- **Confidence:** High (Direct UI observation)
- **Open Questions:**
  - Does the portal permit navigation and pagination through standard user interaction without requiring any DevTools inspection? (Yes, portal remains operational for normal navigation).

---

## Endpoint Catalog

| Endpoint Pattern | Method | Purpose | Response Type | Auth/CSRF Required | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| *Direct DevTools Inspection* | - | Network payload inspection | - | - | `[BLOCKED]` |

---

## Historical Inspection Protocol (Reference Only — Suspended)

*(Retained for future reference if authorized API access or non-intrusive server-side logs become available.)*

1. Open Google Chrome and launch DevTools.
2. Navigate to Network tab > Fetch/XHR.
3. Preserve log & monitor request/response lifecycles.
