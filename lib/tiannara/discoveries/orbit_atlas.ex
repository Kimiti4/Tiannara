defmodule Tiannara.OrbitAtlas do
  @moduledoc """
  Analytical engine for the Orbit Transition Matrix.
  Calculates Markov steady-states, ORR, OVI, classifies attractors/sinks/gateways,
  and identifies common, valuable, dangerous, and high cost transitions.
  """
  alias Tiannara.OrbitTransitions
  alias Tiannara.OrbitEngineering

  @states_path "data/orbit_states.ndjson"

  @doc """
  Ensures transition matrix calculations exist, then returns all computed transitions.
  """
  def get_transitions do
    transitions = OrbitTransitions.all()
    if Enum.empty?(transitions) do
      # Calculate
      case OrbitEngineering.import_and_calculate() do
        {:ok, _} -> OrbitTransitions.all()
        _ -> []
      end
    else
      transitions
    end
  end

  @doc """
  Loads all orbit state snap shots from persistence.
  """
  def get_states do
    if File.exists?(@states_path) do
      @states_path
      |> File.stream!()
      |> Stream.map(&String.trim/1)
      |> Stream.reject(&(&1 == ""))
      |> Stream.map(fn line ->
        case Jason.decode(line, keys: :atoms) do
          {:ok, attrs} ->
            attrs = Map.update!(attrs, :orbit_id, &String.to_atom(to_string(&1)))
            struct(Tiannara.OrbitState, attrs)
          _ -> nil
        end
      end)
      |> Stream.reject(&is_nil/1)
      |> Enum.to_list()
    else
      # Calculate first
      case OrbitEngineering.import_and_calculate() do
        {:ok, _} -> get_states()
        _ -> []
      end
    end
  end

  @doc """
  Calculates the transition probability matrix as a map %{from_orbit => %{to_orbit => prob}}.
  """
  def get_matrix do
    get_transitions()
    |> Enum.reduce(%{}, fn t, acc ->
      Map.put_new_lazy(acc, t.from_orbit, fn -> %{} end)
      |> Map.update!(t.from_orbit, &Map.put(&1, t.to_orbit, t.probability))
    end)
  end

  @doc """
  Computes the steady-state probability distribution of the Markov chain.
  """
  def calculate_steady_state do
    matrix = get_matrix()
    states = Map.keys(matrix)
    n = length(states)
    
    if n == 0 do
      %{}
    else
      initial_pi = Map.new(states, fn s -> {s, 1.0 / n} end)
      
      final_pi = Enum.reduce(1..150, initial_pi, fn _, acc_pi ->
        next_pi = Map.new(states, fn to_s ->
          sum = Enum.reduce(states, 0.0, fn from_s, acc_sum ->
            acc_sum + Map.get(acc_pi, from_s, 0.0) * (Map.get(matrix, from_s, %{}) |> Map.get(to_s, 0.0))
          end)
          {to_s, sum}
        end)
        total_sum = Enum.sum(Map.values(next_pi))
        if total_sum > 0 do
          Map.new(next_pi, fn {k, v} -> {k, v / total_sum} end)
        else
          next_pi
        end
      end)
      
      final_pi
    end
  end

  @doc """
  Finds the dominant recurrent eigen-orbits (highest steady-state probabilities).
  """
  def get_dominant_eigen_orbits do
    calculate_steady_state()
    |> Enum.sort_by(&elem(&1, 1), :desc)
  end

  @doc """
  Calculates Orbit Residency Ratio (ORR) for each orbit class.
  """
  def calculate_residency_ratios do
    states = get_states()
    total = length(states)
    
    if total == 0 do
      %{}
    else
      states
      |> Enum.group_by(& &1.orbit_id)
      |> Map.new(fn {id, list} ->
        {id, Float.round(length(list) / total, 4)}
      end)
    end
  end

  @doc """
  Calculates Mean Orbit Lifetime for each orbit class.
  """
  def calculate_mean_lifetimes do
    transitions = get_transitions()
    
    transitions
    |> Enum.group_by(& &1.from_orbit)
    |> Map.new(fn {from, list} ->
      # Mean Lifetime = total duration of self-looping / count of entries
      self_loop = Enum.find(list, & &1.to_orbit == from)
      total_count = Enum.sum(Enum.map(list, & &1.count))
      
      duration =
        if self_loop && total_count > 0 do
          self_loop.average_duration * (self_loop.count / total_count) + 2.0
        else
          5.0
        end
      {from, Float.round(duration, 2)}
    end)
  end

  @doc """
  Calculates Orbit Volatility Index (OVI) for each civilization/trajectory.
  """
  def calculate_volatility_indices do
    states = get_states()
    
    states
    |> Enum.group_by(& &1.trajectory_id)
    |> Map.new(fn {traj_id, list} ->
      sorted = Enum.sort_by(list, & &1.epoch)
      total_epochs = length(sorted)
      
      changes =
        sorted
        |> Enum.chunk_every(2, 1, :discard)
        |> Enum.count(fn [a, b] -> a.orbit_id != b.orbit_id end)
        
      ovi = if total_epochs > 0, do: changes / total_epochs, else: 0.0
      {traj_id, Float.round(ovi, 4)}
    end)
  end

  @doc """
  Classifies orbits dynamically based on inflow and outflow flow properties.
  """
  def classify_orbits do
    matrix = get_matrix()
    states = Map.keys(matrix)
    
    # Calculate inflow sums (excluding self loops)
    inflows = Enum.reduce(states, %{}, fn s, acc ->
      inflow_sum = Enum.sum(Enum.map(states -- [s], fn other ->
        Map.get(matrix, other, %{}) |> Map.get(s, 0.0)
      end))
      Map.put(acc, s, inflow_sum)
    end)

    # Calculate outflow sums (excluding self loops)
    outflows = Enum.reduce(states, %{}, fn s, acc ->
      outflow_sum = Enum.sum(Enum.map(states -- [s], fn other ->
        Map.get(matrix, s, %{}) |> Map.get(other, 0.0)
      end))
      Map.put(acc, s, outflow_sum)
    end)

    Enum.reduce(states, %{attractors: [], sinks: [], gateways: [], launchers: []}, fn s, acc ->
      in_val = Map.get(inflows, s, 0.0)
      out_val = Map.get(outflows, s, 0.0)
      self_val = Map.get(matrix, s, %{}) |> Map.get(s, 0.0)

      cond do
        self_val > 0.70 ->
          Map.update!(acc, :sinks, & [s | &1])
          
        in_val > 1.2 * out_val ->
          Map.update!(acc, :attractors, & [s | &1])
          
        in_val > 0.15 and out_val > 0.15 and self_val < 0.45 ->
          Map.update!(acc, :gateways, & [s | &1])
          
        out_val > 0.60 and in_val < 0.05 ->
          Map.update!(acc, :launchers, & [s | &1])
          
        true ->
          # fallback
          if self_val > 0.50 do
             Map.update!(acc, :sinks, & [s | &1])
          else
             Map.update!(acc, :gateways, & [s | &1])
          end
      end
    end)
  end

  @doc """
  Identifies forbidden transitions (total attempts > 50, but successes = 0, or prob < 0.02).
  """
  def get_forbidden_transitions do
    get_transitions()
    |> Enum.filter(fn t ->
      (t.attempts > 50 and t.successes == 0) or t.probability < 0.02
    end)
  end

  @doc """
  Retrieves summary parameters for the Mission Control dashboard.
  """
  def get_summary_metrics do
    transitions = get_transitions()
    residency = calculate_residency_ratios()
    
    valid_transitions = Enum.filter(transitions, & &1.from_orbit != &1.to_orbit)

    # 1. Most Common Transition
    most_common = Enum.max_by(valid_transitions, & &1.probability, fn -> nil end)

    # 2. Most Valuable Transition (highest positive GSI increase)
    most_valuable = Enum.max_by(valid_transitions, & &1.average_gsi_change, fn -> nil end)

    # 3. Most Dangerous Transition (largest drop in GSI)
    most_dangerous = Enum.min_by(valid_transitions, & &1.average_gsi_change, fn -> nil end)

    # 4. Highest Cost Transition (highest energy)
    highest_cost = Enum.max_by(valid_transitions, & &1.transition_cost, fn -> nil end)

    # 5. Most Stable Orbit (highest self-loop probability or residency ratio)
    most_stable = 
      if Enum.empty?(residency) do
        nil
      else
        residency
        |> Enum.max_by(fn {_id, val} -> val end)
        |> elem(0)
      end

    %{
      most_common: most_common,
      most_valuable: most_valuable,
      most_dangerous: most_dangerous,
      highest_cost: highest_cost,
      most_stable: most_stable
    }
  end
end
