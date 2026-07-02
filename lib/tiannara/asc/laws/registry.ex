defmodule Tiannara.ASC.Laws.Registry do
  @moduledoc """
  ETS-backed registry of all discovered and candidate software engineering laws.

  Stores `%Law{}` structs and provides query interfaces for:
    - The Laws Discoverer (write path — creates and updates laws)
    - The Meta-Learning Civilization (read path — applies laws to active projects)
    - External consumers (read path — surfaces laws to research domains)

  Laws that reach `:established` status are promoted to the global
  `KnowledgeGraph.Registry` as `:law` nodes with `domains: [:software_engineering]`.
  """

  use GenServer
  require Logger

  alias Tiannara.ASC.Laws.Law

  @table :asc_laws_registry
  @laws_file "data/asc_archive/laws.ndjson"

  # ---------------------------------------------------------------------------
  # Public API
  # ---------------------------------------------------------------------------

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec store(Law.t()) :: {:ok, Law.t()}
  def store(%Law{} = law) do
    GenServer.call(__MODULE__, {:store, law})
  end

  @spec get(String.t()) :: {:ok, Law.t()} | {:error, :not_found}
  def get(id) do
    case :ets.lookup(@table, id) do
      [{^id, law}] -> {:ok, law}
      [] -> {:error, :not_found}
    end
  end

  @spec all() :: [Law.t()]
  def all do
    :ets.tab2list(@table) |> Enum.map(&elem(&1, 1))
  end

  @spec established() :: [Law.t()]
  def established do
    all() |> Enum.filter(&(&1.status == :established))
  end

  @spec candidates() :: [Law.t()]
  def candidates do
    get_laws_by_status(:candidate_law) ++ get_laws_by_status(:candidate_pattern)
  end

  @doc "Phase 5I: Returns laws filtered by governance status."
  @spec get_laws_by_status(Law.status()) :: [Law.t()]
  def get_laws_by_status(status) do
    all() |> Enum.filter(&(&1.status == status))
  end

  @doc "Phase 5I: Returns a governance audit log showing all promotion/demotion events."
  @spec get_governance_audit_log() :: [map()]
  def get_governance_audit_log do
    GenServer.call(__MODULE__, :get_audit_log)
  end

  # Phase 17 Stub
  # TODO: Replace mocked active laws with real telemetry-backed laws
  def get_all_active_laws do
    [
      %{id: "law_functional_core", status: :active},
      %{id: "law_locality_of_behavior", status: :active}
    ]
  end

  @doc "Record evidence for or against a law. Promotes to KG if newly established."
  @spec record_evidence(String.t(), :confirms | :disconfirms, String.t()) :: {:ok, Law.t()} | {:error, :not_found}
  def record_evidence(law_id, verdict, project_id) do
    GenServer.call(__MODULE__, {:record_evidence, law_id, verdict, project_id})
  end

  @doc "Upsert a law by statement, merging metadata."
  @spec upsert_law(String.t(), String.t(), map()) :: {:ok, Law.t()}
  def upsert_law(project_id, statement, metadata) do
    GenServer.call(__MODULE__, {:upsert_law, project_id, statement, metadata})
  end

  # ---------------------------------------------------------------------------
  # GenServer callbacks
  # ---------------------------------------------------------------------------

  @impl true
  def init(_opts) do
    :ets.new(@table, [:named_table, :set, :public, read_concurrency: true])
    File.mkdir_p!("data/asc_archive")
    load_from_disk()
    Logger.info("[ASC.Laws.Registry] Initialized. #{:ets.info(@table, :size)} laws loaded.")
    {:ok, %{audit_log: []}}
  end

  @impl true
  def handle_call({:store, law}, _from, state) do
    existing = case :ets.lookup(@table, law.id) do
      [{_id, existing_law}] -> existing_law
      [] -> nil
    end
    
    state = if existing != nil and existing.status != law.status do
      audit_event = %{
        timestamp: DateTime.utc_now(),
        law_id: law.id,
        statement: law.statement,
        previous_status: existing.status,
        new_status: law.status,
        reason: Map.get(law.variables || %{}, :governance_reason, :criteria_met)
      }
      %{state | audit_log: [audit_event | state.audit_log || []]}
    else
      state
    end

    :ets.insert(@table, {law.id, law})
    persist(law)
    Phoenix.PubSub.broadcast(Tiannara.PubSub, "asc:laws:updated", %{law_id: law.id, status: law.status})
    {:reply, {:ok, law}, state}
  end

  @impl true
  def handle_call(:get_audit_log, _from, state) do
    {:reply, state.audit_log || [], state}
  end

  @impl true
  def handle_call({:record_evidence, law_id, verdict, project_id}, _from, state) do
    case :ets.lookup(@table, law_id) do
      [] ->
        {:reply, {:error, :not_found}, state}

      [{^law_id, law}] ->
        updated_law = Law.update_confidence(law, verdict, project_id)
        :ets.insert(@table, {law_id, updated_law})
        persist(updated_law)

        # Promote to KG if newly established
        if updated_law.status == :established and law.status != :established do
          promote_to_knowledge_graph(updated_law)
        end

        Phoenix.PubSub.broadcast(Tiannara.PubSub, "asc:laws:updated", %{
          law_id: law_id,
          status: updated_law.status,
          confidence: updated_law.confidence
        })

        {:reply, {:ok, updated_law}, state}
    end
  end

  @impl true
  def handle_call({:upsert_law, project_id, statement, metadata}, _from, state) do
    existing = :ets.match_object(@table, {:_, %Law{statement: statement}}) |> Enum.map(&elem(&1, 1)) |> List.first()

    law = if existing do
      existing
    else
      Law.new(statement)
    end

    # Merge metadata into variables and tracking fields
    law = %{law |
      variables: Map.merge(law.variables || %{}, Map.delete(metadata, :tags)),
      domain_tags: Enum.uniq((law.domain_tags || []) ++ Map.get(metadata, :tags, [])),
      support_count: Map.get(metadata, :support_count, law.support_count),
      contradiction_count: Map.get(metadata, :contradiction_count, law.contradiction_count),
      confidence: Map.get(metadata, :confidence, law.confidence)
    }

    # Record evidence if not already present
    law = if project_id not in law.supporting_project_ids and project_id != "asc_transfer_ecology" do
      Law.update_confidence(law, :confirms, project_id)
    else
      # Recalculate status directly for ecology laws based on exact counts if it's the sentinel
      n = law.support_count + law.contradiction_count
      status = cond do
        law.confidence < 0.20                          -> :refuted
        law.confidence >= 0.40 and law.confidence <= 0.60
          and n >= 5                               -> :under_review
        law.confidence >= 0.40 and law.support_count >= 500 -> :canonical_principle
        law.confidence >= 0.25 and law.support_count >= 100 -> :established_law
        law.support_count >= 30                      -> :candidate_law
        true                                       -> :candidate_pattern
      end
      %{law | status: status, last_updated_at: DateTime.utc_now()}
    end

    :ets.insert(@table, {law.id, law})
    persist(law)

    Phoenix.PubSub.broadcast(Tiannara.PubSub, "asc:laws:updated", %{
      law_id: law.id,
      status: law.status,
      confidence: law.confidence
    })

    {:reply, {:ok, law}, state}
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp persist(%Law{} = law) do
    line = Jason.encode!(law) <> "\n"
    File.write!(@laws_file, line, [:append])
  rescue
    e -> Logger.warning("[ASC.Laws.Registry] Persist error: #{inspect(e)}")
  end

  defp load_from_disk do
    if File.exists?(@laws_file) do
      @laws_file
      |> File.stream!()
      |> Stream.map(&String.trim/1)
      |> Stream.reject(&(&1 == ""))
      |> Stream.map(fn line ->
        case Jason.decode(line, keys: :atoms) do
          {:ok, attrs} -> struct(Law, attrs)
          _ -> nil
        end
      end)
      |> Stream.reject(&is_nil/1)
      |> Enum.each(fn law -> :ets.insert(@table, {law.id, law}) end)
    end
  end

  defp promote_to_knowledge_graph(%Law{} = law) do
    node = %Tiannara.KnowledgeGraph.Node{
      id: "law_kg_#{law.id}",
      type: :law,
      name: law.statement,
      domains: [:software_engineering, :computation],
      parents: [],
      metadata: %{
        confidence: law.confidence,
        evidence_count: law.evidence_count,
        variables: law.variables,
        source: :asc_laws_registry
      },
      description: law.statement
    }

    try do
      Tiannara.KnowledgeGraph.Registry.save(node)
      Logger.info("[ASC.Laws.Registry] Law promoted to KG: #{law.statement}")
    rescue
      e -> Logger.warning("[ASC.Laws.Registry] KG promotion failed: #{inspect(e)}")
    end
  end
end
