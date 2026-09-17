# MC-001: Mutation Plan Proposal (A6)

**Status:** PROPOSED — NOT EXECUTED
**Requires:** A separate `ASC-MC-001-MUTATION.human.yaml` authorization before
any production mutation. This plan does not authorize anything.

## Proposed Mutation Groups (by priority, evidence-driven)

### M1 — Resolution of duplicate/conflicting math primitives (HIGH priority)
Grounding: BN-MC001-001 (inspected duplicates + formula conflict).
- Variance/stdev/entropy/cosine exist in ≥2 module families with conflicting
  formulas ({:ok,...} vs bare, sample vs population).
- Action: establish a single canonical `Tiannara.Math.*` implementation per
  operation, with an explicit, documented variance convention (sample vs
  population), and route consumers to it.
- Risk: LOW (pure functions), but MUST document which consumers relied on which
  formula before changing.

### M2 — Decommission theatrical verification + simulation mocks (HIGH priority)
Grounding: BN-MC001-002/003 (Physics depends on mocks).
- Action: replace `FormalVerification.verify_invariants` and
  `Calculus.solve_ode` mock behavior with either (a) real bounded
  implementations, or (b) explicit `{:error, :unavailable}` boundaries that do
  NOT report verified:true/mock trajectory.
- Risk: MEDIUM — Physics.validate currently reports verified:true; changing to
  unavailable will surface previously-hidden false confidence.

### M3 — Stop fabricating metrics (MEDIUM priority)
Grounding: BN-MC001-004 (Physics.metrics + Math dashboard hardcoded values).
- Action: derive metrics from state or return `{:error, :unavailable}` / nil
  rather than reporting fabricated counts (discoveries_this_cycle: 4 while
  discover/1 returns []).
- Risk: MEDIUM (dashboards may break), but required for truth.

### M4 — Establish canonical substrate contract (MEDIUM priority)
Grounding: MC-001-A3 architecture gap (no expression representation, mixed
operation contracts, no versioning).
- Action (additive): define a minimal `Tiannara.Math.Contract` specifying
  expression representation, operation signatures, failure semantics, and
  versioning. Not a full engine.
- Risk: LOW (additive).

### M5 — CapabilityGraph routing (LOW priority, follow-on)
Reuse the CEL-2 pattern to expose consolidated REAL primitives through
CapabilityGraph for discovery-based access. Not required for this gate.

## Explicitly NOT Proposed in This Gate

- Symbolic reasoning engine (large; separate gate)
- Proof verification system (large; separate gate; M2 is only about the mock)
- Conjecture generation (large)
- Counterexample search (large)
- Autonomous discovery engine (large)
- External solver introduction (requires separate evaluation)

## Authorization Requirement

Each mutation group requires:
1. A dedicated `ASC-MC-001-MUTATION-*.human.yaml` (separate from this reconciliation)
2. Human signature (c14_ac or designated operator) — not fabricated
3. Contract hash
4. Verification plan (tests for the specific behavior changed)
5. Rollback plan

No mutation executes unless and until separately authorized.
