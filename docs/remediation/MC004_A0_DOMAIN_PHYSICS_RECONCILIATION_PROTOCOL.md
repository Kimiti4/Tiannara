# MC-004-A0 — Domain/Physics Pilot Reconciliation Protocol

**Gate:** MC-004-A0 (Observational — Reconciliation Only)
**Campaign:** Tiannara Remediation + Substrate Integration
**Predecessors:** MC-003-M CERTIFIED (BOUNDED); MC-003-A0 CERTIFIED (RECONCILIATION ONLY); MC-002-M CERTIFIED (BOUNDED); MC-002-A0 CERTIFIED (RECONCILIATION ONLY); AC-001 FINAL CERTIFIED (BOUNDED)
**Mode:** READ-ONLY. NO production mutation. NO real-execution enablement. NO live physics experiment. NO physics capability certification.
**Date:** 2026-08-31

## Governing Principles

- Truth > apparent capability; Evidence > confidence; Verification > autonomy; Reuse > duplication; Stable migration > broad rewrite.
- The question this gate answers is strictly: **"Can Tiannara, today, produce one bounded Physics result whose computation, execution, observation, provenance, and verification status are all demonstrably truthful — and independently reproducible?"** The answer must be read from the repository, not from roadmap claims.
- An unavailable epistemic capability must never be interpreted as capability; truthful unavailable > fabricated execution (MC-001-M / MC-002-M / MC-003-M precedent).
- Distinguish: proposed / scheduled / simulated / attempted / completed / observed / verified.
- Theatrical capability (randomness + hardcoded "success") is the anti-pattern this gate exposes. Reconciliation records it with file:line; A0 does NOT decommission it.

## Scope

Canonical `:physics` domain reconciliation across: the canonical registry boundary; `Tiannara.Domains.Physics`; the `Tiannara.Physics.*` subsystem (OPC / NDE / IRD / TWP); the math substrate consumed by physics; the scientific workflow chain that would consume physics capability; real-execution integration; verification and provenance paths; safety/authorization of physics paths; and truthfulness of physics-derived metrics.

PRIMARY question: does Tiannara possess a REAL, reusable, testable physics domain capability on the MC-001/MC-002/MC-003 substrates — or is the physics domain theatrical/stubbed/disconnected/dead?

## Truth Classes

REAL / PARTIAL / THEATRICAL / FABRICATED / UNKNOWN / NO

- REAL requires observable computation with genuine derivation or a genuine measurement with provenance.
- THEATRICAL: returns numbers shaped like capable output where the "capability" is randomness or hardcoded constants, not derivation.
- NO: the capability does not exist or returns a truthful unavailability error.
- A passing test of a theatrical implementation remains theatrical evidence.

## Evidence Rules

- Every classification cites file:line.
- Static classification is sufficient for the judgments reached; runtime cross-repo behavior and genuine side-effect observation is recorded as NOT_EXECUTED where the environment prevents it.
- No capability may be classified REAL from module names, documentation, comments, tests, or intended architecture alone.
- Never fabricate a verifier. If verification is absent → classify UNAVAILABLE.

## Reconciliation Checks (this gate)

1. What does the canonical `:physics` domain claim to do vs. what it can actually do?
2. Which physics computation surfaces are REAL, PARTIAL, THEATRICAL, or NO?
3. Does any physics result carry provenance? (kind / derivation / verifier identity)
4. Is there a verification layer for physics results, or is verification self-referential/theatrical/absent?
5. Which execution paths consume physics capability — live, dead, or disconnected?
6. Is authorization / sandboxing / timeout / resource bounding enforced on physics computation?
7. Are physics metrics truthful? Are any metrics fabricated (TD-MC001-M5-DOMAINS)?
8. Which substrate capabilities physics requires (ODE solving, formal verification, numerics, linear algebra) actually exist?
9. Is the physics subsystem (`Tiannara.Physics.*`) connected to the discovery pipeline, or theatrical theater disconnected from truth?
10. What is the smallest bounded physics pilot that could truthfully run after authorized MC-004-M mutation?

## Known Prior-Art Divergences (recorded for truth)

- The physics domain module is honest-empty: `discover` always returns `%{discoveries: []}` and `metrics` are truthful zeros — yet `simulate` and `validate` depend on capabilities decommissioned by MC-001-M (ODE solver) and MC-001-M/MC-002-M (formal verification), so the domain cannot currently perform physics.
- The `Tiannara.Physics.*` subsystem is THEATRICAL: OPC (`opc.ex:472-475`), IRD (`ird.ex:483`, `ird.ex:595`), NDE and TWP fabricate physics-shaped numbers via `:rand.uniform` and canned constants, and several functions are broken (NDE/TWP KeyError paths). This subsystem is NOT consumed by the discovery pipeline, but it is supervised and present, and must not be mistaken for physics capability.
- The `AutonomousDiscoveryEngine.run_discovery_cycle/0` path is DEAD (single occurrence, its own definition, `autonomous_discovery.ex:15`); no production code invokes it, so today no physics claim can influence autonomous decisions.

## Forbidden (this gate)

Production mutation; enabling real execution; running or simulating a physics experiment; implementing an ODE solver or any new math capability; decommissioning or replacing theatrical subsystems; modifying MC-001/MC-002/MC-003/AC-001 artifacts; certifying physics capability; fabricating c14 signature; expanding scope to all 20 canonical domains.

## Deliverables (17)

1. This protocol (`docs/remediation/MC004_A0_DOMAIN_PHYSICS_RECONCILIATION_PROTOCOL.md`)
2. `priv/tiannara/remediation/contracts/MC004_A0_domain_physics_reconciliation.contract.yaml`
3. `priv/tiannara/authorization/ASC-MC-004-A0-DOMAIN-PHYSICS-RECONCILIATION.human.yaml`
4. `certification/remediation/MC004-A0-PHYSICS-INVENTORY.md`
5. `certification/remediation/MC004-A0-TRUTH-CLASSIFICATION.md`
6. `certification/remediation/MC004-A0-CONSUMER-MAP.md`
7. `certification/remediation/MC004-A0-WORKFLOW-TRACE.md`
8. `certification/remediation/MC004-A0-ARCHITECTURE.md`
9. `certification/remediation/MC004-A0-VERIFICATION-PROVENANCE.md`
10. `certification/remediation/MC004-A0-SAFETY-EXECUTION.md`
11. `certification/remediation/MC004-A0-METRICS-DISCOVERY.md`
12. `certification/remediation/MC004-A0-PILOT-DEFINITION.md`
13. `certification/remediation/MC004-A0-BOTTLENECKS.md`
14. `certification/remediation/MC004-A0-MUTATION-PLAN.md`
15. `certification/remediation/MC004-A0-CERTIFICATION.md`
16. `priv/tiannara/remediation/results/MC004_A0_result.json`
17. `priv/tiannara/remediation/verifiers/MC004_A0_domain_physics_reconciliation.py`

## Certification Rule

Certifies only the **quality and completeness of the reconciliation evidence**, NOT physics capability. CERTIFIED_RECONCILIATION iff: inventory complete; classifications source-grounded (file:line); consumers mapped; workflow trace honest (MISSING is a truthful finding); architecture evidence-backed; verification/provenance distinguished from claimed; safety classified; metrics truth established; pilot defined WITHOUT execution; bottlenecks ranked with evidence; mutation candidates remain recommendations; no mutation occurred; verifier passes; limitations recorded.

Settlement sequence: MC-003-M CERTIFIED (BOUNDED) ⇒ MC-004-A0 → HUMAN REVIEW → MC-004-M (separate human authorization) → MC-004-P (bounded pilot execution) → independent verification → MC-004 certification.