defmodule TiannaraAudit.GraphVerifier do
  @moduledoc """
  Independently verifies graph root and node consistency.

  Reconstructs graph root from node/edge data using the same
  deterministic algorithm as MathematicsKnowledgeGraph.

  The verifier is fail-closed: a claim is verified only when the sample
  carries the expectation it is compared against. A missing expectation is a
  failure, not a pass (F-ARC-007).
  """

  alias TiannaraAudit.HashVerifier

  # Keys that describe the claim rather than the claimed content. They are
  # excluded from the canonicalised metadata so that adding an expectation
  # does not change the hash being verified.
  @claim_keys [:node_id, :node_type, :expected_hash, :sample_id, :seq]

  def verify(samples) when is_list(samples) do
    results = Enum.map(samples, fn sample ->
      node_id = sample[:node_id]
      node_type = sample[:node_type]
      metadata = Map.drop(sample, @claim_keys)

      canonical = %{
        "node_id" => node_id,
        "node_type" => node_type,
        "metadata" => canonicalize_metadata(metadata)
      }

      computed_hash = HashVerifier.from_canonical_map(canonical)
      expected = sample[:expected_hash]

      cond do
        is_nil(expected) ->
          %{
            sample_id: sample[:seq] || sample[:sample_id] || 0,
            node_id: node_id,
            computed_hash: computed_hash,
            match: false,
            detail: "no expected hash to verify against"
          }

        computed_hash == expected ->
          %{
            sample_id: sample[:seq] || sample[:sample_id] || 0,
            node_id: node_id,
            computed_hash: computed_hash,
            expected_hash: expected,
            match: true
          }

        true ->
          %{
            sample_id: sample[:seq] || sample[:sample_id] || 0,
            node_id: node_id,
            computed_hash: computed_hash,
            expected_hash: expected,
            match: false,
            detail: "expected #{expected}, computed #{computed_hash}"
          }
      end
    end)

    failures = Enum.filter(results, fn r -> not r.match end)

    %{
      total: length(results),
      failures: length(failures),
      details: Enum.map(failures, fn f ->
        "Graph node ##{f.sample_id}: #{Map.get(f, :detail, "mismatch")}"
      end)
    }
  end

  defp canonicalize_metadata(map) when is_map(map) do
    map
    |> Enum.map(fn {k, v} -> {to_string(k), v} end)
    |> Enum.sort_by(fn {k, _v} -> k end)
    |> Enum.into(%{})
  end
end
