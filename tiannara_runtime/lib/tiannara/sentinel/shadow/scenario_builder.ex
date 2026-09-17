defmodule Tiannara.Sentinel.Shadow.ScenarioBuilder do
  @moduledoc """
  Packages the reconstructed history into a deterministic counterfactual test.
  """
  use GenServer

  alias Tiannara.Sentinel.Shadow.ReplayEngine

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def build_scenario(replay_case) do
    GenServer.cast(__MODULE__, {:build, replay_case})
  end

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:build, replay_case}, state) do
    # In Phase C.0, the scenario is just the isolated replay case itself, 
    # ready for counterfactual evaluation.
    ReplayEngine.evaluate_counterfactual(replay_case)
    {:noreply, state}
  end
end
