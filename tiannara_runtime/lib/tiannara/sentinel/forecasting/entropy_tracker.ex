defmodule Tiannara.Sentinel.Forecasting.EntropyTracker do
  @moduledoc """
  Tracks entropy trends over time to identify ecological collapse risks.
  H = -Σ p_i log(p_i)
  """
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %{historical_entropy: []}}
  end
end
