defmodule Tiannara.HSV.Monitor do
  @moduledoc """
  Lightweight always‑on monitor for HSV.
  Tracks minimal metrics (Ω, Φ, CEI) and emits risk signals when
  thresholds are crossed.
  """

  use GenServer
  require Logger

  @default_state %{omega: 0.0, phi: 0.0, cei: 0.0}
  @risk_threshold 0.75

  # Public API
  def start_link(_opts), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def update_metrics(omega, phi, cei) do
    GenServer.cast(__MODULE__, {:update, omega, phi, cei})
  end

  # Callbacks
  def init(_args) do
    Logger.info("[HSV] Monitor started")
    {:ok, @default_state}
  end

  def handle_cast({:update, omega, phi, cei}, _state) do
    new_state = %{omega: omega, phi: phi, cei: cei}

    if risk?(new_state) do
      Logger.warning("[HSV] Risk signal emitted – metrics exceed threshold")
      send(self(), {:risk_signal, new_state})
    end

    {:noreply, new_state}
  end

  defp risk?(%{omega: o, phi: p, cei: c}) do
    # Simple heuristic: any metric > threshold triggers risk
    Enum.any?([o, p, c], &(&1 > @risk_threshold))
  end
end
