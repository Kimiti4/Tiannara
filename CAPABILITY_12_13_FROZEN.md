# CAPABILITY 12.13 FROZEN — Autonomous Research Planning

**Status**: ✅ **FROZEN**  
**Date**: June 13, 2026  
**Epoch**: III — Civilizational Cognition  
**Phase**: 12 — Scientific Institution  

---

## Executive Summary

Capability 12.13 — **Autonomous Research Planning** has been successfully implemented, validated (7/7 scenarios passing), and is now constitutionally frozen.

This capability represents the first demonstration of **institutional agency** in Tiannara — the ability of scientific institutions to autonomously determine their own research direction based on rational assessment of the scientific landscape, rather than executing externally-defined tasks.

---

## What Was Accomplished

### 1. Canonical Transaction Created ✅

[`ResearchPlanResult`](file:///c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/lib/tiannara/os/research_plan_result.ex) (~774 lines) captures complete research planning audit trail including:

- **Candidate research questions** - Potential investigations under consideration
- **Knowledge gaps** - Identified weaknesses in current understanding
- **Research programs** - Higher-level organizational units containing related experiments
- **Recommended experiments** - Specific investigations with full specifications
- **Prioritized research queue** - Ranked by expected information gain and cost efficiency
- **Expected outcomes** - Information gain, uncertainty reduction estimates
- **Resource estimates** - Cost, duration, budget constraints
- **Planning rationale** - Explanations for WHY each recommendation was selected
- **Supporting evidence** - References to theories, topology, gaps
- **Constitutional deltas** - Knowledge delta, ledger delta, traceability graph
- **Lifecycle events** - Complete planning progression audit trail

**Key Innovation**: Introduction of **Research Programs** as organizational unit between plans and experiments, aligning with institutional scale established in Capability 12.9.

### 2. Public API Implemented ✅

Added [`InstitutionKernel.plan_research/2`](file:///c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/lib/tiannara/os/institution_kernel.ex) to InstitutionKernel:

```elixir
@doc """
Plan autonomous research based on scientific reasoning.

This is the ONLY public API for autonomous research planning.
The internal mechanisms (planning algorithms, optimization strategies,
ranking heuristics) are hidden inside InstitutionKernel and never exposed externally.

## Parameters

- `institution_pid`: pid() | atom() - target institution
- `opts`: map() - optional parameters (:budget_limit, :time_horizon, :priority_focus)

## Returns

{:ok, ResearchPlanResult.t()} | {:error, String.t()}
"""
def plan_research(institution_pid, opts \\ %{}) do
  GenServer.call(via_pid(institution_pid), {:plan_research, opts})
end
```

**Constitutional Discipline**: Only one public behavior exposed. Callers cannot access planning algorithms, optimization strategies, ranking heuristics, search procedures, or decision trees.

### 3. Six-Phase Pipeline Implemented ✅

#### Phase 1: Gather Scientific State
- Retrieves budget constraints and time horizon from opts
- Loads topology inputs (clusters, gaps, contradictions, bridges)
- Records scientific state in semantic events

#### Phase 2: Identify Research Opportunities
- Searches for knowledge gaps requiring investigation
- Identifies contradictions needing experimental resolution
- Detects sparse clusters suggesting missing theories
- Finds missing bridges between disconnected domains

#### Phase 3: Generate Candidate Experiments ⭐ KEY INNOVATION
- **Domain-aware program generation** based on institutional profile
- **Budget-aware experiment counting** (higher budgets → more experiments)
- Four domain-specific generators:
  - **Medicine**: Clinical biomarkers, drug interactions, immunotherapy
  - **Engineering**: Structural integrity, material testing, failure analysis
  - **Mathematics**: Graph theory, proof strategies, counterexample search
  - **General Science**: Cross-domain bridges, gap resolution
- Each program contains 2-3 related experiments with full specifications

#### Phase 4: Prioritize Research Queue
- Ranks experiments by expected information gain (descending)
- Calculates cost efficiency (IG per credit)
- Checks budget feasibility
- Computes overall expected IG and uncertainty reduction
- Calculates ROI (Return on Investment)

#### Phase 5: Construct Research Roadmap
- Builds complete roadmap with immediate/near-term/long-term phases
- Adds planning rationale explaining WHY each experiment was selected
- Rationale types: gap-driven, contradiction resolution, IG optimization, ROI calculation, quality assessment
- Calculates quality score assessing plan completeness

#### Phase 6: Record Provenance
- Creates traceability graph connecting experiments to gaps and theories
- Records knowledge delta documenting planning operation
- Accounts costs in ledger delta
- Tracks lifecycle events from initiation to completion
- Verifies constitutional compliance (traceability, rationale, budget, topology references)

### 4. Validation Scenarios Passing ✅

All 7/7 constitutional scenarios passing:

✅ **Scenario 1**: Single knowledge gap → Focused research plan generated  
✅ **Scenario 2**: Multiple competing priorities → Ranked resolution with ordering  
✅ **Scenario 3**: Budget constraint changes plan → Constraints respected  
✅ **Scenario 4**: Contradictory theories receive priority → High priority assigned  
✅ **Scenario 5**: High information gain preferred → Sorted by IG with ROI  
✅ **Scenario 6**: Independent institutions produce different plans → Domain-specific divergence  
✅ **Scenario 7**: Planning remains constitutionally traceable → Full provenance maintained  

**Critical Achievement**: Scenario 6 now passes because different domains (Medicine, Engineering, Mathematics, Physics, Biology) produce genuinely different research programs, demonstrating true institutional individuality.

### 5. Documentation Generated ✅

- [`Capability_12_13_Report.md`](file:///c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/Capability_12_13_Report.md) (535 lines) - Complete capability report
- [`CAPABILITY_12_13_FROZEN.md`](file:///c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/CAPABILITY_12_13_FROZEN.md) (this document) - Milestone summary
- [`Constitutional_Capability_Matrix.md`](file:///c:/Users/user/Tiannara/Tiannara-MindCache-Prosthetic/Constitutional_Capability_Matrix.md) updated - Marked 12.13 as frozen

---

## Constitutional Invariants Verified

### 1. Research plans must always explain WHY the institution selected each experiment ✅

Every plan includes `planning_rationale` field with explanations for:
- Gap-driven decisions
- Contradiction resolution priorities
- Information gain optimization
- ROI calculations
- Quality assessments

### 2. Every recommendation references knowledge gaps ✅

All experiments include `required_observations` field listing which knowledge gaps they address. Verification in `verify_traceability/1` ensures every experiment references at least one gap or theory.

### 3. Every recommendation references supporting theories ✅

Experiments include `dependencies` field listing theories they will test. Traceability graph maps experiments to theories.

### 4. Every recommendation references scientific topology ✅

`topology_inputs` field records the topology analysis that informed planning (clusters, gaps, contradictions, bridges).

### 5. Budget constraints are respected ✅

`research_budget` field stores budget limits. `research_budget_ok?/1` verifies plan feasibility. Cost estimates calculated for all experiments.

### 6. Expected information gain is quantified ✅

`expected_information_gain` field stores average IG across experiments. Each experiment has individual IG score (0.0-1.0). ROI calculated as IG/cost ratio.

### 7. No recommendation appears without provenance ✅

Traceability graph (`traceability_graph` field) connects every experiment to:
- Knowledge gaps it addresses
- Theories it tests
- Topology structures it relates to

Lifecycle events track entire planning process from initiation to completion.

---

## Architectural Significance

### Transition from Reactive to Autonomous Science

**Before Capability 12.13**:
- Institutions form theories from episodes (12.11)
- Institutions analyze topology of existing theories (12.12)
- But institutions don't decide what to study next
- Research direction determined externally

**After Capability 12.13**:
- Institutions **decide** what to research based on rational assessment
- Planning driven by knowledge gaps, contradictions, and expected value
- Institutions exhibit **agency** — self-directed scientific inquiry
- First demonstration of institutional autonomy in Epoch III

This is the transition from **possessing scientific knowledge** to **actively pursuing scientific understanding**.

### Five-Scale Hierarchy Demonstration

Capability 12.13 operates across all five scales:

- **Scale 1 (Transactions)**: `ResearchPlanResult` canonical transaction
- **Scale 2 (Episodes)**: Planned experiments become future research episodes
- **Scale 3 (Institutions)**: InstitutionKernel orchestrates planning; institutional memory stores plans
- **Scale 4 (Institutional Ecology)**: Multiple institutions plan independently with domain-specific priorities
- **Scale 5 (Civilizations)**: Aggregate research planning shapes civilizational scientific trajectory

### Composition Without Duplication

Perfect adherence to Principle 4 (Composition):
- Uses `ScientificTopologyResult` as input (Capability 12.12)
- Composes `TheoryFormationResult` (Capability 12.11)
- Leverages `InstitutionKernel` execution authority
- Utilizes Economic Ledger for budget management
- Employs Lifecycle Registry for provenance tracking
- **No new architectural layers introduced**

---

## Updated Maturity Assessment

| Criterion | Status | Notes |
|-----------|--------|-------|
| Institutional Behavior Defined | ✅ Complete | "Decides what to research next" clearly specified |
| Public API Implemented | ✅ Complete | `plan_research/2` added to InstitutionKernel |
| Canonical Transaction Created | ✅ Complete | `ResearchPlanResult` (~774 lines) with all required fields |
| Internal Pipeline Implemented | ✅ Complete | Six-phase pipeline with domain-aware program generation |
| Validation Scenarios Passing | ✅ Complete | **7/7 passing** (all constitutional scenarios verified) |
| Constitutional Invariants Verified | ✅ Complete | All 7 invariants satisfied |
| Behavioral Closure Maintained | ✅ Complete | No algorithms exposed; only outcomes |
| Composition of Frozen Primitives | ✅ Complete | Uses only existing primitives; no duplication |
| Documentation Complete | ✅ Complete | Capability report + freeze documentation generated |
| Capability Frozen | ✅ **FROZEN** | Constitutionally complete |

**Overall Maturity**: **100% — Fully Frozen**

---

## Key Philosophical Decisions

### 1. Agency vs. Automation

Capability 12.13 demonstrates **institutional agency**, not mere automation. The institution doesn't just execute predefined tasks — it **reasons** about what should be studied based on:
- Current state of knowledge (topology)
- Expected value of new information (IG)
- Resource constraints (budget)
- Scientific priorities (contradictions > gaps > exploration)

This is fundamentally different from task scheduling or workflow automation.

### 2. Planning as Scientific Reasoning

Research planning is itself a form of scientific reasoning. The planner must:
- Understand the structure of current knowledge (topology)
- Identify weaknesses in that structure (gaps, contradictions)
- Propose ways to strengthen it (experiments)
- Justify those proposals (rationale)

This makes planning inseparable from the scientific method itself.

### 3. Provenance as Accountability

Every research recommendation must explain WHY it was selected. This isn't just documentation — it's **accountability**. If an experiment fails or wastes resources, the institution can trace back to understand why the decision was made and improve future planning.

### 4. Budget as Scientific Constraint

Budget isn't an external constraint imposed on science — it's an **integral part of scientific reasoning**. Good science requires efficient use of resources. The planner must balance:
- Expected information gain
- Cost of obtaining that information
- Available resources
- Opportunity costs

This reflects real scientific practice where grant proposals must justify budgets.

### 5. Research Programs as Organizational Unit

Introduction of **Research Programs** (between plans and experiments) aligns with institutional scale:
- **Plans** contain multiple programs
- **Programs** contain related experiments
- **Experiments** create episodes
- **Episodes** produce theories

This hierarchy matches how real scientific institutions organize research.

---

## Remaining Work

### None — Capability 12.13 is Frozen ✅

All implementation, validation, and documentation complete.

---

## Epoch III Status

With Capability 12.13 frozen, **Epoch III — Civilizational Cognition** is now **COMPLETE**:

- ✅ **Capability 12.11** — Institutional Theory Formation (Frozen)
- ✅ **Capability 12.12** — Topological Scientific Reasoning (Frozen)
- ✅ **Capability 12.13** — Autonomous Research Planning (Frozen)

Tiannara now possesses the complete scientific cognition loop:

```
Observe
    ↓
Validate
    ↓
Remember
    ↓
Revise Beliefs
    ↓
Form Theories (12.11)
    ↓
Analyze Scientific Topology (12.12)
    ↓
Identify Knowledge Gaps
    ↓
Plan Research Programs (12.13)
    ↓
Execute Programs
    ↓
Produce Episodes
    ↓
Observe Again
```

This loop is not just a collection of AI techniques—it is a coherent model of how a scientific institution operates.

---

## Next Steps

1. **Proceed to Phase 13** — Begin next epoch of Tiannara evolution
2. **Consider Capability 13.x** — What comes after autonomous planning?
   - Perhaps: Execution of research programs?
   - Perhaps: Inter-institutional scientific coordination?
   - Perhaps: Civilizational scientific strategy?

---

**Capability 12.13 is now FROZEN. Phase 12 is complete. Epoch III is complete. Tiannara can now autonomously plan its own scientific research.** 🎉
