# Phase 16.0 Pre-Implementation Constitutional Audit — ARCHAEOLOGY_AUDIT

## Scope
Spec-level audit ensuring Phase 16 research artifacts are archaeologically explainable:

- every research decision is reconstructible
- lineage and provenance exist as immutable references
- auditors can explain “why/from/through which evidence/which certificates”

Audited artifacts:
- `DISCOVERY_LINEAGE.json`
- `RESEARCH_CERTIFICATION.md`
- `PHASE16_FINAL_CERTIFICATION.md`
- (supporting) `RESEARCH_REPLAY_MODEL.md`

---

## Archaeology Audit Checklist

### A1 — Lineage Model Exists
Requirement: there is an explicit lineage model format.

Pass/Fail:
- **PASS**
- `DISCOVERY_LINEAGE.json` defines:
  - node schema
  - `artifact_type`
  - `inputs_hashes`
  - `decision_context_hash`
  - `outputs_hashes`
  - deterministic `parents` reference

---

### A2 — Reconstructability Path Exists
Requirement: replay + lineage allow reconstruction of derivations.

Pass/Fail:
- **PASS**
- `RESEARCH_REPLAY_MODEL.md` explicitly requires archaeological reconstruction:
  - why question generated
  - from which knowledge gap
  - which scoring prioritized
  - which program plan + evidence mapping
  - evidence → validation → theory proposal → certification prerequisites

---

### A3 — Evidence-to-Decision Mapping Required
Requirement: decisions must cite evidence and statistical validation artifacts.

Pass/Fail:
- **PASS (spec intent)**
- `RESEARCH_CERTIFICATION.md` defines evidence-first gates and archaeology closure rules.
- Note: the concrete mapping fields for evidence-to-integration are to be finalized when `ResearchOutcome` and audit artifacts exist (runtime later).

---

### A4 — Certificate References Are Enforced in Explanation
Requirement: archaeology must reference which certificates gated acceptance.

Pass/Fail:
- **PASS**
- `PHASE16_FINAL_CERTIFICATION.md` requires:
  - replay certification artifacts
  - independent evidence-only audit artifacts
  - lineage proofs referenced by RESEARCH_PROOF.json / RESEARCH_ARCHAEOLOGY.md (future outputs)

---

### A5 — Deterministic Lineage Parent Ordering
Requirement: lineage parents must be deterministic for replay.

Pass/Fail:
- **PASS**
- `DISCOVERY_LINEAGE.json` states:
  - parent ordering must be deterministic (sorted by parent lineage_node_id)

---

## Findings

### F1 — Future Archaeology Outputs Not Yet Present
- RESEARCH_ARCHAEOLOGY.md is not present yet (expected future output).
- Severity: **BLOCKER** if you require “full end-to-end archaeology artifact availability” at spec stage.
- Otherwise: **WARNING** because lineage model + reconstruction contract exist already.

---

## Conclusion

Phase 16 archaeology is **constitutionally specified**:

- lineage model exists
- replay model defines archaeological reconstruction requirements
- certification/gating rules require evidence-only audit and certificate gating

Remaining gap for “full package archaeology” is the creation of the actual future output files during validation/certification phases.
