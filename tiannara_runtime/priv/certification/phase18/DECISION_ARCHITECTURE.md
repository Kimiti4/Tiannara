# Phase 18.6 — Constitutional Decision Making & Policy Execution: Architecture

## Overview

Phase 18.6 defines the constitutional decision-making and policy-execution subsystem. It provides a formal pipeline through which plans are evaluated, authorized, and converted into executable intents without an execution policy layer — execution itself is handled by downstream phases.

### Decision Pipeline (Plan → Evaluate → Authorize → Intent)

1. **Plan** — A candidate action or plan is submitted by a planning subsystem (e.g., Phase 18.2).
2. **Evaluate** — The plan is evaluated against the active policy hierarchy. Each policy produces scored evaluations.
3. **Authorize** — If the evaluation clears all applicable policies, an execution authorization is issued.
4. **Intent** — The authorization is materialized as an `ExecutionIntent` and handed off for execution.

No execution policy exists at this layer; 18.6 terminates at intent issuance.

### Integration with Phases 18.2–18.5

| Phase | Role in 18.6 |
|-------|-------------|
| 18.2 (Planning) | Supplies plans and candidates for evaluation |
| 18.3 (Simulation) | Provides simulation traces used in policy evaluation |
| 18.4 (Verification) | Supplies formal proof artifacts consumed by Safety and Mathematical policies |
| 18.5 (Resource) | Provides resource budgets and constraints consumed by the Resource policy |

### Policy Hierarchy

Policies are evaluated in the following precedence order. Higher policies may veto a decision regardless of lower-policy scores.

1. **Mission Policy** — Ensures alignment with core mission and constitutional values.
2. **Scientific Policy** — Validates scientific integrity, methodology, and epistemic soundness.
3. **Safety Policy** — Enforces safety constraints, hazard avoidance, and containment.
4. **Mathematical Policy** — Verifies mathematical consistency and formal correctness.
5. **Governance Policy** — Checks procedural compliance, jurisdictional authority, and governance rules.
6. **Simulation Policy** — Ensures simulation fidelity and that simulation-derived evidence is admissible.
7. **Resource Policy** — Validates resource availability within budget.
