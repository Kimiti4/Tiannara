defmodule Tiannara.Sentinel.Shadow.CounterRecommendationGenerator do
  @moduledoc """
  Generates alternative candidate actions for comparative reasoning.
  """
  use GenServer

  alias Tiannara.Sentinel.Shadow.TrajectoryGenerator

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def generate_alternatives(seed) do
    GenServer.cast(__MODULE__, {:generate, seed})
  end

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:generate, seed}, state) do
    primary_action = seed.recommendation.action

    # Generate plausible alternatives (mocked for C.1A++)
    # In reality, this queries RegulationPlanner for the next best options.
    candidates = [
      primary_action,
      :entropy_rebalancing,
      :ecological_diversification,
      :constraint_tightening,
      :observation_only
    ] |> Enum.uniq()

    TrajectoryGenerator.generate_trajectories(seed, candidates)

    {:noreply, state}
  end
end
