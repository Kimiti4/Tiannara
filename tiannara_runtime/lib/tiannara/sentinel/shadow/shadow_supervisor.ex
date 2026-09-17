defmodule Tiannara.Sentinel.ShadowSupervisor do
  @moduledoc """
  Supervises the ESG Replay Engine (Phase C.0).
  """
  use Supervisor

  @phase :c1a

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      # Phase C.0 Replay Engine
      Tiannara.Sentinel.Shadow.ReplayMetrics,
      Tiannara.Sentinel.Shadow.ReplayFailureArchive,
      Tiannara.Sentinel.Shadow.ReplayValidator,
      Tiannara.Sentinel.Shadow.ReplayEngine,
      Tiannara.Sentinel.Shadow.ScenarioBuilder,
      Tiannara.Sentinel.Shadow.HistoricalReconstructor,
      
      # Phase C.1A+/++ Epistemic Comparative Simulation Engine
      Tiannara.Sentinel.Shadow.ShadowMetrics,
      Tiannara.Sentinel.Shadow.ShadowCleanup,
      Tiannara.Sentinel.Shadow.TrajectoryRanker,
      Tiannara.Sentinel.Shadow.FitnessEvaluator,
      Tiannara.Sentinel.Shadow.TrajectoryGenerator,
      Tiannara.Sentinel.Shadow.CounterRecommendationGenerator,
      Tiannara.Sentinel.Shadow.ShadowSeedBuilder
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc "Constitutional boundary guard. Prevents true runtime forking."
  def fork_live_state(), do: {:error, :phase_c1b_required}
  def simulate_live_world(), do: {:error, :phase_c1b_required}
  def evaluate_live_intervention(), do: {:error, :phase_c1b_required}
end
