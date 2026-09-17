# Theory Formation Engine

## Purpose

Construct scientific theories by organizing models, laws, discoveries, and
mechanisms into coherent explanatory frameworks with defined scope and
predictive capability.

## Theory Structure

Each theory records:
- **Scope**: Domain of applicability
- **Assumptions**: All explicit assumptions
- **Supporting Discoveries**: Discovery IDs that ground the theory
- **Supporting Laws**: Law IDs incorporated into the theory
- **Supporting Models**: Model IDs the theory subsumes
- **Predictive Capability**: What the theory predicts and with what accuracy
- **Engineering Utility**: What the theory enables building
- **Uncertainty**: Overall confidence assessment
- **Lineage**: Parent theories, formation timestamp, evolution history
- **Contradictions**: Known contradictory evidence or theories
- **Fingerprint**: Content hash

## Formation Pipeline

1. Receive candidate models from Model Synthesis Engine
2. Identify unifying principles across models
3. Define theory scope and assumptions
4. Link supporting discoveries, laws, and models
5. Assess predictive capability and utility
6. Qualify uncertainty
7. Register as a theory object
8. Submit to Theory Evaluation Engine

## Constitutional Requirements

- Every theory must explicitly state its assumptions
- No theory can suppress contradictory evidence
- All supporting references must be verifiable
