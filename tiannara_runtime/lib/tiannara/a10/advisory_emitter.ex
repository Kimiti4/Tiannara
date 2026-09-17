defmodule Tiannara.A10.AdvisoryEmitter do
  @moduledoc """
  Emits epistemic drift advisories to the EventBus.
  Does NOT directly tune MSCL constraints.
  """
  use GenServer
  alias Tiannara.EventBus

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{}}
  end

  def handle_cast({:emit_advisory, phase, trace}, state) do
    # Emit an advisory payload to the EventBus
    # CIS will interpret this
    payload = %{
      phase: phase,
      structural_drift: trace,
      timestamp: System.os_time(:millisecond)
    }
    
    EventBus.broadcast("drift.advisory", :advisory_issued, payload)
    
    {:noreply, state}
  end
end
