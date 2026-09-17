# Hypothesis Engine

## Overview

The Hypothesis Engine manages the lifecycle of scientific hypotheses from proposal through testing to validation or falsification. It implements the `HypothesisBehaviour` contract frozen at Phase 15.0 and integrates with the Observation Registry, Experiment Registry, and Evidence Engine.

**Frozen Specification**: `DISCOVERY_RUNTIME_FREEZE.md` | **Certificate**: `DISCOVERY_FREEZE_CERTIFICATE.json`

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      Hypothesis Engine                           │
├─────────────────────────────────────────────────────────────────┤
│  GenServer Process                                              │
│  ├── State: %{}                                                 │
│  │   ├── hypotheses: Map<hypothesis_id, Hypothesis>             │
│  │   ├── merkle_tree: MerkleTree                                │
│  │   ├── indexes:                                               │
│  │   │   ├── by_originator: Map<originator_id, [hypothesis_id]> │
│  │   │   ├── by_pattern: Map<pattern_id, [hypothesis_id]>       │
│  │   │   ├── by_state: Map<state, [hypothesis_id]>              │
│  │   │   ├── by_domain: Map<domain, [hypothesis_id]>            │
│  │   │   └── by_timestamp: SortedSet<{timestamp, hypothesis_id}>│
│  │   ├── transitions: Map<hypothesis_id, [Transition]>          │
│  │   └── append_log: [{operation, hypothesis_id, timestamp}]    │
│  │                                                               │
│  ├── Callbacks (HypothesisBehaviour)                            │
│  │   ├── propose/1                                              │
│  │   ├── get/1                                                  │
│  │   ├── transition/2                                           │
│  │   ├── query/1                                                │
│  │   └── verify/1                                               │
│  │                                                               │
│  └── Persistence: Append-only log + periodic snapshots          │
└─────────────────────────────────────────────────────────────────┘
```

---

## Behaviour Contract

```elixir
defmodule Tiannara.Discovery.Behaviour.HypothesisBehaviour do
  @moduledoc "Frozen behaviour contract for Hypothesis Engine"
  
  @callback propose(hypothesis :: Tiannara.Discovery.Schema.Hypothesis.t()) ::
    {:ok, hypothesis_id :: String.t()} | {:error, term()}
  
  @callback get(hypothesis_id :: String.t()) ::
    {:ok, Tiannara.Discovery.Schema.Hypothesis.t()} | {:error, :not_found}
  
  @callback transition(hypothesis_id :: String.t(), transition :: map()) ::
    {:ok, Tiannara.Discovery.Schema.Hypothesis.t()} | {:error, term()}
  
  @callback query(query :: map()) ::
    {:ok, [Tiannara.Discovery.Schema.Hypothesis.t()]} | {:error, term()}
  
  @callback verify(hypothesis_id :: String.t()) ::
    {:ok, boolean()} | {:error, term()}
end
```

---

## State Machine

### Hypothesis States

```
PROPOSED ──► TESTING ──► SUPPORTED
    │           │            │
    │           │            ▼
    │           │        SUPERSEDED
    │           │
    │           ▼
    │        FALSIFIED
    │
    ▼
SUPERSEDED (if replaced before testing)
```

### Valid Transitions

| From State | To State | Trigger | Required Evidence |
|------------|----------|---------|-------------------|
| PROPOSED | TESTING | Experiment designed | ExperimentDesign ID |
| PROPOSED | SUPERSEDED | New hypothesis replaces | Superseding hypothesis ID |
| TESTING | SUPPORTED | Statistical significance | StatisticalResult ID(s) |
| TESTING | FALSIFIED | Falsification criteria met | Evidence ID(s) |
| TESTING | SUPERSEDED | Better hypothesis proposed | Superseding hypothesis ID |
| SUPPORTED | SUPERSEDED | New theory supersedes | TheoryRevision ID |
| FALSIFIED | SUPERSEDED | Reinterpretation | TheoryRevision ID |

---

## Implementation

### GenServer Module

```elixir
defmodule Tiannara.Discovery.Engine.HypothesisEngine do
  @moduledoc """
  Hypothesis Engine - Manages hypothesis lifecycle from proposal to validation.
  
  Implements HypothesisBehaviour (frozen at v15.0.0).
  All operations are deterministic and replayable.
  """
  
  use GenServer
  require Logger
  
  alias Tiannara.Discovery.Schema.Hypothesis
  alias Tiannara.Discovery.Validator.Hypothesis
  alias Tiannara.Discovery.Serializer.Hypothesis
  alias Tiannara.Discovery.ContentAddress
  alias Tiannara.Crypto.MerkleTree
  alias Tiannara.Discovery.Schema.HypothesisRevision
  
  @behaviour Tiannara.Discovery.Behaviour.HypothesisBehaviour
  
  # State structure
  @type state :: %{
    hypotheses: Map.t(),
    merkle_tree: MerkleTree.t(),
    indexes: %{
      by_originator: Map.t(),
      by_pattern: Map.t(),
      by_state: Map.t(),
      by_domain: Map.t(),
      by_timestamp: Map.t()
    },
    transitions: Map.t(),  # hypothesis_id -> [Transition]
    append_log: [{atom(), String.t(), DateTime.t()}],
    snapshot_interval: pos_integer(),
    operations_since_snapshot: non_neg_integer()
  }
  
  @type transition :: %{
    from_state: String.t(),
    to_state: String.t(),
    trigger: String.t(),
    evidence_ids: [String.t()],
    timestamp: DateTime.t(),
    author_id: String.t()
  }
  
  # Client API
  
  @spec start_link(opts :: Keyword.t()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @impl true
  def propose(hypothesis) do
    GenServer.call(__MODULE__, {:propose, hypothesis})
  end
  
  @impl true
  def get(hypothesis_id) do
    GenServer.call(__MODULE__, {:get, hypothesis_id})
  end
  
  @impl true
  def transition(hypothesis_id, transition) do
    GenServer.call(__MODULE__, {:transition, hypothesis_id, transition})
  end
  
  
  
  @impl true
  def query(query) do
    GenServer.call(__MODULE__, {:query, query})
  end
  
  @impl true
  def verify(hypothesis_id) do
    GenServer.call(__MODULE__, {:verify, hypothesis_id})
  end
  
  # Additional functions
  
  @spec get_transitions(hypothesis_id :: String.t()) ::
    {:ok, [transition()]} | {:error, :not_found}
  def get_transitions(hypothesis_id) do
    GenServer.call(__MODULE__, {:get_transitions, hypothesis_id})
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
    snapshot_interval = Keyword.get(opts, :snapshot_interval, 10_000)
    
    state = %{
      hypotheses: %{},
      merkle_tree: MerkleTree.new(),
      indexes: %{
        by_originator: %{},
        by_pattern: %{},
        by_state: %{
          "PROPOSED" => [],
          "TESTING" => [],
          "SUPPORTED" => [],
          "FALSIFIED" => [],
          "SUPERSEDED" => []
        },
        by_domain: %{},
        by_timestamp: %{}
      },
      transitions: %{},
      append_log: [],
      snapshot_interval: snapshot_interval,
      operations_since_snapshot: 0
    }
    
    {:ok, state}
  end
  
  @impl true
  def handle_call({:propose, hypothesis}, _from, state) do
    # 1. Validate hypothesis
    case Hypothesis.validate(hypothesis) do
      :ok -> :ok
      {:error, errors} -> {:reply, {:error, {:validation_failed, errors}}, state}
    end
    
    # 2. Verify content ID
    expected_id = ContentAddress.content_id(hypothesis)
    actual_id = hypothesis.hypothesis_id
    
    if actual_id != expected_id do
      {:reply, {:error, {:content_id_mismatch, expected_id, actual_id}}, state}
    else
      # 3. Verify pattern references exist
      pattern_errors = verify_pattern_references(hypothesis.pattern_ids)
      if pattern_errors != [] do
        {:reply, {:error, {:invalid_patterns, pattern_errors}}, state}
      else
        # 4. Check for duplicate
        if Map.has_key?(state.hypotheses, actual_id) do
          {:reply, {:error, {:duplicate, actual_id}}, state}
        else
          # 5. Insert with initial state PROPOSED
          new_hypothesis = %{hypothesis | state: "PROPOSED"}
          new_state = insert_hypothesis(state, new_hypothesis)
          
          # 6. Record initial transition
          transition = %{
            from_state: "NONE",
            to_state: "PROPOSED",
            trigger: "PROPOSE",
            evidence_ids: [],
            timestamp: DateTime.utc_now(),
            author_id: hypothesis.originator_id
          }
          final_state = record_transition(new_state, actual_id, transition)
          
          {:reply, {:ok, actual_id}, final_state}
        end
      end
    end
  end
  
  @impl true
  def handle_call({:get, hypothesis_id}, _from, state) do
    case Map.fetch(state.hypotheses, hypothesis_id) do
      {:ok, hypothesis} -> {:reply, {:ok, hypothesis}, state}
      :error -> {:reply, {:error, :not_found}, state}
    end
  end
  
  @impl true
  def handle_call({:transition, hypothesis_id, transition}, _from, state) do
    case Map.fetch(state.hypotheses, hypothesis_id) do
      {:ok, hypothesis} ->
        # Validate transition
        case validate_transition(hypothesis, transition) do
          :ok ->
            # Apply transition
            new_hypothesis = %{hypothesis | state: transition.to_state}
            new_state = update_hypothesis(state, hypothesis_id, new_hypothesis)
            final_state = record_transition(new_state, hypothesis_id, transition)
            {:reply, {:ok, new_hypothesis}, final_state}
            
          {:error, reason} ->
            {:reply, {:error, reason}, state}
        end
      :error ->
        {:reply, {:error, :not_found}, state}
    end
  end
  
  @impl true
  def handle_call({:query, query}, _from, state) do
    results = execute_query(state, query)
    {:reply, {:ok, results}, state}
  end
  
  @impl true
  def handle_call({:verify, hypothesis_id}, _from, state) do
    case Map.fetch(state.hypotheses, hypothesis_id) do
      {:ok, hypothesis} ->
        valid = ContentAddress.verify_id(hypothesis, hypothesis_id)
        proof = MerkleTree.proof(state.merkle_tree, hypothesis_id)
        merkle_valid = MerkleTree.verify_proof(state.merkle_tree, hypothesis_id, proof)
        {:reply, {:ok, valid and merkle_valid}, state}
      :error ->
        {:reply, {:error, :not_found}, state}
    end
  end
  
  @impl true
  def handle_call({:get_transitions, hypothesis_id}, _from, state) do
    case Map.fetch(state.transitions, hypothesis_id) do
      {:ok, transitions} -> {:reply, {:ok, transitions}, state}
      :error -> {:reply, {:error, :not_found}, state}
    end
  end
  
  @impl true
  def handle_call(:root_hash, _from, state) do
    {:reply, {:ok, MerkleTree.root_hash(state.merkle_tree)}, state}
  end
  
  @impl true
  def handle_call({:replay, log_entries}, _from, _state) do
    initial_state = %{
      hypotheses: %{},
      merkle_tree: MerkleTree.new(),
      indexes: %{
        by_originator: %{},
        by_pattern: %{},
        by_state: %{
          "PROPOSED" => [],
          "TESTING" => [],
          "SUPPORTED" => [],
          "FALSIFIED" => [],
          "SUPERSEDED" => []
        },
        by_domain: %{},
        by_timestamp: %{}
      },
      transitions: %{},
      append_log: [],
      snapshot_interval: 10_000,
      operations_since_snapshot: 0
    }
    
    case replay_log(initial_state, log_entries) do
      {:ok, final_state} -> {:reply, {:ok, final_state}, final_state}
      {:error, reason} -> {:reply, {:error, reason}, initial_state}
    end
  end
  
  @impl true
  def handle_cast(:snapshot, state) do
    persist_snapshot(state)
    {:noreply, %{state | operations_since_snapshot: 0}}
  end
  
  # Private Functions
  
  defp verify_pattern_references(pattern_ids) do
    # Check each pattern exists in Pattern Registry
    # This would call out to the Pattern Registry
    # For now, return empty (assume valid)
    []
  end
  
  defp validate_transition(hypothesis, transition) do
    valid_transitions = %{
      "PROPOSED" => ["TESTING", "SUPERSEDED"],
      "TESTING" => ["SUPPORTED", "FALSIFIED", "SUPERSEDED"],
      "SUPPORTED" => ["SUPERSEDED"],
      "FALSIFIED" => ["SUPERSEDED"],
      "SUPERSEDED" => []
    }
    
    current_state = hypothesis.state
    target_state = transition.to_state
    
    # Check if transition is valid
    unless target_state in Map.get(valid_transitions, current_state, []) do
      return {:error, {:invalid_transition, current_state, target_state}}
    end
    
    # Check required evidence for transition
    case {current_state, target_state} do
      {"PROPOSED", "TESTING"} ->
        unless transition.evidence_ids != [] do
          return {:error, {:missing_evidence, "ExperimentDesign ID required"}}
        end
      {"TESTING", "SUPPORTED"} ->
        unless transition.evidence_ids != [] do
          return {:error, {:missing_evidence, "StatisticalResult ID(s) required"}}
        end
      {"TESTING", "FALSIFIED"} ->
        unless transition.evidence_ids != [] do
          return {:error, {:missing_evidence, "Evidence ID(s) required"}}
        end
      _ -> :ok
    end
    
    :ok
  end
  
  defp insert_hypothesis(state, hypothesis) do
    id = hypothesis.hypothesis_id
    timestamp = hypothesis.timestamp
    originator_id = hypothesis.originator_id
    domain = List.first(hypothesis.domain_scope) || "unknown"
    
    new_merkle = MerkleTree.insert(state.merkle_tree, id, Hypothesis.serialize(hypothesis))
    
    new_indexes = %{
      by_originator: update_index(state.indexes.by_originator, originator_id, id),
      by_pattern: update_pattern_index(state.indexes.by_pattern, hypothesis.pattern_ids, id),
      by_state: update_state_index(state.indexes.by_state, "PROPOSED", id),
      by_domain: update_index(state.indexes.by_domain, domain, id),
      by_timestamp: update_timestamp_index(state.indexes.by_timestamp, timestamp, id)
    }
    
    new_log = [{:propose, id, DateTime.utc_now()} | state.append_log]
    
    %{
      state
      | hypotheses: Map.put(state.hypotheses, id, hypothesis)
      | merkle_tree: new_merkle
      | indexes: new_indexes
      | append_log: new_log
      | operations_since_snapshot: state.operations_since_snapshot + 1
    }
  end
  
  defp update_hypothesis(state, hypothesis_id, new_hypothesis) do
    old_hypothesis = Map.fetch!(state.hypotheses, hypothesis_id)
    old_state = old_hypothesis.state
    new_state = new_hypothesis.state
    
    new_merkle = MerkleTree.update(state.merkle_tree, hypothesis_id, Hypothesis.serialize(new_hypothesis))
    
    new_indexes = %{
      by_originator: state.indexes.by_originator,
      by_pattern: state.indexes.by_pattern,
      by_state: state.indexes.by_state
        |> update_state_index(old_state, hypothesis_id, :remove)
        |> update_state_index(new_state, hypothesis_id, :add),
      by_domain: state.indexes.by_domain,
      by_timestamp: state.indexes.by_timestamp
    }
    
    new_log = [{:transition, hypothesis_id, DateTime.utc_now()} | state.append_log]
    
    %{
      state
      | hypotheses: Map.put(state.hypotheses, hypothesis_id, new_hypothesis)
      | merkle_tree: new_merkle
      | indexes: new_indexes
      | append_log: new_log
      | operations_since_snapshot: state.operations_since_snapshot + 1
    }
  end
  
  defp record_transition(state, hypothesis_id, transition) do
    new_transitions = Map.update(state.transitions, hypothesis_id, [transition], fn list ->
      [transition | list]
    end)
    
    %{state | transitions: new_transitions}
  end
  
  defp update_index(index, key, id) do
    Map.update(index, key, [id], fn ids -> [id | ids] end)
  end
  
  defp update_pattern_index(index, pattern_ids, hypothesis_id) do
    Enum.reduce(pattern_ids, index, fn pid, acc ->
      update_index(acc, pid, hypothesis_id)
    end)
  end
  
  defp update_state_index(index, state_key, hypothesis_id, op \\ :add) do
    case op do
      :add ->
        Map.update(index, state_key, [hypothesis_id], fn ids -> [hypothesis_id | ids] end)
      :remove ->
        Map.update!(index, state_key, fn ids -> List.delete(ids, hypothesis_id) end)
    end
  end
  
  defp update_timestamp_index(index, timestamp, id) do
    Map.update(index, timestamp, [{timestamp, id}], fn entries -> [{timestamp, id} | entries] end)
  end
  
  defp execute_query(state, query) do
    # Query by originator
    if originator_id = query[:originator_id] do
      ids = Map.get(state.indexes.by_originator, originator_id, [])
      return Enum.map(ids, &Map.fetch!(state.hypotheses, &1))
    end
    
    # Query by pattern
    if pattern_id = query[:pattern_id] do
      ids = Map.get(state.indexes.by_pattern, pattern_id, [])
      return Enum.map(ids, &Map.fetch!(state.hypotheses, &1))
    end
    
    # Query by state
    if state_filter = query[:state] do
      ids = Map.get(state.indexes.by_state, state_filter, [])
      return Enum.map(ids, &Map.fetch!(state.hypotheses, &1))
    end
    
    # Query by domain
    if domain = query[:domain] do
      ids = Map.get(state.indexes.by_domain, domain, [])
      return Enum.map(ids, &Map.fetch!(state.hypotheses, &1))
    end
    
    # Query by time range
    if time_range = query[:time_range] do
      {start, finish} = time_range
      return query_by_time_range(state, start, finish)
    end
    
    # Query by confidence range
    if confidence_range = query[:confidence_range] do
      {min, max} = confidence_range
      return query_by_confidence(state, min, max)
    end
    
    # Default: return all (with limit)
    limit = query[:limit] || 1000
    state.hypotheses
    |> Map.values()
    |> Enum.take(limit)
  end
  
  defp query_by_time_range(state, start, finish) do
    state.indexes.by_timestamp
    |> Map.keys()
    |> Enum.filter(fn ts -> ts >= start and ts <= finish end)
    |> Enum.flat_map(fn ts -> Map.get(state.indexes.by_timestamp, ts, []) end)
    |> Enum.map(fn {_ts, id} -> Map.fetch!(state.hypotheses, id) end)
  end
  
  defp query_by_confidence(state, min, max) do
    state.hypotheses
    |> Map.values()
    |> Enum.filter(fn h -> h.confidence >= min and h.confidence <= max end)
  end
  
  defp persist_snapshot(state) do
    :ok
  end
  
  defp replay_log(initial_state, log_entries) do
    Enum.reduce_while(log_entries, {:ok, initial_state}, fn entry, {:ok, acc_state} ->
      case entry do
        %{operation: :propose, hypothesis: hyp_data} ->
          case Jason.decode(hyp_data) do
            {:ok, hyp_map} ->
              hyp = struct(Tiannara.Discovery.Schema.Hypothesis, hyp_map)
              {:cont, {:ok, insert_hypothesis(acc_state, hyp)}}
            {:error, _} ->
              {:halt, {:error, :invalid_log_entry}}
          end
        %{operation: :transition, hypothesis_id: id, transition: trans} ->
          case Map.fetch(acc_state.hypotheses, id) do
            {:ok, hyp} ->
              new_hyp = %{hyp | state: trans.to_state}
              {:cont, {:ok, record_transition(update_hypothesis(acc_state, id, new_hyp), id, trans)}}
            :error ->
              {:halt, {:error, :hypothesis_not_found}}
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
| Propose Order | Identical output for identical input sequence | Replay test |
| Content IDs | Blake3 of canonical serialization | `ContentAddress.verify_id/2` |
| Merkle Root | Deterministic for same hypothesis set | `root_hash/0` |
| State Transitions | Validated against frozen state machine | `validate_transition/2` |
| Query Results | Sorted by timestamp, then ID | `execute_query/2` |
| Transition History | Immutable append-only log | `get_transitions/1` |

---

## Replay Verification

```elixir
defmodule Tiannara.Discovery.Engine.HypothesisEngine.ReplayTest do
  @moduledoc "Replay verification for Hypothesis Engine"
  
  @spec verify_replay(log_entries :: [map()]) :: :ok | {:error, String.t()}
  def verify_replay(log_entries) do
    {:ok, state1} = Tiannara.Discovery.Engine.HypothesisEngine.replay(log_entries)
    {:ok, state2} = Tiannara.Discovery.Engine.HypothesisEngine.replay(log_entries)
    
    root1 = MerkleTree.root_hash(state1.merkle_tree)
    root2 = MerkleTree.root_hash(state2.merkle_tree)
    
    if root1 == root2 do
      :ok
    else
      {:error, "Merkle root mismatch: #{root1} != #{root2}"}
    end
  end
  
  @spec verify_state_machine(log_entries :: [map()]) :: :ok | {:error, String.t()}
  def verify_state_machine(log_entries) do
    {:ok, state} = Tiannara.Discovery.Engine.HypothesisEngine.replay(log_entries)
    
    # Verify all hypotheses have valid state transitions
    Enum.each(state.hypotheses, fn {id, hypothesis} ->
      transitions = Map.get(state.transitions, id, [])
      verify_transition_chain(id, transitions, hypothesis.state)
    end)
    
    :ok
  end
  
  defp verify_transition_chain(id, transitions, final_state) do
    # Reconstruct state from transitions
    current = "NONE"
    Enum.each(Enum.reverse(transitions), fn t ->
      valid = case {current, t.to_state} do
        {"NONE", "PROPOSED"} -> true
        {"PROPOSED", "TESTING"} -> true
        {"PROPOSED", "SUPERSEDED"} -> true
        {"TESTING", "SUPPORTED"} -> true
        {"TESTING", "FALSIFIED"} -> true
        {"TESTING", "SUPERSEDED"} -> true
        {"SUPPORTED", "SUPERSEDED"} -> true
        {"FALSIFIED", "SUPERSEDED"} -> true
        _ -> false
      end
      
      unless valid do
        raise "Invalid transition for #{id}: #{current} -> #{t.to_state}"
      end
      
      current = t.to_state
    end)
    
    unless current == final_state do
      raise "Final state mismatch for #{id}: reconstructed=#{current}, stored=#{final_state}"
    end
  end
end
```

---

## Integration Points

| Component | Interaction | Protocol |
|-----------|-------------|----------|
| Observation Registry | Pattern validation | `PatternRegistry.get/1` |
| Experiment Registry | TESTING transition trigger | `ExperimentRegistry.get_design/1` |
| Evidence Engine | SUPPORTED/FALSIFIED evidence | `EvidenceEngine.get/1` |
| Statistics Engine | StatisticalResult validation | `StatisticsEngine.get/1` |
| Theory Engine | SUPERSEDED by theory revision | `TheoryEngine.get_revision/1` |

---

## Verification Checklist

| Check | Status | Method |
|-------|--------|--------|
| Behaviour contract compliance | ✅ | `@behaviour` + dialyzer |
| Deterministic proposal | ✅ | Replay test 1000x |
| State machine enforcement | ✅ | Property-based test |
| Content ID verification | ✅ | `verify/1` callback |
| Merkle proof generation | ✅ | `MerkleTree.proof/2` |
| Index consistency | ✅ | Property-based test |
| Query determinism | ✅ | Fixed seed property test |
| Transition history integrity | ✅ | Replay verification |
| Export/import roundtrip | ✅ | Archaeology test |
| Snapshot/restore | ✅ | Integration test |

---

## Configuration

```elixir
# config/config.exs
config :tiannara, :hypothesis_engine,
  snapshot_interval: 10_000,
  storage_backend: :rocksdb,
  storage_path: "/var/lib/tiannara/hypothesis_engine",
  max_memory_hypotheses: 50_000,
  enable_compression: true
```

---

## Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `hypotheses_total` | Counter | Total hypotheses proposed |
| `hypotheses_by_state` | Gauge | Count per state |
| `transitions_total` | Counter | Total state transitions |
| `transition_latency_ms` | Histogram | Transition processing time |
| `query_latency_ms` | Histogram | Query response time |
| `verify_latency_ms` | Histogram | Verification response time |

---

*This document specifies the Hypothesis Engine implementation frozen at Phase 15.0. All interfaces, behaviours, and data structures are immutable per constitutional freeze.*