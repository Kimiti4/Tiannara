defmodule TiannaraRuntime.IRD.QuiescenceManager do
  @moduledoc """
  Phase 5F.12 — IRD Quiescence Manager

  Controls global quiescence windows when stabilizer interference risk
  exceeds safe thresholds.
  """

  use GenServer
  require Logger

  alias TiannaraRuntime.NATS.Publisher

  @quiescence_subject "tiannara.ird.quiescence.global"
  @quiescence_window_ms 800

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %{active: false, last_triggered: nil}}
  end

  @doc "Trigger a global quiescence window for the IRD pipeline."
  def trigger_global_quiescence(interference) do
    GenServer.cast(__MODULE__, {:trigger, interference})
  end

  @impl true
  def handle_cast({:trigger, interference}, state) do
    if state.active do
      {:noreply, state}
    else
      payload = %{
        event: :quiescence_started,
        interference: interference,
        initiated_at: DateTime.utc_now() |> DateTime.to_iso8601(),
        duration_ms: @quiescence_window_ms
      }

      Logger.warning(
        "⚠️ [IRD] Quiescence window started due to high interference #{inspect(interference)}"
      )

      Publisher.publish(@quiescence_subject, Jason.encode!(payload))

      Process.send_after(self(), :end_quiescence, @quiescence_window_ms)

      {:noreply, %{state | active: true, last_triggered: System.system_time(:millisecond)}}
    end
  end

  @impl true
  def handle_info(:end_quiescence, state) do
    payload = %{
      event: :quiescence_ended,
      ended_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    Logger.info("✅ [IRD] Quiescence window ended")
    Publisher.publish(@quiescence_subject, Jason.encode!(payload))
    {:noreply, %{state | active: false}}
  end
end
