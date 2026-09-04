defmodule Tiannara.World.BeliefState do
  defstruct [
    :confidence, :uncertainty, :belief,
    :evidence_strength, :evidence_quality,
    :posterior_probability, :prior_probability,
    :evidence_count, :last_updated, :revision_history
  ]

  @type t :: %__MODULE__{
    confidence: float(), uncertainty: float(), belief: float(),
    evidence_strength: float(), evidence_quality: float(),
    posterior_probability: float(), prior_probability: float(),
    evidence_count: non_neg_integer(),
    last_updated: DateTime.t(), revision_history: [map()]
  }

  def new(prior, evidence_strength, evidence_quality) do
    posterior = (prior + evidence_strength * evidence_quality) / 2.0
    confidence = posterior
    uncertainty = 1.0 - confidence

    %__MODULE__{
      confidence: clamp(confidence),
      uncertainty: clamp(uncertainty),
      belief: clamp(posterior),
      evidence_strength: clamp(evidence_strength),
      evidence_quality: clamp(evidence_quality),
      posterior_probability: clamp(posterior),
      prior_probability: clamp(prior),
      evidence_count: 1,
      last_updated: DateTime.utc_now(),
      revision_history: [%{
        action: :initial_belief, prior: prior, posterior: posterior,
        at: DateTime.utc_now()
      }]
    }
  end

  def update(%__MODULE__{} = state, new_strength, new_quality) do
    weighted_evidence = new_strength * new_quality
    new_posterior = (state.posterior_probability * state.evidence_count + weighted_evidence) / (state.evidence_count + 1)
    new_confidence = new_posterior

    revision = %{
      action: :evidence_fusion, prior_posterior: state.posterior_probability,
      new_evidence_strength: new_strength, new_evidence_quality: new_quality,
      new_posterior: new_posterior, at: DateTime.utc_now()
    }

    %{state |
      confidence: clamp(new_confidence),
      uncertainty: clamp(1.0 - new_confidence),
      belief: clamp(new_posterior),
      evidence_strength: clamp((state.evidence_strength * state.evidence_count + new_strength) / (state.evidence_count + 1)),
      evidence_quality: clamp((state.evidence_quality * state.evidence_count + new_quality) / (state.evidence_count + 1)),
      posterior_probability: clamp(new_posterior),
      evidence_count: state.evidence_count + 1,
      last_updated: DateTime.utc_now(),
      revision_history: state.revision_history ++ [revision]
    }
  end

  def decay(%__MODULE__{} = state, days_stale) do
    decay_factor = :math.exp(-0.01 * days_stale)
    new_confidence = state.confidence * decay_factor

    revision = %{
      action: :temporal_decay, days_stale: days_stale,
      decay_factor: decay_factor, new_confidence: new_confidence,
      at: DateTime.utc_now()
    }

    %{state |
      confidence: clamp(new_confidence),
      uncertainty: clamp(1.0 - new_confidence),
      belief: clamp(new_confidence),
      last_updated: DateTime.utc_now(),
      revision_history: state.revision_history ++ [revision]
    }
  end

  def promotion_ready?(%__MODULE__{} = state, min_confidence \\ 0.8, min_evidence \\ 3) do
    state.confidence >= min_confidence and
    state.evidence_count >= min_evidence and
    state.evidence_quality >= 0.7
  end

  def explain(%__MODULE__{} = state) do
    """
    Belief State:
      Confidence: #{Float.round(state.confidence, 3)}
      Uncertainty: #{Float.round(state.uncertainty, 3)}
      Evidence Strength: #{Float.round(state.evidence_strength, 3)}
      Evidence Quality: #{Float.round(state.evidence_quality, 3)}
      Evidence Count: #{state.evidence_count}
      Prior -> Posterior: #{Float.round(state.prior_probability, 3)} -> #{Float.round(state.posterior_probability, 3)}
      Last Updated: #{state.last_updated}
      Revisions: #{length(state.revision_history)}
    """
  end

  defp clamp(value) when value < 0.0, do: 0.0
  defp clamp(value) when value > 1.0, do: 1.0
  defp clamp(value), do: value
end
