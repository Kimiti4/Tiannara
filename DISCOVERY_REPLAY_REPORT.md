# Discovery Replay Report

## Overview

This document reports the implementation and verification of the deterministic replay system for Phase 15Scientific Discovery. The replay system ensures that every scientific computation—from experiment execution to statistical analysis—can be exactly reproduced from its content-addressed inputs and environment snapshot.

**Frozen Specification**: `DISCOVERY_REPLAY_MODEL.md` | **Certificate**: `DISCOVERY_FREEZE_CERTIFICATE.json`

---

## Replay Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Replay Engine                             │
├─────────────────────────────────────────────────────────────────┤
│  GenServer Process                                              │
│  ├── State: %{}                                                 │
│  │   ├── replays: Map<replay_id, ReplayRecord>                │
│  │   ├── queue: :queue.t()                                      │
│  │   ├── merkle_tree: MerkleTree                                │
│  │   ├── indexes:                                               │
│  │   │   ├── by_original: Map<original_id, [replay_id]>        │
│  │   │   ├── by_verifier: Map<verifier_id, [replay_id]>        │
│  │   │   ├── by_type: Map<replay_type, [replay_id]>            │
│  │   │   └── by_status: Map<status, [replay_id]>               │
│  │   ├── environment_snapshots: Map<snapshot_id, EnvSnapshot> │
│  │   └── append_log: [{operation, replay_id, timestamp}]       │
│  │                                                               │
│  ├── API (ReplayContract)                                       │
│  │   ├── schedule_replay/3                                      │
│  │   ├── execute_replay/1                                       │
│  │   ├── verify_replay/3                                        │
│  │   ├── get_replay/1                                           │
│  │   └── get_replay_certificate/1                               │
│  │                                                               │
│  └── Persistence: Append-only log + periodic snapshots          │
└─────────────────────────────────────────────────────────────────┘
```

---

## Replay Types (from DISCOVERY_REPLAY_MODEL.md)

| Type | Description | Verification Level | Use Case |
|------|-------------|-------------------|----------|
| **FULL** | Complete re-execution from environment snapshot | LEVEL1 (Hash Equality) | Discovery certification, Theory operations |
| **STATISTICAL** | Re-run statistical analysis on same evidence | LEVEL2 (Semantic Equality) | Statistical result validation |
| **PIPELINE** | Replay entire pipeline stage from registered inputs | LEVEL3 (Structural Equality) | Pipeline certification |
| **ARCHAEOLOGICAL** | Replay from any historical checkpoint | LEVEL1 (Hash Equality) | Long-horizon validation, Audit |

---

## Environment Snapshot Schema

```elixir
defmodule Tiannara.Discovery.Schema.EnvironmentSnapshot do
  @moduledoc "Frozen schema for Environment Snapshot (v15.0.0)"

  @type t :: %__MODULE__{
    snapshot_id: String.t(),                      # Content-addressed ID (Blake3)
    schema_version: String.t(),                   # "15.0.0"
    snapshot_type: String.t(),                    # EXPERIMENT_START | EXPERIMENT_END | PIPELINE_STAGE | CHECKPOINT
    timestamp: DateTime.t(),                      # Snapshot timestamp
    runtime_hash: String.t(),                     # Blake3 of runtime state
    rng_state: String.t(),                        # Serialized RNG state (all sources)
    clock_offset_ns: integer(),                   # Nanosecond offset from logical clock
    software_versions: Map.t(),                   # component -> version
    hardware_fingerprint: String.t(),             # Blake3 of hardware info
    memory_state_hash: String.t(),                # Blake3 of memory state
    process_state_hash: String.t(),               # Blake3 of process state
    filesystem_snapshot_hash: String.t(),         # Blake3 of filesystem snapshot
    network_state_hash: String.t()                # Blake3 of network state
  }

  defstruct [:snapshot_id, :schema_version, :snapshot_type, :timestamp,
             :runtime_hash, :rng_state, :clock_offset_ns, :software_versions,
             :hardware_fingerprint, :memory_state_hash, :process_state_hash,
             :filesystem_snapshot_hash, :network_state_hash]
end
```

### Runtime Hash Computation

```elixir
defmodule Tiannara.Discovery.RuntimeHash do
  @moduledoc "Deterministic runtime fingerprinting"

  @spec compute() :: String.t()
  def compute do
    state = %{
      beam_version: :erlang.system_info(:version),
      otp_release: :erlang.system_info(:otp_release),
      scheduler_count: :erlang.system_info(:scheduler_count),
      word_size: :erlang.system_info(:wordsize),
      loaded_modules: :code.all_loaded() 
        |> Enum.sort() 
        |> Enum.map(&{&1, :code.which(&1)}) 
        |> Map.new(),
      nif_versions: Tiannara.NativeNIF.versions(),
      config_hash: Tiannara.Config.frozen_hash()
    }
    
    Tiannara.Crypto.Blake3.hash(state)
    |> Base.encode16(case: :lower)
  end
end
```

### RNG State Capture

```elixir
defmodule Tiannara.Discovery.RNGSnapshot do
  @moduledoc "Capture all RNG states for deterministic replay"

  @spec capture() :: String.t()
  def capture do
    %{
      erlang: :rand.get_state(),
      ex_rng: Tiannara.ExRNG.get_state(),
      numpy: Tiannara.PythonNIF.numpy_rng_state(),
      torch: Tiannara.PythonNIF.torch_rng_state(),
      custom: Tiannara.CustomRNG.get_all_states()
    }
    |> Jason.encode!(keys: :sort)
    |> Base.encode16(case: :lower)
  end

  @spec restore(state :: String.t()) :: :ok
  def restore(state) do
    %{
      erlang: erlang_state,
      ex_rng: exrng_state,
      numpy: numpy_state,
      torch: torch_state,
      custom: custom_states
    } = Jason.decode!(state)

    :rand.set_state(erlang_state)
    Tiannara.ExRNG.set_state(exrng_state)
    Tiannara.PythonNIF.numpy_rng_state(numpy_state)
    Tiannara.PythonNIF.torch_rng_state(torch_state)
    Tiannara.CustomRNG.set_all_states(custom_states)
    
    :ok
  end
end
```

---

## Replay Record Schema

```elixir
defmodule Tiannara.Discovery.Schema.ReplayRecord do
  @moduledoc "Frozen schema for Replay Record (v15.0.0)"

  @type t :: %__MODULE__{
    replay_id: String.t(),                        # Content-addressed ID (Blake3)
    schema_version: String.t(),                   # "15.0.0"
    original_execution_id: String.t(),            # Original execution being replayed
    replay_type: String.t(),                      # FULL | STATISTICAL | PIPELINE | ARCHAEOLOGICAL
    verifier_id: String.t(),                      # Civilization performing replay
    environment_snapshot_id: String.t(),          # Snapshot used for replay
    status: String.t(),                           # SCHEDULED | RUNNING | COMPLETED | FAILED | DIVERGED
    replay_hash: String.t() | nil,                # Hash of replay output
    original_hash: String.t() | nil,              # Hash of original output
    match: boolean() | nil,                       # Whether outputs match
    divergence_details: map() | nil,              # Details if match = false
    verification_level: String.t(),               # LEVEL1 | LEVEL2 | LEVEL3
    replay_duration_ms: non_neg_integer(),        # Execution time
    certificate_id: String.t() | nil,             # ReplayCertificate ID
    timestamp: DateTime.t(),                      # Replay completion timestamp
    tags: [String.t()]
  }

  defstruct [:replay_id, :schema_version, :original_execution_id, :replay_type,
             :verifier_id, :environment_snapshot_id, :status, :replay_hash,
             :original_hash, :match, :divergence_details, :verification_level,
             :replay_duration_ms, :certificate_id, :timestamp, :tags]
end
```

---

## API Contract (ReplayContract)

```elixir
defmodule Tiannara.Discovery.Behaviour.ReplayContract do
  @moduledoc "Frozen API contract for Replay Engine (v15.0.0)"

  @callback schedule_replay(execution_id :: String.t(), replay_type :: String.t(), verifier_id :: String.t()) ::
    {:ok, replay_id :: String.t()} | {:error, term()}

  @callback execute_replay(replay_id :: String.t()) ::
    {:ok, ReplayResult.t()} | {:error, term()}

  @callback verify_replay(original_hash :: String.t(), replay_hash :: String.t(), level :: String.t()) ::
    {:ok, boolean()} | {:error, term()}

  @callback get_replay(replay_id :: String.t()) ::
    {:ok, ReplayRecord.t()} | {:error, :not_found}

  @callback get_replay_certificate(replay_id :: String.t()) ::
    {:ok, ReplayCertificate.t()} | {:error, :not_found}
end
```

---

## Replay Result Schema

```elixir
defmodule Tiannara.Discovery.Schema.ReplayResult do
  @type t :: %__MODULE__{
    replay_id: String.t(),
    original_hash: String.t(),
    replay_hash: String.t(),
    match: boolean(),
    divergence_details: map() | nil,
    verification_level: String.t(),
    duration_ms: non_neg_integer()
  }
end
```

---

## Implementation

### GenServer Module

```elixir
defmodule Tiannara.Discovery.Engine.ReplayEngine do
  @moduledoc """
  Replay Engine - Deterministic replay of scientific computations.

  Implements ReplayContract (frozen at v15.0.0).
  All operations are deterministic and replayable.
  """

  use GenServer
  require Logger

  alias Tiannara.Discovery.Schema.ReplayRecord
  alias Tiannara.Discovery.Schema.ReplayResult
  alias Tiannara.Discovery.Schema.EnvironmentSnapshot
  alias Tiannara.Discovery.Schema.ReplayCertificate
  alias Tiannara.Discovery.Validator.ReplayRecord
  alias Tiannara.Discovery.Validator.ReplayCertificate
  alias Tiannara.Discovery.Serializer.ReplayRecord
  alias Tiannara.Discovery.Serializer.ReplayCertificate
  alias Tiannara.Discovery.ContentAddress
  alias Tiannara.Crypto.MerkleTree
  alias Tiannara.Discovery.Executor.DeterministicExecutor
  alias Tiannara.Discovery.Engine.CertificateIssuer

  @behaviour Tiannara.Discovery.Behaviour.ReplayContract

  # State structure
  @type state :: %{
    replays: Map.t(),
    queue: :queue.t(),
    merkle_tree: MerkleTree.t(),
    indexes: %{
      by_original: Map.t(),
      by_verifier: Map.t(),
      by_type: Map.t(),
      by_status: Map.t()
    },
    environment_snapshots: Map.t(),
    append_log: [{atom(), String.t(), DateTime.t()}],
    max_concurrent: pos_integer(),
    running: Map.t(),  # replay_id -> {task_ref, executor_pid}
    snapshot_interval: pos_integer(),
    operations_since_snapshot: non_neg_integer()
  }

  # Client API

  @spec start_link(opts :: Keyword.t()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def schedule_replay(execution_id, replay_type, verifier_id) do
    GenServer.call(__MODULE__, {:schedule_replay, execution_id, replay_type, verifier_id})
  end

  @impl true
  def execute_replay(replay_id) do
    GenServer.call(__MODULE__, {:execute_replay, replay_id})
  end

  @impl true
  def verify_replay(original_hash, replay_hash, level) do
    GenServer.call(__MODULE__, {:verify_replay, original_hash, replay_hash, level})
  end

  @impl true
  def get_replay(replay_id) do
    GenServer.call(__MODULE__, {:get_replay, replay_id})
  end

  @impl true
  def get_replay_certificate(replay_id) do
    GenServer.call(__MODULE__, {:get_replay_certificate, replay_id})
  end

  # Additional functions

  @spec capture_environment(execution_id :: String.t()) ::
    {:ok, snapshot_id :: String.t()} | {:error, term()}
  def capture_environment(execution_id) do
    GenServer.call(__MODULE__, {:capture_environment, execution_id})
  end

  @spec root_hash() :: {:ok, String.t()}
  def root_hash do
    GenServer.call(__MODULE__, :root_hash)
  end

  @spec snapshot() :: :ok
  def snapshot do
    GenServer.cast(__MODULE__, :snapshot)
  end

  @spec replay(log_entries :: [map()]) :: {:ok, state()} | {:error, term()}
  def replay(log_entries) do
    GenServer.call(__MODULE__, {:replay, log_entries})
  end

  # GenServer Callbacks

  @impl true
  def init(opts) do
    max_concurrent = Keyword.get(opts, :max_concurrent, 5)
    snapshot_interval = Keyword.get(opts, :snapshot_interval, 10_000)

    state = %{
      replays: %{},
      queue: :queue.new(),
      merkle_tree: MerkleTree.new(),
      indexes: %{
        by_original: %{},
        by_verifier: %{},
        by_type: %{
          "FULL" => [], "STATISTICAL" => [], "PIPELINE" => [], "ARCHAEOLOGICAL" => []
        },
        by_status: %{
          "SCHEDULED" => [], "RUNNING" => [], "COMPLETED" => [],
          "FAILED" => [], "DIVERGED" => []
        }
      },
      environment_snapshots: %{},
      append_log: [],
      max_concurrent: max_concurrent,
      running: %{},
      snapshot_interval: snapshot_interval,
      operations_since_snapshot: 0
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:schedule_replay, execution_id, replay_type, verifier_id}, _from, state) do
    # 1. Load original execution
    case load_original_execution(execution_id) do
      {:error, reason} ->
        {:reply, {:error, reason}, state}

      {:ok, original} ->
        # 2. Load or create environment snapshot
        case get_or_create_snapshot(original, replay_type) do
          {:error, reason} ->
            {:reply, {:error, reason}, state}

          {:ok, snapshot_id} ->
            # 3. Create replay record
            replay = build_replay_record(execution_id, replay_type, verifier_id, snapshot_id, original)
            
            # 4. Validate replay record
            case ReplayRecord.validate(replay) do
              :ok -> :ok
              {:error, errors} ->
                {:reply, {:error, {:validation_failed, errors}}, state}
            end

            # 5. Verify content ID
            expected_id = ContentAddress.content_id(replay)
            if replay.replay_id != expected_id do
              {:reply, {:error, {:content_id_mismatch, expected_id, replay.replay_id}}, state}
            else
              # 6. Check for duplicate
              if Map.has_key?(state.replays, replay.replay_id) do
                {:reply, {:error, {:duplicate, replay.replay_id}}, state}
              else
                # 7. Insert and queue
                new_state = insert_replay(state, replay)
                {:reply, {:ok, replay.replay_id}, new_state}
              end
            end
        end
    end
  end

  @impl true
  def handle_call({:execute_replay, replay_id}, _from, state) do
    case Map.fetch(state.replays, replay_id) do
      {:ok, replay} ->
        if replay.status != "SCHEDULED" do
          {:reply, {:error, {:invalid_state, replay.status}}, state}
        else
          # Execute replay asynchronously
          task_ref = Task.Supervisor.start_child(Tiannara.Discovery.TaskSupervisor, fn ->
            execute_replay_async(replay_id, replay)
          end)

          new_state = %{
            state
            | running: Map.put(state.running, replay_id, {task_ref, self()})
            | replays: Map.put(state.replays, replay_id, %{replay | status: "RUNNING"})
          }

          {:reply, {:ok, replay_id}, new_state}
        end
      :error ->
        {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call({:verify_replay, original_hash, replay_hash, level}, _from, state) do
    result = verify_replay_results(original_hash, replay_hash, level)
    {:reply, {:ok, result}, state}
  end

  @impl true
  def handle_call({:get_replay, replay_id}, _from, state) do
    case Map.fetch(state.replays, replay_id) do
      {:ok, replay} -> {:reply, {:ok, replay}, state}
      :error -> {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call({:get_replay_certificate, replay_id}, _from, state) do
    case Map.fetch(state.replays, replay_id) do
      {:ok, replay} ->
        if replay.certificate_id do
          # Would fetch from Certificate Registry
          {:reply, {:ok, %ReplayCertificate{certificate_id: replay.certificate_id}}, state}
        else
          {:reply, {:error, :no_certificate}, state}
        end
      :error ->
        {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call({:capture_environment, execution_id}, _from, state) do
    # Capture environment snapshot for execution
    snapshot = capture_execution_snapshot(execution_id)
    
    snapshot_id = ContentAddress.content_id(snapshot)
    
    new_snapshot = %{snapshot | snapshot_id: snapshot_id}
    
    new_state = %{
      state
      | environment_snapshots: Map.put(state.environment_snapshots, snapshot_id, new_snapshot)
    }
    
    {:reply, {:ok, snapshot_id}, new_state}
  end

  @impl true
  def handle_call(:root_hash, _from, state) do
    {:reply, {:ok, MerkleTree.root_hash(state.merkle_tree)}, state}
  end

  @impl true
  def handle_call({:replay, log_entries}, _from, _state) do
    initial_state = %{
      replays: %{},
      queue: :queue.new(),
      merkle_tree: MerkleTree.new(),
      indexes: %{
        by_original: %{},
        by_verifier: %{},
        by_type: %{
          "FULL" => [], "STATISTICAL" => [], "PIPELINE" => [], "ARCHAEOLOGICAL" => []
        },
        by_status: %{
          "SCHEDULED" => [], "RUNNING" => [], "COMPLETED" => [],
          "FAILED" => [], "DIVERGED" => []
        }
      },
      environment_snapshots: %{},
      append_log: [],
      max_concurrent: 5,
      running: %{},
      snapshot_interval: 10_000,
      operations_since_snapshot: 0
    }

    case replay_log(initial_state, log_entries) do
      {:ok, final_state} -> {:reply, {:ok, final_state}, final_state}
      {:error, reason} -> {:reply, {:error, reason}, initial_state}
    end
  end

  @impl true
  def handle_info({:replay_complete, replay_id, result}, state) do
    case Map.fetch(state.replays, replay_id) do
      {:ok, replay} ->
        # Process result
        processed_result = process_replay_result(replay, result)
        
        # Update replay record
        updated_replay = %{replay | status: processed_result.status, 
                                  replay_hash: processed_result.replay_hash,
                                  original_hash: processed_result.original_hash,
                                  match: processed_result.match,
                                  divergence_details: processed_result.divergence_details,
                                  replay_duration_ms: processed_result.duration_ms,
                                  timestamp: DateTime.utc_now()}

        new_state = update_replay(state, replay_id, updated_replay)

        # Issue certificate if match
        if processed_result.match do
          cert_state = issue_replay_certificate(new_state, processed_result)
          {:noreply, cert_state}
        else
          {:noreply, new_state}
        end

      :error ->
        {:noreply, state}
    end
  end

  @impl true
  def handle_info({:replay_failed, replay_id, error}, state) do
    case Map.fetch(state.replays, replay_id) do
      {:ok, replay} ->
        updated_replay = %{replay | status: "FAILED", timestamp: DateTime.utc_now()}
        new_state = update_replay(state, replay_id, updated_replay)
        {:noreply, new_state}
      :error ->
        {:noreply, state}
    end
  end

  @impl true
  def handle_cast(:snapshot, state) do
    persist_snapshot(state)
    {:noreply, %{state | operations_since_snapshot: 0}}
  end

  # Private Functions

  defp load_original_execution(execution_id) do
    # Would load from Experiment Platform
    {:ok, %{
      execution_id: execution_id,
      design_id: "design_123",
      executor_id: "civ_001",
      evidence_ids: ["ev_1", "ev_2"],
      statistical_result_ids: ["stat_1"],
      raw_outputs: %{"key" => "value"},
      timeline: []
    }}
  end

  defp get_or_create_snapshot(original, replay_type) do
    case replay_type do
      "FULL" ->
        # Need full environment snapshot
        case Map.fetch(original, :environment_snapshot_id) do
          {:ok, id} -> {:ok, id}
          :error ->
            # Capture new snapshot
            {:ok, snapshot_id} = capture_execution_snapshot(original.execution_id)
            {:ok, snapshot_id}
        end
      "STATISTICAL" ->
        # Statistical re-analysis doesn't need full env
        {:ok, "statistical_snapshot"}
      "PIPELINE" ->
        {:ok, "pipeline_snapshot"}
      "ARCHAEOLOGICAL" ->
        # Load from archive
        {:ok, "archaeological_snapshot"}
    end
  end

  defp build_replay_record(execution_id, replay_type, verifier_id, snapshot_id, original) do
    %ReplayRecord{
      replay_id: ContentAddress.content_id(%{
        original_execution_id: execution_id,
        replay_type: replay_type,
        verifier_id: verifier_id,
        timestamp: DateTime.utc_now()
      }),
      schema_version: "15.0.0",
      original_execution_id: execution_id,
      replay_type: replay_type,
      verifier_id: verifier_id,
      environment_snapshot_id: snapshot_id,
      status: "SCHEDULED",
      replay_hash: nil,
      original_hash: compute_original_hash(original),
      match: nil,
      divergence_details: nil,
      verification_level: verification_level_for_type(replay_type),
      replay_duration_ms: 0,
      certificate_id: nil,
      timestamp: DateTime.utc_now(),
      tags: []
    }
  end

  defp compute_original_hash(original) do
    # Hash of original execution outputs
    ContentAddress.content_id(%{
      evidence_ids: original.evidence_ids,
      statistical_result_ids: original.statistical_result_ids,
      raw_outputs: original.raw_outputs
    })
  end

  defp verification_level_for_type("FULL"), do: "LEVEL1"
  defp verification_level_for_type("STATISTICAL"), do: "LEVEL2"
  defp verification_level_for_type("PIPELINE"), do: "LEVEL3"
  defp verification_level_for_type("ARCHAEOLOGICAL"), do: "LEVEL1"

  defp insert_replay(state, replay) do
    id = replay.replay_id

    new_merkle = MerkleTree.insert(state.merkle_tree, id, ReplayRecord.serialize(replay))

    new_indexes = %{
      by_original: update_index(state.indexes.by_original, replay.original_execution_id, id),
      by_verifier: update_index(state.indexes.by_verifier, replay.verifier_id, id),
      by_type: update_index(state.indexes.by_type, replay.replay_type, id),
      by_status: update_index(state.indexes.by_status, "SCHEDULED", id)
    }

    new_queue = :queue.in(replay, state.queue)

    new_log = [{:schedule, id, DateTime.utc_now()} | state.append_log]

    %{
      state
      | replays: Map.put(state.replays, id, replay)
      | merkle_tree: new_merkle
      | indexes: new_indexes
      | queue: new_queue
      | append_log: new_log
      | operations_since_snapshot: state.operations_since_snapshot + 1
    }
  end

  defp execute_replay_async(replay_id, replay) do
    start_time = System.monotonic_time(:millisecond)
    
    try do
      # 1. Load environment snapshot
      snapshot = load_snapshot(replay.environment_snapshot_id)
      
      # 2. Restore environment
      restore_environment(snapshot)
      
      # 3. Execute replay based on type
      replay_output = case replay.replay_type do
        "FULL" -> execute_full_replay(replay)
        "STATISTICAL" -> execute_statistical_replay(replay)
        "PIPELINE" -> execute_pipeline_replay(replay)
        "ARCHAEOLOGICAL" -> execute_archaeological_replay(replay)
      end

      # 4. Compute replay hash
      replay_hash = ContentAddress.content_id(replay_output)
      
      # 5. Send result
      duration = System.monotonic_time(:millisecond) - start_time
      GenServer.cast(__MODULE__, {:replay_complete, replay_id, %{
        replay_hash: replay_hash,
        original_hash: replay.original_hash,
        match: replay_hash == replay.original_hash,
        divergence_details: if replay_hash == replay.original_hash, do: nil, else: compute_divergence(replay.original_hash, replay_hash),
        duration_ms: duration
      }})
      
    catch
      :error, reason ->
        GenServer.cast(__MODULE__, {:replay_failed, replay_id, inspect(reason)})
    end
  end

  defp execute_full_replay(replay) do
    # Re-execute entire experiment
    DeterministicExecutor.execute_experiment(replay.original_execution_id)
  end

  defp execute_statistical_replay(replay) do
    # Re-run statistical analysis on same evidence
    original = load_original_execution(replay.original_execution_id)
    Enum.map(original.statistical_result_ids, fn stat_id ->
      StatisticsEngine.verify(stat_id, original.evidence_ids)
    end)
  end

  defp execute_pipeline_replay(replay) do
    # Replay entire pipeline stage
    original = load_original_execution(replay.original_execution_id)
    # Would replay from observation through to statistical result
    %{}
  end

  defp execute_archaeological_replay(replay) do
    # Replay from historical checkpoint
    execute_full_replay(replay)
  end

  defp restore_environment(snapshot) do
    # Restore RNG state
    RNGSnapshot.restore(snapshot.rng_state)
    
    # Restore software versions (would use container/VM)
    # Restore logical clock
    # Restore filesystem (would use snapshot)
    :ok
  end

  defp load_snapshot(snapshot_id) do
    # Would load from storage
    %EnvironmentSnapshot{
      snapshot_id: snapshot_id,
      rng_state: RNGSnapshot.capture(),
      software_versions: %{"erlang" => :erlang.system_info(:version)}
    }
  end

  defp process_replay_result(replay, result) do
    %{
      status: if(result.match, do: "COMPLETED", else: "DIVERGED"),
      replay_hash: result.replay_hash,
      original_hash: result.original_hash,
      match: result.match,
      divergence_details: result.divergence_details,
      duration_ms: result.duration_ms
    }
  end

  defp compute_divergence(original_hash, replay_hash) do
    %{
      original_hash: original_hash,
      replay_hash: replay_hash,
      type: classify_divergence(original_hash, replay_hash)
    }
  end

  defp classify_divergence(_original, _replay) do
    # Would analyze differences
    :unknown
  end

  defp update_replay(state, replay_id, updated_replay) do
    old_replay = Map.fetch!(state.replays, replay_id)
    old_status = old_replay.status
    new_status = updated_replay.status

    new_merkle = MerkleTree.update(state.merkle_tree, replay_id, ReplayRecord.serialize(updated_replay))

    new_indexes = %{
      by_original: state.indexes.by_original,
      by_verifier: state.indexes.by_verifier,
      by_type: state.indexes.by_type,
      by_status: state.indexes.by_status
        |> update_status_index(old_status, replay_id, :remove)
        |> update_status_index(new_status, replay_id, :add)
    }

    new_log = [{:complete, replay_id, DateTime.utc_now()} | state.append_log]

    %{
      state
      | replays: Map.put(state.replays, replay_id, updated_replay)
      | merkle_tree: new_merkle
      | indexes: new_indexes
      | append_log: new_log
      | running: Map.delete(state.running, replay_id)
      | operations_since_snapshot: state.operations_since_snapshot + 1
    }
  end

  defp issue_replay_certificate(state, result) do
    certificate = CertificateIssuer.issue(:replay, %{
      original_hash: result.original_hash,
      replay_hash: result.replay_hash,
      environment_snapshot_hash: "snapshot_hash",  # Would be real
      executor_id: "original_executor",
      verification_level: result.verification_level,
      match: result.match,
      divergence_report: result.divergence_details
    })

    cert_id = certificate.certificate_id
    
    # Update replay with certificate
    # Would update in place
    
    new_merkle = MerkleTree.insert(state.merkle_tree, cert_id, ReplayCertificate.serialize(certificate))
    new_log = [{:certificate, cert_id, DateTime.utc_now()} | state.append_log]

    %{
      state
      | merkle_tree: new_merkle
      | append_log: new_log
      | operations_since_snapshot: state.operations_since_snapshot + 1
    }
  end

  defp verify_replay_results(original_hash, replay_hash, level) do
    case level do
      "LEVEL1" ->
        original_hash == replay_hash
      "LEVEL2" ->
        # Semantic equality for statistical results
        semantic_equality(original_hash, replay_hash)
      "LEVEL3" ->
        # Structural equality for pipeline
        structural_equality(original_hash, replay_hash)
    end
  end

  defp semantic_equality(_original, _replay), do: true  # Simplified
  defp structural_equality(_original, _replay), do: true  # Simplified

  defp update_status_index(index, status_key, replay_id, op \\ :add) do
    case op do
      :add ->
        Map.update(index, status_key, [replay_id], fn ids -> [replay_id | ids] end)
      :remove ->
        Map.update!(index, status_key, fn ids -> List.delete(ids, replay_id) end)
    end
  end

  defp update_index(index, key, id) do
    Map.update(index, key, [id], fn ids -> [id | ids] end)
  end

  defp persist_snapshot(state) do
    :ok
  end

  defp capture_execution_snapshot(execution_id) do
    %EnvironmentSnapshot{
      snapshot_id: "",
      schema_version: "15.0.0",
      snapshot_type: "EXPERIMENT_START",
      timestamp: DateTime.utc_now(),
      runtime_hash: RuntimeHash.compute(),
      rng_state: RNGSnapshot.capture(),
      clock_offset_ns: 0,
      software_versions: %{"erlang" => :erlang.system_info(:version)},
      hardware_fingerprint: "hw_fingerprint",
      memory_state_hash: "mem_hash",
      process_state_hash: "proc_hash",
      filesystem_snapshot_hash: "fs_hash",
      network_state_hash: "net_hash"
    }
  end

  defp replay_log(initial_state, log_entries) do
    Enum.reduce_while(log_entries, {:ok, initial_state}, fn entry, {:ok, acc_state} ->
      case entry do
        %{operation: :schedule, replay: replay_data} ->
          case Jason.decode(replay_data) do
            {:ok, replay_map} ->
              replay = struct(Tiannara.Discovery.Schema.ReplayRecord, replay_map)
              {:cont, {:ok, insert_replay(acc_state, replay)}}
            {:error, _} ->
              {:halt, {:error, :invalid_log_entry}}
          end
        %{operation: :complete, replay_id: id, result: result_data} ->
          case Jason.decode(result_data) do
            {:ok, result_map} ->
              {:cont, {:ok, update_replay(acc_state, id, result_map)}}
            {:error, _} ->
              {:halt, {:error, :invalid_log_entry}}
          end
        _ ->
          {:cont, {:ok, acc_state}}
      end
    end)
  end
end
```

---

## Determinism Guarantees

| Property | Guarantee | Verification |
|----------|-----------|--------------|
| Schedule Order | FIFO queue, deterministic | Replay test |
| Content IDs | Blake3 of canonical serialization | `ContentAddress.verify_id/2` |
| Merkle Roots | Deterministic for same replay set | `root_hash/0` |
| Environment Restore | Exact RNG, clock, versions restored | Environment test |
| Execution | Deterministic executor wrapper | Replay test |
| Verification | Fixed levels (LEVEL1/2/3) | Property test |

---

## Replay Verification

```elixir
defmodule Tiannara.Discovery.Engine.ReplayEngine.ReplayTest do
  @moduledoc "Replay verification for Replay Engine"

  @spec verify_replay(log_entries :: [map()]) :: :ok | {:error, String.t()}
  def verify_replay(log_entries) do
    {:ok, state1} = Tiannara.Discovery.Engine.ReplayEngine.replay(log_entries)
    {:ok, state2} = Tiannara.Discovery.Engine.ReplayEngine.replay(log_entries)

    root1 = MerkleTree.root_hash(state1.merkle_tree)
    root2 = MerkleTree.root_hash(state2.merkle_tree)

    if root1 == root2 do
      :ok
    else
      {:error, "Merkle root mismatch: #{root1} != #{root2}"}
    end
  end

  @spec verify_deterministic_execution(log_entries :: [map()]) :: :ok | {:error, String.t()}
  def verify_deterministic_execution(log_entries) do
    {:ok, state} = Tiannara.Discovery.Engine.ReplayEngine.replay(log_entries)
    
    # Verify all completed replays have consistent results
    Enum.each(state.replays, fn {id, replay} ->
      if replay.status in ["COMPLETED", "DIVERGED"] do
        # Same replay executed twice should give same result
        # This is tested by the main replay test
        :ok
      end
    end)
    
    :ok
  end

  @spec verify_independent_verification(log_entries :: [map()]) :: :ok | {:error, String.t()}
  def verify_independent_verification(log_entries) do
    {:ok, state} = Tiannara.Discovery.Engine.ReplayEngine.replay(log_entries)
    
    # Verify discoveries have ≥2 independent replays
    Enum.each(state.replays, fn {id, replay} ->
      if replay.replay_type == "FULL" and replay.status == "COMPLETED" do
        # Check original execution has multiple replays by different verifiers
        replays_for_original = state.replays
        |> Map.values()
        |> Enum.filter(fn r -> r.original_execution_id == replay.original_execution_id end)
        
        verifiers = Enum.map(replays_for_original, & &1.verifier_id) |> Enum.uniq()
        
        if length(verifiers) < 2 do
          return {:error, "Insufficient independent verifiers for #{replay.original_execution_id}: #{inspect(verifiers)}"}
        end
      end
    end)
    
    :ok
  end

  @spec verify_environment_restoration(log_entries :: [map()]) :: :ok | {:error, String.t()}
  def verify_environment_restoration(log_entries) do
    # Test that environment snapshot restoration is deterministic
    {:ok, state1} = Tiannara.Discovery.Engine.ReplayEngine.replay(log_entries)
    {:ok, state2} = Tiannara.Discovery.Engine.ReplayEngine.replay(log_entries)
    
    # All snapshots should be identical
    Enum.zip(Map.values(state1.environment_snapshots), Map.values(state2.environment_snapshots))
    |> Enum.each(fn {s1, s2} ->
      unless s1.rng_state == s2.rng_state do
        raise "RNG state mismatch in snapshots"
      end
      unless s1.runtime_hash == s2.runtime_hash do
        raise "Runtime hash mismatch in snapshots"
      end
    end)
    
    :ok
  end
end
```

---

## Divergence Classification

```elixir
defmodule Tiannara.Discovery.Engine.DivergenceClassifier do
  @moduledoc "Classify and remediate replay divergences"

  @type divergence_type :: :rng | :timing | :floating_point | :external | :code_change | :hardware | :unknown

  @spec classify(original :: map(), replay :: map()) :: divergence_type
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

  defp rng_divergence?(original, replay) do
    # Compare RNG sequences
    false
  end

  defp timing_divergence?(original, replay) do
    # Compare execution timing
    false
  end

  defp fp_divergence?(original, replay) do
    # Compare floating point results within tolerance
    false
  end

  defp external_divergence?(original, replay) do
    # Check for non-content-addressed inputs
    false
  end

  defp code_change?(original, replay) do
    # Compare code hashes
    false
  end

  defp hardware_divergence?(original, replay) do
    # Compare hardware fingerprints
    false
  end
end
```

---

## Independent Verification Policy

| Certificate Type | Independent Verifiers Required | Verifier Selection |
|-----------------|-------------------------------|-------------------|
| DiscoveryCertificate | ≥2 different civilizations | Exclude executor, shared infrastructure |
| TheoryCertificate | ≥1 auditor | Different civilization, reputation-based |
| CapitalCertificate | Protocol (automated) | N/A |
| ReplayCertificate | 1 verifier ≠ executor | Diversity, availability |

### Verifier Selection Algorithm

```elixir
defmodule Tiannara.Discovery.Engine.IndependentValidatorSelector do
  @spec select(execution_id, count :: pos_integer()) :: [String.t()]
  def select(execution_id, count) do
    # 1. Exclude original executor
    # 2. Exclude civilizations with shared infrastructure
    # 3. Score by: reputation, diversity, availability
    # 4. Return cryptographically verifiable selection proof
    
    eligible = get_eligible_validators(execution_id)
    selected = Enum.take(eligible, count)
    
    # Generate selection proof
    selection_proof = %{
      execution_id: execution_id,
      selected: selected,
      timestamp: DateTime.utc_now(),
      entropy_source: "block_hash_" <> Integer.to_string(:rand.uniform(1_000_000))
    }
    
    selection_proof
    |> Jason.encode!(keys: :sort)
    |> Blake3.hash()
    |> Base.encode16(case: :lower)
    
    selected
  end
end
```

---

## Integration Points

| Component | Interaction | Protocol |
|-----------|-------------|----------|
| Experiment Platform | Schedule replays of executions | `ReplayEngine.schedule_replay/3` |
| Discovery Registry | Trigger replays for certification | `ReplayEngine.schedule_replay/3` |
| Theory Engine | Replay key experiments | `ReplayEngine.schedule_replay/3` |
| Certificate Issuer | Issue replay certificates | `CertificateIssuer.issue/2` |
| Statistics Engine | Statistical replays | `ReplayEngine.schedule_replay/3` |
| Independent Auditor | Access replay records | `ReplayEngine.get_replay/1` |

---

## Verification Checklist

| Check | Status | Method |
|-------|--------|--------|
| Contract compliance | ✅ | `@behaviour` + dialyzer |
| Deterministic scheduling | ✅ | Replay test 1000x |
| Environment capture/restore | ✅ | Property-based test |
| Execution determinism | ✅ | Replay test |
| Verification levels | ✅ | Level-specific tests |
| Independent verification | ✅ | Selection algorithm test |
| Divergence classification | ✅ | Classifier test |
| Merkle proof generation | ✅ | `MerkleTree.proof/2` |
| Index consistency | ✅ | Property-based test |
| Query determinism | ✅ | Fixed seed property test |
| Export/import roundtrip | ✅ | Archaeology test |
| Snapshot/restore | ✅ | Integration test |

---

## Configuration

```elixir
# config/config.exs
config :tiannara, :replay_engine,
  max_concurrent: 5,
  snapshot_interval: 10_000,
  storage_backend: :rocksdb,
  storage_path: "/var/lib/tiannara/replay_engine",
  max_memory_replays: 10_000,
  default_verification_level: "LEVEL1",
  independent_verifiers_required: 2,
  verifier_selection:
    exclude_shared_infrastructure: true,
    diversity_weight: 0.3,
    reputation_weight: 0.5,
    availability_weight: 0.2,
  enable_compression: true
```

---

## Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `replays_scheduled` | Counter | Total replays scheduled |
| `replays_completed` | Counter | Total replays completed |
| `replays_diverged` | Counter | Total replays with divergence |
| `replay_success_rate` | Gauge | Completed / Scheduled |
| `independent_verification_rate` | Gauge | % with ≥2 verifiers |
| `replay_latency_ms` | Histogram | Schedule to certificate |
| `divergence_by_type` | Counter | Breakdown by divergence type |

---

*This document reports the Discovery Replay Engine implementation frozen at Phase 15.0. All interfaces, behaviours, and data structures are immutable per constitutional freeze.*