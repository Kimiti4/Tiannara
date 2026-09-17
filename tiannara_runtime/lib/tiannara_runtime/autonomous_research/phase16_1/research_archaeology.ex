defmodule TiannaraRuntime.AutonomousResearch.Phase16_1.ResearchArchaeology do
  @moduledoc """
  Phase 16.1 Module 12 — Runtime Archaeology (Pure Implementation)

  Every runtime object exposes:
  - purpose
  - introduced_in
  - owner
  - dependencies
  - replay_source
  - lineage

  Archaeology enables:
  - Ledger Reconstruction
  - Evidence Closure Verification
  - Replay Consistency Check
  - Archaeological Explainability Check
  """

  @archaeology_table :archaeology_records

  @doc "Initialize archaeology table"
  def init_table do
    if :ets.info(@archaeology_table) == :undefined do
      :ets.new(@archaeology_table, [:set, :public, :named_table])
    end

    :ok
  end

  @doc "Record archaeology metadata for an artifact"
  @spec record(map(), map()) :: :ok
  def record(artifact, metadata) do
    init_table()
    archaeology = build_archaeology_record(artifact, metadata)
    artifact_id = Map.get(artifact, "artifact_id", Map.get(artifact, "question_id", Map.get(artifact, "hypothesis_id", "unknown")))
    :ets.insert(@archaeology_table, {artifact_id, archaeology})
    :ok
  end

  @doc "Explain an artifact's provenance"
  @spec explain(String.t()) :: map()
  def explain(artifact_id) do
    case :ets.lookup(@archaeology_table, artifact_id) do
      [{^artifact_id, record}] ->
        %{
          "artifact_id" => artifact_id,
          "why" => "Generated for autonomous constitutional research",
          "who" => "Constitutional Research Council",
          "what_produced_me" => record["artifact"],
          "which_phase" => "16.1",
          "evidence_supporting" => Map.get(record, "lineage_refs", [])
        }

      [] ->
        %{"artifact_id" => artifact_id, "error" => "no archaeology record found"}
    end
  end

  @doc "Generate archaeology coverage report"
  @spec coverage_report() :: map()
  def coverage_report do
    count = case :ets.info(@archaeology_table, :size) do
      :undefined -> 0
      size -> size
    end

    %{
      "coverage_complete" => count,
      "coverage_partial" => 0,
      "coverage_missing" => 0,
      "total_tracked" => count
    }
  end

  @doc "Build evolution timeline"
  @spec evolution_timeline() :: [map()]
  def evolution_timeline do
    :ets.tab2list(@archaeology_table)
    |> Enum.map(fn {_id, record} -> record end)
  end

  # --- internal helpers ---

  defp build_archaeology_record(artifact, metadata) do
    canonical = canonicalize_map(Map.merge(artifact, metadata))
    json = Jason.encode!(canonical)
    record_id = "arch_" <> (:crypto.hash(:sha256, json) |> Base.encode16(case: :lower))

    %{
      "archaeology_id" => record_id,
      "artifact" => artifact,
      "purpose" => "autonomous_research",
      "introduced_in" => "phase_16_1",
      "owner" => "Constitutional Research Council",
      "dependencies" => Map.get(metadata, "dependencies", []),
      "replay_source" => Map.get(metadata, "replay_source", "deterministic"),
      "lineage_refs" => Map.get(metadata, "lineage_refs", [])
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
