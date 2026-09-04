defmodule Tiannara.Sentinel.D2.Types.EpistemicBasin do
  defstruct [
    :id, :species_ids, :entry_count, :exit_count, :extinction_count,
    :breakthrough_count, :avg_persistence_epochs,
    escape_rate: 0.0,
    productive_escape_rate: 0.0
  ]
end

defmodule Tiannara.Sentinel.D2.BasinTracker do
  use GenServer
  require Logger

  @table :basin_temporal_stability
  @similarity_threshold 0.85
  @search_radius 25
  @absence_decay 50
  @max_nodes 10000

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    :ets.new(@table, [:set, :public, :named_table])
    
    initial_state = %{
      ghosts: %{},
      similarity_histogram: %{
        "0.95+" => 0,
        "0.90-0.95" => 0,
        "0.85-0.90" => 0,
        "0.80-0.85" => 0,
        "<0.80" => 0
      },
      promotions: 0,
      merges: 0,
      splits: 0,
      lifespans: []
    }
    
    {:ok, initial_state}
  end

  # --- NATS Event Sink ---
  def handle_cast({:nats_event, payload}, state) do
    state = case payload["event"] do
      "basin_birth" -> handle_birth(payload, state)
      "basin_update" -> handle_update(payload, state)
      "basin_death" -> handle_death(payload, state)
      _ -> state
    end
    {:noreply, state}
  end

  def handle_call(:get_telemetry, _from, state) do
    {:reply, state, state}
  end

  defp handle_birth(payload, state) do
    node_id = payload["node_id"]
    fp = payload["fingerprint"]
    epoch = payload["epoch"]

    # Garbage collect stale ghosts
    state = prune_ghosts(state, epoch)

    {lineage_id, initial_age, state} = find_or_create_lineage(node_id, fp, state)
    
    :ets.insert(@table, {lineage_id, node_id, initial_age, fp, epoch})
    state
  end

  defp handle_update(payload, state) do
    node_id = payload["node_id"]
    fp = payload["fingerprint"]
    epoch = payload["epoch"]
    
    match = :ets.match_object(@table, {~c"$1", node_id, ~c"$2", ~c"$3", ~c"$4"})
    case match do
      [{lineage_id, ^node_id, age, _old_fp, _last_seen}] ->
        new_age = age + 50
        :ets.insert(@table, {lineage_id, node_id, new_age, fp, epoch})
        
        if new_age >= 500 and age < 500 do
          state = %{state | promotions: state.promotions + 1}
          Logger.info("[UCC Promotion] Lineage #{lineage_id} crossed 500 epochs at Node #{node_id}. Total Promotions: #{state.promotions}")
          # Trigger Level 1 Dependency Extraction -> Level 2 ESG...
        end
        state
      [] -> state
    end
  end

  defp handle_death(payload, state) do
    node_id = payload["node_id"]
    epoch = payload["epoch"]
    
    match = :ets.match_object(@table, {~c"$1", node_id, ~c"$2", ~c"$3", ~c"$4"})
    case match do
      [{lineage_id, ^node_id, age, fp, _last_seen}] ->
        :ets.delete(@table, lineage_id)
        ghost = %{node_id: node_id, age: payload["final_age"] || age, fingerprint: fp, death_epoch: epoch}
        %{state | ghosts: Map.put(state.ghosts, lineage_id, ghost)}
      [] -> state
    end
  end

  defp find_or_create_lineage(new_node_id, new_fp, state) do
    candidates = Enum.filter(state.ghosts, fn {_id, ghost} -> 
      dist = abs(ghost.node_id - new_node_id)
      dist = min(dist, @max_nodes - dist)
      dist <= @search_radius
    end)
    
    candidates_with_sim = Enum.map(candidates, fn {id, ghost} -> 
      sim = cosine_similarity(ghost.fingerprint, new_fp)
      {id, ghost, sim}
    end)
    
    state = Enum.reduce(candidates_with_sim, state, fn {_id, _ghost, sim}, acc ->
      bucket = cond do
        sim >= 0.95 -> "0.95+"
        sim >= 0.90 -> "0.90-0.95"
        sim >= 0.85 -> "0.85-0.90"
        sim >= 0.80 -> "0.80-0.85"
        true -> "<0.80"
      end
      put_in(acc, [:similarity_histogram, bucket], acc.similarity_histogram[bucket] + 1)
    end)

    valid_matches = Enum.filter(candidates_with_sim, fn {_id, _ghost, sim} -> sim >= @similarity_threshold end)
                    |> Enum.sort_by(fn {_id, _ghost, sim} -> sim end, :desc)

    case valid_matches do
      [] ->
        lineage_id = "Lineage_#{new_node_id}_#{:erlang.unique_integer([:positive])}"
        {lineage_id, 1, state}
      [{lineage_id, ghost, _sim}] ->
        new_ghosts = Map.delete(state.ghosts, lineage_id)
        {lineage_id, ghost.age, %{state | ghosts: new_ghosts}}
      multiple_matches ->
        state = %{state | merges: state.merges + 1}
        Logger.info("[Lineage Merge] #{length(multiple_matches)} lineages merged at #{new_node_id}")
        
        {primary_id, _primary_ghost, _} = hd(multiple_matches)
        merged_age = Enum.map(multiple_matches, fn {_, g, _} -> g.age end) |> Enum.sum()
        
        new_ghosts = Enum.reduce(multiple_matches, state.ghosts, fn {id, _, _}, acc -> Map.delete(acc, id) end)
        {primary_id, merged_age, %{state | ghosts: new_ghosts}}
    end
  end

  defp prune_ghosts(state, current_epoch) do
    {alive, dead} = Enum.split_with(state.ghosts, fn {_id, ghost} -> 
      (current_epoch - ghost.death_epoch) <= @absence_decay 
    end)
    
    lifespans = Enum.reduce(dead, state.lifespans, fn {id, ghost}, acc -> 
      if ghost.age > 100 do # Only record meaningful lifespans
        [{id, ghost.age} | acc]
      else
        acc
      end
    end)
    
    %{state | ghosts: Map.new(alive), lifespans: lifespans}
  end

  defp cosine_similarity(v1, v2) do
    dot = Enum.zip(v1, v2) |> Enum.map(fn {a, b} -> a * b end) |> Enum.sum()
    mag1 = :math.sqrt(Enum.map(v1, &(&1 * &1)) |> Enum.sum())
    mag2 = :math.sqrt(Enum.map(v2, &(&1 * &1)) |> Enum.sum())
    if mag1 * mag2 == 0.0, do: 0.0, else: dot / (mag1 * mag2)
  end
end
