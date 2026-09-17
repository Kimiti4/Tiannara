# Impact Pipeline

## Purpose

Define the deterministic pipeline that transforms a discovery into its full impact forecast. Every transition is replayable, every intermediate result preservable.

## Pipeline Stages

| Stage | Input | Output |
|-------|-------|--------|
| Impact Identification | Discovery + Knowledge Graph | Set of affected systems |
| Causal Propagation | Affected systems + Causal Graph | Impact graph (direct effects) |
| Second-Order Effects | Impact graph | Extended impact graph |
| Third-Order Effects | Extended impact graph | Full impact graph |
| Scenario Generation | Impact graph | Scenario tree |
| Risk Assessment | Scenario tree | Risk-qualified scenarios |
| Opportunity Assessment | Scenario tree | Opportunity-qualified scenarios |
| Engineering Forecast | Scenarios + Risks + Opportunities | Engineering impact forecast |
| Planetary Forecast | Engineering forecast + Ecosystem data | Planetary impact forecast |
| Civilizational Forecast | All prior stages | Civilizational impact forecast |
| Research Feedback | Civilizational forecast | Prioritized research directions |
| Certification | Complete forecast package | Certified impact forecast |

## Pipeline Properties

- Every stage is deterministic given its inputs
- Stages can be rerun independently
- Partial pipeline execution is supported
- Pipeline state is fully serializable for replay
