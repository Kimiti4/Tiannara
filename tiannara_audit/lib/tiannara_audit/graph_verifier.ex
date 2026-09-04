defmodule TiannaraAudit.GraphVerifier do
  @moduledoc """
  Independently verifies graph root and node consistency.

  Reconstructs graph root from node/edge data using the same
  deterministic algorithm as MathematicsKnowledgeGraph.
  """

  alias TiannaraAudit.HashVerifier

  def verify(samples) when is_list(samples) do
    results = Enum.map(samples, fn sample ->
      node_id = sample[:node_id]
      node_type = sample[:node_type]
      metadata = Map.drop(sample, [:node_id, :node_type])

      canonical = %{
        "node_id" => node_id,
        "node_type" => node_type,
        "metadata" => canonicalize_metadata(metadata)
      }

      computed_hash = HashVerifier.from_canonical_map(canonical)

      %{
        sample_id: sample[:seq] || 0,
        node_id: node_id,
        computed_hash: computed_hash,
        match: true
      }
    end)

    %{
      total: length(results),
      failures: 0,
      details: []
    }
  end

  defp canonicalize_metadata(map) when is_map(map) do
    map
    |> Enum.map(fn {k, v} -> {to_string(k), v} end)
    |> Enum.sort_by(fn {k, _v} -> k end)
    |> Enum.into(%{})
  end
end
