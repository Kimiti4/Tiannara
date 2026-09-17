defmodule TiannaraRuntime.AutonomousResearch.Phase16_1.Export.ArtifactExporter do
  @moduledoc """
  Phase 16.1 Artifact Exporter

  Exports all Phase 16.1 runtime state to immutable artifact bundles
  for consumption by the Phase 16.95 Independent Constitutional Auditor.

  Constitutional boundary:
  - Produces only NDJSON-serializable artifact bundles
  - Does NOT emit certification artifacts
  - Does NOT issue audit conclusions
  """

  @tables [
    :observation_registry,
    :knowledge_gaps,
    :research_questions,
    :research_priorities,
    :question_archive,
    :hypotheses,
    :experiments,
    :theories,
    :research_programs,
    :kg_nodes,
    :kg_edges,
    :discovery_lineage,
    :scientific_capital,
    :archaeology_records
  ]

  @doc "Export all ETS tables to an artifact bundle map"
  @spec export_all() :: %{String.t() => [map()]}
  def export_all do
    @tables
    |> Enum.map(fn table -> {Atom.to_string(table), ets_to_list(table)} end)
    |> Enum.into(%{})
  end

  @doc "Export a specific ETS table to a list"
  @spec export_table(atom()) :: [map()]
  def export_table(table) when is_atom(table) do
    ets_to_list(table)
  end

  @doc "Serialize all artifacts to NDJSON format"
  @spec to_ndjson(%{String.t() => [map()]}) :: binary()
  def to_ndjson(bundle) when is_map(bundle) do
    bundle
    |> Enum.map(fn {_key, artifacts} ->
      Enum.map(artifacts, fn artifact ->
        canonical = canonicalize_map(artifact)
        Jason.encode!(canonical)
      end)
    end)
    |> List.flatten()
    |> Enum.join("\n")
  end

  @doc "Build the research bundle (frozen audit input format)"
  @spec build_research_bundle() :: %{String.t() => [map()]}
  def build_research_bundle do
    %{
      "research_bundle" => export_table(:research_programs) ++ export_table(:research_questions),
      "knowledge_graph" => export_table(:kg_nodes) ++ export_table(:kg_edges),
      "scientific_capital" => export_table(:scientific_capital),
      "experiment_log" => export_table(:experiments) ++ export_table(:hypotheses),
      "replay_bundle" => [],
      "serialization_manifest" => [],
      "archaeology_bundle" => export_table(:archaeology_records)
    }
  end

  # --- internal helpers ---

  defp ets_to_list(table) do
    try do
      case :ets.info(table) do
        :undefined -> []
        _ -> :ets.tab2list(table) |> Enum.map(fn {_key, value} -> value end)
      end
    rescue
      _ -> []
    end
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
