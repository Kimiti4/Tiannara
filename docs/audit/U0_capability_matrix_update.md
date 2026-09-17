# U0 Capability Matrix — Post-U1 Update

**Reviewed by:** Human operator + assistant
**Probe:** U1 (Reality → Knowledge), executed under signed Tier-1 authorization
**Principle:** Evidence Before Confidence — no status upgraded without evidence.

| Capability              | U1 Result | New Status | Note |
|-------------------------|-----------|-----------|------|
| C1 Perception           | PASS      | `✓`       | Works standalone; boundary defect logged (see findings) |
| C2 Unified Reality Graph| BLOCKED   | `?`       | NOT `~`; runtime question unanswered |
| C3 Knowledge            | PASS      | `✓`       | mem-4bebb8f275f8 written + read back |
| C4 Epistemics           | PASS      | `✓`       | node rendered |
| C7 Memory/Lineage       | PASS      | `✓`       | verify_chain True |
| World-model shadow check| UNASSESSED| `?`       | world model unreachable standalone |

**No other matrix entries changed.**

# U0 Capability Matrix — Post-U4 Update (Integration Edges)

**Probe:** U4 (Governance → ASC), auth-free certification per POL-CERT-AUTH-001
**Principle:** Evidence Before Confidence — verdict targets integration edges, not whole capabilities.

| Integration Edge | U4 Result | Edge Status | Note |
|------------------|-----------|-------------|------|
| C3 → C8 (knowledge → engineering context) | PASS (both controls) | `✓` | CanonicalWorldState schema consumed knowledge artifacts |
| C8 → C14 (context → governance evaluation) | PASS (both controls) | `✓` | CapabilityChecker.authorize?/3 evaluated real intent context |
| C14 → C9 (governance → ASC candidate) | PASS (both controls) | `✓` | candidate governance_decision_ref == decision_hash; DENY blocks eligibility/executability/adoptability |

**Bounded claim (NOT a universal one):** under the tested execution path, ASC consumed the
authoritative C14 decision before producing consequential candidate state.

**No whole-capability statuses changed by U4.** C9/C14 retain their prior markers;
this update records demonstrated integration edges only.

## Verification Status Model (unchanged)
✓ = demonstrated · ~ = documented · ? = unassessed · ✗ = empirically failed

# U0 Capability Matrix — Post-U5/U6 Update (External Ingress Edges)

**Probe:** U5/U6 (External Reality Ingress & Propagation), auth-free certification per POL-CERT-AUTH-001
**Contract:** `priv/tiannara/probes/contracts/U5_U6_external_reality_ingress.contract.yaml` (hash `dd416de37d049a92...`)
**Principle:** Evidence Before Confidence — verdict targets integration edges, not whole capabilities.

| Integration Edge | U5/U6 Result | Edge Status | Note |
|------------------|--------------|-------------|------|
| C11 → C1 (boundary → perception) | PASS (valid signed ingress) | `✓` | signature verified, provenance captured, Observatory governance consult `:ok`, Event ingested |
| C11 (tampered ingress) | REJECTED (correct negative control) | `✓` | no mock/unverified external reality accepted; C1/C2/C3 skipped — no unauthorized side channel |
| C1 → C2 (perception → reality model) | BROKEN (honest) | `✗` | attempted real `add_node/3`; `:noproc` ExecutiveMemory exit recorded, not masked |
| C2 → C3 (reality model → knowledge) | NOT EXERCISED (chain broken) | `?` | C3 correctly refused state on broken chain (no shadow state) |
| C3 (standalone) | re-confirmed operational | `✓` | KnowledgeStore ready; refused shadow-state ingestion honestly |

**Bounded claim (NOT a universal one):** under the tested execution path, a signed external
reality event was received at the C11 boundary with verified cryptographic provenance,
consumed by C1 perception, attempted against the canonical C2 reality model, and the causal
chain was honestly recorded as broken at C1→C2 — with no shadow state and no unauthorized
side channel.

**C2 remains `?` (deferred, DEC-U1-C2-DEFER-003).** This run provides the formal runtime
evidence justifying the C2 Remediation Mission (proposal: outcome A — documented, verified
supervised bootstrap topology; or outcome B — repaired independence).

**Proposed matrix updates for human ratification (17-capability model):**
- C11 External Reality Interface (Ingress side): R `✓`, I `✓`, C `✓`; Egress side remains `?` (ACTION, C14-gated)
- C2: unchanged `?`
- No whole-capability statuses changed by U5/U6.

# U0 Capability Matrix — Post-C2-REM-001 Update (C2 Remediation Mission)

**Mission:** C2-REM-001 (C14-authorized ACTION, operator `schtickman`, signature `mock_test_c2`)
**Result:** CANDIDATE_ACCEPTED — outcome A: C2's ExecutiveMemory dependency is an **intentional supervised-runtime invariant**
**Evidence:** `docs/probes/C2_REMEDIATION_findings.md` + `priv/tiannara/probes/results/C2_REMEDIATION_mission_result.json`

| Capability | Status | Note |
|---|---|---|
| C2 Unified Reality Graph (canonical: `Tiannara.World.UnifiedRealityGraph`) | **PROPOSED: R ✓, I ✓, C ✓** (topology-dependent) | C1→C2→C3 verified with single trace envelope under minimal bootstrap AND full production boot; lineage recorded via ExecutiveMemory→EventStore |
| C1 → C2 / C2 → C3 edges | PROPOSED: `✓` | M5 decisive test VERIFIED (single trace id) |
| Legacy `Tiannara.Graph.UnifiedRealityGraph` | orphaned module (NOT ServiceRegistry-registered) | F2 defect retained (rescue-only); not the canonical C2 |
| UnifiedWorldModel shadow check | `?` unchanged | EOS boot still reports `unified_world_model` failed (F9) |

**Proposed disposition (awaiting human ratification):**
- C2 upgraded from `?` to `✓` **conditional on the documented supervised bootstrap topology** (outcome A). Standalone-operability is explicitly NOT claimed.
- DEC-U1-C2-DEFER-003 open question resolved: **by-design** (documented supervised-runtime invariant), not a standalone-operability defect.
- Any adoption of the bootstrap topology into production supervision requires a SEPARATE C14 authorization (C2-ADOPTION-001).

**No production change was made by this mission.**

# U0 Capability Matrix — Post-U7 Update (Homeostasis / C12)

**Probe:** U7 (Homeostasis & Cognitive Immune System), auth-free certification per POL-CERT-AUTH-001
**Contract:** `priv/tiannara/probes/contracts/U7_homeostasis.contract.yaml` (hash `28eb43ab36fd8a06...`)
**Result:** SUCCESS — all phases U7-A (healthy detection), U7-B (fault detection), U7-C (recovery observation), U7-D (F9 false-emergency resistance), U7-E (autonomy boundary) PASS
**Evidence:** `docs/probes/U7_findings.md` + `priv/tiannara/probes/results/U7_homeostasis_result.json`

| Capability / Edge | Status | Note |
|---|---|---|
| C12 Homeostasis/CIS (test topology) | PROPOSED: R ✓, I ✓, C ✓ (test-topology-dependent) | healthy baseline classified HEALTHY; injected ExecutiveMemory fault detected (severity 0.8 → quarantine, FAILED/DEGRADED); recovery proposed log-only, service restored, canonical state + lineage preserved |
| C12 → recovery action | `✓` (observation/proposal only) | RegulationExecutor is log-only; actual restart executed by test harness under `test_topology_bootstrap_allowed` — no mutation authority |
| C12 → telemetry | `✗` | CollapsePredictor.assess_risk/1 returns RANDOM values, not telemetry-derived (F10, NEW) |
| C12 → production | `✗` | CIS.Supervisor NOT in production supervision tree (`whereis` nil in full boot) (F11, NEW) |
| C12 vs F9 (false emergency) | `✓` (resisted) | EOS report claims failed/emergency for LIVE services; no catastrophic recovery triggered from bad telemetry |
| C12 autonomy boundary | `✓` | observation ≠ authorization; no production mutation, no C14 bypass, no adoption artifact minted |

**Bounded claim (NOT a universal one):** under the tested execution path, C12 accurately
detected injected faults and state anomalies (including F9 false-emergency signals) without
executing unauthorized corrective mutations outside the isolated test harness.

**Proposed disposition (awaiting human ratification):**
- C12 upgraded from `?` to `✓` **conditional on the exercised test topology** — production wiring (F11) and telemetry grounding (F10) explicitly NOT claimed.
- F10 (random collapse risk) and F11 (CIS absent from production tree) carried as open defects for disposition with F8/F9.
- Any adoption of CIS into the production supervision tree requires a SEPARATE C14 authorization.

**No production change was made by this probe.**

# U0 Capability Matrix — Post-U7 Ratified Update (Homeostasis / C12)

**Ratification:** DEC-U7-C12-RATIFICATION (2026-08-21, human operator) — ratified as given
**Probe:** U7 (Homeostasis & Cognitive Immune System), auth-free certification per POL-CERT-AUTH-001

```text
C12
  Structural: ✓
  Runtime:    ✓*
  Integration:✓*
  Causal:     ✓*

  * Demonstrated in declared/test topology;
    production supervision integration remains unproven (F11).
```

**Bounded claim (NOT a universal one):** under the tested execution path, C12 accurately
detected injected faults and state anomalies (including F9 false-emergency signals) without
executing unauthorized corrective mutations outside the isolated test harness.

**Disposition of new defects:**
- F10 (CollapsePredictor random risk): OPEN / HIGH PRIORITY — epistemic integrity defect; deferred to post-U8 remediation.
- F11 (CIS.Supervisor absent from production tree): OPEN / ARCHITECTURAL — production residency unproven; dedicated integration mission required post-U8.

**No production change was made by this probe.**

# U0 Capability Matrix — Post-U8 Update (Continuity / C15)

**Probe:** U8 (Continuity & Civilizational Memory), auth-free certification per POL-CERT-AUTH-001
**Contract:** `priv/tiannara/probes/contracts/U8_continuity.contract.yaml` (hash `f8066b67ff029904...`)
**Result:** SUCCESS — U8-1 identity, U8-2 causality, U8-3 epistemic continuity, U8-4 recovery honesty all PASS
**Evidence:** `docs/probes/U8_findings.md` + `priv/tiannara/probes/results/U8_continuity_result.json`

| Capability / Edge | Status | Note |
|---|---|---|
| C15 Continuity (test topology, durable stores) | PROPOSED: R ✓, I ✓, C ✓ (test-topology-dependent) | S0→E→K→kill→S1 verified: identity + causality + knowledge survive catastrophic topology kill via EventStore DETS + file-backed KnowledgeStore |
| C15 Recovery Honesty | ✓ | F8 crash reported explicitly; no fabricated/empty history |
| C7 lineage retrieval | `✗` (F8) | persisted but not retrievable — root cause identified (`{:continue}` leak in `:dets.traverse`) |
| C2 canonical graph across crash | `✗` (volatile) | digraph is in-memory; identity survives in durable event stream, not the graph |
| C12/C7 health telemetry | `✗` (F12, NEW) | `healthy?/0`/`health/0` permanently negative — stale `{:ok,_}` match on `:dets.info/1`; likely F9 contributor |

**Bounded claim (NOT a universal one):** under the tested failure/recovery cycle, the system
preserved canonical identity and causal history; where continuity could not be recovered
(F8), the break was explicitly reported rather than fabricated.

**Proposed disposition (awaiting human ratification):**
- C15 upgraded from `?` to `✓*` (test-topology-conditional, durable-store path; production residency unproven — consistent with the C12 `✓*` convention).
- F12 added as OPEN defect (health telemetry). F8/F9/F10/F11 unchanged.
- Remediation items (F8 lineage retrieval, F10 telemetry-grounded risk, F11 CIS residency, F12 health checks) deferred to dedicated missions; none patched during U8.

**No production change was made by this probe.**

# U0 Capability Matrix — Post-CEL-1 Update (Registry-Driven Delegation)

**Probe:** CEL-1 (Registry-Driven Executive Delegation), auth-free certification per POL-CERT-AUTH-001
**Contract:** `priv/tiannara/probes/contracts/CEL-1_registry_delegation.contract.yaml` (hash `9c7dfc1a293e64b5c61fea18d37a7026eaa9fc5bbd749da90733fdf318ee2fc1`)
**Result:** PASS (bounded, for tested path) — `CEL-1_registry_delegation_result.json`
**Evidence:** `docs/probes/CEL-1_evidence_report.md` + `docs/probes/CEL-1_findings.md`

| Capability / Edge | Status | Note |
|---|---|---|
| CEL-1 Registry-Driven Delegation (tested path: achieve:create_capability → asc) | PROPOSED: `✓` (bounded) | Objective → registry_query → candidate_set → health/ownership → selection → governance_gate → delegation → ExecutiveMemory; no hardcoded shortcut; 4 controls PASS |
| CEL Executive | `?` → PROPOSED: `✓` (integration edge) | Dynamic discovery via `CapabilityRegistry.find_provider/1` demonstrated; not yet universal |
| CapabilityRegistry | `?` → PROPOSED: `✓` (mechanism) / `?` (depth) | Mechanism works (4 providers, health-filtered); depth still static (no interface/tool descriptors, no workload/dependency) |
| C4/C8/C14 → CEL-1 → C9 | PROPOSED: `✓` (integration edge) | C14 governance gate present and causal |

**Bounded claim (NOT a universal one):** under the tested execution path, CEL discovered `asc` via the descriptor `create_capability`, evaluated health/ownership, gated through C14, and delegated via `MissionDirector` — without a hardcoded objective→provider mapping.

**Proposed disposition (awaiting human ratification):**
- CEL-1 edge upgraded to `✓` (bounded, for tested path). The 55% depth finding from `cel.md` remains: registry is still a 4-entry static map, not a live capability discovery system.
- No production change was made by this probe. Remediation for deeper registry depth (interfaces/tools/health/workload) deferred to post-CEL-1 work, gated by evidence.

**No production change was made by this probe.**
