# Constitutional Capability Template

**Purpose**: Standard template for all Phase 12+ institutional capabilities  
**Discipline**: One capability, one API, one canonical transaction, seven validation scenarios  
**Status**: Immutable specification format (frozen)

---

## Template Structure

Every future capability must be specified using this exact structure before implementation begins. This ensures architectural consistency, prevents drift, and makes capabilities composable.

```markdown
# Capability [Number] — [Institutional Capability Name]

**Date**: YYYY-MM-DD  
**Status**: ⏳ Specification | 🚧 Implementation | ✅ Validated | ❄️ Frozen  
**Validation**: X/7 scenarios passed  
**Architectural Discipline**: Composes frozen primitives only

---

## Institutional Capability

### Mission Statement

> [One sentence describing what institutional behavior is realized]

**Example**:  
> Every Research Institution can evaluate the consequences of hypothetical interventions using its accumulated episodic history while preserving constitutional explainability.

### Behavioral Specification

[Clear description of observable institutional behavior from external perspective. NOT algorithmic detail.]

**Key Questions Answered**:
- What does the institution DO?
- What observable outcome is produced?
- How does this differ from existing capabilities?

---

## Public API

### Interface Signature

```elixir
InstitutionKernel.[api_name]/[arity]
```

**Parameters**:
- `institution_pid`: pid() - target institution
- `[param1]`: type() - description
- `[param2]`: type() - description
- `opts`: map() - optional parameters

**Returns**:
```elixir
{:ok, [CanonicalArtifact].t()} | {:error, String.t()}
```

**Example Usage**:
```elixir
{:ok, result} = InstitutionKernel.[api_name](kernel_pid, param1, param2, opts)
```

**Contract**:
- Only externally visible interface
- Internal algorithms are replaceable implementation details
- Signature remains stable after freezing

---

## Canonical Transaction Artifact

### Artifact Name

`[ArtifactName]Result`

### Purpose

[What immutable transaction this artifact captures]

### Struct Definition

```elixir
defmodule TiannaraOS.[ArtifactName]Result do
  @derive Jason.Encoder
  defstruct [
    # Identity
    :[artifact_id],                 # String.t()
    :institution_id,                # atom()
    :timestamp,                     # DateTime.t()
    :tick,                          # integer()
    
    # Input/Context
    :[input_field1],                # type()
    :[input_field2],                # type()
    
    # Output/Result
    :[output_field1],               # type()
    :[output_field2],               # type()
    
    # Constitutional Deltas
    :knowledge_delta,               # KnowledgeDelta.t() | nil
    :ledger_delta,                  # LedgerDelta.t()
    :memory_delta,                  # MemoryDelta.t()
    
    # Audit Trail
    :lifecycle_events,              # [LifecycleEvent.t()]
    :semantic_events,               # [SemanticEvent.t()]
    
    # Execution Metadata
    :execution_time_ms,             # integer()
    :constitutional_validation,     # Validation.t()
    
    # Status
    :status,                        # atom()
    :failure_reason                 # String.t() | nil
  ]
end
```

### Public API Functions

```elixir
def new(institution_id, [inputs], opts \\ [])
def add_[component](result, [component_data])
def mark_completed(result, reason)
def mark_failed(result, error_msg)
# ... other builder functions
```

---

## Constitutional Components

### Frozen Primitives Composed

[List which frozen constitutional primitives this capability uses]

**Required**:
- ResearchEpisode - [how used]
- EpisodeIndex - [how used]
- Knowledge Graph - [how used]
- InstitutionKernel - [how used]
- [Other primitives...]

**Optional**:
- Governance Engine - [if governance review required]
- Economic Ledger - [if budget accounting required]
- Memory Pipeline - [if memory consolidation required]

### No New Persistent State

This capability introduces NO new persistent state. All data stored in existing constitutional structures:
- Episodes stored in `civilizational_memory[:episodes]`
- Index entries in `civilizational_memory[:episode_index]`
- Transactions referenced within episodes
- Results returned as canonical artifacts (not persisted independently)

---

## Execution Pipeline

### Internal Flow

```
[Step 1: Input validation / budget check]
  ↓
[Step 2: Retrieve relevant episodes (via EpisodeIndex)]
  ↓
[Step 3: Execute core logic (internal algorithm)]
  ↓
[Step 4: Build canonical transaction artifact]
  ↓
[Step 5: Account costs (ledger delta)]
  ↓
[Step 6: Record lifecycle events]
  ↓
[Step 7: Emit semantic events]
  ↓
[Step 8: Validate constitutional invariants]
  ↓
[Step 9: Return canonical artifact]
```

### Algorithm Independence

The internal algorithm ([Do-Calculus / Bayesian Networks / etc.]) is a **replaceable implementation detail**. The Constitution exposes only the behavioral contract, not the algorithmic choice.

Future implementations may swap algorithms without changing:
- Public API signature
- Canonical artifact structure
- Validation scenarios
- Constitutional components

---

## Validation Scenarios

Seven behavioral scenarios mirroring earlier capabilities. All must pass against genuine institutional history.

### Scenario 1: [Primary Success Case]

**Test**: [Description]  
**Expected Behavior**: [What should happen]  
**Pass Criteria**: [Observable outcome]

### Scenario 2: [Alternative Success Case]

**Test**: [Description]  
**Expected Behavior**: [What should happen]  
**Pass Criteria**: [Observable outcome]

### Scenario 3: [Failure Handling]

**Test**: [Description]  
**Expected Behavior**: [How failure is handled gracefully]  
**Pass Criteria**: [Error artifact produced, no state corruption]

### Scenario 4: [Edge Case / Insufficient Data]

**Test**: [Description]  
**Expected Behavior**: [Graceful handling of insufficient evidence/data]  
**Pass Criteria**: [Appropriate status returned]

### Scenario 5: [Governance Rejection]

**Test**: [Description]  
**Expected Behavior**: [Governance can reject if required by domain profile]  
**Pass Criteria**: [Rejection recorded in artifact]

### Scenario 6: [Budget Exhaustion]

**Test**: [Description]  
**Expected Behavior**: [Insufficient budget causes deferral]  
**Pass Criteria**: [Status=:deferred with explanation]

### Scenario 7: [Twenty Institutions Simultaneous]

**Test**: All 20 research domains execute capability concurrently  
**Expected Behavior**: Zero race conditions, independent histories preserved  
**Pass Criteria**: All 20 institutions complete successfully

---

## Definition of Done

> [Capability name] is constitutionally complete when:
> 1. [Criterion 1 - e.g., All 7 validation scenarios pass]
> 2. [Criterion 2 - e.g., Canonical artifact produced for every execution]
> 3. [Criterion 3 - e.g., No new persistent state introduced]
> 4. [Criterion 4 - e.g., Principle compliance verified]
> 5. [Criterion 5 - e.g., Three-artifact rule satisfied]

---

## Capability Report

Following the Three-Artifact Rule, produce:

1. **Capability Specification**: This document
2. **Validation Script**: `run_capability_[number]_validation.exs` (7 scenarios)
3. **Constitution Report**: `Capability_[number]_Report.md` (behavioral report)

---

## Frozen Status

Once validated and report produced, this capability becomes **frozen**:
- Public API signature immutable
- Canonical artifact structure immutable
- Constitutional components immutable
- May only be modified for bug fixes (no architectural changes)

**Frozen Date**: YYYY-MM-DD  
**Frozen By**: [Validation summary]

---

## Downstream Impact

[List which future capabilities will compose this one]

**Example**:
- Capability 12.7 (Neuro-Symbolic Routing) → uses intervention reasoning results
- Capability 12.10 (Distributed Validation) → compares intervention reasoning across institutions
- Capability 12.13 (Active Epistemic Foraging) → selects interventions based on historical success

---

## Notes

- Follow same engineering discipline as 12.1, 12.4, 12.5
- Internal algorithms are replaceable; behavioral contract is permanent
- Seven validation scenarios ensure consistency across all capabilities
- Capability Matrix updated upon completion
```

---

## Usage Instructions

### Before Implementation

1. Copy this template
2. Fill in all sections for the new capability
3. Review with architectural team
4. Ensure three questions answered:
   - What institutional capability is being realized?
   - Which constitutional components compose it?
   - Which constitutional invariants prove it works?

### During Implementation

1. Create canonical artifact struct
2. Implement public API in InstitutionKernel
3. Build execution pipeline using frozen primitives
4. Write validation script (7 scenarios)
5. Execute validation
6. Produce capability report

### After Validation

1. Update Capability Matrix
2. Mark capability as frozen
3. Document downstream impact
4. Begin next capability

---

## Example: Capability 12.6 Skeleton

```markdown
# Capability 12.6 — Institutional Causal Intervention Reasoning

**Date**: 2026-06-26  
**Status**: ⏳ Specification  
**Validation**: 0/7 scenarios  
**Architectural Discipline**: Composes ResearchEpisode, EpisodeIndex, Knowledge Graph

---

## Institutional Capability

### Mission Statement

> Every Research Institution can evaluate the consequences of hypothetical interventions using its accumulated episodic history while preserving constitutional explainability.

### Behavioral Specification

The institution receives an intervention query (e.g., "What would happen if we changed variable X?") and returns a reasoned assessment of likely outcomes based on:
- Previous similar interventions from episode history
- Causal relationships in the knowledge graph
- Counterfactual simulation using structural models

Observable outcome: `InterventionReasoningResult` artifact containing predicted effects, confidence levels, supporting evidence (episode references), and constitutional deltas.

---

## Public API

### Interface Signature

```elixir
InstitutionKernel.reason_about_intervention/3
```

**Parameters**:
- `institution_pid`: pid() - target institution
- `intervention`: map() - hypothetical intervention (%{variable: atom(), change: term(), context: map()})
- `opts`: map() - optional parameters (:max_counterfactuals, :confidence_threshold, :governance_required)

**Returns**:
```elixir
{:ok, InterventionReasoningResult.t()} | {:error, String.t()}
```

---

## Canonical Transaction Artifact

### Artifact Name

`InterventionReasoningResult`

[... rest of specification follows template ...]
```

---

## Template Benefits

1. **Consistency**: Every capability follows identical structure
2. **Clarity**: Separates behavioral contract from implementation detail
3. **Composability**: Makes dependencies explicit
4. **Validation**: Seven scenarios ensure thorough testing
5. **Freezing**: Clear criteria for when capability is complete
6. **Documentation**: Three-artifact rule produces complete reference
7. **Maintainability**: Future engineers understand exactly how to extend system

---

**This template is now part of the constitutional infrastructure.**  
All future capabilities (12.6-12.13+) must use this format.
