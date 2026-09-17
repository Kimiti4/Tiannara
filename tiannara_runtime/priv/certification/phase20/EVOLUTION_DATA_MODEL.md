# Phase 20.3 — Evolution Data Model

## Evolution Object Hierarchy

All evolution objects inherit from the base ConstitutionalObject (Phase 20.1), adding evolution-specific fields:

```
ConstitutionalObject (base)
├── EvolutionOpportunity
├── BottleneckReport
├── ArchitecturalHypothesis
├── ArchitectureCandidate
├── EvolutionCampaign
├── ExperimentResult
├── SandboxRun
├── CanaryRun
├── ProductionRun
├── EvolutionGeneration
├── RollbackPlan
├── RollbackEvent
├── EvolutionMetrics
├── GenerationLineage
├── EvolutionDecision
├── EvolutionReplay
└── EvolutionArchaeology
```

## Object Definitions

### EvolutionOpportunity
| Field | Type | Description |
|-------|------|-------------|
| opportunity_id | string | Content-addressed identifier |
| origin | string | Source subsystem or observation |
| bottleneck | string | Reference to BottleneckReport |
| priority | integer | Priority ranking (1 = highest) |
| estimated_gain | object | Expected improvement per metric |
| created_at | integer | Deterministic timestamp |
| status | string | Lifecycle stage |

### BottleneckReport
| Field | Type | Description |
|-------|------|-------------|
| bottleneck_id | string | Content-addressed identifier |
| category | string | One of 14 bottleneck categories |
| severity | string | Critical/Major/Moderate/Minor/Informational |
| impact | object | Quantitative impact description |
| frequency | string | Continuous/Periodic/Intermittent/Rare |
| evidence | array | References to ObservationRecords |
| root_cause | string | Identified root cause |
| historical_trends | array | Trend data over time |
| confidence | number | Confidence in bottleneck assessment |
| expected_resolution_gain | object | Estimated gain per metric |

### ArchitecturalHypothesis
| Field | Type | Description |
|-------|------|-------------|
| hypothesis_id | string | Content-addressed identifier |
| problem | string | Formal problem statement |
| prediction | string | Falsifiable prediction |
| assumptions | array | Key assumptions |
| expected_improvements | object | Quantitative improvement predictions |
| failure_conditions | array | Conditions that would falsify hypothesis |
| dependencies | array | Required preconditions |
| mathematical_justification | string | Formal mathematical reasoning |
| scientific_justification | string | Scientific basis |

### ArchitectureCandidate
| Field | Type | Description |
|-------|------|-------------|
| candidate_id | string | Content-addressed identifier |
| hypothesis | string | Reference to ArchitecturalHypothesis |
| description | string | Structural description |
| affected_components | array | Subsystems and components affected |
| interfaces | array | Interface specifications |
| data_flows | array | Data flow specifications |
| dependencies | array | Dependency graph |
| expected_metrics | object | Quantitative expectations |
| risk_assessment | object | Risk analysis and mitigations |
| required_extensions | array | New extensions required |
| benchmark_targets | object | Minimum passing thresholds |
| expected_cost | object | Resource and effort estimates |

### EvolutionCampaign
| Field | Type | Description |
|-------|------|-------------|
| campaign_id | string | Content-addressed identifier |
| candidate | string | Reference to ArchitectureCandidate |
| benchmark_plan | object | Benchmark suite specification |
| simulation_plan | object | Simulation environment and scope |
| validation_plan | object | Validation criteria and schedule |
| audit_plan | object | Independent audit specification |
| deployment_plan | object | Progressive deployment strategy |
| rollback_plan | string | Reference to RollbackPlan |

### ExperimentResult
| Field | Type | Description |
|-------|------|-------------|
| experiment_id | string | Content-addressed identifier |
| campaign | string | Reference to EvolutionCampaign |
| stage | string | Which pipeline stage produced this |
| simulation_artifacts | object | Simulation outputs |
| benchmark_results | object | Benchmark measurements |
| stress_results | object | Stress test outcomes |
| adversarial_results | object | Adversarial test outcomes |
| long_horizon_results | object | Long-horizon validation outcomes |
| evidence_root | string | Root hash of evidence chain |

### SandboxRun
| Field | Type | Description |
|-------|------|-------------|
| sandbox_id | string | Content-addressed identifier |
| candidate | string | Reference to ArchitectureCandidate |
| metrics | object | Sandbox measurements |
| simulation_comparison | object | Comparison with simulation predictions |
| status | string | Pass/Fail/InProgress |
| duration | integer | Run duration in simulation steps |
| replay_root | string | Root hash of replay chain |

### CanaryRun
| Field | Type | Description |
|-------|------|-------------|
| canary_id | string | Content-addressed identifier |
| candidate | string | Reference to ArchitectureCandidate |
| load_fraction | number | Fraction of production load |
| metrics | object | Canary measurements |
| sandbox_comparison | object | Comparison with sandbox predictions |
| status | string | Pass/Fail/InProgress |

### ProductionRun
| Field | Type | Description |
|-------|------|-------------|
| production_id | string | Content-addressed identifier |
| candidate | string | Reference to ArchitectureCandidate |
| generation | integer | Resulting generation number |
| metrics | object | Production measurements |
| canary_comparison | object | Comparison with canary predictions |
| status | string | Active/Frozen/RolledBack |

### EvolutionGeneration
| Field | Type | Description |
|-------|------|-------------|
| generation | integer | Monotonically increasing generation number |
| parent_generation | integer | Previous generation number |
| candidate | string | ArchitectureCandidate that produced this generation |
| integrated_extensions | array | Extensions added in this generation |
| retired_extensions | array | Extensions removed in this generation |
| constitutional_hash | string | SHA-256 hash of complete generation state |
| replay_root | string | Root hash of generation replay chain |
| archaeology_root | string | Root hash of generation archaeology |
| evidence_root | string | Root hash of generation evidence |

### RollbackPlan
| Field | Type | Description |
|-------|------|-------------|
| rollback_id | string | Content-addressed identifier |
| candidate | string | ArchitectureCandidate this plan protects |
| trigger_conditions | array | Conditions that trigger rollback |
| restoration_generation | integer | Generation to restore to |
| verification_strategy | string | How to verify successful restoration |
| rollback_steps | array | Ordered rollback procedure |

### RollbackEvent
| Field | Type | Description |
|-------|------|-------------|
| rollback_id | string | Content-addressed identifier |
| generation | integer | Generation that was rolled back |
| trigger | string | Specific condition that triggered rollback |
| trigger_evidence | object | Evidence of trigger condition |
| restored_generation | integer | Generation restored to |
| metrics | object | Metrics at time of rollback |
| rollback_plan | string | Reference to RollbackPlan used |

### EvolutionMetrics
| Field | Type | Description |
|-------|------|-------------|
| metrics_id | string | Content-addressed identifier |
| generation | integer | Generation these metrics describe |
| evolution_frequency | number | Rate of evolution generations |
| candidate_acceptance_rate | number | Fraction of candidates reaching production |
| rollback_rate | number | Fraction of generations rolled back |
| scientific_gain | number | Cumulative scientific improvement |
| engineering_gain | number | Cumulative engineering improvement |
| simulation_gain | number | Cumulative simulation improvement |
| performance_gain | number | Cumulative performance improvement |
| knowledge_growth | number | Knowledge growth rate |
| energy_efficiency | number | Energy efficiency trend |
| architectural_complexity | number | Complexity metric |
| replay_cost | number | Replay performance cost |
| audit_cost | number | Audit effort metric |
| extension_growth | number | Rate of extension adoption |
| generation_stability | number | Mean time between rollbacks |
| civilization_readiness | number | Civilization readiness metric |

### GenerationLineage
| Field | Type | Description |
|-------|------|-------------|
| lineage_id | string | Content-addressed identifier |
| generation | integer | Generation number |
| ancestry | array | Ordered list of ancestor generations |
| changes | array | Summary of changes from parent |
| bottlenecks_resolved | array | Bottlenecks addressed in lineage |
| candidates_tried | array | Candidates attempted (including rejected) |
| decisions | array | Key decisions with rationale |

### EvolutionDecision
| Field | Type | Description |
|-------|------|-------------|
| decision_id | string | Content-addressed identifier |
| candidate | string | Candidate this decision concerns |
| decision | string | Accept/Reject/Rollback/Defer |
| rationale | string | Complete rationale |
| evidence | array | Supporting evidence references |
| authority | string | Entity that made the decision |
| timestamp | integer | Deterministic decision timestamp |

## Lifecycle Stages Per Object

| Object | Lifecycle |
|--------|----------|
| EvolutionOpportunity | Detected → Verified → Prioritized → Addressed → Archived |
| BottleneckReport | Detected → Verified → Accepted → Resolved → Archived |
| ArchitecturalHypothesis | Draft → Validated → Tested → Confirmed/Falsified → Archived |
| ArchitectureCandidate | Draft → Validated → Simulated → Benchmarked → Audited → Certified → Rejected/Deployed → Archived |
| EvolutionCampaign | Draft → Validated → Executing → Completed → Archived |
| ExperimentResult | Draft → Validated → Audited → Archived |
| SandboxRun | Draft → Running → Validated → Passed/Failed → Archived |
| CanaryRun | Draft → Running → Validated → Passed/Failed → Archived |
| ProductionRun | Draft → Running → Active → Frozen/RolledBack → Archived |
| EvolutionGeneration | Draft → Validated → Frozen → Observed → Archived |
| RollbackPlan | Draft → Validated → Armed → Triggered/Retired → Archived |
| RollbackEvent | Draft → Validated → Executed → Archived |
| EvolutionMetrics | Draft → Collected → Validated → Archived |
| GenerationLineage | Draft → Validated → Archived |
| EvolutionDecision | Draft → Validated → Certified → Archived |
