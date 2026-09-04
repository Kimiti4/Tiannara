defmodule Tiannara.Autonomy.ImprovementEngine do
  @moduledoc """
  Improvement Engine — identifies improvement opportunities.
  Continuously analyzes runtime metrics, reflections, bottleneck reports,
  and performance data to identify where Tiannara can improve itself.
  """

  use GenServer
  require Logger
  alias Tiannara.Executive.Types

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec identify() :: [map()]
  def identify do
    GenServer.call(__MODULE__, :identify, 30_000)
  end

  @spec status() :: map()
  def status do
    GenServer.call(__MODULE__, :status)
  end

  @impl true
  def init(_opts) do
    {:ok, %{total_identified: 0, last_identification_at: nil, history: []}}
  end

  @impl true
  def handle_call(:identify, _from, state) do
    opportunities = gather_opportunities()
    new_state = %{state | total_identified: state.total_identified + length(opportunities), last_identification_at: DateTime.utc_now(), history: [opportunities | Enum.take(state.history, 49)]}
    :telemetry.execute([:tiannara, :autonomy, :opportunities_identified], %{count: length(opportunities)}, %{categories: Enum.map(opportunities, & &1.category)})
    {:reply, opportunities, new_state}
  end

  @impl true
  def handle_call(:status, _from, state) do
    {:reply, %{total_identified: state.total_identified, last_identification_at: state.last_identification_at, history_depth: length(state.history)}, state}
  end

  defp gather_opportunities do
    [] |> gather_from_reflections() |> gather_from_sentinel() |> gather_from_performance() |> gather_from_knowledge_gaps() |> Enum.sort_by(& &1.estimated_impact, :desc) |> Enum.take(10)
  end

  defp gather_from_reflections(opportunities) do
    case Process.whereis(Tiannara.Executive.Cognitive.ReflectionEngine) do
      nil -> opportunities
      _pid ->
        try do
          reflection = Tiannara.Executive.Cognitive.ReflectionEngine.last_reflection()
          if reflection do
            bottleneck_opps = (reflection[:bottlenecks] || []) |> Enum.map(fn b -> %{id: Types.new_id(), category: :bottleneck, target: :runtime, description: b, evidence: [reflection], estimated_impact: 0.7, confidence: reflection[:confidence] || 0.5, urgency: 0.6, identified_at: DateTime.utc_now()} end)
            scaling_opps = (reflection[:scaling_concerns] || []) |> Enum.map(fn c -> %{id: Types.new_id(), category: :scalability, target: :architecture, description: c, evidence: [reflection], estimated_impact: 0.8, confidence: 0.6, urgency: 0.5, identified_at: DateTime.utc_now()} end)
            opportunities ++ bottleneck_opps ++ scaling_opps
          else
            opportunities
          end
        catch _, _ -> opportunities end
    end
  end

  defp gather_from_sentinel(opportunities) do
    case Process.whereis(Tiannara.Sentinel.SentinelRuntime) do
      nil -> opportunities
      _pid ->
        try do
          health = Tiannara.Sentinel.SentinelRuntime.health()
          if health[:anomalies_detected] > 5 do
            [%{id: Types.new_id(), category: :reliability, target: :sentinel, description: "Sentinel has detected #{health[:anomalies_detected]} anomalies.", evidence: [health], estimated_impact: 0.6, confidence: 0.7, urgency: 0.7, identified_at: DateTime.utc_now()} | opportunities]
          else
            opportunities
          end
        catch _, _ -> opportunities end
    end
  end

  defp gather_from_performance(opportunities) do
    run_queue = :erlang.statistics(:run_queue)
    if run_queue > 4 do
      [%{id: Types.new_id(), category: :performance, target: :scheduler, description: "BEAM run queue at #{run_queue}. Scheduler saturation may be limiting throughput.", evidence: [%{run_queue: run_queue, timestamp: DateTime.utc_now()}], estimated_impact: 0.75, confidence: 0.8, urgency: 0.6, identified_at: DateTime.utc_now()} | opportunities]
    else
      opportunities
    end
  end

  defp gather_from_knowledge_gaps(opportunities) do
    case Process.whereis(Tiannara.Research.ResearchDirector) do
      nil -> opportunities
      _pid ->
        try do
          health = Tiannara.Research.ResearchDirector.health()
          if health[:active_hypotheses] > 10 do
            [%{id: Types.new_id(), category: :knowledge, target: :research_pipeline, description: "#{health[:active_hypotheses]} hypotheses pending investigation.", evidence: [health], estimated_impact: 0.65, confidence: 0.6, urgency: 0.4, identified_at: DateTime.utc_now()} | opportunities]
          else
            opportunities
          end
        catch _, _ -> opportunities end
    end
  end
end
