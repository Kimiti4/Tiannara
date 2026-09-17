defmodule Tiannara.Sentinel.Shadow.FitnessEvaluator do
  @moduledoc """
  Scores the projected states of trajectories against the %Fitness{} contract.
  """
  use GenServer

  alias Tiannara.Sentinel.Contracts.Fitness
  alias Tiannara.Sentinel.Shadow.TrajectoryRanker

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def evaluate_trajectories(seed, trajectory_set) do
    GenServer.cast(__MODULE__, {:evaluate, seed, trajectory_set})
  end

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:evaluate, seed, trajectory_set}, state) do
    evaluated_set =
      Enum.map(trajectory_set, fn action_set ->
        evaluated_trajectories = 
          Enum.map(action_set.trajectories, fn traj -> 
            fitness = compute_fitness(traj)
            Map.put(traj, :fitness, fitness)
          end)
          
        %{action: action_set.action, trajectories: evaluated_trajectories}
      end)

    TrajectoryRanker.rank_actions(seed, evaluated_set)

    {:noreply, state}
  end

  defp compute_fitness(trajectory) do
    # Mock calculation of constitutional fitness
    stability = if trajectory.entropy_delta < 0, do: 0.8, else: 0.4
    novelty = if trajectory.novelty_delta > 0, do: 0.9, else: 0.5
    compliance = 0.95
    entropy_reg = if trajectory.entropy_delta < 0.1, do: 0.85, else: 0.3
    
    total = (stability + novelty + compliance + entropy_reg) / 4.0

    %Fitness{
      stability: stability,
      novelty: novelty,
      constraint_compliance: compliance,
      entropy_regulation: entropy_reg,
      total: total
    }
  end
end
