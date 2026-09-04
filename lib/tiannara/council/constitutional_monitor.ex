defmodule Tiannara.Council.ConstitutionalMonitor do
  use GenServer
  require Logger

  @monitor_interval :timer.seconds(30)

  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def health_report, do: GenServer.call(__MODULE__, :health_report)

  def report_score(service_id, scores), do: GenServer.cast(__MODULE__, {:report_score, service_id, scores})

  @impl true
  def init(_opts) do
    schedule_monitor()
    {:ok, %{service_scores: %{}, stress_log: [], last_report: nil}}
  end

  @impl true
  def handle_cast({:report_score, service_id, scores}, state) do
    new_scores = Map.put(state.service_scores, service_id, Map.put(scores, :reported_at, DateTime.utc_now()))
    {:noreply, %{state | service_scores: new_scores}}
  end

  @impl true
  def handle_call(:health_report, _from, state), do: {:reply, state.last_report, state}

  @impl true
  def handle_info(:monitor_cycle, state) do
    report = compute_health_report(state.service_scores)

    :telemetry.execute([:tiannara, :council, :monitor, :cycle], %{
      aggregate_score: report.aggregate_constitutional_score,
      services_monitored: report.services_monitored,
      stressed_principles: length(report.stressed_principles)
    }, %{stressed: report.stressed_principles})

    new_stress_log =
      if length(report.stressed_principles) > 0 do
        [%{at: DateTime.utc_now(), principles: report.stressed_principles} | state.stress_log]
        |> Enum.take(100)
      else
        state.stress_log
      end

    schedule_monitor()
    {:noreply, %{state | last_report: report, stress_log: new_stress_log}}
  end

  defp compute_health_report(service_scores) do
    if map_size(service_scores) == 0 do
      %{
        aggregate_constitutional_score: 1.0,
        services_monitored: 0,
        stressed_principles: [],
        service_details: [],
        autonomy_index: 0.0,
        computed_at: DateTime.utc_now()
      }
    else
      details =
        Enum.map(service_scores, fn {id, scores} ->
          %{
            service: id,
            constitutional_alignment: Map.get(scores, :constitutional_alignment, 1.0),
            transparency: Map.get(scores, :transparency, 1.0),
            explainability: Map.get(scores, :explainability, 1.0),
            evidence_quality: Map.get(scores, :evidence_quality, 1.0),
            human_oversight: Map.get(scores, :human_oversight, 1.0)
          }
        end)

      aggregate =
        details
        |> Enum.map(& &1.constitutional_alignment)
        |> Enum.sum()
        |> Kernel./(length(details))

      stressed =
        details
        |> Enum.filter(fn d -> d.constitutional_alignment < 0.8 end)
        |> Enum.map(& &1.service)

      %{
        aggregate_constitutional_score: aggregate,
        services_monitored: length(details),
        stressed_principles: stressed,
        service_details: details,
        autonomy_index: compute_autonomy_index(service_scores),
        computed_at: DateTime.utc_now()
      }
    end
  end

  defp compute_autonomy_index(service_scores) do
    oversight_scores =
      service_scores
      |> Map.values()
      |> Enum.map(&Map.get(&1, :human_oversight, 1.0))

    if length(oversight_scores) > 0 do
      1.0 - (Enum.sum(oversight_scores) / length(oversight_scores))
    else
      0.0
    end
  end

  defp schedule_monitor, do: Process.send_after(self(), :monitor_cycle, @monitor_interval)
end
