# Phase 19 — Civilizational Pipeline

## Overview

The civilizational pipeline defines the sequential, deterministic flow of data and control through all Phase 19 components. Every transition is certified, logged, and archaeologically recoverable.

## Pipeline Transitions

### T1: CivilizationController → InstitutionManager

| Field | Value |
|-------|-------|
| Input | CivilizationConfig, GenesisArtifact |
| Output | RegisteredInstitutions |
| Owner | CivilizationController |
| Replay | civilization_replay artifact (civilization_root) |
| Evidence | InstitutionRegistrationEvidence |
| Archaeology | CivilizationOriginArchaeology |

### T2: InstitutionManager → ResearchProgram

| Field | Value |
|-------|-------|
| Input | InstitutionCharter, ScientistRegistry |
| Output | ResearchPrograms |
| Owner | InstitutionManager |
| Replay | institution_replay artifact (institution_root) |
| Evidence | ProgramCreationEvidence |
| Archaeology | InstitutionGenesisArchaeology |

### T3: ResearchProgram → PortfolioGovernor

| Field | Value |
|-------|-------|
| Input | ResearchPrograms, ProgramMetrics |
| Output | GovernedPortfolio |
| Owner | PortfolioGovernor |
| Replay | portfolio_replay artifact (portfolio_root) |
| Evidence | PortfolioGovernanceEvidence |
| Archaeology | PortfolioDecisionArchaeology |

### T4: PortfolioGovernor → ScientificEconomy

| Field | Value |
|-------|-------|
| Input | GovernedPortfolio, NoveltyScores, MaturityScores |
| Output | CapitalAllocations, RewardDistributions |
| Owner | ScientificEconomy |
| Replay | economy_replay artifact (economy_root) |
| Evidence | EconomySettlementEvidence |
| Archaeology | EconomyFlowArchaeology |

### T5: ScientificEconomy → CollaborationEngine

| Field | Value |
|-------|-------|
| Input | CapitalAllocations, InstitutionCapabilities |
| Output | CollaborationGraph |
| Owner | CollaborationEngine |
| Replay | collaboration_replay artifact (collaboration_root) |
| Evidence | CollaborationFormationEvidence |
| Archaeology | CollaborationNetworkArchaeology |

### T6: CollaborationEngine → CivilizationKnowledgeGraph

| Field | Value |
|-------|-------|
| Input | CollaborationGraph, DiscoveryArtifacts |
| Output | MergedKnowledgeGraph |
| Owner | CivilizationKnowledgeGraph |
| Replay | knowledge_replay artifact (knowledge_root) |
| Evidence | KnowledgeMergeEvidence |
| Archaeology | KnowledgeGenesisArchaeology |

### T7: CivilizationKnowledgeGraph → Replay

| Field | Value |
|-------|-------|
| Input | All evidence artifacts |
| Output | DeterministicReplay |
| Owner | CivilizationReplay |
| Replay | recursive_replay artifact |
| Evidence | ReplayFidelityEvidence |
| Archaeology | ReplayArchaeology |

### T8: Replay → Archaeology

| Field | Value |
|-------|-------|
| Input | All replay artifacts |
| Output | CivilizationArchaeology |
| Owner | CivilizationArchaeology |
| Replay | archaeology_replay artifact |
| Evidence | ArchaeologyCompletenessEvidence |
| Archaeology | ArchaeologyOfArchaeology |

## Institution Registry

The InstitutionManager maintains a registry of five constitutional institutes:

| Institute | Domain | Charter Prefix |
|-----------|--------|----------------|
| Physics | Fundamental laws, energy, matter | INST_PHYS |
| Mathematics | Formal systems, proofs, structures | INST_MATH |
| Robotics | Autonomous systems, embodiment | INST_ROBO |
| Medicine | Biological cognition, health | INST_MED |
| Engineering | Applied systems, infrastructure | INST_ENG |
