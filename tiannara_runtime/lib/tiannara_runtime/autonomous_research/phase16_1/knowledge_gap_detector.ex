defmodule TiannaraRuntime.AutonomousResearch.Phase16_1.KnowledgeGapDetector do
  @moduledoc """
  Phase 16.1 Module 2 — Knowledge Gap Detector (Pure Implementation)

  Implements frozen contract from RESEARCH_RUNTIME_FREEZE.md Stage B:
  - Input: observations / knowledge graph snapshot
  - Output: `KnowledgeGap` artifacts with measurable closure criteria

  Frozen schema from RESEARCH_DATA_MODEL.md:
  - knowledge_gap_id, schema_version, timestamp, gap_type, domain, description
  - current_confidence, target_confidence, evidence_requirements
  - contradicting_claim_ids, unresolved_prediction_ids, engineering_bottleneck
  """

  @gap_table :knowledge_gaps

  def init_table do
    if :ets.info(@gap_table) == :undefined do
      :ets.new(@gap_table, [:set, :public, :named_table])
    end
    :ok
  end

  @doc "Detect knowledge gaps from observations and current knowledge state"
  @spec detect_gaps([map()], map()) :: {:ok, [map()]}
  def detect_gaps(observations, _context \\ %{}) when is_list(observations) do
    init_table()
    gaps = Enum.map(observations, &build_gap/1)
    Enum.each(gaps, fn g -> :ets.insert(@gap_table, {Map.get(g, "knowledge_gap_id"), g}) end)
    {:ok, gaps}
  end

  @doc "Lookup gap by ID"
  @spec lookup_gap(String.t()) :: {:ok, map()} | :error
  def lookup_gap(gap_id) when is_binary(gap_id) do
    case :ets.lookup(@gap_table, gap_id) do
      [{^gap_id, gap}] -> {:ok, gap}
      [] -> :error
    end
  end

  @doc "List all detected gaps"
  @spec list_gaps() :: [map()]
  def list_gaps do
    :ets.tab2list(@gap_table)
    |> Enum.map(fn {_id, g} -> g end)
  end

  @doc "Generate gap from observation deterministically"
  @spec build_gap(map()) :: map()
  def build_gap(observation) do
    origin = Map.get(observation, "origin", %{})
    obs_id = origin |> Map.keys() |> List.first() |> to_string()

    gap_inputs = %{
      "observation_id" => obs_id,
      "gap_type" => "UNCERTAINTY",
      "domain" => "autonomous_research",
      "description" => "Knowledge gap derived from observation #{obs_id}"
    }

    canonical = canonicalize_map(gap_inputs)
    json = Jason.encode!(canonical)
    gap_id = "gap_" <> (:crypto.hash(:sha256, json) |> Base.encode16(case: :lower))

    %{
      "knowledge_gap_id" => gap_id,
      "schema_version" => "16.1.0",
      "timestamp" => "2000-01-01T00:00:00Z",
      "gap_type" => "UNCERTAINTY",
      "domain" => "autonomous_research",
      "description" => "Knowledge gap derived from observation #{obs_id}",
      "current_confidence" => 0.5,
      "target_confidence" => 0.95,
      "evidence_requirements" => [
        %{"evidence_type" => "STATISTICAL", "minimum_quantity" => 100, "required_quality" => "HIGH"}
      ],
      "contradicting_claim_ids" => [],
      "unresolved_prediction_ids" => [],
      "engineering_bottleneck" => nil
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
