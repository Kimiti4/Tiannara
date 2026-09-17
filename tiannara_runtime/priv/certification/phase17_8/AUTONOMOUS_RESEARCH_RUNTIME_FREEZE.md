# Phase 17.8 — Autonomous Research Runtime Freeze

## Structs

### 1. ResearchProgram (`research_program.ex`)
| Field | Type | Description |
|---|---|---|
| program_id | String | Content-addressed ID (`rp_` + sha256) |
| name | String | Human-readable name |
| objective | String | Research objective |
| knowledge_gaps | [map()] | Originating knowledge gaps |
| research_questions | [map()] | Generated research questions |
| hypotheses | [map()] | Formed hypotheses |
| experiments | [ExperimentPortfolio] | Designed experiment portfolios |
| priority | float | Priority score (0.0–1.0) |
| budget | ExperimentBudget | Resource allocation |
| status | atom | `:active`, `:paused`, `:completed`, `:terminated` |
| dependencies | [String] | Program dependency IDs |
| success_criteria | [String] | Criteria for completion |
| evidence_ledger | [map()] | Collected evidence entries |
| replay_fingerprint | String | Deterministic replay hash |
| archaeology_root | String | Root evidence ID for lineage |
| created_at | String | ISO 8601 timestamp |

### 2. ResearchCampaign (`research_campaign.ex`)
| Field | Type | Description |
|---|---|---|
| campaign_id | String | Content-addressed ID (`rc_` + sha256) |
| program_id | String | Parent program ID |
| portfolio_id | String | Parent portfolio ID |
| experiment_ids | [String] | Experiments in campaign |
| execution_order | [String] | Ordered experiment IDs |
| status | atom | `:pending`, `:running`, `:completed`, `:failed` |
| started_at | String | ISO 8601 or nil |
| completed_at | String | ISO 8601 or nil |

### 3. ExperimentPortfolio (`experiment_portfolio.ex`)
| Field | Type | Description |
|---|---|---|
| portfolio_id | String | Content-addressed ID (`pf_` + sha256) |
| program_id | String | Parent program ID |
| experiments | [map()] | Experiment specifications |
| diversity_score | float | Scientific diversity metric (0.0–1.0) |
| expected_information_gain | float | Expected information gain |
| allocated_budget | ExperimentBudget | Budget for this portfolio |

### 4. ExperimentBudget (`experiment_budget.ex`)
| Field | Type | Description |
|---|---|---|
| budget_id | String | Content-addressed ID (`bd_` + sha256) |
| max_compute_units | integer | Maximum computation units |
| max_simulations | integer | Maximum Digital Twin simulations |
| max_wall_clock_ms | integer | Maximum wall clock time (ms) |
| priority_weight | float | Priority weight (0.0–1.0) |

### 5. ExperimentSchedule (`experiment_schedule.ex`)
| Field | Type | Description |
|---|---|---|
| schedule_id | String | Content-addressed ID (`sc_` + sha256) |
| program_id | String | Parent program ID |
| campaigns | [ResearchCampaign] | Campaign specifications |
| adaptive | boolean | Whether schedule adapts |
| created_at | String | ISO 8601 timestamp |

### 6. ResearchOutcome (`research_outcome.ex`)
| Field | Type | Description |
|---|---|---|
| outcome_id | String | Content-addressed ID (`ro_` + sha256) |
| experiment_id | String | Source experiment ID |
| hypothesis_id | String | Tested hypothesis ID |
| evidence | [ResearchEvidence] | Collected evidence |
| supported | boolean | Whether hypothesis was supported |
| effect_size | float | Statistical effect size |
| confidence | float | Confidence level (0.0–1.0) |
| replay_hash | String | Replay verification hash |

### 7. ResearchEvidence (`research_evidence.ex`)
| Field | Type | Description |
|---|---|---|
| evidence_id | String | Content-addressed ID (`re_` + sha256) |
| experiment_id | String | Source experiment ID |
| type | atom | `:observation`, `:measurement`, `:comparison` |
| variable | String | Measured variable |
| value | term | Observed value |
| confidence | float | Confidence (0.0–1.0) |
| timestamp | integer | Simulation tick |

### 8. ProgramMetrics (`program_metrics.ex`)
| Field | Type | Description |
|---|---|---|
| metrics_id | String | Content-addressed ID (`pm_` + sha256) |
| program_id | String | Parent program ID |
| experiments_completed | integer | Count of completed experiments |
| hypotheses_tested | integer | Count of tested hypotheses |
| theories_updated | integer | Count of theory updates |
| information_gained | float | Accumulated information gain |
| resource_utilization | float | Budget utilization (0.0–1.0) |
| knowledge_gaps_filled | integer | Gaps resolved |

## Behaviours

### 1. ResearchBehaviour (`research_behaviour.ex`)
```elixir
@callback start_program(ResearchProgram.t()) ::
            {:ok, ResearchProgram.t()} | {:error, term()}

@callback pause_program(ResearchProgram.t()) ::
            {:ok, ResearchProgram.t()} | {:error, term()}

@callback terminate_program(ResearchProgram.t()) ::
            {:ok, ResearchProgram.t()} | {:error, term()}

@callback get_status(ResearchProgram.t()) ::
            {:ok, atom()} | {:error, term()}
```

### 2. CampaignBehaviour (`campaign_behaviour.ex`)
```elixir
@callback execute_campaign(ResearchCampaign.t(), keyword()) ::
            {:ok, ResearchCampaign.t()} | {:error, term()}

@callback get_campaign_status(ResearchCampaign.t()) ::
            {:ok, atom()} | {:error, term()}

@callback cancel_campaign(ResearchCampaign.t()) ::
            {:ok, ResearchCampaign.t()} | {:error, term()}
```

### 3. PlanningBehaviour (`planning_behaviour.ex`)
```elixir
@callback plan_experiment(map(), keyword()) ::
            {:ok, ExperimentPortfolio.t()} | {:error, term()}

@callback validate_plan(ExperimentPortfolio.t()) ::
            {:ok, boolean()} | {:error, term()}

@callback estimate_cost(ExperimentPortfolio.t()) ::
            {:ok, ExperimentBudget.t()} | {:error, term()}
```

### 4. SchedulingBehaviour (`scheduling_behaviour.ex`)
```elixir
@callback schedule(ExperimentSchedule.t(), keyword()) ::
            {:ok, ExperimentSchedule.t()} | {:error, term()}

@callback reschedule(ExperimentSchedule.t(), keyword()) ::
            {:ok, ExperimentSchedule.t()} | {:error, term()}

@callback get_schedule(ExperimentSchedule.t()) ::
            {:ok, map()} | {:error, term()}
```

### 5. ReplayBehaviour (`replay_behaviour.ex`)
```elixir
@callback verify_replay(ResearchProgram.t()) ::
            {:ok, boolean()} | {:error, term()}

@callback compute_fingerprint(ResearchProgram.t()) ::
            {:ok, String.t()} | {:error, term()}

@callback get_replay_root(ResearchProgram.t()) ::
            {:ok, String.t()} | {:error, term()}
```

## API Surface

### Struct Constructors
- `ResearchProgram.new/1` — validates and returns `{:ok, %ResearchProgram{}} | {:error, reason}`
- `ResearchCampaign.new/1` — validates and returns `{:ok, %ResearchCampaign{}} | {:error, reason}`
- `ExperimentPortfolio.new/1` — validates and returns `{:ok, %ExperimentPortfolio{}} | {:error, reason}`
- `ExperimentBudget.new/1` — validates and returns `{:ok, %ExperimentBudget{}} | {:error, reason}`
- `ExperimentSchedule.new/1` — validates and returns `{:ok, %ExperimentSchedule{}} | {:error, reason}`
- `ResearchOutcome.new/1` — validates and returns `{:ok, %ResearchOutcome{}} | {:error, reason}`
- `ResearchEvidence.new/1` — validates and returns `{:ok, %ResearchEvidence{}} | {:error, reason}`
- `ProgramMetrics.new/1` — validates and returns `{:ok, %ProgramMetrics{}} | {:error, reason}`

### ID Generation
Each struct exports `generate_id/1` taking a canonical map and returning a content-addressed SHA-256 hex string with a type prefix:
- `rp_` — ResearchProgram
- `rc_` — ResearchCampaign
- `pf_` — ExperimentPortfolio
- `bd_` — ExperimentBudget
- `sc_` — ExperimentSchedule
- `ro_` — ResearchOutcome
- `re_` — ResearchEvidence
- `pm_` — ProgramMetrics

### Serialization
Each struct exports `deep_struct_to_map/1` for deterministic JSON serialization, handling nested structs, maps, lists, tuples, and primitives.

### Validation
Each struct exports `validate/1` returning `{:ok, struct} | {:error, reason}` with field-level checks.

## Freeze Confirmation

All schemas, contracts, and data models defined in Phase 17.8 are hereby frozen. No changes to struct fields, field types, ID prefix conventions, behaviour callbacks, or validation logic shall be made without a formal amendment to this certification document.

**Certification Date**: July 2026
**Certifying Artifact**: Phase 17.8 Autonomous Research Runtime Freeze
