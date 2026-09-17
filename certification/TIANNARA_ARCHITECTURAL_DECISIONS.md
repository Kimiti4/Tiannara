# Tiannara Architectural Decisions — Remediation Campaign

Campaign: Remediation Architecture & Epistemic Foundation Certification (READ-ONLY)
Baseline commit: `3bd1601b9bb3c718f985d44ceaa8ef2e638d4ec6`
All decisions are **PROPOSED** — adoption requires human-authorized ASC per POL-CERT-AUTH-001. None were implemented.

---

## D1 — Canonical domain ontology
**Decision:** 20 domains = OS `@twenty_domains` minus `:science`, `:mathematics` plus `:physics`, `:chemistry`. Mathematics reclassified as epistemic substrate; Science as methodology. ComputerScience orphan merged into `:computation`.
**Alternatives:** (a) keep both registries for different consumers — rejected: phantom ids already poison ASC seeds and crash paths; (b) add physics/chemistry alongside science/mathematics (22 domains) — rejected: contradicts ratified target architecture.
**Consequences:** migration map for stored id references; ~14 call-site fixes; single source of truth (`DomainRegistry` GenServer started).

## D2 — Math substrate by consolidation, not construction
**Decision:** Canonical `Tiannara.Math` = evidenced kernels only (bayes_update, cosine_similarity/correlation/distance set, one entropy, Numerics stable forms, InformationTheory fold-in). Dead code deleted; mocks made real or deleted with their claims.
**Alternatives:** full symbolic/proof math layer — rejected: no consumer evidence; violates bounded-certification discipline.
**Consequences:** golden-value tests precede every dedup deletion; economics loses fake "equilibrium analysis" until nash is real.

## D3 — Minimal logic kernel (6 functions)
**Decision:** Extract `Logic.*` kernel from Contradiction.Engine + Sentinel.Verification; BeliefSystem negation matcher replaced; constitution registry dangling ref resolved.
**Alternatives:** build general theorem prover — rejected: over-generalization risk, no requirement.
**Consequences:** Loop B question stream changes → mandatory shadow-run diff period before cutover.

## D4 — Quarantine fabricated-evidence loop BEFORE any substrate trust (R0)
**Decision:** Loop A's random executor path and CEL constant-result steps are removed from live wiring or feature-flagged default-off; persistent memory purged of records whose provenance resolves to fabricated execution.
**Alternatives:** leave running "until remediation done" — rejected: every heartbeat writes poisoned priors that substrate work would inherit.
**Consequences:** short-term drop in visible "research activity" telemetry — accepted; honesty over optics.

## D5 — Single execution gateway
**Decision:** `Phase4.ExperimentOrchestrator.submit_experiment` becomes the only production execution entry point (resource validation + Council gating + retries); Sandbox restricted to approval-gated use; discovery loop's direct workflow dispatch routes through orchestrator.
**Alternatives:** keep three executor tiers — rejected: unverifiable provenance, MC-003 acceptance impossible.
**Consequences:** throughput bounded by concurrency cap (:267-270); requires wiring previously-dead service into a live caller.

## D6 — Physics-first domain activation
**Decision:** Pilot = Physics; second = Chemistry; first cross-domain pair ecology→economics (existing TransferMatrix seed row).
**Alternatives:** Cognition-first — rejected: highest coupling to unremediated reasoning layers.
**Consequences:** replaces ASC hardcoded experiment list with registry-driven selection.

## D7 — Registry stack startup policy
**Decision:** Start UnknownRegistry/DiscoveryRegistry/DomainRegistry in supervision tree after fixing OS ResearchDirector's latent self-call deadlock (:377-381); wire mutators to live events.
**Alternatives:** leave canonical stack dormant — rejected: MC-003 acceptance requires non-empty UnknownRegistry fed by kernel contradictions.
**Consequences:** new live processes require supervision specs + tests; deadlock fix is prerequisite.

## D8 — Evidence-derived uncertainty propagation
**Decision:** Replace fixed ±0.1 confidence deltas with uncertainty computed from evidence distributions (posterior variance from bayes_update outputs).
**Alternatives:** defer — rejected: fixed deltas make verdict confidence meaningless, undermining all downstream prioritization.
**Consequences:** touches finalize paths in scheduler + pipeline; covered by P16-AT(d).

## Dependency enforcement
Order R0 → AC-001 → MC-001 → MC-002 → MC-003 → MC-004 enforced via dependency graph artifact; each gate closes only on its acceptance tests, executed under certification bounds with hashed contracts per house convention.
