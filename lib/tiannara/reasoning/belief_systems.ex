defmodule Tiannara.Reasoning.BeliefSystems do
  @moduledoc """
  Manages belief states and Bayesian updates.
  Uses Foundations for the math, but maintains the cognitive state of beliefs.
  """
  alias Tiannara.Foundations.InformationTheory
  alias Tiannara.Math.Probability

  @doc "Updates a belief state given new evidence."
  def update_belief(%{prior: prior, model: model} = belief_state, evidence) do
    likelihood = model.likelihood_fn(evidence)
    evidence_prob = marginal_likelihood(prior, model, evidence)
    {:ok, posterior} = Probability.bayes_update(prior, likelihood, evidence_prob)

    prior_entropy = InformationTheory.shannon_entropy(Map.values(prior))
    posterior_entropy = InformationTheory.shannon_entropy(Map.values(posterior))
    info_gain = prior_entropy - posterior_entropy

    %{
      belief_state
      | prior: posterior,
        last_info_gain: info_gain,
        confidence: Enum.max(Map.values(posterior))
    }
  end

  defp marginal_likelihood(prior, model, evidence) do
    prior
    |> Enum.reduce(0.0, fn {_hyp, prob}, acc ->
      acc + prob * model.likelihood_fn(evidence)
    end)
  end
end
