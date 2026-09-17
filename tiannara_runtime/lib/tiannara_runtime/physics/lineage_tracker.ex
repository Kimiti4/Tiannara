defmodule Tiannara.Physics.LineageTracker do
  @moduledoc """
  Physics Law Lineage Tracker - Records mutation chains of CAL/CIS/entropy rules.
  
  Tracks every physics law change as an animated biography, enabling:
  - Full evolutionary replay of law mutations
  - Divergence tree visualization (where laws split into variants)
  - Extinction and resurrection tracking
  - Historical comparison of law versions
  
  ## Data Model
  
      LawLineage: %{
        law_id: String.t(),
        law_type: :cal | :cis | :entropy | :selection,
        mutation_chain: [mutation_record()],
        created_at: DateTime.t(),
        last_mutated: DateTime.t(),
        status: :active | :extinct | :resurrected,
        extinction_count: non_neg_integer()
      }
      
      MutationRecord: %{
        version: integer(),
        timestamp: DateTime.t(),
        old_form: any(),
        new_form: any(),
        mutation_reason: String.t(),
        entropy_context: float(),
        fitness_impact: float()
      }
  """

  use GenServer
  require Logger

  alias Tiannara.Meta.Memory.LawArchive

  @type law_type :: :cal | :cis | :entropy | :selection
  @type law_status :: :active | :extinct | :resurrected

  @type t :: %__MODULE__{
    law_id: String.t(),
    law_type: law_type(),
    mutation_chain: [mutation_record()],
    created_at: DateTime.t(),
    last_mutated: DateTime.t(),
    status: law_status(),
    extinction_count: non_neg_integer()
  }

  @type mutation_record :: %{
    version: non_neg_integer(),
    timestamp: DateTime.t(),
    old_form: any(),
    new_form: any(),
    mutation_reason: String.t(),
    entropy_context: float(),
    fitness_impact: float()
  }

  defstruct [
    :law_id,
    :law_type,
    :mutation_chain,
    :created_at,
    :last_mutated,
    :status,
    :extinction_count
  ]

  # ==================== GenServer API ====================

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    # Initialize ETS table for lineage storage
    :ets.new(:law_lineages, [:named_table, :set, :public])
    
    Logger.info("🧬 LineageTracker initialized (physics law evolution history)")
    {:ok, %{total_tracked: 0, total_mutations: 0}}
  end

  # ==================== Public API ====================

  @doc """
  Record a new physics law mutation.
  
  Creates or updates the lineage chain for this law.
  """
  def record_mutation(law_id, law_type, old_form, new_form, reason, entropy_context, fitness_impact) do
    GenServer.cast(__MODULE__, {:mutation, law_id, law_type, old_form, new_form, reason, entropy_context, fitness_impact})
  end

  @doc """
  Record a chimeric merge event that creates a new hybrid law.
  """
  def record_merge_lineage(surviving_id, consumed_ids, merge_metadata) do
    GenServer.cast(__MODULE__, {:merge, surviving_id, consumed_ids, merge_metadata})
  end

  @doc """
  Mark a law as extinct (no longer active in any world).
  """
  def mark_extinct(law_id, reason) do
    GenServer.cast(__MODULE__, {:extinct, law_id, reason})
  end

  @doc """
  Mark a law as resurrected (reactivated from archive).
  """
  def mark_resurrected(law_id, resurrection_context) do
    GenServer.cast(__MODULE__, {:resurrected, law_id, resurrection_context})
  end

  @doc """
  Get full biography of a law (complete mutation history).
  """
  def get_law_biography(law_id) do
    GenServer.call(__MODULE__, {:get_biography, law_id})
  end

  @doc """
  Get divergence tree for a law family (all variants that split from original).
  """
  def get_divergence_tree(root_law_id) do
    GenServer.call(__MODULE__, {:get_divergence, root_law_id})
  end

  @doc """
  Get all active laws with their current versions.
  """
  def get_active_laws do
    GenServer.call(__MODULE__, :get_active)
  end

  @doc """
  Get lineage statistics.
  """
  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  # ==================== GenServer Callbacks ====================

  @impl true
  def handle_cast({:mutation, law_id, law_type, old_form, new_form, reason, entropy_context, fitness_impact}, state) do
    lineage = get_or_create_lineage(law_id, law_type)
    
    # Determine version number
    version = length(lineage.mutation_chain) + 1
    
    mutation = %{
      version: version,
      timestamp: DateTime.utc_now(),
      old_form: old_form,
      new_form: new_form,
      mutation_reason: reason,
      entropy_context: entropy_context,
      fitness_impact: fitness_impact
    }
    
    updated_lineage = %{
      lineage |
      mutation_chain: lineage.mutation_chain ++ [mutation],
      last_mutated: DateTime.utc_now(),
      status: :active
    }
    
    :ets.insert(:law_lineages, {law_id, updated_lineage})
    
    # Publish mutation event via NATS
    publish_mutation_event(updated_lineage, mutation)
    
    Logger.info("🧬 Recorded mutation #{law_id} v#{version} (#{reason})")
    {:noreply, %{state | total_tracked: state.total_tracked + 1, total_mutations: state.total_mutations + 1}}
  end

  @impl true
  def handle_cast({:merge, surviving_id, consumed_ids, metadata}, state) do
    # Create new lineage for merged law
    parent_lineages = Enum.map(consumed_ids, &get_lineage/1) |> Enum.filter(& &1)
    
    merged_lineage = %__MODULE__{
      law_id: surviving_id,
      law_type: determine_merged_type(parent_lineages),
      mutation_chain: [%{
        version: 1,
        timestamp: DateTime.utc_now(),
        old_form: nil,
        new_form: "chimeric_merge",
        mutation_reason: "subsystem_recombination",
        entropy_context: Map.get(metadata, "entropy", 0.5),
        fitness_impact: Map.get(metadata, "fitness_delta", 0.0)
      }],
      created_at: DateTime.utc_now(),
      last_mutated: DateTime.utc_now(),
      status: :active,
      extinction_count: 0
    }
    
    :ets.insert(:law_lineages, {surviving_id, merged_lineage})
    
    Logger.info("🔀 Created merged lineage #{surviving_id} from #{length(consumed_ids)} parents")
    {:noreply, state}
  end

  @impl true
  def handle_cast({:extinct, law_id, reason}, state) do
    case get_lineage(law_id) do
      nil ->
        Logger.warning("⚠️  Cannot mark extinct: unknown law #{law_id}")
      
      lineage ->
        updated = %{lineage | status: :extinct, extinction_count: lineage.extinction_count + 1}
        :ets.insert(:law_lineages, {law_id, updated})
        
        # Archive the extinct law in thermodynamic memory
        archive_extinct_law(updated, reason)
        
        Logger.info("💀 Law #{law_id} marked extinct (#{reason})")
    end
    
    {:noreply, state}
  end

  @impl true
  def handle_cast({:resurrected, law_id, context}, state) do
    case get_lineage(law_id) do
      nil ->
        Logger.warning("⚠️  Cannot resurrect: unknown law #{law_id}")
      
      lineage ->
        updated = %{lineage | status: :resurrected}
        :ets.insert(:law_lineages, {law_id, updated})
        
        Logger.info("⚡ Law #{law_id} resurrected")
    end
    
    {:noreply, state}
  end

  @impl true
  def handle_call({:get_biography, law_id}, _from, state) do
    biography = case get_lineage(law_id) do
      nil -> {:error, :not_found}
      lineage -> {:ok, format_biography(lineage)}
    end
    
    {:reply, biography, state}
  end

  @impl true
  def handle_call({:get_divergence, root_law_id}, _from, state) do
    root_lineage = get_lineage(root_law_id)
    
    if root_lineage do
      all_lineages = :ets.foldl(fn {_id, lineage}, acc -> [lineage | acc] end, [], :law_lineages)
      
      {variants, max_depth} = build_divergence_tree(root_lineage, all_lineages, root_lineage.law_type)
      
      divergence = %{
        root: root_law_id,
        variants: variants,
        depth: max_depth
      }
      
      {:reply, {:ok, divergence}, state}
    else
      {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call(:get_active, _from, state) do
    active_laws = :ets.foldl(fn {_id, lineage}, acc ->
      if lineage.status == :active or lineage.status == :resurrected do
        [format_law_summary(lineage) | acc]
      else
        acc
      end
    end, [], :law_lineages)
    
    {:reply, {:ok, active_laws}, state}
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    stats = :ets.foldl(fn {_id, lineage}, acc ->
      Map.update(acc, lineage.status, 1, &(&1 + 1))
    end, %{active: 0, extinct: 0, resurrected: 0}, :law_lineages)
    
    stats = Map.merge(stats, %{
      total_tracked: state.total_tracked,
      total_mutations: state.total_mutations,
      avg_mutations_per_law: if(state.total_tracked > 0, do: state.total_mutations / state.total_tracked, else: 0)
    })
    
    {:reply, {:ok, stats}, state}
  end

  # ==================== Private Helpers ====================

  defp get_or_create_lineage(law_id, law_type) do
    case get_lineage(law_id) do
      nil -> create_lineage(law_id, law_type)
      lineage -> lineage
    end
  end

  defp create_lineage(law_id, law_type) do
    %__MODULE__{
      law_id: law_id,
      law_type: law_type,
      mutation_chain: [],
      created_at: DateTime.utc_now(),
      last_mutated: DateTime.utc_now(),
      status: :active,
      extinction_count: 0
    }
  end

  defp get_lineage(law_id) do
    case :ets.lookup(:law_lineages, law_id) do
      [{^law_id, lineage}] -> lineage
      [] -> nil
    end
  end

  defp format_biography(lineage) do
    %{
      law_id: lineage.law_id,
      law_type: lineage.law_type,
      status: lineage.status,
      total_mutations: length(lineage.mutation_chain),
      created_at: lineage.created_at,
      last_mutated: lineage.last_mutated,
      extinction_count: lineage.extinction_count,
      mutation_history: Enum.map(lineage.mutation_chain, fn m ->
        %{
          version: m.version,
          timestamp: m.timestamp,
          reason: m.mutation_reason,
          entropy: m.entropy_context,
          fitness_delta: m.fitness_impact
        }
      end)
    }
  end

  defp format_law_summary(lineage) do
    %{
      law_id: lineage.law_id,
      type: lineage.law_type,
      status: lineage.status,
      current_version: length(lineage.mutation_chain),
      last_mutated: lineage.last_mutated
    }
  end

  defp determine_merged_type(parent_lineages) do
    # Determine dominant law type from parents
    # For now, default to :cal (most common)
    :cal
  end

  defp build_divergence_tree(root, all, law_type) do
    root_chain_length = length(root.mutation_chain)
    same_type = Enum.filter(all, fn l -> l.law_type == law_type and l.law_id != root.law_id end)

    variants = Enum.reduce(same_type, [], fn candidate, acc ->
      divergence_point = find_divergence_point(root.mutation_chain, candidate.mutation_chain)

      candidate_info = %{
        law_id: candidate.law_id,
        status: candidate.status,
        total_mutations: length(candidate.mutation_chain),
        divergence_at_version: divergence_point,
        variants: []
      }

      [{candidate_info, length(candidate.mutation_chain) - max(divergence_point, 0)} | acc]
    end)

    sorted = Enum.sort_by(variants, fn {_v, depth} -> depth end, :desc)
    max_depth = if sorted == [], do: 0, else: elem(hd(sorted), 1)

    {Enum.map(sorted, fn {v, _} -> v end), max_depth}
  end

  defp find_divergence_point(chain_a, chain_b) do
    common = Enum.zip(chain_a, chain_b)
    |> Enum.take_while(fn {a, b} ->
      a.old_form == b.old_form and a.new_form == b.new_form and
      a.mutation_reason == b.mutation_reason
    end)
    length(common)
  end

  defp archive_extinct_law(lineage, reason) do
    latest_mutation = List.last(lineage.mutation_chain)
    
    if latest_mutation do
      {cal_expr, cis_expr} = case lineage.law_type do
        :cal -> {latest_mutation.new_form, "unknown"}
        :cis -> {"unknown", latest_mutation.new_form}
        :entropy -> {"unknown", latest_mutation.new_form}
        :selection -> {latest_mutation.new_form, "unknown"}
        _ -> {"unknown", "unknown"}
      end
      
      LawArchive.store_extinct_law(
        lineage.law_id,
        cal_expr,
        cis_expr,
        {latest_mutation.entropy_context - 0.1, latest_mutation.entropy_context + 0.1},
        latest_mutation.fitness_impact,
        min(1.0, abs(latest_mutation.entropy_context) + 0.4)
      )
    end
  end

  defp publish_mutation_event(lineage, mutation) do
    payload = %{
      event_type: "law_mutation",
      law_id: lineage.law_id,
      law_type: lineage.law_type,
      version: mutation.version,
      reason: mutation.mutation_reason,
      entropy_context: mutation.entropy_context,
      fitness_impact: mutation.fitness_impact,
      timestamp: mutation.timestamp |> DateTime.to_iso8601()
    }
    
    try do
      Tiannara.NATS.MetaEvolutionStreamManager.publish("tiannara.physics.lineage.mutated", payload)
    rescue
      e -> Logger.warning("⚠️  Failed to publish mutation event: #{inspect(e)}")
    end
  end
end
