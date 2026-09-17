# Phase 14.0.95 — Governance Validation Runtime Architecture

**Status**: 📐 Architectural Specification  
**Objective**: Build constitutional runtime that executes any campaign from registry data  
**Approach**: Data-driven execution engine, not campaign-specific code

---

## Architectural Evolution

### Phase 13 Pattern (Scientific Capital)

```
Constitutional Invariants (data)
    ↓ executed by
StructuralValidationGate (runtime)
    ↓ produces
Evidence Artifacts (immutable)
```

**Key Insight**: Invariants are data, not code. The gate is a generic executor.

---

### Phase 14 Pattern (Governance Validation)

```
Campaign Registry (data)
Failure Registry (data)
Evidence Registry (data)
    ↓ executed by
Governance Validation Runtime (engine)
    ↓ produces
Evidence Artifacts (immutable, content-addressed)
```

**Key Insight**: Campaigns are data, not code. The runtime is a generic executor.

---

## Core Architecture

### Three Registries (Data Layer)

```
┌─────────────────────────────────────┐
│   GOVERNANCE_CAMPAIGN_REGISTRY.md   │  ← Campaign definitions (GV-001 to GV-012+)
├─────────────────────────────────────┤
│   GOVERNANCE_FAILURE_REGISTRY.md    │  ← Failure mode definitions (FAIL-001 to FAIL-048)
├─────────────────────────────────────┤
│  GOVERNANCE_EVIDENCE_REGISTRY.md    │  ← Evidence type definitions (EVID-001 to EVID-012)
└─────────────────────────────────────┘
```

All three are **versioned separately** from the constitution.

---

### Seven Runtime Components (Execution Layer)

```
CampaignRegistry (loads registry data)
    ↓ builds execution plan
CampaignPlanner (constructs DAG)
    ↓ schedules execution
CampaignScheduler (manages parallel/serial/retry)
    ↓ executes campaigns
CampaignExecutor (generic executor, no GV-specific logic)
    ↓ collects outputs
EvidenceCollector (gathers raw data)
    ↓ signs artifacts
EvidenceSigner (cryptographic signing)
    ↓ verifies integrity
EvidenceVerifier (independent verification)
    ↓ aggregates results
EvidenceAggregator (combines campaign results)
    ↓ generates reports
ReportGenerator (produces markdown/JSON/certificate)
```

**Critical**: No component contains GV-specific logic. All behavior driven by registry data.

---

## Component Specifications

### 1. CampaignRegistry

**Purpose**: Load and parse campaign registry data

**Interface**:
```elixir
defmodule TiannaraOS.Governance.Validation.CampaignRegistry do
  @spec load_registry() :: {:ok, [map()]} | {:error, term()}
  @spec get_campaign(String.t()) :: {:ok, map()} | {:error, :not_found}
  @spec get_campaign_by_id(String.t()) :: {:ok, map()} | {:error, :not_found}
  @spec list_campaigns_by_phase(non_neg_integer()) :: [map()]
  @spec get_dependencies(String.t()) :: [String.t()]
end
```

**Responsibilities**:
- Parse YAML/JSON registry files
- Validate schema conformance
- Resolve failure references (FAIL-XXX)
- Resolve evidence references (EVID-XXX)
- Cache loaded data

**Does NOT**:
- Execute campaigns
- Contain campaign logic
- Hardcode campaign IDs

---

### 2. CampaignPlanner

**Purpose**: Build execution plan from registry (DAG construction)

**Interface**:
```elixir
defmodule TiannaraOS.Governance.Validation.CampaignPlanner do
  @spec build_execution_plan([map()]) :: {:ok, ExecutionPlan.t()} | {:error, term()}
  @spec detect_cycles([map()]) :: :valid | {:cycle_detected, [String.t()]}
  @spec topological_sort([map()]) :: [[String.t()]]  # Phases
  @spec validate_dependencies([map()]) :: :valid | {:invalid_deps, map()}
end
```

**Input**: Campaign registry data  
**Output**: Execution plan with phases

**Example Output**:
```elixir
%ExecutionPlan{
  phases: [
    [GV-001, GV-002, GV-005, GV-009, GV-010],  # Phase 1 (parallel)
    [GV-003, GV-006, GV-011],                   # Phase 2 (parallel)
    [GV-004, GV-007],                           # Phase 3 (parallel)
    [GV-008],                                   # Phase 4 (serial)
    [GV-012]                                    # Phase 5 (serial)
  ]
}
```

**Does NOT**:
- Execute campaigns
- Schedule timing
- Handle retries

---

### 3. CampaignScheduler

**Purpose**: Manage execution ordering, parallelism, retries

**Interface**:
```elixir
defmodule TiannaraOS.Governance.Validation.CampaignScheduler do
  @spec execute_plan(ExecutionPlan.t(), opts) :: {:ok, [Result.t()]} | {:error, term()}
  @spec execute_phase([String.t()], opts) :: %{String.t() => Result.t()}
  @spec retry_failed(Result.t(), max_retries) :: Result.t()
  @spec apply_backoff(attempt_number) :: non_neg_integer()  # milliseconds
end
```

**Responsibilities**:
- Execute phases in order
- Run campaigns within phase in parallel (Task.async_stream)
- Retry failed campaigns with backoff
- Enforce timeouts
- Collect results

**Does NOT**:
- Know campaign logic
- Process evidence
- Generate reports

---

### 4. CampaignExecutor

**Purpose**: Generic campaign executor (no GV-specific logic)

**Interface**:
```elixir
defmodule TiannaraOS.Governance.Validation.CampaignExecutor do
  @spec execute_campaign(campaign_spec, adapters) :: {:ok, Evidence.t()} | {:error, Failure.t()}
  @spec resolve_adapter(atom()) :: module()
  @spec execute_adapter(adapter_module, operation, params) :: term()
end
```

**Execution Flow**:
```elixir
def execute_campaign(spec, adapters) do
  # 1. Resolve adapter from spec
  adapter_module = resolve_adapter(spec.adapter)
  
  # 2. Execute adapter operation
  result = execute_adapter(adapter_module, :execute, spec.params)
  
  # 3. Wrap in evidence structure
  case result do
    {:ok, data} -> {:ok, wrap_evidence(spec.evidence_type, data)}
    {:error, reason} -> {:error, lookup_failure(spec.failure_modes, reason)}
  end
end
```

**Key Principle**: Executor knows nothing about GV-001, GV-002, etc. It only knows:
- `spec.adapter` → which adapter to call
- `spec.params` → what parameters to pass
- `spec.evidence_type` → how to wrap result
- `spec.failure_modes` → how to categorize errors

**Adding GV-013 requires**: Zero changes to executor. Only registry entry.

---

### 5. EvidenceCollector

**Purpose**: Gather raw outputs, logs, measurements, timings

**Interface**:
```elixir
defmodule TiannaraOS.Governance.Validation.EvidenceCollector do
  @spec collect_raw_output(execution_result) :: binary()
  @spec compute_measurements(adapter_results) :: map()
  @spec record_timings(start_time, end_time) :: map()
  @spec capture_logs(execution_context) :: [String.t()]
  @spec compute_input_fingerprint(canonical_inputs) :: String.t()
  @spec compute_output_fingerprint(output_data) :: String.t()
end
```

**Responsibilities**:
- Capture raw campaign output
- Compute quantitative measurements (from adapters)
- Record execution timings
- Capture diagnostic logs
- Compute fingerprints for inputs/outputs

**Does NOT**:
- Sign artifacts
- Hash content
- Store artifacts

---

### 6. EvidenceSigner

**Purpose**: Cryptographically sign evidence artifacts

**Interface**:
```elixir
defmodule TiannaraOS.Governance.Validation.EvidenceSigner do
  @spec sign_artifact(EvidenceArtifact.t()) :: EvidenceArtifact.t()
  @spec compute_content_hash(content) :: String.t()
  @spec generate_signature(data, private_key) :: String.t()
  @spec store_content_addressed(artifact) :: String.t()  # Returns hash
end
```

**Signing Process**:
```elixir
def sign_artifact(%EvidenceArtifact{} = artifact) do
  # 1. Compute content hash
  content_hash = compute_content_hash(artifact.content)
  
  # 2. Generate signature
  signature_data = "#{artifact.campaign_id}:#{artifact.timestamp}:#{content_hash}"
  signature = generate_signature(signature_data, private_key())
  
  # 3. Store content-addressed
  storage_path = store_content_addressed(artifact)
  
  # 4. Return signed artifact
  %EvidenceArtifact{
    artifact
    | content_hash: content_hash,
      signature: signature,
      storage_path: storage_path
  }
end
```

**Storage**: Content-addressed (`evidence/{hash}.json`)

---

### 7. EvidenceVerifier

**Purpose**: Independently verify evidence integrity (never trusts signer)

**Interface**:
```elixir
defmodule TiannaraOS.Governance.Validation.EvidenceVerifier do
  @spec verify_artifact(EvidenceArtifact.t()) :: :valid | {:invalid, reason}
  @spec verify_signature(EvidenceArtifact.t()) :: :valid | :invalid
  @spec verify_hash(EvidenceArtifact.t()) :: :valid | :invalid
  @spec verify_fingerprint(EvidenceArtifact.t()) :: :match | :mismatch
  @spec replay_and_verify(campaign_spec, evidence) :: :verified | :failed
end
```

**Verification Process**:
```elixir
def verify_artifact(%EvidenceArtifact{} = artifact) do
  with :valid <- verify_signature(artifact),
       :valid <- verify_hash(artifact),
       :match <- verify_fingerprint(artifact),
       :verified <- replay_and_verify(artifact.campaign_spec, artifact) do
    :valid
  else
    {:invalid, reason} -> {:invalid, reason}
  end
end
```

**Independence**: Verifier uses separate code path from signer to avoid shared bugs.

---

### 8. EvidenceAggregator

**Purpose**: Combine individual campaign results into overall assessment

**Interface**:
```elixir
defmodule TiannaraOS.Governance.Validation.EvidenceAggregator do
  @spec aggregate_results([EvidenceArtifact.t()]) :: ValidationSummary.t()
  @spec determine_overall_status([EvidenceArtifact.t()]) :: :pass | :fail | :partial
  @spec count_by_status([EvidenceArtifact.t()]) :: %{pass: integer(), fail: integer()}
  @spec identify_failures([EvidenceArtifact.t()]) :: [Failure.t()]
  @spec determine_freeze_recommendation(ValidationSummary.t()) :: :freeze | :do_not_freeze
end
```

**Output**:
```elixir
%ValidationSummary{
  overall_status: :pass,
  total_campaigns: 12,
  passed_campaigns: 12,
  failed_campaigns: 0,
  critical_failures: [],
  warning_failures: [],
  freeze_recommendation: :freeze
}
```

**Does NOT**:
- Format reports
- Generate markdown
- Create certificates

---

### 9. ReportGenerator

**Purpose**: Produce human-readable reports from aggregated data

**Interface**:
```elixir
defmodule TiannaraOS.Governance.Validation.ReportGenerator do
  @spec generate_markdown_report(ValidationSummary.t(), [EvidenceArtifact.t()]) :: String.t()
  @spec export_json_report(ValidationSummary.t(), [EvidenceArtifact.t()]) :: map()
  @spec generate_certificate(ValidationSummary.t()) :: Certificate.t()
  @spec export_to_file(report_content, path) :: :ok | {:error, term()}
end
```

**Outputs**:
1. `GOVERNANCE_VALIDATION_REPORT.md` (human-readable)
2. `validation_summary.json` (machine-readable)
3. `governance-validation-certificate.pem` (cryptographic proof)

**Does NOT**:
- Execute campaigns
- Aggregate results
- Verify artifacts

---

## Adapter Layer

### 10 Required Adapters

| Adapter | Domain | Operations |
|---------|--------|------------|
| `LedgerAdapter` | Governance Ledger | `get_events/0`, `reconstruct_state/0`, `compute_hash/0` |
| `StateAdapter` | Governance State | `capture_state/0`, `get_field/1`, `compare_states/2` |
| `GraphAdapter` | Institution/Capability Graphs | `get_nodes/1`, `get_edges/1`, `traverse_lineage/1` |
| `ReplayAdapter` | Replay Engine | `replay_from_ledger/0`, `verify_determinism/2` |
| `CertificateAdapter` | Certificates | `issue_certificate/4`, `verify_certificate/1` |
| `FingerprintAdapter` | Fingerprints | `compute_fingerprint/0`, `compare_fingerprints/2` |
| `ArchaeologyAdapter` | Archaeology | `trace_provenance/1`, `reconstruct_history/1` |
| `FitnessAdapter` | Fitness Evaluator | `measure_fitness/0`, `apply_mutation/2` |
| `EntropyAdapter` | Entropy Tracker | `measure_entropy/0`, `simulate_proposals/2` |
| `CostAdapter` | Cost Ledger | `record_cost/2`, `replay_costs/1`, `get_total/0` |

### Adapter Interface Contract

```elixir
defmodule TiannaraOS.Governance.Validation.Adapters.LedgerAdapter do
  @callback get_events() :: [Event.t()]
  @callback append_event(event_type, data) :: {:ok, Event.t()} | {:error, term()}
  @callback reconstruct_state() :: GovernanceState.t()
  @callback compute_hash() :: String.t()
end
```

**Ownership Rule**: Adapters own measurement logic, not campaigns.

---

## Execution Flow

### Complete Pipeline

```
1. Load registries
   CampaignRegistry.load_registry()
   FailureRegistry.load_registry()
   EvidenceRegistry.load_registry()

2. Build execution plan
   CampaignPlanner.build_execution_plan(campaigns)

3. Execute phases
   CampaignScheduler.execute_plan(plan)
     ├─ Phase 1: Execute GV-001, GV-002, GV-005, GV-009, GV-010 (parallel)
     ├─ Phase 2: Execute GV-003, GV-006, GV-011 (parallel)
     ├─ Phase 3: Execute GV-004, GV-007 (parallel)
     ├─ Phase 4: Execute GV-008 (serial)
     └─ Phase 5: Execute GV-012 (serial)

4. For each campaign:
   CampaignExecutor.execute_campaign(spec, adapters)
     ├─ Resolve adapter from spec
     ├─ Execute adapter operation
     ├─ Collect evidence via EvidenceCollector
     ├─ Sign artifact via EvidenceSigner
     └─ Verify artifact via EvidenceVerifier

5. Aggregate results
   EvidenceAggregator.aggregate_results(all_artifacts)

6. Generate report
   ReportGenerator.generate_markdown_report(summary, artifacts)
   ReportGenerator.export_json_report(summary, artifacts)
   ReportGenerator.generate_certificate(summary)

7. Output artifacts
   - docs/GOVERNANCE_VALIDATION_REPORT.md
   - evidence/*.json (content-addressed)
   - validation_summary.json
   - governance-validation-certificate.pem
```

---

## Adding New Campaigns (GV-013+)

### Step 1: Add Registry Entry

Add to `GOVERNANCE_CAMPAIGN_REGISTRY.md`:

```yaml
campaign_id: GV-013
campaign_version: 1.0.0
name: Proposal Lifecycle Validation
introduced_in: Phase 14.1

objective: >
  Verify RFC proposal lifecycle executes correctly.

adapter: ProposalLifecycleAdapter

evidence_type: EVID-013  # Add to evidence registry

failure_modes:
  - FAIL-049  # Add to failure registry
  - FAIL-050

thresholds:
  minimum_required: 10
  recommended: 100
  certification: 1000

dependencies:
  - GV-001
  - GV-008

execution_phase: 6
```

### Step 2: Add Failure Mode (if needed)

Add to `GOVERNANCE_FAILURE_REGISTRY.md`:

```yaml
failure_id: FAIL-049
name: Proposal Stuck in Review
severity: :warning
repair_strategy: :escalate_review
```

### Step 3: Add Evidence Type (if needed)

Add to `GOVERNANCE_EVIDENCE_REGISTRY.md`:

```yaml
evidence_id: EVID-013
name: Proposal Lifecycle Report
schema: ...
```

### Step 4: Implement Adapter

Create `lib/tiannara/os/governance/validation/adapters/proposal_lifecycle_adapter.ex`:

```elixir
defmodule TiannaraOS.Governance.Validation.Adapters.ProposalLifecycleAdapter do
  @behaviour TiannaraOS.Governance.Validation.Adapter
  
  @impl true
  def execute(params) do
    # Implementation
  end
end
```

### Step 5: Run Validation

```elixir
{:ok, report} = GovernanceValidationLaboratory.run_full_campaign()
```

**Zero changes required to**:
- CampaignExecutor
- CampaignScheduler
- EvidenceCollector
- EvidenceSigner
- EvidenceVerifier
- EvidenceAggregator
- ReportGenerator

---

## Constitutional Principles

### 1. Data-Driven Execution

Campaigns are data, not code. Runtime is generic executor.

### 2. Separation of Concerns

- Registries define **what** to validate
- Runtime executes **how** to validate
- Adapters provide **access** to kernel state

### 3. Content-Addressed Storage

All evidence stored by hash, ensuring immutability.

### 4. Independent Verification

EvidenceVerifier never trusts EvidenceSigner. Separate code paths.

### 5. Versioned Evolution

Registries versioned separately from constitution. Easy to add campaigns without amending constitution.

### 6. Adapter Ownership

Adapters own measurement logic. Campaigns request measurements, don't compute them.

---

## Comparison with Phase 13

| Aspect | Phase 13 (Scientific Capital) | Phase 14.0.95 (Governance Validation) |
|--------|-------------------------------|---------------------------------------|
| **Specification** | CAUSAL_FLOW.md | GOVERNANCE_VALIDATION_CONSTITUTION.md |
| **Invariant Registry** | ConstitutionalInvariantRegistry | CAMPAIGN_REGISTRY + FAILURE_REGISTRY + EVIDENCE_REGISTRY |
| **Runtime** | StructuralValidationGate | GovernanceValidationLaboratory (9 components) |
| **Execution** | Invariant execution | Campaign execution |
| **Evidence** | Replay certificates | Content-addressed artifacts |
| **Verification** | Independent replay | EvidenceVerifier |
| **Extension** | Add invariant to registry | Add campaign to registry |

Same architectural pattern, different domain.

---

## Next Steps

1. **Implement 9 runtime components** (CampaignRegistry through ReportGenerator)
2. **Implement 10 adapters** (LedgerAdapter through CostAdapter)
3. **Execute full validation campaign** using runtime
4. **Generate evidence artifacts** (content-addressed)
5. **Independent verification** of all artifacts
6. **Generate validation report** and freeze recommendation
7. **Create PHASE14_GOVERNANCE_FREEZE.md** if all mandatory campaigns pass

---

**Signed**: Tiannara Constitutional Architecture Team  
**Date**: June 13, 2026  
**Architecture Status**: 📐 Specified, Ready for Implementation
