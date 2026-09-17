defmodule ObservationBus.Subscriber.MetricsEngine do
  @moduledoc """
  COB subscriber that feeds constitutional events into the Metrics Engine.
  """

  use GenServer

  @topic_pattern "constitution.*:*.*:*"

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    ObservationBus.SubscriptionRegistry.subscribe(self(), @topic_pattern)
    {:ok, %{recorded: 0}}
  end

  @impl true
  def handle_info({:constitutional_event, %ObservationBus.Event{} = event, _topic}, state) do
    feed_metrics_engine(event)
    {:noreply, %{state | recorded: state.recorded + 1}}
  end

  defp feed_metrics_engine(%ObservationBus.Event{domain: domain, priority: prio} = event) do
    domain_name = domain |> String.replace("/", "_") |> String.replace("-", "_")

    MetricsEngine.Counter.increment("cob.event.#{domain_name}", 1)
    MetricsEngine.Counter.increment("cob.event.all", 1)
    MetricsEngine.Counter.increment("cob.priority.#{prio}", 1)

    if event.global_sequence do
      MetricsEngine.Gauge.set("cob.global_sequence", event.global_sequence)
    end

    if event.timestamp do
      MetricsEngine.Histogram.observe("cob.event.latency_ms", latency_ms(event.timestamp))
    end

    :ok
  end

  defp latency_ms(timestamp) do
    DateTime.diff(DateTime.utc_now(), timestamp, :millisecond)
  end
end
