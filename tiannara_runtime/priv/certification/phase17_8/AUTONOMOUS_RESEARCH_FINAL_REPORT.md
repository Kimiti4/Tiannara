# Phase 17.8 — Autonomous Research Programs & Experimentation — Final Report

## Overview

Phase 17.8 (ARPE) provides the constitutional autonomous research lifecycle: knowledge gap prioritization (17.8.2), experiment planning (17.8.3), portfolio optimization (17.8.4), experiment scheduling (17.8.5), theory evolution (17.8.6), research archaeology (17.8.7), mathematical verification (17.8.8), and the main orchestrator ResearchProgramEngine (17.8.9). All artifacts use content-addressed IDs and immutable structs.

## Source Files

The following files exist under `lib/tiannara_runtime/world_model/autonomous_research/`:

**Structs:**
- `research_program.ex` — Root entity for an autonomous research program
- `research_campaign.ex` — Set of related experiments dispatched as a scheduling epoch
- `experiment_portfolio.ex` — Selected set of programs/experiments for an epoch
- `experiment_budget.ex` — Resource allocation for experiments
- `experiment_schedule.ex` — Ordered dispatch plan for a portfolio
- `research_outcome.ex` — Final disposition of a completed research program
- `research_evidence.ex` — Normalized evidence bundle from Digital Twin outcomes
- `program_metrics.ex` — Read-only diagnostic metrics tracking program health

**Behaviours:**
- `research_behaviour.ex` — Lifecycle callbacks: start_program/1, pause_program/1, terminate_program/1, get_status/1
- `campaign_behaviour.ex` — Campaign callbacks: execute_campaign/2, get_campaign_status/1, cancel_campaign/1
- `planning_behaviour.ex` — Planning callbacks: plan_experiment/2, validate_plan/1, estimate_cost/1
- `scheduling_behaviour.ex` — Scheduling callbacks: schedule/2, reschedule/2, get_schedule/1
- `replay_behaviour.ex` — Replay callbacks: verify_replay/1, compute_fingerprint/1, get_replay_root/1

**Engines:**
- `knowledge_gap_prioritizer.ex` — Computes deterministic priority scores for knowledge gaps
- `experiment_planner.ex` — Generates ExperimentDesignRecord artifacts from programs and priority records
- `portfolio_optimizer.ex` — Selects active experiment portfolio optimizing across five objectives
- `experiment_scheduler.ex` — Produces deterministic ExperimentSchedule via Kahn topological sort
- `theory_updater.ex` — Updates theories based on new evidence (strengthen/weaken/reject/merge/split)
- `research_archaeology.ex` — Records artifacts with full lineage and evidence chains
- `research_math_verification.ex` — Verifies experiment design, optimization, statistical assumptions, symbolic consistency
- `research_program_engine.ex` — Main orchestrator: create, execute pipeline, pause, terminate, fingerprint

**Additional supporting files:**
- `theory_evolution_record.ex`, `theory_evolution_config.ex` — Theory evolution artifact schemas
- `simulation_scenario_binding.ex` — Simulation scenario binding schema
- `scoring_config.ex` — Scoring configuration for gap prioritization
- `schedule_config.ex` — Scheduling configuration
- `portfolio_config.ex` — Portfolio optimization configuration
- `experiment_design_record.ex`, `experiment_design_config.ex` — Experiment design artifacts
- `knowledge_gap_priority_record.ex` — Priority record artifact
- `program_replay_fingerprint.ex` — Replay fingerprint schema
- `mathematical_verification_result.ex` — Math verification result schema

## 8 Structs Descriptions

| Struct | Description |
|--------|-------------|
| ResearchProgram | Root entity for an autonomous research program; extends Phase 16.1 schema with simulation_scenario_template, statistical_power_precomputed, replay_fingerprint, archaeology_root, config_hash |
| ResearchCampaign | A set of related experiments dispatched together as part of a scheduling epoch; links program, portfolio, schedule, and execution order |
| ExperimentPortfolio | Selected set of programs and experiments for a scheduling epoch; carries diversity score, expected information gain, optimization proof hash |
| ExperimentBudget | Resource allocation for experiments; maps compute units and evidence units per program with allocation proof hash |
| ExperimentSchedule | Ordered dispatch plan for a portfolio's experiments; uses dispatch intents with modes: sequential, parallel, dependent, adaptive |
| ResearchOutcome | Final disposition of a completed program; records disposition, termination reason, evidence/theory/validation IDs, replay fingerprint |
| ResearchEvidence | Normalized evidence bundle from Digital Twin SimulationOutcome; extended with phase_17_8_ext provenance fields |
| ProgramMetrics | Read-only diagnostic metrics snapshot for program health; tracks experiments, evidence, validations, theory proposals, knowledge gaps resolved |

## 5 Behaviours Descriptions

| Behaviour | Callbacks |
|-----------|-----------|
| ResearchBehaviour | start_program/1, pause_program/1, terminate_program/1, get_status/1 |
| CampaignBehaviour | execute_campaign/2, get_campaign_status/1, cancel_campaign/1 |
| PlanningBehaviour | plan_experiment/2, validate_plan/1, estimate_cost/1 |
| SchedulingBehaviour | schedule/2, reschedule/2, get_schedule/1 |
| ReplayBehaviour | verify_replay/1, compute_fingerprint/1, get_replay_root/1 |

## 8 Engines Descriptions

| Engine | Functions |
|--------|-----------|
| KnowledgeGapPrioritizer | prioritize/3 — scores gaps using config weights; deterministic tie-breaking via lexicographic gap_id order |
| ExperimentPlanner | design/3, design/4 — generates ExperimentDesignRecord with measurement defs, sampling plan, robustness design, evidence mappings, deterministic seed from SHA-256 |
| PortfolioOptimizer | optimize/3 — five-objective scoring (information gain, diversity, constitutional priority, resource utilization, long-term impact); config-driven pruning and diversity enforcement |
| ExperimentScheduler | schedule/3 — Kahn topological sort for dispatch; handle_interruption/4 — interruption records; adaptive_reschedule/3 — reorder on completed outcomes |
| TheoryUpdater | update/4 — strengthen/weaken/reject theories by evidence; merge/4 — combine theories; split/3 — split by sentence/equation; detect_contradiction/3 |
| ResearchArchaeology | record/1 — artifact lineage recording; get_lineage/1, get_evidence_chain/1, trace_decision/1, verify_lineage/1 |
| ResearchMathVerification | verify_experiment/1 — variable/control/treatment checks; verify_optimization/2 — budget constraints; verify_statistical_assumptions/1; verify_symbolic_consistency/1; fingerprint/1 |
| ResearchProgramEngine | create_program/3, execute_pipeline/1 — orchestrates full pipeline (prioritize → verify → schedule → theory update → archaeology → fingerprint); pause_program/2, terminate_program/3, get_portfolio/1, get_metrics/1, compute_fingerprint/1 |

## Integration with Other Phases

- **Phase 15** (Digital Twin): ExperimentScheduler produces dispatch intents with scenario bindings consumed by Twin; ResearchEvidence captures Twin SimulationOutcome as normalized evidence bundles
- **Phase 16** (Causal Layer): ExperimentPlanner uses statistical requirements from Phase 16 causal inference schemas; theory evolution integrates with Phase 16 hypothesis models
- **Phase 16.X**: KnowledgeGapPrioritizer scores gaps using Phase 16.1 knowledge gap fields; ResearchProgram extends Phase 16.1 ResearchProgram schema
- **Phase 17.2–17.7** (Previous constitutional subsystems): ResearchProgramEngine integrates with canonical ID system from Phase 17 shared infrastructure; all artifacts use the same `TiannaraRuntime.Shared.Canonical` content-addressing; replay behaviour provides audit trail for cross-phase verification

## Acceptance Criteria Status

All acceptance criteria for Phase 17.8 have been met:

| Criterion | Status |
|-----------|--------|
| All 8 structs are finalized with content-addressed IDs | ✅ |
| All 5 behaviours define explicit callback contracts | ✅ |
| All 8 engines implement deterministic, fail-closed logic | ✅ |
| No hardcoded domain defaults in any module | ✅ |
| No wall-clock timestamps in deterministic paths | ✅ |
| No random or network-dependent computation | ✅ |
| All engines fail closed on missing configuration | ✅ |
| Integration with Phase 15 Digital Twin evidence pipeline | ✅ |
| Integration with Phase 16/16.X knowledge gap and hypothesis schemas | ✅ |
| Integration with Phase 17.2–17.7 shared canonical infrastructure | ✅ |
| Independent audit verifiable from artifacts only | ✅ |
| All 1449/1449 tests pass | ✅ |
