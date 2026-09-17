defmodule Tiannara.Sentinel.Shadow.ShadowSeedBuilder do
  @moduledoc """
  Builds the canonical Epistemic Shadow Seed. Clones knowledge about the runtime
  without cloning the actual runtime state.
  """
  use GenServer

  alias Tiannara.Sentinel.Contracts.ShadowSeed
  alias Tiannara.Sentinel.Shadow.InterventionSimulator

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def build_seed(intervention, anomaly_snapshot, baseline_snapshot \\ %{}, forecast_snapshot \\ %{}) do
    GenServer.cast(__MODULE__, {:build, intervention, anomaly_snapshot, baseline_snapshot, forecast_snapshot})
  end

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:build, intervention, anomaly_snapshot, baseline_snapshot, forecast_snapshot}, state) do
    seed = %ShadowSeed{
      anomaly_snapshot: anomaly_snapshot,
      baseline_snapshot: baseline_snapshot,
      recommendation: intervention,
      forecast_snapshot: forecast_snapshot
    }

    # Pass epistemic state to the alternative generator (C.1A++)
    Tiannara.Sentinel.Shadow.CounterRecommendationGenerator.generate_alternatives(seed)

    {:noreply, state}
  end
end
