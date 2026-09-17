defmodule TiannaraRuntime.WorldModel.Ontology.DiscoveryRegistry do
  require Logger
  @doc "Count discoveries within a time window (ms)"
  def count_recent(_time_window_ms) do
    {:ok, 0}
  end
  @doc "Get recent discoveries within a time window"
  def get_recent(_time_window_ms) do
    {:ok, []}
  end
  @doc "Count discoveries with engineering applications"
  def count_with_engineering do
    {:ok, 0}
  end
  @doc "Count all discoveries"
  def count_all do
    {:ok, 0}
  end
end
