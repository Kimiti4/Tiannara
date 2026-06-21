defmodule Tiannara.Meta.Hardware.HorizonScheduler do
  @moduledoc """
  Dynamically maps incoming Exascale payloads to the HSV pool 
  based on distance penalties and available Planck-area capacity.
  """
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def route_payload(payload) do
    GenServer.call(__MODULE__, {:route, payload})
  end

  @impl true
  def init(opts) do
    hsv_pool = Keyword.get(opts, :hsv_pool, [:hsv_alpha, :hsv_beta, :hsv_gamma])
    {:ok, %{hsv_pool: hsv_pool}}
  end

  @impl true
  def handle_call({:route, payload}, _from, state) do
    result = attempt_routing(state.hsv_pool, payload)
    {:reply, result, state}
  end

  # Recursive failover: if an HSV is saturated, try the next one
  defp attempt_routing([], _payload) do
    Logger.error("🔥 [Scheduler] All Event Horizons saturated. Dropping payload.")
    {:error, :total_saturation}
  end

  defp attempt_routing([hsv_id | rest], payload) do
    case Tiannara.Meta.Hardware.EventHorizonTensorCore.submit_payload(hsv_id, payload) do
      :accepted -> {:ok, hsv_id}
      {:error, :backpressure} -> attempt_routing(rest, payload)
      {:error, _reason} -> attempt_routing(rest, payload)
    end
  end
end
