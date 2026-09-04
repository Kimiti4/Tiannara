defmodule Tiannara.Discovery.HypothesisGenerator do
  alias Tiannara.Discovery.Domain.{KnowledgeGap, HypothesisSpec}

  def generate(%KnowledgeGap{} = gap, n \\ 3) do
    templates = get_templates(gap.domain)
    templates
    |> Enum.take(n)
    |> Enum.with_index()
    |> Enum.map(fn {template_fn, _idx} ->
      hypothesis = template_fn.(gap)
      %{hypothesis | prior: 1.0 / min(length(templates), Enum.min([n, 4]))}
    end)
  end

  defp get_templates(:epistemic_consistency) do
    [
      fn g -> HypothesisSpec.new(%{id: hyp_id(), description: "Systematic bias in #{g.description}", statement: "Systematic bias in #{g.description}", domain: g.domain, prior: 0.0, confidence: 0.0, evidence: [], predictions: [], falsifiable: true, status: :proposed}) end,
      fn g -> HypothesisSpec.new(%{id: hyp_id(), description: "Measurement error in #{g.description}", statement: "Measurement error in #{g.description}", domain: g.domain, prior: 0.0, confidence: 0.0, evidence: [], predictions: [], falsifiable: true, status: :proposed}) end,
      fn g -> HypothesisSpec.new(%{id: hyp_id(), description: "Genuine anomaly in #{g.description}", statement: "Genuine anomaly in #{g.description}", domain: g.domain, prior: 0.0, confidence: 0.0, evidence: [], predictions: [], falsifiable: true, status: :proposed}) end,
      fn g -> HypothesisSpec.new(%{id: hyp_id(), description: "Causal confound in #{g.description}", statement: "Causal confound in #{g.description}", domain: g.domain, prior: 0.0, confidence: 0.0, evidence: [], predictions: [], falsifiable: true, status: :proposed}) end,
    ]
  end

  defp get_templates(:evidence_quality) do
    [
      fn g -> HypothesisSpec.new(%{id: hyp_id(), description: "Underpowered analysis of #{g.description}", statement: "Underpowered analysis of #{g.description}", domain: g.domain, prior: 0.0, confidence: 0.0, evidence: [], predictions: [], falsifiable: true, status: :proposed}) end,
      fn g -> HypothesisSpec.new(%{id: hyp_id(), description: "Confounding variable in #{g.description}", statement: "Confounding variable in #{g.description}", domain: g.domain, prior: 0.0, confidence: 0.0, evidence: [], predictions: [], falsifiable: true, status: :proposed}) end,
      fn g -> HypothesisSpec.new(%{id: hyp_id(), description: "P-hacking in #{g.description}", statement: "P-hacking in #{g.description}", domain: g.domain, prior: 0.0, confidence: 0.0, evidence: [], predictions: [], falsifiable: true, status: :proposed}) end,
    ]
  end

  defp get_templates(:knowledge_freshness) do
    [
      fn g -> HypothesisSpec.new(%{id: hyp_id(), description: "#{g.description} is stale; new evidence may exist", statement: "#{g.description} is stale; new evidence may exist", domain: g.domain, prior: 0.0, confidence: 0.0, evidence: [], predictions: [], falsifiable: true, status: :proposed}) end,
      fn g -> HypothesisSpec.new(%{id: hyp_id(), description: "#{g.description} has been refuted by recent studies", statement: "#{g.description} has been refuted by recent studies", domain: g.domain, prior: 0.0, confidence: 0.0, evidence: [], predictions: [], falsifiable: true, status: :proposed}) end,
    ]
  end

  defp get_templates(:provenance) do
    [
      fn g -> HypothesisSpec.new(%{id: hyp_id(), description: "Provenance chain broken for #{g.description}", statement: "Provenance chain broken for #{g.description}", domain: g.domain, prior: 0.0, confidence: 0.0, evidence: [], predictions: [], falsifiable: true, status: :proposed}) end,
      fn g -> HypothesisSpec.new(%{id: hyp_id(), description: "Source integrity compromised for #{g.description}", statement: "Source integrity compromised for #{g.description}", domain: g.domain, prior: 0.0, confidence: 0.0, evidence: [], predictions: [], falsifiable: true, status: :proposed}) end,
    ]
  end

  defp get_templates(:general) do
    [
      fn g -> HypothesisSpec.new(%{id: hyp_id(), description: "Alternative explanation for #{g.description}", statement: "Alternative explanation for #{g.description}", domain: g.domain, prior: 0.0, confidence: 0.0, evidence: [], predictions: [], falsifiable: true, status: :proposed}) end,
      fn g -> HypothesisSpec.new(%{id: hyp_id(), description: "Null hypothesis for #{g.description}", statement: "Null hypothesis for #{g.description}", domain: g.domain, prior: 0.0, confidence: 0.0, evidence: [], predictions: [], falsifiable: true, status: :proposed}) end,
      fn g -> HypothesisSpec.new(%{id: hyp_id(), description: "Composite hypothesis for #{g.description}", statement: "Composite hypothesis for #{g.description}", domain: g.domain, prior: 0.0, confidence: 0.0, evidence: [], predictions: [], falsifiable: true, status: :proposed}) end,
    ]
  end

  defp get_templates(_), do: get_templates(:general)

  defp hyp_id, do: "hyp_#{:crypto.strong_rand_bytes(6) |> Base.encode16(case: :lower)}"
end
