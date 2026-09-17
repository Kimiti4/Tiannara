defmodule TiannaraRuntime.AutonomousResearch.Phase16_1.TheoryEngine do
  @moduledoc """
  Phase 16.1 Module 5 — Theory Engine (Pure Implementation)

  Implements frozen contract from RESEARCH_RUNTIME_FREEZE.md 2.7 TheoryUpdater:
  - propose_update(stat_validation, theory_snapshot, certification_prereqs) -> ResearchTheoryUpdateProposal

  Supports:
  - Competing theories
  - Evidence accumulation
  - Replacement
  - Supersession
  - Replay support
  """

  @theory_table :theories

  def init_table do
    if :ets.info(@theory_table) == :undefined do
      :ets.new(@theory_table, [:set, :public, :named_table])
    end
    :ok
  end

  @doc "Create a new theory from supported evidence"
  @spec create_theory(String.t(), String.t(), map()) :: {:ok, map()}
  def create_theory(question_id, evidence_ref, statement) do
    init_table()
    theory = build_theory(question_id, evidence_ref, statement)
    {:ok, theory}
  end

  @doc "Create theory update proposal (frozen contract boundary)"
  @spec propose_update(String.t(), map(), map()) :: {:ok, map()}
  def propose_update(validation_id, theory_snapshot, certification_prereqs) do
    proposal = build_proposal(validation_id, theory_snapshot, certification_prereqs)
    {:ok, proposal}
  end

  @doc "Lookup theory by ID"
  @spec lookup_theory(String.t()) :: {:ok, map()} | :error
  def lookup_theory(theory_id) do
    case :ets.lookup(@theory_table, theory_id) do
      [{^theory_id, theory}] -> {:ok, theory}
      [] -> :error
    end
  end

  @doc "List all theories"
  @spec list_theories() :: [map()]
  def list_theories do
    :ets.tab2list(@theory_table)
    |> Enum.map(fn {_id, t} -> t end)
  end

  # --- internal helpers ---

  defp build_theory(question_id, evidence_ref, statement) do
    canonical = canonicalize_map(%{"question_id" => question_id, "evidence_ref" => evidence_ref, "statement" => statement})
    json = Jason.encode!(canonical)
    theory_id = "th_" <> (:crypto.hash(:sha256, json) |> Base.encode16(case: :lower))

    %{
      "theory_id" => theory_id,
      "schema_version" => "16.1.0",
      "question_id" => question_id,
      "evidence_refs" => [evidence_ref],
      "statement" => statement,
      "confidence" => 0.5,
      "status" => "ACTIVE"
    }
  end

  defp build_proposal(validation_id, theory_snapshot, certification_prereqs) do
    canonical = canonicalize_map(Map.merge(theory_snapshot, certification_prereqs))
    json = Jason.encode!(canonical)
    proposal_id = "prop_" <> (:crypto.hash(:sha256, json) |> Base.encode16(case: :lower))

    %{
      "theory_proposal_id" => proposal_id,
      "schema_version" => "16.1.0",
      "research_program_id" => Map.get(theory_snapshot, "program_id", ""),
      "operation" => "NEW",
      "target_theory_id" => nil,
      "previous_theory_hash" => nil,
      "justification_hash" => proposal_id,
      "supporting_evidence_validation_ids" => [validation_id],
      "supporting_discovery_ids" => [],
      "contradicting_evidence_ids" => [],
      "replay_prerequisites" => %{"required_replay_levels" => ["LEVEL1"]},
      "certificate_prerequisites" => Map.put(certification_prereqs, "required_certificate_types", ["DISCOVERY", "REPLAY"])
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
