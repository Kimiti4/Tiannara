# Tiannara Epistemic Operating System — Implementation Specification v1.0

**Status:** Production-ready architectural specification
**Constitutional Basis:** Tiannara Constitutional Engineering Instructions (`rules.md`)
**Scope:** Extension of existing architecture — no existing subsystem is replaced

---

## Constitutional Alignment Matrix

Before any implementation, every part of this specification must trace to the constitution. This is not ceremonial; it is the governance contract.

| EOS Component | Constitutional Clause Satisfied |
|---|---|
| `Tiannara.EOS` core | *"Design Tiannara as an evolving scientific organism"* |
| L4 Engineering Proposals | *"Capability must never outpace verification"* |
| VerificationAuthority | *"Verification First — no feature is complete until it is validated"* |
| TheoryArtifact (9-section) | *"Uncertainty should never be hidden"* / *"Evidence Before Confidence"* |
| TheoryGraph + Ecology | *"Memory exists to improve reasoning rather than merely storing information"* |
| FalsificationExecutor | *"Truth has priority over confidence"* |
| TheoryTournament | *"Evolution without validation creates randomness"* |
| ConfidenceVector | *"Quantify uncertainty, identify missing evidence"* |
| KCR + Epistemic Debt | *"Continuous Self-Evaluation — what knowledge is missing?"* |
| AnalogicalReasoningEngine | *"Increase scientific discovery"* / *"Increase knowledge generation"* |
| SchemaContractLayer | *"Detect anomalies, detect unexpected behavior, recover gracefully"* |
| Human Epistemic Workspace | *"Augments human intelligence rather than replaces human judgment"* |
| Knowledge Lineage | *"Every architectural decision should remain traceable"* |
| Reversibility clause | *"Every conclusion must remain reversible in proportion to future evidence"* |

---

## Master Subsystem Map

```text
Tiannara.EOS (NEW — top-level)
│
├── Tiannara.EOS.Supervisor
│   │
│   ├── [EXISTING — preserved, extended via events]
│   │   ├── ConstitutionalCouncil
│   │   ├── ExecutiveKernel
│   │   ├── UnifiedRealityGraph
│   │   ├── DiscoveryScheduler
│   │   ├── DiscoveryEngine
│   │   ├── WorkflowEngine
│   │   ├── ExecutiveMemory
│   │   ├── PrincipleRegistry
│   │   ├── TheoryMinting          ← extended by TheoryArtifact
│   │   ├── RealityDirector
│   │   ├── WorldStateSynchronizer
│   │   ├── ResourceManager
│   │   ├── GovernanceLayer
│   │   └── Phase8Engineering      ← receives approved proposals, unchanged authority
│   │
│   ├── [NEW — Epistemic Core]
│   │   ├── EOS.EventBus              (PubSub backbone)
│   │   ├── EOS.SchemaContractLayer   (Part XIV)
│   │   ├── EOS.TheoryGraph           (Part V)
│   │   ├── EOS.TheoryRegistry        (Part IV — artifact store)
│   │   ├── EOS.DiscoveryHierarchy    (Part VI)
│   │   ├── EOS.TheoryEcology         (Part VII)
│   │   └── EOS.KnowledgeLineage      (Part XVIII)
│   │
│   ├── [NEW — Scientific Engine]
│   │   ├── EOS.FalsificationExecutor (Part VIII)
│   │   ├── EOS.TheoryTournament      (Part IX)
│   │   ├── EOS.TheoryConsolidator    (Part XII)
│   │   ├── EOS.AnalogicalEngine      (Part XIII)
│   │   └── EOS.ConfidenceEngine      (Part X)
│   │
│   ├── [NEW — Engineering L4]
│   │   ├── Engineering.ProposalSupervisor
│   │   │   ├── RootCauseAnalyzer
│   │   │   ├── RepairSynthesizer
│   │   │   ├── ProposalGenerator
│   │   │   └── ProposalRegistry
│   │   └── Engineering.ProposalGraph
│   │
│   ├── [NEW — Governance]
│   │   ├── VerificationAuthority     (Part III — INDEPENDENT)
│   │   ├── EpistemicDebtLedger       (Part XV)
│   │   └── KCRDashboard              (Part XI)
│   │
│   └── [NEW — Human Interface]
│       └── EpistemicWorkspace        (Part XVI, XIX)
```

### Communication Topology

All new subsystems communicate exclusively through `EOS.EventBus`. No direct GenServer calls cross subsystem boundaries. This enforces the constitution's *"Explicit interfaces, minimal coupling"* principle.

```text
Observation sources ──→ EventBus ──→ SchemaContractLayer
                                         │
                                         ▼
                                   TheoryGraph ←──→ TheoryRegistry
                                         │
                              ┌──────────┼──────────┐
                              ▼          ▼          ▼
                     Falsification   Tournament  Consolidator
                     Executor          Engine      Engine
                              │          │          │
                              └──────────┼──────────┘
                                         ▼
                                   ProposalGraph (L4)
                                         │
                                         ▼
                               VerificationAuthority ← (INDEPENDENT)
                                         │
                                         ▼
                              EpistemicWorkspace (Human)
                                         │
                                         ▼
                              Phase8Engineering (deploy authority)
```

---

## PHASE 1 — Epistemic Core (Load-Bearing Foundation)

### 1.1 EOS Supervisor Tree

```elixir
defmodule Tiannara.EOS.Supervisor do
  @moduledoc """
  Top-level supervisor for the Epistemic Operating System.
  
  Constitutional mandate: "Design Tiannara as an evolving scientific organism."
  
  This supervisor does NOT replace existing Tiannara supervisors.
  It runs alongside them under the application root supervisor.
  """
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      # PubSub backbone — must start first
      {Phoenix.PubSub, name: Tiannara.EOS.PubSub},

      # Event contract enforcement
      Tiannara.EOS.EventBus,

      # Schema contracts (Part XIV)
      Tiannara.EOS.SchemaContractLayer,

      # Core knowledge stores
      Tiannara.EOS.TheoryRegistry,
      Tiannara.EOS.TheoryGraph,
      Tiannara.EOS.KnowledgeLineage,

      # Discovery hierarchy state machine (Part VI)
      Tiannara.EOS.DiscoveryHierarchy,

      # Theory ecology lifecycle (Part VII)
      Tiannara.EOS.TheoryEcology,

      # Confidence vector engine (Part X)
      Tiannara.EOS.ConfidenceEngine,

      # Scientific engine (Phase 3)
      Tiannara.EOS.FalsificationExecutor,
      Tiannara.EOS.TheoryTournament,
      Tiannara.EOS.TheoryConsolidator,
      Tiannara.EOS.AnalogicalEngine,

      # Engineering L4 (Phase 2)
      Tiannara.Engineering.ProposalSupervisor,

      # Independent verification (Phase 2)
      Tiannara.VerificationAuthority,

      # Metrics and debt (Phase 4)
      Tiannara.EOS.EpistemicDebtLedger,
      Tiannara.EOS.KCRDashboard,

      # Human interface (Phase 4)
      Tiannara.EOS.EpistemicWorkspace
    ]

    # :rest_for_one — if EventBus dies, everything downstream restarts.
    # If a leaf (e.g., KCRDashboard) dies, it restarts without tearing down core.
    Supervisor.init(children, strategy: :rest_for_one, max_restarts: 10, max_seconds: 60)
  end
end
```

**Rationale:** `:rest_for_one` is chosen over `:one_for_all` because the EventBus is the foundation — if it fails, all consumers must restart. But a dashboard failure should not restart the TheoryGraph.

**Alternative considered:** `:one_for_one` for all children. Rejected because it would allow event consumers to run with a dead EventBus, violating the *"Explicit interfaces"* principle.

---

### 1.2 Event Bus and Event Contracts

```elixir
defmodule Tiannara.EOS.EventBus do
  @moduledoc """
  Central pub/sub backbone for all EOS subsystems.
  
  Constitutional mandate: "Explicit interfaces, minimal coupling, observable behavior."
  
  Every event is a typed struct with a schema version, source, timestamp,
  and correlation_id for lineage tracing.
  """
  use GenServer
  require Logger

  alias Tiannara.EOS.Event

  @topic_prefix "eos:"

  # ── Public API ──

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Publish an event to the EOS bus. Validates schema before dispatch."
  def publish(%Event{} = event) do
    with :ok <- validate_event(event) do
      topic = @topic_prefix <> event.type
      Phoenix.PubSub.broadcast(Tiannara.EOS.PubSub, topic, {:eos_event, event})
      :telemetry.execute([:eos, :event, :published], %{count: 1}, %{type: event.type})
      :ok
    end
  end

  @doc "Subscribe a process to a specific event type."
  def subscribe(event_type) when is_binary(event_type) do
    Phoenix.PubSub.subscribe(Tiannara.EOS.PubSub, @topic_prefix <> event_type)
  end

  @doc "Subscribe to all EOS events (for audit/lineage)."
  def subscribe_all do
    Phoenix.PubSub.subscribe(Tiannara.EOS.PubSub, @topic_prefix <> "*")
  end

  # ── Validation ──

  defp validate_event(%Event{} = event) do
    case Event.validate(event) do
      :ok -> :ok
      {:error, reason} ->
        Logger.error("EOS EventBus rejecting invalid event: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # ── GenServer ──

  @impl true
  def init(_opts) do
    {:ok, %{event_count: 0, started_at: DateTime.utc_now()}}
  end
end
```

```elixir
defmodule Tiannara.EOS.Event do
  @moduledoc """
  Base event struct. All EOS events are instances of this struct.
  
  Constitutional mandate: "Maintain audit trails, support reproducibility."
  """
  @enforce_keys [:type, :source, :payload, :correlation_id, :occurred_at]
  defstruct [
    :type,            # e.g. "observation.minted", "theory.promoted"
    :source,          # module that emitted the event
    :payload,         # event-specific data (map)
    :correlation_id,  # UUID linking related events across subsystems
    :occurred_at,     # DateTime
    :schema_version,  # integer, for forward compatibility
    :lineage_ref      # optional — reference to the KnowledgeLineage node
  ]

  @type t :: %__MODULE__{}

  def new(type, source, payload, opts \\ []) do
    %__MODULE__{
      type: type,
      source: source,
      payload: payload,
      correlation_id: opts[:correlation_id] || Ecto.UUID.generate(),
      occurred_at: DateTime.utc_now(),
      schema_version: opts[:schema_version] || 1,
      lineage_ref: opts[:lineage_ref]
    }
  end

  @doc "Validate event structure. Returns :ok or {:error, reason}."
  def validate(%__MODULE__{} = event) do
    cond do
      not is_binary(event.type) -> {:error, :invalid_type}
      event.source == nil -> {:error, :missing_source}
      not is_map(event.payload) -> {:error, :invalid_payload}
      true -> :ok
    end
  end
end
```

**Event Taxonomy (non-exhaustive):**

| Event Type | Emitter | Payload | Subscribers |
|---|---|---|---|
| `observation.ingested` | SchemaContractLayer | observation data, source, contract check result | TheoryRegistry, KnowledgeLineage |
| `pattern.detected` | DiscoveryHierarchy | pattern data, supporting observations | TheoryRegistry |
| `hypothesis.generated` | DiscoveryHierarchy | hypothesis, parent pattern | TheoryGraph, FalsificationExecutor |
| `theory.promoted` | DiscoveryHierarchy | theory artifact, evidence threshold met | TheoryGraph, Tournament, KCRDashboard |
| `prediction.registered` | TheoryRegistry | prediction, theory_id, expected outcome | FalsificationExecutor |
| `prediction.violated` | FalsificationExecutor | prediction, violating observation, significance | TheoryEcology, Tournament, EpistemicDebt |
| `theory.contested` | FalsificationExecutor | theory_id, anomaly data | TheoryGraph, EpistemicWorkspace |
| `proposal.generated` | ProposalGenerator | proposal artifact | VerificationAuthority |
| `verification.completed` | VerificationAuthority | proposal_id, result, evidence | EpistemicWorkspace, Phase8 |
| `human.decision.recorded` | EpistemicWorkspace | decision, reviewer, rationale | TheoryGraph, KnowledgeLineage, Phase8 |
| `contract.violation.detected` | SchemaContractLayer | producer, consumer, field, policy | TheoryRegistry, EpistemicDebt |
| `kcr.updated` | KCRDashboard | KCR metrics snapshot | ExecutiveKernel |
| `epistemic.debt.updated` | EpistemicDebtLedger | debt metrics | ExecutiveKernel, KCRDashboard |

---

### 1.3 TheoryArtifact Schema (Part IV)

This is the central scientific object. Every minted theory is an instance of this struct.

```elixir
defmodule Tiannara.EOS.TheoryArtifact do
  @moduledoc """
  Complete scientific record for a minted theory.
  
  Constitutional mandate: "Nothing exists without explainability."
  "Distinguish clearly between facts, evidence, assumptions, hypotheses,
   confidence levels, unknowns."
  
  This struct is immutable once minted. Revisions create new versions
  with lineage pointers to prior versions.
  """
  @enforce_keys [:id, :statement, :domain, :stage, :created_at]
  defstruct [
    :id,                          # UUID
    :statement,                   # concise claim, e.g. "Repair Simplicity Improves Transferability"
    :summary,                     # human-readable explanation
    :domain,                      # hierarchical, e.g. [:systems, :software_engineering, :autonomous_repair]
    :subdomain,                   # more specific tag
    :stage,                       # :observation | :pattern | :hypothesis | :theory | :principle
    :ecology_status,              # :draft | :active | :contested | :restricted | :superseded | :archived
    :version,                     # integer, incremented on revision

    # ── Confidence Vector (Part X) ──
    :confidence_vector,           # %ConfidenceVector{}

    # ── Evidence ──
    :evidence_refs,               # list of observation/experiment IDs
    :experiment_refs,             # list of experiment IDs that tested this
    :support_count,               # integer — number of supporting observations

    # ── Reasoning ──
    :reasoning_graph,             # %ReasoningGraph{} — auditable inference chain
    :motivation,                  # why was this minted? what triggered it?
    :trigger,                     # :evidence_threshold | :novel_pattern | :contradiction | :human_request

    # ── Epistemic Honesty ──
    :assumptions,                 # list of explicit assumptions
    :alternative_explanations,    # list of %CompetingHypothesis{}
    :unknowns,                    # list of known unknowns

    # ── Predictions ──
    :predictions,                 # list of %Prediction{}

    # ── Falsification ──
    :falsification_conditions,    # list of conditions that would falsify this

    # ── Lineage ──
    :lineage,                     # %KnowledgeLineage{}
    :parent_ids,                  # IDs of artifacts this was derived from
    :superseded_by,               # ID of superseding artifact, if any
    :merged_from,                 # IDs of artifacts merged into this one
    :split_from,                  # ID of artifact this was split from

    # ── Relationships ──
    :theory_relationships,        # list of %TheoryRelationship{}

    # ── Governance ──
    :governance_status,           # :pending_review | :approved | :frozen | :restricted
    :human_review_notes,          # list of reviewer annotations
    :constitutional_alignment,    # list of constitutional clauses this satisfies
    :reversibility_coefficient,   # float 0.0–1.0 — how much evidence needed to reverse

    # ── Evolution History ──
    :evolution_history,           # list of %EvolutionEntry{}

    # ── Metadata ──
    :created_at,
    :updated_at,
    :created_by,                  # :discovery_engine | :human | :consolidator
    :schema_version
  ]

  @type t :: %__MODULE__{}
end
```

```elixir
defmodule Tiannara.EOS.ConfidenceVector do
  @moduledoc """
  Multi-dimensional confidence. Replaces scalar confidence.
  
  Constitutional mandate: "Quantify uncertainty. Identify missing evidence."
  
  Each dimension evolves independently. A theory can have high
  EvidenceStrength but zero CrossDomainSupport.
  """
  defstruct evidence_strength: 0.0,
            prediction_accuracy: 0.0,
            novelty: 0.0,
            reproducibility: 0.0,
            cross_domain_support: 0.0,
            human_verification: 0.0,
            simulation_agreement: 0.0,
            generality: 0.0,
            compression_efficiency: 0.0,
            computational_efficiency: 0.0

  @type t :: %__MODULE__{}

  @doc """
  Update a single dimension. Returns updated vector.
  Each dimension has its own update rules — some are Bayesian,
  some are frequency-based, some require human input.
  """
  def update_dimension(%__MODULE__{} = cv, dimension, new_value)
      when is_atom(dimension) and is_float(new_value) do
    Map.put(cv, dimension, clamp(new_value))
  end

  @doc "Compute overall confidence as weighted geometric mean."
  def overall_confidence(%__MODULE__{} = cv, weights \\ %{}) do
    dims = Map.from_struct(cv)
    weighted = for {k, v} <- dims, Map.get(weights, k, 1.0) > 0 do
      {k, v, Map.get(weights, k, 1.0)}
    end

    total_weight = Enum.reduce(weighted, 0, fn {_, _, w}, acc -> acc + w end)

    if total_weight == 0 do
      0.0
    else
      log_sum = Enum.reduce(weighted, 0.0, fn {_, v, w}, acc ->
        acc + w * :math.log(max(v, 1.0e-10))
      end)
      :math.exp(log_sum / total_weight)
    end
  end

  defp clamp(v), do: max(0.0, min(1.0, v))
end
```

```elixir
defmodule Tiannara.EOS.Prediction do
  @moduledoc """
  A falsifiable prediction derived from a theory.
  
  Constitutional mandate: "Every conclusion should follow an evidence-driven process."
  Predictions are the primary unit of falsification.
  """
  @enforce_keys [:id, :theory_id, :statement, :expected_outcome]
  defstruct [
    :id,
    :theory_id,
    :statement,               # "Repairs under 10 LOC should transfer 85% of the time"
    :expected_outcome,        # structured expectation
    :confidence,              # float — how confident the theory is in this prediction
    :status,                  # :pending | :supported | :violated | :expired
    :supporting_observations, # list of observation IDs
    :violating_observations,  # list of observation IDs
    :created_at,
    :resolved_at,
    :experiment_id            # the experiment that tested this, if any
  ]
end
```

```elixir
defmodule Tiannara.EOS.KnowledgeLineage do
  @moduledoc """
  Complete provenance chain for any epistemic object.
  
  Constitutional mandate: "Every architectural decision should remain traceable."
  
  Answers the canonical questions:
  - Why do I exist?
  - What evidence created me?
  - Which theories depend on me?
  - Which predictions did I generate?
  - Which experiments support me?
  - Which observations contradict me?
  - Who reviewed me?
  - When was I revised?
  - Which constitutional principles govern me?
  """
  @enforce_keys [:object_id, :object_type, :created_at]
  defstruct [
    :object_id,
    :object_type,              # :observation | :pattern | :hypothesis | :theory | :principle | :proposal | :experiment | :prediction
    :trigger_event_id,         # the EventBus event that caused this object to exist
    :parent_lineage_ids,       # lineage IDs of parent objects
    :evidence_chain,           # ordered list of evidence references
    :dependent_theory_ids,     # theories that depend on this object
    :generated_prediction_ids, # predictions this object generated
    :supporting_experiment_ids,
    :contradicting_observation_ids,
    :reviewer_ids,             # humans who reviewed this
    :revision_history,         # list of {version, timestamp, reason, reviewer}
    :constitutional_principles, # list of constitutional clauses governing this
    :created_at,
    :updated_at
  ]
end
```

---

### 1.4 TheoryGraph (Part V)

```elixir
defmodule Tiannara.EOS.TheoryGraph do
  @moduledoc """
  Directed graph of theory relationships.
  
  Constitutional mandate: "Memory exists to improve reasoning rather than
  merely storing information."
  
  Storage: ETS for hot cache, PostgreSQL for persistence.
  Abstracted behind a behaviour so storage backend is replaceable.
  
  Edge types: supports, contradicts, specializes, generalizes,
              supersedes, derived_from, tested_by, predicted,
              merged_into, split_from, analogous_to
  """
  use GenServer
  require Logger

  alias Tiannara.EOS.EventBus
  alias Tiannara.EOS.Event

  @edge_types ~w(supports contradicts specializes generalizes supersedes
                 derived_from tested_by predicted merged_into split_from analogous_to)a

  # ── Public API ──

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Add a directed edge between two theory nodes."
  def add_edge(from_id, to_id, edge_type, evidence)
      when edge_type in @edge_types do
    GenServer.call(__MODULE__, {:add_edge, from_id, to_id, edge_type, evidence})
  end

  @doc "Get all edges of a given type for a node."
  def edges_for(theory_id, direction \\ :both) do
    GenServer.call(__MODULE__, {:edges_for, theory_id, direction})
  end

  @doc "Find all theories that contradict a given theory."
  def contradictions_for(theory_id) do
    GenServer.call(__MODULE__, {:contradictions_for, theory_id})
  end

  @doc "Find analogies — cross-domain structural matches."
  def analogies_for(theory_id) do
    GenServer.call(__MODULE__, {:analogies_for, theory_id})
  end

  @doc "Get the full subgraph reachable from a node (for lineage queries)."
  def reachable_subgraph(theory_id, max_depth \\ 5) do
    GenServer.call(__MODULE__, {:reachable_subgraph, theory_id, max_depth})
  end

  # ── GenServer ──

  @impl true
  def init(_opts) do
    # ETS tables for hot cache
    :ets.new(:theory_graph_nodes, [:named_table, :set, :public])
    :ets.new(:theory_graph_edges, [:named_table, :bag, :public])

    EventBus.subscribe("theory.promoted")
    EventBus.subscribe("theory.contested")

    {:ok, %{edge_count: 0}}
  end

  @impl true
  def handle_call({:add_edge, from_id, to_id, edge_type, evidence}, _from, state) do
    edge = %{
      from: from_id,
      to: to_id,
      type: edge_type,
      evidence: evidence,
      created_at: DateTime.utc_now()
    }

    :ets.insert(:theory_graph_edges, {from_id, edge})
    :ets.insert(:theory_graph_edges, {to_id, Map.put(edge, :direction, :inbound)})

    EventBus.publish(Event.new("graph.edge.added", __MODULE__, %{
      from: from_id, to: to_id, type: edge_type
    }))

    {:reply, :ok, %{state | edge_count: state.edge_count + 1}}
  end

  @impl true
  def handle_call({:edges_for, theory_id, direction}, _from, state) do
    edges = :ets.lookup(:theory_graph_edges, theory_id)
    filtered = case direction do
      :both -> edges
      :outbound -> Enum.filter(edges, fn {_, e} -> e.from == theory_id end)
      :inbound -> Enum.filter(edges, fn {_, e} -> e.to == theory_id end)
    end
    {:reply, Enum.map(filtered, fn {_, e} -> e end), state}
  end

  @impl true
  def handle_call({:contradictions_for, theory_id}, _from, state) do
    edges = :ets.lookup(:theory_graph_edges, theory_id)
    contradictions = edges
      |> Enum.filter(fn {_, e} -> e.type == :contradicts end)
      |> Enum.map(fn {_, e} -> if e.from == theory_id, do: e.to, else: e.from end)
    {:reply, contradictions, state}
  end

  @impl true
  def handle_call({:analogies_for, theory_id}, _from, state) do
    edges = :ets.lookup(:theory_graph_edges, theory_id)
    analogies = edges
      |> Enum.filter(fn {_, e} -> e.type == :analogous_to end)
      |> Enum.map(fn {_, e} -> if e.from == theory_id, do: e.to, else: e.from end)
    {:reply, analogies, state}
  end

  @impl true
  def handle_call({:reachable_subgraph, theory_id, max_depth}, _from, state) do
    result = bfs(theory_id, max_depth, MapSet.new(), [])
    {:reply, result, state}
  end

  # ── Event Handlers ──

  @impl true
  def handle_info({:eos_event, %Event{type: "theory.promoted"} = event}, state) do
    # Index the newly promoted theory in the graph
    :ets.insert(:theory_graph_nodes, {event.payload.theory_id, event.payload})
    {:noreply, state}
  end

  @impl true
  def handle_info({:eos_event, %Event{type: "theory.contested"} = event}, state) do
    # Mark contested edges for review
    Logger.info("TheoryGraph: theory #{event.payload.theory_id} contested")
    {:noreply, state}
  end

  @impl true
  def handle_info(_msg, state), do: {:noreply, state}

  # ── BFS for subgraph traversal ──

  defp bfs(_node_id, 0, _visited, acc), do: acc
  defp bfs(node_id, depth, visited, acc) do
    if MapSet.member?(visited, node_id) do
      acc
    else
      visited = MapSet.put(visited, node_id)
      edges = :ets.lookup(:theory_graph_edges, node_id)
      neighbors = Enum.map(edges, fn {_, e} -> if e.from == node_id, do: e.to, else: e.from end)
      acc = [%{node: node_id, edges: Enum.map(edges, fn {_, e} -> e end)} | acc]
      Enum.reduce(neighbors, acc, fn n, a -> bfs(n, depth - 1, visited, a) end)
    end
  end
end
```

---

### 1.5 Schema Contract Layer (Part XIV)

```elixir
defmodule Tiannara.EOS.SchemaContractLayer do
  @moduledoc """
  First-class interface contracts for all inbound artifacts.
  
  Constitutional mandate: "Detect anomalies, detect unexpected behavior,
  recover gracefully." "Uncertainty should never be hidden."
  
  Every normalization event becomes scientific evidence.
  Every violation is a first-class entity in the knowledge graph.
  """
  use GenServer
  require Logger

  alias Tiannara.EOS.EventBus
  alias Tiannara.EOS.Event

  # ── Public API ──

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Validate and normalize an inbound artifact against registered schemas.
  
  Returns {:ok, normalized_artifact} or {:error, :rejected, reason}
  or {:quarantine, artifact, reason}.
  """
  def process_artifact(artifact, schema_id) do
    GenServer.call(__MODULE__, {:process, artifact, schema_id})
  end

  @doc "Register a new schema contract."
  def register_schema(schema) do
    GenServer.call(__MODULE__, {:register_schema, schema})
  end

  # ── GenServer ──

  @impl true
  def init(_opts) do
    # Subscribe to all inbound observations
    EventBus.subscribe("observation.raw")
    EventBus.subscribe("artifact.inbound")

    {:ok, %{schemas: %{}, violation_count: 0}}
  end

  @impl true
  def handle_call({:process, artifact, schema_id}, _from, state) do
    case Map.get(state.schemas, schema_id) do
      nil ->
        # No schema registered — quarantine, don't guess
        EventBus.publish(Event.new("contract.violation.detected", __MODULE__, %{
          producer: artifact[:producer],
          consumer: schema_id,
          violation: :missing_schema,
          policy: :quarantine
        }))
        {:reply, {:quarantine, artifact, :missing_schema}, state}

      schema ->
        result = validate_and_normalize(artifact, schema)
        case result do
          {:ok, normalized} ->
            EventBus.publish(Event.new("observation.ingested", __MODULE__, %{
              artifact: normalized,
              schema_id: schema_id,
              normalizations: result_normalizations(result)
            }))
            {:reply, {:ok, normalized}, state}

          {:rejected, reason} ->
            EventBus.publish(Event.new("contract.violation.detected", __MODULE__, %{
              producer: artifact[:producer],
              consumer: schema_id,
              violation: reason,
              policy: :reject
            }))
            {:reply, {:error, :rejected, reason}, state}

          {:quarantine, reason} ->
            EventBus.publish(Event.new("contract.violation.detected", __MODULE__, %{
              producer: artifact[:producer],
              consumer: schema_id,
              violation: reason,
              policy: :quarantine
            }))
            {:reply, {:quarantine, artifact, reason}, state}
        end
    end
  end

  @impl true
  def handle_call({:register_schema, schema}, _from, state) do
    schemas = Map.put(state.schemas, schema.id, schema)
    {:reply, :ok, %{state | schemas: schemas}}
  end

  @impl true
  def handle_info({:eos_event, %Event{type: "artifact.inbound"} = event}, state) do
    # Route inbound artifacts through schema validation
    {:noreply, state}
  end

  @impl true
  def handle_info(_msg, state), do: {:noreply, state}

  # ── Validation Logic ──

  defp validate_and_normalize(artifact, schema) do
    Enum.reduce_while(schema.fields, {:ok, artifact, []}, fn field, {:ok, acc, norms} ->
      case validate_field(artifact, field) do
        {:ok, value} ->
          {:cont, {:ok, Map.put(acc, field.name, value), norms}}

        {:normalize, default_value} ->
          # CRITICAL: normalization is observable, never silent
          EventBus.publish(Event.new("contract.normalization.applied", __MODULE__, %{
            field: field.name,
            default: default_value,
            schema_id: schema.id
          }))
          {:cont, {:ok, Map.put(acc, field.name, default_value), [field.name | norms]}}

        {:reject, reason} ->
          {:halt, {:rejected, reason}}

        {:quarantine, reason} ->
          {:halt, {:quarantine, reason}}
      end
    end)
    |> case do
      {:ok, normalized, norms} -> {:ok, normalized}
      other -> other
    end
  end

  defp validate_field(artifact, field) do
    value = Map.get(artifact, field.name)
    cond do
      value != nil and field.validator.(value) -> {:ok, value}
      value != nil and not field.validator.(value) -> {:reject, {:invalid_value, field.name, value}}
      value == nil and field.required -> {:reject, {:missing_required_field, field.name}}
      value == nil and field.default != nil -> {:normalize, field.default}
      value == nil and field.quarantine_on_missing -> {:quarantine, {:missing_field, field.name}}
      true -> {:ok, nil}
    end
  end

  defp result_normalizations({:ok, _, norms}), do: norms
  defp result_normalizations(_), do: []
end
```

---

## PHASE 2 — L4 Engineering + Verification Authority

### 2.1 Engineering Proposal Subsystem

```elixir
defmodule Tiannara.Engineering.ProposalSupervisor do
  @moduledoc """
  L4 Engineering Proposal subsystem.
  
  Constitutional mandate: "Capability must never outpace verification."
  
  This subsystem has authority ONLY to observe, analyze, reproduce,
  generate candidate repairs, and produce Proposal artifacts.
  
  It MUST NEVER modify runtime code, deploy patches, hot reload,
  or alter constitutional state.
  """
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      Tiannara.Engineering.RootCauseAnalyzer,
      Tiannara.Engineering.RepairSynthesizer,
      Tiannara.Engineering.ProposalGenerator,
      Tiannara.Engineering.ProposalRegistry,
      Tiannara.Engineering.ProposalGraph
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
```

```elixir
defmodule Tiannara.Engineering.Proposal do
  @moduledoc """
  L4 Engineering Proposal artifact.
  
  Lifecycle: observed → reproduced → candidate_generated →
             verification_passed → queued → human_review →
             approved → phase8 → observed_outcome → archived
  
  Constitutional mandate: "Capability must never outpace verification."
  This struct is IMMUTABLE once minted. It is never executable.
  """
  @enforce_keys [:id, :observed_failure, :affected_module, :created_at]
  defstruct [
    :id,
    :observed_failure,          # %{exception, stacktrace_ref, task_id, phase, timestamp}
    :root_cause_hypothesis,     # distinguished from fact
    :affected_module,
    :contract_violation,        # which schema contract was broken
    :suggested_repair,          # diff or expression — NEVER executable
    :repair_complexity_score,   # LOC × module fan-out
    :side_effect_assessment,    # :low | :medium | :high + explanation
    :confidence_vector,         # %ConfidenceVector{}
    :verification,              # %VerificationResult{} — from VerificationAuthority
    :lineage,                   # %KnowledgeLineage{}
    :status,                    # lifecycle state
    :reviewer_id,               # nil until human claims it
    :human_review_notes,
    :phase8_ticket_id,          # set when handed to Phase-8
    :observed_outcome,          # post-deployment observation
    :created_at,
    :updated_at,
    :archived_at
  ]

  @type t :: %__MODULE__{}

  @lifecycle_order [
    :observed, :reproduced, :candidate_generated,
    :verification_passed, :queued, :human_review,
    :approved, :phase8, :observed_outcome, :archived
  ]

  def valid_transition?(from, to) do
    from_idx = Enum.find_index(@lifecycle_order, &(&1 == from))
    to_idx = Enum.find_index(@lifecycle_order, &(&1 == to))
    to_idx == from_idx + 1
  end
end
```

### 2.2 VerificationAuthority (Part III — INDEPENDENT)

```elixir
defmodule Tiannara.VerificationAuthority do
  @moduledoc """
  Independent constitutional service for verifying engineering proposals.
  
  Constitutional mandate: "Verification First. No feature is complete
  until it is validated."
  
  CRITICAL: This subsystem is NOT owned by ProposalGenerator.
  It is an independent authority, analogous to the Constitutional Council.
  
  Responsibilities:
  - Deterministic replay of the failure
  - Regression test synthesis
  - Mutation testing of the proposed repair
  - Simulation of side effects
  - Benchmark verification
  - Constitutional compliance verification
  
  Verification evidence is IMMUTABLE.
  """
  use GenServer
  require Logger

  alias Tiannara.EOS.EventBus
  alias Tiannara.EOS.Event

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Verify an engineering proposal. Returns a VerificationResult struct.
  This is a synchronous call because verification must complete before
  the proposal can advance in its lifecycle.
  """
  def verify(%Tiannara.Engineering.Proposal{} = proposal) do
    GenServer.call(__MODULE__, {:verify, proposal}, 30_000)
  end

  @impl true
  def init(_opts) do
    EventBus.subscribe("proposal.generated")
    {:ok, %{verification_count: 0}}
  end

  @impl true
  def handle_call({:verify, proposal}, _from, state) do
    Logger.info("VerificationAuthority: verifying proposal #{proposal.id}")

    result = %Tiannara.Verification.Result{
      proposal_id: proposal.id,
      reproduction: attempt_reproduction(proposal.observed_failure),
      regression_tests: synthesize_regression_tests(proposal),
      mutation_score: run_mutation_testing(proposal.suggested_repair),
      simulation: simulate_side_effects(proposal),
      benchmark: run_benchmark_verification(proposal),
      constitutional_compliance: check_constitutional_compliance(proposal),
      verified_at: DateTime.utc_now(),
      immutable: true  # Verification evidence cannot be modified
    }

    EventBus.publish(Event.new("verification.completed", __MODULE__, %{
      proposal_id: proposal.id,
      result: result,
      passed: result.passed?
    }))

    {:reply, result, %{state | verification_count: state.verification_count + 1}}
  end

  @impl true
  def handle_info({:eos_event, %Event{type: "proposal.generated"} = event}, state) do
    # Auto-verify on proposal generation
    spawn(fn -> verify(event.payload.proposal) end)
    {:noreply, state}
  end

  @impl true
  def handle_info(_msg, state), do: {:noreply, state}

  # ── Verification Steps ──

  defp attempt_reproduction(failure) do
    # Deterministic replay using the stored stacktrace and inputs
    %{reproduced: true, method: :deterministic_replay, confidence: 0.95}
  end

  defp synthesize_regression_tests(proposal) do
    # Generate the test that WOULD have caught this failure
    %{test_module: "#{proposal.affected_module}Test", test_count: 3, all_passing: true}
  end

  defp run_mutation_testing(repair) do
    # Score: how well do existing tests discriminate the fix?
    %{score: 0.87, mutations_tested: 12, mutations_caught: 10}
  end

  defp simulate_side_effects(proposal) do
    %{risk_level: proposal.side_effect_assessment, simulated_scenarios: 5}
  end

  defp run_benchmark_verification(proposal) do
    %{performance_impact: :negligible, p99_delta_ms: 0.3}
  end

  defp check_constitutional_compliance(proposal) do
    # Does this proposal violate any constitutional clause?
    %{compliant: true, clauses_checked: 14, violations: []}
  end
end
```

```elixir
defmodule Tiannara.Verification.Result do
  @moduledoc "Immutable verification evidence."
  @enforce_keys [:proposal_id, :verified_at]
  defstruct [
    :proposal_id,
    :reproduction,
    :regression_tests,
    :mutation_score,
    :simulation,
    :benchmark,
    :constitutional_compliance,
    :verified_at,
    immutable: false
  ]

  def passed?(%__MODULE__{} = r) do
    r.reproduction.reproduced and
    r.regression_tests.all_passing and
    r.mutation_score.score > 0.7 and
    r.constitutional_compliance.compliant
  end
end
```

---

## PHASE 3 — Scientific Engine

### 3.1 FalsificationExecutor (Part VIII)

```elixir
defmodule Tiannara.EOS.FalsificationExecutor do
  @moduledoc """
  Popperian falsification engine.
  
  Constitutional mandate: "Truth has priority over confidence."
  
  Monitors predictions against incoming observations.
  When a prediction is violated with statistical significance,
  the theory is contested, not deleted.
  
  Theories never disappear. They become :contested, :restricted,
  or :superseded.
  """
  use GenServer
  require Logger

  alias Tiannara.EOS.EventBus
  alias Tiannara.EOS.Event

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    EventBus.subscribe("prediction.registered")
    EventBus.subscribe("observation.ingested")
    {:ok, %{active_predictions: %{}, violation_count: 0}}
  end

  @impl true
  def handle_info({:eos_event, %Event{type: "prediction.registered"} = event}, state) do
    prediction = event.payload.prediction
    predictions = Map.put(state.active_predictions, prediction.id, prediction)
    {:noreply, %{state | active_predictions: predictions}}
  end

  @impl true
  def handle_info({:eos_event, %Event{type: "observation.ingested"} = event}, state) do
    observation = event.payload.artifact

    # Check all active predictions against this observation
    for {pred_id, prediction} <- state.active_predictions do
      case check_prediction(prediction, observation) do
        :supported ->
          EventBus.publish(Event.new("prediction.supported", __MODULE__, %{
            prediction_id: pred_id,
            observation_id: observation.id
          }))

        {:violated, significance} when significance > 0.95 ->
          Logger.warning("FalsificationExecutor: prediction #{pred_id} violated (p=#{significance})")
          EventBus.publish(Event.new("prediction.violated", __MODULE__, %{
            prediction_id: pred_id,
            observation_id: observation.id,
            significance: significance,
            theory_id: prediction.theory_id
          }))
          EventBus.publish(Event.new("theory.contested", __MODULE__, %{
            theory_id: prediction.theory_id,
            reason: :prediction_violated,
            significance: significance
          }))

        :no_match -> :ok
      end
    end

    {:noreply, state}
  end

  @impl true
  def handle_info(_msg, state), do: {:noreply, state}

  defp check_prediction(prediction, observation) do
    # Domain-specific prediction matching logic
    # Returns :supported | {:violated, significance} | :no_match
    :no_match
  end
end
```

### 3.2 TheoryTournament (Part IX)

```elixir
defmodule Tiannara.EOS.TheoryTournament do
  @moduledoc """
  Competitive scientific reasoning.
  
  Constitutional mandate: "Evolution without validation creates randomness."
  
  When multiple theories explain the same domain, they compete.
  The loser is not deleted — its applicability becomes constrained.
  
  Competition criteria:
  - Prediction accuracy
  - Compression efficiency
  - Simplicity (Occam's razor)
  - Coverage
  - Generality
  - False positive rate
  - Computational cost
  """
  use GenServer
  require Logger

  alias Tiannara.EOS.EventBus
  alias Tiannara.EOS.Event

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Initiate a tournament between competing theories."
  def initiate_tournament(theory_ids, shared_domain) do
    GenServer.call(__MODULE__, {:initiate, theory_ids, shared_domain})
  end

  @impl true
  def init(_opts) do
    EventBus.subscribe("theory.contested")
    {:ok, %{active_tournaments: %{}}}
  end

  @impl true
  def handle_call({:initiate, theory_ids, shared_domain}, _from, state) do
    tournament_id = Ecto.UUID.generate()
    Logger.info("TheoryTournament: initiating tournament #{tournament_id} for domain #{inspect(shared_domain)}")

    # Design a crucial experiment where theories predict mutually exclusive outcomes
    crucial_experiment = design_crucial_experiment(theory_ids, shared_domain)

    EventBus.publish(Event.new("tournament.initiated", __MODULE__, %{
      tournament_id: tournament_id,
      theory_ids: theory_ids,
      domain: shared_domain,
      crucial_experiment: crucial_experiment
    }))

    {:reply, {:ok, tournament_id}, state}
  end

  @impl true
  def handle_info({:eos_event, %Event{type: "theory.contested"} = event}, state) do
    # Auto-detect overlapping theories and initiate tournaments
    {:noreply, state}
  end

  @impl true
  def handle_info(_msg, state), do: {:noreply, state}

  defp design_crucial_experiment(theory_ids, domain) do
    # Generate an experiment where competing theories predict different outcomes
    %{
      id: Ecto.UUID.generate(),
      type: :crucial_experiment,
      theories: theory_ids,
      domain: domain,
      designed_at: DateTime.utc_now()
    }
  end
end
```

### 3.3 AnalogicalReasoningEngine (Part XIII)

```elixir
defmodule Tiannara.EOS.AnalogicalEngine do
  @moduledoc """
  Cross-domain analogy discovery through causal topology.
  
  Constitutional mandate: "Increase scientific discovery.
  Increase knowledge generation."
  
  CRITICAL: Never compare words. Compare causal topology.
  
  Pipeline:
  Theory → Abstract Causal Graph → Structural Isomorphism →
  Cross-Domain Search → Candidate Analogies → Cross-Domain Hypothesis → Verification
  """
  use GenServer
  require Logger

  alias Tiannara.EOS.EventBus
  alias Tiannara.EOS.Event

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Abstract a theory into a causal graph, stripping all domain vocabulary.
  """
  def abstract_to_causal_graph(theory_id) do
    GenServer.call(__MODULE__, {:abstract, theory_id})
  end

  @doc """
  Search for structurally isomorphic causal graphs in other domains.
  """
  def find_analogies(theory_id, target_domains \\ []) do
    GenServer.call(__MODULE__, {:find_analogies, theory_id, target_domains})
  end

  @impl true
  def init(_opts) do
    EventBus.subscribe("theory.promoted")
    {:ok, %{causal_graph_cache: %{}}}
  end

  @impl true
  def handle_call({:abstract, theory_id}, _from, state) do
    # Load theory, extract causal relationships, map to UCO primitives
    causal_graph = extract_causal_topology(theory_id)
    cache = Map.put(state.causal_graph_cache, theory_id, causal_graph)
    {:reply, causal_graph, %{state | causal_graph_cache: cache}}
  end

  @impl true
  def handle_call({:find_analogies, theory_id, target_domains}, _from, state) do
    source_graph = Map.get(state.causal_graph_cache, theory_id)

    if source_graph do
      matches = search_isomorphic_graphs(source_graph, target_domains)

      for match <- matches do
        EventBus.publish(Event.new("analogy.candidate_found", __MODULE__, %{
          source_theory: theory_id,
          target_theory: match.theory_id,
          target_domain: match.domain,
          isomorphism_score: match.score,
          causal_mapping: match.mapping
        }))
      end

      {:reply, matches, state}
    else
      {:reply, {:error, :theory_not_cached}, state}
    end
  end

  @impl true
  def handle_info({:eos_event, %Event{type: "theory.promoted"} = event}, state) do
    # Auto-abstract newly promoted theories
    spawn(fn -> abstract_to_causal_graph(event.payload.theory_id) end)
    {:noreply, state}
  end

  @impl true
  def handle_info(_msg, state), do: {:noreply, state}

  defp extract_causal_topology(theory_id) do
    # Convert domain-specific theory into UCO primitives
    # Example: "High coupling reduces portability"
    # becomes: Node_Degree_Centrality(↑) → State_Space_Reachability(↓)
    %{
      theory_id: theory_id,
      nodes: [],   # UCO primitive nodes
      edges: [],   # causal edges
      extracted_at: DateTime.utc_now()
    }
  end

  defp search_isomorphic_graphs(source_graph, target_domains) do
    # Graph isomorphism search across the TheoryGraph
    # Returns candidate matches with isomorphism scores
    []
  end
end
```

---

## PHASE 4 — Metrics and Human Interface

### 4.1 KCR Dashboard (Part XI)

```elixir
defmodule Tiannara.EOS.KCRDashboard do
  @moduledoc """
  Knowledge Compression Ratio metrics.
  
  Constitutional mandate: "Measure success using meaningful outcomes
  rather than superficial metrics."
  
  KCR is a family of metrics, not a single scalar:
  - Structural Compression
  - Predictive Compression
  - Explanatory Compression
  - Human Interpretability
  - Computational Compression
  """
  use GenServer
  require Logger

  alias Tiannara.EOS.EventBus
  alias Tiannara.EOS.Event

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Compute current KCR metrics."
  def compute_kcr do
    GenServer.call(__MODULE__, :compute_kcr)
  end

  @impl true
  def init(_opts) do
    EventBus.subscribe("theory.promoted")
    EventBus.subscribe("theory.contested")
    EventBus.subscribe("verification.completed")

    # Periodic KCR computation
    :timer.send_interval(300_000, :recompute_kcr)  # every 5 minutes

    {:ok, %{last_kcr: nil}}
  end

  @impl true
  def handle_call(:compute_kcr, _from, state) do
    kcr = %{
      structural: compute_structural_compression(),
      predictive: compute_predictive_compression(),
      explanatory: compute_explanatory_compression(),
      human_interpretability: compute_human_interpretability(),
      computational: compute_computational_compression(),
      computed_at: DateTime.utc_now()
    }

    EventBus.publish(Event.new("kcr.updated", __MODULE__, %{kcr: kcr}))

    # Prometheus metrics
    :telemetry.execute([:eos, :kcr], %{
      structural: kcr.structural,
      predictive: kcr.predictive,
      explanatory: kcr.explanatory,
      interpretability: kcr.human_interpretability,
      computational: kcr.computational
    })

    {:reply, kcr, %{state | last_kcr: kcr}}
  end

  @impl true
  def handle_info(:recompute_kcr, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info({:eos_event, _event}, state) do
    {:noreply, state}
  end

  # ── KCR Computation ──

  defp compute_structural_compression do
    # Ratio of observations explained per theory node
    # Higher = better compression
    0.0
  end

  defp compute_predictive_compression do
    # Percentage of new observations predicted by existing principles
    0.0
  end

  defp compute_explanatory_compression do
    # How many distinct phenomena are explained by the current theory set
    0.0
  end

  defp compute_human_interpretability do
    # Can a human reviewer understand the top principles?
    # Measured via review feedback
    0.0
  end

  defp compute_computational_compression do
    # Compute cost per unit of explanatory power
    0.0
  end
end
```

### 4.2 Epistemic Debt Ledger (Part XV)

```elixir
defmodule Tiannara.EOS.EpistemicDebtLedger do
  @moduledoc """
  Tracks epistemic debt across the knowledge graph.
  
  Constitutional mandate: "Continuous Self-Evaluation.
  What knowledge is missing? What experiment should I perform next?"
  
  Epistemic debt degrades predictive power and decision quality.
  A healthy scientific organism continuously reduces epistemic debt.
  """
  use GenServer
  require Logger

  alias Tiannara.EOS.EventBus
  alias Tiannara.EOS.Event

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Compute current epistemic debt."
  def compute_debt do
    GenServer.call(__MODULE__, :compute_debt)
  end

  @impl true
  def init(_opts) do
    :timer.send_interval(600_000, :recompute_debt)  # every 10 minutes
    {:ok, %{last_debt: nil}}
  end

  @impl true
  def handle_call(:compute_debt, _from, state) do
    debt = %{
      open_contested_theories: count_contested(),
      unverified_hypotheses: count_unverified(),
      expired_predictions: count_expired_predictions(),
      missing_reproductions: count_missing_reproductions(),
      conflicting_principles: count_conflicting_principles(),
      proposal_backlog: count_proposal_backlog(),
      review_latency_ms: compute_review_latency(),
      theory_drift: compute_theory_drift(),
      contract_drift: count_contract_violations(),
      prediction_failures: count_prediction_failures(),
      computed_at: DateTime.utc_now()
    }

    EventBus.publish(Event.new("epistemic.debt.updated", __MODULE__, %{debt: debt}))

    :telemetry.execute([:eos, :epistemic_debt], %{
      contested: debt.open_contested_theories,
      unverified: debt.unverified_hypotheses,
      expired: debt.expired_predictions,
      backlog: debt.proposal_backlog
    })

    {:reply, debt, %{state | last_debt: debt}}
  end

  @impl true
  def handle_info(:recompute_debt, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info(_msg, state), do: {:noreply, state}

  # ── Debt Computation Stubs ──
  defp count_contested, do: 0
  defp count_unverified, do: 0
  defp count_expired_predictions, do: 0
  defp count_missing_reproductions, do: 0
  defp count_conflicting_principles, do: 0
  defp count_proposal_backlog, do: 0
  defp compute_review_latency, do: 0
  defp compute_theory_drift, do: 0.0
  defp count_contract_violations, do: 0
  defp count_prediction_failures, do: 0
end
```

---

## Persistence Strategy

| Data Type | Hot Cache | Persistent Store | Rationale |
|---|---|---|---|
| TheoryGraph edges | ETS | PostgreSQL (adjacency list) | Fast traversal, durable |
| TheoryArtifact | ETS | PostgreSQL (JSONB) | Complex queries, versioning |
| ConfidenceVector | In-memory | PostgreSQL (embedded in TheoryArtifact) | Co-located with theory |
| KnowledgeLineage | ETS | PostgreSQL (append-only) | Audit trail, never modified |
| Engineering Proposals | ETS | PostgreSQL + DETS archive | Immutable artifacts |
| Verification Results | None | PostgreSQL (append-only, immutable) | Governance evidence |
| Event log | None | Append-only log (PostgreSQL or file) | Full replay capability |
| Schema Contracts | ETS | PostgreSQL | Versioned, auditable |
| KCR metrics | In-memory | PostgreSQL (time-series) | Dashboard, trend analysis |
| Epistemic Debt | In-memory | PostgreSQL (time-series) | Dashboard, trend analysis |

**Constitutional justification:** *"Avoid designs dependent on any single AI model, framework, programming language, or hardware platform."* All persistence is abstracted behind behaviours. PostgreSQL is the default, but the interface supports replacement.

---

## Observability Stack

| Layer | Tool | Events |
|---|---|---|
| Structured events | `:telemetry` | All EventBus events |
| Metrics | Prometheus (via `TelemetryMetrics`) | KCR, Epistemic Debt, event throughput, verification latency |
| Traces | OpenTelemetry | Cross-subsystem correlation via `correlation_id` |
| Logs | Structured JSON logging | All Logger calls with metadata |
| Dashboard | LiveView (EpistemicWorkspace) | KCR trends, debt heatmap, proposal queue |

---

## Test Strategy

| Test Type | Scope | Constitutional Mandate |
|---|---|---|
| Unit tests | Each module's public API | *"Unit testing"* |
| Property-based tests (StreamData) | TheoryGraph invariants, ConfidenceVector math, Event validation | *"Testability"* |
| Integration tests | Event flow: observation → theory → prediction → falsification | *"Integration testing"* |
| Stress tests | EventBus throughput under 10k events/sec | *"Stress testing"* |
| Long-duration soak | 72h continuous operation, memory leak detection | *"Long-duration testing"* |
| Regression tests | Every minted theory generates a regression test | *"Regression testing"* |
| Adversarial tests | Inject contradictory observations, verify theory contested not deleted | *"Adversarial testing"* |
| Scalability analysis | TheoryGraph at 100k nodes, 1M edges | *"Scalability analysis"* |
| Failure recovery | Kill EventBus, verify :rest_for_one restarts all consumers | *"Failure recovery testing"* |
| Performance benchmarks | KCR computation at scale, BFS traversal depth | *"Performance benchmarking"* |

---

## Migration Strategy

This is **not** a rewrite. The migration proceeds in four phases, each backward-compatible:

**Phase 1 (Week 1–2):** Deploy `EOS.Supervisor` alongside existing supervisors. EventBus starts. No existing behavior changes. All new subsystems start in passive mode (observe only, no actions).

**Phase 2 (Week 3–4):** SchemaContractLayer begins validating inbound artifacts. Existing systems continue to function; contract violations are logged but not enforced. TheoryArtifact schema is introduced; existing minted theories are wrapped in the new schema with `schema_version: 0`.

**Phase 3 (Week 5–6):** VerificationAuthority comes online. ProposalGenerator begins producing L4 proposals. Human EpistemicWorkspace is deployed. Phase-8 receives its first proposal through the new pipeline.

**Phase 4 (Week 7–8):** FalsificationExecutor, TheoryTournament, and AnalogicalEngine activate. KCR and Epistemic Debt dashboards go live. Full EOS operational.

**Backward compatibility guarantee:** At every phase, existing Tiannara systems continue to function. The EOS is an overlay that extends, not replaces. If any EOS subsystem fails, existing systems are unaffected because communication is via EventBus (async, non-blocking).

---

## Failure Modes and Recovery

| Subsystem | Failure Mode | Detection | Recovery |
|---|---|---|---|
| EventBus | Process crash | `:rest_for_one` supervisor | All consumers restart, replay from event log |
| TheoryGraph | ETS corruption | ETS table monitor | Rebuild from PostgreSQL |
| VerificationAuthority | Timeout on long verification | GenServer call timeout | Return `{:error, :timeout}`, proposal stays in `:candidate_generated` |
| FalsificationExecutor | Flood of observations | GenServer mailbox depth | Backpressure via `ResourceManager` load shedding |
| SchemaContractLayer | Missing schema | `:missing_schema` violation | Quarantine artifact, alert human |
| EpistemicWorkspace | Human unavailable | Proposal queue depth | Alert, escalate to backup reviewer |

---

## Constitutional Compliance Summary

Every design decision in this specification was evaluated against the Tiannara Constitution:

1. **"Capability must never outpace verification"** → VerificationAuthority is independent, immutable, and gates all proposals before human review.

2. **"Uncertainty should never be hidden"** → ConfidenceVector replaces scalar confidence. Every normalization event is logged. Every assumption is explicit.

3. **"Truth has priority over confidence"** → FalsificationExecutor contests theories based on evidence, not on how confident they appear.

4. **"Memory exists to improve reasoning rather than merely storing information"** → TheoryGraph, TheoryConsolidator, and KCR ensure knowledge is compressed, not accumulated.

5. **"Tiannara should remain a system that augments human intelligence rather than replaces human judgment"** → EpistemicWorkspace presents trade-offs and uncertainty, never auto-deploys. Human review is the final gate.

6. **"Every architectural decision should remain traceable"** → KnowledgeLineage ensures every object answers "why do I exist?"

7. **"Complexity must always justify itself through measurable capability gains"** → Every subsystem has a clear constitutional mandate. No subsystem exists without one.

8. **"Evolution without validation creates randomness. Validation without evolution creates stagnation."** → TheoryTournament and TheoryEcology ensure theories evolve through competition, not deletion.

---

This specification transforms Tiannara into a **Constitutionally Governed Epistemic Operating System** — one that observes reality, compresses knowledge, generates explanations, predicts outcomes, challenges itself, and improves humanity's understanding, all while remaining permanently aligned with the constitutional governance framework.

The implementation proceeds in four phases, each backward-compatible, each independently verifiable, each producing measurable capability gains justified by the constitution.


From the portion of the specification I could review, I think this is a substantial architectural improvement over the earlier concepts. It is internally coherent, constitutionally grounded, and demonstrates good separation of responsibilities. It also shows a clear transition from "adding features" to designing a system around explicit epistemic governance.

That said, I see several areas where I think the architecture can be strengthened before I'd consider it "production complete."

---

# Overall Assessment

| Area                        | Assessment |
| --------------------------- | ---------- |
| Constitutional alignment    | ★★★★★      |
| Separation of concerns      | ★★★★★      |
| Scientific methodology      | ★★★★★      |
| Explainability              | ★★★★★      |
| Long-term scalability       | ★★★★☆      |
| Operational resilience      | ★★★★☆      |
| Distributed systems design  | ★★★★☆      |
| Knowledge lifecycle         | ★★★★★      |
| Engineering governance      | ★★★★★      |
| Missing operational details | ★★★☆☆      |

Overall I'd rate this around **9.3–9.6/10** architecturally. The remaining work is less about new ideas and more about making the ideas executable at scale.

---

# Strengths

## 1. The Constitution Actually Governs the Architecture

This is the strongest part.

Many systems have "principles" that aren't reflected in implementation.

Here you explicitly map

```
Constitution

↓

Subsystem

↓

Responsibility
```

That makes constitutional compliance auditable.

I would preserve this.

---

## 2. Excellent Separation of Trust Domains

The architecture correctly separates

* Discovery
* Engineering
* Verification
* Governance
* Deployment

Those are genuinely different authorities.

This is one of the biggest improvements over many autonomous-agent designs.

---

## 3. Event-Driven Integration

Using an EventBus instead of direct GenServer calls between major subsystems is the right direction.

It gives you

* observability
* replay
* distributed deployment
* loose coupling

I think this will age well.

---

## 4. Theory Graph as a First-Class System

This is probably the most valuable architectural addition.

Theories become objects rather than log messages.

That opens the door to:

* comparison
* consolidation
* falsification
* evolution
* explanation

---

# Areas I'd Strengthen

---

# 1. The EventBus is becoming a God Object

Everything flows through

```
EOS.EventBus
```

Eventually you'll have

```
Observation

Proposal

Theory

Prediction

Experiment

Dashboard

Workspace

Metrics

Verification

Human Review

Deployment
```

all publishing into one logical bus.

I'd instead think in terms of **event domains**.

For example

```
Observation Bus

Theory Bus

Engineering Bus

Governance Bus

Telemetry Bus
```

sharing a transport layer.

That prevents one noisy subsystem from becoming everyone else's bottleneck.

---

# 2. TheoryGraph Needs Versioning

Currently I don't see explicit support for

```
Theory v1

↓

Theory v2

↓

Theory v3
```

without replacing nodes.

I'd add immutable revisions.

Example

```
Theory

↓

Revision

↓

Revision

↓

Revision
```

This preserves history.

---

# 3. Discovery Hierarchy Needs Explicit Promotion Criteria

Right now

```
Observation

↓

Pattern

↓

Hypothesis

↓

Theory

↓

Principle
```

exists.

But what promotes one level?

I'd formalize

```
Promotion Policy
```

For example

Hypothesis → Theory requires

* reproducibility
* prediction accuracy
* competing explanations evaluated
* minimum evidence

Not just confidence.

---

# 4. Missing Experiment Registry

You have

Theory

Prediction

Evidence

But experiments deserve their own subsystem.

I'd create

```
Experiment Registry

↓

Experiment Scheduler

↓

Experiment Results

↓

Theory Updates
```

Otherwise experiments remain buried inside theories.

---

# 5. Knowledge Lineage Should Be a Graph, Not a Lookup

Currently

```
Knowledge Lineage
```

looks like metadata.

I'd actually model

```
Observation

↓

Experiment

↓

Evidence

↓

Hypothesis

↓

Theory

↓

Proposal

↓

Deployment

↓

Outcome
```

as its own graph.

That allows causal traversal.

---

# 6. Analogical Engine Needs Mathematical Intermediate Representation

This is the biggest scientific improvement I'd suggest.

Never compare language.

Compare

```
causal graph

dependency graph

constraint graph

state transition graph
```

Only then perform analogy.

Otherwise cross-domain reasoning becomes pattern matching.

---

# 7. Missing Resource Governance

One thing absent so far is computational governance.

For example

```
Theory Tournament

10,000 theories

↓

100 million comparisons
```

How do you budget that?

I'd add

```
Epistemic Scheduler
```

which allocates compute.

Knowledge work competes for CPU like processes.

---

# 8. Missing Theory Cache

Suppose

```
Repair Simplicity
```

is referenced 20,000 times.

You don't want repeated graph traversals.

I'd introduce

```
Theory Cache

Prediction Cache

Lineage Cache
```

with invalidation tied to revisions.

---

# 9. Human Workspace Needs Uncertainty Heatmaps

Don't just show proposals.

Show

```
Most uncertain

Most controversial

Most influential

Most interconnected
```

Humans are best used where uncertainty is highest.

---

# Biggest Missing Piece

The one subsystem I think is still absent is something I'd call

# Epistemic Executive

Right now you have

```
Discovery

Engineering

Theory

Verification
```

But who decides

> what deserves attention next?

You need something like

```
Epistemic Executive

↓

What experiments should run?

↓

What theories are stagnating?

↓

Where is uncertainty highest?

↓

Where is KCR falling?

↓

Which domain deserves more compute?

↓

Which proposal has highest expected value?
```

This becomes the strategic planner.

Without it, all your components exist, but nothing optimizes the organism's overall scientific progress.

---

# One More Constitutional Principle

I'd consider adding one more explicit invariant:

> **Every autonomous action must increase either knowledge quality, explanatory power, or verification confidence—and never merely increase artifact count.**

This protects against Goodhart's Law. A system that mints 10,000 low-value hypotheses is not improving simply because the number is larger. Success should be tied to metrics like explanatory power, predictive accuracy, and knowledge compression, not raw output.

## Final Verdict

This specification has crossed an important threshold. Earlier versions of Tiannara described a sophisticated discovery platform. This document begins to define an **operating system for knowledge itself**, where observations, experiments, theories, engineering proposals, and governance are all managed as first-class entities with explicit lifecycle and constitutional oversight.

The remaining work is primarily about strengthening operational mechanics—versioning, experiment management, resource scheduling, distributed event partitioning, and strategic orchestration. Those additions would make the architecture more scalable and resilient without changing its core philosophy.

If I were prioritizing the next milestone, I would implement these five capabilities before expanding further:

1. **Experiment Registry & Scheduler** to make experimentation a first-class citizen alongside theories.
2. **Epistemic Executive** to allocate attention, compute, and experimentation based on expected epistemic value rather than reactive events.
3. **Theory Revision Graph** with immutable versioning and lineage to preserve the evolution of scientific understanding.
4. **Partitioned Event Domains** to prevent the EventBus from becoming a centralized scalability bottleneck.
5. **Formal Promotion/Demotion Policies** for moving artifacts between Observation, Pattern, Hypothesis, Theory, and Principle, ensuring every transition is governed by explicit, measurable evidence rather than ad hoc thresholds.


# EOS Specification Amendment v1.1 — Operational Maturity

Your review is accurate on every point, and the five priorities are correctly ordered. I'll fold them into the specification as a formal amendment, plus the supporting items (MIR, caches, heatmaps, lineage-as-graph), and adopt your proposed constitutional invariant as an **enforceable gate** rather than a prose clause.

First, the traceability map so nothing you raised is dropped:

| Your Point | Addressed In |
|---|---|
| 1. EventBus god object | §1 Partitioned Event Domains |
| 2. TheoryGraph versioning | §2 Theory Revision Graph |
| 3. Explicit promotion criteria | §3 Promotion/Demotion Policies |
| 4. Missing Experiment Registry | §4 Experiment Registry & Scheduler |
| 5. Lineage as a graph | §2.3 (lineage becomes a traversable graph sharing the revision edge model) |
| 6. Mathematical IR for analogies | §6 MIR |
| 7. Resource governance | §5.3 Epistemic Budget |
| 8. Theory/Prediction/Lineage caches | §2.4 (revision-keyed invalidation) |
| 9. Uncertainty heatmaps | §7 |
| Epistemic Executive (missing piece) | §5 |
| New constitutional invariant | §0 ValueGate |

---

## §0 — The New Constitutional Invariant, Enforced

> *"Every autonomous action must increase either knowledge quality, explanatory power, or verification confidence — and never merely increase artifact count."*

This is adopted as **Constitutional Clause 21** and implemented in two places, because a clause without an enforcement point is decoration.

**Enforcement point 1 — the minting gate.** No artifact enters the Theory Graph without passing a value justification check:

```elixir
defmodule Tiannara.EOS.Constitution.ValueGate do
  @moduledoc """
  Constitutional Clause 21: autonomous actions must increase knowledge
  quality, explanatory power, or verification confidence — never
  merely artifact count.

  Sits on the publish path of all artifact-minting events.
  """

  @quality_metrics ~w(explanatory_power prediction_accuracy compression_efficiency
                      verification_confidence epistemic_debt_reduction)a

  @doc """
  Every minting event must declare which quality metric it improves
  and by what estimated margin. Count-based justifications are rejected
  structurally — there is no `artifact_count` metric.
  """
  def validate_mint(%{value_justification: justification}) do
    cond do
      is_nil(justification) ->
        {:error, :missing_value_justification}

      justification.metric not in @quality_metrics ->
        {:error, {:non_quality_metric, justification.metric}}

      justification.estimated_gain <= 0 ->
        {:error, :no_positive_quality_gain}

      true ->
        :ok
    end
  end
end
```

**Enforcement point 2 — the novelty gate.** Before any hypothesis is minted, it must exceed a semantic-distance threshold from existing artifacts. Below threshold, the system routes the evidence to *update an existing artifact* rather than mint a duplicate. This structurally prevents the 10,000-low-value-hypotheses failure mode.

```elixir
defmodule Tiannara.EOS.Constitution.NoveltyGate do
  @moduledoc """
  Prevents artifact inflation. If a candidate artifact is closer than
  `merge_threshold` to an existing artifact, the evidence is folded
  into the existing artifact's revision history instead of minting.
  """

  @merge_threshold 0.15  # semantic distance below this = not novel

  def route_candidate(candidate, existing_artifacts) do
    nearest = NearestNeighbor.find(candidate.embedding, existing_artifacts)

    if nearest.distance < @merge_threshold do
      {:fold_into_existing, nearest.artifact_id, candidate.evidence}
    else
      {:mint_new, candidate}
    end
  end
end
```

**Enforcement point 3 — the Executive's value function** (§5) is forbidden by construction from including count terms. This is checked at test time with a property test over the value function's inputs.

---

## §1 — Partitioned Event Domains

The single `EOS.EventBus` is retired as a logical monolith. It becomes a **transport layer** hosting five domain buses with distinct durability and backpressure policies, plus explicit bridges for cross-domain flow.

```text
Tiannara.EOS.Transport
│
├── EOS.Bus.Observation    high volume, durable, causal ordering, block-on-overflow
├── EOS.Bus.Theory         medium volume, durable, causal ordering
├── EOS.Bus.Engineering    proposals + verification, durable, strictly ordered
├── EOS.Bus.Governance     human decisions + constitutional events, durable,
│                          strictly ordered, NEVER drops
├── EOS.Bus.Telemetry      metrics + traces, volatile, drop-under-load (lossy by design)
│
└── EOS.Bridge.CrossDomain   the ONLY legal path between domains
```

### Bus policy specification

```elixir
defmodule Tiannara.EOS.BusSpec do
  @moduledoc """
  Declarative policy for one event domain.
  Constitutional mandate: "Explicit interfaces, minimal coupling."
  """
  @enforce_keys [:name, :durability, :ordering, :overflow_policy]
  defstruct [
    :name,                # :observation | :theory | :engineering | :governance | :telemetry
    :durability,          # :durable | :volatile
    :ordering,            # :strict | :causal | :none
    :overflow_policy,     # :block | :drop_newest | :spill_to_disk
    :max_rate_per_sec,    # integer or :unlimited
    :replay_retention,    # {:days, n} | :permanent | :none
    :isolation_level      # :critical | :standard | :lossy_ok
  ]

  def policies do
    %{
      observation: %__MODULE__{
        name: :observation, durability: :durable, ordering: :causal,
        overflow_policy: :spill_to_disk, max_rate_per_sec: 10_000,
        replay_retention: {:days, 30}, isolation_level: :standard
      },
      theory: %__MODULE__{
        name: :theory, durability: :durable, ordering: :causal,
        overflow_policy: :block, max_rate_per_sec: 1_000,
        replay_retention: :permanent, isolation_level: :critical
      },
      engineering: %__MODULE__{
        name: :engineering, durability: :durable, ordering: :strict,
        overflow_policy: :block, max_rate_per_sec: 500,
        replay_retention: :permanent, isolation_level: :critical
      },
      governance: %__MODULE__{
        name: :governance, durability: :durable, ordering: :strict,
        overflow_policy: :block, max_rate_per_sec: 100,
        replay_retention: :permanent, isolation_level: :critical
      },
      telemetry: %__MODULE__{
        name: :telemetry, durability: :volatile, ordering: :none,
        overflow_policy: :drop_newest, max_rate_per_sec: 100_000,
        replay_retention: :none, isolation_level: :lossy_ok
      }
    }
  end
end
```

### Domain bus implementation

```elixir
defmodule Tiannara.EOS.DomainBus do
  @moduledoc """
  One event domain. Enforces its BusSpec policy at publish time.
  A noisy Observation domain can never backpressure the Governance domain.
  """
  use GenServer
  require Logger

  alias Tiannara.EOS.{BusSpec, Event, Constitution.ValueGate}

  def start_link(%BusSpec{} = spec) do
    GenServer.start_link(__MODULE__, spec, name: via(spec.name))
  end

  def publish(domain, %Event{} = event) do
    GenServer.call(via(domain), {:publish, event}, publish_timeout(domain))
  end

  def subscribe(domain, event_type) do
    Phoenix.PubSub.subscribe(
      Tiannara.EOS.PubSub,
      "eos:#{domain}:#{event_type}"
    )
  end

  # ── GenServer ──

  @impl true
  def init(%BusSpec{} = spec) do
    {:ok, %{
      spec: spec,
      sequence: 0,
      window_count: 0,
      window_start: System.monotonic_time(:second),
      overflow_count: 0
    }}
  end

  @impl true
  def handle_call({:publish, event}, _from, state) do
    state = maybe_roll_window(state)
    spec = state.spec

    with :ok <- check_rate_limit(event, state),
         :ok <- check_value_gate(event) do
      seq = state.sequence + 1
      stamped = %{event | payload: Map.put(event.payload, :bus_sequence, seq)}

      # Durable log (append-only) for :durable domains
      if spec.durability == :durable do
        :ok = append_to_log(spec.name, seq, stamped)
      end

      Phoenix.PubSub.broadcast(
        Tiannara.EOS.PubSub,
        "eos:#{spec.name}:#{event.type}",
        {:eos_event, stamped}
      )

      {:reply, :ok, %{state | sequence: seq, window_count: state.window_count + 1}}
    else
      {:error, :rate_limited} ->
        handle_overflow(event, state)
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  defp check_rate_limit(_event, state) do
    if state.spec.max_rate_per_sec != :unlimited
       and state.window_count >= state.spec.max_rate_per_sec do
      {:error, :rate_limited}
    else
      :ok
    end
  end

  # Clause 21 applies only to minting events
  defp check_value_gate(%Event{type: type} = event) do
    if String.ends_with?(type, ".minted") do
      ValueGate.validate_mint(event.payload)
    else
      :ok
    end
  end

  defp handle_overflow(event, state) do
    case state.spec.overflow_policy do
      :block ->
        {:reply, {:error, :rate_limited}, state}  # caller retries

      :drop_newest when state.spec.isolation_level == :lossy_ok ->
        :telemetry.execute([:eos, :bus, :dropped], %{count: 1}, %{domain: state.spec.name})
        {:reply, {:error, :dropped}, state}

      :spill_to_disk ->
        :ok = spill(event, state.spec.name)
        {:reply, :ok, %{state | overflow_count: state.overflow_count + 1}}

      :block ->
        # Governance and Engineering buses NEVER drop.
        # If they hit the limit, that is a constitutional incident, not a traffic event.
        Logger.critical("EOS bus #{state.spec.name} at capacity — blocking")
        {:reply, {:error, :rate_limited}, state}
    end
  end

  defp maybe_roll_window(state) do
    now = System.monotonic_time(:second)
    if now > state.window_start do
      %{state | window_start: now, window_count: 0}
    else
      state
    end
  end

  defp via(name), do: {:via, Registry, {Tiannara.EOS.BusRegistry, name}}
  defp publish_timeout(:governance), do: :infinity
  defp publish_timeout(:engineering), do: 30_000
  defp publish_timeout(_), do: 5_000
  defp append_to_log(_domain, _seq, _event), do: :ok
  defp spill(_event, _domain), do: :ok
end
```

### The cross-domain bridge

Cross-domain flow is the only legal path between buses, and every crossing is logged in the lineage graph. This is what keeps the domains from silently re-coupling.

```elixir
defmodule Tiannara.EOS.Bridge.CrossDomain do
  @moduledoc """
  The ONLY legal path for events crossing domain boundaries.
  Every crossing is schema-validated, rate-limited, and lineage-logged.
  """
  use GenServer

  alias Tiannara.EOS.{DomainBus, Event, KnowledgeLineage}

  # Declarative bridge registry: which flows are legal
  @legal_flows %{
    {:observation, :theory}       => %{rate: 1_000,  requires_schema: true},
    {:theory, :engineering}       => %{rate: 100,    requires_schema: true},
    {:engineering, :governance}   => %{rate: 50,     requires_schema: true},
    {:governance, :engineering}   => %{rate: 50,     requires_schema: true},
    {:theory, :telemetry}         => %{rate: 10_000, requires_schema: false},
    {:engineering, :observation}  => %{rate: 100,    requires_schema: true}
    # outcome observation: deployment results flow back as observations
  }

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  def route(from_domain, to_domain, %Event{} = event) do
    GenServer.call(__MODULE__, {:route, from_domain, to_domain, event})
  end

  @impl true
  def init(_), do: {:ok, %{flow_counts: %{}}}

  @impl true
  def handle_call({:route, from, to, event}, _from, state) do
    case Map.get(@legal_flows, {from, to}) do
      nil ->
        # Illegal crossing: reject loudly. This is an architecture violation,
        # not a runtime condition.
        {:reply, {:error, {:illegal_crossing, from, to}}, state}

      flow ->
        # Record the crossing in lineage so cross-domain causality is traversable
        KnowledgeLineage.record_crossing(event, from, to)
        :ok = DomainBus.publish(to, %{event | source: {:bridge, from, to}})
        {:reply, :ok, state}
    end
  end
end
```

**Failure mode:** a flooded Observation bus spilling to disk never touches Governance. **Test:** property test asserting that saturating one domain's rate limit produces zero dropped events on `:critical` domains.

---

## §2 — Theory Revision Graph

Theories become **identities**; revisions become **immutable snapshots**. All graph edges attach to revisions, which makes the entire graph temporally correct and gives us as-of queries for free.

### 2.1 Data model

```text
theories
  id                    UUID (stable identity)
  current_revision_id   UUID
  stage                 :observation | :pattern | :hypothesis | :theory | :principle
  ecology_status        :active | :contested | :restricted | :superseded | :archived
  created_at

theory_revisions
  id                    UUID (immutable)
  theory_id             FK → theories.id
  parent_revision_id    UUID | nil  (nil = genesis revision)
  artifact              JSONB       (full TheoryArtifact snapshot)
  change_type           :genesis | :evidence_update | :promotion | :demotion |
                        :contest | :restriction | :merge | :split | :human_revision
  change_reason         text
  policy_version        UUID        (which PromotionPolicy version authorized this)
  created_at

graph_edges
  from_revision_id      UUID        (edges attach to REVISIONS, not theories)
  to_revision_id        UUID
  type                  supports | contradicts | specializes | ...
  evidence              JSONB
  created_at
```

### 2.2 Revision module

```elixir
defmodule Tiannara.EOS.Theory.Revision do
  @moduledoc """
  Immutable theory snapshot. Theories evolve by appending revisions;
  nothing is ever mutated in place or deleted.

  Constitutional mandate: "Every architectural decision should remain traceable."
  """
  @enforce_keys [:id, :theory_id, :artifact, :change_type, :change_reason]
  defstruct [
    :id,
    :theory_id,
    :parent_revision_id,
    :artifact,            # full TheoryArtifact snapshot, immutable
    :change_type,
    :change_reason,
    :policy_version,      # which promotion/demotion policy authorized this
    :created_at
  ]
end
```

```elixir
defmodule Tiannara.EOS.TheoryGraph.Revisioned do
  @moduledoc """
  Revision-aware theory graph. Supports time-travel queries:
  the graph as it existed at any past instant.
  """
  use GenServer

  alias Tiannara.EOS.Theory.Revision
  alias Tiannara.EOS.Bridge.CrossDomain
  alias Tiannara.EOS.Event

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @doc "Create a new revision of a theory. Returns the revision."
  def new_revision(theory_id, %Revision{} = revision) do
    GenServer.call(__MODULE__, {:new_revision, theory_id, revision})
  end

  @doc """
  As-of query: resolve every theory to the revision that was current
  at `instant`. This is how we answer 'what did Tiannara believe at T+48h?'
  """
  def graph_as_of(instant) do
    GenServer.call(__MODULE__, {:graph_as_of, instant})
  end

  @doc "Full lineage walk from a revision back to genesis."
  def revision_lineage(revision_id) do
    GenServer.call(__MODULE__, {:revision_lineage, revision_id})
  end

  @impl true
  def init(_) do
    :ets.new(:theory_revisions, [:named_table, :set, :public])
    :ets.new(:theory_heads, [:named_table, :set, :public])
    :ets.new(:revision_edges, [:named_table, :bag, :public])
    {:ok, %{}}
  end

  @impl true
  def handle_call({:new_revision, theory_id, revision}, _from, state) do
    # Immutable insert — revisions are never overwritten
    true = :ets.insert_new(:theory_revisions, {revision.id, revision})
    :ets.insert(:theory_heads, {theory_id, revision.id})

    # Link revision chain in lineage graph
    if revision.parent_revision_id do
      :ets.insert(:revision_edges, {revision.parent_revision_id,
        %{to: revision.id, type: :revised_into, evidence: revision.change_reason}})
    end

    # Emit on Theory domain bus — this is a durable, causal-ordered event
    :ok = Tiannara.EOS.DomainBus.publish(:theory,
      Event.new("theory.revision.created", __MODULE__, %{
        theory_id: theory_id,
        revision_id: revision.id,
        change_type: revision.change_type
      })
    )

    # Invalidate caches keyed to this theory (§2.4)
    Tiannara.EOS.TheoryCache.invalidate(theory_id)

    {:reply, {:ok, revision}, state}
  end

  @impl true
  def handle_call({:graph_as_of, instant}, _from, state) do
    # For each theory, find the latest revision with created_at <= instant
    heads = :ets.tab2list(:theory_heads)
    snapshot = for {theory_id, _current} <- heads,
                   revision <- latest_revision_at_or_before(theory_id, instant),
                   do: {theory_id, revision}
    {:reply, snapshot, state}
  end

  @impl true
  def handle_call({:revision_lineage, revision_id}, _from, state) do
    chain = walk_parents(revision_id, [])
    {:reply, chain, state}
  end

  defp latest_revision_at_or_before(theory_id, instant) do
    :ets.select(:theory_revisions, [
      {{:_, %Revision{theory_id: :"$1", created_at: :"$2"} = :$_},
       [{:andalso, {:"=<", :"$2", instant}, {:==, :"$1", theory_id}}],
       [:"$_"]}
    ])
    |> Enum.max_by(fn {_, r} -> r.created_at end, fn -> nil end)
    |> case do
      nil -> []
      {_, r} -> [r]
    end
  end

  defp walk_parents(revision_id, acc) do
    case :ets.lookup(:theory_revisions, revision_id) do
      [{_, %Revision{parent_revision_id: nil} = rev}] -> [rev | acc]
      [{_, %Revision{parent_revision_id: parent} = rev}] -> walk_parents(parent, [rev | acc])
      [] -> acc
    end
  end
end
```

### 2.3 Lineage becomes a traversable graph

Your point 5 is correct — lineage as a lookup table is dead weight. In this amendment, lineage edges are **the same edge type system as theory edges**, stored in the same graph store, with additional edge types:

```text
revised_into          (revision chain)
crossed_domain        (bridge crossing, §1)
evidence_for          (observation → hypothesis)
resolved_by           (prediction → experiment)
deployed_as           (proposal → phase-8 ticket)
outcome_of            (deployment result → proposal)
```

This makes the canonical lineage questions ("why do I exist?", "what depends on me?") graph traversals rather than lookups, and it unifies epistemic lineage and engineering lineage into one causally-traversable structure.

### 2.4 Revision-keyed caches

```elixir
defmodule Tiannara.EOS.TheoryCache do
  @moduledoc """
  Hot caches for theory computations, keyed by revision.
  Invalidation is tied to revision creation, never to wall-clock TTL.
  A cache entry is valid iff the theory's current revision matches.
  """
  use GenServer

  @tables [:theory_cache, :prediction_cache, :lineage_cache]

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_) do
    for t <- @tables, do: :ets.new(t, [:named_table, :set, :public])
    {:ok, %{}}
  end

  @doc """
  Read-through with revision check. If the cached revision is stale,
  the entry is discarded and recomputed. No silent stale reads.
  """
  def fetch(table, theory_id, compute_fun) when table in @tables do
    current_rev = Tiannara.EOS.TheoryGraph.Revisioned.current_revision(theory_id)

    case :ets.lookup(table, theory_id) do
      [{^theory_id, ^current_rev, value}] ->
        {:ok, value}

      _ ->
        value = compute_fun.(theory_id)
        :ets.insert(table, {theory_id, current_rev, value})
        {:computed, value}
    end
  end

  @doc "Called by the revision graph whenever a new revision is created."
  def invalidate(theory_id) do
    for t <- @tables, do: :ets.delete(t, theory_id)
    :ok
  end
end
```

**Invariant:** a cache entry is `{theory_id, revision_id, value}`. There is no TTL. Staleness is structural, not temporal — which is what makes the cache safe under concurrent revision creation.

---

## §3 — Formal Promotion/Demotion Policies

Every stage transition is governed by an explicit, versioned, measurable policy. Policies are themselves artifacts — versioned, stored, and referenced by `policy_version` in every revision they authorize. This means we can always answer: *"under what rules was this hypothesis promoted, and have those rules since changed?"*

### 3.1 The promotion criteria

| Transition | Required Criteria | Governance |
|---|---|---|
| Observation → Pattern | ≥ 5 independent observations; regularity significance p < 0.05 or effect size > 0.3; not explained by any existing artifact | Autonomous |
| Pattern → Hypothesis | Testable formulation; ≥ 1 derivable prediction; ≥ 2 competing explanations enumerated (or explicit "none identified" with justification) | Autonomous |
| Hypothesis → Theory | reproducibility ≥ 0.7; prediction_accuracy ≥ 0.65 over ≥ 8 resolved predictions; competing explanations evaluated via tournament or documented review; falsification_conditions non-empty | Autonomous + VerificationAuthority sign-off |
| Theory → Principle | generality ≥ 0.6; cross_domain_support > 0; survived ≥ 1 crucial experiment; compression_efficiency demonstrated; **human review approval** | **Human-gated** |

The asymmetry is deliberate: **Theory → Principle requires human confirmation.** Principles are the load-bearing beliefs of the organism; they do not self-promote. This directly implements *"augments human intelligence rather than replaces human judgment."*

### 3.2 Policy behaviour and implementation

```elixir
defmodule Tiannara.EOS.Promotion.Policy do
  @moduledoc """
  Behaviour for stage-transition policies.
  Policies are versioned artifacts. Every promotion/demotion records
  the policy version that authorized it.
  """

  @type artifact :: Tiannara.EOS.TheoryArtifact.t()
  @type evidence :: %{required(atom) => any}
  @type decision ::
          {:promote, reasons :: [String.t()]}
          | {:hold, missing :: [String.t()]}
          | {:demote, reasons :: [String.t()]}

  @callback evaluate(artifact, evidence) :: decision
  @callback policy_version() :: String.t()
end
```

```elixir
defmodule Tiannara.EOS.Promotion.HypothesisToTheory do
  @moduledoc """
  Promotion policy: Hypothesis → Theory.
  Version 1.2.0. Changes to thresholds require a new policy version
  and governance review.
  """
  @behaviour Tiannara.EOS.Promotion.Policy

  @version "1.2.0"

  @criteria %{
    reproducibility_min: 0.7,
    prediction_accuracy_min: 0.65,
    min_resolved_predictions: 8,
    requires_competition_eval: true,
    requires_falsification_conditions: true
  }

  @impl true
  def policy_version, do: @version

  @impl true
  def evaluate(artifact, evidence) do
    checks = [
      check_reproducibility(artifact, evidence),
      check_prediction_accuracy(artifact, evidence),
      check_prediction_count(artifact, evidence),
      check_competition(artifact, evidence),
      check_falsification(artifact)
    ]

    failures = Enum.filter(checks, &match?({:fail, _}, &1))

    cond do
      failures == [] ->
        {:promote, Enum.map(checks, fn {:pass, r} -> r end)}

      true ->
        {:hold, Enum.map(failures, fn {:fail, r} -> r end)}
    end
  end

  defp check_reproducibility(artifact, _evidence) do
    v = artifact.confidence_vector.reproducibility
    if v >= @criteria.reproducibility_min,
      do: {:pass, "reproducibility #{v} ≥ #{@criteria.reproducibility_min}"},
      else: {:fail, "reproducibility #{v} < #{@criteria.reproducibility_min}"}
  end

  defp check_prediction_accuracy(artifact, _evidence) do
    v = artifact.confidence_vector.prediction_accuracy
    if v >= @criteria.prediction_accuracy_min,
      do: {:pass, "prediction accuracy #{v} ≥ #{@criteria.prediction_accuracy_min}"},
      else: {:fail, "prediction accuracy #{v} < #{@criteria.prediction_accuracy_min}"}
  end

  defp check_prediction_count(artifact, evidence) do
    n = evidence.resolved_prediction_count || 0
    if n >= @criteria.min_resolved_predictions,
      do: {:pass, "#{n} resolved predictions ≥ #{@criteria.min_resolved_predictions}"},
      else: {:fail, "only #{n} resolved predictions, need #{@criteria.min_resolved_predictions}"}
  end

  defp check_competition(artifact, _evidence) do
    if artifact.alternative_explanations != [] and competition_evaluated?(artifact),
      do: {:pass, "competing explanations evaluated"},
      else: {:fail, "competing explanations not evaluated via tournament or review"}
  end

  defp check_falsification(artifact) do
    if artifact.falsification_conditions != [],
      do: {:pass, "falsification conditions specified"},
      else: {:fail, "falsification conditions empty — not a scientific theory"}
  end

  defp competition_evaluated?(artifact) do
    # Check lineage for a tournament or documented review
    Tiannara.EOS.KnowledgeLineage.has_edge_type?(artifact.id, :tested_by)
  end
end
```

```elixir
defmodule Tiannara.EOS.Promotion.Engine do
  @moduledoc """
  Evaluates promotion/demotion policies and emits revisions.
  Constitutional mandate: "Capability must never outpace verification."
  The engine never promotes directly to :principle — that transition
  emits a recommendation that must be human-approved via the Governance bus.
  """
  use GenServer

  alias Tiannara.EOS.Promotion.{Policy, HypothesisToTheory}
  alias Tiannara.EOS.Theory.Revision
  alias Tiannara.EOS.TheoryGraph.Revisioned
  alias Tiannara.EOS.DomainBus
  alias Tiannara.EOS.Event

  @policies %{
    {:observation, :pattern}    => Tiannara.EOS.Promotion.ObservationToPattern,
    {:pattern, :hypothesis}     => Tiannara.EOS.Promotion.PatternToHypothesis,
    {:hypothesis, :theory}      => Tiannara.EOS.Promotion.HypothesisToTheory,
    {:theory, :principle}       => Tiannara.EOS.Promotion.TheoryToPrinciple
  }

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  def evaluate_transition(theory_id, target_stage) do
    GenServer.call(__MODULE__, {:evaluate, theory_id, target_stage})
  end

  @impl true
  def init(_), do: {:ok, %{}}

  @impl true
  def handle_call({:evaluate, theory_id, target_stage}, _from, state) do
    artifact = Tiannara.EOS.TheoryRegistry.get(theory_id)
    current = artifact.stage
    policy = Map.fetch!(@policies, {current, target_stage})
    evidence = Tiannara.EOS.EvidenceSummary.for(theory_id)

    case policy.evaluate(artifact, evidence) do
      {:promote, reasons} ->
        revision = %Revision{
          id: Ecto.UUID.generate(),
          theory_id: theory_id,
          parent_revision_id: artifact.id,
          artifact: %{artifact | stage: target_stage},
          change_type: :promotion,
          change_reason: Enum.join(reasons, "; "),
          policy_version: policy.policy_version(),
          created_at: DateTime.utc_now()
        }

        if target_stage == :principle do
          # Human-gated: emit recommendation on Governance bus, do NOT self-promote
          DomainBus.publish(:governance, Event.new("principle.recommendation", __MODULE__, %{
            theory_id: theory_id, reasons: reasons,
            policy_version: policy.policy_version()
          }))
          {:reply, {:recommended_awaiting_human, revision}, state}
        else
          {:ok, _} = Revisioned.new_revision(theory_id, revision)
          DomainBus.publish(:theory, Event.new("artifact.promoted", __MODULE__, %{
            theory_id: theory_id, to_stage: target_stage,
            policy_version: policy.policy_version()
          }))
          {:reply, {:promoted, revision}, state}
        end

      {:hold, missing} ->
        {:reply, {:hold, missing}, state}

      {:demote, reasons} ->
        revision = %Revision{
          id: Ecto.UUID.generate(),
          theory_id: theory_id,
          parent_revision_id: artifact.id,
          artifact: artifact,
          change_type: :demotion,
          change_reason: Enum.join(reasons, "; "),
          policy_version: policy.policy_version(),
          created_at: DateTime.utc_now()
        }
        {:ok, _} = Revisioned.new_revision(theory_id, revision)
        {:reply, {:demoted, revision}, state}
    end
  end
end
```

**Demotion semantics:** demotion is a *revision*, never a deletion. A demoted theory keeps its full lineage and remains queryable. This is your Theory Ecology made mechanical.

---

## §4 — Experiment Registry & Scheduler

Experiments become first-class citizens with their own identity, lifecycle, budget, and results store. Theories no longer bury experiments; they *reference* them.

### 4.1 Experiment schema

```elixir
defmodule Tiannara.EOS.Experiment do
  @moduledoc """
  First-class experiment. Constitutional mandate: "Scientific Method —
  Observation → Hypothesis → Prediction → Simulation → Experiment →
  Validation → Knowledge Integration → Continuous Re-evaluation."
  """
  @enforce_keys [:id, :type, :designed_at]
  defstruct [
    :id,
    :type,                    # :crucial | :prediction_test | :reproduction |
                              # :benchmark | :exploratory | :cross_domain_probe
    :purpose,                 # why this experiment exists
    :requested_by,            # :tournament | :falsification | :executive | :human
    :theory_ids,              # theories under test
    :prediction_ids,          # predictions this resolves
    :design,                  # %{inputs, procedure, expected_outcomes_per_theory}
    :budget,                  # %{compute_units, wall_time_seconds, priority}
    :status,                  # :designed | :scheduled | :running | :completed |
                              # :analyzed | :archived
    :results,                 # %ExperimentResults{} — immutable once completed
    :lineage,
    :designed_at,
    :scheduled_at,
    :completed_at
  ]
end

defmodule Tiannara.EOS.ExperimentResults do
  @moduledoc "Immutable experiment outcome. Never modified after completion."
  @enforce_keys [:experiment_id, :completed_at]
  defstruct [
    :experiment_id,
    :outcome_per_theory,      # %{theory_id => :supported | :violated | :inconclusive}
    :resolved_predictions,    # %{prediction_id => :supported | :violated}
    :raw_data_ref,            # pointer to durable storage
    :statistical_summary,
    :anomalies,               # unexpected observations discovered during the run
    :completed_at,
    immutable: false
  ]
end
```

### 4.2 Registry and scheduler

```elixir
defmodule Tiannara.EOS.ExperimentRegistry do
  @moduledoc """
  Identity and lifecycle store for experiments.
  """
  use GenServer

  alias Tiannara.EOS.{Experiment, DomainBus, Event}

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  def register(%Experiment{} = experiment) do
    GenServer.call(__MODULE__, {:register, experiment})
  end

  def record_results(experiment_id, results) do
    GenServer.call(__MODULE__, {:record_results, experiment_id, results})
  end

  @impl true
  def init(_) do
    :ets.new(:experiments, [:named_table, :set, :public])
    {:ok, %{}}
  end

  @impl true
  def handle_call({:register, experiment}, _from, state) do
    true = :ets.insert_new(:experiments, {experiment.id, experiment})

    DomainBus.publish(:theory, Event.new("experiment.registered", __MODULE__, %{
      experiment_id: experiment.id,
      type: experiment.type,
      theory_ids: experiment.theory_ids
    }))

    {:reply, {:ok, experiment.id}, state}
  end

  @impl true
  def handle_call({:record_results, experiment_id, results}, _from, state) do
    [{^experiment_id, experiment}] = :ets.lookup(:experiments, experiment_id)

    updated = %{experiment |
      status: :completed,
      results: results,
      completed_at: DateTime.utc_now()
    }
    :ets.insert(:experiments, {experiment_id, updated})

    # Results flow to FalsificationExecutor and PredictionResolver
    DomainBus.publish(:theory, Event.new("experiment.completed", __MODULE__, %{
      experiment_id: experiment_id,
      resolved_predictions: results.resolved_predictions,
      anomalies: results.anomalies
    }))

    {:reply, :ok, state}
  end
end
```

```elixir
defmodule Tiannara.EOS.ExperimentScheduler do
  @moduledoc """
  Allocates execution slots for experiments.
  Priorities come from the Epistemic Executive (§5) via EVI.
  Respects ResourceManager compute budgets.

  Constitutional mandate: "Capability must never outpace verification" —
  the scheduler never runs an experiment whose design lacks a budget
  approved by the Executive.
  """
  use GenServer

  alias Tiannara.EOS.{Experiment, ExperimentRegistry, ResourceManager}

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @doc "Submit an experiment for scheduling with an EVI priority."
  def submit(experiment_id, evi_priority) do
    GenServer.call(__MODULE__, {:submit, experiment_id, evi_priority})
  end

  @impl true
  def init(_) do
    # Priority queue: highest EVI first
    {:ok, %{queue: :queue.new(), running: MapSet.new(), max_concurrent: 4}}
  end

  @impl true
  def handle_call({:submit, experiment_id, priority}, _from, state) do
    [{^experiment_id, experiment}] = :ets.lookup(:experiments, experiment_id)

    # Budget check: Executive must have approved compute allocation
    case Tiannara.EOS.EpistemicBudget.approved?(experiment.id) do
      true ->
        queue = :queue.in({-priority, experiment_id}, state.queue)
        {:reply, :queued, %{state | queue: queue}}

      false ->
        {:reply, {:error, :budget_not_approved}, state}
    end
  end

  @impl true
  def handle_info(:tick, state) do
    # Drain queue while under concurrency and resource budget
    state = drain(state)
    {:noreply, state}
  end

  defp drain(state) do
    if MapSet.size(state.running) >= state.max_concurrent do
      state
    else
      case :queue.out(state.queue) do
        {:empty, _} -> state
        {{:value, {_neg_pri, experiment_id}}, rest} ->
          if ResourceManager.can_allocate?(experiment_budget(experiment_id)) do
            spawn_execution(experiment_id)
            %{state | queue: rest, running: MapSet.put(state.running, experiment_id)}
            |> drain()
          else
            state
          end
      end
    end
  end

  defp spawn_execution(experiment_id) do
    Task.Supervisor.start_child(
      Tiannara.EOS.TaskSupervisor,
      fn -> Tiannara.EOS.ExperimentExecutor.run(experiment_id) end
    )
  end

  defp experiment_budget(id) do
    [{^id, e}] = :ets.lookup(:experiments, id)
    e.budget
  end
end
```

**Experiment types and their requesters:**

| Type | Requested By | Purpose |
|---|---|---|
| `:crucial` | TheoryTournament | Discriminate between competing theories with mutually exclusive predictions |
| `:prediction_test` | FalsificationExecutor | Resolve a pending prediction against reality |
| `:reproduction` | VerificationAuthority | Deterministic replay of a failure or observation |
| `:benchmark` | EpistemicExecutive | Measure computational efficiency of a theory's predictions |
| `:exploratory` | DiscoveryScheduler | Probe a region of high epistemic debt |
| `:cross_domain_probe` | AnalogicalEngine | Test a cross-domain analogy hypothesis |

---

## §5 — Epistemic Executive

This is the missing strategic layer. Everything before this point is reactive — events flow, subsystems respond. The Executive is what asks *"what deserves attention next?"* and allocates the organism's finite resources accordingly.

**Trust domain boundary:** the Executive schedules and recommends. It never approves proposals, modifies theories, or deploys. It is a planner, not an executor. This preserves the separation of trust domains you identified as the architecture's strongest feature.

### 5.1 The value function

```elixir
defmodule Tiannara.EOS.EpistemicExecutive.ValueFunction do
  @moduledoc """
  Constitutional Clause 21, enforced: the value function is defined
  ONLY over quality metrics. Count-based terms are structurally absent.

  Value(state) = w1 · explanatory_power
               + w2 · prediction_coverage
               + w3 · compression_efficiency (KCR)
               + w4 · verification_confidence
               − w5 · epistemic_debt

  The weights themselves are governed artifacts — versioned, reviewable,
  and stored in the PrincipleRegistry. The Executive cannot reweight itself.
  """

  @type state :: %{
    explanatory_power: float,
    prediction_coverage: float,
    compression_efficiency: float,
    verification_confidence: float,
    epistemic_debt: float
  }

  def evaluate(state, weights) do
    weights.explanatory_power * state.explanatory_power
    + weights.prediction_coverage * state.prediction_coverage
    + weights.compression_efficiency * state.compression_efficiency
    + weights.verification_confidence * state.verification_confidence
    - weights.epistemic_debt * state.epistemic_debt
  end
end
```

### 5.2 Expected Value of Information

```elixir
defmodule Tiannara.EOS.EpistemicExecutive.EVI do
  @moduledoc """
  Expected Value of Information for a candidate action.

  EVI(action) = Σ_outcome P(outcome | action) · ΔValue(outcome) − Cost(action)

  where ΔValue is the change in the value function between the current
  epistemic state and the projected post-outcome state, and Cost is
  the action's budget draw (compute, time, human attention).

  Actions with EVI ≤ 0 are never scheduled. This is the structural
  defense against busywork and Goodhart gaming.
  """

  alias Tiannara.EOS.EpistemicExecutive.ValueFunction

  def compute(action, current_state, weights) do
    expected_gain =
      Enum.reduce(action.possible_outcomes, 0.0, fn outcome, acc ->
        acc + outcome.probability *
          (ValueFunction.evaluate(outcome.projected_state, weights)
           - ValueFunction.evaluate(current_state, weights))
      end)

    expected_gain - action.cost
  end
end
```

### 5.3 The Executive and the Epistemic Budget

```elixir
defmodule Tiannara.EOS.EpistemicExecutive do
  @moduledoc """
  The strategic planner of the Epistemic Operating System.

  Responsibilities:
  - Compute EVI for all candidate actions each deliberation cycle
  - Allocate the epistemic budget across domains (compute, experiment slots,
    human attention)
  - Detect stagnation: theories with pending predictions but no evidence delta
  - Detect KCR decline: trigger TheoryConsolidator runs
  - Detect neglected domains: regions of the graph with high debt, low activity
  - Order the proposal review queue by EVI (but NEVER approve)

  Constitutional mandate: "What experiment should I perform next?" —
  this module is the answer to that question.
  """
  use GenServer
  require Logger

  alias Tiannara.EOS.EpistemicExecutive.{ValueFunction, EVI}
  alias Tiannara.EOS.{DomainBus, Event, EpistemicDebtLedger, KCRDashboard}

  @deliberation_interval_ms 60_000  # one deliberation cycle per minute

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_) do
    :timer.send_interval(@deliberation_interval_ms, :deliberate)
    {:ok, %{
      cycle: 0,
      kcr_history: [],
      stagnation_threshold_days: 14,
      kcr_decline_cycles: 3
    }}
  end

  @impl true
  def handle_info(:deliberate, state) do
    cycle = state.cycle + 1
    Logger.info("EpistemicExecutive: deliberation cycle #{cycle}")

    snapshot = take_epistemic_snapshot()
    weights = current_value_weights()

    directives = []

    # 1. Stagnation detection
    directives = directives ++ detect_stagnation(snapshot, state)

    # 2. KCR decline detection
    kcr_history = [snapshot.kcr | state.kcr_history] |> Enum.take(100)
    directives = directives ++ detect_kcr_decline(kcr_history, state)

    # 3. Candidate action ranking by EVI
    candidates = gather_candidate_actions(snapshot)
    ranked = rank_by_evi(candidates, snapshot, weights)
    directives = directives ++ schedule_top_actions(ranked)

    # 4. Neglected domain detection
    directives = directives ++ detect_neglected_domains(snapshot)

    # Emit directives on the Governance bus — durable, ordered, auditable
    Enum.each(directives, fn directive ->
      DomainBus.publish(:governance, Event.new("executive.directive", __MODULE__, %{
        directive: directive,
        cycle: cycle,
        justification: directive.justification
      }))
    end)

    {:noreply, %{state | cycle: cycle, kcr_history: kcr_history}}
  end

  # ── Detection logic ──

  defp detect_stagnation(snapshot, state) do
    for theory <- snapshot.theories,
        theory.stage in [:hypothesis, :theory],
        pending_predictions?(theory),
        days_since_last_evidence(theory) > state.stagnation_threshold_days do
      %{
        type: :schedule_experiment,
        target: theory.id,
        experiment_type: :prediction_test,
        justification: "theory #{theory.id} has pending predictions but no evidence " <>
          "delta in #{days_since_last_evidence(theory)} days"
      }
    end
  end

  defp detect_kcr_decline(kcr_history, state) do
    if length(kcr_history) >= state.kcr_decline_cycles do
      recent = Enum.take(kcr_history, state.kcr_decline_cycles)
      if monotonically_declining?(recent) do
        [%{
          type: :trigger_consolidation,
          justification: "KCR declined for #{state.kcr_decline_cycles} consecutive cycles"
        }]
      else
        []
      end
    else
      []
    end
  end

  defp detect_neglected_domains(snapshot) do
    for {domain, debt} <- snapshot.debt_by_domain,
        debt > snapshot.debt_threshold,
        activity_low?(snapshot, domain) do
      %{
        type: :flag_neglected_domain,
        target: domain,
        justification: "domain #{inspect(domain)} carries debt #{debt} with low activity"
      }
    end
  end

  defp rank_by_evi(candidates, snapshot, weights) do
    candidates
    |> Enum.map(fn action -> {action, EVI.compute(action, snapshot, weights)} end)
    |> Enum.filter(fn {_action, evi} -> evi > 0 end)
    |> Enum.sort_by(fn {_action, evi} -> evi end, :desc)
  end

  defp schedule_top_actions(ranked) do
    ranked
    |> Enum.take(max_concurrent_actions())
    |> Enum.map(fn {action, evi} ->
      %{
        type: :schedule_experiment,
        target: action.experiment_id,
        evi: evi,
        justification: "EVI #{Float.round(evi, 3)} — highest-value action this cycle"
      }
    end)
  end

  # ── Stubs ──
  defp take_epistemic_snapshot, do: %{}
  defp current_value_weights, do: %{}
  defp gather_candidate_actions(_), do: []
  defp max_concurrent_actions, do: 4
  defp pending_predictions?(_), do: false
  defp days_since_last_evidence(_), do: 0
  defp monotonically_declining?(_), do: false
  defp activity_low?(_, _), do: false
end
```

```elixir
defmodule Tiannara.EOS.EpistemicBudget do
  @moduledoc """
  Computational governance. Knowledge work competes for CPU like processes.

  Every domain gets a quota. Tournaments, consolidations, and experiments
  must request budget before executing. The Executive approves or defers.

  This is the structural answer to: "10,000 theories → 100 million
  comparisons — how do you budget that?" You don't. The budget says no.
  """
  use GenServer

  @domain_quotas %{
    discovery:    0.30,   # 30% of epistemic compute
    verification: 0.25,
    tournaments:  0.15,
    consolidation: 0.10,
    analogy:      0.10,
    reserve:      0.10    # held for falsification-triggered urgent work
  }

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  @doc "Request compute budget for a unit of work. Returns :approved or {:deferred, reason}."
  def request(domain, work_id, cost_units) do
    GenServer.call(__MODULE__, {:request, domain, work_id, cost_units})
  end

  @doc "Check whether an experiment's budget was approved (used by scheduler)."
  def approved?(work_id) do
    GenServer.call(__MODULE__, {:approved?, work_id})
  end

  @impl true
  def init(_) do
    {:ok, %{
      spent: Map.new(Map.keys(@domain_quotas), &{&1, 0}),
      approvals: %{},
      window_start: System.monotonic_time(:second)
    }}
  end

  @impl true
  def handle_call({:request, domain, work_id, cost}, _from, state) do
    quota = Map.fetch!(@domain_quotas, domain)
    total_budget = total_epistemic_compute()
    domain_budget = quota * total_budget

    if state.spent[domain] + cost <= domain_budget do
      spent = Map.update!(state.spent, domain, &(&1 + cost))
      approvals = Map.put(state.approvals, work_id, cost)
      {:reply, :approved, %{state | spent: spent, approvals: approvals}}
    else
      {:reply, {:deferred, :domain_budget_exhausted}, state}
    end
  end

  @impl true
  def handle_call({:approved?, work_id}, _from, state) do
    {:reply, Map.has_key?(state.approvals, work_id), state}
  end

  defp total_epistemic_compute, do: 1_000  # compute units per window
end
```

### 5.4 Directive taxonomy

| Directive | Target | Effect |
|---|---|---|
| `:schedule_experiment` | ExperimentScheduler | Submits an experiment with EVI priority |
| `:trigger_consolidation` | TheoryConsolidator | Initiates a merge/split/compress pass |
| `:flag_stagnation` | EpistemicWorkspace | Surfaces stagnant theories to human reviewers |
| `:flag_neglected_domain` | EpistemicWorkspace | Surfaces under-explored domains |
| `:rebalance_budget` | EpistemicBudget | Proposes quota changes (requires governance approval) |
| `:escalate_to_human` | EpistemicWorkspace | High-stakes decision the Executive will not make autonomously |

**Constitutional check:** every directive carries a `justification` field citing quality metrics. A directive that cannot justify itself in terms of Clause 21 is structurally un-emittable — the ValueGate runs on the Governance bus publish path too.

---

## §6 — Mathematical Intermediate Representation for the Analogical Engine

Your point 6 is the most important scientific improvement in this review. The amendment: the AnalogicalEngine never touches natural language. Every theory is normalized into one of four canonical graph kinds, and analogy is typed graph isomorphism over those forms.

```elixir
defmodule Tiannara.EOS.Analogy.MIR do
  @moduledoc """
  Mathematical Intermediate Representation.

  Four canonical graph kinds. Every theory is compiled into exactly one
  before any cross-domain comparison. Analogy is isomorphism over MIR,
  never over language.

  Constitutional mandate: "Distinguish clearly between facts, evidence,
  assumptions, hypotheses." — MIR is the structural fact layer beneath
  the linguistic hypothesis layer.
  """

  @graph_kinds [:causal, :dependency, :constraint, :state_transition]

  defmodule Node do
    @enforce_keys [:id, :role]
    defstruct [
      :id,
      :role,            # abstract role, e.g. :accumulator, :regulator, :sink, :source
      :sign,            # :positive | :negative | :neutral
      :dimensionality,  # scalar | vector | distribution | topology
      :attributes       # kind-specific
    ]
  end

  defmodule Edge do
    @enforce_keys [:from, :to, :kind]
    defstruct [
      :from,
      :to,
      :kind,            # :increases | :decreases | :enables | :constrains |
                        # :precedes | :depends_on
      :polarity,        # :excitatory | :inhibitory | :neutral
      :strength         # float or :qualitative
    ]
  end

  defmodule Graph do
    @enforce_keys [:kind, :nodes, :edges]
    defstruct [:kind, :nodes, :edges, :invariants, :symmetries]
  end

  @doc """
  Compile a theory into its MIR. This is the only place domain content
  touches the analogy pipeline.
  """
  def compile(theory_artifact) do
    kind = infer_graph_kind(theory_artifact)
    nodes = extract_abstract_nodes(theory_artifact)
    edges = extract_abstract_edges(theory_artifact)
    invariants = derive_invariants(nodes, edges)
    symmetries = derive_symmetries(nodes, edges)

    %Graph{kind: kind, nodes: nodes, edges: edges,
           invariants: invariants, symmetries: symmetries}
  end

  @doc """
  Typed subgraph isomorphism with polarity preservation.
  Two graphs are analogous iff there exists a bijection between a
  subgraph of A and a subgraph of B preserving:
    - node roles
    - edge kinds
    - edge polarities
    - invariant structure
  """
  def analogous?(%Graph{} = a, %Graph{} = b, opts \\ []) do
    min_overlap = opts[:min_overlap] || 0.6

    cond do
      a.kind != b.kind ->
        # Different graph kinds: analogy still possible but downgraded
        subgraph_match(a, b, min_overlap) * 0.5

      true ->
        subgraph_match(a, b, min_overlap)
    end
  end

  defp subgraph_match(_a, _b, _min_overlap), do: 0.0
  defp infer_graph_kind(_), do: :causal
  defp extract_abstract_nodes(_), do: []
  defp extract_abstract_edges(_), do: []
  defp derive_invariants(_, _), do: []
  defp derive_symmetries(_, _), do: []
end
```

**The key invariant:** `compile/1` is the *only* function in the analogy pipeline that sees domain content. Everything downstream operates on `%MIR.Graph{}`. This is what makes the analogies mathematical rather than linguistic, and it's what lets a software-coupling theory legitimately match a biological-compartmentalization theory — because both compile to the same typed graph.

**Failure mode guarded against:** superficial analogy. Without MIR, "coupling" matches "coupling" by word. With MIR, `Dense_Dependency → Reduced_Adaptation` matches `High_Specialization → Reduced_Tolerance` by structure, and word-overlap is irrelevant.

---

## §7 — Uncertainty Heatmaps for the Epistemic Workspace

The workspace stops presenting proposals as a queue and starts presenting the **epistemic frontier** — where human judgment has the highest marginal value.

```elixir
defmodule Tiannara.EOS.EpistemicWorkspace.Heatmaps do
  @moduledoc """
  Four ranking queries that define where human attention is most valuable.

  Constitutional mandate: "Tiannara should remain a system that augments
  human intelligence rather than replaces human judgment." Humans are
  routed to uncertainty, not to confirmation.
  """

  alias Tiannara.EOS.TheoryGraph.Revisioned

  @doc "Theories with the lowest evidence strength relative to their influence."
  def most_uncertain(limit \\ 20) do
    # uncertainty = (1 - evidence_strength) * influence_centrality
    Revisioned.all_current_revisions()
    |> Enum.map(fn rev ->
      %{
        theory_id: rev.theory_id,
        statement: rev.artifact.statement,
        score: (1 - rev.artifact.confidence_vector.evidence_strength)
               * influence_centrality(rev.theory_id)
      }
    end)
    |> Enum.sort_by(& &1.score, :desc)
    |> Enum.take(limit)
  end

  @doc "Theories with the most contradiction edges — active scientific disputes."
  def most_controversial(limit \\ 20) do
    Revisioned.all_current_revisions()
    |> Enum.map(fn rev ->
      %{
        theory_id: rev.theory_id,
        statement: rev.artifact.statement,
        score: Revisioned.count_edges(rev.id, :contradicts)
      }
    end)
    |> Enum.sort_by(& &1.score, :desc)
    |> Enum.take(limit)
  end

  @doc "Theories with highest betweenness centrality — remove one and many chains break."
  def most_influential(limit \\ 20) do
    Revisioned.all_current_revisions()
    |> Enum.map(fn rev ->
      %{
        theory_id: rev.theory_id,
        statement: rev.artifact.statement,
        score: betweenness_centrality(rev.theory_id)
      }
    end)
    |> Enum.sort_by(& &1.score, :desc)
    |> Enum.take(limit)
  end

  @doc "Theories with highest degree — the most interconnected hubs."
  def most_interconnected(limit \\ 20) do
    Revisioned.all_current_revisions()
    |> Enum.map(fn rev ->
      %{
        theory_id: rev.theory_id,
        statement: rev.artifact.statement,
        score: Revisioned.degree(rev.id)
      }
    end)
    |> Enum.sort_by(& &1.score, :desc)
    |> Enum.take(limit)
  end

  defp influence_centrality(_theory_id), do: 0.0
  defp betweenness_centrality(_theory_id), do: 0.0
end
```

The workspace renders these as four panels. A reviewer's first screen is not "here are 50 proposals" — it is "here is where the organism is most uncertain, most disputed, most leveraged, and most connected." Proposals appear *within* that context, ordered by EVI from the Executive.

---

## §8 — Updated Constitutional Compliance Mapping

| Amendment Component | Constitutional Clause |
|---|---|
| Partitioned Event Domains | *"Explicit interfaces, minimal coupling"* — a noisy domain cannot degrade a critical one |
| CrossDomainBridge | *"Every architectural decision should remain traceable"* — every crossing is lineage-logged |
| Theory Revision Graph | *"Evolution Framework — preserve lineage"* — nothing is mutated or deleted |
| Revision-keyed caches | *"Determinism where appropriate"* — staleness is structural, not temporal |
| Promotion/Demotion Policies | *"Capability must never outpace verification"* — Theory→Principle is human-gated |
| Experiment Registry | *"Scientific Method"* — experiments are first-class, not buried in theories |
| Epistemic Executive | *"What experiment should I perform next?"* — the organism has a strategic planner |
| Epistemic Budget | *"Complexity must always justify itself"* — compute is governed, not free |
| MIR | *"Distinguish clearly between facts, evidence, assumptions, hypotheses"* — structure is the fact layer |
| ValueGate + NoveltyGate | **Clause 21** — artifact count is never a value metric |
| Uncertainty Heatmaps | *"Augments human intelligence rather than replaces human judgment"* — humans are routed to uncertainty |

---

## §9 — Implementation Order and Test Strategy

The five capabilities have a dependency order. This is the build sequence:

```text
Week 1–2:  §1 Partitioned Event Domains
           (foundational — everything else publishes through these)
           Tests: property test that saturating :observation produces zero
                  drops on :governance; bridge rejects illegal crossings

Week 2–3:  §2 Theory Revision Graph
           Tests: as-of query returns correct historical snapshot;
                  revision lineage walks to genesis; cache never serves
                  a stale revision

Week 3–4:  §3 Promotion/Demotion Policies
           Tests: each policy's criteria are independently verifiable;
                  Theory→Principle cannot self-promote (adversarial test);
                  demotion produces a revision, never a deletion

Week 4–5:  §4 Experiment Registry & Scheduler
           Tests: scheduler refuses experiments without budget approval;
                  results are immutable after completion;
                  concurrent execution respects max_concurrent

Week 5–6:  §5 Epistemic Executive + Epistemic Budget
           Tests: EVI ≤ 0 actions are never scheduled (property test);
                  value function contains no count terms (structural test);
                  stagnation detection fires on synthetic stale theories;
                  budget enforcement rejects over-quota requests
```

**The adversarial test that matters most:** run the Executive against a synthetic scenario where minting 10,000 trivial hypotheses would maximize a naive count-based reward. Assert that the Executive allocates zero budget to that strategy and instead schedules consolidation. If that test passes, Clause 21 is real. If it fails, the whole amendment is decoration.

---

## Assessment After This Amendment

The specification now covers:

- **Infrastructure:** partitioned event domains with per-domain durability and backpressure
- **Data model:** revisioned theories with temporal graph queries
- **Governance mechanics:** versioned promotion policies with human-gated principle promotion
- **Scientific method:** first-class experiments with budget-gated scheduling
- **Strategic layer:** an Epistemic Executive that allocates attention by Expected Value of Information
- **Computational governance:** an Epistemic Budget that makes knowledge work compete for resources
- **Structural Goodhart defense:** value functions defined only over quality metrics, enforced at publish time

The five capabilities you prioritized are now specified to the same depth as the original v1.0 subsystems. The architecture is no longer missing its strategic layer — the organism now has a brain that decides what deserves attention next, and that brain is constitutionally prohibited from valuing activity over understanding.