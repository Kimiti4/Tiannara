# Decision: AE-008 Closure & F13 Refinement

**Decision ID:** DEC-AE-008-CLOSURE
**Timestamp:** 2026-08-21
**Authority:** Human operator (via ASC-AE-008 diagnosis)
**Status:** CLOSED (DIAGNOSTIC-ONLY — NO ADOPTION ARTIFACT)

## Verdict Recorded
`H5_real_failure_metrics` — `DiscoveryMetrics` failed to start during
canonical boot. Not duplicate ownership, not classification bug, not
health-shape mismatch, not total Discovery failure.

**Remedy from verdict:** `investigate_metrics` (no surface patch).

## F13 Decomposition (lineage preserved)
F13 is refined, not replaced:
```text
F13 (original): "discovery_supervisor degraded"
   └── F13 (refined): "DiscoveryMetrics lifecycle failure"
          ├── Engine       ✓ alive
          ├── Scheduler    ✓ alive
          ├── Metrics      ✗ failed to start
          └── health       → DEGRADED (true EOS output)
```

## Epistemic Note
The current health contract `[:degraded, [:discovery_metrics]]` penalizes
metrics absence. This is EVIDENCE but not conclusive proof that metrics are
REQUIRED — the contract itself may be the mis-specification. Intent must be
established before the contract is trusted or changed.

## Blocker Map Update
| Finding | Status | Notes |
|---------|--------|-------|
| F8, F9, F10, F11, F12 | ✅ RESOLVED | Adopted + verified |
| F13 | 🟠 OPEN (refined) | DiscoveryMetrics lifecycle failure — investigate |
| CEL-1 | ⏸️ LOCKED | Pending F13 closure |

## Next Mission
ASC-AE-009 — DiscoveryMetrics Lifecycle Investigation (diagnostic-first).
