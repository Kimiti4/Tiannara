# Phase 20.7 — Experiment Design Engine

## Role

The Experiment Design Engine transforms experiment proposals into complete, constitutionally-compliant experimental designs. It ensures every experiment has defined variables, controls, sample size, statistical power, safety limits, resource budgets, and success/failure criteria.

## Inputs

- Experiment proposal (from Engineering, Discovery, Research, or Runtime Evolution)
- Constitutional rules and constraints
- Resource availability
- Domain-specific constraints

## Outputs

- ExperimentPlan with complete experimental design

## Design Dimensions

### Variable Selection
Selection and specification of all experimental variables.

| Variable Type | Description | Requirements |
|---------------|-------------|--------------|
| Independent | Variables manipulated by the experiment | Must be deterministic and controllable |
| Dependent | Variables measured to assess effect | Must be observable and measurable |
| Controlled | Variables held constant | Must be identifiable and enforceable |
| Confounding | Variables that could affect results | Must be identified and mitigated |

### Controls
Specification of control conditions.

| Control Type | Description |
|--------------|-------------|
| Negative control | Condition where no effect is expected |
| Positive control | Condition where a known effect is expected |
| Placebo control | Baseline condition for comparison |
| Historical control | Comparison against prior experiment data |

### Sample Size
Determination of sample size based on statistical requirements.

| Parameter | Description |
|-----------|-------------|
| Effect size | Minimum detectable effect size |
| Power | Statistical power requirement (minimum) |
| Significance | Significance threshold (alpha) |
| Variability | Expected variability in measurements |
| Sample size | Computed minimum sample size |

### Statistical Power Requirements
Requirements for statistical validity.

| Requirement | Description |
|-------------|-------------|
| Minimum power | Statistical power must exceed constitutional minimum |
| Significance threshold | Maximum p-value for significance |
| Effect size precision | Required precision of effect size estimate |
| Confidence interval | Required confidence level |
| Multiple comparison correction | Method for correcting multiple comparisons |

### Safety Limits
Boundaries that must not be crossed during execution.

| Limit | Description |
|-------|-------------|
| Resource limit | Maximum resource consumption |
| Time limit | Maximum execution duration |
| Scope limit | Maximum scope of variable manipulation |
| Risk limit | Maximum acceptable risk level |
| Containment limit | Boundaries for effect propagation |

### Resource Budgets
Allocation of resources for experiment execution.

| Resource | Description |
|----------|-------------|
| Compute budget | CPU time allocation |
| Memory budget | Memory allocation |
| Storage budget | Storage allocation for observations |
| Domain budget | Domain-specific resource allocation |

### Success Criteria
Conditions under which the experiment is considered successful.

| Criterion | Description |
|-----------|-------------|
| Hypothesis confirmation | Statistical evidence supporting hypothesis |
| Effect detection | Detected effect exceeds minimum threshold |
| Reproducibility | Experiment reproduces identically |
| Safety compliance | All safety limits respected |

### Failure Criteria
Conditions under which the experiment is considered failed.

| Criterion | Description |
|-----------|-------------|
| Resource exhaustion | Resource consumption exceeds budget |
| Safety violation | Safety limit crossed |
| Invalid assumptions | Assumptions violated during execution |
| Non-reproducibility | Results not reproducible |
| Statistical invalidity | Statistical assumptions violated |

## Design Constraints

- All variables must be deterministic
- Controls must be specified for every independent variable
- Sample size must meet minimum statistical power requirements
- Safety limits must be defined before execution
- Resource budgets must be within constitutional bounds
- Success and failure criteria must be unambiguous and testable

## Output Format

The ExperimentPlan is an immutable, content-addressed object:

| Field | Description |
|-------|-------------|
| plan_id | Content-addressed identifier |
| proposal | Reference to original experiment proposal |
| variables | Independent, dependent, controlled, confounding variables |
| controls | Control specifications |
| sample_size | Computed sample size with statistical parameters |
| statistical_requirements | Power, significance, confidence requirements |
| safety_limits | Resource, time, scope, risk, containment limits |
| resource_budgets | Compute, memory, storage, domain budgets |
| success_criteria | Conditions for success |
| failure_criteria | Conditions for failure |
| statistical_plan | Detailed statistical analysis plan |
| fingerprint | SHA-256 of canonical form |
