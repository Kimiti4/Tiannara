# Phase 16.999 — Research Freeze (Final Package Manifest)

## Status

This file is **part of Phase 16 final certification package structure**.

For now it documents:
- what constitutes “freeze” for autonomous constitutional research artifacts
- how freeze manifests reference immutable artifacts
- what replay auditors will consume

No runtime implementation.

---

## Freeze Epoch

- Phase: `16.999`
- Freeze boundary: after all required validation + evidence-only independent audit + long-horizon checks + replay certification.

---

## What Gets Frozen

Frozen eligibility includes:

1. Research ontology and schema contracts
   - `RESEARCH_DATA_MODEL.md`
   - `RESEARCH_SCHEMA_REPORT.md`

2. Replay and certification specs
   - `RESEARCH_REPLAY_MODEL.md`
   - `RESEARCH_CERTIFICATION.md`

3. Research program artifacts (immutable ledgers + content-addressed outputs)
   - Knowledge gaps
   - Questions
   - Research programs
   - Experiment designs/simulation specs
   - Evidence bundles + normalization proofs
   - Statistical validation outputs
   - Theory update proposals
   - Discovery lineage proofs

4. Final certification package artifacts (this directory/phase)
   - RESEARCH_CERTIFICATE.json
   - RESEARCH_FINAL_REPORT.md
   - RESEARCH_PROOF.json
   - RESEARCH_ARCHAEOLOGY.md
   - `PHASE16_FINAL_CERTIFICATION.md`

---

## Freeze Manifest Contract

A freeze manifest must be replayable and reconstruct the set of artifacts eligible for acceptance.

The manifest must include:

- `freeze_epoch`
- `frozen_contract_hashes`
  - hashes of specification documents used
- `research_artifact_manifest`
  - mapping from logical entities → content-addressed IDs
- `replay_coverage_manifest`
  - which replay levels were completed
- `audit_manifest`
  - evidence-only audit certificate id(s)

---

## Required Immutable Artifacts (spec reference)

The freeze boundary may only be asserted when the following artifacts exist (at minimum):

- `RESEARCH_RUNTIME_FREEZE.md`
- `RESEARCH_FREEZE_CERTIFICATE.json` (template/spec record)
- `DISCOVERY_LINEAGE.json` structure (lineage proof format)
- `AUTONOMOUS_RESEARCH_VALIDATION.md`
- `INDEPENDENT_RESEARCH_AUDIT.md`
- `LONG_HORIZON_RESEARCH.md`
- `RESEARCH_READINESS.md`

(Actual issued certificate ids are referenced in RESEARCH_CERTIFICATE.json.)

---

## Summary

`RESEARCH_FREEZE.md` defines the final freeze boundary and the freeze manifest contract for Phase 16 Autonomous Constitutional Research certification.
