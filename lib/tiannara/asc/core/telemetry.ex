defmodule Tiannara.ASC.Core.Telemetry do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def emit(phase, event, measurements \\ %{}, metadata \\ %{}) do
    :telemetry.execute(
      [:tiannara, :asc, phase, event],
      Map.put(measurements, :system_time, System.monotonic_time()),
      Map.merge(metadata, %{phase: phase, at: DateTime.utc_now()})
    )
  end

  def timed(phase, event, fun) when is_function(fun, 0) do
    start = System.monotonic_time(:millisecond)
    result = fun.()
    duration = System.monotonic_time(:millisecond) - start
    emit(phase, :"#{event}_duration", %{duration_ms: duration})
    result
  end

  @impl true
  def init(_opts), do: {:ok, %{started_at: DateTime.utc_now()}}

  @impl true
  def handle_call(:snapshot, _from, state), do: {:reply, %{started_at: state.started_at}, state}

  @impl true
  def handle_info(_, state), do: {:noreply, state}
end
