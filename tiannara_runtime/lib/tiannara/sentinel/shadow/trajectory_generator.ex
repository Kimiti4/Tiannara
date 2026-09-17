defmodule Tiannara.Sentinel.Shadow.TrajectoryGenerator do
  @moduledoc """
  Generates explicit epistemic trajectories based on structural uncertainty.
  """
  use GenServer

  alias Tiannara.Sentinel.Shadow.FitnessEvaluator

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def generate_trajectories(seed, candidates) do
    GenServer.cast(__MODULE__, {:generate, seed, candidates})
  end

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:generate, seed, candidates}, state) do
    # Generate structured possibility space per candidate action
    # :optimistic, :baseline, :pessimistic, :divergence, :calibration_failure, :shock
    
    trajectory_set = 
      Enum.map(candidates, fn action ->
        trajectories = build_structured_trajectories(action, seed)
        %{action: action, trajectories: trajectories}
      end)

    FitnessEvaluator.evaluate_trajectories(seed, trajectory_set)

    {:noreply, state}
  end

  defp build_structured_trajectories(_action, _seed) do
    # Mocking explicit structured trajectories for C.1A++
    # Each trajectory represents a distinct epistemic state projection
    [
      %{type: :optimistic, entropy_delta: -0.15, novelty_delta: 0.1},
      %{type: :baseline, entropy_delta: -0.05, novelty_delta: 0.05},
      %{type: :pessimistic, entropy_delta: 0.10, novelty_delta: -0.1},
      %{type: :forecast_divergence, entropy_delta: 0.0, novelty_delta: 0.2},
      %{type: :external_shock, entropy_delta: 0.40, novelty_delta: -0.3}
    ]
  end
end
