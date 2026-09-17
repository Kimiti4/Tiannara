# Tiannara Remediation Architecture Report — Master

Campaign: Remediation Architecture & Epistemic Foundation Certification
Mode: READ-ONLY audit. Zero production mutations. POL-CERT-AUTH-001 honored (no ACTION taken; recommendations only).
Baseline commit: `3bd1601b9bb3c718f985d44ceaa8ef2e638d4ec6` (== HEAD at audit time; pre-existing unrelated working-tree modifications present and out of scope)
Date: 2026-08-25
Predecessor artifacts: `certification/TIANNARA_CERTIFICATION_MANIFEST.json`, `TIANNARA_MISSING_CAPABILITY_REGISTER.md`, `TIANNARA_ARCHITECTURE_CERTIFICATION_MATRIX.md`

---

## 0. ID mapping note

The prior register numbered gaps MC-001=Domain Execution, MC-002=Math Proof Kernel, MC-003=Logic Substrate, MC-004=P16 Execution. The ratified campaign prompt numbers them MC-001=Math substrate, MC-002=Logic substrate, MC-003=P16 execution, MC-004=Domain execution (+AC-001 registry mismatch). Both numberings are preserved in artifacts; cross-references resolved by content. No silent reconciliation.

## 1. Executive summary per gap

| Gap | Verdict | One-line resolution |
|---|---|---|
| **MC-001 Mathematics** | Exists as distributed infrastructure + thin partly-mocked core (B+C+D) | Consolidate evidenced kernels; delete dead code; make-or-delete mocks |
| **MC-002 Logic** | Distributed + partially theatrical (B, partial E) | Extract 6-function kernel from sound sites; replace broken matcher; fix dangling ref |
| **MC-003 Phase16 execution** | Break at Stage 7; three executor tiers; two live loops of divergent integrity | Quarantine fabrication (R0); adopt Phase4 orchestrator as sole gateway; start registry stack |
| **MC-004 Domain execution** | Universal stubs (`{:ok, []}` ×21 modules) | Physics pilot through real gateway after prerequisites |
| **AC-001 Registry contradiction** | CONFIRMED AND EXTENDED beyond prior report | Canonical ontology swap; unify registries; fix ~14 crash call sites |

## 2. What the audit found that the previous certification missed

1. **F-NEW-1 (CRITICAL): a live, heartbeat-driven loop fabricates experimental results and persists them into persistent memory** (`research/research_director.ex:142-171`; CEL constant steps `experiment.ex:49-57`). The prior register flagged P16 as "PARTIAL — planning operational, execution missing"; in fact fake execution is *running*.
2. **F-NEW-2:** provenance theater — ledger identity hash over a literal module-name string (`recursive_civilization_runner.ex:725-728`) plus two competing ScientificCapitalLedgers.
3. **F-NEW-3:** the fully resource-validated, Council-gated orchestrator has zero callers (`submit_experiment`) — the "missing" execution layer exists but is unwired.
4. **F-NEW-5:** `constitution/registry.ex:118` calls a nonexistent logic module — architectural evidence that a Logic kernel was always assumed.
5. AC-001 extended: phantom domain ids seeded by ASC research bridge; ComputerScience orphan; ~14 nonexistent-API crash paths; observatory metrics hardcoded.

## 3. Autonomous loops verdict (MC-003 detail)

Two closed loops run without human advancement:
- **Loop A** — structurally complete, epistemically fake (random measurements → persistent memory). CRITICAL quarantine target R0.
- **Loop B** — genuinely closed (discovery → real divergence measurement → world-model writeback via WorldStateSynchronizer) but narrow: only measures divergence between seeded observation entities; uncertainty updates fixed ±0.1.

Human gates exist (Sentinel approval, experiment approval status gate, Council high-risk gate) but do not intercept Loop A's fabricated path.

## 4. Remediation architecture (summary)

Order enforced by dependency graph artifact:

1. **R0** — Quarantine fabricated-evidence sources; purge poisoned persistent records by lineage.
2. **AC-001** — Canonical 20-domain ontology (`−:science −:mathematics +:physics +:chemistry`), unified registry, crash-path fixes.
3. **MC-001** — Math consolidation under canonical facade; CapabilityGraph registration in production supervision.
4. **MC-002** — Logic kernel extraction (6 functions), shadow-run cutover.
5. **MC-003** — Fix OS-director deadlock; start UnknownRegistry stack; wire orchestrator; evidence-derived uncertainty.
6. **MC-004** — Physics → Chemistry pilots; ecology→economics transfer pair; delete ASC hardcode.

Each stage closes only via its acceptance tests (M-AT/L-AT/P16-AT/D-AT sets defined in sub-artifacts), executed with hashed contracts per house convention.

## 5. Validation architecture

Per-gap categories assigned (MISSING / DISTRIBUTED / DUPLICATED / MOCKED / THEATRICAL / OPERATIONAL-NARROW). Every claim in this campaign carries file:line; load-bearing claims were re-verified by direct reads during synthesis (research_director.ex:173-185, cel experiment step, os/domain_registry.ex:83-104, capital-ledger stub).

## 6. Risks to remediation itself

- Golden-value capture must precede every dedup deletion (math/logic).
- Loop B behavior will shift when kernel-grade contradiction detection lands — shadow-run mandatory.
- Purge scope for R0 must key on experiment_id lineage to avoid deleting legitimate records.
- Ontology migration must map stored references before cutover.
- Orchestrator-as-gateway creates a throughput bottleneck (concurrency cap already present).

## 7. Open questions (for human adjudication)

1. Is unbooted `tiannara_runtime`/REA stack the intended canonical P16 implementation, or does remediation proceed on the main app? (Affects whether D5 gateway is Phase4 or REA.)
2. Should dormant Omega.Supervisor propose-only tree be adopted or deleted?
3. FormalVerification mock: implement or remove its claims?
4. ComputerScience orphan: merge into `:computation` or alias-register?

## 8. FINAL RECOMMENDATION

# PROCEED TO REMEDIATION

Conditions: sequence R0 → AC-001 → MC-001 → MC-002 → MC-003 → MC-004 enforced; each gate closed by acceptance tests; every production mutation individually human-authorized (`ASC-*.human.yaml`); no verdicts assumed satisfied without hashed-contract reruns.

Rationale: all five targets have evidenced implementation seeds (no greenfield requirement); the single blocking hazard (fabricated-evidence loop) has a well-defined quarantine action; the dependency order eliminates every identified circularity risk. BLOCKED was considered and rejected — no required evidence was missing. REQUIRES ARCHITECTURAL REVISION was considered and rejected — findings support targeted consolidation within the existing architecture rather than redesign.
