defmodule ObservationBus.CIL.Prediction.MissionForecast do
  @moduledoc """
  Projects future milestone completion and constitutional readiness.

  Tracks scientific throughput, discovery challenge completion,
  certification readiness, planetary model maturity, and civilization
  simulation readiness.
  """

  use GenServer

  @milestones ~w(scientific_throughput discovery_completion certification_ready
                  planetary_maturity civilization_readiness)a

  defstruct [:milestones, :total_projections, :last_projection]

  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    mstones = Enum.into(@milestones, %{}, fn m -> {m, default_progress(m)} end)
    {:ok, %__MODULE__{milestones: mstones, total_projections: 0, last_projection: nil}}
  end

  @doc "Project a milestone's completion timeline."
  @spec project(atom()) :: {:ok, map()}
  def project(milestone) when milestone in @milestones do
    GenServer.call(__MODULE__, {:project, milestone})
  end

  @doc "Project all milestones."
  @spec project_all() :: [map()]
  def project_all do
    GenServer.call(__MODULE__, :project_all)
  end

  @doc "Get milestone readiness dashboard."
  @spec dashboard() :: map()
  def dashboard do
    GenServer.call(__MODULE__, :dashboard)
  end

  @doc "Return engine stats."
  @spec stats() :: map()
  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  @impl true
  def handle_call({:project, milestone}, _from, state) do
    projection = build_projection(milestone, state)
    milestones = Map.put(state.milestones, milestone, projection)
    {:reply, {:ok, projection},
     %{state | milestones: milestones, total_projections: state.total_projections + 1,
               last_projection: projection.projected_at}}
  end

  def handle_call(:project_all, _from, state) do
    results = Enum.map(@milestones, fn m -> build_projection(m, state) end)
    {:reply, results, state}
  end

  def handle_call(:dashboard, _from, state) do
    {:reply, %{
      milestones: state.milestones,
      overall_readiness: compute_overall_readiness(state.milestones),
      last_updated: state.last_projection
    }, state}
  end

  def handle_call(:stats, _from, state) do
    {:reply, %{
      total_projections: state.total_projections,
      milestones_tracked: @milestones,
      last_projection: state.last_projection
    }, state}
  end

  defp compute_eta(:scientific_throughput, current), do: trunc((100 - current) / 2.0)
  defp compute_eta(:discovery_completion, current), do: trunc((100 - current) / 1.5)
  defp compute_eta(:certification_ready, current), do: trunc((100 - current) / 1.0)
  defp compute_eta(:planetary_maturity, current), do: trunc((100 - current) / 0.8)
  defp compute_eta(:civilization_readiness, current), do: trunc((100 - current) / 0.5)

  defp compute_confidence(:scientific_throughput, _), do: 0.75
  defp compute_confidence(:discovery_completion, _), do: 0.70
  defp compute_confidence(:certification_ready, _), do: 0.80
  defp compute_confidence(:planetary_maturity, _), do: 0.60
  defp compute_confidence(:civilization_readiness, _), do: 0.50

  defp compute_overall_readiness(milestones) do
    scores = Enum.map(milestones, fn {_k, v} ->
      case v do
        %{current: c} -> c
        %{current_progress: c} -> c
        _ -> 0
      end
    end)
    if length(scores) > 0 do
      Enum.sum(scores) / length(scores)
    else
      0.0
    end
  end

  defp build_projection(milestone, state) do
    progress = Map.get(state.milestones, milestone, default_progress(milestone))
    now = DateTime.utc_now()
    eta_days = compute_eta(milestone, progress.current)
    confidence = compute_confidence(milestone, progress.current)

    %{
      milestone: milestone,
      current_progress: progress.current,
      target: 100.0,
      eta_days: eta_days,
      eta_date: DateTime.add(now, eta_days * 86400, :second),
      confidence: confidence,
      trend: progress.trend,
      projected_at: now
    }
  end

  defp default_progress(:scientific_throughput), do: %{current: 35.0, trend: :increasing}
  defp default_progress(:discovery_completion), do: %{current: 22.0, trend: :increasing}
  defp default_progress(:certification_ready), do: %{current: 15.0, trend: :stable}
  defp default_progress(:planetary_maturity), do: %{current: 10.0, trend: :stable}
  defp default_progress(:civilization_readiness), do: %{current: 5.0, trend: :slow}
end
