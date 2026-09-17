# MC-003-A0 — Real Execution Reconciliation Protocol

**Gate:** MC-003-A0 (Observational)
**Campaign:** Tiannara Remediation + Substrate Integration
**Predecessors:** MC-002-M CERTIFIED (BOUNDED); MC-002-A0 CERTIFIED (RECONCILIATION ONLY); AC-001 FINAL CERTIFIED (BOUNDED)
**Mode:** READ-ONLY. No production mutation. No execution engine created.
**Date:** 2026-08-29

## Governing Principles

- Evidence Before Confidence; Truth > apparent capability; Uncertainty never hidden.
- Verification First; capability must never outpace verification.
- Execution is REAL only when a side effect occurred that can be observed. A
  function named `execute` is not execution merely because it returns `{:ok, ...}`.
- `executed: true`, `success: true`, `status: :completed`, `deployed: N` are
  claims, never evidence. Evidence is an observable side effect (filesystem,
  subprocess, container, network, durable store, world change) or a genuine
  measurement with provenance.
- A successful function return is NOT proof that execution succeeded.
- An unavailable epistemic capability must never be interpreted as execution;
  truthful unavailable > fabricated execution (MC-001-M/MC-002-M precedent).
- Distinguish: proposed / scheduled / simulated / attempted / completed /
  observed / verified.

## Scope

Inventory and truth-classify the P16 / Real Execution substrate: execution
bridges, executors, orchestrators, schedulers, sandboxes, deployment pipelines,
rollback engines, verification of outcomes, external sensors, simulator-as-real
paths, self-improvement machinery, repair/deployment pipelines, autonomous
loops, and the Intent→Plan→Authorization→Execution→Observation→Result→Verification→Knowledge-integration chain.

PRIMARY question: does Tiannara possess a REAL, reusable, testable execution
capability — or simulated/theatrical/mocked/delegated/planned-only execution?

## Truth Classes

REAL / PARTIAL / THEATRICAL / FABRICATED / UNKNOWN / NO

REAL requires observable side-effect evidence or a genuine measurement with
provenance. A passing test of a theatrical implementation remains theatrical
evidence.

## Evidence Rules

- Every classification cites file:line.
- Static classification is sufficient for the judgments reached; full-runtime
  cross-repo behavior and genuine side-effect observation is recorded as
  NOT_EXECUTED where the environment prevents it.
- No capability may be classified REAL from module names, documentation,
  comments, tests, or intended architecture alone.
- Never fabricate a verifier. If verification is absent → classify UNAVAILABLE.

## Execution-Reality Checks (this gate)

1. Executable work actually performed, or data constructed?
2. Where does execution begin; what owns it; what performs the side effect?
3. What constitutes completion vs failure?
4. Are results directly returned from executed work, or mocked/hardcoded/
   synthesized without execution?
5. Is there an independent verification layer, or is verification
   self-referential/theatrical?
6. Are authorization, sandboxing, resource limits, timeouts, cancellation,
   isolation, rollback enforced — or merely documented?
7. Which execution paths feed discovery/planning/research/optimization/
   self-improvement/repair/autonomy (HIGH CRITICALITY)?
8. Which execution paths are dead/unconsumed?
9. Does the system distinguish proposed/scheduled/simulated/attempted/
   completed/observed/verified execution?

## Known Prior-Art Divergences (recorded for truth)

- `research/heartbeat.ex` documents itself as the quarantined replacement for a
  heartbeat that fabricated experiment results using randomness — yet the live
  `Tiannara.Sandbox` (wired in `sentinel/supervisor.ex:40`) still performs
  probabilistic outcome fabrication (`sandbox.ex:226-228`). Reconciliation
  records both facts.
- `Phase4.ExperimentOrchestrator.submit_experiment` is registered as an
  ExecutiveService but is NOT in the app supervision tree and has zero
  production callers — "built-dead" per remediation register.
- R0 (fabricated-evidence loop) remains OPEN-CRITICAL: `ExecutiveCycle`
  (`:execute` posts `status: :executed` to an in-memory blackboard) and
  `Tiannara.Sandbox` keep a fabricated Loop A live.

## Forbidden

Production mutation; API/test/supervision/config/ontology changes; creating an
execution engine; replacing theatrical implementations; implementing missing
capabilities; expanding P16 into general autonomous agency; modifying
MC-001/MC-002/AC-001 artifacts; fabricating c14 signature.

## Certification Rule

Certifies only the **quality and completeness of the reconciliation evidence**,
NOT P16 capability. CERTIFIED_RECONCILIATION iff: inventory complete;
classifications source-grounded (file:line); consumers mapped; architecture
evidence-backed; verification claims distinguished from actual verification;
side-effect/authenticity questions answered; safety/reliability classified;
bottlenecks ranked with evidence; mutation candidates remain recommendations;
no mutation occurred; verifier passes; limitations recorded.

Settlement sequence: MC-002-M CERTIFIED (BOUNDED) ⇒ MC-003-A0 → HUMAN REVIEW →
MC-003-M (separate human authorization).