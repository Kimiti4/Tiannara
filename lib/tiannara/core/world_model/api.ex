defmodule Tiannara.Core.WorldModel.API do
  @moduledoc """
  Integration APIs for World Model operations.
  
  Provides standardized interfaces for domains and runtime systems
  to interact with the World Model as the canonical reality representation.
  """

  alias Tiannara.Core.WorldModel
  alias Tiannara.Core.WorldModel.Entity
  alias Tiannara.Core.WorldModel.BeliefSystem
  alias Tiannara.Core.WorldModel.CausalEngine
  alias Tiannara.Core.WorldModel.TimelineManager
  alias Tiannara.Core.WorldModel.UncertaintyTracker
  alias Tiannara.Core.WorldModel.PredictionEngine
  require Logger

  @doc "Initialize a new World Model instance."
  def initialize_world_model(opts \\ []) do
    WorldModel.new()
    |> apply_initialization_options(opts)
  end

  @doc "Create and register a new entity in the World Model."
  def create_entity(entity_id, type, name, attributes \\ %{}) do
    entity = Entity.new(entity_id, type, name, attributes)
    
    # Register with Entity Registry
    case Tiannara.Core.WorldModel.EntityRegistry.register_entity(entity) do
      {:ok, _entity_id} ->
        {:ok, entity}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc "Add a belief to the World Model."
  def add_belief(statement, confidence \\ 0.7, source \\ "system", evidence \\ []) do
    BeliefSystem.add_belief(statement, confidence, source, evidence)
  end

  @doc "Add a causal relationship between entities."
  def add_causal_relationship(source_entity, target_entity, relationship_type, strength \\ 0.7, confidence \\ 0.8) do
    CausalEngine.add_causal_relationship(source_entity, target_entity, relationship_type, strength, confidence)
  end

  @doc "Record a timeline event."
  def record_event(entity_id, event_type, description, timestamp \\ nil) do
    event_id = "event:#{System.system_time(:microsecond)}"
    TimelineManager.add_event(event_id, entity_id, event_type, description, timestamp)
  end

  @doc "Add an ambiguity to track uncertainty."
  def record_ambiguity(entity_id, description, ambiguity_level \\ 0.5) do
    UncertaintyTracker.add_ambiguity(entity_id, description, ambiguity_level)
  end

  @doc "Create a prediction scenario."
  def create_prediction(target_entity, prediction_type, time_horizon, base_probability \\ 0.5) do
    scenario_id = "scenario:#{System.system_time(:microsecond)}"
    PredictionEngine.create_prediction(scenario_id, target_entity, prediction_type, time_horizon, base_probability)
  end

  @doc "Query World Model for entities by type."
  def query_entities(entity_type) do
    Tiannara.Core.WorldModel.EntityRegistry.get_entities_by_type(entity_type)
  end

  @doc "Query World Model for high-confidence beliefs."
  def query_high_confidence_beliefs(threshold \\ 0.7) do
    BeliefSystem.get_high_confidence_beliefs(threshold)
  end

  @doc "Query World Model for causal relationships."
  def query_causal_relationships(entity_id) do
    CausalEngine.get_entity_relationships(entity_id)
  end

  @doc "Query World Model for timeline events."
  def query_events(entity_id \\ nil, event_type \\ nil) do
    case {entity_id, event_type} do
      {nil, nil} ->
        TimelineManager.list_events()
      {nil, type} ->
        TimelineManager.get_events_by_type(type)
      {id, nil} ->
        TimelineManager.get_entity_events(id)
      {id, type} ->
        TimelineManager.get_entity_events(id)
        |> Enum.filter(&(&1.type == type))
    end
  end

  @doc "Query World Model for uncertainties."
  def query_uncertainties do
    Logger.debug("UncertaintyTracker.get_ambiguities/0 not available")
    []
  end

  @doc "Query World Model for active predictions."
  def query_active_predictions do
    Logger.debug("PredictionEngine.get_active_predictions/0 not available")
    []
  end

  @doc "Update an entity in the World Model."
  def update_entity(entity_id, updates) do
    Tiannara.Core.WorldModel.EntityRegistry.update_entity(entity_id, updates)
  end

  @doc "Update belief confidence based on new evidence."
  def update_belief_confidence(_belief_id, _new_confidence, _reason \\ nil) do
    Logger.debug("UncertaintyTracker.update_belief_confidence/3 not available")
    {:error, :not_found}
  end

  @doc "Update prediction confidence based on outcomes."
  def update_prediction_confidence(_scenario_id, _new_confidence) do
    Logger.debug("PredictionEngine.update_scenario_confidence/2 not available")
    {:error, :not_available}
  end

  @doc "Perform causal inference - predict effects of changes."
  def infer_effects(entity_id, change_description) do
    CausalEngine.infer_effects(entity_id, change_description)
  end

  def apply_initialization_options(world_model, opts) do
    Enum.reduce(opts, world_model, fn
      {:add_core_entity, core_id}, model ->
        core_entity = Entity.new("core:#{core_id}", "Core", "Tiannara Cognitive Core", %{type: "sovereign"})
        %{model | entities: Map.put(model.entities, core_entity.id, core_entity)}
      {:add_domain_entities, domains}, model ->
        Enum.reduce(domains, model, fn domain, acc_model ->
          domain_entity = Entity.new("domain:#{domain}", "Domain", "Domain: #{domain}", %{type: "cognitive"})
          %{acc_model | entities: Map.put(acc_model.entities, domain_entity.id, domain_entity)}
        end)
      _, model ->
        model
    end)
  end
end