# Constitutional Capability Matrix — Phase 12 & 13

**Last Updated**: 2026-06-13  
**Status**: Institutional Execution Model Frozen | Epoch II Complete (12.8-12.10) | **Epoch III COMPLETE (12.11-12.13: 3/3 frozen)** | **Phase 13 In Progress (13.1: ✅ FROZEN)**

---

## Overview

This matrix tracks all Phase 12 institutional capabilities, their canonical artifacts, public APIs, constitutional components, validation status, and freeze state. It serves as the operational dashboard for remaining Phase 12 work and prevents architectural drift by making it immediately obvious whether a proposed change introduces a genuinely new capability or merely reimplements existing functionality.

---

## Frozen Capabilities (Constitutional Infrastructure)

| Capability | Canonical Artifact | Public API | Constitutional Components | Validation Status | Frozen |
|------------|-------------------|------------|--------------------------|-------------------|--------|
| **12.1.2B**<br>Institutional Scientific Investigation | `ResearchCycleResult` | `InstitutionKernel.conduct_research_cycle/3` | InstitutionKernel, Governance Engine, Economic Ledger, Knowledge Graph, Memory Pipeline, Lifecycle Registry, Semantic Event Bus | ✅ 7/7 scenarios | ✅ Yes |
| **12.2.1**<br>Inter-Institution Exchange | `PublicationResult`<br>`ConsensusResult` | `InstitutionKernel.publish_findings/3`<br>`InstitutionKernel.request_consensus/3` | InstitutionKernel, Knowledge Graph, Economic Ledger, Governance Engine, Discovery Exchange Protocol | ✅ Validated | ✅ Yes |
| **12.3**<br>Domain Profiles | `DomainProfile`<br>(configuration artifact) | `DomainProfile.load/1`<br>`DomainProfile.apply/2` | InstitutionKernel (receives profile), ResearchInstitution struct | ✅ 20 domains validated | ✅ Yes |
| **12.4.1**<br>Constitutionally Consistent Belief Revision | `BeliefRevisionResult` | `InstitutionKernel.revise_beliefs/3` | InstitutionKernel, JTMS++ (internal), Knowledge Graph, Governance Engine, Economic Ledger, Memory Pipeline, Lifecycle Registry, Semantic Event Bus | ✅ 7/7 scenarios | ✅ Yes |
| **12.5.0**<br>Institutional Episode Formation | `ResearchEpisode` | *(Internal orchestration)*<br>Automatically created by `conduct_research_cycle/3` | InstitutionKernel, ResearchEpisode struct, civilizational_memory storage | ✅ Gate 2.5 passed (7/7 scenarios) | ✅ Yes |
| **12.5.1**<br>Institutional Episode Retrieval | `ExperienceRetrievalResult` | `InstitutionKernel.retrieve_experience/3` | InstitutionKernel, EpisodeIndex (derived service), ResearchEpisode objects, civilizational_memory storage | ✅ 7/7 scenarios | ✅ Yes |
| **12.6**<br>Institutional Causal Intervention Reasoning | `InterventionReasoningResult` | `InstitutionKernel.reason_about_intervention/3` | ResearchEpisode, EpisodeIndex, Knowledge Graph, Causal Engine (internal) | ✅ 7/7 scenarios | ✅ Yes |
| **12.7**<br>Institutional Reasoning Strategy Selection | `ReasoningStrategyResult` | `InstitutionKernel.select_reasoning_strategy/3` | ResearchEpisode, EpisodeIndex, DomainProfile, Governance Engine, Economic Ledger | ✅ 7/7 scenarios | ✅ Yes |
| **12.8**<br>Evaluate Epistemic Health | `EpistemicHealthResult` | `InstitutionKernel.evaluate_epistemic_health/2` | InstitutionKernel, Episode monitoring, Anomaly detection (internal), Governance Engine, Economic Ledger | ✅ 7/7 scenarios | ✅ Yes |
| **12.9**<br>Institutional Scientific Coordination | `ResearchCoordinationResult` | `InstitutionKernel.coordinate_research/2` | InstitutionKernel, ResearchEpisode, EpisodeIndex, Governance Engine, Economic Ledger, Lifecycle Registry | ✅ 8/8 scenarios | ✅ Yes |
| **12.10**<br>Distributed Scientific Validation | `DistributedValidationResult` | `InstitutionKernel.validate_distributed_claim/4` | InstitutionKernel, ResearchEpisode, EpisodeIndex, DistributedValidationResult, Knowledge Graph, Governance Engine (supervisory only) | ✅ 8/8 scenarios | ✅ Yes |
| **12.11**<br>Institutional Theory Formation | `TheoryFormationResult` | `InstitutionKernel.form_theory/2` | InstitutionKernel, ResearchEpisode, EpisodeIndex, DistributedValidationResult, Knowledge Graph, Lifecycle Registry, Economic Ledger | ✅ 7/7 scenarios | ✅ Yes |
| **12.12**<br>Topological Scientific Reasoning | `ScientificTopologyResult` | `InstitutionKernel.analyze_scientific_topology/2` | InstitutionKernel, TheoryFormationResult, Knowledge Graph, Lifecycle Registry, Economic Ledger | ✅ 7/7 scenarios | ✅ Yes |
| **12.13**<br>Autonomous Research Planning | `ResearchPlanResult` | `InstitutionKernel.plan_research/2` | InstitutionKernel, ScientificTopologyResult, TheoryFormationResult, Knowledge Graph, Lifecycle Registry, Economic Ledger | ✅ 7/7 scenarios | ✅ Yes |

---

## All Capabilities Frozen ✅

**Phase 12 is COMPLETE.** All institutional capabilities have been implemented, validated, and constitutionally frozen.

---

## Phase 13 — Self-Evolving Scientific Civilization (In Progress)

| Capability | Canonical Artifact | Public API | Constitutional Components | Validation Status | Frozen |
|------------|-------------------|------------|--------------------------|-------------------|--------|
| **13.1**<br>Institution Self-Model Formation | `InstitutionSelfModel` | `InstitutionKernel.construct_self_model/2` | InstitutionKernel, ResearchEpisode, TheoryFormationResult, ScientificTopologyResult, ResearchPlanResult, DistributedValidationResult, EpistemicHealthResult, Knowledge Graph, EpisodeIndex, Lifecycle Registry, Economic Ledger | ✅ 7/7 scenarios | ✅ Yes |

---

## Constitutional Primitives (Immutable Until Phase 13)

### Core Primitives
- **Institution** - Owning entity for all institutional activity
- **ResearchEpisode** - Immutable unit of institutional history (Principle 12)
- **ResearchCycleResult** - Canonical transaction for scientific investigation
- **BeliefRevisionResult** - Canonical transaction for epistemic change
- **ExperienceRetrievalResult** - Canonical transaction for memory access
- **InterventionReasoningResult** - Canonical transaction for causal intervention reasoning
- **ReasoningStrategyResult** - Canonical transaction for reasoning strategy selection
- **EpistemicHealthResult** - Canonical transaction for institutional health evaluation
- **ResearchCoordinationResult** - Canonical transaction for institutional coordination
- **DistributedValidationResult** - Canonical transaction for distributed validation
- **TheoryFormationResult** - Canonical transaction for theory formation
- **ScientificTopologyResult** - Canonical transaction for topology analysis
- **ResearchPlanResult** - Canonical transaction for research planning
- **InstitutionSelfModel** - Canonical transaction for institution self-model formation (Phase 13)
- **Knowledge Graph** - Immutable event-sourced knowledge store
- **EpisodeIndex** - Derived index over ResearchEpisodes (rebuildable)
- **InstitutionKernel** - GenServer orchestrating institutional cognition

### Supporting Infrastructure
- Runtime Atlas - System-wide observability
- Lifecycle Registry - Entity lifecycle tracking
- Semantic Event Bus - Domain-specific event emission
- Governance Engine - Approval/rejection decisions
- Economic Ledger - Resource accounting
- Memory Pipeline - Operational → Civilizational memory consolidation
- Validation Framework - Constitutional invariant checking

### Constitutional Principles
- **Principles 1–15** (including Institutional Episodic Integrity and Separation of Knowledge/Governance)
- **Three-Artifact Rule** (Specification + Validation + Report)
- **Capability-first engineering discipline**
- **No new persistent state unless extending constitutional model**
- **One capability, one API, one transaction**

---

## Architectural Layers

```
┌─────────────────────────────────────────────────┐
│           CONSTITUTIONAL LAYER (Frozen)          │
│  • Principles 1-12                               │
│  • Constitutional invariants                     │
│  • Three-Artifact Rule                           │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│        INSTITUTIONAL EXECUTION MODEL             │
│  • InstitutionKernel                             │
│  • ResearchEpisode                               │
│  • Canonical Transactions                        │
│  • Knowledge Graph                               │
│  • EpisodeIndex                                  │
│  • Lifecycle / Ledger / Memory / Governance      │
└─────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────┐
│         INSTITUTIONAL CAPABILITIES               │
│  • 12.1 Research Runtime ✅                      │
│  • 12.2 Inter-Institution Exchange ✅            │
│  • 12.3 Domain Profiles ✅                       │
│  • 12.4 Belief Revision ✅                       │
│  • 12.5 Semantic Memory ✅                       │
│  • 12.6 Causal Intervention ✅                   │
│  • 12.7 Strategy Selection ✅ (INDIVIDUAL)       │
│  • 12.8 Epistemic Health ✅ (ECOLOGY START)      │
│  • 12.9 Scientific Coordination ✅               │
│  • 12.10 Distributed Validation ✅ (ECOLOGY END) │
│  • 12.11 Theory Formation ✅ (CIV START)         │
│  • 12.12 Topological Reasoning ⏳                │
│  • 12.13 Autonomous Planning ⏳ (CIV END)        │
└─────────────────────────────────────────────────┘
```

**Key Property**: Everything above the "Institutional Execution Model" line is **constitutional infrastructure** (frozen). Everything below is **institutional capability** (behavioral enrichment).

---

## Implementation Discipline

Every new capability must answer three questions before implementation begins:

1. **What institutional capability is being realized?**
   - Clear behavioral specification (not algorithmic detail)
   - Observable outcome from institution's perspective

2. **Which constitutional components compose it?**
   - Must use only frozen primitives
   - No new persistent state unless extending constitutional model
   - Internal algorithms are replaceable implementation details

3. **Which constitutional invariants prove it works?**
   - Seven validation scenarios (mirroring earlier capabilities)
   - All scenarios must pass against genuine institutional history
   - Principle compliance verified (especially Principles 11-12)

If these three questions cannot be answered cleanly, the implementation is not ready.

---

## Next Steps: Capability 12.6

**Capability Name**: Institutional Causal Intervention Reasoning  
**Objective**: Every Research Institution can reason about interventions and counterfactuals by composing immutable Research Episodes, canonical transactions, and the frozen constitutional substrate while preserving complete explainability and constitutional integrity.

**Proposed Canonical Artifact**: `InterventionReasoningResult`  
**Proposed Public API**: `InstitutionKernel.reason_about_intervention/3`

**Validation Scenarios** (to be defined):
1. Successful intervention prediction
2. Counterfactual reasoning ("What if experiment B had been chosen?")
3. Negative intervention handling
4. Insufficient causal evidence
5. Governance rejection
6. Budget exhaustion
7. Twenty institutions reasoning simultaneously

**Constitutional Components**:
- ResearchEpisode (source of intervention history)
- EpisodeIndex (retrieve similar interventions)
- Knowledge Graph (causal relationships)
- Causal Engine (internal - do-calculus implementation)

**Status**: Ready to begin specification phase.

---

## Notes

- This matrix should be updated after each capability validation
- Frozen capabilities may only be modified for bug fixes (no architectural changes)
- New capabilities must follow the Three-Artifact Rule
- Validation scenarios should mirror the seven-scenario pattern established by earlier capabilities
- The goal is behavioral enrichment, not architectural redesign
