defmodule Tiannara.Metrics.Export do
  @moduledoc """
  Persists Metrics Snapshots for historical validation.
  """
  require Logger

  @export_file "data/metrics_snapshot.ndjson"

  def persist_snapshot(snapshot) do
    File.mkdir_p!("data")
    json = Jason.encode!(Map.from_struct(snapshot)) <> "\n"
    File.write!(@export_file, json, [:append])
    Logger.debug("💾 [Metrics.Export] Persisted snapshot to #{@export_file}")
  end
end
