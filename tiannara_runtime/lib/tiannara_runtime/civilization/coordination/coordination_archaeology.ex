defmodule TiannaraRuntime.Civilization.Coordination.CoordinationArchaeology do
  def record(coordinator, collab_engine, origin) do
    {:ok, %{coordinator: coordinator, collab_engine: collab_engine, origin: origin, lineage: []}}
  end

  def explain(archaeology) do
    collab_count = length(Map.get(archaeology, :coordinator, %{}) |> Map.get(:collaborations, []))
    proposal_count = length(Map.get(archaeology, :collab_engine, %{}) |> Map.get(:proposals, []))
    narrative = "Coordination archaeology from #{Map.get(archaeology, :origin)}: #{collab_count} collaborations, #{proposal_count} proposals"
    {:ok, narrative}
  end

  def get_lineage(archaeology) do
    {:ok, Map.get(archaeology, :lineage, [])}
  end
end
