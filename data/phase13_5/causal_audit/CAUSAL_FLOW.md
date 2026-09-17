# Constitutional Causal Flow - Phase 13.5A.2

**Date**: 2026-06-30T19:27:25.669000Z
**Purpose**: Establish complete causal dependency graph for all civilization metrics
**Status**: Constitutional Artifact - Single Source of Truth for Metric Definitions

---

## Executive Summary

This document defines the **complete causal dependency graph** for every measurable quantity in the Tiannara research civilization. It serves as the constitutional specification for all validators, dashboards, statistical analyses, and future governance mechanisms.

### Key Principles

1. **Every metric must terminate in canonical transactions** (ResearchEpisode, TheoryFormationResult, etc.)
2. **No metric may depend on adaptation flags, random seeds, or simulation configuration**
3. **No circular dependencies** - the causal graph must be a Directed Acyclic Graph (DAG)
4. **Conservation laws must hold exactly** (budget, discoveries, theories, unknowns)
5. **Temporal separation** - adaptations in generation G only affect generation G+1

---

## Graph Statistics

- **Total Nodes**: 41
- **Total Edges**: 55
- **Root Nodes** (Canonical Transactions): 8
- **Leaf Nodes** (Composite Metrics): 19
- **Metric Nodes**: 25

### Validation Results

| Check | Status |
|-------|--------|
| Cycle Detection | ✅ PASS - No circular dependencies |
| Metric Completeness | ✅ PASS |
| Reward Leakage | ✅ PASS |
| Temporal Separation | ✅ PASS |
| Budget Conservation | ✅ PASS |
| Research Debt Conservation | ✅ PASS |
| Scientific Capital Conservation | ✅ PASS |

---

## Metric Dependency Graph

### Canonical Transaction Dependencies

Every metric's complete causal chain terminating in frozen canonical primitives:

#### Scientific Capital

**Description**: Accumulated value of validated scientific knowledge

**Constitutional Principle**: Scientific Capital Accumulation

**Immediate Dependencies**:
      - discoveries_made
      - theories_formed
      - unknowns_resolved


#### Research Debt

**Description**: Level of unresolved unknown dependencies

**Constitutional Principle**: Research Debt Management

**Immediate Dependencies**:
      - unknowns_resolved


#### Research Velocity

**Description**: Rate of discovery production (discoveries/generation)

**Constitutional Principle**: N/A

**Immediate Dependencies**:
      - discoveries_made
      - episodes_created


#### Replication Success Rate

**Description**: Success rate of replication attempts

**Constitutional Principle**: Replication Protocol

**Immediate Dependencies**:
      - distributed_validation_result


#### Prediction Calibration

**Description**: Accuracy of predictions vs actual outcomes

**Constitutional Principle**: Prediction Assessment Protocol

**Immediate Dependencies**:
      - belief_revision_result


#### Theory Stability

**Description**: Stability of theories over time (low variance = stable)

**Constitutional Principle**: N/A

**Immediate Dependencies**:
      - theories_formed


#### Innovation Velocity

**Description**: Rate of novel theory/method introduction

**Constitutional Principle**: N/A

**Immediate Dependencies**:
      - method_evolution_result


#### Discovery Rate

**Description**: Discoveries per episode (efficiency metric)

**Constitutional Principle**: N/A

**Immediate Dependencies**:
      - discoveries_made
      - episodes_created


#### Resource Efficiency

**Description**: Discoveries per credit spent (economic efficiency)

**Constitutional Principle**: N/A

**Immediate Dependencies**:
      - discoveries_made
      - credits_spent


#### Budget Consumption

**Description**: Rate of budget utilization over time

**Constitutional Principle**: N/A

**Immediate Dependencies**:
      - credits_spent


#### Civilization Adaptation Index

**Description**: Composite measure of civilizational health and improvement capacity

**Constitutional Principle**: Civilization Adaptation Index Calculation

**Immediate Dependencies**:
      - adaptation_success_rate
      - prediction_reliability
      - constitutional_violations
      - rollback_frequency
      - institution_diversity
      - method_diversity


#### Institution Diversity

**Description**: Diversity of institutional specializations

**Constitutional Principle**: Institutional Diversity Principle

**Immediate Dependencies**:
      - institution_adaptation_result
      - institution_adaptation_result


#### Method Diversity

**Description**: Diversity of research methods employed

**Constitutional Principle**: Methodological Diversity Principle

**Immediate Dependencies**:
      - method_evolution_result
      - method_evolution_result


#### Collaboration Density

**Description**: Network density of inter-institution collaboration

**Constitutional Principle**: N/A

**Immediate Dependencies**:
      - research_episode


#### Transferability

**Description**: Success rate of cross-domain knowledge transfer

**Constitutional Principle**: N/A

**Immediate Dependencies**:
      - institution_adaptation_result


#### Robustness

**Description**: System resilience to perturbations

**Constitutional Principle**: N/A

**Immediate Dependencies**:
      - rollback_frequency
      - constitutional_violations


#### Knowledge Density

**Description**: Knowledge per episode (compression metric)

**Constitutional Principle**: N/A

**Immediate Dependencies**:
      - theories_formed
      - episodes_created


#### Theory Compression

**Description**: Ratio of theories to observations (explanatory power)

**Constitutional Principle**: N/A

**Immediate Dependencies**:
      - theories_formed
      - discoveries_made


#### Validation Success

**Description**: Success rate of validation attempts

**Constitutional Principle**: N/A

**Immediate Dependencies**:
      - distributed_validation_result


#### Unknown Resolution Rate

**Description**: Rate at which unknowns are resolved

**Constitutional Principle**: N/A

**Immediate Dependencies**:
      - unknowns_resolved
      - episodes_created


#### Adaptation Success Rate

**Description**: Success rate of adopted adaptations

**Constitutional Principle**: N/A

**Immediate Dependencies**:
      - adaptations_adopted
      - adaptations_evaluated


#### Prediction Reliability

**Description**: Reliability of prediction assessments over time

**Constitutional Principle**: N/A

**Immediate Dependencies**:
      - belief_revision_result


#### Constitutional Violations

**Description**: Count of constitutional principle violations

**Constitutional Principle**: Constitutional Compliance Monitoring

**Immediate Dependencies**:
      - civilization_adaptation_result


#### Lifecycle Completeness Pct

**Description**: Percentage of lifecycle events completed

**Constitutional Principle**: Lifecycle Completeness Principle

**Immediate Dependencies**:
      - research_episode


#### Rollback Frequency

**Description**: Frequency of rollback operations (lower = more stable)

**Constitutional Principle**: N/A

**Immediate Dependencies**:
      - civilization_adaptation_result


---

## Reward Leakage Audit

✅ **No reward leakage detected.** All metrics properly derive from canonical transactions through complete causal chains.

### Verification Method

For each metric, verified that:
1. At least one complete dependency chain exists
2. Chain terminates in a canonical transaction or research episode
3. No direct manipulation based on adaptation state

---

## Temporal Audit

✅ **No temporal leakage detected.** Adaptations properly delayed to generation G+1.

### Verification Method

Checked generation pairs (G, G+1) for:
1. Immediate CAI changes after adaptation adoption (>5% decrease suggests immediate effect)
2. Disproportionate scientific capital changes not explained by discoveries/theories
3. Proper one-generation delay between adaptation approval and metric impact

---

## Conservation Audit

#### Budget

**Status**: ✅ PASS

All conservation equations hold exactly.


#### Research debt

**Status**: ✅ PASS

All conservation equations hold exactly.


#### Scientific capital

**Status**: ✅ PASS

All conservation equations hold exactly.


#### Theory count

**Status**: ✅ PASS

All conservation equations hold exactly.


#### Unknown count

**Status**: ✅ PASS

All conservation equations hold exactly.


### Conservation Equations

**Budget**: `Initial = Remaining + Spent`

**Research Debt**: `Debt(G+1) = Debt(G) + New Unknowns - Resolved Unknowns`

**Scientific Capital**: `Capital(G+1) >= Capital(G) + Validated Discoveries + Validated Theories`

**Theory Count**: `Previous + New - Retired = Current`

**Unknown Count**: `Previous + Generated - Resolved = Current`

---

## Architectural Violations

✅ **No architectural violations detected.** The causal graph is constitutionally compliant.

---

## Required Fixes

✅ **No fixes required.** Proceed to statistical validation.

---

## Canonical Transaction Reference

### Root Nodes (Immutable Evidence Sources)

- **research_episode**: Fundamental unit of institutional memory - groups related transactions into coherent investigations
  - Principle: Principle 12 - Episodic Integrity
- **theory_formation_result**: Result of theory formation process - creates/updates theoretical frameworks
  - Principle: Theory Formation Protocol
- **distributed_validation_result**: Result of distributed validation - validates theories across institutions
  - Principle: Distributed Validation Protocol
- **institution_adaptation_result**: Result of institution adaptation - proposes/adopts institutional changes
  - Principle: Institution Adaptation Protocol
- **method_evolution_result**: Result of method evolution - evolves research methods based on performance
  - Principle: Method Evolution Protocol
- **civilization_adaptation_result**: Result of civilization adaptation - adopts civilizational improvements
  - Principle: Civilization Adaptation Protocol
- **belief_revision_result**: Result of belief revision - updates epistemic beliefs based on evidence
  - Principle: Belief Revision Protocol
- **research_cycle_result**: Result of research cycle - executes hypothesis testing cycle
  - Principle: Research Cycle Protocol

---

## Usage Guidelines

After this phase, **never hand-maintain metric definitions again**. All components must query `CausalGraph`:

```elixir
# Correct usage
graph = CausalGraph.build()
deps = CausalGraph.get_dependencies(graph, :scientific_capital)

# Incorrect - don't embed metric knowledge
scientific_capital = discoveries * 100 + theories * 50  # ❌ WRONG
```

### Components That Must Use CausalGraph

- Statistical Validator
- Mission Control Dashboard
- Executive Dashboard
- Robustness Tests
- Phase 14 Constitutional Meta-Governance

---

**Generated By**: TiannaraOS.CausalAudit
**Constitutional Compliance**: All metrics derived from frozen canonical primitives
**Next Steps**: Fix identified violations, then re-run validator audit
