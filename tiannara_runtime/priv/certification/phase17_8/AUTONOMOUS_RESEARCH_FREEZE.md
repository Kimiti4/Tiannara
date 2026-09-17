# Autonomous Research Programs & Experimentation — Constitutional Freeze

**Phase:** 17.8
**Freeze Date:** deterministic_generation_timestamp
**Reference:** AUTONOMOUS_RESEARCH_RUNTIME_FREEZE.md

This document certifies that all Phase 17.8 schemas are constitutionally frozen.

## Scope

- All **8 structs** are finalized: ResearchProgram, ResearchCampaign, ExperimentPortfolio, ExperimentBudget, ExperimentSchedule, ResearchOutcome, ResearchEvidence, ProgramMetrics
- All **5 behaviours** are finalized: ResearchBehaviour, CampaignBehaviour, PlanningBehaviour, SchedulingBehaviour, ReplayBehaviour
- All **8 engines** are finalized: KnowledgeGapPrioritizer, ExperimentPlanner, PortfolioOptimizer, ExperimentScheduler, TheoryUpdater, ResearchArchaeology, ResearchMathVerification, ResearchProgramEngine

## Constraints

No further modifications are permitted to any Phase 17.8 schema, behaviour, or engine without a formal constitutional amendment. The runtime freeze (AUTONOMOUS_RESEARCH_RUNTIME_FREEZE.md) governs all execution paths and prohibits:

- Hardcoded domain defaults
- Wall-clock timestamps in deterministic paths
- Random/network-dependent computation
- Placeholder or mock artifacts

All structs use content-addressed IDs via `TiannaraRuntime.Shared.Canonical`. All engines fail closed on missing configuration. All behaviours define explicit callback contracts with typed return values.

## Signature

This freeze is certified by the Phase 17.8 Final Certification authority.
