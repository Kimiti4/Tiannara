defmodule TelemetryGateway.TelemetryAuditor do
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def record(category, detail \\ nil) do
    GenServer.cast(__MODULE__, {:record, category, detail})
  end

  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  def reset do
    GenServer.cast(__MODULE__, :reset)
  end

  @impl true
  def init(_opts) do
    {:ok,
     %{
       counters: %{},
       malformed: 0,
       dropped: 0,
       dead_letters: 0,
       replayed: 0,
       signatures_verified: 0,
       signatures_failed: 0,
       duplicates_detected: 0,
       total_ingested: 0,
       total_validated: 0,
       total_routed: 0,
       validation_errors: %{},
       start_time: System.system_time(:millisecond)
     }}
  end

  @impl true
  def handle_cast({:record, category, detail}, state) do
    state
    |> record_event(category, detail)
    |> then(fn s -> {:noreply, s} end)
  end

  @impl true
  def handle_cast(:reset, _state) do
    {:noreply,
     %{
       counters: %{},
       malformed: 0,
       dropped: 0,
       dead_letters: 0,
       replayed: 0,
       signatures_verified: 0,
       signatures_failed: 0,
       duplicates_detected: 0,
       total_ingested: 0,
       total_validated: 0,
       total_routed: 0,
       validation_errors: %{},
       start_time: System.system_time(:millisecond)
     }}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    uptime = System.system_time(:millisecond) - state.start_time
    stats = Map.put(state, :uptime_ms, uptime)
    {:reply, stats, state}
  end

  defp record_event(state, :ingested, _), do: %{state | total_ingested: state.total_ingested + 1}

  defp record_event(state, :validated, _),
    do: %{state | total_validated: state.total_validated + 1}

  defp record_event(state, :routed, _), do: %{state | total_routed: state.total_routed + 1}
  defp record_event(state, :dropped, _), do: %{state | dropped: state.dropped + 1}
  defp record_event(state, :dead_letter, _), do: %{state | dead_letters: state.dead_letters + 1}
  defp record_event(state, :malformed, _), do: %{state | malformed: state.malformed + 1}
  defp record_event(state, :replayed, _), do: %{state | replayed: state.replayed + 1}

  defp record_event(state, :signature_ok, _),
    do: %{state | signatures_verified: state.signatures_verified + 1}

  defp record_event(state, :signature_fail, _),
    do: %{state | signatures_failed: state.signatures_failed + 1}

  defp record_event(state, :duplicate, _),
    do: %{state | duplicates_detected: state.duplicates_detected + 1}

  defp record_event(state, :validation_error, detail) do
    errors = Map.update(state.validation_errors, detail, 1, &(&1 + 1))
    %{state | validation_errors: errors}
  end

  defp record_event(state, :counter, {name, by}) do
    %{state | counters: Map.update(state.counters, name, by, &(&1 + by))}
  end
end
