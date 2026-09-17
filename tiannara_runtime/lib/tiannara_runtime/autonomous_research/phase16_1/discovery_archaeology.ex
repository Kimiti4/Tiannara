defmodule TiannaraRuntime.AutonomousResearch.Phase16_1.DiscoveryArchaeology do
  @moduledoc """
  Phase 16.1 Module 8 — Discovery Archaeology (Pure Implementation)

  Records archaeological metadata for discovery lineage entries:
  - origin: where the discovery came from
  - context: what circumstances produced it
  - phase: which phase introduced it
  """

  @doc "Record archaeological context for a lineage entry"
  @spec record(String.t(), map()) :: map()
  def record(artifact_id, context) do
    canonical = canonicalize_map(Map.merge(context, %{"artifact_id" => artifact_id}))
    json = Jason.encode!(canonical)
    arch_id = "arch_disc_" <> (:crypto.hash(:sha256, json) |> Base.encode16(case: :lower))

    %{
      "archaeology_id" => arch_id,
      "artifact_id" => artifact_id,
      "origin" => Map.get(context, "origin", "unknown"),
      "owner" => Map.get(context, "owner", "Constitutional Research Council"),
      "phase" => Map.get(context, "phase", "16.1"),
      "context" => context
    }
  end

  defp canonicalize_map(term) when is_map(term) do
    term
    |> Enum.map(fn {k, v} -> {to_string(k), canonicalize_map(v)} end)
    |> Enum.sort_by(fn {k, _v} -> k end)
    |> Enum.into(%{})
  end

  defp canonicalize_map(term) when is_list(term), do: Enum.map(term, &canonicalize_map/1)
  defp canonicalize_map(term), do: term
end
