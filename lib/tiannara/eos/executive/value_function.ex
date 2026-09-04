defmodule Tiannara.EOS.EpistemicExecutive.ValueFunction do
  @moduledoc """
  Constitutional Clause 21, enforced: the value function is defined
  ONLY over quality metrics. Count-based terms are structurally absent.

  Value(state) = w1 · explanatory_power
               + w2 · prediction_coverage
               + w3 · compression_efficiency (KCR)
               + w4 · verification_confidence
               − w5 · epistemic_debt

  The weights themselves are governed artifacts — versioned, reviewable,
  and stored in the PrincipleRegistry. The Executive cannot reweight itself.
  """

  @type state :: %{
          explanatory_power: float,
          prediction_coverage: float,
          compression_efficiency: float,
          verification_confidence: float,
          epistemic_debt: float
        }

  def evaluate(state, weights) do
    weights.explanatory_power * state.explanatory_power
    + weights.prediction_coverage * state.prediction_coverage
    + weights.compression_efficiency * state.compression_efficiency
    + weights.verification_confidence * state.verification_confidence
    - weights.epistemic_debt * state.epistemic_debt
  end
end
