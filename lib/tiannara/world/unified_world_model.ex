defmodule Tiannara.World.UnifiedWorldModel do
  use GenServer
  use Tiannara.ExecutiveService.Base
  require Logger

  alias Tiannara.World.{UnifiedRealityGraph, ProvenanceEngine, WorldMutationEngine}
  alias Tiannara.CEL.Services.EventBus
  alias Tiannara.CEL.Kernel.ConstitutionalScore

  @canonical_types Tiannara.World.CanonicalWorldState.domain_entity_types()
                   |> Map.values()
                   |> List.flatten()
  @entity_types [
                  :physical_entity,
                  :scientific_entity,
                  :engineering_entity,
                  :resource_entity,
                  :agent_entity,
                  :mission_entity,
                  :capability_entity,
                  :knowledge_entity,
                  :event_entity,
                  :constraint_entity
                ] ++ @canonical_types

  @relationship_types [
    :causes,
    :caused_by,
    :supports,
    :refutes,
    :depends_on,
    :required_by,
    :derived_from,
    :generalizes,
    :part_of,
    :contains,
    :observed_by,
    :validated_by,
    :consumes,
    :produces,
    :constrained_by
  ]

  @impl true
  def id, do: :unified_world_model

  @impl true
  def version, do: "1.0.0"

  @impl true
  def capabilities do
    [
      :canonical_world_representation,
      :typed_entity_management,
      :typed_relationship_management,
      :provenance_integration,
      :mutation_auditability,
      :cross_domain_queries,
      :event_driven_synchronization
    ]
  end

  @impl true
  def dependencies do
    [
      :executive_memory,
      :executive_service_bus,
      :unified_reality_graph,
      :provenance_engine,
      :world_mutation_engine
    ]
  end

  @impl true
  def health, do: if(Process.whereis(__MODULE__), do: :healthy, else: :unhealthy)

  @impl true
  def constitutional_score do
    stats =
      if Process.whereis(__MODULE__),
        do: GenServer.call(__MODULE__, :stats),
        else: %{
          entity_count: 0,
          entities_with_provenance: 0,
          relationship_count: 0,
          healthy: true
        }

    ev_qual =
      if stats.entity_count > 0,
        do: stats.entities_with_provenance / stats.entity_count,
        else: 1.0

    %ConstitutionalScore{
      service_id: id(),
      health: if(stats.healthy, do: 1.0, else: 0.0),
      constitutional_alignment: 1.0,
      transparency: 1.0,
      explainability: 1.0,
      evidence_quality: ev_qual,
      human_oversight: 1.0,
      computed_at: DateTime.utc_now()
    }
  end

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def create_entity(spec), do: GenServer.call(__MODULE__, {:create_entity, spec})
  def get_entity(entity_id), do: GenServer.call(__MODULE__, {:get_entity, entity_id})

  def update_entity(entity_id, updates, context \\ nil),
    do: GenServer.call(__MODULE__, {:update_entity, entity_id, updates, context})

  def delete_entity(entity_id), do: GenServer.call(__MODULE__, {:delete_entity, entity_id})

  def transition_stage(entity_id, target_stage),
    do: GenServer.call(__MODULE__, {:transition_stage, entity_id, target_stage})

  def refute_entity(entity_id, reason, context \\ nil),
    do: GenServer.call(__MODULE__, {:refute_entity, entity_id, reason, context})

  def create_relationship(spec), do: GenServer.call(__MODULE__, {:create_relationship, spec})

  def get_relationships(entity_id, opts \\ []),
    do: GenServer.call(__MODULE__, {:get_relationships, entity_id, opts})

  def create_scientific_entity(subtype, attributes, opts \\ []),
    do: create_entity(build_spec(:scientific_entity, subtype, attributes, opts))

  def create_engineering_entity(subtype, attributes, opts \\ []),
    do: create_entity(build_spec(:engineering_entity, subtype, attributes, opts))

  def create_resource_entity(subtype, attributes, opts \\ []),
    do: create_entity(build_spec(:resource_entity, subtype, attributes, opts))

  def create_mission_entity(subtype, attributes, opts \\ []),
    do: create_entity(build_spec(:mission_entity, subtype, attributes, opts))

  def create_knowledge_entity(subtype, attributes, opts \\ []),
    do: create_entity(build_spec(:knowledge_entity, subtype, attributes, opts))

  def stats, do: GenServer.call(__MODULE__, :stats)

  @impl true
  def init(_opts) do
    Logger.info("UnifiedWorldModel: initialized as canonical world representation")

    {:ok,
     %{
       type_counts: Map.new(@entity_types, &{&1, 0}),
       rel_type_counts: Map.new(@relationship_types, &{&1, 0}),
       total_entities: 0,
       total_relationships: 0,
       entities_with_provenance: 0,
       healthy: true,
       started_at: DateTime.utc_now()
     }}
  end

  @max_entities 1_000_000
  @max_relationships 10_000_000

  @impl true
  def handle_call({:create_entity, spec}, _from, state) do
    if state.total_entities >= @max_entities do
      {:reply, {:error, :entity_count_exceeded}, state}
    else
      with :ok <- validate_entity(spec) do
        case WorldMutationEngine.mutate(:create_entity, spec, spec[:constitutional_context]) do
          {:ok, mutation_id} ->
            conf = Map.get(spec, :confidence, 0.5)

            entity = %{
              id: spec.id,
              type: spec.type,
              subtype: Map.get(spec, :subtype),
              domain: Map.get(spec, :domain),
              attributes: Map.get(spec, :attributes, %{}),
              confidence: conf,
              uncertainty: 1.0 - conf,
              status: :active,
              owner_subsystem: Map.get(spec, :owner_subsystem),
              provenance: Map.get(spec, :provenance),
              mutation_id: mutation_id,
              created_at: DateTime.utc_now(),
              updated_at: DateTime.utc_now(),
              version: 1
            }

            case UnifiedRealityGraph.add_entity(entity) do
              {:ok, eid} ->
                if Map.has_key?(spec, :provenance),
                  do:
                    ProvenanceEngine.record_provenance(Map.put(spec.provenance, :entity_id, eid))

                prov = if(Map.has_key?(spec, :provenance), do: 1, else: 0)

                ns = %{
                  state
                  | type_counts: Map.update!(state.type_counts, spec.type, &(&1 + 1)),
                    total_entities: state.total_entities + 1,
                    entities_with_provenance: state.entities_with_provenance + prov
                }

                EventBus.publish(
                  "world.entity.created",
                  %{
                    entity_id: eid,
                    type: spec.type,
                    subtype: Map.get(spec, :subtype),
                    mutation_id: mutation_id
                  },
                  []
                )

                {:reply, {:ok, eid}, ns}

              err ->
                {:reply, err, state}
            end

          err ->
            {:reply, err, state}
        end
      else
        {:error, r} -> {:reply, {:error, r}, state}
      end
    end
  end

  @impl true
  def handle_call({:get_entity, entity_id}, _from, state) do
    {:reply, UnifiedRealityGraph.get_entity(entity_id), state}
  end

  @impl true
  def handle_call({:delete_entity, entity_id}, _from, state) do
    case UnifiedRealityGraph.get_entity(entity_id) do
      {:ok, entity} ->
        UnifiedRealityGraph.remove_entity(entity_id)
        UnifiedRealityGraph.remove_relationships_for_entity(entity_id)
        EventBus.publish("world.entity.deleted", %{entity_id: entity_id})
        ent_type = Map.get(entity, :type, :unknown)

        ns = %{
          state
          | total_entities: max(0, state.total_entities - 1),
            type_counts: Map.update!(state.type_counts, ent_type, &max(0, &1 - 1))
        }

        {:reply, :ok, ns}

      err ->
        {:reply, err, state}
    end
  end

  @impl true
  def handle_call({:update_entity, entity_id, updates, context}, _from, state) do
    case UnifiedRealityGraph.get_entity(entity_id) do
      {:ok, current} ->
        case WorldMutationEngine.mutate(
               :update_entity,
               %{id: entity_id, current: current, updates: updates},
               context
             ) do
          {:ok, mutation_id} ->
            new_attrs = Map.merge(Map.get(current, :attributes, %{}) || %{}, updates)
            new_conf = Map.get(updates, :confidence, current.confidence)

            updated = %{
              current
              | attributes: new_attrs,
                confidence: new_conf,
                uncertainty: 1.0 - new_conf,
                updated_at: DateTime.utc_now(),
                version: current.version + 1
            }

            UnifiedRealityGraph.add_entity(updated)

            EventBus.publish(
              "world.entity.updated",
              %{entity_id: entity_id, mutation_id: mutation_id, updates: Map.keys(updates)},
              []
            )

            {:reply, :ok, state}

          err ->
            {:reply, err, state}
        end

      err ->
        {:reply, err, state}
    end
  end

  @impl true
  def handle_call({:refute_entity, entity_id, reason, context}, _from, state) do
    case UnifiedRealityGraph.get_entity(entity_id) do
      {:ok, current} ->
        case WorldMutationEngine.mutate(
               :refute_entity,
               %{id: entity_id, current: current, reason: reason},
               context
             ) do
          {:ok, mutation_id} ->
            refuted = %{
              current
              | status: :refuted,
                refutation_reason: reason,
                updated_at: DateTime.utc_now()
            }

            UnifiedRealityGraph.add_entity(refuted)

            UnifiedRealityGraph.propagate_uncertainty(entity_id, 0.0, %{
              type: :refutation,
              reason: reason,
              mutation_id: mutation_id
            })

            EventBus.publish(
              "world.entity.refuted",
              %{entity_id: entity_id, reason: reason, mutation_id: mutation_id},
              []
            )

            {:reply, :ok, state}

          err ->
            {:reply, err, state}
        end

      err ->
        {:reply, err, state}
    end
  end

  @impl true
  def handle_call({:create_relationship, spec}, _from, state) do
    if state.total_relationships >= @max_relationships do
      {:reply, {:error, :relationship_count_exceeded}, state}
    else
      with :ok <- validate_rel(spec) do
        case WorldMutationEngine.mutate(:create_relationship, spec, spec[:constitutional_context]) do
          {:ok, mutation_id} ->
            case UnifiedRealityGraph.add_relationship(spec) do
              {:ok, edge} ->
                ns = %{
                  state
                  | rel_type_counts: Map.update!(state.rel_type_counts, spec.type, &(&1 + 1)),
                    total_relationships: state.total_relationships + 1
                }

                EventBus.publish(
                  "world.relationship.created",
                  %{
                    from_id: spec.from_id,
                    to_id: spec.to_id,
                    type: spec.type,
                    mutation_id: mutation_id
                  },
                  []
                )

                {:reply, {:ok, edge}, ns}

              err ->
                {:reply, err, state}
            end

          err ->
            {:reply, err, state}
        end
      else
        {:error, r} -> {:reply, {:error, r}, state}
      end
    end
  end

  @impl true
  def handle_call({:get_relationships, entity_id, opts}, _from, state) do
    dir = Keyword.get(opts, :direction, :both)
    tf = Keyword.get(opts, :type)
    {:reply, UnifiedRealityGraph.get_relationships(entity_id, dir, tf), state}
  end

  @impl true
  def handle_call({:transition_stage, entity_id, target_stage}, _from, state) do
    case UnifiedRealityGraph.get_entity(entity_id) do
      {:ok, current} ->
        case WorldMutationEngine.mutate(
               :update_entity,
               %{id: entity_id, current: current, updates: %{subtype: target_stage}},
               nil
             ) do
          {:ok, _mutation_id} ->
            updated = Map.put(current, :subtype, target_stage)
            UnifiedRealityGraph.add_entity(updated)

            EventBus.publish(
              "world.entity.updated",
              %{entity_id: entity_id, subtype: target_stage},
              []
            )

            {:reply, :ok, state}

          err ->
            {:reply, err, state}
        end

      err ->
        {:reply, err, state}
    end
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply,
     %{
       healthy: state.healthy,
       entity_count: state.total_entities,
       relationship_count: state.total_relationships,
       entities_with_provenance: state.entities_with_provenance,
       entity_type_distribution: state.type_counts,
       relationship_type_distribution: state.rel_type_counts
     }, state}
  end

  defp validate_entity(spec) do
    cond do
      not Map.has_key?(spec, :id) ->
        {:error, :missing_id}

      not Map.has_key?(spec, :type) ->
        {:error, :missing_type}

      spec.type not in @entity_types ->
        {:error, {:invalid_type, spec.type}}

      true ->
        conf = Map.get(spec, :confidence, 0.5)
        unc = Map.get(spec, :uncertainty, 1.0 - conf)

        if abs(conf + unc - 1.0) > 0.01 do
          {:error, :confidence_uncertainty_invariant_broken}
        else
          :ok
        end
    end
  end

  defp validate_rel(spec) do
    cond do
      not Map.has_key?(spec, :from_id) -> {:error, :missing_from_id}
      not Map.has_key?(spec, :to_id) -> {:error, :missing_to_id}
      not Map.has_key?(spec, :type) -> {:error, :missing_type}
      spec.type not in @relationship_types -> {:error, {:invalid_type, spec.type}}
      true -> :ok
    end
  end

  defp build_spec(type, subtype, attrs, opts) do
    %{
      id: Keyword.get(opts, :id) || gen_id(type, subtype),
      type: type,
      subtype: subtype,
      attributes: attrs,
      confidence: Keyword.get(opts, :confidence, 0.5),
      uncertainty: 1.0 - Keyword.get(opts, :confidence, 0.5),
      provenance: Keyword.get(opts, :provenance),
      constitutional_context: Keyword.get(opts, :constitutional_context)
    }
  end

  defp gen_id(type, subtype),
    do: "#{type}_#{subtype}_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"
end
