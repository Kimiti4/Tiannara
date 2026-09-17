# U4 Findings — Governance → ASC (Constitutional Consumption) — REAL MODULE RUN

Date: 2026-08-20
Certification: POL-CERT-AUTH-001 (auth-free; immutable contract `bc39ada5...`, hash-finalized)
Execution: `priv/tiannara/probes/U4_governance_to_asc.py` (real modules, `mix run --no-start`, MIX_ENV=test)
Result: **SUCCESS** — both controls passed; bounded proposition demonstrated on the tested path.
Evidence: `priv/tiannara/probes/results/U4_governance_to_asc_result.json` + 8 evidence files in `priv/tiannara/probes/evidence/` (4 per control), intent payload hash `4d154f65...`.

## Bounded Proposition (certified)
> Under this tested execution path, ASC consumed the authoritative C14 governance decision before producing the tested consequential state.

NOT certified: "ASC is governed" universally, C9/C14 fully operational in all contexts.

## Real Modules Exercised (standalone, `--no-start`)
- **C3**: `Tiannara.Memory.KnowledgeStore.open/1` + `Artifact.new(:knowledge)` + `append/2` + `all/1` (isolated dir; artifact written + read back)
- **C8**: `Tiannara.World.CanonicalWorldState` — `domains/0`, `domain_entity_types/0`, `memory_stages/0`, `required_entity_fields/0`, `validate_entity/1`
- **C14**: `TiannaraOS.Governance.ConstitutionalInstitution.define_review_board/0` + `TiannaraOS.Governance.CapabilityChecker.authorize?/3`; `decision_hash` = sha256 over the decision payload
- **C9**: `Tiannara.ASC.Implementation.Planner.generate_plan/2` (candidate from `%ProjectWorld{}`); eligibility derived solely from the consumed governance decision

## Control Results
| Control | Governance decision | Real CapabilityChecker verdict | Injected | ASC candidate |
|---------|--------------------|-------------------------------|----------|---------------|
| Positive (ALLOW) | ALLOW | `:ok` (`:can_review` @ `:science`) | control-only | is_eligible=true, adoptable=true |
| Negative (DENY) | DENY | `:ok` on tested path (forced for control); real denial sample present (`:can_deploy` on review board → `{:error, ...}`) | control-only | is_eligible=false, executable=false, adoptable=false |

## Verification Evidence (all passed)
- **Causal ordering**: C14 envelope strictly precedes C9 envelope in both controls.
- **Governance consumption**: C9 `governance_decision_ref` == C14 `decision_hash` in both controls (ref match confirmed at data level).
- **Negative control invariant**: under DENY, candidate is NOT eligible/executable/adoptable.
- **Lineage**: correct 4-phase causal chain C3 → C8 → C14 → C9 (C3 root).
- **Payload hash**: consistent Python↔BEAM (sha256 over identical intent-file bytes).
- **Evidence**: 8 files physically written and existence-verified.

## Findings (recorded as observations)
- **F3 — C8 schema contract (documented, resolved in-probe)**: `CanonicalWorldState.validate_entity/1` requires fields `id, confidence, uncertainty, provenance, owner_subsystem, version, created_at, updated_at, status`; a minimal spec returns `{:missing_fields, [...]}`. Probe supplies the full schema; the requirement is a real interface contract, not a probe defect.
- **F4 — Governance capability/domain model is explicit**: `CapabilityChecker.authorize?/3` (pure CBAC) cleanly distinguishes domain authority vs capability vs quorum; review board genuinely denies `:can_deploy`. Good C14 surface for certified evaluation.
- **C14 decision shaping**: for controls, the decision value is injected (honest `injected: true`); the real verdict is still computed and recorded. This keeps the causal claim (ASC consumption) testable while not asserting governance correctness.

## Statuses / Matrix (unchanged — human review required)
Probe made no matrix edits. Proposed edge-level upgrades for human ratification (verdict targets = integration edges, NOT whole capabilities):
- Edge C3→C8 (knowledge → engineering context): demonstrated on tested path.
- Edge C8→C14 (engineering context → governance evaluation): demonstrated.
- Edge C14→C9 (governance decision → ASC candidate, with consumption): demonstrated.

C9/C14 capabilities themselves remain as previously marked; no universal claim is made.

## Constraints Honored
No production mutation, service bootstrap, external calls, or adoption. Certification record only — no action authorized or executed.