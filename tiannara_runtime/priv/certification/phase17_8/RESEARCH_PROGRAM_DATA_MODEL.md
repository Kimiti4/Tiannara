# Phase 17.8 — Research Program Data Model

## Structs

### ResearchProgram
Root entity representing an autonomous research program.

| Field | Type | Description |
|---|---|---|
| program_id | String | Content-addressed ID (rp_<sha256>) |
| name | String | Human-readable name |
| objective | String | Research objective |
| knowledge_gaps | [KnowledgeGap] | Originating gaps |
| research_questions | [ResearchQuestion] | Generated questions |
| hypotheses | [Hypothesis] | Formed hypotheses |
| experiments | [ExperimentPortfolio] | Designed experiments |
| priority | float | Priority score (0.0–1.0) |
| budget | ExperimentBudget | Resource allocation |
| status | atom | :active, :paused, :completed, :terminated |
| dependencies | [String] | Program dependency IDs |
| success_criteria | [String] | Criteria for completion |
| evidence_ledger | [EvidenceEntry] | Collected evidence |
| replay_fingerprint | String | Deterministic replay hash |
| archaeology_root | String | Root evidence ID |
| created_at | String | ISO 8601 timestamp |

### ExperimentPortfolio
Collection of experiments within a program.

| Field | Type | Description |
|---|---|---|
| portfolio_id | String | Content-addressed ID |
| program_id | String | Parent program |
| experiments | [Experiment] | Experiment specifications |
| diversity_score | float | Scientific diversity metric |
| expected_information_gain | float | Expected information gain |
| allocated_budget | ExperimentBudget | Budget for this portfolio |

### ExperimentBudget
Resource allocation for experiments.

| Field | Type | Description |
|---|---|---|
| budget_id | String | Content-addressed ID |
| max_compute_units | integer | Maximum computation units |
| max_simulations | integer | Maximum Digital Twin simulations |
| max_wall_clock_ms | integer | Maximum wall clock time |
| priority_weight | float | Priority weight (0.0–1.0) |

### ExperimentSchedule
Schedule for experiment execution.

| Field | Type | Description |
|---|---|---|
| schedule_id | String | Content-addressed ID |
| program_id | String | Parent program |
| campaigns | [ResearchCampaign] | Campaign specifications |
| adaptive | boolean | Whether schedule adapts |
| created_at | String | ISO 8601 timestamp |

### ResearchCampaign
A set of related experiments executed together.

| Field | Type | Description |
|---|---|---|
| campaign_id | String | Content-addressed ID (rc_<sha256>) |
| program_id | String | Parent program |
| portfolio_id | String | Parent portfolio |
| experiment_ids | [String] | Experiments in campaign |
| execution_order | [String] | Ordered experiment IDs |
| status | atom | :pending, :running, :completed, :failed |
| started_at | String | ISO 8601 or nil |
| completed_at | String | ISO 8601 or nil |

### ResearchOutcome
Result of a research experiment.

| Field | Type | Description |
|---|---|---|
| outcome_id | String | Content-addressed ID |
| experiment_id | String | Source experiment |
| hypothesis_id | String | Tested hypothesis |
| evidence | [ResearchEvidence] | Collected evidence |
| supported | boolean | Whether hypothesis was supported |
| effect_size | float | Statistical effect size |
| confidence | float | Confidence level (0.0–1.0) |
| replay_hash | String | Replay verification hash |

### ResearchEvidence
Single piece of evidence from an experiment.

| Field | Type | Description |
|---|---|---|
| evidence_id | String | Content-addressed ID (re_<sha256>) |
| experiment_id | String | Source experiment |
| type | atom | :observation, :measurement, :comparison |
| variable | String | Measured variable |
| value | term | Observed value |
| confidence | float | Confidence in this evidence |
| timestamp | integer | Simulation tick |

### ProgramMetrics
Metrics tracking program health.

| Field | Type | Description |
|---|---|---|
| metrics_id | String | Content-addressed ID |
| program_id | String | Parent program |
| experiments_completed | integer | Count of completed experiments |
| hypotheses_tested | integer | Count of tested hypotheses |
| theories_updated | integer | Count of theory updates |
| information_gained | float | Accumulated information gain |
| resource_utilization | float | Budget utilization (0.0–1.0) |
| knowledge_gaps_filled | integer | Gaps resolved |

## Schema IDs

All IDs are content-addressed SHA-256 hashes with type prefixes:
- `rp_` — ResearchProgram
- `rc_` — ResearchCampaign
- `re_` — ResearchEvidence
- `pf_` — ExperimentPortfolio
- `bd_` — ExperimentBudget
- `sc_` — ExperimentSchedule
