# MC-001: Mathematical Bottleneck Analysis

**Date:** 2026-08-27

## Bottlenecks (ranked)

| ID | Category | Description | Impact | Frequency | Severity | Repairability |
|----|----------|-------------|--------|-----------|----------|---------------|
| BN-MC001-001 | Duplication + formula conflict | variance/stdev/entropy/cosine implemented in ≥2 module families with conflicting formulas (sample vs population) and conflicting return contracts ({:ok,float} vs float) | HIGH | HIGH | HIGH | HIGH (pure funcs) |
| BN-MC001-002 | Theatrical verification | FormalVerification always returns verified:true; consumed by Physics.validate → false confidence | HIGH (epistemic) | MEDIUM | CRITICAL | HIGH (make real or mark unavailable) |
| BN-MC001-003 | Theatrical simulation | Calculus.solve_ode returns mock trajectory; consumed by Physics.simulate | HIGH (epistemic) | MEDIUM | HIGH | MEDIUM (needs real integrator or unavailable boundary) |
| BN-MC001-004 | Fabricated metrics | Physics.metrics + Math dashboard return hardcoded numbers unconsumed by state | MEDIUM | HIGH | MEDIUM | HIGH (compute or return unavailable) |
| BN-MC001-005 | Missing symbolic tier | No expression AST / symbolic reasoning | HIGH | LOW | HIGH | LOW (large effort) |
| BN-MC001-006 | Missing proof/verification tier | No proof checker beyond mock | HIGH | LOW | HIGH | LOW (large effort) |
| BN-MC001-007 | Naming/vendor ambiguity | hardcoded vendor metrics disguised as computed | MEDIUM | LOW | MEDIUM | MEDIUM |

## Millennium Prize Problem Prerequisites

Exactly as the reconciliation requires — this assesses **prerequisites**, not
ability to solve. Tiannara cannot solve Millennium problems today.

| Prerequisite | Status | Evidence |
|-------------|--------|----------|
| Formal representation | MISSING | no formal AST found |
| Symbolic reasoning | MISSING | no symbolic engine found |
| Proof search | MISSING | no proof search found |
| Counterexample search | MISSING | none found |
| Large-scale computation | PARTIAL | Numerics exist; scale unproven |
| Conjecture generation | MISSING | none found |
| Literature/knowledge integration | PARTIAL | knowledge_graph exists |
| Experiment management | PARTIAL | physics design_experiments is empty stub |
| Reproducibility | PARTIAL | some REAL tests exist |
| Proof verification | MISSING | formal_verification is mock |
| Long-horizon search | MISSING | none found |

**Summary: 0 AVAILABLE, 4 PARTIAL, 7 MISSING.**

## Repair Order Recommendation (for the separate mutation gate)

1. Resolve duplication + formula conflict (single canonical vendor per op).
2. Decommission / make-unavailable the theatrical verification and ODE mocks.
3. Stop fabricating metrics (return unavailable or compute real values).
4. Only then consider building symbolic and proof tiers.
