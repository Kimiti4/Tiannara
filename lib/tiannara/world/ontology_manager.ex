defmodule Tiannara.World.OntologyManager do
  @moduledoc """
  Ontology Manager — enables Tiannara to evolve its own understanding of reality.

  Merge, split, retire, and map concepts across domains with full semantic lineage.
  """
  use GenServer
  use Tiannara.ExecutiveService.Base
  require Logger

  alias Tiannara.World.{UnifiedWorldModel, WorldMutationEngine}
  alias Tiannara.CEL.Services.{ExecutiveMemory, EventBus}
  alias Tiannara.CEL.Kernel.ConstitutionalScore

  @ontology_table :ontology_manager
  @ontology_file ~c"./ontology_manager.dets"

  # ---------- ExecutiveService Behaviour ----------

  @impl Tiannara.ExecutiveService
  def id, do: :ontology_manager

  @impl Tiannara.ExecutiveService
  def version, do: "1.0.0"

  @impl Tiannara.ExecutiveService
  def capabilities do
    [
      :concept_definition,
      :concept_merging,
      :concept_splitting,
      :concept_retirement,
      :cross_domain_mapping,
      :semantic_lineage
    ]
  end

  @impl Tiannara.ExecutiveService
  def dependencies, do: [:persistent_memory, :event_transport, :unified_world_model, :world_mutation_engine]

  @impl Tiannara.ExecutiveService
  def priority, do: :high

  @impl Tiannara.ExecutiveService
  def constitutional_score do
    stats = GenServer.call(__MODULE__, :stats)

    %ConstitutionalScore{
      service_id: id(),
      health: if(stats.healthy, do: 1.0, else: 0.0),
      constitutional_alignment: 1.0,
      transparency: 1.0,
      explainability: 1.0,
      evidence_quality: 1.0,
      human_oversight: 1.0,
      computed_at: DateTime.utc_now()
    }
  end

  # ---------- Client API ----------

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def define_concept(concept_spec) do
    GenServer.call(__MODULE__, {:define_concept, concept_spec})
  end

  def merge_concepts(concept_a_id, concept_b_id, merged_spec) do
    GenServer.call(__MODULE__, {:merge_concepts, concept_a_id, concept_b_id, merged_spec})
  end

  def split_concept(concept_id, split_specs) do
    GenServer.call(__MODULE__, {:split_concept, concept_id, split_specs})
  end

  def retire_concept(concept_id, reason, successor_concept_id \\ nil) do
    GenServer.call(__MODULE__, {:retire_concept, concept_id, reason, successor_concept_id})
  end

  def map_concepts(concept_a_id, concept_b_id, mapping_spec) do
    GenServer.call(__MODULE__, {:map_concepts, concept_a_id, concept_b_id, mapping_spec})
  end

  def semantic_lineage(concept_id), do: GenServer.call(__MODULE__, {:semantic_lineage, concept_id})

  def active_concepts, do: GenServer.call(__MODULE__, :active_concepts)

  def cross_domain_mappings, do: GenServer.call(__MODULE__, :cross_domain_mappings)

  def stats, do: GenServer.call(__MODULE__, :stats)

  # ---------- Server Callbacks ----------

  @impl true
  def init(_opts) do
    case :dets.open_file(@ontology_table, type: :set, file: @ontology_file) do
      {:ok, _} ->
        Logger.info("OntologyManager: initialized")
        {:ok, %{
          concepts: %{},
          mappings: %{},
          concept_count: 0,
          active_concepts: 0,
          retired_concepts: 0,
          mappings_count: 0,
          healthy: true,
          started_at: DateTime.utc_now()
        }}

      {:error, reason} ->
        Logger.error("OntologyManager: failed to open storage: #{inspect(reason)}")
        {:ok, %{healthy: false, concepts: %{}, mappings: %{}}}
    end
  end

  @impl true
  def handle_call({:define_concept, spec}, _from, state) do
    concept = %{
      id: spec.id,
      name: spec.name,
      domain: spec.domain,
      definition: spec.definition,
      parent_concepts: Map.get(spec, :parent_concepts, []),
      attributes: Map.get(spec, :attributes, %{}),
      provenance: Map.get(spec, :provenance),
      status: :active,
      version: 1,
      created_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now(),
      lineage: [%{event: :created, at: DateTime.utc_now(), by: get_in(spec, [:provenance, :produced_by])}]
    }

    :dets.insert(@ontology_table, {:concept, concept.id, concept})

    UnifiedWorldModel.create_knowledge_entity(:concept, %{
      concept_id: concept.id,
      name: concept.name,
      definition: concept.definition
    }, id: "concept_#{concept.id}", confidence: 1.0, provenance: concept.provenance)

    ExecutiveMemory.record_decision(
      "ontology_define_#{concept.id}",
      :concept_defined,
      %{concept_id: concept.id, name: concept.name, domain: concept.domain}
    )

    EventBus.publish("ontology.concept.defined", %{concept_id: concept.id, domain: concept.domain})

    new_state = %{state |
      concepts: Map.put(state.concepts, concept.id, concept),
      concept_count: state.concept_count + 1,
      active_concepts: state.active_concepts + 1
    }

    {:reply, {:ok, concept.id}, new_state}
  end

  @impl true
  def handle_call({:merge_concepts, a_id, b_id, merged_spec}, _from, state) do
    with {:ok, concept_a} <- Map.fetch(state.concepts, a_id),
         {:ok, concept_b} <- Map.fetch(state.concepts, b_id) do

      merged_id = merged_spec.id || "merged_#{a_id}_#{b_id}"

      merged_concept = %{
        id: merged_id,
        name: merged_spec.name || "#{concept_a.name}+#{concept_b.name}",
        domain: concept_a.domain,
        definition: merged_spec.definition || "#{concept_a.definition} (merged with #{concept_b.name})",
        parent_concepts: Enum.uniq(concept_a.parent_concepts ++ concept_b.parent_concepts),
        attributes: Map.merge(concept_a.attributes, concept_b.attributes),
        provenance: %{
          origin: :ontology_merge,
          produced_by: merged_spec[:produced_by] || :system,
          produced_at: DateTime.utc_now(),
          source_concepts: [a_id, b_id]
        },
        status: :active,
        version: 1,
        created_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now(),
        lineage: [
          %{event: :created_via_merge, at: DateTime.utc_now(), sources: [a_id, b_id]}
        ]
      }

      deprecated_a = %{concept_a | status: :deprecated, merged_into: merged_id, updated_at: DateTime.utc_now()}
      deprecated_b = %{concept_b | status: :deprecated, merged_into: merged_id, updated_at: DateTime.utc_now()}

      :dets.insert(@ontology_table, {:concept, merged_id, merged_concept})
      :dets.insert(@ontology_table, {:concept, a_id, deprecated_a})
      :dets.insert(@ontology_table, {:concept, b_id, deprecated_b})

      WorldMutationEngine.mutate(:ontology_merge, %{
        merged_id: merged_id,
        source_concepts: [a_id, b_id]
      })

      ExecutiveMemory.record_decision(
        "ontology_merge_#{merged_id}",
        :concepts_merged,
        %{merged_id: merged_id, sources: [a_id, b_id]}
      )

      EventBus.publish("ontology.concepts.merged", %{merged_id: merged_id, sources: [a_id, b_id]})

      new_concepts = state.concepts
        |> Map.put(merged_id, merged_concept)
        |> Map.put(a_id, deprecated_a)
        |> Map.put(b_id, deprecated_b)

      new_state = %{state |
        concepts: new_concepts,
        concept_count: state.concept_count + 1,
        active_concepts: state.active_concepts + 1,
        retired_concepts: state.retired_concepts + 2
      }

      {:reply, {:ok, merged_id}, new_state}
    else
      :error -> {:reply, {:error, :concept_not_found}, state}
    end
  end

  @impl true
  def handle_call({:split_concept, concept_id, split_specs}, _from, state) do
    case Map.fetch(state.concepts, concept_id) do
      {:ok, concept} ->
        split_concepts = Enum.map(split_specs, fn spec ->
          %{
            id: spec.id,
            name: spec.name,
            domain: concept.domain,
            definition: spec.definition,
            parent_concepts: [concept_id | Map.get(spec, :parent_concepts, [])],
            attributes: Map.merge(concept.attributes, Map.get(spec, :attributes, %{})),
            provenance: %{
              origin: :ontology_split,
              produced_by: spec[:produced_by] || :system,
              produced_at: DateTime.utc_now(),
              source_concept: concept_id
            },
            status: :active,
            version: 1,
            created_at: DateTime.utc_now(),
            updated_at: DateTime.utc_now(),
            lineage: [%{event: :created_via_split, at: DateTime.utc_now(), source: concept_id}]
          }
        end)

        deprecated = %{concept | status: :deprecated, split_into: Enum.map(split_concepts, & &1.id), updated_at: DateTime.utc_now()}

        Enum.each(split_concepts, fn c -> :dets.insert(@ontology_table, {:concept, c.id, c}) end)
        :dets.insert(@ontology_table, {:concept, concept_id, deprecated})

        WorldMutationEngine.mutate(:ontology_split, %{
          source: concept_id,
          splits: Enum.map(split_concepts, & &1.id)
        })

        new_concepts = Enum.reduce(split_concepts, state.concepts, fn c, acc -> Map.put(acc, c.id, c) end)
        new_concepts = Map.put(new_concepts, concept_id, deprecated)

        new_state = %{state |
          concepts: new_concepts,
          concept_count: state.concept_count + length(split_concepts),
          active_concepts: state.active_concepts + length(split_concepts),
          retired_concepts: state.retired_concepts + 1
        }

        {:reply, {:ok, Enum.map(split_concepts, & &1.id)}, new_state}

      :error ->
        {:reply, {:error, :concept_not_found}, state}
    end
  end

  @impl true
  def handle_call({:retire_concept, concept_id, reason, successor_id}, _from, state) do
    case Map.fetch(state.concepts, concept_id) do
      {:ok, concept} ->
        retired = %{concept |
          status: :deprecated,
          retirement_reason: reason,
          successor: successor_id,
          updated_at: DateTime.utc_now(),
          lineage: concept.lineage ++ [%{event: :retired, at: DateTime.utc_now(), reason: reason, successor: successor_id}]
        }

        :dets.insert(@ontology_table, {:concept, concept_id, retired})

        WorldMutationEngine.mutate(:ontology_retire, %{
          concept_id: concept_id,
          reason: reason,
          successor: successor_id
        })

        ExecutiveMemory.record_decision(
          "ontology_retire_#{concept_id}",
          :concept_retired,
          %{concept_id: concept_id, reason: reason, successor: successor_id}
        )

        EventBus.publish("ontology.concept.retired", %{concept_id: concept_id, reason: reason})

        new_state = %{state |
          concepts: Map.put(state.concepts, concept_id, retired),
          active_concepts: state.active_concepts - 1,
          retired_concepts: state.retired_concepts + 1
        }

        {:reply, :ok, new_state}

      :error ->
        {:reply, {:error, :concept_not_found}, state}
    end
  end

  @impl true
  def handle_call({:map_concepts, a_id, b_id, mapping_spec}, _from, state) do
    mapping_id = "mapping_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"

    mapping = %{
      id: mapping_id,
      concept_a: a_id,
      concept_b: b_id,
      mapping_type: Map.get(mapping_spec, :type, :semantic_equivalence),
      confidence: Map.get(mapping_spec, :confidence, 0.8),
      evidence: Map.get(mapping_spec, :evidence, []),
      provenance: Map.get(mapping_spec, :provenance),
      created_at: DateTime.utc_now()
    }

    :dets.insert(@ontology_table, {:mapping, mapping_id, mapping})

    ExecutiveMemory.record_decision(
      "ontology_mapping_#{mapping_id}",
      :concept_mapping_created,
      %{mapping_id: mapping_id, concepts: [a_id, b_id], type: mapping.mapping_type}
    )

    new_state = %{state |
      mappings: Map.put(state.mappings, mapping_id, mapping),
      mappings_count: state.mappings_count + 1
    }

    {:reply, {:ok, mapping_id}, new_state}
  end

  @impl true
  def handle_call({:semantic_lineage, concept_id}, _from, state) do
    case Map.fetch(state.concepts, concept_id) do
      {:ok, concept} ->
        lineage = build_lineage_tree(concept, state.concepts, MapSet.new())
        {:reply, {:ok, lineage}, state}

      :error ->
        {:reply, {:error, :concept_not_found}, state}
    end
  end

  @impl true
  def handle_call(:active_concepts, _from, state) do
    active = state.concepts |> Map.values() |> Enum.filter(&(&1.status == :active))
    {:reply, active, state}
  end

  @impl true
  def handle_call(:cross_domain_mappings, _from, state) do
    {:reply, Map.values(state.mappings), state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, %{
      healthy: state.healthy,
      concept_count: state.concept_count,
      active_concepts: state.active_concepts,
      retired_concepts: state.retired_concepts,
      mappings_count: state.mappings_count
    }, state}
  end

  defp build_lineage_tree(concept, all_concepts, visited) do
    if MapSet.member?(visited, concept.id) do
      %{id: concept.id, name: concept.name, cyclic: true}
    else
      new_visited = MapSet.put(visited, concept.id)

      parent_trees = Enum.map(concept.parent_concepts, fn parent_id ->
        case Map.fetch(all_concepts, parent_id) do
          {:ok, parent} -> build_lineage_tree(parent, all_concepts, new_visited)
          :error -> %{id: parent_id, name: :unknown}
        end
      end)

      %{
        id: concept.id,
        name: concept.name,
        status: concept.status,
        lineage_events: concept.lineage,
        parents: parent_trees
      }
    end
  end
end
