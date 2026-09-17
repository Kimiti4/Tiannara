defmodule Tiannara.Sentinel.Observatories.EpistemicDiversityTracker do
  @moduledoc """
  Tracks the distribution of an observatory's recommendations to detect monocultures.
  """
  use GenServer
  
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def record_recommendation(obs_id, action) do
    GenServer.cast(__MODULE__, {:record, obs_id, action})
  end
  
  def get_mesh_diversity_index do
    GenServer.call(__MODULE__, {:get_diversity_index, :mesh})
  end

  def get_diversity_index(obs_id) do
    GenServer.call(__MODULE__, {:get_diversity_index, obs_id})
  end

  def get_diversity_modifier(obs_id) do
    GenServer.call(__MODULE__, {:get_modifier, obs_id})
  end
  
  @impl true
  def init(_opts) do
    # Map of obs_id => %{action => count}
    {:ok, %{}}
  end
  
  @impl true
  def handle_cast({:record, obs_id, action}, state) do
    obs_data = Map.get(state, obs_id, %{})
    new_count = Map.get(obs_data, action, 0) + 1
    new_data = Map.put(obs_data, action, new_count)
    {:noreply, Map.put(state, obs_id, new_data)}
  end
  
  @impl true
  def handle_call({:get_modifier, obs_id}, from, state) do
    # Keep the modifier for ReliabilityTracker backwards compat, based on entropy
    {:reply, score, _state} = handle_call({:get_diversity_index, obs_id}, from, state)
    modifier = 0.5 + (score / 2.0)
    {:reply, Float.round(modifier, 3), state}
  end

  @impl true
  def handle_call({:get_diversity_index, obs_id}, _from, state) do
    obs_data = Map.get(state, obs_id, %{})
    total_recs = obs_data |> Map.values() |> Enum.sum()
    
    score = 
      if total_recs == 0 do
        0.0
      else
        # Shannon entropy H = -Σ(p_i * log2(p_i))
        counts = Map.values(obs_data)
        entropy = 
          Enum.reduce(counts, 0.0, fn count, acc ->
            p = count / total_recs
            if p > 0, do: acc - (p * :math.log2(p)), else: acc
          end)

        # Normalize 0.0 to 1.0 (max entropy for N items is log2(N))
        n_actions = map_size(obs_data)
        if n_actions <= 1 do
          0.0
        else
          entropy / :math.log2(n_actions)
        end
      end
      
    {:reply, Float.round(score, 3), state}
  end
end
