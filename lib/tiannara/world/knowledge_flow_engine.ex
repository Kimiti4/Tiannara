defmodule Tiannara.World.KnowledgeFlowEngine do
  use GenServer
  use Tiannara.ExecutiveService.Base
  require Logger

  alias Tiannara.World.{UnifiedWorldModel, OntologyManager, WorldQueryEngine}
  alias Tiannara.CEL.Services.{EventBus, ExecutiveMemory, CapabilityGraph}
  alias Tiannara.CEL.Kernel.ConstitutionalScore

  @stagnation_check_interval :timer.hours(12)
  @max_stagnation_days 30

  @impl Tiannara.ExecutiveService
  def id, do: :knowledge_flow_engine

  @impl Tiannara.ExecutiveService
  def version, do: "1.0.0"

  @impl Tiannara.ExecutiveService
  def capabilities do
    [
      :cross_domain_propagation,
      :semantic_translation,
      :target_identification,
      :stagnation_prevention,
      :propagation_auditability
    ]
  end

  @impl Tiannara.ExecutiveService
  def dependencies do
    [:persistent_memory, :event_transport, :unified_world_model,
     :ontology_manager, :capability_graph]
  end

  @impl Tiannara.ExecutiveService
  def priority, do: :high

  @impl Tiannara.ExecutiveService
  def constitutional_score do
    stats = GenServer.call(__MODULE__, :stats)
    evidence_quality =
      if stats.total_knowledge_items > 0,
        do: stats.propagated_knowledge_items / stats.total_knowledge_items,
        else: 1.0

    health = if stats.stagnant_items > 0, do: 0.8, else: 1.0

    %ConstitutionalScore{
      service_id: id(),
      health: health,
      constitutional_alignment: 1.0,
      transparency: 1.0,
      explainability: 1.0,
      evidence_quality: evidence_quality,
      human_oversight: 1.0,
      computed_at: DateTime.utc_now()
    }
  end

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def force_propagate(entity_id), do: GenServer.call(__MODULE__, {:force_propagate, entity_id})

  def stats, do: GenServer.call(__MODULE__, :stats)

  @impl true
  def init(_opts) do
    EventBus.subscribe("knowledge.promoted", self())
    EventBus.subscribe("knowledge.validated", self())
    EventBus.subscribe("discovery.published", self())
    EventBus.subscribe("engineering.deployment", self())

    schedule_stagnation_check()

    {:ok, %{
      total_knowledge_items: 0,
      propagated_knowledge_items: 0,
      stagnant_items: 0,
      propagation_ledger: %{},
      healthy: true,
      started_at: DateTime.utc_now()
    }}
  end

  @impl true
  def handle_info({:event, event}, state) do
    event_type = event.type
    payload = event.raw_payload

    case event_type do
      :generic ->
        topic = Map.get(payload, :topic, "")
        handle_event_type(topic, payload, state)

      _ ->
        handle_event_type(event_type, payload, state)
    end
  end

  @impl true
  def handle_info(:check_stagnation, state) do
    cutoff_date = DateTime.add(DateTime.utc_now(), -@max_stagnation_days, :day)

    {:ok, result} = WorldQueryEngine.find(
      type: :knowledge_entity,
      status: :active,
      limit: 10_000
    )

    stagnant = Enum.filter(result.results, fn entity ->
      ledger = Map.get(state.propagation_ledger, entity.id, %{targets_reached: [], last_propagated_at: entity.created_at})
      length(ledger.targets_reached) == 0 and DateTime.compare(ledger.last_propagated_at, cutoff_date) == :lt
    end)

    if length(stagnant) > 0 do
      Logger.warning("KnowledgeFlowEngine: Detected #{length(stagnant)} stagnant knowledge items")

      ExecutiveMemory.record_decision(
        "stagnation_alert_#{DateTime.utc_now() |> DateTime.to_unix()}",
        :knowledge_stagnation_detected,
        %{stagnant_count: length(stagnant), sample_ids: Enum.take(stagnant, 5) |> Enum.map(& &1.id)}
      )
    end

    schedule_stagnation_check()
    {:noreply, %{state | stagnant_items: length(stagnant)}}
  end

  @impl true
  def handle_call({:force_propagate, entity_id}, _from, state) do
    {:reply, handle_propagation(entity_id, state), state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, state, state}
  end

  defp handle_event_type(topic, payload, state) do
    entity_id =
      cond do
        Map.has_key?(payload, :entity_id) -> payload.entity_id
        Map.has_key?(payload, :discovery_id) -> payload.discovery_id
        Map.has_key?(payload, :deployment_id) -> payload.deployment_id
        true -> nil
      end

    stage = Map.get(payload, :stage)

    if entity_id do
      cond do
        topic == "knowledge.promoted" and stage in [:pattern, :model, :principle, :generalized_understanding, :scientific_discovery] ->
          handle_propagation(entity_id, state)
          {:noreply, %{state | total_knowledge_items: state.total_knowledge_items + 1}}

        topic in ["knowledge.validated", "discovery.published"] ->
          handle_propagation(entity_id, state)
          {:noreply, state}

        topic == "engineering.deployment" ->
          handle_propagation(entity_id, state)
          {:noreply, state}

        true ->
          {:noreply, state}
      end
    else
      {:noreply, state}
    end
  end

  defp handle_propagation(entity_id, state) do
    case UnifiedWorldModel.get_entity(entity_id) do
      {:ok, entity} ->
        target_domains = identify_target_domains(entity)
        source_domain = Map.get(entity, :owner_subsystem, :unknown)

        propagation_results = Enum.map(target_domains, fn domain ->
          propagate_to_domain(entity, domain)
        end)

        successful_targets = propagation_results
          |> Enum.filter(fn {:ok, _} -> true; _ -> false end)
          |> Enum.map(fn {:ok, d} -> d end)

        current_ledger = Map.get(state.propagation_ledger, entity_id, %{
          targets_reached: [],
          last_propagated_at: entity.created_at || DateTime.utc_now()
        })

        new_targets = Enum.uniq(current_ledger.targets_reached ++ successful_targets)
        new_ledger = %{current_ledger | targets_reached: new_targets, last_propagated_at: DateTime.utc_now()}

        ExecutiveMemory.record_decision(
          "flow_propagate_#{entity_id}",
          :knowledge_propagated,
          %{entity_id: entity_id, targets: successful_targets, source: source_domain}
        )

        was_previously_propagated = length(current_ledger.targets_reached) > 0
        newly_propagated_count = if not was_previously_propagated and length(new_targets) > 0, do: 1, else: 0

        {:ok, %{state |
          propagation_ledger: Map.put(state.propagation_ledger, entity_id, new_ledger),
          propagated_knowledge_items: state.propagated_knowledge_items + newly_propagated_count
        }}

      {:error, _reason} ->
        {:error, :entity_not_found}
    end
  end

  defp identify_target_domains(entity) do
    base_targets = [:executive_memory, :unified_world_model]

    domain_specific_targets =
      case entity.subtype do
        :scientific_discovery -> [:research, :simulation, :engineering]
        :pattern -> [:research, :cci]
        :model -> [:simulation, :engineering, :asc]
        :principle -> [:research, :engineering, :asc, :cci, :governance]
        _ -> []
      end

    Enum.uniq(base_targets ++ domain_specific_targets)
  end

  defp propagate_to_domain(_entity, :executive_memory), do: {:ok, :executive_memory}
  defp propagate_to_domain(_entity, :unified_world_model), do: {:ok, :unified_world_model}

  defp propagate_to_domain(entity, :research) do
    EventBus.publish("research.knowledge_available", %{
      entity_id: entity.id,
      type: entity.subtype,
      confidence: entity.confidence,
      attributes: entity.attributes
    })
    {:ok, :research}
  end

  defp propagate_to_domain(entity, :simulation) do
    EventBus.publish("simulation.knowledge_update", %{
      entity_id: entity.id,
      type: entity.subtype,
      parameters: extract_simulation_parameters(entity)
    })
    {:ok, :simulation}
  end

  defp propagate_to_domain(entity, :engineering) do
    EventBus.publish("engineering.knowledge_available", %{
      entity_id: entity.id,
      type: entity.subtype,
      potential_applications: estimate_applications(entity)
    })
    {:ok, :engineering}
  end

  defp propagate_to_domain(entity, :asc) do
    EventBus.publish("asc.knowledge_integrated", %{
      entity_id: entity.id,
      type: entity.subtype,
      capability_impact: estimate_capability_impact(entity)
    })
    {:ok, :asc}
  end

  defp propagate_to_domain(entity, :cci) do
    EventBus.publish("cci.forecast_update", %{
      entity_id: entity.id,
      type: entity.subtype,
      forecast_impact: :positive
    })
    {:ok, :cci}
  end

  defp propagate_to_domain(_entity, :governance) do
    {:ok, :governance}
  end

  defp propagate_to_domain(_entity, _domain), do: {:ok, :ignored}

  defp extract_simulation_parameters(entity) do
    entity.attributes
    |> Map.filter(fn {_k, v} -> is_number(v) end)
  end

  defp estimate_applications(_entity), do: ["optimization", "efficiency", "design"]

  defp estimate_capability_impact(_entity), do: 0.15

  defp schedule_stagnation_check do
    Process.send_after(self(), :check_stagnation, @stagnation_check_interval)
  end
end
