# Discovery Pipeline Specification

## Overview

This document specifies the complete discovery pipeline for Phase 15, from observation ingestion through theory evolution. The pipeline is designed as a series of deterministic, registry-driven stages with full provenance tracking and replay capability.

---

## Pipeline Stages

```
┌─────────────┐   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│   INGEST    │──►│  PATTERN    │──►│ HYPOTHESIS  │──►│  EXPERIMENT │──►│   EVIDENCE  │──►│  DISCOVERY  │──►│   THEORY    │
│  OBSERVATION│   │  DETECTION  │   │  FORMATION  │   │   DESIGN    │   │ COLLECTION  │   │   │ VALIDATION │   │ EVOLUTION   │
└─────────────┘   └─────────────┘   └─────────────┘   └─────────────┘   └─────────────┘   └─────────────┘   └─────────────┘
      │               │               │               │               │               │               │
      ▼               ▼               ▼               ▼               ▼               ▼               ▼
┌─────────────┐   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│  OBSERVATION│   │  PATTERN    │   │ HYPOTHESIS  │   │ EXPERIMENT  │   │  EVIDENCE   │   │ DISCOVERY   │   │   THEORY    │
│   REGISTRY  │   │  REGISTRY   │   │  REGISTRY   │   │  REGISTRY   │   │   LEDGER    │   │  REGISTRY   │   │   ENGINE    │
└─────────────┘   └─────────────┘   └─────────────┘   └─────────────┘   └─────────────┘   └─────────────┘   └─────────────┘
```

---

## Stage 1: Observation Ingestion

### Input Sources
1. **Sensor Observations**: Raw data from physical/virtual sensors
2. **Simulation Observations**: Outputs from computational models
3. **Human Observations**: Annotated observations from domain experts
4. **Derived Observations**: Computed from other observations (transformations, aggregations)

### Observation Schema
```json
{
  "observation_id": "blake3_hash",
  "timestamp": "ISO8601",
  "observer_id": "agent_id|civilization_id|sensor_id",
  "observation_type": "sensor|simulation|human|derived",
  "domain": "physics|biology|chemistry|computer_science|...",
  "raw_data_ref": "content_addressed_blob_hash",
  "processed_data": "inline_or_ref",
  "metadata": {
    "instrument": "string",
    "conditions": "object",
    "uncertainty": "float",
    "coordinates": "spacetime_coordinates",
    "tags": ["string"]
  },
  "context_hash": "blake3_hash_of_experimental_context",
  "provenance": {
    "source_observation_ids": ["blake3_hash"],
    "transformation": "description_if_derived",
    "pipeline_version": "semver"
  }
}
```

### Ingestion Process
1. **Validate**: Schema compliance, observer authorization, data integrity
2. **Fingerprint**: Compute Blake3 hash of canonical observation
3. **Deduplicate**: Check registry for existing hash (idempotent)
4. **Register**: Append to Observation Registry with merkle proof
5. **Index**: Update domain indexes, time-series indexes, observer indexes
6. **Emit Event**: `ObservationRegistered` event for downstream consumers

### Determinism Guarantees
- Same input → Same observation_id (content-addressed)
- Registration order determined by timestamp + hash tiebreaker
- No side effects during ingestion

---

## Stage 2: Pattern Detection

### Purpose
Automatically detect patterns, anomalies, correlations, and regularities in registered observations that may warrant hypothesis formation.

### Detection Algorithms
1. **Statistical Anomaly Detection**: Z-score, isolation forest, spectral residuals
2. **Correlation Mining**: Pairwise, partial, canonical correlation analysis
3. **Clustering**: Density-based, hierarchical, spectral clustering
4. **Time Series Patterns**: Seasonality, trends, regime changes, recurrences
5. **Symbolic Regression**: Equation discovery from observational data
6. **Causal Discovery**: PC algorithm, FCI, NOTEARS, Granger causality

### Pattern Schema
```json
{
  "pattern_id": "blake3_hash",
  "pattern_type": "anomaly|correlation|cluster|trend|equation|causal",
  "source_observation_ids": ["blake3_hash"],
  "detection_algorithm": "algorithm_name_version",
  "parameters": "algorithm_specific_parameters",
  "statistics": {
    "significance": "p_value_or_bayes_factor",
    "effect_size": "float",
    "confidence_interval": [low, high],
    "reproducibility_score": "float"
  },
  "description": "human_readable_description",
  "detected_at": "ISO8601",
  "detector_id": "agent_id|civilization_id|autonomous_engine_id"
}
```

### Pattern Registry
- Patterns registered in Pattern Registry (sub-registry of Observation Registry)
- Each pattern links to source observations via content hashes
- Patterns are immutable once registered
- Pattern confidence evolves with new observations (new pattern versions)

---

## Stage 3: Hypothesis Formation

### Purpose
Generate falsifiable scientific hypotheses from detected patterns and existing knowledge.

### Hypothesis Generation Strategies
1. **Pattern-Driven**: Direct hypothesis from pattern (e.g., "Correlation X implies causation Y")
2. **Theory-Driven**: Deduction from existing theories (e.g., "Theory T predicts phenomenon P")
3. **Analogical**: Transfer from similar domains (e.g., "Domain A exhibits X, so Domain B may too")
4. **Abductive**: Best explanation for observations (e.g., "Mechanism M explains observations O")
5. **Counterfactual**: "If condition C held, outcome O would occur"
6. **Autonomous**: Generated by ASC agents with research genomes

### Hypothesis Schema
```json
{
  "hypothesis_id": "blake3_hash",
  "hypothesis_text": "formal_statement_in_logic_or_natural_language",
  "hypothesis_type": "causal|correlational|mechanistic|predictive|explanatory",
  "origin": {
    "strategy": "pattern_driven|theory_driven|analogical|abductive|counterfactual|autonomous",
    "source_pattern_ids": ["blake3_hash"],
    "source_theory_ids": ["blake3_hash"],
    "generator_id": "agent_id|civilization_id|engine_id"
  },
  "falsification_criteria": {
    "type": "statistical|logical|observational|experimental",
    "threshold": "p_value|effect_size|logical_contradiction|observation_set",
    "required_evidence": "description_of_evidence_needed_to_falsify"
  },
  "predicted_outcomes": [
    {
      "condition": "experimental_condition",
      "prediction": "quantitative_or_qualitative_prediction",
      "confidence": "float"
    }
  ],
  "scope": {
    "domain": "string",
    "applicability_conditions": "object",
    "limitations": "string"
  },
  "state": "PROPOSED|TESTING|SUPPORTED|FALSIFIED|INCONCLUSIVE|RETRACTED",
  "version": 1,
  "parent_hypothesis_id": "blake3_hash_if_revision",
  "created_at": "ISO8601",
  "updated_at": "ISO8601"
}
```

### Hypothesis State Machine
```
PROPOSED ──(experiment_designed)──► TESTING
TESTING ──(evidence_supports)──► SUPPORTED
TESTING ──(evidence_falsifies)──► FALSIFIED
TESTING ──(insufficient_evidence)──► INCONCLUSIVE
SUPPORTED ──(new_contradictory_evidence)──► FALSIFIED
SUPPORTED ──(refined)──► PROPOSED (new version)
FALSIFIED ──(revision)──► PROPOSED (new version)
INCONCLUSIVE ──(new_experiment)──► TESTING
```

### Registration
- Hypotheses registered in Hypothesis Registry
- Content-addressed by hypothesis_id (hash of canonical form)
- State transitions recorded as immutable events
- Versioning creates new content-addressed entries

---

## Stage 4: Experiment Design

### Purpose
Design rigorous experiments to test hypotheses with appropriate statistical power and controls.

### Experiment Design Schema
```json
{
  "experiment_id": "blake3_hash",
  "hypothesis_id": "blake3_hash",
  "design": {
    "protocol": "detailed_experimental_protocol",
    "independent_variables": [
      {"name": "string", "type": "continuous|categorical", "levels": "values_or_range"}
    ],
    "dependent_variables": [
      {"name": "string", "type": "continuous|categorical|ordinal", "measurement": "method"}
    ],
    "controls": [
      {"variable": "string", "control_type": "negative|positive|placebo|sham", "value": "control_value"}
    ],
    "randomization": "method_description",
    "blinding": "single|double|triple|none",
    "sample_size": {
      "calculation_method": "power_analysis|precision|resource_constrained",
      "power": 0.8,
      "alpha": 0.05,
      "effect_size": "expected_effect_size",
      "n_per_group": "integer"
    },
    "stopping_rules": {
      "futility": "condition",
      "efficacy": "condition",
      "safety": "condition"
    }
  },
  "predicted_results": {
    "primary_outcome": "prediction_with_confidence_interval",
    "secondary_outcomes": ["predictions"],
    "effect_sizes": "object"
  },
  "resources": {
    "compute": "resource_specification",
    "instruments": ["instrument_specs"],
    "duration_estimate": "ISO8601_duration",
    "cost_estimate": "capital_units"
  },
  "designer_id": "agent_id|civilization_id",
  "design_version": 1,
  "parent_design_id": "blake3_hash_if_revision",
  "created_at": "ISO8601"
}
```

### Design Validation
1. **Statistical Validity**: Power analysis, Type I/II error control
2. **Logical Validity**: Experiment actually tests hypothesis
3. **Feasibility**: Resources available, ethical compliance
4. **Reproducibility**: Protocol sufficiently detailed for independent replication

### Registration
- Designs registered in Experiment Registry (DESIGN phase)
- Immutable once registered
- Revisions create new experiment_id

---

## Stage 5: Experiment Execution

### Purpose
Execute designed experiments and collect evidence in a deterministic, replayable manner.

### Execution Process
1. **Schedule**: Allocate resources, reserve instruments, queue execution
2. **Snapshot Environment**: Capture complete runtime state (memory, RNG, clock, versions)
3. **Execute**: Run protocol steps in deterministic order
4. **Collect Evidence**: Stream evidence to Evidence Engine
5. **Record Execution**: Log every step, measurement, decision
6. **Snapshot Final State**: Capture post-execution state

### Execution Schema
```json
{
  "execution_id": "blake3_hash",
  "experiment_id": "blake3_hash",
  "design_hash": "blake3_hash_of_design_at_execution_time",
  "executor_id": "agent_id|civilization_id|autonomous_engine_id",
  "environment_snapshot": {
    "runtime_hash": "blake3_hash_of_runtime_state",
    "rng_state": "serialized_rng_state",
    "clock_offset": "float",
    "software_versions": {"component": "version"},
    "hardware_fingerprint": "hash"
  },
  "timeline": [
    {
      "step": "integer",
      "timestamp": "ISO8601",
      "action": "protocol_step_description",
      "input_hashes": ["blake3_hash"],
      "output_hashes": ["blake3_hash"],
      "evidence_ids": ["blake3_hash"],
      "decisions": ["decision_record"]
    }
  ],
  "evidence_collected": ["blake3_hash"],
  "execution_status": "COMPLETED|FAILED|ABORTED|PAUSED",
  "started_at": "ISO8601",
  "completed_at": "ISO8601",
  "resource_consumption": {"compute": "units", "time": "duration"}
}
```

### Determinism Requirements
- **Fixed Execution Order**: Steps executed in protocol-defined sequence
- **Deterministic RNG**: Seeded from experiment_id + step number
- **No External Dependencies**: All inputs content-addressed and frozen
- **Replay Verification**: Execution must be exactly replayable

### Registration
- Executions appended to Experiment Registry (EXECUTION phase)
- Linked to design via design_hash
- Evidence registered separately in Evidence Ledger

---

## Stage 6: Evidence Collection & Analysis

### Purpose
Centralized evidence management with statistical analysis and fingerprinting.

### Evidence Schema
```json
{
  "evidence_id": "blake3_hash",
  "execution_id": "blake3_hash",
  "evidence_type": "raw_measurement|processed_data|statistical_result|derived_quantity",
  "data_ref": "content_addressed_blob_hash",
  "schema": "data_schema_version",
  "metadata": {
    "measurement_instrument": "string",
    "conditions": "object",
    "uncertainty": "float",
    "coordinates": "spacetime_coordinates"
  },
  "processing_chain": [
    {
      "step": "integer",
      "operation": "transform|aggregate|filter|model_fit",
      "code_hash": "blake3_hash_of_code",
      "input_hashes": ["blake3_hash"],
      "output_hash": "blake3_hash",
      "parameters": "object"
    }
  ],
  "fingerprint": "blake3_hash_of_canonical_evidence",
  "collector_id": "agent_id|civilization_id",
  "collected_at": "ISO8601"
}
```

### Statistical Analysis Pipeline
1. **Descriptive Statistics**: Mean, variance, distribution characterization
2. **Inferential Statistics**: Hypothesis tests, confidence intervals, effect sizes
3. **Bayesian Analysis**: Posterior distributions, Bayes factors, model comparison
4. **Robustness Checks**: Sensitivity analysis, outlier detection, assumption validation
5. **Meta-Analysis**: If multiple experiments, combine evidence

### Statistical Result Schema
```json
{
  "statistical_result_id": "blake3_hash",
  "evidence_ids": ["blake3_hash"],
  "analysis_type": "frequentist|bayesian|meta_analysis|robustness",
  "method": "specific_test_or_model_name",
  "parameters": "method_parameters",
  "results": {
    "test_statistic": "float",
    "p_value": "float",
    "confidence_interval": [low, high],
    "effect_size": "float",
    "bayes_factor": "float",
    "posterior": "distribution_specification"
  },
  "assumptions": ["assumption_checks"],
  "diagnostics": {"convergence": "bool", "fit_quality": "metrics"},
  "analyst_id": "agent_id|civilization_id|autonomous_engine_id",
  "analyzed_at": "ISO8601",
  "code_hash": "blake3_hash_of_analysis_code"
}
```

### Evidence Ledger
- Append-only ledger of all evidence and analyses
- Each entry content-addressed and merkle-proofed
- Supports queries by: execution, hypothesis, type, time range, collector
- Immutable; corrections append new entries with CORRECTION type

---

## Stage 7: Discovery Validation

### Purpose
Validate that evidence supports a discovery claim with statistical significance and reproducibility.

### Discovery Criteria (Configurable Thresholds)
1. **Statistical Significance**: p < α (default 0.05) OR Bayes Factor > BF_threshold (default 10)
2. **Effect Size**: Minimum practically significant effect size
3. **Replication**: At least N independent replications (default 2)
4. **Consistency**: Effect direction consistent across replications
5. **Robustness**: Results hold across reasonable analysis variations
6. **Falsification Survival**: Hypothesis not falsified by any evidence

### Discovery Schema
```json
{
  "discovery_id": "blake3_hash",
  "hypothesis_id": "blake3_hash",
  "supporting_executions": ["blake3_hash"],
  "supporting_evidence": ["blake3_hash"],
  "statistical_results": ["blake3_hash"],
  "replication_proofs": [
    {
      "execution_id": "blake3_hash",
      "independent_validator_id": "civilization_id",
      "validation_certificate": "blake3_hash"
    }
  ],
  "validation_criteria": {
    "significance_threshold": "float",
    "effect_size_threshold": "float",
    "replication_count": "integer",
    "consistency_requirement": "string"
  },
  "validation_outcome": {
    "status": "VALIDATED|REJECTED|PENDING_REPLICATION",
    "significance_achieved": "bool",
    "effect_size_achieved": "bool",
    "replications_confirmed": "integer",
    "robustness_checks_passed": "bool"
  },
  "discovery_certificate": "blake3_hash_of_certificate",
  "validator_id": "civilization_id|protocol",
  "validated_at": "ISO8601",
  "version": 1
}
```

### Discovery Certificate
Issued by Certificate Issuer upon successful validation:
```json
{
  "certificate_id": "blake3_hash",
  "certificate_type": "DISCOVERY",
  "discovery_id": "blake3_hash",
  "hypothesis_hash": "blake3_hash",
  "evidence_hashes": ["blake3_hash"],
  "statistical_result_hash": "blake3_hash",
  "replication_proof_hashes": ["blake3_hash"],
  "issuer_signature": "cryptographic_signature",
  "timestamp": "ISO8601",
  "validity_conditions": "object"
}
```

---

## Stage 8: Theory Evolution

### Purpose
Integrate validated discoveries into theoretical frameworks, managing theory lifecycle with full lineage, revision, and supersession.

### Theory Schema
```json
{
  "theory_id": "blake3_hash",
  "name": "string",
  "formal_statement": "logical_or_mathematical_formulation",
  "domain": "string",
  "scope": {
    "phenomena_covered": ["string"],
    "conditions": "object",
    "limitations": "string"
  },
  "constituent_hypotheses": ["blake3_hash"],
  "supporting_discoveries": ["blake3_hash"],
  "contradicting_evidence": ["blake3_hash"],
  "predictive_scope": {
    "testable_predictions": ["prediction_specification"],
    "validated_predictions": ["blake3_hash"],
    "failed_predictions": ["blake3_hash"]
  },
  "confidence": "float",
  "version": 1,
  "lineage": {
    "parent_theory_id": "blake3_hash",
    "operation": "NEW|REVISE|SUPERSEDE|CONTRADICT|MERGE|DEPRECATE",
    "justification": "blake3_hash_of_justification",
    "timestamp": "ISO8601"
  },
  "contributors": [
    {"agent_id": "string", "contribution_type": "formulation|validation|extension|correction"}
  ],
  "created_at": "ISO8601",
  "updated_at": "ISO8601",
  "status": "ACTIVE|SUPERSEDED|DEPRECATED|CONTRADICTED"
}
```

### Theory Operations
1. **REVISE**: Modify theory while preserving core (new version, same theory_id lineage)
2. **SUPERSEDE**: New theory replaces old (old status=SUPERSEDED, new theory_id)
3. **CONTRADICT**: Evidence contradicts theory (status=CONTRADICTED)
4. **MERGE**: Combine theories (new theory_id, both parents in lineage)
5. **DEPRECATE**: Theory no longer maintained (status=DEPRECATED)

### Theory Certificate
```json
{
  "certificate_id": "blake3_hash",
  "certificate_type": "THEORY",
  "theory_id": "blake3_hash",
  "operation": "REVISE|SUPERSEDE|CONTRADICT|MERGE|DEPRECATE",
  "previous_theory_hash": "blake3_hash",
  "justification_hash": "blake3_hash",
  "lineage_proof": "merkle_proof_of_lineage",
  "issuer_signature": "cryptographic_signature",
  "timestamp": "ISO8601"
}
```

---

## Pipeline Orchestration

### Event-Driven Architecture
Each stage emits events consumed by downstream stages:

```elixir
# Event types
%ObservationRegistered{observation_id, timestamp}
%PatternDetected{pattern_id, source_observation_ids}
%HypothesisProposed{hypothesis_id, source_pattern_ids}
%ExperimentDesigned{experiment_id, hypothesis_id}
%ExperimentExecuted{execution_id, experiment_id, evidence_ids}
%EvidenceAnalyzed{statistical_result_id, evidence_ids}
%DiscoveryValidated{discovery_id, hypothesis_id, certificate_id}
%TheoryEvolved{theory_id, operation, discovery_ids}
```

### Pipeline Guarantees
1. **Ordering**: Events processed in causal order (topological sort of DAG)
2. **Idempotency**: Duplicate events safely ignored
3. **Exactly-Once**: Each observation/hypothesis/experiment processed once
4. **Backpressure**: Stages signal capacity; upstream throttles
5. **Checkpointing**: Pipeline state checkpointed for recovery

### Pipeline Configuration
```json
{
  "discovery_thresholds": {
    "significance_alpha": 0.05,
    "bayes_factor_threshold": 10,
    "min_effect_size": 0.2,
    "min_replications": 2,
    "consistency_requirement": "all_same_direction"
  },
  "replay_policy": {
    "auto_replay_on_discovery": true,
    "replay_sample_rate": 1.0,
    "independent_replay_required": true
  },
  "capital_weights": {
    "discovery": 1.0,
    "evidence": 0.5,
    "knowledge": 0.8,
    "theory": 1.2,
    "prediction": 1.5,
    "engineering": 2.0,
    "innovation": 1.8,
    "reproducibility": 3.0
  }
}
```

---

## Monitoring & Observability

### Pipeline Metrics
- **Throughput**: Observations/sec, hypotheses/sec, experiments/sec, discoveries/sec
- **Latency**: Stage-to-stage latency (p50, p95, p99)
- **Quality**: False discovery rate, replication rate, theory stability
- **Resource**: Compute, storage, network per stage
- **Replay**: Replay success rate, replay latency, divergence detection

### Alerts
- Pipeline stall (no progress > threshold)
- Quality degradation (FDR > threshold)
- Replay failure (divergence detected)
- Resource exhaustion
- Certificate issuance failure

---

## Integration Points

### Upstream (Input)
- **Sensor Networks**: Direct observation ingestion
- **Simulation Engines**: Simulation observation ingestion
- **Human Interfaces**: Annotated observation submission
- **ASC Agents**: Autonomous observation/hypothesis generation

### Downstream (Output)
- **Knowledge Graph**: All validated objects and relationships
- **Scientific Capital Engine**: Capital delta computation
- **Replay Engine**: Execution replay requests
- **Certificate Issuer**: Certificate requests
- **Civilization Metrics**: Discovery velocity, knowledge growth

---

## Constitutional Compliance

This pipeline satisfies:
- **Reproducibility**: Every stage deterministic, replayable
- **Evidence-First**: All claims traceable to evidence
- **Content-Addressed**: All objects identified by content hash
- **Archaeological**: Full event log preserved
- **Ownership**: Explicit ownership at every stage
- **Lineage**: Complete theory/discovery lineage tracked

---

*This document is part of Phase 15.0 Architecture Review. No implementation occurs in this phase.*