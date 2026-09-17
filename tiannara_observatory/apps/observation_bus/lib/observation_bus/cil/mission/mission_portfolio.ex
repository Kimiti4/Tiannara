defmodule ObservationBus.CIL.Mission.MissionPortfolio do
  @moduledoc """
  Balances the mission portfolio across risk, novelty, cost, scientific
  return, and engineering return dimensions.

  Provides portfolio-level analytics for Mission Control operators.
  """
  use GenServer

  defstruct [:total_analyses]

  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %__MODULE__{total_analyses: 0}}
  end

  @doc "Analyze the current mission portfolio."
  @spec analyze() :: map()
  def analyze do
    GenServer.call(__MODULE__, :analyze)
  end

  @impl true
  def handle_call(:analyze, _from, state) do
    missions = ObservationBus.CIL.Mission.MissionRegistry.list()
    statuses = Enum.group_by(missions, & &1.status)
    domains = missions |> Enum.flat_map(& &1.domains) |> Enum.frequencies()

    portfolio = %{
      total_missions: length(missions),
      by_status: Enum.map(statuses, fn {k, v} -> {k, length(v)} end) |> Map.new(),
      domain_distribution: domains,
      diversity_score: compute_diversity(missions),
      risk_exposure: compute_risk_exposure(missions),
      analyzed_at: DateTime.utc_now()
    }
    {:reply, portfolio, %{state | total_analyses: state.total_analyses + 1}}
  end

  defp compute_diversity(missions) do
    domains = missions |> Enum.flat_map(& &1.domains) |> Enum.uniq() |> length()
    total = max(length(missions), 1)
    min(1.0, domains / total)
  end

  defp compute_risk_exposure(missions) do
    highs = Enum.count(missions, &(&1.priority >= 80))
    highs / max(length(missions), 1)
  end
end
