defmodule Tiannara.HAI.ExplainabilityBridge do
  alias Tiannara.HAI.Domain.Explanation
  alias Tiannara.Discovery.Discovery
  alias Tiannara.Engineering.Domain.EngineeringDesign
  alias Tiannara.Simulation.Domain.ImpactAssessment

  @spec explain_discovery(Discovery.t()) :: Explanation.t()
  def explain_discovery(%Discovery{} = disc) do
    Explanation.new(%{
      subject_id: disc.id, subject_type: :discovery,
      summary: build_discovery_summary(disc),
      reasoning_chain: build_discovery_reasoning_chain(disc),
      evidence: build_discovery_evidence(disc),
      confidence: disc.confidence, uncertainty: disc.uncertainty,
      assumptions: build_discovery_assumptions(disc),
      alternatives_considered: build_alternatives(disc),
      limitations: build_discovery_limitations(disc)
    })
  end

  @spec explain_design(EngineeringDesign.t()) :: Explanation.t()
  def explain_design(%EngineeringDesign{} = design) do
    Explanation.new(%{
      subject_id: design.id, subject_type: :engineering_design,
      summary: "Engineering design '#{design.name}' derived from principle: #{design.description}",
      reasoning_chain: [
        "Source principle identified with confidence #{design.feasibility}",
        "Design approach: #{Map.get(design.architecture, :pattern, :unknown)}",
        "Components: #{Enum.map_join(design.components, ", ", & &1.name)}",
        "Safety score: #{design.safety_score}",
        "Risk level: #{design.risk}"
      ],
      evidence: [%{type: :source_principle, insight_id: design.insight_id}],
      confidence: design.feasibility, uncertainty: 1.0 - design.feasibility,
      assumptions: ["Source principle remains valid",
        "Resource estimates are accurate within 50%", "No external dependencies change"],
      alternatives_considered: [],
      limitations: ["Design has not been physically implemented",
        "Performance estimates are theoretical", "Integration with existing systems not verified"]
    })
  end

  @spec explain_impact(ImpactAssessment.t()) :: Explanation.t()
  def explain_impact(%ImpactAssessment{} = assessment) do
    Explanation.new(%{
      subject_id: assessment.id, subject_type: :impact_assessment,
      summary: "Impact assessment for design #{assessment.design_id}: recommendation = #{assessment.recommendation}",
      reasoning_chain: [
        "Scientific impact: #{Float.round(assessment.scientific_impact, 2)}",
        "Engineering impact: #{Float.round(assessment.engineering_impact, 2)}",
        "Civilizational impact: #{Float.round(assessment.civilizational_impact, 2)}",
        "Sustainability impact: #{Float.round(assessment.sustainability_impact, 2)}",
        "Safety impact: #{Float.round(assessment.safety_impact, 2)}",
        "Economic impact: #{Float.round(assessment.economic_impact, 2)}",
        "Composite score: #{Float.round(assessment.composite_score, 3)}",
        "Recommendation: #{assessment.recommendation}"
      ],
      evidence: Enum.map(assessment.horizon_forecasts, fn f ->
        %{type: :horizon_forecast, years: f.horizon_years, confidence: f.confidence}
      end),
      confidence: assessment.confidence, uncertainty: assessment.uncertainty,
      assumptions: ["Current trajectory continues",
        "No paradigm-shifting discoveries intervene", "Resource availability remains stable"],
      alternatives_considered: [],
      limitations: ["Long-term forecasts (50-100 years) have high uncertainty",
        "Civilizational impact is difficult to quantify", "Black swan events are not modeled"]
    })
  end

  defp build_discovery_summary(%Discovery{} = disc) do
    status_text = case disc.status do
      :completed -> "completed"
      :abandoned -> "abandoned"
      _ -> "in progress (#{disc.status})"
    end
    "Discovery #{disc.id}: #{disc.question} [#{status_text}, confidence: #{Float.round(disc.confidence, 2)}]"
  end

  defp build_discovery_reasoning_chain(%Discovery{} = disc) do
    chain = ["1. Knowledge gap detected: #{disc.gap && disc.gap.description}"]
    chain = chain ++ ["2. #{length(disc.hypotheses)} competing hypotheses generated"]
    chain = chain ++ Enum.map(disc.hypotheses, fn hyp ->
      "   - #{hyp.statement} (prior: #{Float.round(hyp.prior || 0.5, 2)}, EIG: #{Float.round(hyp.expected_information_gain || 0.5, 2)})"
    end)
    chain = chain ++ ["3. #{length(disc.predictions)} falsifiable predictions derived"]
    chain = chain ++ ["4. #{length(disc.experiments)} experiments designed"]
    chain = chain ++ ["5. #{length(disc.evidence)} evidence items collected"]
    if disc.conclusion do
      chain ++ ["6. Conclusion: #{Map.get(disc.conclusion, :summary, "reached")}"]
    else
      chain ++ ["6. Conclusion: pending"]
    end
  end

  defp build_discovery_evidence(%Discovery{} = disc) do
    Enum.map(disc.evidence, fn result ->
      %{type: :experimental_result, experiment_id: result.experiment_id,
        outcome: result.outcome, confidence_delta: result.confidence_delta,
        evidence_count: length(result.evidence)}
    end)
  end

  defp build_discovery_assumptions(%Discovery{} = disc) do
    base = ["The knowledge gap is genuine (not an artifact of incomplete data)",
            "The experimental methodology is sound", "Evidence collection is unbiased"]
    if disc.gap && disc.gap.source == :contradiction do
      base ++ ["The contradiction is not due to measurement error"]
    else
      base
    end
  end

  defp build_alternatives(%Discovery{} = disc) do
    Enum.map(disc.hypotheses, fn hyp ->
      %{hypothesis_id: hyp.id, statement: hyp.statement,
        prior: hyp.prior, status: if(hyp.prior > 0.3, do: :competitive, else: :unlikely)}
    end)
  end

  defp build_discovery_limitations(%Discovery{} = disc) do
    (if length(disc.evidence) < 3,
      do: ["Limited evidence (#{length(disc.evidence)} items) — confidence may be overstated"], else: []) ++
    (if disc.uncertainty > 0.5,
      do: ["High uncertainty (#{Float.round(disc.uncertainty, 2)}) — further investigation recommended"], else: []) ++
    (if disc.status == :abandoned,
      do: ["Discovery was abandoned — conclusion may be incomplete"], else: [])
  end
end
