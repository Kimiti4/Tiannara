defmodule ObservationBus.CIL.Prediction.RiskProjection do
  @moduledoc """
  Forecasts constitutional failures before they materialize.

  Risk types: replay overload, knowledge collapse, theory monoculture,
  engineering stagnation, certification bottleneck.

  Each projection includes probability, impact, time horizon, and
  mitigation options.
  """

  use GenServer

  @risk_types ~w(replay_overload knowledge_collapse theory_monoculture
                  engineering_stagnation certification_bottleneck)a

  defstruct [:projections, :total_projections, :last_projection]

  @doc false
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    projs = Enum.into(@risk_types, %{}, fn rt -> {rt, default_projection(rt)} end)
    {:ok, %__MODULE__{projections: projs, total_projections: 0, last_projection: nil}}
  end

  @doc "Project a specific risk type."
  @spec project(atom(), keyword()) :: {:ok, map()}
  def project(risk_type, indicators \\ []) when risk_type in @risk_types do
    GenServer.call(__MODULE__, {:project, risk_type, indicators})
  end

  @doc "Project all risk types."
  @spec project_all() :: [map()]
  def project_all do
    GenServer.call(__MODULE__, :project_all)
  end

  @doc "Get top risks by severity."
  @spec top_risks(pos_integer()) :: [map()]
  def top_risks(count \\ 5) do
    GenServer.call(__MODULE__, {:top, count})
  end

  @doc "Return engine stats."
  @spec stats() :: map()
  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  @impl true
  def handle_call({:project, risk_type, indicators}, _from, state) do
    projection = build_projection(risk_type, indicators)
    projs = Map.put(state.projections, risk_type, projection)
    {:reply, {:ok, projection},
     %{state | projections: projs, total_projections: state.total_projections + 1,
               last_projection: DateTime.utc_now()}}
  end

  def handle_call(:project_all, _from, state) do
    results = Enum.map(@risk_types, fn rt ->
      build_projection(rt, [])
    end)
    {:reply, results, state}
  end

  def handle_call({:top, count}, _from, state) do
    state.projections
    |> Map.values()
    |> Enum.sort_by(& &1.severity, :desc)
    |> Enum.take(count)
    |> then(&{:reply, &1, state})
  end

  def handle_call(:stats, _from, state) do
    {:reply, %{
      total_projections: state.total_projections,
      risk_types_tracked: @risk_types,
      last_projection: state.last_projection
    }, state}
  end

  defp build_projection(risk_type, indicators) do
    probability = compute_probability(risk_type, indicators)
    impact = compute_impact(risk_type)
    severity = probability * impact

    %{
      risk_type: risk_type,
      probability: probability,
      impact: impact,
      severity: min(10, trunc(severity * 10)),
      time_horizon: compute_horizon(risk_type),
      mitigation: mitigation_strategy(risk_type),
      indicators: indicators,
      projected_at: DateTime.utc_now()
    }
  end

  defp compute_probability(:replay_overload, indicators) do
    base = 0.3
    boost = if :high_queue_depth in indicators, do: 0.3, else: 0
    min(1.0, base + boost)
  end

  defp compute_probability(:knowledge_collapse, indicators) do
    base = 0.15
    boost = if :low_knowledge_diversity in indicators, do: 0.2, else: 0
    min(1.0, base + boost)
  end

  defp compute_probability(:theory_monoculture, indicators) do
    base = 0.2
    boost = if :low_theory_diversity in indicators, do: 0.25, else: 0
    min(1.0, base + boost)
  end

  defp compute_probability(:engineering_stagnation, indicators) do
    base = 0.2
    boost = if :low_engineering_velocity in indicators, do: 0.2, else: 0
    min(1.0, base + boost)
  end

  defp compute_probability(:certification_bottleneck, indicators) do
    base = 0.25
    boost = if :high_certification_queue in indicators, do: 0.3, else: 0
    min(1.0, base + boost)
  end

  defp compute_impact(:replay_overload), do: 0.8
  defp compute_impact(:knowledge_collapse), do: 0.9
  defp compute_impact(:theory_monoculture), do: 0.6
  defp compute_impact(:engineering_stagnation), do: 0.7
  defp compute_impact(:certification_bottleneck), do: 0.5

  defp compute_horizon(:replay_overload), do: "1-7 days"
  defp compute_horizon(:knowledge_collapse), do: "30-90 days"
  defp compute_horizon(:theory_monoculture), do: "90-180 days"
  defp compute_horizon(:engineering_stagnation), do: "30-60 days"
  defp compute_horizon(:certification_bottleneck), do: "7-30 days"

  defp mitigation_strategy(:replay_overload), do: "Reduce replay frequency, increase storage capacity"
  defp mitigation_strategy(:knowledge_collapse), do: "Expand ontology, diversify knowledge sources"
  defp mitigation_strategy(:theory_monoculture), do: "Encourage competing theories, fund alternative paradigms"
  defp mitigation_strategy(:engineering_stagnation), do: "Increase engineering budget, hire additional engineers"
  defp mitigation_strategy(:certification_bottleneck), do: "Automate certification pipeline, add certification capacity"

  defp default_projection(rt) do
    %{risk_type: rt, probability: 0.0, impact: 0.0, severity: 0,
      time_horizon: "unknown", mitigation: "", indicators: [],
      projected_at: nil}
  end
end
