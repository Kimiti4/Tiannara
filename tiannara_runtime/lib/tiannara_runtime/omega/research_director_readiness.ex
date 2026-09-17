defmodule TiannaraRuntime.Omega.ResearchDirectorReadiness do
  @moduledoc """
  Converts observations into queued research candidates without running experiments.
  """

  use GenServer

  alias TiannaraRuntime.Omega.{SafeCPL, SentinelEventBus}

  @max_queue 250

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def queue, do: GenServer.call(__MODULE__, :queue)
  def status, do: GenServer.call(__MODULE__, :status)

  @impl true
  def init(_opts) do
    send(self(), :subscribe)
    {:ok, %{queue: [], observed: 0, candidates: 0}}
  end

  @impl true
  def handle_call(:queue, _from, state), do: {:reply, state.queue, state}

  @impl true
  def handle_call(:status, _from, state) do
    {:reply,
     %{
       observed: state.observed,
       candidates: state.candidates,
       queued: length(state.queue),
       experiments_enabled: false
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
  def handle_info({:tiannara_event, event}, state) do
    state = %{state | observed: state.observed + 1}

    case candidate_from_event(event) do
      nil ->
        {:noreply, state}

      candidate ->
        SafeCPL.record_event(:research_candidate, candidate)
        publish(:research_candidate_queued, candidate)

        queue =
          [candidate | state.queue]
          |> Enum.sort_by(& &1.priority_score, :desc)
          |> Enum.take(@max_queue)

        {:noreply, %{state | queue: queue, candidates: state.candidates + 1}}
    end
  end

  defp candidate_from_event(event) do
    if candidate_topic?(event.topic) or candidate_payload?(event.payload) do
      %{
        id: "research_candidate_#{System.unique_integer([:positive])}",
        observation_event_id: event.id,
        topic: event.topic,
        priority_score: score(event),
        status: :queued,
        experiments_enabled: false,
        timestamp: System.system_time(:millisecond)
      }
    end
  end

  defp candidate_topic?(topic) when is_atom(topic) do
    topic in [:unknown_observed, :contradiction_detected, :research_opportunity, :runtime_anomaly]
  end

  defp candidate_topic?(topic) when is_binary(topic) do
    String.contains?(topic, ["unknown", "contradiction", "research", "anomaly"])
  end

  defp candidate_payload?(%{status: :unknown}), do: true
  defp candidate_payload?(%{"status" => "unknown"}), do: true
  defp candidate_payload?(_payload), do: false

  defp score(%{topic: :contradiction_detected}), do: 100
  defp score(%{topic: :runtime_anomaly}), do: 90
  defp score(%{topic: :unknown_observed}), do: 75
  defp score(_event), do: 50

  defp publish(topic, payload) do
    if Process.whereis(SentinelEventBus) do
      SentinelEventBus.publish(topic, payload, %{source: __MODULE__})
    end
  end
end
