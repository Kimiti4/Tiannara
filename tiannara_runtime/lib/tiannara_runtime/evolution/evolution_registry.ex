defmodule TiannaraRuntime.Evolution.EvolutionRegistry do
  require Logger
  @doc "Count evolution events within a time window (ms)"
  def get_recent_count(_time_window_ms) do
    {:ok, 0}
  end
end
