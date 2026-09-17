defmodule TiannaraRuntime.OS.Governance.Certification.ReadinessIndexReport do
  @moduledoc """
  ReadinessIndexReport — Computes the 12-dimension Constitutional Readiness Index
  from evidence produced by the 30 certification campaigns.

  ## Dimensions

  | Dimension | Weight |
  |---|---|
  | Scientific Capability | 15% |
  | Engineering Capability | 10% |
  | Simulation Capability | 10% |
  | Replay Integrity | 10% |
  | Archaeology Completeness | 10% |
  | Knowledge Integrity | 10% |
  | Optimization Quality | 5% |
  | Evolution Stability | 5% |
  | Civilization Intelligence | 10% |
  | Planetary Readiness | 5% |
  | Autonomous Research | 5% |
  | Constitutional Compliance | 5% |

  ## Usage

      evidence_chain = [...] # from CampaignOrchestrator
      report = ReadinessIndexReport.compute(evidence_chain)
  """

  alias TiannaraRuntime.OS.Governance.Certification.CampaignAdapter

  @type dimension :: :scientific_capability | :engineering_capability | :simulation_capability |
                     :replay_integrity | :archaeology_completeness | :knowledge_integrity |
                     :optimization_quality | :evolution_stability | :civilization_intelligence |
                     :planetary_readiness | :autonomous_research | :constitutional_compliance

  @type dimension_score :: %{
    dimension: dimension(),
    weight: float(),
    score: float(),
    evidence_count: integer(),
    status: :pass | :fail | :partial
  }

  @type report :: %{
    report_id: String.t(),
    computed_at: integer(),
    dimensions: [dimension_score()],
    overall_score: float(),
    overall_status: :certified_for_planetary_intelligence | :certified_with_conditions | :further_development_required,
    campaign_count: integer(),
    passed_count: integer(),
    failed_count: integer()
  }

  @weights %{
    scientific_capability: 0.15,
    engineering_capability: 0.10,
    simulation_capability: 0.10,
    replay_integrity: 0.10,
    archaeology_completeness: 0.10,
    knowledge_integrity: 0.10,
    optimization_quality: 0.05,
    evolution_stability: 0.05,
    civilization_intelligence: 0.10,
    planetary_readiness: 0.05,
    autonomous_research: 0.05,
    constitutional_compliance: 0.05
  }

  @doc """
  Computes the readiness index report from a chain of campaign evidence.
  """
  @spec compute([CampaignAdapter.evidence()]) :: report()
  def compute(evidence_chain) do
    passed = Enum.count(evidence_chain, fn e -> e.status == :pass end)
    failed = Enum.count(evidence_chain, fn e -> e.status == :fail end)
    total = length(evidence_chain)

    dimensions = compute_dimensions(evidence_chain)
    overall = compute_overall_score(dimensions)

    status = cond do
      overall >= 0.90 and failed == 0 -> :certified_for_planetary_intelligence
      overall >= 0.75 -> :certified_with_conditions
      true -> :further_development_required
    end

    %{
      report_id: generate_report_id(),
      computed_at: :erlang.unique_integer([:positive]),
      dimensions: dimensions,
      overall_score: overall,
      overall_status: status,
      campaign_count: total,
      passed_count: passed,
      failed_count: failed
    }
  end

  @doc """
  Returns the weight for a given dimension.
  """
  @spec weight(dimension()) :: float()
  def weight(dim), do: Map.get(@weights, dim, 0.0)

  # ── Internal ─────────────────────────────────────────────────

  defp compute_dimensions(evidence_chain) do
    for {dim, weight} <- @weights do
      scores = scores_for_dimension(dim, evidence_chain)
      score = if scores == [], do: 0.0, else: Enum.sum(scores) / length(scores)
      status = if score >= 0.90, do: :pass, else: (if score >= 0.75, do: :partial, else: :fail)

      %{
        dimension: dim,
        weight: weight,
        score: score,
        evidence_count: length(scores),
        status: status
      }
    end
  end

  defp scores_for_dimension(:scientific_capability, evidence) do
    Enum.filter(evidence, fn e -> e.domain in [:scientific_integrity] end)
    |> Enum.map(fn e -> if e.status == :pass, do: 1.0, else: 0.0 end)
  end

  defp scores_for_dimension(:engineering_capability, evidence) do
    Enum.filter(evidence, fn e -> e.campaign_id in ["CC-014", "CC-020"] end)
    |> Enum.map(fn e -> if e.status == :pass, do: 1.0, else: 0.0 end)
  end

  defp scores_for_dimension(:simulation_capability, evidence) do
    Enum.filter(evidence, fn e -> e.campaign_id in ["CC-008", "CC-021", "CC-025"] end)
    |> Enum.map(fn e -> if e.status == :pass, do: 1.0, else: 0.0 end)
  end

  defp scores_for_dimension(:replay_integrity, evidence) do
    Enum.filter(evidence, fn e -> e.campaign_id in ["CC-003", "CC-007", "CC-015", "CC-022", "CC-029"] end)
    |> Enum.map(fn e -> if e.status == :pass, do: 1.0, else: 0.0 end)
  end

  defp scores_for_dimension(:archaeology_completeness, evidence) do
    Enum.filter(evidence, fn e -> e.campaign_id in ["CC-002", "CC-009", "CC-015", "CC-022"] end)
    |> Enum.map(fn e -> if e.status == :pass, do: 1.0, else: 0.0 end)
  end

  defp scores_for_dimension(:knowledge_integrity, evidence) do
    Enum.filter(evidence, fn e -> e.domain in [:scientific_integrity] end)
    |> Enum.map(fn e -> if e.status == :pass, do: 1.0, else: 0.0 end)
  end

  defp scores_for_dimension(:optimization_quality, evidence) do
    Enum.filter(evidence, fn e -> e.campaign_id in ["CC-013", "CC-023"] end)
    |> Enum.map(fn e -> if e.status == :pass, do: 1.0, else: 0.0 end)
  end

  defp scores_for_dimension(:evolution_stability, evidence) do
    Enum.filter(evidence, fn e -> e.domain in [:evolution_integrity] end)
    |> Enum.map(fn e -> if e.status == :pass, do: 1.0, else: 0.0 end)
  end

  defp scores_for_dimension(:civilization_intelligence, evidence) do
    Enum.filter(evidence, fn e -> e.domain in [:civilizational_readiness] end)
    |> Enum.map(fn e -> if e.status == :pass, do: 1.0, else: 0.0 end)
  end

  defp scores_for_dimension(:planetary_readiness, evidence) do
    Enum.filter(evidence, fn e -> e.domain in [:planetary_readiness] end)
    |> Enum.map(fn e -> if e.status == :pass, do: 1.0, else: 0.0 end)
  end

  defp scores_for_dimension(:autonomous_research, evidence) do
    Enum.filter(evidence, fn e -> e.campaign_id in ["CC-013", "CC-017", "CC-019"] end)
    |> Enum.map(fn e -> if e.status == :pass, do: 1.0, else: 0.0 end)
  end

  defp scores_for_dimension(:constitutional_compliance, evidence) do
    Enum.filter(evidence, fn e -> e.domain in [:constitutional_integrity] end)
    |> Enum.map(fn e -> if e.status == :pass, do: 1.0, else: 0.0 end)
  end

  defp compute_overall_score(dimensions) do
    Enum.reduce(dimensions, 0.0, fn dim, acc ->
      acc + dim.score * dim.weight
    end)
  end

  defp generate_report_id() do
    "cri_" <> (:crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower))
  end
end
