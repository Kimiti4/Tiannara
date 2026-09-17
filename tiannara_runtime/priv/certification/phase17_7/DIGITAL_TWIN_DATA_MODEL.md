# Phase 17.7 — Digital Twin Data Model

## 1. Core Structs

### DigitalTwin

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| twin_id | String | computed | `dt_` + SHA-256 |
| name | String | yes | Twin name |
| parent_model_ids | [String.t()] | yes | Constituent model IDs |
| composition_id | String | yes | Parent composition ID |
| clock | SimulationClock.t() | yes | Simulation clock |
| state | TwinState.t() | yes | Current twin state |
| intervention_queue | InterventionQueue.t() | no | Queued interventions |
| scenario_registry | [SimulationScenario.t()] | no | Registered scenarios |
| event_timeline | [SimulationEvent.t()] | no | Executed events |
| metrics | [TwinMetrics.t()] | no | Computed metrics |
| evidence_ledger | [map()] | no | Tick evidence |
| archaeology_root | String | no | Archaeology lineage root |
| replay_fingerprint | String | computed | `fp_` + SHA-256 |
| certificate | map() | no | Certification |
| created_at | String | computed | ISO 8601 |

### TwinState

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| state_id | String | computed | `ts_` + SHA-256 |
| tick | non_neg_integer | yes | Simulation tick |
| model_states | %{String.t() => map()} | yes | Per-model state snapshots |
| shared_variables | %{String.t() => term()} | no | Resolved shared variables |
| metadata | map() | no | Extra metadata |

### SimulationClock

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| clock_id | String | computed | `sc_` + SHA-256 |
| mode | atom | yes | :fixed \| :variable \| :event_driven \| :hybrid |
| tick | non_neg_integer | yes | Current tick |
| time | float | yes | Simulation time |
| delta | float | yes | Current timestep |
| total_ticks | non_neg_integer | no | Total ticks executed |
| seed | integer | no | Random seed |
| metadata | map() | no | Extra metadata |

### SimulationEvent

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| event_id | String | computed | `se_` + SHA-256 |
| name | String | yes | Event name |
| type | atom | yes | :engineering \| :policy \| :disaster \| :discovery \| :economic \| :medical \| :infrastructure \| :environmental |
| trigger_tick | non_neg_integer | yes | Tick to fire |
| probability | float | no | Probability (0.0-1.0) |
| effects | map() | yes | State modifications |
| dependencies | [String.t()] | no | Event dependencies |
| metadata | map() | no | Extra metadata |

### InterventionQueue

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| queue_id | String | computed | `iq_` + SHA-256 |
| interventions | [ScheduledIntervention.t()] | yes | Ordered interventions |
| dependency_graph | map() | no | Dependency edges |

### ScheduledIntervention

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| scheduled_id | String | computed | `si_` + SHA-256 |
| intervention | map() | yes | Intervention specification |
| schedule_type | atom | yes | :immediate \| :delayed \| :conditional \| :recurring \| :adaptive |
| trigger_tick | non_neg_integer | no | Tick to apply |
| condition | map() | no | Conditional trigger |
| recurrence | non_neg_integer | no | Recurrence interval |
| dependencies | [String.t()] | no | Intervention dependencies |
| metadata | map() | no | Extra metadata |

### SimulationScenario

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| scenario_id | String | computed | `ss_` + SHA-256 |
| name | String | yes | Scenario name |
| initial_conditions | map() | yes | Initial state |
| events | [SimulationEvent.t()] | no | Scheduled events |
| interventions | [ScheduledIntervention.t()] | no | Scheduled interventions |
| total_ticks | non_neg_integer | yes | Max ticks |
| metrics_config | [atom()] | no | Metrics to compute |
| seed | integer | no | Random seed |
| metadata | map() | no | Extra metadata |

### SimulationOutcome

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| outcome_id | String | computed | `so_` + SHA-256 |
| scenario_id | String | yes | Parent scenario |
| final_state | TwinState.t() | yes | Final state |
| metrics | [TwinMetrics.t()] | yes | Computed metrics |
| events_executed | non_neg_integer | yes | Event count |
| interventions_executed | non_neg_integer | yes | Intervention count |
| emergent_patterns | [map()] | no | Detected patterns |
| replay_fingerprint | String | computed | `fp_` + SHA-256 |
| metadata | map() | no | Extra metadata |

### TwinMetrics

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| metrics_id | String | computed | `tm_` + SHA-256 |
| tick | non_neg_integer | yes | Tick |
| economic_output | float | no | GDP or equivalent |
| scientific_productivity | float | no | Research output |
| infrastructure_health | float | no | 0.0-1.0 scale |
| governance_stability | float | no | 0.0-1.0 scale |
| ecological_resilience | float | no | 0.0-1.0 scale |
| energy_efficiency | float | no | 0.0-1.0 scale |
| logistics_performance | float | no | 0.0-1.0 scale |
| medical_outcomes | float | no | 0.0-1.0 scale |
| knowledge_growth | float | no | Knowledge units |
| civilization_readiness | float | no | 0.0-1.0 scale |
| metadata | map() | no | Extra metadata |

## 2. ID Prefixes

| Prefix | Struct |
|--------|--------|
| `dt_` | DigitalTwin |
| `ts_` | TwinState |
| `sc_` | SimulationClock |
| `se_` | SimulationEvent |
| `iq_` | InterventionQueue |
| `si_` | ScheduledIntervention |
| `ss_` | SimulationScenario |
| `so_` | SimulationOutcome |
| `tm_` | TwinMetrics |
| `fp_` | Replay fingerprint |

## 3. Serialization Rules

- All structs implement `canonicalize/1` returning key-sorted map
- Nested structs canonicalized recursively
- Atoms stringified via `Atom.to_string/1`
- Lists sorted where order is semantically irrelevant
- ID computed via SHA-256 over canonical JSON
- Replay fingerprint excludes: twin_id, archaeology_root, created_at, metadata, replay_fingerprint, certificate, evidence_ledger
