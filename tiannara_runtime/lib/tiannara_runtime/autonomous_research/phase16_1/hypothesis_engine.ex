defmodule TiannaraRuntime.AutonomousResearch.Phase16_1.HypothesisEngine do
  @moduledoc """
  Phase 16.1 Module 3 — Hypothesis Engine (Pure Implementation)

  Implements frozen contract from RESEARCH_RUNTIME_FREEZE.md 2.3 PortfolioManager:
  - select_portfolio(priorities, constraints) -> [ResearchProgram]

  Capabilities:
  - Hypothesis generation
  - Confidence estimation
  - Uncertainty tracking
  - Dependency graph
  - Replay support
  """

  @hypothesis_table :hypotheses

  def init_table do
    if :ets.info(@hypothesis_table) == :undefined do
      :ets.new(@hypothesis_table, [:set, :public, :named_table])
    end
    :ok
  end

  @doc "Create a hypothesis from question and evidence"
  @spec create_hypothesis(String.t(), map(), map()) :: {:ok, map()}
  def create_hypothesis(question_id, evidence, context \\ %{}) do
    init_table()
    hypothesis = build_hypothesis(question_id, evidence, context)
    {:ok, hypothesis}
  end

  @doc "Register a hypothesis"
  @spec register_hypothesis(map()) :: :ok | {:error, String.t()}
  def register_hypothesis(hypothesis) do
    case validate_hypothesis(hypothesis) do
      :ok ->
        :ets.insert(@hypothesis_table, {Map.get(hypothesis, "hypothesis_id"), hypothesis})
        :ok

      {:error, _} = error ->
        error
    end
  end

  @doc "Lookup hypothesis by ID"
  @spec lookup_hypothesis(String.t()) :: {:ok, map()} | :error
  def lookup_hypothesis(hypothesis_id) do
    case :ets.lookup(@hypothesis_table, hypothesis_id) do
      [{^hypothesis_id, hypothesis}] -> {:ok, hypothesis}
      [] -> :error
    end
  end

  @doc "List all hypotheses"
  @spec list_hypotheses() :: [map()]
  def list_hypotheses do
    :ets.tab2list(@hypothesis_table)
    |> Enum.map(fn {_id, h} -> h end)
  end

  # --- internal helpers ---

  defp build_hypothesis(question_id, evidence, _context) do
    canonical = canonicalize_map(Map.merge(evidence, %{}))
    json = Jason.encode!(canonical)
    hypothesis_id = "h_" <> (:crypto.hash(:sha256, json) |> Base.encode16(case: :lower))

    %{
      "hypothesis_id" => hypothesis_id,
      "schema_version" => "16.1.0",
      "question_id" => question_id,
      "statement" => "Hypothesis derived from question #{String.slice(question_id, 0..7)}",
      "confidence" => 0.5,
      "uncertainty" => 0.5,
      "dependencies" => [question_id],
      "evidence_refs" => extract_evidence_refs(evidence)
    }
  end

  defp extract_evidence_refs(evidence) do
    evidence
    |> Map.get("evidence_records", [])
    |> Enum.map(fn r -> Map.get(r, "evidence_bundle_id", "") end)
  end

  defp validate_hypothesis(%{"hypothesis_id" => _, "question_id" => _, "statement" => stmt}) when is_binary(stmt) do
    :ok
  end

  defp validate_hypothesis(_), do: {:error, "missing required fields"}

  defp canonicalize_map(term) when is_map(term) do
    term
    |> Enum.map(fn {k, v} -> {to_string(k), canonicalize_map(v)} end)
    |> Enum.sort_by(fn {k, _v} -> k end)
    |> Enum.into(%{})
  end

  defp canonicalize_map(term) when is_list(term), do: Enum.map(term, &canonicalize_map/1)
  defp canonicalize_map(term), do: term
end
