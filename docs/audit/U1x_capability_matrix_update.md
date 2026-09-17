# U1x Capability Matrix — Unified Closed-Loop Update

**Probe:** U1x (Full Closed-Loop Certification), auth-free per POL-CERT-AUTH-001
**Contract:** `U1x_closed_loop` hash `de944edb05d0084046b2bd06109311ce778022519dd081eddff5a02b144ede05`
**Result:** PASS

## Edge Upgrades (only on PASS, human-reviewed)

| Edge | Status | Note |
|------|--------|------|
| C11 → C1 | `✓` (reaffirmed) | Novel external objective accepted via C11 ingress |
| C1 → C2 | `✓` | Perception → canonical reality mutation |
| C2 → C3 | `✓` | Reality → knowledge artifact |
| C3 → C4 | `✓` | Knowledge → epistemic assessment |
| C4 → C5/C6 | `✓` (math honest) | Plan with `math: :unwired_or_wired` — unwired flag is honest |
| C5/C6 → C8 | `✓` | Research plan → world/engineering constraints |
| C8 → C14 | `✓` | Context → governance decision (allow) |
| **C14 → CEL-1** | `✓` (new) | **Governance → dynamic delegation (CEL-1 bridge)** |
| **CEL-1 → C9** | `✓` (new) | **Registry-driven ASC provider discovery (capability_engineering → asc)** |
| C9 → C12 | `✓` | ASC → homeostasis monitoring (grounded) |
| C12 → C15 | `✓` | Homeostasis → continuity (persist/readback) |
| C15 → C11 | `✓` (dry_run) | Traceable egress, governance-gated, no external mutation |
| C11 egress (real) | `?` | Still gated — real external action requires separate C14 ACTION |

## Proposed Disposition
- The closed loop `C11→C1→C2→C3→C4→C5/C6→C8→C14→CEL-1→C9→C12→C15→C11` is now demonstrated with CEL-1 as the executive bridge. This upgrades the prior U0 `?` edges for C5/C6 and the CEL-1 integration edge to `✓`.
- The 4-entry static registry remains the next limitation: `MATH_NOT_REGISTERED` for `constitutional_mathematics` is the honest next gap, feeding **Constitutional Math v1 / CEL-2** (capability should be registered, not hardcoded).

**Bounded claim:** Under the tested execution path with descriptor `capability_engineering`, the organism demonstrated a causally-closed loop with dynamic provider discovery. No production mutation.

**No production change was made by this probe.**
