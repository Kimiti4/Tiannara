# Discovery Replay Model

## Overview

This document specifies the deterministic replay model for Phase 15 Scientific Discovery. Replay is the cornerstone of scientific reproducibility: every experiment, analysis, and discovery must be exactly replayable from its content-addressed inputs.

---

## Replay Principles

1. **Deterministic Execution**: Same inputs + same environment → same outputs
2. **Content-Addressed Inputs**: All inputs identified by Blake3 hashes
3. **Environment Snapshots**: Complete runtime state captured at execution start
4. **Immutable Ledger**: Execution timeline append-only, cryptographically verified
5. **Independent Verification**: Replay by independent validator required for certification

---

## Replay Types

### 1. Full Replay (Gold Standard)
- Complete re-execution from environment snapshot
- Identical RNG state, clock, software versions
- Produces bit-for-bit identical evidence
- Required for: Discovery certification, Theory evolution

### 2. Statistical Replay (Validation)
- Re-run statistical analysis on same evidence
- Verifies analysis code produces identical results
- Required for: Statistical result validation

### 3. Pipeline Replay (Integration)
- Replay entire pipeline stage from registered inputs
- Verifies stage determinism end-to-end
- Required for: Pipeline certification

### 4. Archaeological Replay (Historical)
- Replay from any historical checkpoint
- Uses archived environment snapshots
- Required for: Long-horizon validation, Audit

---

## Environment Snapshot

### Snapshot Schema
```json
{
  "snapshot_id": "blake3_hash",
  "snapshot_type": "EXPERIMENT_START|EXPERIMENT_END|PIPELINE_STAGE|CHECKPOINT",
  "timestamp": "ISO8601",
  "runtime_hash": "blake3_hash",
  "rng_state": "serialized_rng_state",
  "clock_offset_ns": "integer",
  "software_versions": {
    "object",
  "hardware_fingerprint": "blake3_hash",
  "memory_state_hash": "blake3_hash",
  "process_state_hash": "blake3_hash",
  "filesystem_snapshot_hash": "blake3_hash",
  "network_state_hash": "blake3_hash"
}
```

### Runtime Hash Computation
```elixir
defmodule RuntimeHash do
  @spec compute() :: content_hash()
  def compute do
    state = %{
      beam_version: :erlang.system_info(:version),
      otp_release: :erlang.system_info(:otp_release),
      scheduler_count: :erlang.system_info(:scheduler_count),
      word_size: :erlang.system_info(:wordsize),
      loaded_modules: :code.all_loaded() |> Enum.sort() |> Enum.map(&{&1, :code.which(&1)}) |> Map.new(),
      nif_versions: NativeNIF.versions(),
      config_hash: Config.frozen_hash()
    }
    Blake3.hash(state)
  end
end
```

### RNG State Capture
```elixir
defmodule RNGSnapshot do
  @spec capture() :: String.t()
  def capture do
    # Capture all RNG states
    %{
      erlang: :rand.get_state(),
      ex_rng: ExRNG.get_state(),
      numpy: PythonNIF.numpy_rng_state(),
      torch: PythonNIF.torch_rng_state(),
      custom: CustomRNG.get_all_states()
    }
    |> Jason.encode!(keys: :sort)
    |> Base.encode16()
  end
end
```

---

## Replay Engine

### Interface
```elixir
defmodule ReplayEngine do
  @spec replay(execution_id, replay_type, verifier_id) :: {:ok, replay_result} | {:error, reason}
  def replay(execution_id, replay_type, verifier_id) do
    # 1. Load original execution
    # 2. Load environment snapshot
    # 3. Restore environment
    # 4. Execute replay
    # 5. Compare outputs
    # 6. Generate replay certificate
  end

  @spec verify_replay(original_hash, replay_hash, tolerance) :: boolean()
  def verify_replay(original_hash, replay_hash, tolerance \\ 0) do
    original_hash == replay_hash
  end
end
```

### Replay Process

```
┌─────────────────┐
│  Load Original  │
│  Execution      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Load Snapshot  │
│  (Environment)  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Restore Env    │
│  (RNG, Clock,   │
│   Versions)     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Execute Replay │
│  (Deterministic)│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Compare Outputs│
│  (Bit-for-bit)  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Issue Cert     │
│  (Replay Cert)  │
└─────────────────┘
```

### Replay Result Schema
```json
{
  "replay_id": "blake3_hash",
  "original_execution_id": "blake3_hash",
  "replay_type": "FULL|STATISTICAL|PIPELINE|ARCHAEOLOGICAL",
  "verifier_id": "civilization_id",
  "environment_snapshot_hash": "blake3_hash",
  "replay_hash": "blake3_hash",
  "original_hash": "blake3_hash",
  "match": "boolean",
  "divergence_details": "object|null",
  "replay_duration_ms": "integer",
  "timestamp": "ISO8601",
  "certificate_id": "blake3_hash"
}
```

---

## Determinism Requirements

### Execution Determinism
1. **Fixed Step Order**: Protocol steps executed in declared sequence
2. **Seeded RNG**: `seed = blake3(experiment_id <> step_number)`
3. **No Wall Clock**: Logical time only; `timestamp = start_time + step_duration`
4. **No External I/O**: All inputs pre-loaded, content-addressed
5. **Sorted Collections**: Maps/sets iterated in deterministic order

### Analysis Determinism
1. **Fixed Algorithm Versions**: Analysis code hash recorded
2. **Sorted Data**: Input evidence sorted by content hash before processing
3. **Deterministic Libraries**: Only deterministic numerical libraries allowed
4. **Fixed Precision**: IEEE 754 double precision; no extended precision

### Pipeline Determinism
1. **Topological Order**: Stages execute in DAG topological order
2. **Idempotent Stages**: Re-running stage produces same output
3. **Content-Addressed Cache**: Stage outputs cached by input hashes

---

## Replay Verification

### Verification Levels

#### Level 1: Hash Equality (Strict)
```elixir
def verify_level1(original, replay) do
  original.content_hash == replay.content_hash
end
```
- Required for: Discovery certification, Theory operations

#### Level 2: Semantic Equality (Statistical)
```elixir
def verify_level2(original, replay) do
  # For statistical results: compare within numerical tolerance
  Enum.all?(original.results, fn {k, v} ->
    case replay.results[k] do
      nil -> false
      rv -> abs(v - rv) < 1e-10
    end
  end)
end
```
- Allowed for: Statistical re-analysis with same code version

#### Level 3: Structural Equality (Pipeline)
```elixir
def verify_level3(original, replay) do
  # Same DAG structure, same content hashes at each node
  original.dag_structure == replay.dag_structure &&
  Enum.all?(original.nodes, fn {hash, _} -> Map.has_key?(replay.nodes, hash) end)
end
```
- Used for: Pipeline stage replay

---

## Replay Certificate

### Schema
```json
{
  "certificate_id": "blake3_hash",
  "certificate_type": "REPLAY",
  "original_hash": "blake3_hash",
  "replay_hash": "blake3_hash",
  "environment_snapshot_hash": "blake3_hash",
  "executor_id": "civilization_id",
  "verifier_signature": "cryptographic_signature",
  "timestamp": "ISO8601",
  "verification_level": "LEVEL1|LEVEL2|LEVEL3",
  "match": "boolean",
  "divergence_report": "object|null"
}
```

### Issuance Process
1. Replay completes successfully
2. Verification passes at required level
3. Certificate issued by Certificate Issuer
4. Certificate registered in Certificate Registry
5. Original execution marked `REPLAY_VERIFIED`

---

## Independent Replay Requirement

### Policy
- **Discovery Certification**: Requires ≥2 independent replays by different civilizations
- **Theory Evolution**: Requires ≥1 independent replay of supporting experiments
- **Capital Computation**: Requires replay of all source experiments

### Independent Validator Selection
```elixir
defmodule IndependentValidatorSelector do
  @spec select(execution_id, count) :: [civilization_id]
  def select(execution_id, count) do
    # Exclude original executor
    # Exclude civilizations with shared infrastructure
    # Select by: reputation, diversity, availability
    # Return cryptographically verifiable selection proof
  end
end
```

### Replay Attestation
Each independent validator produces:
1. Replay certificate (signed)
2. Environment fingerprint (hardware, software)
3. Timing proof (blockchain timestamp or VDF)
4. Divergence report (if any)

---

## Replay Storage

### Replay Ledger
Append-only ledger of all replay attempts:
```json
{
  "replay_ledger_entry": {
    "entry_id": "blake3_hash",
    "replay_id": "blake3_hash",
    "original_execution_id": "blake3_hash",
    "verifier_id": "civilization_id",
    "result": "SUCCESS|FAILURE|DIVERGENCE",
    "certificate_id": "blake3_hash|null",
    "timestamp": "ISO8601"
  }
}
```

### Replay Index
- By original execution: `original_execution_id → [replay_id]`
- By verifier: `verifier_id → [replay_id]`
- By result: `result → [replay_id]`
- By time: `timestamp → [replay_id]`

---

## Archaeological Replay

### Purpose
Replay historical executions from any point in the system's history.

### Archive Format
```json
{
  "archive_id": "blake3_hash",
  "checkpoint_type": "EPOCH|DAILY|ON_DEMAND",
  "timestamp": "ISO8601",
  "runtime_snapshot": "snapshot_object",
  "registry_roots": {
    "observation": "merkle_root",
    "hypothesis": "merkle_root",
    "experiment": "merkle_root",
    "evidence": "merkle_root",
    "discovery": "merkle_root",
    "theory": "merkle_root"
  },
  "execution_logs": "compressed_logs_hash",
  "code_archive_hash": "blake3_hash"
}
```

### Archaeological Replay Process
1. Load archive for target timestamp
2. Restore runtime from snapshot
3. Restore registries from merkle roots
4. Execute replay in restored environment
5. Compare with historical execution log

### Long-Horizon Guarantees
- Archives created at every epoch boundary
- Code archive includes all dependencies (NIFs, system libs)
- Hardware fingerprint recorded for compatibility checking
- Emulation layer for obsolete hardware architectures

---

## Replay Failure Handling

### Divergence Classification
```elixir
defmodule DivergenceClassifier do
  @type divergence_type :: :rng | :timing | :floating_point | :external | :code_change | :hardware | :unknown

  @spec classify(original, replay) :: divergence_type
  def classify(original, replay) do
    cond do
      rng_divergence?(original, replay) -> :rng
      timing_divergence?(original, replay) -> :timing
      fp_divergence?(original, replay) -> :floating_point
      external_divergence?(original, replay) -> :external
      code_change?(original, replay) -> :code_change
      hardware_divergence?(original, replay) -> :hardware
      true -> :unknown
    end
  end
end
```

### Remediation
| Divergence Type | Remediation |
|-----------------|-------------|
| RNG | Restore exact RNG state; verify seeding |
| Timing | Use logical time; disable async |
| Floating Point | Enforce IEEE 754; same BLAS version |
| External | All inputs must be content-addressed |
| Code Change | Replay with archived code version |
| Hardware | Use emulation or compatible hardware |

---

## Replay Metrics

### System-Level Metrics
- **Replay Success Rate**: % of replays with `match=true`
- **Replay Latency**: Time from request to certificate (p50, p95, p99)
- **Independent Replay Rate**: % of discoveries with ≥2 independent replays
- **Archaeological Replay Success**: % of historical replays successful

### Quality Metrics
- **Divergence Rate**: % of replays with divergence
- **Divergence Classification**: Breakdown by type
- **Time to Divergence Detection**: How quickly divergence caught
- **Remediation Success**: % of divergences resolved

### Capacity Metrics
- **Replay Queue Depth**: Pending replay requests
- **Replay Throughput**: Replays completed per hour
- **Storage Growth**: Replay ledger + certificates size over time

---

## Integration with Pipeline

### Automatic Replay Triggers
```elixir
defmodule ReplayTrigger do
  @spec on_discovery_validated(discovery_id) :: :ok
  def on_discovery_validated(discovery_id) do
    # Trigger replay of all supporting executions
    executions = Discovery.get_supporting_executions(discovery_id)
    Enum.each(executions, &ReplayEngine.schedule_replay(&1, :FULL))
  end

  @spec on_theory_evolved(theory_id) :: :ok
  def on_theory_evolved(theory_id) do
    # Trigger replay of key supporting experiments
    experiments = Theory.get_key_experiments(theory_id)
    Enum.each(experiments, &ReplayEngine.schedule_replay(&1, :FULL))
  end
end
```

### Replay-Gated Operations
- Discovery certificate issuance: Requires replay verification
- Theory supersession: Requires replay of contradicting evidence
- Capital delta computation: Requires replay of source experiments

---

## Constitutional Compliance

This replay model satisfies:
- **Reproducibility**: Every claim replayable from content-addressed inputs
- **Evidence-First**: Replay operates on evidence, not claims
- **Content-Addressed**: All inputs/outputs identified by Blake3
- **Archaeological**: Full historical replay capability
- **Ownership**: Explicit verifier ownership of replay certificates
- **Lineage**: Replay certificates form verification chain

---

*This document is part of Phase 15.0 Architecture Review. No implementation occurs in this phase.*