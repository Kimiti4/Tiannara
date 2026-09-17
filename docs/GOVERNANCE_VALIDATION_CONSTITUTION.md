# Governance Validation Constitution

**Version**: 1.0.0  
**Status**: 📜 Constitutional Specification (Frozen)  
**Purpose**: Immutable rules governing governance validation system  
**Authority**: Overrides all implementation details in case of conflict  
**Amendment Process**: RFC → Review Board → Governance Council → Archive

---

## Preamble

This document defines the **immutable constitutional framework** for validating Tiannara's institutional governance system. It ensures that:

1. All validation derives from canonical specifications
2. Evidence artifacts follow uniform schema
3. Success thresholds evolve through governance, not implementation
4. Campaign dependencies form a directed acyclic graph (no circular validation)
5. Every campaign is explainable, replayable, and auditable

This document changes **only** through constitutional amendment. Campaign definitions live in `GOVERNANCE_CAMPAIGN_REGISTRY.md` (versioned separately).

---

## Section 1: Validation Ontology

Every governance validation campaign MUST define these fields. No other fields are permitted at the constitutional level.

### Required Fields

| Field | Type | Purpose |
|-------|------|---------|
| `objective` | String | What this campaign proves |
| `evidence` | String | What immutable artifact is produced |
| `canonical_inputs` | List[Atom] | Authoritative data sources |
| `expected_output` | Map | Structured result format |
| `failure_modes` | List[Atom] | Enumerated failure categories |
| `repair_strategy` | Atom | How to respond to failure |
| `replay_requirements` | Map | Conditions for deterministic replay |
| `evidence_artifact` | String | Export format specification |

### Forbidden Patterns

❌ Hardcoded test counts (use threshold classes instead)  
❌ Direct module calls (use validation adapters)  
❌ Inline measurement logic (delegate to adapters)  
❌ Implicit success criteria (must be explicit)  
❌ Circular dependencies (must form DAG)  

### Ownership Rule

**Campaigns never define measurements.** Campaigns request measurements from adapters:

```
Campaign
    ↓ requests measurement
Validation Adapter
    ↓ queries
Governance Module
    ↓ computes from
Kernel State
```

This prevents duplicate algorithms appearing inside campaigns.

---

## Section 2: Evidence Artifact Schema

All campaigns MUST produce evidence artifacts following this canonical schema.

### EvidenceArtifact Structure

```elixir
%EvidenceArtifact{
  campaign_id: String.t(),        # e.g., "GV-001"
  campaign_version: String.t(),   # e.g., "1.0.0"
  timestamp: DateTime.t(),        # UTC when artifact generated
  input_fingerprint: String.t(),  # SHA-256 hash of canonical inputs
  output_fingerprint: String.t(), # SHA-256 hash of campaign output
  replay_certificate: String.t(), # Certificate proving deterministic replay
  pass_fail: :pass | :fail,       # Overall result
  measurements: map(),            # Quantitative metrics (from adapter)
  raw_evidence: binary(),         # Raw data for independent verification
  statistical_summary: map(),     # Aggregated statistics
  signature: String.t()           # Cryptographic signature
}
```

### Content-Addressed Storage

Evidence artifacts are stored using content-addressed naming:

```
evidence/
  SHA256(artifact_content).json
```

References to artifacts use the hash, not descriptive names:

```elixir
%{
  campaign_id: "GV-001",
  evidence_hash: "a1b2c3d4e5f6...",
  evidence_path: "evidence/a1b2c3d4e5f6.json"
}
```

This aligns with constitutional philosophy established for manifests and certificates.

### Field Definitions

| Field | Type | Required | Purpose |
|-------|------|----------|---------|
| `campaign_id` | String | ✅ Yes | Unique campaign identifier |
| `campaign_version` | String | ✅ Yes | Validator definition version |
| `timestamp` | DateTime | ✅ Yes | When artifact was generated (UTC) |
| `input_fingerprint` | String | ✅ Yes | SHA-256 of all canonical inputs |
| `output_fingerprint` | String | ✅ Yes | SHA-256 of campaign output |
| `replay_certificate` | String | ✅ Yes | Proof of deterministic replay |
| `pass_fail` | Atom | ✅ Yes | Overall pass/fail status |
| `measurements` | Map | ✅ Yes | Quantitative metrics (from adapter) |
| `raw_evidence` | Binary | ✅ Yes | Raw data for independent audit |
| `statistical_summary` | Map | ✅ Yes | Aggregated statistics |
| `signature` | String | ✅ Yes | Cryptographic signature (SHA-256) |

### Signature Calculation

```elixir
signature = SHA-256(
  campaign_id <>
  campaign_version <>
  timestamp <>
  input_fingerprint <>
  output_fingerprint <>
  pass_fail <>
  measurements_hash
)
```

---

## Section 3: Failure Taxonomy

All campaign failures MUST be categorized using this constitutional taxonomy.

### Failure Categories

| Category | Code | Description | Severity | Freeze Required |
|----------|------|-------------|----------|-----------------|
| Structural Failure | `:structural_failure` | Violation of governance structure | Critical | ✅ Yes |
| Replay Failure | `:replay_failure` | Deterministic replay failed | Critical | ✅ Yes |
| Authority Failure | `:authority_failure` | Unauthorized action succeeded | Critical | ✅ Yes |
| Conservation Failure | `:conservation_failure` | Institution/appointment disappeared | Critical | ✅ Yes |
| Provenance Failure | `:provenance_failure` | Incomplete lineage chain | Critical | ✅ Yes |
| Drift Failure | `:drift_failure` | Mutation undetected | Critical | ✅ Yes |
| Entropy Failure | `:entropy_failure` | Unbounded entropy growth | Warning | ❌ No |
| Fitness Failure | `:fitness_failure` | Random oscillation detected | Warning | ❌ No |
| Stress Failure | `:stress_failure` | Performance bounds exceeded | Warning | ❌ No |
| Cost Failure | `:cost_failure` | Cost reconstruction mismatch | Warning | ❌ No |

### Repair Strategies

| Strategy | Description | When Used |
|----------|-------------|-----------|
| `:freeze_and_audit` | Halt all operations, investigate root cause | Critical failures |
| `:immediate_freeze` | Emergency freeze without delay | Authority violations |
| `:emergency_restore` | Restore from last known good state | Conservation failures |
| `:fix_provenance_chain` | Repair broken lineage links | Provenance failures |
| `:critical_alert` | Alert governance council immediately | Drift detection |
| `:optimize_governance` | Adjust governance parameters | Entropy issues |
| `:tune_fitness_function` | Recalibrate fitness evaluation | Fitness oscillation |
| `:optimize_performance` | Improve system performance | Stress failures |
| `:recalculate_costs` | Recompute cost ledger | Cost mismatches |

---

## Section 4: Threshold Model

Thresholds evolve constitutionally through four classes, not hardcoded values.

### Threshold Classes

| Class | Purpose | Example Use |
|-------|---------|-------------|
| **Minimum Required** | Absolute floor for acceptance | Initial validation |
| **Recommended** | Standard validation level | Regular audits |
| **Certification** | High-confidence validation | Pre-freeze certification |
| **Stress** | Extreme load testing | Capacity planning |

### Threshold Evolution

Thresholds can only change through constitutional amendment:

1. Propose threshold change via RFC
2. Review Board evaluates impact on validation integrity
3. Governance Council ratifies amendment
4. New thresholds become canonical
5. Old thresholds archived (never deleted)

### Per-Campaign Threshold Specifications

Each campaign in `GOVERNANCE_CAMPAIGN_REGISTRY.md` specifies its thresholds per class. Example:

```yaml
campaign_id: GV-001
thresholds:
  minimum_required: 100
  recommended: 1000
  certification: 10000
  stress: 100000
```

---

## Section 5: Validation Dependencies (DAG Rules)

Campaign dependencies MUST form a directed acyclic graph. No circular validation allowed.

### Dependency Rules

1. **No cycles**: If A depends on B, B cannot depend on A (directly or transitively)
2. **Explicit declaration**: All dependencies must be declared in campaign registry
3. **Execution order**: Dependencies execute before dependents
4. **Failure propagation**: If dependency fails, dependent campaigns skip (not fail)

### Execution Phases

Campaigns execute in phases based on dependency depth:

```
Phase 1: Independent campaigns (no dependencies)
Phase 2: Campaigns depending only on Phase 1
Phase 3: Campaigns depending only on Phase 1-2
...
Phase N: Final campaigns (all dependencies satisfied)
```

### Parallel Execution

Campaigns within the same phase MAY execute in parallel if they have no interdependencies.

---

## Section 6: Campaign Versioning

Every campaign exposes version metadata for historical replay accuracy.

### Version Fields

| Field | Type | Purpose |
|-------|------|---------|
| `campaign_id` | String | Unique identifier (e.g., "GV-001") |
| `campaign_version` | String | Semantic version (e.g., "1.0.0") |
| `introduced_in` | String | Phase/version when campaign added |
| `deprecated_in` | String? | Phase/version when deprecated (nil if active) |
| `supersedes` | String? | Previous campaign ID this replaces (nil if first) |
| `required_kernel_version` | String | Minimum kernel version required |

### Version Semantics

- **Major version** (1.x.x): Breaking changes to campaign logic
- **Minor version** (x.1.x): New features, backward compatible
- **Patch version** (x.x.1): Bug fixes, no behavior change

### Historical Replay

When replaying historical governance states, use the campaign version active at that time:

```elixir
# Replay with correct validator version
campaign_spec = CampaignRegistry.get_campaign_at_version("GV-001", "1.0.0")
result = CampaignExecutor.execute(campaign_spec, historical_state)
```

---

## Section 7: Adapter Architecture

Campaigns MUST NOT call governance modules directly. Use validation adapters.

### Adapter Pattern

```
Campaign
    ↓ requests operation
Validation Adapter
    ↓ translates to
Governance API
    ↓ operates on
Kernel State
```

### Adapter Responsibilities

Adapters provide:
1. **Abstraction**: Hide implementation details from campaigns
2. **Measurement**: Compute metrics from kernel state
3. **Consistency**: Single source of truth for each domain
4. **Mockability**: Easy to substitute for testing

### Required Adapters

| Adapter | Domain | Provides |
|---------|--------|----------|
| `LedgerAdapter` | Governance Ledger | Event access, state reconstruction |
| `StateAdapter` | Governance State | State snapshots, field access |
| `GraphAdapter` | Institution/Capability Graphs | Node/edge queries, traversal |
| `ReplayAdapter` | Replay Engine | Deterministic state reconstruction |
| `CertificateAdapter` | Certificates | Issue, verify, export certificates |
| `FingerprintAdapter` | Fingerprints | Compute, compare fingerprints |
| `ArchaeologyAdapter` | Archaeology | Historical chain reconstruction |
| `FitnessAdapter` | Fitness Evaluator | Fitness metrics computation |
| `EntropyAdapter` | Entropy Tracker | Entropy metrics computation |
| `CostAdapter` | Cost Ledger | Cost tracking, reconstruction |

### Adapter Interface Contract

Each adapter implements a standard interface:

```elixir
defmodule TiannaraOS.Governance.Validation.Adapters.LedgerAdapter do
  @callback get_events() :: [Event.t()]
  @callback append_event(event_type, data) :: {:ok, Event.t()} | {:error, term()}
  @callback reconstruct_state() :: GovernanceState.t()
  @callback compute_hash() :: String.t()
end
```

### Measurement Ownership

**Adapters own measurement logic**, not campaigns:

```elixir
# WRONG: Campaign computes entropy
def run_entropy_campaign do
  entropy = calculate_entropy(state)  # ❌ Duplicate logic
end

# CORRECT: Campaign requests from adapter
def run_entropy_campaign do
  entropy = EntropyAdapter.measure_entropy(state)  # ✅ Single source
end
```

---

## Section 8: Laboratory Decomposition

The validation laboratory MUST be decomposed into six components, not one monolithic module.

### Component Architecture

```
GovernanceValidationLaboratory (orchestrator)
    ↓ delegates to
CampaignRegistry (lookup constitutional specs)
    ↓ provides specs to
CampaignExecutor (execute campaigns from specs)
    ↓ produces results for
EvidenceCollector (gather raw evidence)
    ↓ passes to
EvidenceSigner (cryptographically sign artifacts)
    ↓ aggregates via
EvidenceAggregator (combine campaign results)
    ↓ formats by
ReportGenerator (produce human-readable report)
```

### Component Responsibilities

#### 1. GovernanceValidationLaboratory (Orchestrator)

```elixir
defmodule TiannaraOS.Governance.Validation.GovernanceValidationLaboratory do
  @spec run_full_campaign(threshold_level) :: {:ok, map()} | {:error, term()}
  @spec run_campaign(String.t(), threshold_level) :: {:ok, map()} | {:error, term()}
  @spec explain_campaign(String.t()) :: %CampaignExplanation{}
end
```

**Responsibility**: Orchestrate campaign execution according to constitutional specs.

---

#### 2. CampaignRegistry

```elixir
defmodule TiannaraOS.Governance.Validation.CampaignRegistry do
  @spec get_campaign_spec(String.t()) :: map()
  @spec get_campaign_at_version(String.t(), String.t()) :: map()
  @spec list_all_campaigns() :: [String.t()]
  @spec get_dependencies(String.t()) :: [String.t()]
  @spec get_threshold(String.t(), :minimum | :recommended | :certification | :stress) :: non_neg_integer()
end
```

**Responsibility**: Lookup constitutional specifications from campaign registry.

---

#### 3. CampaignExecutor

```elixir
defmodule TiannaraOS.Governance.Validation.CampaignExecutor do
  @spec execute_campaign(spec_map, threshold_level) :: {:ok, map()} | {:error, term()}
  @spec execute_campaign_parallel([spec_map]) :: %{String.t() => {:ok, map()} | {:error, term()}}
  @spec execute_phase(phase_number) :: %{String.t() => {:ok, map()} | {:error, term()}}
end
```

**Responsibility**: Execute campaigns according to constitutional specs, respecting dependencies.

---

#### 4. EvidenceCollector

```elixir
defmodule TiannaraOS.Governance.Validation.EvidenceCollector do
  @spec collect_raw_evidence(campaign_result) :: binary()
  @spec compute_measurements(adapter_results) :: map()
  @spec generate_statistical_summary(raw_data) :: map()
  @spec compute_input_fingerprint(canonical_inputs) :: String.t()
  @spec compute_output_fingerprint(campaign_output) :: String.t()
end
```

**Responsibility**: Gather raw evidence and compute measurements from adapters.

---

#### 5. EvidenceSigner

```elixir
defmodule TiannaraOS.Governance.Validation.EvidenceSigner do
  @spec sign_artifact(EvidenceArtifact.t()) :: EvidenceArtifact.t()
  @spec verify_signature(EvidenceArtifact.t()) :: :valid | :invalid
  @spec compute_content_hash(artifact) :: String.t()
  @spec store_content_addressed(artifact) :: String.t()  # Returns hash
end
```

**Responsibility**: Cryptographically sign evidence artifacts and store content-addressed.

---

#### 6. EvidenceAggregator

```elixir
defmodule TiannaraOS.Governance.Validation.EvidenceAggregator do
  @spec aggregate_results([EvidenceArtifact.t()]) :: %{
    overall_status: :pass | :fail | :partial,
    total_tests: non_neg_integer(),
    passed_tests: non_neg_integer(),
    failed_tests: non_neg_integer(),
    campaign_results: %{String.t() => :pass | :fail}
  }
  @spec determine_freeze_recommendation(aggregated_results) :: :freeze | :do_not_freeze
end
```

**Responsibility**: Combine individual campaign results into overall assessment.

---

#### 7. ReportGenerator

```elixir
defmodule TiannaraOS.Governance.Validation.ReportGenerator do
  @spec generate_markdown_report(aggregated_results, [EvidenceArtifact.t()]) :: String.t()
  @spec export_json_report(aggregated_results, [EvidenceArtifact.t()]) :: map()
  @spec generate_freeze_recommendation(aggregated_results) :: :freeze | :do_not_freeze
end
```

**Responsibility**: Produce human-readable reports and freeze recommendations.

---

## Section 9: Execution Semantics

Defines how campaigns execute deterministically.

### Determinism Requirements

1. **Fixed seed**: All random generation uses campaign-specified seed
2. **Canonical inputs**: Only use inputs from `canonical_inputs` list
3. **Replay certificate**: Every execution produces replay certificate
4. **Content-addressed**: Artifacts stored by hash, not name

### Execution Flow

```
1. Load campaign spec from CampaignRegistry
2. Resolve dependencies (execute if not yet executed)
3. Initialize adapters for canonical inputs
4. Execute campaign logic with fixed seed
5. Collect evidence via EvidenceCollector
6. Sign artifact via EvidenceSigner
7. Store content-addressed
8. Return result to orchestrator
```

### Replay Verification

To verify a campaign result:

```
1. Load evidence artifact by hash
2. Verify signature
3. Replay campaign with same seed and inputs
4. Compare output fingerprint
5. Verify match (exact equality, no epsilon)
```

---

## Section 10: Constitutional Amendments

This document can only be modified through constitutional amendment process.

### Amendment Process

1. **Propose**: Submit RFC with proposed changes
2. **Review**: Review Board evaluates impact on validation integrity
3. **Simulate**: Run validation campaigns with proposed changes
4. **Ratify**: Governance Council votes on amendment (2/3 majority)
5. **Archive**: Old version preserved in `/archive/constitution/v{old_version}.md`
6. **Execute**: New version becomes canonical

### Version History

| Version | Date | Changes | Amended By |
|---------|------|---------|------------|
| 1.0.0 | 2026-06-13 | Initial constitution | Governance Council |

### Backward Compatibility

New versions MUST specify:
- Which previous version they supersede
- Migration path for existing campaigns
- Deprecation timeline for old schemas

---

## Conclusion

This constitution ensures that governance validation is:

✅ **Defined** - Single canonical specification for all campaigns  
✅ **Audited** - Evidence artifacts enable independent verification  
✅ **Replayable** - Deterministic execution with cryptographic proof  
✅ **Explainable** - Every campaign supports `ExplainCampaign()` query  
✅ **Composable** - Seven tiny components, not one monolithic module  
✅ **Adaptable** - Thresholds evolve through constitutional amendment  
✅ **Versioned** - Campaign versions enable historical replay  
✅ **Content-Addressed** - Artifacts stored by hash, ensuring immutability  

The governance layer now has the same constitutional discipline as Phase 13's scientific execution layer.

---

**Signed**: Tiannara Constitutional Architecture Team  
**Date**: June 13, 2026  
**Authority**: Governance Council Ratification Required  
**Next Amendment Window**: After Phase 14.1 RFC System Implementation
