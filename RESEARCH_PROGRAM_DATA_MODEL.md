# Phase 17.8.0 — Research Program Data Model (CAR)

document_version: 17.8.0
phase: 17.8
status: Architecture Review
owner: Constitutional Research Council
depends_on:
  - AUTONOMOUS_RESEARCH_PROGRAM_ARCHITECTURE.md
  - RESEARCH_EXECUTION_PIPELINE.md
  - RESEARCH_DATA_MODEL.md (Phase 16.1 — extended, not replaced)
  - MATHEMATICS_DATA_MODEL.md
  - digital_twin/twin_state.ex (Phase 17.7.1)
  - digital_twin/simulation_outcome.ex (Phase 17.7.1)
supersedes: null

---

## Purpose

This document specifies the Phase 17.8 data model as an architecture-level definition.

It extends Phase 16.1 schemas with Phase 17.8-specific fields and introduces new
entity types required by the ARPE subsystem.

This is a constitutional architecture document. Schema validation, content-addressed ID
implementation, and serialization contracts are defined in Phase 17.8.1 (Ontology).
No implementation is introduced here.

---

## Inheritance Principle

Phase 17.8 does NOT redefine Phase 16.1 schemas.

All Phase 16.1 schemas are used verbatim:
- KnowledgeGap (extended with twin_provenance, see below)
- ResearchQuestion (used verbatim)
- ResearchExperiment (extended with SimulationScenario binding, see below)
- ResearchEvidence (extended with twin_outcome_provenance, see below)
- ResearchStatisticalValidation (used verbatim)
- ResearchTheoryUpdateProposal (used verbatim)
- ResearchProgram (used verbatim)
- DiscoveryLineage (used verbatim)

Schema extensions add fields under a `"phase_17_8_ext"` namespace to preserve
backward compatibility with Phase 16 validators.

---

## New Entity Types (Phase 17.8 Only)

These entities have no Phase 16 equivalent.

---

### 1) ExperimentPortfolio

The selected set of programs and experiments to run in a given scheduling epoch.

```json
{
  "portfolio_id": "blake3_hash",
  "schema_version": "17.8.0",
  "timestamp": "ISO8601",
  "epoch_id": "blake3_hash",
  "config_hash": "blake3_hash",
  "selected_program_ids": ["blake3_hash"],
  "selected_experiment_ids": ["blake3_hash"],
  "diversity_score": "float",
  "expected_total_information_gain": "float",
  "optimization_proof_hash": "blake3_hash",
  "budget_allocation_id": "blake3_hash",
  "selection_rationale_hash": "blake3_hash"
}
```

Content-addressed ID derivation:
`portfolio_id = blake3(canonical(epoch_id + selected_program_ids + config_hash))`

---

### 2) ExperimentBudget

The per-program resource allocation for a portfolio epoch.

```json
{
  "budget_id": "blake3_hash",
  "schema_version": "17.8.0",
  "timestamp": "ISO8601",
  "portfolio_id": "blake3_hash",
  "total_compute_units": "number",
  "total_evidence_units": "number",
  "per_program_allocations": [
    {
      "program_id": "blake3_hash",
      "compute_units": "number",
      "evidence_units": "number",
      "max_experiments": "number",
      "priority_rank": "integer"
    }
  ],
  "allocation_algorithm_version": "string",
  "allocation_proof_hash": "blake3_hash"
}
```

---

### 3) ExperimentSchedule

The ordered dispatch plan for a portfolio's experiments.

```json
{
  "schedule_id": "blake3_hash",
  "schema_version": "17.8.0",
  "timestamp": "ISO8601",
  "portfolio_id": "blake3_hash",
  "budget_id": "blake3_hash",
  "dispatch_intents": [
    {
      "intent_id": "blake3_hash",
      "experiment_id": "blake3_hash",
      "dispatch_mode": "SEQUENTIAL|PARALLEL|DEPENDENT|ADAPTIVE",
      "depends_on_intent_ids": ["blake3_hash"],
      "stopping_criteria": [
        {
          "criterion_type": "string",
          "threshold": "number",
          "direction": "UP|DOWN|REACH"
        }
      ],
      "scenario_id": "blake3_hash"
    }
  ],
  "schedule_algorithm_version": "string",
  "schedule_fingerprint": "blake3_hash"
}
```

---

### 4) SimulationScenarioBinding

The Phase 17.8 artifact that binds a ResearchExperiment to a Digital Twin SimulationScenario.

```json
{
  "binding_id": "blake3_hash",
  "schema_version": "17.8.0",
  "timestamp": "ISO8601",
  "experiment_id": "blake3_hash",
  "program_id": "blake3_hash",
  "scenario": {
    "name": "string",
    "initial_conditions": {},
    "events": [],
    "interventions": [],
    "total_ticks": "integer",
    "metrics_config": ["string"]
  },
  "variable_mappings": [
    {
      "experiment_variable": "string",
      "twin_state_path": "string",
      "mutation_type": "INITIAL_CONDITION|EVENT|INTERVENTION"
    }
  ],
  "evidence_observable_mappings": [
    {
      "experiment_measurement_key": "string",
      "twin_outcome_field": "string",
      "normalization_transform": "string"
    }
  ],
  "stopping_condition_mappings": [
    {
      "experiment_criterion": "string",
      "twin_metric": "string",
      "direction": "UP|DOWN|REACH",
      "threshold": "number"
    }
  ],
  "deterministic_seed": "blake3_hash"
}
```

Content-addressed ID derivation:
`binding_id = blake3(canonical(experiment_id + scenario + variable_mappings + deterministic_seed))`

---

### 5) ResearchOutcome

The final disposition of a completed research program.

```json
{
  "outcome_id": "blake3_hash",
  "schema_version": "17.8.0",
  "timestamp": "ISO8601",
  "program_id": "blake3_hash",
  "disposition": "COMPLETED|TERMINATED|SUPERSEDED|ARCHIVED|PROVISIONAL_ARCHIVE",
  "termination_reason": "SUCCESS|BUDGET_EXHAUSTED|STOPPING_CRITERION_MET|CONTRADICTION_DETECTED|CONSTITUTIONAL_VIOLATION|MATHEMATICAL_UNVERIFIED",
  "completed_experiment_ids": ["blake3_hash"],
  "evidence_bundle_ids": ["blake3_hash"],
  "validation_ids": ["blake3_hash"],
  "theory_proposal_ids": ["blake3_hash"],
  "replay_fingerprint_id": "blake3_hash",
  "certificate_id": "blake3_hash | null",
  "archaeology_record_id": "blake3_hash",
  "total_compute_units_consumed": "number",
  "total_evidence_units_consumed": "number"
}
```

---

### 6) ProgramReplayFingerprint

The replay certification artifact for a complete research program.

```json
{
  "fingerprint_id": "blake3_hash",
  "schema_version": "17.8.0",
  "timestamp": "ISO8601",
  "program_id": "blake3_hash",
  "replay_levels_achieved": ["LEVEL1", "LEVEL2", "LEVEL3"],
  "merkle_root": "blake3_hash",
  "artifact_ids_replayed": ["blake3_hash"],
  "divergence_report": null,
  "divergence_report_id": "blake3_hash | null",
  "replay_algorithm_version": "string",
  "replay_config_hash": "blake3_hash"
}
```

---

### 7) ProgramArchaeologyRecord

Complete explainability record for a research program.

```json
{
  "archaeology_id": "blake3_hash",
  "schema_version": "17.8.0",
  "timestamp": "ISO8601",
  "program_id": "blake3_hash",
  "originating_gap_ids": ["blake3_hash"],
  "question_id": "blake3_hash",
  "planning_decision_hash": "blake3_hash",
  "planning_algorithm_version": "string",
  "experiment_lineage": [
    {
      "experiment_id": "blake3_hash",
      "binding_id": "blake3_hash",
      "outcome_id": "blake3_hash",
      "evidence_bundle_ids": ["blake3_hash"]
    }
  ],
  "theory_update_lineage": [
    {
      "proposal_id": "blake3_hash",
      "operation": "string",
      "evidence_ids": ["blake3_hash"],
      "validation_ids": ["blake3_hash"]
    }
  ],
  "resource_allocation": {
    "budget_id": "blake3_hash",
    "total_compute_used": "number",
    "total_evidence_used": "number"
  },
  "math_verification_ids": ["blake3_hash"],
  "replay_fingerprint_id": "blake3_hash",
  "explanation_completeness": "COMPLETE|PARTIAL|INCOMPLETE",
  "missing_explanation_nodes": ["string"]
}
```

---

### 8) MathematicalVerificationResult

Result of Phase 16.X Mathematics Substrate verification for an experiment.

```json
{
  "verification_id": "blake3_hash",
  "schema_version": "17.8.0",
  "timestamp": "ISO8601",
  "experiment_id": "blake3_hash",
  "verification_status": "VERIFIED|MATHEMATICALLY_UNVERIFIED|VERIFICATION_FAILED",
  "checks_performed": [
    {
      "check_type": "STATISTICAL_POWER|DIMENSIONAL_CONSISTENCY|SAMPLING_PLAN|OPTIMIZATION_CONSTRAINTS|SYMBOLIC_INVARIANTS",
      "result": "PASS|FAIL|UNVERIFIED",
      "proof_hash": "blake3_hash | null",
      "failure_reason": "string | null"
    }
  ],
  "substrate_version": "string",
  "substrate_certified": "boolean",
  "verification_config_hash": "blake3_hash"
}
```

---

### 9) ARPECertificate

The final constitutional certificate for a research program.

```json
{
  "certificate_id": "blake3_hash",
  "schema_version": "17.8.0",
  "timestamp": "ISO8601",
  "program_id": "blake3_hash",
  "outcome_id": "blake3_hash",
  "replay_fingerprint_id": "blake3_hash",
  "archaeology_record_id": "blake3_hash",
  "independent_audit_id": "blake3_hash",
  "math_verification_id": "blake3_hash",
  "statistical_validation_ids": ["blake3_hash"],
  "phase_16_upstream_status": "CERTIFIED|WITHHELD|PENDING",
  "issuer_id": "string",
  "issuer_signature": "ed25519_signature",
  "certificate_status": "CERTIFIED|PROVISIONAL|WITHHELD"
}
```

---

## Phase 16.1 Schema Extensions (Phase 17.8 namespace)

These are additive extensions under `phase_17_8_ext`. They do not modify Phase 16.1 fields.

### KnowledgeGap extension

```json
{
  "phase_17_8_ext": {
    "gap_source": "WORLD_MODEL|CAUSAL_GRAPH|PREDICTION_RESIDUAL|COUNTERFACTUAL|COMPOSITION_INCONSISTENCY",
    "twin_provenance_hash": "blake3_hash",
    "source_snapshot_hashes": {
      "world_model_snapshot": "blake3_hash | null",
      "causal_graph_snapshot": "blake3_hash | null",
      "prediction_residual_snapshot": "blake3_hash | null",
      "counterfactual_snapshot": "blake3_hash | null",
      "composition_snapshot": "blake3_hash | null"
    }
  }
}
```

### ResearchExperiment extension

```json
{
  "phase_17_8_ext": {
    "simulation_scenario_binding_id": "blake3_hash",
    "twin_executable": "boolean",
    "math_verification_id": "blake3_hash | null"
  }
}
```

### ResearchEvidence extension

```json
{
  "phase_17_8_ext": {
    "twin_outcome_id": "blake3_hash",
    "simulation_fingerprint": "blake3_hash",
    "normalization_proof_hash": "blake3_hash"
  }
}
```

---

## Content-addressed ID Rules

All Phase 17.8 entities follow Phase 16.1 ID rules verbatim:

`artifact_id = blake3(canonical_json(artifact_without_artifact_id))`

Canonical JSON rules:
1. Stable key ordering (lexicographic)
2. No NaN, Infinity, or locale-dependent number formatting
3. Null vs missing fields are canonicalized per schema definition
4. Arrays are ordered as specified in the schema

---

## Ownership Summary

| Entity | Owner | Mutable After Creation |
|---|---|---|
| ExperimentPortfolio | ARPEPortfolioManager | No |
| ExperimentBudget | ARPEBudgetAllocator | No |
| ExperimentSchedule | ARPEScheduler | No |
| SimulationScenarioBinding | ARPEExperimentPlanner | No |
| ResearchOutcome | ARPEProgramEngine | No |
| ProgramReplayFingerprint | ARPEReplayEngine | No |
| ProgramArchaeologyRecord | ARPEArchaeologyRegistry | No (append for partial records) |
| MathematicalVerificationResult | ARPEMathVerifier | No |
| ARPECertificate | ConstitutionalCertificateAuthority | No |

No entity is mutable after creation. Revisions produce new artifacts with new IDs.

---

## No Implementation Note

This document defines the data model at the architecture level only.

Schema validation, serialization, canonical ID implementation, and struct definitions
are introduced in Phase 17.8.1 (Ontology).

Phase 17.8.05 (Constitutional Freeze) freezes these schema contracts before
any implementation begins.
