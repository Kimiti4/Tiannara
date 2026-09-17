defmodule TiannaraRuntime.Omega.FailureObservatory do
  @moduledoc """
  Captures runtime failures and anomalous Omega events without crashing callers.
  """

  use GenServer

  alias TiannaraRuntime.Omega.{SafeCPL, SentinelEventBus}

  @default_max_failures 500

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec record_failure(atom() | String.t(), term(), map()) :: :ok
  def record_failure(source, reason, metadata \\ %{}) do
    if Process.whereis(__MODULE__) do
      GenServer.cast(__MODULE__, {:record_failure, source, reason, metadata})
    end

    :ok
  end

  @spec report() :: map()
  def report do
    GenServer.call(__MODULE__, :report)
  end

  @impl true
  def init(opts) do
    send(self(), :subscribe)

    {:ok,
     %{
       failures: [],
       failure_count: 0,
       max_failures: Keyword.get(opts, :max_failures, @default_max_failures)
     }}
  end

  @impl true
  def handle_cast({:record_failure, source, reason, metadata}, state) do
    failure = build_failure(source, reason, metadata)
    SafeCPL.record_event(:failure, failure)
    publish_recorded_failure(failure)

    {:noreply,
     %{
       state
       | failures: [failure | state.failures] |> Enum.take(state.max_failures),
         failure_count: state.failure_count + 1
     }}
  end

  @impl true
  def handle_call(:report, _from, state) do
    {:reply,
     %{
       failure_count: state.failure_count,
       retained_failures: length(state.failures),
       recent_failures: Enum.take(state.failures, 25),
       status: if(state.failure_count == 0, do: :clear, else: :observing_failures)
     }, state}
  end

  @impl true
  def handle_info(:subscribe, state) do
    if Process.whereis(SentinelEventBus) do
      SentinelEventBus.subscribe(:all)
    end

    {:noreply, state}
  end

  @impl true
  def handle_info({:tiannara_event, %{topic: topic} = event}, state) do
    if failure_topic?(topic) do
      handle_cast(
        {:record_failure, topic, Map.get(event, :payload), %{event_id: event.id}},
        state
      )
    else
      {:noreply, state}
    end
  end

  defp build_failure(source, reason, metadata) do
    %{
      id: "omega_failure_#{System.unique_integer([:positive])}",
      source: source,
      reason: inspect(reason),
      metadata: metadata,
      timestamp: System.system_time(:millisecond),
      monotonic_time: System.monotonic_time(:millisecond)
    }
  end

  defp failure_topic?(topic) when is_atom(topic) do
    topic in [:failure, :checkpoint_failure, :dependency_failure, :runtime_anomaly]
  end

  defp failure_topic?(topic) when is_binary(topic) do
    String.contains?(topic, ["failure", "anomaly", "crash"])
  end

  defp publish_recorded_failure(failure) do
    if Process.whereis(SentinelEventBus) do
      SentinelEventBus.publish(:failure_recorded, failure, %{source: __MODULE__})
    end
  end
end
