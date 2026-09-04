defmodule Tiannara.SystemHealth do
  @moduledoc """
  Unified interface for System Health.
  Dashboard and other subsystems should only query this interface.
  """
  require Logger

  @doc """
  Safely fetches a metric from a subsystem. If the subsystem crashes or isn't loaded,
  it falls back gracefully to prevent cascading failure to Mission Control.
  """
  def safe_metric(metric_name, fetcher_fn) do
    try do
      fetcher_fn.()
    rescue
      _e -> 
        Logger.warning("⚠️ [SystemHealth] Safe fallback triggered for #{metric_name}.")
        %{status: :unavailable}
    end
  end
end
