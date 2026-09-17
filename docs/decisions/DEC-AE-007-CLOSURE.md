# Decision: AE-007 Closure & CEL-1 Forward Lock

**Decision ID:** DEC-AE-007-CLOSURE
**Timestamp:** 2026-08-21
**Authority:** Human operator (via ASC-AE-007-ADOPTION.human.yaml)
**Status:** CLOSED (ADOPTED)

## Resolution
F11 (CIS production residency) is remediated and adopted.
`Tiannara.CIS.Supervisor` is now a child of `Tiannara.Application`
(inserted after `Tiannara.Sentinel.Supervisor`). All 9 residency gates PASS.

## Layered Regression Evidence
The fixes compose on a common substrate:
```text
CIS production resident (F11)
  + EventStore healthy / ExecutiveMemory healthy (F12)
  + EOS no critical failures, no false emergency (F9)
  + grounded assess_risk, nil → unknown (F10)
  + restart semantics + C2/C3 continuity isolation (U7/U8 properties)
```

## Updated Blocker Map
| Finding | Status | Notes |
|---------|--------|-------|
| F8  | ✅ ADOPTED | Lineage retrieval honest + crash-free |
| F10 | ✅ ADOPTED | Risk prediction grounded + bounded |
| F12 | ✅ ADOPTED | DETS health contract corrected |
| F9  | ✅ RESOLVED | False emergency eliminated |
| F11 | ✅ ADOPTED | CIS production-resident |
| F13 | 🟠 OPEN | Discovery supervisor lifecycle — NEXT (diagnosis) |
| CEL-1 | ⏸️ LOCKED | Dynamic delegation — AFTER F13 |

## CEL-1 Forward Lock (recorded, not started)
**Milestone name:** CEL-1 — Registry-Driven Executive Delegation
**Three independent claims to prove:**
1. **Discovery** — CEL discovers capabilities dynamically (not hardcoded map).
2. **Selection** — CEL selects among eligible capabilities using actual state
   (health + dependencies + authority).
3. **Delegation** — CEL executes through the selected capability while
   preserving C14 authorization, lineage, and causal trace.
**Critical test requirement:** The delegated capability must be one the
registry did NOT hardcode specifically for the test. Otherwise CEL-1 can
pass while remaining the static delegation system identified in the cel.md
side-check (~55% depth).
**Acceptance path:**
```text
Novel mission → CEL Executive → CapabilityRegistry
  → discover → evaluate(health+deps+authority) → select delegate
  → Mission Director → execute → ExecutiveMemory → causal trace
```
**Gate:** CEL-1 begins only after F13 verdict is recorded.
