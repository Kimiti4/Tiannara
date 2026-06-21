defmodule Tiannara.Web.ReportChannel do
  use Phoenix.Channel
  alias Tiannara.Report.ProgressiveAggregator
  alias Tiannara.Telemetry.ReportSlice

  def join("report:completion", _payload, socket) do
    # Spawn aggregator, bind to demand-driven stream
    {:ok, aggregator} = ProgressiveAggregator.start_link(%{source_pid: self()})
    send(self(), {:start_pull, aggregator})
    {:ok, assign(socket, %{aggregator: aggregator, pct: 0})}
  end

  def handle_info({:start_pull, agg}, socket) do
    # Pull in chunks of 10, report progress to UI
    GenStage.sync_subscribe(self(), to: agg, max_demand: 10)
    {:noreply, socket}
  end

  def handle_info({:progress, pct}, socket) do
    push(socket, "progress", %{pct: pct})
    {:noreply, socket}
  end

  def handle_info({:chunk, data}, socket) do
    push(socket, "slice", {:binary, ReportSlice.encode(struct(ReportSlice, data))})
    {:noreply, socket}
  end
end
