defmodule TiannaraRuntime.Mathematics.ProofComposer do
  @moduledoc """
  Composes proof candidates from verified-or-unverified lemma/proof objects.

  Composition itself never confers truth. It rejects circular dependencies and
  records every consumed object for later independent verification.
  """

  alias TiannaraRuntime.Mathematics.MathematicalID
  alias TiannaraRuntime.Mathematics.ProofEngine

  def compose(assertion_id, components) when is_binary(assertion_id) and is_list(components) do
    nodes =
      Enum.map(components, fn c ->
        %{
          "node_id" => Map.get(c, "proof_id") || Map.get(c, "lemma_id") || Map.get(c, :proof_id) || Map.get(c, :lemma_id),
          "type" => if(Map.has_key?(c, "proof_id") or Map.has_key?(c, :proof_id), do: "proof", else: "lemma")
        }
      end)

    edges =
      Enum.flat_map(components, fn c ->
        id = Map.get(c, "proof_id") || Map.get(c, "lemma_id") || Map.get(c, :proof_id) || Map.get(c, :lemma_id)
        deps = Map.get(c, "dependencies", Map.get(c, :dependencies, []))
        Enum.map(deps, &%{"from" => &1, "to" => id, "edge_type" => "DEPENDS_ON"})
      end)

    case ProofEngine.detect_cycles(nodes, edges) do
      {:error, cycles} ->
        {:error, {:circular_proof_dependency, cycles}}

      {:ok, :no_cycles} ->
        composition_id = MathematicalID.from_canonical_map(%{
          "assertion_id" => assertion_id,
          "components" => Enum.map(nodes, & &1["node_id"])
        })

        {:ok, %{
          "composition_id" => "composition_" <> composition_id,
          "assertion_id" => assertion_id,
          "components" => nodes,
          "dependencies" => Enum.map(edges, & &1["from"]) |> Enum.uniq() |> Enum.sort(),
          "status" => "candidate",
          "verification_status" => "unverified",
          "certification_eligible" => false
        }}
    end
  end
end
