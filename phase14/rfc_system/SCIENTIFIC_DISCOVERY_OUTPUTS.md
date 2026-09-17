# Scientific Discovery Outputs

## Overview
Every constitutional experiment may optionally produce scientific discovery outputs that feed into Phase 15's scientific discovery mission. These outputs represent the raw materials for building Tiannara's civilization knowledge graph.

## Discovery Types

### 1. Discovery
A validated finding that emerges from experimental evidence.
- **Structure**: {id, claim, confidence, evidence_references, timestamp}
- **Content-Addressed**: SHA-256 hash of canonical form
- **Validation**: Must reference statistical validation artifacts

### 2. Observation
An initial phenomenon detected during experimentation.
- **Structure**: {phenomenon, context, timestamp, initial_hypothesis}
- **Source**: Direct measurement or simulation output
- **Evolution**: May become hypothesis or be discarded

### 3. Theory
A coherent explanation for observed phenomena.
- **Structure**: {explanation, scope, assumptions, predictions, confidence}
- **Testability**: Must generate falsifiable predictions
- **Evolution**: Refines over time with new evidence

### 4. Law
A universal principle discovered through repeated validation.
- **Structure**: {principle, mathematical_form, conditions, exceptions, confidence}
- **Universality**: Applies across multiple experiments and contexts
- **Stability**: High confidence from repeated validation

### 5. Invariant
A constant relationship that holds across constitutional changes.
- **Structure**: {relationship, measurement, stability_score, contexts}
- **Detection**: Identified through counterfactual analysis
- **Implication**: Fundamental constraint on governance design

### 6. Pattern
A recurring structure or behavior in constitutional dynamics.
- **Structure**: {pattern_type, frequency, conditions, predictive_power}
- **Classification**: Temporal, spatial, causal, or statistical
- **Application**: Used for prediction and anomaly detection

### 7. Dataset
Structured collection of experimental results.
- **Structure**: {schema, records, provenance, quality_metrics}
- **Versioning**: Immutable, content-addressed versions
- **Sharing**: Distributed across knowledge graph nodes

## Output Integration Pipeline

```
Experiment
    ↓
Evidence Collection
    ↓
Statistical Analysis
    ↓
Discovery Generation
    ↓
Knowledge Graph Integration
    ↓
Scientific Capital Update
```

## Discovery Metadata

Each discovery output includes:
- **Origin**: Source experiment ID and RFC
- **Timestamp**: When discovery was made
- **Confidence**: Statistical confidence level
- **Evidence**: References to supporting artifacts
- **Impact**: Estimated governance impact score
- **Novelty**: Information gain compared to existing knowledge

## Knowledge Graph Edges

Discoveries create edges in the knowledge graph:
- **DISCOVERED_IN**: Discovery → Experiment
- **SUPPORTS**: Discovery → Theory/Law
- **CHALLENGES**: Discovery → Existing Theory
- **GENERATES**: Experiment → Dataset
- **EVOLVED_FROM**: Discovery → Previous Discovery

## Validation Requirements
- All discovery outputs must be content-addressed
- Confidence levels must reference statistical validation
- Evidence must be independently reproducible
- Novelty must be measurable (information gain)
- Impact must be quantifiable (governance metrics)