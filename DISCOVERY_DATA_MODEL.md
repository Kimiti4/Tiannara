# Discovery Data Model

## Overview

This document defines the complete data model for Phase 15 Scientific Discovery. All objects are content-addressed (Blake3), immutable once registered, and form a directed acyclic graph of scientific provenance.

---

## Core Principles

1. **Content-Addressed Identity**: Every object identified by Blake3 hash of its canonical serialization
2. **Immutability**: Once registered, objects never change; revisions create new objects
3. **Provenance**: Every object carries complete lineage to source observations
4. **Determinism**: Serialization is deterministic; same content → same hash
5. **Schema Versioning**: All schemas versioned; migrations are explicit and replayable

---

## Type Definitions

### Primitive Types

```elixir
# Content hash using Blake3 (32 bytes, hex encoded)
@type content_hash :: String.t()  # 64 hex chars

# ISO8601 timestamp
@type timestamp :: String.t()

# Agent/Civilization identifier
@type agent_id :: String.t()
@type civilization_id :: String.t()

# Semantic version
@type semver :: String.t()

# Non-negative integer
@type uint :: non_neg_integer()

# Positive float
@type positive_float :: float()
```

### Blake3 Hash Computation

```elixir
defmodule Blake3 do
  @spec hash(term()) :: content_hash()
  def hash(data) do
    # Canonical JSON serialization (sorted keys, no whitespace)
    canonical = Jason.encode!(data, keys: :sort, whitespace: false)
    :blake3.hash(canonical) |> Base.encode16(case: :lower)
  end
end
```

---

## 1. Observation

### Schema
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["observation_id", "timestamp", "observer_id", "observation_type", "domain", "raw_data_ref", "metadata", "context_hash", "provenance"],
  "properties": {
    "observation_id": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "timestamp": {"type": "string", "format": "date-time"},
    "observer_id": {"type": "string"},
    "observation_type": {"type": "string", "enum": ["sensor", "simulation", "human", "derived"]},
    "domain": {"type": "string"},
    "raw_data_ref": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "processed_data": {"type": ["object", "string", "null"]},
    "metadata": {
      "type": "object",
      "required": ["instrument", "conditions", "uncertainty", "coordinates", "tags"],
      "properties": {
        "instrument": {"type": "string"},
        "conditions": {"type": "object"},
        "uncertainty": {"type": "number", "minimum": 0},
        "coordinates": {"type": "object"},
        "tags": {"type": "array", "items": {"type": "string"}}
      }
    },
    "context_hash": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "provenance": {
      "type": "object",
      "required": ["source_observation_ids", "transformation", "pipeline_version"],
      "properties": {
        "source_observation_ids": {"type": "array", "items": {"type": "string", "pattern": "^[a-f0-9]{64}$"}},
        "transformation": {"type": "string"},
        "pipeline_version": {"type": "string"}
      }
    }
  }
}
```

### Canonical Serialization Order
1. observation_id
2. timestamp
3. observer_id
4. observation_type
5. domain
6. raw_data_ref
7. processed_data (null if absent)
8. metadata.instrument
9. metadata.conditions (sorted keys)
10. metadata.uncertainty
11. metadata.coordinates (sorted keys)
12. metadata.tags (sorted)
13. context_hash
14. provenance.source_observation_ids (sorted)
15. provenance.transformation
16. provenance.pipeline_version

---

## 2. Pattern

### Schema
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["pattern_id", "pattern_type", "source_observation_ids", "detection_algorithm", "parameters", "statistics", "description", "detected_at", "detector_id"],
  "properties": {
    "pattern_id": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "pattern_type": {"type": "string", "enum": ["anomaly", "correlation", "cluster", "trend", "equation", "causal"]},
    "source_observation_ids": {"type": "array", "items": {"type": "string", "pattern": "^[a-f0-9]{64}$"}},
    "detection_algorithm": {"type": "string"},
    "parameters": {"type": "object"},
    "statistics": {
      "type": "object",
      "required": ["significance", "effect_size", "confidence_interval", "reproducibility_score"],
      "properties": {
        "significance": {"type": "number"},
        "effect_size": {"type": "number"},
        "confidence_interval": {"type": "array", "items": {"type": "number"}, "minItems": 2, "maxItems": 2},
        "reproducibility_score": {"type": "number", "minimum": 0, "maximum": 1}
      }
    },
    "description": {"type": "string"},
    "detected_at": {"type": "string", "format": "date-time"},
    "detector_id": {"type": "string"}
  }
}
```

---

## 3. Hypothesis

### Schema
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["hypothesis_id", "hypothesis_text", "hypothesis_type", "origin", "falsification_criteria", "predicted_outcomes", "scope", "state", "version", "created_at", "updated_at"],
  "properties": {
    "hypothesis_id": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "hypothesis_text": {"type": "string"},
    "hypothesis_type": {"type": "string", "enum": ["causal", "correlational", "mechanistic", "predictive", "explanatory"]},
    "origin": {
      "type": "object",
      "required": ["strategy", "source_pattern_ids", "source_theory_ids", "generator_id"],
      "properties": {
        "strategy": {"type": "string", "enum": ["pattern_driven", "theory_driven", "analogical", "abductive", "counterfactual", "autonomous"]},
        "source_pattern_ids": {"type": "array", "items": {"type": "string", "pattern": "^[a-f0-9]{64}$"}},
        "source_theory_ids": {"type": "array", "items": {"type": "string", "pattern": "^[a-f0-9]{64}$"}},
        "generator_id": {"type": "string"}
      }
    },
    "falsification_criteria": {
      "type": "object",
      "required": ["type", "threshold", "required_evidence"],
      "properties": {
        "type": {"type": "string", "enum": ["statistical", "logical", "observational", "experimental"]},
        "threshold": {"type": "string"},
        "required_evidence": {"type": "string"}
      }
    },
    "predicted_outcomes": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["condition", "prediction", "confidence"],
        "properties": {
          "condition": {"type": "string"},
          "prediction": {"type": "string"},
          "confidence": {"type": "number", "minimum": 0, "maximum": 1}
        }
      }
    },
    "scope": {
      "type": "object",
      "required": ["domain", "applicability_conditions", "limitations"],
      "properties": {
        "domain": {"type": "string"},
        "applicability_conditions": {"type": "object"},
        "limitations": {"type": "string"}
      }
    },
    "state": {"type": "string", "enum": ["PROPOSED", "TESTING", "SUPPORTED", "FALSIFIED", "INCONCLUSIVE", "RETRACTED"]},
    "version": {"type": "integer", "minimum": 1},
    "parent_hypothesis_id": {"type": ["string", "null"], "pattern": "^[a-f0-9]{64}$"},
    "created_at": {"type": "string", "format": "date-time"},
    "updated_at": {"type": "string", "format": "date-time"}
  }
}
```

---

## 4. Experiment

### Schema (Design Phase)
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["experiment_id", "hypothesis_id", "design", "predicted_results", "resources", "designer_id", "design_version", "created_at"],
  "properties": {
    "experiment_id": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "hypothesis_id": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "design": {
      "type": "object",
      "required": ["protocol", "independent_variables", "dependent_variables", "controls", "randomization", "blinding", "sample_size", "stopping_rules"],
      "properties": {
        "protocol": {"type": "string"},
        "independent_variables": {
          "type": "array",
          "items": {
            "type": "object",
            "required": ["name", "type", "levels"],
            "properties": {
              "name": {"type": "string"},
              "type": {"type": "string", "enum": ["continuous", "categorical"]},
              "levels": {"type": ["array", "string"]}
            }
          }
        },
        "dependent_variables": {
          "type": "array",
          "items": {
            "type": "object",
            "required": ["name", "type", "measurement"],
            "properties": {
              "name": {"type": "string"},
              "type": {"type": "string", "enum": ["continuous", "categorical", "ordinal"]},
              "measurement": {"type": "string"}
            }
          }
        },
        "controls": {
          "type": "array",
          "items": {
            "type": "object",
            "required": ["variable", "control_type", "value"],
            "properties": {
              "variable": {"type": "string"},
              "control_type": {"type": "string", "enum": ["negative", "positive", "placebo", "sham"]},
              "value": {"type": ["string", "number", "boolean"]}
            }
          }
        },
        "randomization": {"type": "string"},
        "blinding": {"type": "string", "enum": ["single", "double", "triple", "none"]},
        "sample_size": {
          "type": "object",
          "required": ["calculation_method", "power", "alpha", "effect_size", "n_per_group"],
          "properties": {
            "calculation_method": {"type": "string", "enum": ["power_analysis", "precision", "resource_constrained"]},
            "power": {"type": "number", "minimum": 0, "maximum": 1},
            "alpha": {"type": "number", "minimum": 0, "maximum": 1},
            "effect_size": {"type": "string"},
            "n_per_group": {"type": "integer", "minimum": 1}
          }
        },
        "stopping_rules": {
          "type": "object",
          "properties": {
            "futility": {"type": "string"},
            "efficacy": {"type": "string"},
            "safety": {"type": "string"}
          }
        }
      }
    },
    "predicted_results": {
      "type": "object",
      "required": ["primary_outcome", "secondary_outcomes", "effect_sizes"],
      "properties": {
        "primary_outcome": {"type": "string"},
        "secondary_outcomes": {"type": "array", "items": {"type": "string"}},
        "effect_sizes": {"type": "object"}
      }
    },
    "resources": {
      "type": "object",
      "required": ["compute", "instruments", "duration_estimate", "cost_estimate"],
      "properties": {
        "compute": {"type": "string"},
        "instruments": {"type": "array", "items": {"type": "string"}},
        "duration_estimate": {"type": "string"},
        "cost_estimate": {"type": "string"}
      }
    },
    "designer_id": {"type": "string"},
    "design_version": {"type": "integer", "minimum": 1},
    "parent_design_id": {"type": ["string", "null"], "pattern": "^[a-f0-9]{64}$"},
    "created_at": {"type": "string", "format": "date-time"}
  }
}
```

### Schema (Execution Phase)
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["execution_id", "experiment_id", "design_hash", "executor_id", "environment_snapshot", "timeline", "evidence_collected", "execution_status", "started_at", "completed_at", "resource_consumption"],
  "properties": {
    "execution_id": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "experiment_id": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "design_hash": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "executor_id": {"type": "string"},
    "environment_snapshot": {
      "type": "object",
      "required": ["runtime_hash", "rng_state", "clock_offset", "software_versions", "hardware_fingerprint"],
      "properties": {
        "runtime_hash": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
        "rng_state": {"type": "string"},
        "clock_offset": {"type": "number"},
        "software_versions": {"type": "object"},
        "hardware_fingerprint": {"type": "string"}
      }
    },
    "timeline": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["step", "timestamp", "action", "input_hashes", "output_hashes", "evidence_ids", "decisions"],
        "properties": {
          "step": {"type": "integer", "minimum": 1},
          "timestamp": {"type": "string", "format": "date-time"},
          "action": {"type": "string"},
          "input_hashes": {"type": "array", "items": {"type": "string", "pattern": "^[a-f0-9]{64}$"}},
          "output_hashes": {"type": "array", "items": {"type": "string", "pattern": "^[a-f0-9]{64}$"}},
          "evidence_ids": {"type": "array", "items": {"type": "string", "pattern": "^[a-f0-9]{64}$"}},
          "decisions": {"type": "array", "items": {"type": "string"}}
        }
      }
    },
    "evidence_collected": {"type": "array", "items": {"type": "string", "pattern": "^[a-f0-9]{64}$"}},
    "execution_status": {"type": "string", "enum": ["COMPLETED", "FAILED", "ABORTED", "PAUSED"]},
    "started_at": {"type": "string", "format": "date-time"},
    "completed_at": {"type": "string", "format": "date-time"},
    "resource_consumption": {
      "type": "object",
      "required": ["compute", "time"],
      "properties": {
        "compute": {"type": "string"},
        "time": {"type": "string"}
      }
    }
  }
}
```

---

## 5. Evidence

### Schema
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["evidence_id", "execution_id", "evidence_type", "data_ref", "schema", "metadata", "processing_chain", "fingerprint", "collector_id", "collected_at"],
  "properties": {
    "evidence_id": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "execution_id": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "evidence_type": {"type": "string", "enum": ["raw_measurement", "processed_data", "statistical_result", "derived_quantity"]},
    "data_ref": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "schema": {"type": "string"},
    "metadata": {
      "type": "object",
      "required": ["measurement_instrument", "conditions", "uncertainty", "coordinates"],
      "properties": {
        "measurement_instrument": {"type": "string"},
        "conditions": {"type": "object"},
        "uncertainty": {"type": "number", "minimum": 0},
        "coordinates": {"type": "object"}
      }
    },
    "processing_chain": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["step", "operation", "code_hash", "input_hashes", "output_hash", "parameters"],
        "properties": {
          "step": {"type": "integer", "minimum": 1},
          "operation": {"type": "string", "enum": ["transform", "aggregate", "filter", "model_fit"]},
          "code_hash": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
          "input_hashes": {"type": "array", "items": {"type": "string", "pattern": "^[a-f0-9]{64}$"}},
          "output_hash": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
          "parameters": {"type": "object"}
        }
      }
    },
    "fingerprint": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "collector_id": {"type": "string"},
    "collected_at": {"type": "string", "format": "date-time"}
  }
}
```

---

## 6. Statistical Result

### Schema
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["statistical_result_id", "evidence_ids", "analysis_type", "method", "parameters", "results", "assumptions", "diagnostics", "analyst_id", "analyzed_at", "code_hash"],
  "properties": {
    "statistical_result_id": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "evidence_ids": {"type": "array", "items": {"type": "string", "pattern": "^[a-f0-9]{64}$"}},
    "analysis_type": {"type": "string", "enum": ["frequentist", "bayesian", "meta_analysis", "robustness"]},
    "method": {"type": "string"},
    "parameters": {"type": "object"},
    "results": {
      "type": "object",
      "properties": {
        "test_statistic": {"type": "number"},
        "p_value": {"type": "number", "minimum": 0, "maximum": 1},
        "confidence_interval": {"type": "array", "items": {"type": "number"}, "minItems": 2, "maxItems": 2},
        "effect_size": {"type": "number"},
        "bayes_factor": {"type": "number"},
        "posterior": {"type": "object"}
      }
    },
    "assumptions": {"type": "array", "items": {"type": "string"}},
    "diagnostics": {
      "type": "object",
      "properties": {
        "convergence": {"type": "boolean"},
        "fit_quality": {"type": "object"}
      }
    },
    "analyst_id": {"type": "string"},
    "analyzed_at": {"type": "string", "format": "date-time"},
    "code_hash": {"type": "string", "pattern": "^[a-f0-9]{64}$"}
  }
}
```

---

## 7. Discovery

### Schema
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["discovery_id", "hypothesis_id", "supporting_executions", "supporting_evidence", "statistical_results", "replication_proofs", "validation_criteria", "validation_outcome", "discovery_certificate", "validator_id", "validated_at", "version"],
  "properties": {
    "discovery_id": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "hypothesis_id": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "supporting_executions": {"type": "array", "items": {"type": "string", "pattern": "^[a-f0-9]{64}$"}},
    "supporting_evidence": {"type": "array", "items": {"type": "string", "pattern": "^[a-f0-9]{64}$"}},
    "statistical_results": {"type": "array", "items": {"type": "string", "pattern": "^[a-f0-9]{64}$"}},
    "replication_proofs": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["execution_id", "independent_validator_id", "validation_certificate"],
        "properties": {
          "execution_id": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
          "independent_validator_id": {"type": "string"},
          "validation_certificate": {"type": "string", "pattern": "^[a-f0-9]{64}$"}
        }
      }
    },
    "validation_criteria": {
      "type": "object",
      "required": ["significance_threshold", "effect_size_threshold", "replication_count", "consistency_requirement"],
      "properties": {
        "significance_threshold": {"type": "number", "minimum": 0, "maximum": 1},
        "effect_size_threshold": {"type": "number", "minimum": 0},
        "replication_count": {"type": "integer", "minimum": 1},
        "consistency_requirement": {"type": "string"}
      }
    },
    "validation_outcome": {
      "type": "object",
      "required": ["status", "significance_achieved", "effect_size_achieved", "replications_confirmed", "robustness_checks_passed"],
      "properties": {
        "status": {"type": "string", "enum": ["VALIDATED", "REJECTED", "PENDING_REPLICATION"]},
        "significance_achieved": {"type": "boolean"},
        "effect_size_achieved": {"type": "boolean"},
        "replications_confirmed": {"type": "integer", "minimum": 0},
        "robustness_checks_passed": {"type": "boolean"}
      }
    },
    "discovery_certificate": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "validator_id": {"type": "string"},
    "validated_at": {"type": "string", "format": "date-time"},
    "version": {"type": "integer", "minimum": 1}
  }
}
```

---

## 8. Theory

### Schema
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["theory_id", "name", "formal_statement", "domain", "scope", "constituent_hypotheses", "supporting_discoveries", "contradicting_evidence", "predictive_scope", "confidence", "version", "lineage", "contributors", "created_at", "updated_at", "status"],
  "properties": {
    "theory_id": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "name": {"type": "string"},
    "formal_statement": {"type": "string"},
    "domain": {"type": "string"},
    "scope": {
      "type": "object",
      "required": ["phenomena_covered", "conditions", "limitations"],
      "properties": {
        "phenomena_covered": {"type": "array", "items": {"type": "string"}},
        "conditions": {"type": "object"},
        "limitations": {"type": "string"}
      }
    },
    "constituent_hypotheses": {"type": "array", "items": {"type": "string", "pattern": "^[a-f0-9]{64}$"}},
    "supporting_discoveries": {"type": "array", "items": {"type": "string", "pattern": "^[a-f0-9]{64}$"}},
    "contradicting_evidence": {"type": "array", "items": {"type": "string", "pattern": "^[a-f0-9]{64}$"}},
    "predictive_scope": {
      "type": "object",
      "required": ["testable_predictions", "validated_predictions", "failed_predictions"],
      "properties": {
        "testable_predictions": {"type": "array", "items": {"type": "string"}},
        "validated_predictions": {"type": "array", "items": {"type": "string", "pattern": "^[a-f0-9]{64}$"}},
        "failed_predictions": {"type": "array", "items": {"type": "string", "pattern": "^[a-f0-9]{64}$"}}
      }
    },
    "confidence": {"type": "number", "minimum": 0, "maximum": 1},
    "version": {"type": "integer", "minimum": 1},
    "lineage": {
      "type": "object",
      "required": ["parent_theory_id", "operation", "justification", "timestamp"],
      "properties": {
        "parent_theory_id": {"type": ["string", "null"], "pattern": "^[a-f0-9]{64}$"},
        "operation": {"type": "string", "enum": ["NEW", "REVISE", "SUPERSEDE", "CONTRADICT", "MERGE", "DEPRECATE"]},
        "justification": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
        "timestamp": {"type": "string", "format": "date-time"}
      }
    },
    "contributors": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["agent_id", "contribution_type"],
        "properties": {
          "agent_id": {"type": "string"},
          "contribution_type": {"type": "string", "enum": ["formulation", "validation", "extension", "correction"]}
        }
      }
    },
    "created_at": {"type": "string", "format": "date-time"},
    "updated_at": {"type": "string", "format": "date-time"},
    "status": {"type": "string", "enum": ["ACTIVE", "SUPERSEDED", "DEPRECATED", "CONTRADICTED"]}
  }
}
```

---

## 9. Theory Revision

### Schema
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["revision_id", "theory_id", "operation", "previous_theory_hash", "new_theory_hash", "justification", "evidence_supporting", "evidence_contradicting", "timestamp", "author_id"],
  "properties": {
    "revision_id": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "theory_id": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "operation": {"type": "string", "enum": ["REVISE", "SUPERSEDE", "CONTRADICT", "MERGE", "DEPRECATE"]},
    "previous_theory_hash": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "new_theory_hash": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "justification": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "evidence_supporting": {"type": "array", "items": {"type": "string", "pattern": "^[a-f0-9]{64}$"}},
    "evidence_contradicting": {"type": "array", "items": {"type": "string", "pattern": "^[a-f0-9]{64}$"}},
    "timestamp": {"type": "string", "format": "date-time"},
    "author_id": {"type": "string"}
  }
}
```

---

## 10. Scientific Capital Delta

### Schema
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["delta_id", "capital_type", "owner_id", "amount", "source_hashes", "computation_proof", "confidence", "reproducibility_multiplier", "timestamp", "valid_from", "valid_until"],
  "properties": {
    "delta_id": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "capital_type": {"type": "string", "enum": ["discovery", "evidence", "knowledge", "theory", "prediction", "engineering", "innovation", "reproducibility"]},
    "owner_id": {"type": "string"},
    "amount": {"type": "number"},
    "source_hashes": {"type": "array", "items": {"type": "string", "pattern": "^[a-f0-9]{64}$"}},
    "computation_proof": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "confidence": {"type": "number", "minimum": 0, "maximum": 1},
    "reproducibility_multiplier": {"type": "number", "minimum": 0},
    "timestamp": {"type": "string", "format": "date-time"},
    "valid_from": {"type": "string", "format": "date-time"},
    "valid_until": {"type": ["string", "null"], "format": "date-time"}
  }
}
```

---

## 11. Knowledge Node

### Schema
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["node_id", "node_type", "content_hash", "label", "properties", "confidence", "created_at", "creator_id"],
  "properties": {
    "node_id": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "node_type": {"type": "string", "enum": ["observation", "hypothesis", "experiment", "discovery", "theory", "concept", "evidence", "pattern", "agent", "civilization"]},
    "content_hash": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "label": {"type": "string"},
    "properties": {"type": "object"},
    "confidence": {"type": "number", "minimum": 0, "maximum": 1},
    "created_at": {"type": "string", "format": "date-time"},
    "creator_id": {"type": "string"}
  }
}
```

---

## 12. Knowledge Edge

### Schema
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["edge_id", "source_node_id", "target_node_id", "edge_type", "weight", "confidence", "evidence_hashes", "created_at", "creator_id"],
  "properties": {
    "edge_id": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "source_node_id": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "target_node_id": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "edge_type": {"type": "string", "enum": ["SUPPORTS", "CONTRADICTS", "DERIVES_FROM", "REFINES", "SUPERSEDES", "REPLICATES", "PREDICTS", "EXPLAINS", "USES", "CITES"]},
    "weight": {"type": "number", "minimum": 0, "maximum": 1},
    "confidence": {"type": "number", "minimum": 0, "maximum": 1},
    "evidence_hashes": {"type": "array", "items": {"type": "string", "pattern": "^[a-f0-9]{64}$"}},
    "created_at": {"type": "string", "format": "date-time"},
    "creator_id": {"type": "string"}
  }
}
```

---

## 13. Discovery Certificate

### Schema
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["certificate_id", "certificate_type", "discovery_id", "hypothesis_hash", "evidence_hashes", "statistical_result_hash", "replication_proof_hashes", "issuer_signature", "timestamp", "validity_conditions"],
  "properties": {
    "certificate_id": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "certificate_type": {"type": "string", "const": "DISCOVERY"},
    "discovery_id": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "hypothesis_hash": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "evidence_hashes": {"type": "array", "items": {"type": "string", "pattern": "^[a-f0-9]{64}$"}},
    "statistical_result_hash": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "replication_proof_hashes": {"type": "array", "items": {"type": "string", "pattern": "^[a-f0-9]{64}$"}},
    "issuer_signature": {"type": "string"},
    "timestamp": {"type": "string", "format": "date-time"},
    "validity_conditions": {"type": "object"}
  }
}
```

---

## 14. Replay Certificate

### Schema
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["certificate_id", "certificate_type", "original_hash", "replay_hash", "environment_snapshot_hash", "executor_id", "verifier_signature", "timestamp"],
  "properties": {
    "certificate_id": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "certificate_type": {"type": "string", "const": "REPLAY"},
    "original_hash": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "replay_hash": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "environment_snapshot_hash": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "executor_id": {"type": "string"},
    "verifier_signature": {"type": "string"},
    "timestamp": {"type": "string", "format": "date-time"}
  }
}
```

---

## 15. Theory Certificate

### Schema
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["certificate_id", "certificate_type", "theory_id", "operation", "previous_theory_hash", "justification_hash", "lineage_proof", "issuer_signature", "timestamp"],
  "properties": {
    "certificate_id": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "certificate_type": {"type": "string", "const": "THEORY"},
    "theory_id": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "operation": {"type": "string", "enum": ["REVISE", "SUPERSEDE", "CONTRADICT", "MERGE", "DEPRECATE"]},
    "previous_theory_hash": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "justification_hash": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "lineage_proof": {"type": "string"},
    "issuer_signature": {"type": "string"},
    "timestamp": {"type": "string", "format": "date-time"}
  }
}
```

---

## 16. Capital Certificate

### Schema
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["certificate_id", "certificate_type", "capital_type", "delta_hash", "source_hashes", "computation_proof", "issuer_signature", "timestamp"],
  "properties": {
    "certificate_id": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "certificate_type": {"type": "string", "const": "CAPITAL"},
    "capital_type": {"type": "string", "enum": ["discovery", "evidence", "knowledge", "theory", "prediction", "engineering", "innovation", "reproducibility"]},
    "delta_hash": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "source_hashes": {"type": "array", "items": {"type": "string", "pattern": "^[a-f0-9]{64}$"}},
    "computation_proof": {"type": "string", "pattern": "^[a-f0-9]{64}$"},
    "issuer_signature": {"type": "string"},
    "timestamp": {"type": "string", "format": "date-time"}
  }
}
```

---

## Serialization Rules

### Canonical JSON Serialization
All objects MUST be serialized using canonical JSON before hashing:

```elixir
defmodule CanonicalJSON do
  @spec encode(term()) :: String.t()
  def encode(data) do
    Jason.encode!(data, keys: :sort, whitespace: false)
  end
end
```

### Field Ordering
Object keys MUST be sorted lexicographically (ASCII order).

### Numeric Precision
- Integers: No trailing zeros, no leading zeros (except "0")
- Floats: Maximum 15 significant digits, no trailing zeros after decimal
- Scientific notation allowed for |value| < 1e-6 or |value| >= 1e15

### String Encoding
- UTF-8 encoded
- No escape sequences for printable ASCII
- Unicode escape (\uXXXX) for non-ASCII

### Null Handling
- Null fields OMITTED from canonical serialization
- Empty arrays/objects included as `[]` / `{}`

---

## Schema Versioning

### Version Header
Every schema includes a version field:
```json
{
  "schema_version": "15.0.0",
  "schema_name": "Observation"
}
```

### Migration Rules
1. **Additive only**: New fields optional with defaults
2. **Never remove**: Deprecated fields kept, marked deprecated
3. **Never rename**: Use aliases, keep original
4. **Migration function**: Explicit, deterministic, replayable

### Compatibility Matrix
| Schema Version | Reads v15.0.0 | Reads v15.1.0 | Writes v15.0.0 |
|----------------|---------------|---------------|----------------|
| v15.0.0        | ✓             | ✗             | ✓              |
| v15.1.0        | ✓             | ✓             | ✗              |

---

## Registry Storage Format

### Entry Structure
```json
{
  "entry_id": "blake3_hash",
  "schema_version": "15.0.0",
  "schema_name": "Observation",
  "content_hash": "blake3_hash",
  "content": "{...canonical_json...}",
  "registered_at": "ISO8601",
  "registrar_id": "agent_id",
  "merkle_proof": "merkle_proof_object"
}
```

### Index Structures
- **Primary Index**: content_hash → entry_id (unique)
- **Type Index**: schema_name → [entry_id]
- **Time Index**: registered_at → [entry_id] (B-tree)
- **Owner Index**: registrar_id → [entry_id]
- **Reference Index**: referenced_hash → [entry_id] (reverse lookup)

---

## Validation Rules

### Cross-Reference Integrity
1. Every `source_observation_ids` must exist in Observation Registry
2. Every `hypothesis_id` in Experiment must exist in Hypothesis Registry
3. Every `evidence_id` must exist in Evidence Ledger
4. Every `discovery_id` must have valid DiscoveryCertificate
5. Every `theory_id` lineage must form valid DAG

### Content Hash Verification
On every read: `Blake3.hash(content) == content_hash` MUST hold

### Merkle Proof Verification
Registry merkle proofs MUST verify against current root

---

*This document is part of Phase 15.0 Architecture Review. No implementation occurs in this phase.*