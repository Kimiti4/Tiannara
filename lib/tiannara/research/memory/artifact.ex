defmodule Tiannara.Research.Memory.Artifact do
  @moduledoc """
  The Research Memory Contract: a typed ResearchArtifact carrying the full
  epistemic state between discovery and research. Prevents the Research
  Director from becoming an opaque GenServer with arbitrary maps.

  Aligns with the Memory Philosophy ladder:
      Data → Information → Knowledge → Patterns → Models → Principles →
      Generalized Understanding → Engineering Insight → Scientific Discovery

  Promotion up the ladder is EVIDENCE-GATED ("Evidence Before Confidence"): 
  higher stages require evidence, sufficient confidence, and no unresolved
  contradictions. Memory exists to improve reasoning, not merely store data.

  Constitutional basis: Memory Philosophy, Explainability, "Every architectural
  decision should remain traceable", "Distinguish clearly between facts,
  evidence, assumptions, hypotheses, confidence levels, unknowns."
  """

  @enforce_keys [:id, :memory_stage]
  defstruct [
    :id,
    :memory_stage,
    :content,
    lineage: [],
    provenance: [],
    observations: [],
    hypotheses: [],
    predictions: [],
    experiments: [],
    evidence: [],
    contradictions: [],
    falsifiers: [],
    conclusions: [],
    confidence: 0.0,
    uncertainty: 1.0,
    constitutional_status: %{verified: false, checks: []},
    created_at: nil,
    updated_at: nil
  ]

  @type t :: %__MODULE__{}

  @memory_stages [:data, :information, :knowledge, :patterns, :models,
                  :principles, :generalized_understanding, :engineering_insight,
                  :scientific_discovery]


  def memory_stages, do: @memory_stages

  def new(id, memory_stage, content, opts \\ []) do
    now = System.system_time(:second)

    base = %__MODULE__{
      id: id,
      memory_stage: memory_stage,
      content: content,
      created_at: now,
      updated_at: now
    }

    Enum.reduce(opts, base, fn {k, v}, acc ->
      if Map.has_key?(acc, k), do: Map.put(acc, k, v), else: acc
    end)
  end

  @doc """
  Promote an artifact up the memory ladder. Enforces: upward-only movement,
  evidence for knowledge-and-above, no unresolved contradictions for
  principles-and-above, and a stage-appropriate confidence threshold.
  """
  def promote(%__MODULE__{} = artifact, target_stage) do
    current_idx = Enum.find_index(@memory_stages, &(&1 == artifact.memory_stage))
    target_idx = Enum.find_index(@memory_stages, &(&1 == target_stage))

    cond do
      target_idx == nil ->
        {:error, :unknown_stage}

      target_idx <= current_idx ->
        {:error, :must_promote_upward}

      true ->
        validate_promotion(artifact, target_stage, target_idx)
    end
  end

  defp validate_promotion(artifact, target_stage, target_idx) do
    with :ok <- check_evidence(artifact, target_idx),
         :ok <- check_contradictions(artifact, target_idx),
         :ok <- check_confidence(artifact, target_idx) do
      {:ok,
       %{artifact
         | memory_stage: target_stage,
           updated_at: System.system_time(:second),
           lineage: artifact.lineage ++ [artifact.memory_stage]}}
    end
  end

  defp check_evidence(artifact, target_idx) do
    if target_idx >= 2 and length(artifact.evidence) == 0,
      do: {:error, :insufficient_evidence},
      else: :ok
  end

  defp check_contradictions(artifact, target_idx) do
    if target_idx >= 5 and length(artifact.contradictions) > 0,
      do: {:error, :unresolved_contradictions},
      else: :ok
  end

  defp check_confidence(artifact, target_idx) do
    required = Enum.at(confidence_thresholds(), target_idx)

    if artifact.confidence >= required,
      do: :ok,
      else: {:error, {:insufficient_confidence, artifact.confidence, required}}
  end

  defp confidence_thresholds do
    Application.get_env(:tiannara, :memory_confidence_thresholds,
      [0.0, 0.1, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9])
  end
end