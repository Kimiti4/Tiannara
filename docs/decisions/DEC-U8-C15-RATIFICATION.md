# Decision: U8 Continuity Ratification & F12 Classification

**Decision ID:** DEC-U8-C15-RATIFICATION
**Timestamp:** 2026-08-21
**Authority:** Human operator
**Status:** ACTIVE

## C15 Disposition
**Status:** `✓*` (Test-topology-conditional, durable-store path)

All four continuity questions answered affirmatively:
1. **Identity ✓** — Entity ID retained post-kill via durable EventStore.
   Honest caveat: C2 digraph lookup returns `:not_found` (in-memory graph lost).
2. **Causality ✓** — Exactly 1 matching event at S0 and S1, no duplicates,
   `latest_offset` unchanged, replay traces to original event.
3. **Epistemic Continuity ✓** — Knowledge artifact file-backed, lineage resolves.
4. **Recovery Honesty ✓** — F8 crash caught and break reported explicitly.
   No fabricated or empty history returned.

## F12: Stale DETS Health Contract
**Status:** OPEN / HIGH PRIORITY

`EventStore.healthy?/0` → `false` and `ExecutiveMemory.health/0` → `:unhealthy`
on a fully healthy topology. Root cause: `match?({:ok, _}, :dets.info/1)` expects
a tagged tuple, but current OTP returns the bare info list.

### Hypothesis (recorded, not proven)
F12 is the likely **mechanistic root** of:
- F9 (false EOS emergency) — EOS consumes health telemetry that is permanently negative.
- Potentially distorted C12 homeostasis decisions if CIS were production-resident (F11).

Causal chain (hypothesized):
```text
F12 (stale DETS match pattern)
       ↓
EventStore.healthy?/0 → false (always)
ExecutiveMemory.health/0 → :unhealthy (always)
       ↓
F9 (EOS aggregates false negatives → reports emergency)
       ↓
Any future C12 production integration would inherit bad telemetry
```

This hypothesis requires verification. It is NOT proven causality.

## Cumulative Defect Register (Post-U8)
| ID | Description | Status | Priority |
|----|-------------|--------|----------|
| F1 | C1 atom-key boundary contract | OPEN | MEDIUM |
| F2 | Ω.R OOM remediation (deferred) | OPEN | DEFERRED |
| F8 | DETS traverse continuation leak | OPEN | MEDIUM |
| F9 | False EOS emergency | OPEN | HIGH |
| F10| Random CollapsePredictor risk | OPEN | HIGH |
| F11| CIS.Supervisor absent from production tree | OPEN | ARCHITECTURAL |
| F12| Stale DETS health reporting contract | OPEN | HIGH |