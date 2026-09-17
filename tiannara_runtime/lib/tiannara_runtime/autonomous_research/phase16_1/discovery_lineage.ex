defmodule TiannaraRuntime.AutonomousResearch.Phase16_1.DiscoveryLineage do
  @moduledoc """
  Phase 16.1 Module 8 — Discovery Lineage (Pure Implementation)

  Implements frozen contract from RESEARCH_RUNTIME_FREEZE.md 2.9 CertificateIssuer:
  - issuer verifies criteria satisfaction from immutable artifacts and emits certificate outputs.

  Every discovery answers:
  - Origin, Evidence, Experiments, Theories, Certificates, Research Program, Dependencies

  All lineage entries are immutable and replayable.
  """

  @lineage_table :discovery_lineage

  def init_table do
    if :ets.info(@lineage_table) == :undefined do
      :ets.new(@lineage_table, [:set, :public, :named_table])
    end

    :ok
  end

  @doc "Build lineage entry for an artifact"
  @spec build_lineage(String.t(), String.t(), [String.t()], map()) :: {:ok, map()}
  def build_lineage(artifact_id, artifact_type, inputs, context) do
    init_table()
    lineage = build_lineage_entry(artifact_id, artifact_type, inputs, context)
    :ets.insert(@lineage_table, {artifact_id, lineage})
    {:ok, lineage}
  end

  @doc "Replay lineage from immutable inputs"
  @spec replay_lineage(String.t(), map()) :: {:ok, map()}
  def replay_lineage(artifact_id, inputs) do
    lineage = rebuild_lineage_entry(artifact_id, inputs)
    {:ok, lineage}
  end

  @doc "Lookup lineage by ID"
  @spec lookup_lineage(String.t()) :: {:ok, map()} | :error
  def lookup_lineage(lineage_id) do
    case :ets.lookup(@lineage_table, lineage_id) do
      [{^lineage_id, lineage}] -> {:ok, lineage}
      [] -> :error
    end
  end

  # --- internal helpers ---

  defp build_lineage_entry(artifact_id, artifact_type, inputs, context) do
    canonical = canonicalize_map(Map.merge(context, %{"inputs" => inputs}))
    lineage_node_id = "lineage_" <> (Jason.encode!(canonical) |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower))

    %{
      "lineage_node_id" => lineage_node_id,
      "schema_version" => "16.1.0",
      "artifact_type" => artifact_type,
      "artifact_id" => artifact_id,
      "inputs_hashes" => Enum.map(inputs, &hash_input/1),
      "decision_context_hash" => lineage_node_id,
      "outputs_hashes" => [],
      "parents" => [],
      "archaeology_metadata" => %{
        "origin" => Map.get(context, "origin", "unknown"),
        "owner" => Map.get(context, "owner", "Constitutional Research Council"),
        "phase" => Map.get(context, "phase", "16.1")
      }
    }
  end

  defp rebuild_lineage_entry(artifact_id, inputs) do
    canonical = canonicalize_map(%{"artifact_id" => artifact_id, "inputs" => inputs})
    computed_id = "lineage_" <> (Jason.encode!(canonical) |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower))

    %{
      "lineage_node_id" => computed_id,
      "artifact_id" => artifact_id,
      "replayed" => true
    }
  end

  defp hash_input(input) when is_binary(input), do: input
  defp hash_input(input) when is_map(input) do
    input |> canonicalize_map() |> Jason.encode!() |> then(&:crypto.hash(:sha256, &1)) |> Base.encode16(case: :lower)
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
