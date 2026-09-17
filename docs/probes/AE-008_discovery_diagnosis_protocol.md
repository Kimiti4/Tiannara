# AE-008 Phase B: Discovery Supervisor Diagnosis Protocol

## Objective
Isolate WHY canonical boot classifies Discovery as degraded, by walking a
decision tree that discriminates among H1–H5. This is read-only diagnosis.

## Golden Rule
Do NOT patch during diagnosis. Record evidence. The verdict decides the remedy.
If Discovery is legitimately degraded, the correct EOS output remains degraded.

---

## Step 1 — Functionality Probe (discriminates H5)
**Action:** Probe Discovery's REAL functionality, not its boot status.
Call its actual API / exercise its actual job. Check liveness via whereis.
**Question:** Is Discovery actually doing its work?
- **NON-FUNCTIONAL** (crashes, no response, wrong output) → **H5 (real failure)**.
  STOP classification analysis. Escalate to dedicated remediation. Do not surface-patch.
- **FUNCTIONAL** → proceed to Step 2.

## Step 2 — Ownership Audit (discriminates H1)
**Action:** Enumerate ALL supervisors' child specs. Search for Discovery's
child id / module across the entire tree. Count how many supervisors claim it.
**Question:** How many supervisors believe they own Discovery?
- **TWO (or more) parents claim it** → **H1 (duplicate ownership)**.
  Remedy direction: topology fix (single owner). Adoption-gated.
- **ONE parent** → proceed to Step 3.

## Step 3 — Topology Check (discriminates H3)
**Action:** Compare Discovery's ACTUAL parent against its INTENDED parent
(from architecture docs / design intent).
**Question:** Is Discovery under its intended parent?
- **ACTUAL != INTENDED** → **H3 (incorrect topology)**.
  Remedy direction: relocate under intended parent. Adoption-gated.
- **ACTUAL == INTENDED** → proceed to Step 4.

## Step 4 — Contract Check (discriminates H4)
**Action:** Inspect the ServiceRegistry health_check registered for Discovery
and the EOS classification logic. Compare the return shape the implementation
produces against the shape EOS expects. (Same failure family as F12.)
**Question:** Does the health/boot contract match the implementation?
- **MISMATCH** (stale match pattern, wrong return shape, wrong health_check name)
  → **H4 (lifecycle contract mismatch)**.
  Remedy direction: contract correction. Adoption-gated.
- **MATCH** → proceed to Step 5.

## Step 5 — Nested-Startup Check (discriminates H2)
**Action:** Determine whether Discovery (or a sub-process) is intentionally
started by a nested component BEFORE the owning supervisor attempts to start it,
making already_started an EXPECTED outcome.
**Question:** Is already_started expected here, and is EOS misreading it?
- **YES — expected nested start, EOS misclassifies** → **H2 (classification bug)**.
  Remedy direction: EOS should treat expected-already-started as healthy.
  Adoption-gated. MUST preserve sensitivity to genuine failures.
- **NO — already_started is unexpected** → escalate. Degradation is genuine and
  unclassified. Record a NEW FINDING; do not force a hypothesis.

---

## Verdict Table

| Evidence Signature | Hypothesis | Verdict | Remedy |
|--------------------|-----------|---------|--------|
| Discovery non-functional | H5 | Real failure | Escalate (no surface patch) |
| Two parents claim it | H1 | Duplicate ownership | Topology fix (gated) |
| Under wrong parent | H3 | Incorrect topology | Relocate (gated) |
| Contract shape mismatch | H4 | Contract mismatch | Contract fix (gated) |
| Expected nested start, EOS misreads | H2 | Classification bug | EOS fix (gated) |
| Functional, correct owner, contract ok, not nested — still degraded | — | Legitimately degraded OR new finding | NO patch; record truth |

## Regression Guard (binding, from F9/F12)
Any remediation candidate MUST be tested for classification accuracy:
```text
genuinely healthy Discovery  → classified healthy
genuinely degraded Discovery → classified degraded  (must NOT be silenced)
genuinely failed Discovery   → classified failed
```
A candidate that makes a genuinely-degraded Discovery report healthy is
**REJECTED** regardless of all other results. We do not trade truth for green.

## Deliverable
`ASC-AE-008_VERDICT.md` — records:
1. The evidence for each step of the decision tree.
2. The discriminated hypothesis (or "legitimately degraded" / "new finding").
3. The remedy decision (no change / isolated candidate / escalation).
4. The regression-guard test results if a candidate was generated.
