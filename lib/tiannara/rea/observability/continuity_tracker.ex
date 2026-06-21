defmodule Tiannara.REA.Observability.ContinuityTracker do
  @moduledoc """
  The Epistemic Continuity Tracker.
  Tracks metrics to prove whether epistemic novelty production continues after
  biological diversity collapses.
  """
  use GenServer
  require Logger

  # --- Client API ---

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def record_epoch_state(epoch, population_state, epistemic_state) do
    GenServer.cast(__MODULE__, {:record, epoch, population_state, epistemic_state})
  end

  def get_time_series do
    GenServer.call(__MODULE__, :get_data)
  end

  # --- Server Callbacks ---

  @impl true
  def init(_opts) do
    table = :ets.new(:continuity_telemetry, [:named_table, :ordered_set, :public])
    
    state = %{
      table: table,
      prev_novelty_count: 0,
      prev_lineage_count: 0,
      monoculture_epoch: nil
    }
    
    Logger.info("📊 [Observability] Epistemic Continuity Tracker initialized.")
    {:ok, state}
  end

  @impl true
  def handle_cast({:record, epoch, pop_state, epi_state}, state) do
    # 1. Calculate Genome Diversity
    genome_entropy = calculate_shannon_entropy(pop_state.genome_hashes)
    
    # 2. Calculate Domain Entropy
    domain_entropy = calculate_domain_entropy(pop_state.domain_profiles)
    
    # 3. Calculate Novelty Creation Rate
    current_novelty_count = epi_state.global_novelties_count
    novelty_rate = current_novelty_count - state.prev_novelty_count
    
    # 4. Calculate Lineage Extinctions
    current_lineage_count = pop_state.unique_lineages
    extinctions = max(0, state.prev_lineage_count - current_lineage_count)
    
    # 5. Detect Monoculture
    is_monoculture = genome_entropy == 0.0 or genome_entropy < 0.01
    monoculture_epoch = 
      cond do
        state.monoculture_epoch != nil -> state.monoculture_epoch
        is_monoculture -> epoch
        true -> nil
      end
      
    # 6. Novelty Source Diversity (Requested by User)
    novelty_source_count = (epi_state[:novelty_sources] || []) |> MapSet.new() |> MapSet.size()
      
    # 7. Compile row
    telemetry_row = %{
      epoch: epoch,
      novelty_rate: novelty_rate,
      novelty_source_count: novelty_source_count,
      genome_entropy: Float.round(genome_entropy, 4),
      domain_entropy: Float.round(domain_entropy, 4),
      extinctions: extinctions,
      total_knowledge: current_novelty_count,
      is_monoculture: is_monoculture,
      monoculture_emerged_at: monoculture_epoch
    }
    
    :ets.insert(state.table, {epoch, telemetry_row})
    
    if is_monoculture and state.monoculture_epoch == nil do
      Logger.warning("💀 [Observability] BIOLOGICAL COLLAPSE DETECTED at Epoch #{epoch}. Shannon Entropy -> 0.0")
    end
    
    if novelty_rate > 0 and is_monoculture do
      Logger.info("👻 [Observability] GHOST IN THE MACHINE: Novelty rate #{novelty_rate} from #{novelty_source_count} sources post-monoculture at Epoch #{epoch}")
    end

    new_state = %{
      state
      | prev_novelty_count: current_novelty_count,
        prev_lineage_count: current_lineage_count,
        monoculture_epoch: monoculture_epoch
    }

    {:noreply, new_state}
  end

  @impl true
  def handle_call(:get_data, _from, state) do
    data = :ets.tab2list(state.table) |> Enum.map(fn {_, v} -> v end)
    {:reply, data, state}
  end

  # --- Math Helpers ---

  defp calculate_shannon_entropy(hashes) when is_list(hashes) do
    total = length(hashes)
    if total == 0 do
      0.0
    else
      hashes
      |> Enum.frequencies()
      |> Map.values()
      |> Enum.reduce(0.0, fn count, acc ->
        p = count / total
        acc - p * :math.log2(p)
      end)
    end
  end
  defp calculate_shannon_entropy(_), do: 0.0

  defp calculate_domain_entropy(profiles) when is_list(profiles) do
    if length(profiles) == 0 do
      0.0
    else
      dominant_domains = 
        profiles
        |> Enum.flat_map(fn p -> Map.keys(p) end)
        |> Enum.frequencies()
        |> Map.values()
        
      total = Enum.sum(dominant_domains)
      if total == 0 do
        0.0
      else
        dominant_domains
        |> Enum.reduce(0.0, fn count, acc ->
          p = count / total
          acc - p * :math.log2(p)
        end)
      end
    end
  end
  defp calculate_domain_entropy(_), do: 0.0
end
