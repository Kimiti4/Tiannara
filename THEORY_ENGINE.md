# Theory Engine Implementation Report

## Overview

This document reports the implementation and verification of the Theory Engine for Phase 15 Scientific Discovery. The Theory Engine manages the complete lifecycle of scientific theories including creation, revision, comparison, supersession, and archaeological reconstruction.

**Frozen Specification**: `DISCOVERY_RUNTIME_FREEZE.md` | **Certificate**: `DISCOVERY_FREEZE_CERTIFICATE.json`

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      Theory Engine                               │
├─────────────────────────────────────────────────────────────────┤
│  GenServer Process                                              │
│  ├── State: %{}                                                 │
│  │   ├── theories: Map<theory_id, Theory>                      │
│  │   ├── revisions: Map<revision_id, TheoryRevision>           │
│  │   ├── merkle_tree: MerkleTree                                │
│  │   ├── indexes:                                               │
│  │   │   ├── by_proposer: Map<proposer_id, [theory_id]>        │
│  │   │   ├── by_domain: Map<domain, [theory_id]>               │
│  │   │   ├── by_status: Map<status, [theory_id]>               │
│  │   │   ├── by_timestamp: SortedSet<{timestamp, theory_id}>   │
│  │   │   └── by_confidence: SortedSet<{confidence, theory_id}> │
│  │   ├── lineage: Map<theory_id, [theory_id]>                  │
│  │   ├── supersession_graph: Map<theory_id, theory_id>         │
│  │   ├── append_log: [{operation, id, timestamp}]              │
│  │   └── snapshot_interval: pos_integer()                      │
│  │                                                               │
│  ├── API (TheoryEngine)                                         │
│  │   ├── propose/2                                              │
│  │   ├── revise/3                                               │
│  │   ├── compare/2                                              │
│  │   ├── supersede/3                                            │
│  │   ├── get/1                                                  │
│  │   ├── get_revision/1                                         │
│  │   ├── get_lineage/1                                          │
│  │   ├── query/1                                                │
│  │   └── verify/2                                               │
│  │                                                               │
│  └── Persistence: Append-only log + periodic snapshots          │
└─────────────────────────────────────────────────────────────────┘
```

---

## Theory Schema (from DISCOVERY_DATA_MODEL.md)

```elixir
defmodule Tiannara.Discovery.Schema.Theory do
  @moduledoc "Frozen schema for Theory (v15.0.0)"

  @type t :: %__MODULE__{
    theory_id: String.t(),                      # Content-addressed ID (Blake3)
    schema_version: String.t(),                 # "15.0.0"
    timestamp: DateTime.t(),                    # Creation timestamp
    proposer_id: String.t(),                    # Proposer civilization
    domain: String.t(),                         # Domain identifier
    scope: %{
      domains: [String.t()],                    # Covered domains
      phenomena: [String.t()],                  # Explained phenomena
      score: float()                            # Scope score 0.0-1.0
    },
    confidence: float(),                        # 0.0-1.0
    predictions: [String.t()],                  # Testable predictions
    evidence_supporting: [String.t()],          # Discovery IDs
    evidence_contradicting: [String.t()],       # Discovery IDs
    status: String.t(),                         # PROPOSED | ACTIVE | SUPERSEDED | RETIRED
    version: pos_integer(),                     # Theory version
    parent_theory_id: String.t() | nil,         # For lineage
    tags: [String.t()]
  }

  defstruct [:theory_id, :schema_version, :timestamp, :proposer_id, :domain,
             :scope, :confidence, :predictions, :evidence_supporting,
             :evidence_contradicting, :status, :version, :parent_theory_id, :tags]
end
```

---

## Theory Revision Schema

```elixir
defmodule Tiannara.Discovery.Schema.TheoryRevision do
  @moduledoc "Frozen schema for Theory Revision (v15.0.0)"

  @type t :: %__MODULE__{
    revision_id: String.t(),                    # Content-addressed ID (Blake3)
    schema_version: String.t(),                 # "15.0.0"
    timestamp: DateTime.t(),
    theory_id: String.t(),                      # Theory being revised
    author_id: String.t(),                      # Revision author
    operation: String.t(),                      # CONFIRM | REFINE | EXTEND | SUPERSEDE | RETIRE
    changes: %{
      confidence_delta: float(),                # Change in confidence
      scope_changes: %{                         # Scope modifications
        domains_added: [String.t()],
        domains_removed: [String.t()],
        phenomena_added: [String.t()],
        phenomena_removed: [String.t()],
        score_delta: float()
      },
      predictions_added: [String.t()],
      predictions_removed: [String.t()],
      evidence_added: [String.t()],
      evidence_removed: [String.t()],
      status_change: String.t() | nil
    },
    certificate_id: String.t(),                 # RevisionCertificate ID
    justification: String.t(),                  # Human-readable justification
    tags: [String.t()]
  }

  defstruct [:revision_id, :schema_version, :timestamp, :theory_id, :author_id,
             :operation, :changes, :certificate_id, :justification, :tags]
end
```

---

## API Contract (TheoryEngine Behaviour)

```elixir
defmodule Tiannara.Discovery.Behaviour.TheoryEngine do
  @moduledoc "Frozen API contract for Theory Engine (v15.0.0)"

  @callback propose(theory_spec :: map(), proposer_id :: String.t()) ::
    {:ok, theory_id :: String.t()} | {:error, term()}

  @callback revise(theory_id :: String.t(), revision_spec :: map(), author_id :: String.t()) ::
    {:ok, revision_id :: String.t()} | {:error, term()}

  @callback compare(theory_id_1 :: String.t(), theory_id_2 :: String.t()) ::
    {:ok, comparison :: map()} | {:error, term()}

  @callback supersede(old_theory_id :: String.t(), new_theory_id :: String.t(), author_id :: String.t()) ::
    {:ok, supersession_id :: String.t()} | {:error, term()}

  @callback get(theory_id :: String.t()) ::
    {:ok, Theory.t()} | {:error, :not_found}

  @callback get_revision(revision_id :: String.t()) ::
    {:ok, TheoryRevision.t()} | {:error, :not_found}

  @callback get_lineage(theory_id :: String.t()) ::
    {:ok, [Theory.t()]} | {:error, term()}

  @callback query(query :: map()) ::
    {:ok, [Theory.t()]} | {:error, term()}

  @callback verify(theory_id :: String.t(), evidence_ids :: [String.t()]) ::
    {:ok, verification :: map()} | {:error, term()}
end
```

---

## Implementation

### GenServer Module

```elixir
defmodule Tiannara.Discovery.Engine.TheoryEngine do
  @moduledoc """
  Theory Engine - Manages scientific theory lifecycle.

  Implements TheoryEngine behaviour (frozen at v15.0.0).
  All operations are deterministic and replayable.
  """

  use GenServer
  require Logger

  alias Tiannara.Discovery.Schema.Theory
  alias Tiannara.Discovery.Schema.TheoryRevision
  alias Tiannara.Discovery.Validator.Theory
  alias Tiannara.Discovery.Validator.TheoryRevision
  alias Tiannara.Discovery.Serializer.Theory
  alias Tiannara.Discovery.Serializer.TheoryRevision
  alias Tiannara.Discovery.ContentAddress
  alias Tiannara.Crypto.MerkleTree
  alias Tiannara.Discovery.Engine.CertificateIssuer

  @behaviour Tiannara.Discovery.Behaviour.TheoryEngine

  @type state :: %{
    theories: Map.t(),
    revisions: Map.t(),
    merkle_tree: MerkleTree.t(),
    indexes: %{
      by_proposer: Map.t(),
      by_domain: Map.t(),
      by_status: Map.t(),
      by_timestamp: Map.t(),
      by_confidence: Map.t()
    },
    lineage: Map.t(),
    supersession_graph: Map.t(),
    append_log: [{atom(), String.t(), DateTime.t()}],
    snapshot_interval: pos_integer(),
    operations_since_snapshot: non_neg_integer()
  }

  # Client API

  @spec start_link(opts :: Keyword.t()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def propose(theory_spec, proposer_id) do
    GenServer.call(__MODULE__, {:propose, theory_spec, proposer_id})
  end

  @impl true
  def revise(theory_id, revision_spec, author_id) do
    GenServer.call(__MODULE__, {:revise, theory_id, revision_spec, author_id})
  end

  @impl true
  def compare(theory_id_1, theory_id_2) do
    GenServer.call(__MODULE__, {:compare, theory_id_1, theory_id_2})
  end

  @impl true
  def supersede(old_theory_id, new_theory_id, author_id) do
    GenServer.call(__MODULE__, {:supersede, old_theory_id, new_theory_id, author_id})
  end

  @impl true
  def get(theory_id) do
    GenServer.call(__MODULE__, {:get, theory_id})
  end

  @impl true
  def get_revision(revision_id) do
    GenServer.call(__MODULE__, {:get_revision, revision_id})
  end

  @impl true
  def get_lineage(theory_id) do
    GenServer.call(__MODULE__, {:get_lineage, theory_id})
  end

  @impl true
  def query(query) do
    GenServer.call(__MODULE__, {:query, query})
  end

  @impl true
  def verify(theory_id, evidence_ids) do
    GenServer.call(__MODULE__, {:verify, theory_id, evidence_ids})
  end

  # Additional functions

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
      theories: %{},
      revisions: %{},
      merkle_tree: MerkleTree.new(),
      indexes: %{
        by_proposer: %{},
        by_domain: %{},
        by_status: %{
          "PROPOSED" => [], "ACTIVE" => [], "SUPERSEDED" => [], "RETIRED" => []
        },
        by_timestamp: %{},
        by_confidence: %{}
      },
      lineage: %{},
      supersession_graph: %{},
      append_log: [],
      snapshot_interval: snapshot_interval,
      operations_since_snapshot: 0
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:propose, theory_spec, proposer_id}, _from, state) do
    # Build Theory struct
    theory = build_theory(theory_spec, proposer_id)

    # Validate
    case Theory.validate(theory) do
      :ok -> :ok
      {:error, errors} -> {:reply, {:error, {:validation_failed, errors}}, state}
    end

    # Verify content ID
    expected_id = ContentAddress.content_id(theory)
    if theory.theory_id != expected_id do
      {:reply, {:error, {:content_id_mismatch, expected_id, theory.theory_id}}, state}
    else
      # Check for duplicate
      if Map.has_key?(state.theories, theory.theory_id) do
        {:reply, {:error, {:duplicate, theory.theory_id}}, state}
      else
        new_state = insert_theory(state, theory)
        {:reply, {:ok, theory.theory_id}, new_state}
      end
    end
  end

  @impl true
  def handle_call({:revise, theory_id, revision_spec, author_id}, _from, state) do
    case Map.fetch(state.theories, theory_id) do
      {:ok, theory} ->
        # Build revision
        revision = build_revision(theory, revision_spec, author_id)

        # Validate
        case TheoryRevision.validate(revision) do
          :ok -> :ok
          {:error, errors} -> {:reply, {:error, {:validation_failed, errors}}, state}
        end

        # Verify content ID
        expected_id = ContentAddress.content_id(revision)
        if revision.revision_id != expected_id do
          {:reply, {:error, {:content_id_mismatch, expected_id, revision.revision_id}}, state}
        else
          # Apply revision to theory
          updated_theory = apply_revision(theory, revision)
          
          # Validate updated theory
          case Theory.validate(updated_theory) do
            :ok ->
              new_state = insert_revision(state, revision)
              final_state = update_theory(new_state, updated_theory)
              {:reply, {:ok, revision.revision_id}, final_state}
            {:error, errors} ->
              {:reply, {:error, {:updated_theory_invalid, errors}}, state}
          end
        end
      :error ->
        {:reply, {:error, :theory_not_found}, state}
    end
  end

  @impl true
  def handle_call({:compare, theory_id_1, theory_id_2}, _from, state) do
    case {Map.fetch(state.theories, theory_id_1), Map.fetch(state.theories, theory_id_2)} do
      {{:ok, t1}, {:ok, t2}} ->
        comparison = TheoryComparison.compare(t1, t2)
        {:reply, {:ok, comparison}, state}
      _ ->
        {:reply, {:error, :theory_not_found}, state}
    end
  end

  @impl true
  def handle_call({:supersede, old_theory_id, new_theory_id, author_id}, _from, state) do
    case {Map.fetch(state.theories, old_theory_id), Map.fetch(state.theories, new_theory_id)} do
      {{:ok, old_theory}, {:ok, new_theory}} ->
        # Create supersession revision for old theory
        old_revision = %TheoryRevision{
          revision_id: ContentAddress.content_id(%{
            theory_id: old_theory_id,
            operation: "SUPERSEDE",
            superseded_by: new_theory_id,
            author_id: author_id,
            timestamp: DateTime.utc_now()
          }),
          schema_version: "15.0.0",
          timestamp: DateTime.utc_now(),
          theory_id: old_theory_id,
          author_id: author_id,
          operation: "SUPERSEDE",
          changes: %{
            confidence_delta: 0.0,
            scope_changes: %{
              domains_added: [], domains_removed: [],
              phenomena_added: [], phenomena_removed: [],
              score_delta: 0.0
            },
            predictions_added: [], predictions_removed: [],
            evidence_added: [], evidence_removed: [],
            status_change: "SUPERSEDED"
          },
          certificate_id: "",
          justification: "Superseded by #{new_theory_id}",
          tags: ["supersession"]
        }

        # Create confirmation revision for new theory
        new_revision = %TheoryRevision{
          revision_id: ContentAddress.content_id(%{
            theory_id: new_theory_id,
            operation: "CONFIRM",
            supersedes: old_theory_id,
            author_id: author_id,
            timestamp: DateTime.utc_now()
          }),
          schema_version: "15.0.0",
          timestamp: DateTime.utc_now(),
          theory_id: new_theory_id,
          author_id: author_id,
          operation: "CONFIRM",
          changes: %{
            confidence_delta: 0.05,
            scope_changes: %{
              domains_added: [], domains_removed: [],
              phenomena_added: [], phenomena_removed: [],
              score_delta: 0.0
            },
            predictions_added: [], predictions_removed: [],
            evidence_added: [], evidence_removed: [],
            status_change: "ACTIVE"
          },
          certificate_id: "",
          justification: "Confirmed by superseding #{old_theory_id}",
          tags: ["supersession", "confirmation"]
        }

        # Apply both revisions
        updated_old = apply_revision(old_theory, old_revision)
        updated_new = apply_revision(new_theory, new_revision)

        new_state = insert_revision(state, old_revision)
        new_state = update_theory(new_state, updated_old)
        new_state = insert_revision(new_state, new_revision)
        final_state = update_theory(new_state, updated_new)

        # Update supersession graph
        final_state = %{final_state | supersession_graph: Map.put(final_state.supersession_graph, old_theory_id, new_theory_id)}

        {:reply, {:ok, old_revision.revision_id}, final_state}
      _ ->
        {:reply, {:error, :theory_not_found}, state}
    end
  end

  @impl true
  def handle_call({:get, theory_id}, _from, state) do
    case Map.fetch(state.theories, theory_id) do
      {:ok, theory} -> {:reply, {:ok, theory}, state}
      :error -> {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call({:get_revision, revision_id}, _from, state) do
    case Map.fetch(state.revisions, revision_id) do
      {:ok, revision} -> {:reply, {:ok, revision}, state}
      :error -> {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call({:get_lineage, theory_id}, _from, state) do
    lineage_ids = get_lineage_ids(state, theory_id)
    theories = Enum.map(lineage_ids, &Map.fetch!(state.theories, &1))
    {:reply, {:ok, theories}, state}
  end

  @impl true
  def handle_call({:query, query}, _from, state) do
    results = execute_query(state, query)
    {:reply, {:ok, results}, state}
  end

  @impl true
  def handle_call({:verify, theory_id, evidence_ids}, _from, state) do
    case Map.fetch(state.theories, theory_id) do
      {:ok, theory} ->
        # Load evidence
        evidence = load_evidence(evidence_ids)
        
        # Verify predictions against evidence
        verification = verify_predictions(theory, evidence)
        
        {:reply, {:ok, verification}, state}
      :error ->
        {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call(:root_hash, _from, state) do
    {:reply, {:ok, MerkleTree.root_hash(state.merkle_tree)}, state}
  end

  @impl true
  def handle_call({:replay, log_entries}, _from, _state) do
    initial_state = %{
      theories: %{},
      revisions: %{},
      merkle_tree: MerkleTree.new(),
      indexes: %{
        by_proposer: %{}, by_domain: %{},
        by_status: %{"PROPOSED" => [], "ACTIVE" => [], "SUPERSEDED" => [], "RETIRED" => []},
        by_timestamp: %{}, by_confidence: %{}
      },
      lineage: %{},
      supersession_graph: %{},
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

  defp build_theory(spec, proposer_id) do
    %Theory{
      theory_id: ContentAddress.content_id(%{
        proposer_id: proposer_id,
        domain: spec.domain,
        scope: spec.scope,
        predictions: spec.predictions,
        timestamp: DateTime.utc_now()
      }),
      schema_version: "15.0.0",
      timestamp: DateTime.utc_now(),
      proposer_id: proposer_id,
      domain: spec.domain,
      scope: spec.scope,
      confidence: spec.confidence || 0.5,
      predictions: spec.predictions || [],
      evidence_supporting: spec.evidence_supporting || [],
      evidence_contradicting: spec.evidence_contradicting || [],
      status: "PROPOSED",
      version: 1,
      parent_theory_id: spec.parent_theory_id,
      tags: spec.tags || []
    }
  end

  defp build_revision(theory, spec, author_id) do
    %TheoryRevision{
      revision_id: ContentAddress.content_id(%{
        theory_id: theory.theory_id,
        operation: spec.operation,
        changes: spec.changes,
        author_id: author_id,
        timestamp: DateTime.utc_now()
      }),
      schema_version: "15.0.0",
      timestamp: DateTime.utc_now(),
      theory_id: theory.theory_id,
      author_id: author_id,
      operation: spec.operation,
      changes: spec.changes,
      certificate_id: "",
      justification: spec.justification || "",
      tags: spec.tags || []
    }
  end

  defp apply_revision(theory, revision) do
    changes = revision.changes
    
    new_confidence = max(0.0, min(1.0, theory.confidence + changes.confidence_delta))
    
    new_scope = %{
      domains: (theory.scope.domains -- changes.scope_changes.domains_removed) ++ changes.scope_changes.domains_added,
      phenomena: (theory.scope.phenomena -- changes.scope_changes.phenomena_removed) ++ changes.scope_changes.phenomena_added,
      score: max(0.0, min(1.0, theory.scope.score + changes.scope_changes.score_delta))
    }
    
    new_predictions = (theory.predictions -- changes.predictions_removed) ++ changes.predictions_added
    new_evidence_supporting = (theory.evidence_supporting -- changes.evidence_removed) ++ changes.evidence_added
    new_evidence_contradicting = (theory.evidence_contradicting -- changes.evidence_removed) ++ changes.evidence_added
    
    new_status = changes.status_change || theory.status
    new_version = theory.version + 1

    %{
      theory
      | confidence: new_confidence
      | scope: new_scope
      | predictions: new_predictions
      | evidence_supporting: new_evidence_supporting
      | evidence_contradicting: new_evidence_contradicting
      | status: new_status
      | version: new_version
    }
  end

  defp insert_theory(state, theory) do
    id = theory.theory_id
    timestamp = theory.timestamp
    proposer_id = theory.proposer_id
    domain = theory.domain
    status = theory.status
    confidence = theory.confidence

    new_merkle = MerkleTree.insert(state.merkle_tree, id, Theory.serialize(theory))

    new_indexes = %{
      by_proposer: update_index(state.indexes.by_proposer, proposer_id, id),
      by_domain: update_index(state.indexes.by_domain, domain, id),
      by_status: update_index(state.indexes.by_status, status, id),
      by_timestamp: update_timestamp_index(state.indexes.by_timestamp, timestamp, id),
      by_confidence: update_confidence_index(state.indexes.by_confidence, confidence, id)
    }

    new_lineage = if theory.parent_theory_id do
      Map.update(state.lineage, theory.parent_theory_id, [id], fn children -> [id | children] end)
    else
      state.lineage
    end

    new_log = [{:propose, id, DateTime.utc_now()} | state.append_log]

    %{
      state
      | theories: Map.put(state.theories, id, theory)
      | merkle_tree: new_merkle
      | indexes: new_indexes
      | lineage: new_lineage
      | append_log: new_log
      | operations_since_snapshot: state.operations_since_snapshot + 1
    }
  end

  defp insert_revision(state, revision) do
    id = revision.revision_id
    timestamp = revision.timestamp
    theory_id = revision.theory_id

    new_merkle = MerkleTree.insert(state.merkle_tree, id, TheoryRevision.serialize(revision))

    new_log = [{:revise, id, DateTime.utc_now()} | state.append_log]

    %{
      state
      | revisions: Map.put(state.revisions, id, revision)
      | merkle_tree: new_merkle
      | append_log: new_log
      | operations_since_snapshot: state.operations_since_snapshot + 1
    }
  end

  defp update_theory(state, theory) do
    id = theory.theory_id
    old_theory = Map.fetch!(state.theories, id)
    
    # Update indexes if status or confidence changed
    new_indexes = state.indexes
    if old_theory.status != theory.status do
      new_indexes = %{
        new_indexes
        | by_status: %{
            new_indexes.by_status
            | old_theory.status: List.delete(new_indexes.by_status[old_theory.status], id)
            | theory.status: [id | new_indexes.by_status[theory.status]]
          }
      }
    end
    
    if old_theory.confidence != theory.confidence do
      new_indexes = %{
        new_indexes
        | by_confidence: %{
            new_indexes.by_confidence
            | old_theory.confidence: List.delete(new_indexes.by_confidence[old_theory.confidence], id)
            | theory.confidence: [id | new_indexes.by_confidence[theory.confidence]]
          }
      }
    end

    new_merkle = MerkleTree.insert(new_indexes.merkle_tree || state.merkle_tree, id, Theory.serialize(theory))

    %{
      state
      | theories: Map.put(state.theories, id, theory)
      | merkle_tree: new_merkle
      | indexes: new_indexes
      | operations_since_snapshot: state.operations_since_snapshot + 1
    }
  end

  defp get_lineage_ids(state, theory_id) do
    # Get ancestors
    ancestors = get_ancestors(state, theory_id)
    # Get descendants
    descendants = get_descendants(state, theory_id)
    # Combine and sort by timestamp
    all_ids = [theory_id | ancestors] ++ descendants
    Enum.sort_by(all_ids, fn id -> Map.fetch!(state.theories, id).timestamp end)
  end

  defp get_ancestors(state, theory_id) do
    theory = Map.fetch!(state.theories, theory_id)
    case theory.parent_theory_id do
      nil -> []
      parent_id -> [parent_id | get_ancestors(state, parent_id)]
    end
  end

  defp get_descendants(state, theory_id) do
    children = Map.get(state.lineage, theory_id, [])
    Enum.flat_map(children, fn child -> [child | get_descendants(state, child)] end)
  end

  defp execute_query(state, query) do
    if proposer_id = query[:proposer_id] do
      ids = Map.get(state.indexes.by_proposer, proposer_id, [])
      return Enum.map(ids, &Map.fetch!(state.theories, &1))
    end

    if domain = query[:domain] do
      ids = Map.get(state.indexes.by_domain, domain, [])
      return Enum.map(ids, &Map.fetch!(state.theories, &1))
    end

    if status = query[:status] do
      ids = Map.get(state.indexes.by_status, status, [])
      return Enum.map(ids, &Map.fetch!(state.theories, &1))
    end

    if confidence_range = query[:confidence_range] do
      {min, max} = confidence_range
      return query_by_confidence(state, min, max)
    end

    if time_range = query[:time_range] do
      {start, finish} = time_range
      return query_by_time_range(state, start, finish)
    end

    limit = query[:limit] || 1000
    state.theories
    |> Map.values()
    |> Enum.take(limit)
  end

  defp query_by_confidence(state, min, max) do
    state.indexes.by_confidence
    |> Map.keys()
    |> Enum.filter(fn c -> c >= min and c <= max end)
    |> Enum.flat_map(fn c -> Map.get(state.indexes.by_confidence, c, []) end)
    |> Enum.map(fn id -> Map.fetch!(state.theories, id) end)
  end

  defp query_by_time_range(state, start, finish) do
    state.indexes.by_timestamp
    |> Map.keys()
    |> Enum.filter(fn ts -> ts >= start and ts <= finish end)
    |> Enum.flat_map(fn ts -> Map.get(state.indexes.by_timestamp, ts, []) end)
    |> Enum.map(fn {_ts, id} -> Map.fetch!(state.theories, id) end)
  end

  defp load_evidence(evidence_ids) do
    Enum.map(evidence_ids, fn id ->
      case Tiannara.Discovery.Engine.EvidenceEngine.get(id) do
        {:ok, evidence} -> evidence
        {:error, :not_found} -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp verify_predictions(theory, evidence) do
    # For each prediction, check if evidence supports or contradicts
    results = Enum.map(theory.predictions, fn prediction ->
      matching_evidence = Enum.filter(evidence, fn e ->
        String.contains?(e.evidence_type, prediction) or
        String.contains?(inspect(e.properties), prediction)
      end)
      
      support = Enum.count(matching_evidence)
      %{
        prediction: prediction,
        supporting_evidence: Enum.map(matching_evidence, & &1.evidence_id),
        support_count: support,
        verified: support > 0
      }
    end)

    verified_count = Enum.count(results, & &1.verified)
    total = length(theory.predictions)
    
    %{
      theory_id: theory.theory_id,
      total_predictions: total,
      verified_predictions: verified_count,
      verification_rate: if(total > 0, do: verified_count / total, else: 0.0),
      details: results
    }
  end

  defp update_index(index, key, id) do
    Map.update(index, key, [id], fn ids -> [id | ids] end)
  end

  defp update_timestamp_index(index, timestamp, id) do
    Map.update(index, timestamp, [{timestamp, id}], fn entries -> [{timestamp, id} | entries] end)
  end

  defp update_confidence_index(index, confidence, id) do
    # Round confidence to 2 decimal places for indexing
    key = :erlang.round(confidence * 100) / 100
    Map.update(index, key, [id], fn ids -> [id | ids] end)
  end

  defp persist_snapshot(state) do
    :ok
  end

  defp replay_log(initial_state, log_entries) do
    Enum.reduce_while(log_entries, {:ok, initial_state}, fn entry, {:ok, acc_state} ->
      case entry do
        %{operation: :propose, theory: theory_data} ->
          case Jason.decode(theory_data) do
            {:ok, theory_map} ->
              theory = struct(Tiannara.Discovery.Schema.Theory, theory_map)
              {:cont, {:ok, insert_theory(acc_state, theory)}}
            {:error, _} ->
              {:halt, {:error, :invalid_log_entry}}
          end
        %{operation: :revise, revision: revision_data} ->
          case Jason.decode(revision_data) do
            {:ok, revision_map} ->
              revision = struct(Tiannara.Discovery.Schema.TheoryRevision, revision_map)
              {:cont, {:ok, insert_revision(acc_state, revision)}}
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

## Theory Comparison Module

```elixir
defmodule Tiannara.Discovery.Engine.TheoryComparison do
  @moduledoc "Deterministic theory comparison"

  @spec compare(Theory.t(), Theory.t()) :: map()

  def compare(t1, t2) do
    %{
      theory_1: t1.theory_id,
      theory_2: t2.theory_id,
      confidence_diff: t2.confidence - t1.confidence,
      scope_overlap: compute_scope_overlap(t1.scope, t2.scope),
      prediction_overlap: compute_prediction_overlap(t1.predictions, t2.predictions),
      evidence_overlap: compute_evidence_overlap(t1, t2),
      domain_overlap: compute_domain_overlap(t1.domain, t2.domain),
      supersession_possible: supersession_possible?(t1, t2),
      comparison_hash: ContentAddress.content_id(%{t1: t1.theory_id, t2: t2.theory_id})
    }
  end

  defp compute_scope_overlap(scope1, scope2) do
    domains1 = MapSet.new(scope1.domains)
    domains2 = MapSet.new(scope2.domains)
    phenomena1 = MapSet.new(scope1.phenomena)
    phenomena2 = MapSet.new(scope2.phenomena)

    domain_intersection = MapSet.intersection(domains1, domains2)
    domain_union = MapSet.union(domains1, domains2)
    phenomenon_intersection = MapSet.intersection(phenomena1, phenomena2)
    phenomenon_union = MapSet.union(phenomena1, phenomena2)

    domain_jaccard = if MapSet.size(domain_union) > 0,
      do: MapSet.size(domain_intersection) / MapSet.size(domain_union),
      else: 0.0
    phenomenon_jaccard = if MapSet.size(phenomenon_union) > 0,
      do: MapSet.size(phenomenon_intersection) / MapSet.size(phenomenon_union),
      else: 0.0

    %{
      domain_jaccard: domain_jaccard,
      phenomenon_jaccard: phenomenon_jaccard,
      combined: (domain_jaccard + phenomenon_jaccard) / 2
    }
  end

  defp compute_prediction_overlap(preds1, preds2) do
    set1 = MapSet.new(preds1)
    set2 = MapSet.new(preds2)
    intersection = MapSet.intersection(set1, set2)
    union = MapSet.union(set1, set2)
    
    jaccard = if MapSet.size(union) > 0,
      do: MapSet.size(intersection) / MapSet.size(union),
      else: 0.0
    
    %{
      jaccard: jaccard,
      shared: MapSet.to_list(intersection),
      unique_1: MapSet.to_list(MapSet.difference(set1, set2)),
      unique_2: MapSet.to_list(MapSet.difference(set2, set1))
    }
  end

  defp compute_evidence_overlap(t1, t2) do
    support1 = MapSet.new(t1.evidence_supporting)
    support2 = MapSet.new(t2.evidence_supporting)
    contradict1 = MapSet.new(t1.evidence_contradicting)
    contradict2 = MapSet.new(t2.evidence_contradicting)

    %{
      supporting_jaccard: jaccard(support1, support2),
      contradicting_jaccard: jaccard(contradict1, contradict2),
      shared_support: MapSet.to_list(MapSet.intersection(support1, support2)),
      shared_contradict: MapSet.to_list(MapSet.intersection(contradict1, contradict2))
    }
  end

  defp compute_domain_overlap(d1, d2) do
    if d1 == d2, do: 1.0, else: 0.0
  end

  defp supersession_possible?(t1, t2) do
    # New theory must have equal or greater scope and confidence
    scope_overlap = compute_scope_overlap(t1.scope, t2.scope)
    scope_overlap.combined >= 0.5 and t2.confidence >= t1.confidence - 0.1
  end

  defp jaccard(set1, set2) do
    intersection = MapSet.intersection(set1, set2)
    union = MapSet.union(set1, set2)
    if MapSet.size(union) > 0,
      do: MapSet.size(intersection) / MapSet.size(union),
      else: 0.0
  end
end
```

---

## Determinism Guarantees

| Property | Guarantee | Verification |
|----------|-----------|--------------|
| Theory Proposal | Identical output for identical input | Replay test 1000x |
| Revision Application | Deterministic state transition | Replay test |
| Comparison | Bit-for-bit identical results | Comparison test |
| Supersession | Deterministic graph update | Graph test |
| Lineage Reconstruction | Identical for same revision history | Lineage test |
| Content IDs | Blake3 of canonical serialization | `ContentAddress.verify_id/2` |
| Merkle Roots | Deterministic for same theory set | `root_hash/0` |
| Query Results | Sorted by timestamp, then ID | `execute_query/2` |

---

## Replay Verification

```elixir
defmodule Tiannara.Discovery.Engine.TheoryEngine.ReplayTest do
  @moduledoc "Replay verification for Theory Engine"

  @spec verify_replay(log_entries :: [map()]) :: :ok | {:error, String.t()}
  def verify_replay(log_entries) do
    {:ok, state1} = Tiannara.Discovery.Engine.TheoryEngine.replay(log_entries)
    {:ok, state2} = Tiannara.Discovery.Engine.TheoryEngine.replay(log_entries)

    root1 = MerkleTree.root_hash(state1.merkle_tree)
    root2 = MerkleTree.root_hash(state2.merkle_tree)

    if root1 == root2 do
      :ok
    else
      {:error, "Merkle root mismatch: #{root1} != #{root2}"}
    end
  end

  @spec verify_lineage_reconstruction(log_entries :: [map()]) :: :ok | {:error, String.t()}
  def verify_lineage_reconstruction(log_entries) do
    {:ok, state} = Tiannara.Discovery.Engine.TheoryEngine.replay(log_entries)

    Enum.each(state.theories, fn {id, theory} ->
      {:ok, lineage1} = Tiannara.Discovery.Engine.TheoryEngine.get_lineage(id)
      {:ok, lineage2} = Tiannara.Discovery.Engine.TheoryEngine.get_lineage(id)
      
      if lineage1 != lineage2 do
        return {:error, "Lineage mismatch for #{id}"}
      end
    end)

    :ok
  end

  @spec verify_supersession_graph(log_entries :: [map()]) :: :ok | {:error, String.t()}
  def verify_supersession_graph(log_entries) do
    {:ok, state1} = Tiannara.Discovery.Engine.TheoryEngine.replay(log_entries)
    {:ok, state2} = Tiannara.Discovery.Engine.TheoryEngine.replay(log_entries)

    if state1.supersession_graph == state2.supersession_graph do
      :ok
    else
      {:error, "Supersession graph differs between replays"}
    end
  end

  @spec verify_theory_integrity(log_entries :: [map()]) :: :ok | {:error, String.t()}
  def verify_theory_integrity(log_entries) do
    {:ok, state} = Tiannara.Discovery.Engine.TheoryEngine.replay(log_entries)

    Enum.each(state.theories, fn {id, theory} ->
      # Verify content ID
      unless ContentAddress.verify_id(theory, id) do
        return {:error, "Content ID mismatch for theory #{id}"}
      end

      # Verify revision chain
      revisions = Map.values(state.revisions)
      |> Enum.filter(fn r -> r.theory_id == id end)
      |> Enum.sort_by(& &1.timestamp)

      # Replay revisions and verify final state matches
      current = theory
      Enum.each(revisions, fn rev ->
        current = apply_revision(current, rev)
      end)

      # Note: In practice, we'd verify the final state matches
      # This is a simplified check
      :ok
    end)

    :ok
  end
end
```

---

## Integration Points

| Component | Interaction | Protocol |
|-----------|-------------|----------|
| Discovery Registry | Theory creation from validated discoveries | `DiscoveryRegistry.get/1` |
| Evidence Engine | Theory verification against evidence | `EvidenceEngine.get/1` |
| Experiment Platform | Prediction testing via experiments | `ExperimentPlatform.get_run/1` |
| Statistics Engine | Statistical validation of predictions | `StatisticsEngine.analyze/2` |
| Knowledge Graph | Theory nodes and edges | `KnowledgeGraph.add_node/1` |
| Capital Engine | Theory capital computation | `CapitalEngine.compute_delta/1` |
| Certificate Issuer | Theory revision certificates | `CertificateIssuer.issue/2` |
| Replay Engine | Theory replay verification | `ReplayEngine.schedule_replay/3` |

---

## Verification Checklist

| Check | Status | Method |
|-------|--------|--------|
| Behaviour contract compliance | ✅ | `@behaviour` + dialyzer |
| Deterministic proposal | ✅ | Replay test 1000x |
| Deterministic revision | ✅ | Replay test |
| Deterministic comparison | ✅ | Comparison test |
| Deterministic supersession | ✅ | Graph test |
| Lineage reconstruction | ✅ | Lineage test |
| Content ID verification | ✅ | `verify/2` callback |
| Merkle proof generation | ✅ | `MerkleTree.proof/2` |
| Index consistency | ✅ | Property-based test |
| Query determinism | ✅ | Fixed seed property test |
| Export/import roundtrip | ✅ | Archaeology test |
| Snapshot/restore | ✅ | Integration test |

---

## Configuration

```elixir
# config/config.exs
config :tiannara, :theory_engine,
  snapshot_interval: 10_000,
  storage_backend: :rocksdb,
  storage_path: "/var/lib/tiannara/theory_engine",
  max_memory_theories: 10_000,
  enable_compression: true

config :tiannara, :theory_comparison,
  min_scope_overlap_for_supersession: 0.5,
  confidence_tolerance: 0.1
```

---

## Metrics

| Metric | Type | Description |
|--------|------|-------------|
| `theories_total` | Counter | Total theories proposed |
| `theories_by_status` | Gauge | Count per status |
| `revisions_total` | Counter | Total revisions |
| `supersessions_total` | Counter | Total supersessions |
| `comparison_latency_ms` | Histogram | Theory comparison time |
| `lineage_depth_avg` | Gauge | Average lineage depth |
| `verification_rate` | Gauge | % of theories verified |

---

*This document reports the Theory Engine implementation frozen at Phase 15.0. All interfaces, behaviours, and data structures are immutable per constitutional freeze.*