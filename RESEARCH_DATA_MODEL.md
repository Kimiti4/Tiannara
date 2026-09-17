# Phase 16.1 — Research Ontology (Data Model)

## Overview

This document specifies the **research ontology** for Phase 16 Autonomous Constitutional Research.

Maturity discipline:
- **Architecture** is defined in `AUTONOMOUS_RESEARCH_ARCHITECTURE.md`
- **Pipeline structure** is defined in `RESEARCH_PIPELINE.md`
- This file defines the **specification-level ontology**: schemas/structs/validators/serialization contracts.

No implementation is introduced in Phase 16.1.

---

## Frozen ID Principle (Content-addressed IDs)

Every artifact representing a conceptual object MUST have a deterministic content-addressed ID:

- `artifact_id = blake3_hash(canonical_serialization(artifact_without_artifact_id))`

Canonical serialization rules:
1. stable key ordering
2. fixed number formatting strategy (e.g., canonical JSON number formatting)
3. deterministic array ordering OR explicit ordering keys are modeled
4. no hidden/implicit fields

---

## Core Schema Set

### 1) ResearchQuestion

An autonomous research question derived from an explicit knowledge gap.

```json
{
  "question_id": "blake3_hash",
  "schema_version": "16.1.0",
  "timestamp": "ISO8601",
  "knowledge_gap_id": "blake3_hash",
  "title": "string",
  "description": "string",
  "expected_uncertainty_reduction": "float",
  "estimated_impact": "float",
  "estimated_cost": {
    "compute_units": "number",
    "evidence_budget": "number"
  },
  "dependencies": ["blake3_hash"],
  "required_validation_types": ["STATISTICAL", "ROBUSTNESS", "REPLAY", "AUDIT"],
  "stopping_criteria": [
    {
      "criterion_type": "string",
      "threshold": "number",
      "direction": "UP|DOWN|REACH"
    }
  ],
  "priority_hint": {
    "novelty": "float",
    "feasibility": "float"
  }
}
```

---

### 2) KnowledgeGap

Explicit missing/contradictory/uncertain knowledge that motivates research.

```json
{
  "knowledge_gap_id": "blake3_hash",
  "schema_version": "16.1.0",
  "timestamp": "ISO8601",
  "gap_type": "UNCERTAINTY|CONTRADICTION|MISSING_EVIDENCE|FAILED_PREDICTION|ENGINEERING_BLOCKER",
  "domain": "string",
  "description": "string",
  "current_confidence": "float",
  "target_confidence": "float",
  "evidence_requirements": [
    {
      "evidence_type": "string",
      "minimum_quantity": "number",
      "required_quality": "string"
    }
  ],
  "contradicting_claim_ids": ["blake3_hash"],
  "unresolved_prediction_ids": ["blake3_hash"],
  "engineering_bottleneck": {
    "description": "string",
    "constraints": ["string"]
  }
}
```

---

### 3) ResearchExperiment

An experiment design and/or simulation plan needed to collect evidence.

```json
{
  "experiment_id": "blake3_hash",
  "schema_version": "16.1.0",
  "timestamp": "ISO8601",
  "research_program_id": "blake3_hash",
  "experiment_type": "REAL_RUN|SIMULATION|HYBRID",
  "measurement_definitions": [
    {
      "measurement_key": "string",
      "observable": "string",
      "units": "string",
      "expected_signal_scale": "float"
    }
  ],
  "sampling_plan": {
    "sample_strategy": "string",
    "sample_size_target": "number",
    "seeds": {
      "deterministic_seed_source": "blake3_hash"
    }
  },
  "robustness_design": {
    "assumptions_to_stress": ["string"],
    "sensitivity_metrics": ["string"]
  },
  "evidence_to_measurement_mapping": [
    {
      "evidence_field": "string",
      "measurement_key": "string",
      "transform_spec": "string"
    }
  ],
  "expected_evidence_schema": "blake3_hash"
}
```

---

### 4) ResearchEvidence

Normalized and bundled evidence produced from executed experiments (later implementation).

```json
{
  "evidence_bundle_id": "blake3_hash",
  "schema_version": "16.1.0",
  "timestamp": "ISO8601",
  "experiment_id": "blake3_hash",
  "evidence_type": "RAW|NORMALIZED",
  "evidence_schema_id": "blake3_hash",
  "provenance": {
    "source_artifact_ids": ["blake3_hash"],
    "capture_context": {
      "environment_snapshot_hash": "blake3_hash"
    }
  },
  "evidence_records": [
    {
      "record_id": "blake3_hash",
      "record_type": "string",
      "content_hash": "blake3_hash",
      "content_pointer": "content_addressed://blake3/..."
    }
  ],
  "normalization_proof": {
    "normalizer_id": "string",
    "normalization_rules_hash": "blake3_hash"
  }
}
```

---

### 5) ResearchStatisticalValidation

Deterministic statistical validation outputs produced from evidence bundles.

```json
{
  "validation_id": "blake3_hash",
  "schema_version": "16.1.0",
  "timestamp": "ISO8601",
  "evidence_bundle_id": "blake3_hash",
  "validation_types": ["FREQUENTIST", "BAYESIAN", "META_ANALYSIS", "ROBUSTNESS"],
  "statistical_result_hashes": ["blake3_hash"],
  "power_requirements": {
    "alpha": "float",
    "target_power": "float"
  },
  "robustness_summary": {
    "assumption_stability_score": "float",
    "sensitivity_outcomes_hash": "blake3_hash"
  },
  "conclusion": "SUPPORTED|FALSIFIED|INCONCLUSIVE",
  "uncertainty_reduction_estimate": "float"
}
```

---

### 6) ResearchTheoryUpdateProposal

A proposed theory update derived from validated results (integration gated by certificates).

```json
{
  "theory_proposal_id": "blake3_hash",
  "schema_version": "16.1.0",
  "timestamp": "ISO8601",
  "research_program_id": "blake3_hash",
  "operation": "NEW|REVISE|SUPERSEDE|CONTRADICT|MERGE|DEPRECATE",
  "target_theory_id": "blake3_hash",
  "previous_theory_hash": "blake3_hash|null",
  "justification_hash": "blake3_hash",
  "supporting_evidence_validation_ids": ["blake3_hash"],
  "supporting_discovery_ids": ["blake3_hash"],
  "contradicting_evidence_ids": ["blake3_hash"],
  "replay_prerequisites": {
    "required_replay_levels": ["LEVEL1", "LEVEL2"]
  },
  "certificate_prerequisites": {
    "required_certificate_types": ["DISCOVERY", "REPLAY", "AUDIT"]
  }
}
```

---

### 7) ResearchProgram

A planned autonomous research program with objectives, milestones, experiments, evidence requirements, and stopping criteria.

```json
{
  "research_program_id": "blake3_hash",
  "schema_version": "16.1.0",
  "timestamp": "ISO8601",
  "primary_question_id": "blake3_hash",
  "portfolio_rank_hint": "number",
  "objectives": [
    {
      "objective_key": "string",
      "description": "string"
    }
  ],
  "milestones": [
    {
      "milestone_key": "string",
      "expected_evidence_bundle_id": "blake3_hash|null",
      "stopping_rule_reference": "string"
    }
  ],
  "experiments": ["blake3_hash"],
  "evidence_requirements": [
    {
      "evidence_type": "string",
      "minimum_quantity": "number",
      "required_quality": "string"
    }
  ],
  "statistical_requirements": {
    "alpha": "float",
    "target_power": "float",
    "confidence_interval_target": "float"
  },
  "stopping_criteria": [
    {
      "criterion_type": "string",
      "threshold": "number",
      "direction": "UP|DOWN|REACH"
    }
  ],
  "resource_constraints": {
    "max_compute_units": "number",
    "max_experiments": "number"
  }
}
```

---

## Discovery Lineage (Fragment Schema)

A lineage node records replayable traceability for decisions and artifacts.

```json
{
  "lineage_node_id": "blake3_hash",
  "schema_version": "16.1.0",
  "timestamp": "ISO8601",
  "artifact_type": "KNOWLEDGE_GAP|QUESTION|PROGRAM|EXPERIMENT|EVIDENCE|VALIDATION|THEORY_PROPOSAL|OUTCOME|CERTIFICATE",
  "artifact_id": "blake3_hash",
  "inputs_hashes": ["blake3_hash"],
  "decision_context_hash": "blake3_hash",
  "outputs_hashes": ["blake3_hash"],
  "parents": ["lineage_node_id"]
}
```

---

## Validation & Serialization (Spec-level)

Each schema is validated by:
1. shape correctness (JSON schema / struct validator)
2. ID correctness (content-addressed determinism)
3. cross-reference correctness (IDs refer to immutable artifacts later)
4. certificate compatibility (references only types available in Phase 16 certification scheme)

---

*Phase 16.1 defines schemas/serialization contracts only. Implementation is deferred until later phases after constitutional freeze.*
