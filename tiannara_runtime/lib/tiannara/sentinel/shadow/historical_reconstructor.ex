defmodule Tiannara.Sentinel.Shadow.HistoricalReconstructor do
  @moduledoc """
  Takes a case from the ReasoningArchive and reconstructs the scenario.
  In Phase C.0, this relies on the %Anomaly{} as the canonical seed state.
  """
  use GenServer

  alias Tiannara.Sentinel.Shadow.ReplayCase
  alias Tiannara.Sentinel.Shadow.ScenarioBuilder

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def reconstruct(archived_case) do
    GenServer.cast(__MODULE__, {:reconstruct, archived_case})
  end

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:reconstruct, archived_case}, state) do
    replay_case = %ReplayCase{
      id: "replay_#{System.unique_integer()}",
      anomaly: archived_case.anomaly_snapshot,
      baseline_snapshot: %{}, # Optional in C.0
      recommendation: archived_case.recommendation,
      expected_impact: archived_case.recommendation.expected_impact,
      actual_outcome: archived_case.eventual_outcome,
      reconstructed_at: System.system_time(:second)
    }

    ScenarioBuilder.build_scenario(replay_case)

    {:noreply, state}
  end
end
