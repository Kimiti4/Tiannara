defmodule Tiannara.REA.Epistemic.Goal do
  @derive Jason.Encoder
  defstruct [
    :id,
    :target_domain,            # atom, e.g. :engineering, :robotics
    :focus_coordinates,        # map: %{volatility: f, complexity: f, adversariality: f, security_pressure: f}
    :expected_information_gain, # float
    :priority_weight,          # float
    :generation,               # integer
    :status,                   # :active, :completed, :abandoned
    :created_at_epoch          # integer
  ]
end

defmodule Tiannara.REA.Epistemic.GoalRegistry do
  use GenServer
  alias Tiannara.REA.Epistemic.Goal

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  # --- PUBLIC API ---

  def register_goal(%Goal{} = goal) do
    GenServer.call(__MODULE__, {:register, goal})
  end

  def get_goals do
    GenServer.call(__MODULE__, :get_goals)
  end

  def active_goals do
    GenServer.call(__MODULE__, :active_goals)
  end

  def completed_goals do
    GenServer.call(__MODULE__, :completed_goals)
  end

  def complete_goal(id) do
    GenServer.call(__MODULE__, {:update_status, id, :completed})
  end

  def abandon_goal(id) do
    GenServer.call(__MODULE__, {:update_status, id, :abandoned})
  end

  def update_priority(id, priority) do
    GenServer.call(__MODULE__, {:update_priority, id, priority})
  end

  def set_goals(goals) do
    GenServer.call(__MODULE__, {:set_goals, goals})
  end

  def reset do
    GenServer.call(__MODULE__, :reset)
  end

  # --- CALLBACKS ---

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:register, goal}, _from, state) do
    {:reply, :ok, Map.put(state, goal.id, goal)}
  end

  @impl true
  def handle_call(:get_goals, _from, state) do
    {:reply, Map.values(state), state}
  end

  @impl true
  def handle_call(:active_goals, _from, state) do
    active = state |> Map.values() |> Enum.filter(&(&1.status == :active))
    {:reply, active, state}
  end

  @impl true
  def handle_call(:completed_goals, _from, state) do
    completed = state |> Map.values() |> Enum.filter(&(&1.status == :completed))
    {:reply, completed, state}
  end

  @impl true
  def handle_call({:update_status, id, status}, _from, state) do
    case Map.get(state, id) do
      nil -> {:reply, {:error, :not_found}, state}
      goal ->
        new_goal = %{goal | status: status}
        {:reply, :ok, Map.put(state, id, new_goal)}
    end
  end

  @impl true
  def handle_call({:update_priority, id, priority}, _from, state) do
    case Map.get(state, id) do
      nil -> {:reply, {:error, :not_found}, state}
      goal ->
        new_goal = %{goal | priority_weight: priority}
        {:reply, :ok, Map.put(state, id, new_goal)}
    end
  end

  @impl true
  def handle_call({:set_goals, goals}, _from, _state) do
    new_state = Map.new(goals, & {&1.id, &1})
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:reset, _from, _state) do
    {:reply, :ok, %{}}
  end
end

defmodule Tiannara.REA.Epistemic.GoalEcology do
  @moduledoc """
  Manages goal evolution (mutation, crossover) and selection sweeps.
  Goal fitness = EIG * priority * coordinate_alignment
  """
  alias Tiannara.REA.Epistemic.{Goal, GoalRegistry}

  # All 20 research domains dynamically loaded from registry (with static fallback if registry fails)
  def list_domains do
    if Code.ensure_loaded?(Tiannara.Domains.Registry) do
      Tiannara.Domains.Registry.all() |> Enum.map(& &1.id)
    else
      [:engineering, :medicine, :governance, :computation, :science, :agriculture, :energy, :logistics, :cognition, :materials, :robotics, :economics, :philosophy, :sociology, :linguistics, :aerospace, :ecology, :cybernetics, :architecture, :mathematics]
    end
  end

  @doc """
  Runs goal evolution sweeps: fitness evaluations, selections, mutations, crossovers, and new founding goals.
  """
  def tick(epoch, environment_context) do
    active = GoalRegistry.active_goals()
    
    # 1. Evaluate fitness for each active goal
    scored = Enum.map(active, fn g ->
      {g, calculate_fitness(g, environment_context)}
    end)

    # 2. Select top goals (replicator dynamics select subset)
    target_count = 5
    selected =
      scored
      |> Enum.sort_by(&elem(&1, 1), :desc)
      |> Enum.take(target_count)
      |> Enum.map(&elem(&1, 0))

    # 3. Mutate and crossover to yield next generation of active goals
    reproduced = reproduce_goals(selected, epoch)

    # 4. Foundation of new goals targeting domains with high research uncertainty (if active count is low)
    founding =
      if length(reproduced) < target_count do
        generate_founding_goals(target_count - length(reproduced), epoch, environment_context)
      else
        []
      end

    # Save to Registry
    GoalRegistry.set_goals(reproduced ++ founding)
    :ok
  end

  def calculate_fitness(%Goal{} = g, env) do
    # EIG * priority * Coordinate Alignment
    eig = g.expected_information_gain
    priority = g.priority_weight

    # Coordinate Alignment: cosine distance metric or euclidean distance
    gc = g.focus_coordinates
    v_diff = :math.pow(Map.get(gc, :volatility, 0.5) - Map.get(env, :volatility, 0.5), 2)
    c_diff = :math.pow(Map.get(gc, :complexity, 0.5) - Map.get(env, :complexity, 0.5), 2)
    a_diff = :math.pow(Map.get(gc, :adversariality, 0.5) - Map.get(env, :adversariality, 0.5), 2)
    s_diff = :math.pow(Map.get(gc, :security_pressure, 0.5) - Map.get(env, :security_pressure, 0.5), 2)
    dist = :math.sqrt(v_diff + c_diff + a_diff + s_diff)
    alignment = max(0.01, 1.0 - (dist / 2.0))

    Float.round(eig * priority * alignment, 4)
  end

  defp reproduce_goals([], epoch, env) do
    generate_founding_goals(5, epoch, env)
  end
  defp reproduce_goals(selected, epoch) do
    Enum.flat_map(selected, fn g ->
      # Mutate goal coordinates
      mutated = %Goal{
        id: String.to_atom("goal_mut_#{g.id}_#{System.unique_integer([:positive])}"),
        target_domain: g.target_domain,
        focus_coordinates: mutate_coords(g.focus_coordinates),
        expected_information_gain: g.expected_information_gain,
        priority_weight: g.priority_weight,
        generation: g.generation + 1,
        status: :active,
        created_at_epoch: epoch
      }
      [g, mutated]
    end)
    |> Enum.take(10) # Bounded population size
  end

  defp mutate_coords(coords) do
    Map.new(coords, fn {k, v} ->
      # Mutate coordinate by +/- 0.1
      delta = (:rand.uniform() - 0.5) * 0.2
      {k, max(0.0, min(1.0, v + delta))}
    end)
  end

  defp generate_founding_goals(count, epoch, env) do
    domains = list_domains()
    
    for _i <- 1..count do
      domain = Enum.random(domains)
      id = String.to_atom("goal_found_#{domain}_#{System.unique_integer([:positive])}")
      
      # Calculate dynamic expected info gain (uncertainty index)
      eig =
        if Code.ensure_loaded?(Tiannara.Domains.Registry) do
          case Tiannara.Domains.Registry.get_portfolio_vector(domain) do
            %{uncertainty: u} -> u
            _ -> 0.5
          end
        else
          0.5
        end

      %Goal{
        id: id,
        target_domain: domain,
        focus_coordinates: %{
          volatility: Map.get(env, :volatility, 0.5),
          complexity: Map.get(env, :complexity, 0.5),
          adversariality: Map.get(env, :adversariality, 0.5),
          security_pressure: Map.get(env, :security_pressure, 0.5)
        },
        expected_information_gain: Float.round(eig, 4),
        priority_weight: 1.0,
        generation: 0,
        status: :active,
        created_at_epoch: epoch
      }
    end
  end
end
