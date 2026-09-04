defmodule Tiannara.EOS.Promotion.Policy do
  @moduledoc """
  Behaviour for stage-transition policies.
  Policies are versioned artifacts. Every promotion/demotion records
  the policy version that authorized it.
  """

  @type artifact :: map()
  @type evidence :: %{required(atom) => any}
  @type decision ::
          {:promote, reasons :: [String.t()]}
          | {:hold, missing :: [String.t()]}
          | {:demote, reasons :: [String.t()]}

  @callback evaluate(artifact, evidence) :: decision
  @callback policy_version() :: String.t()
end

defmodule Tiannara.EOS.Promotion.HypothesisToTheory do
  @moduledoc """
  Promotion policy: Hypothesis → Theory.
  Version 1.2.0. Changes to thresholds require a new policy version
  and governance review.
  """

  @behaviour Tiannara.EOS.Promotion.Policy

  @version "1.2.0"

  @criteria %{
    reproducibility_min: 0.7,
    prediction_accuracy_min: 0.65,
    min_resolved_predictions: 8,
    requires_competition_eval: true,
    requires_falsification_conditions: true
  }

  @impl true
  def policy_version, do: @version

  @impl true
  def evaluate(artifact, evidence) do
    checks = [
      check_reproducibility(artifact, evidence),
      check_prediction_accuracy(artifact, evidence),
      check_prediction_count(artifact, evidence),
      check_competition(artifact, evidence),
      check_falsification(artifact)
    ]

    failures = Enum.filter(checks, &match?({:fail, _}, &1))

    cond do
      failures == [] ->
        {:promote, Enum.map(checks, fn {:pass, r} -> r end)}

      true ->
        {:hold, Enum.map(failures, fn {:fail, r} -> r end)}
    end
  end

  defp check_reproducibility(artifact, _evidence) do
    v = Map.get(artifact, :reproducibility, 0.0)
    if v >= @criteria.reproducibility_min,
      do: {:pass, "reproducibility #{v} ≥ #{@criteria.reproducibility_min}"},
      else: {:fail, "reproducibility #{v} < #{@criteria.reproducibility_min}"}
  end

  defp check_prediction_accuracy(artifact, _evidence) do
    v = artifact.confidence_vector.prediction_accuracy
    if v >= @criteria.prediction_accuracy_min,
      do: {:pass, "prediction accuracy #{v} ≥ #{@criteria.prediction_accuracy_min}"},
      else: {:fail, "prediction accuracy #{v} < #{@criteria.prediction_accuracy_min}"}
  end

  defp check_prediction_count(_artifact, evidence) do
    n = evidence[:resolved_prediction_count] || 0
    if n >= @criteria.min_resolved_predictions,
      do: {:pass, "#{n} resolved predictions ≥ #{@criteria.min_resolved_predictions}"},
      else: {:fail, "only #{n} resolved predictions, need #{@criteria.min_resolved_predictions}"}
  end

  defp check_competition(artifact, _evidence) do
    if artifact.alternative_explanations != [] and competition_evaluated?(artifact),
      do: {:pass, "competing explanations evaluated"},
      else: {:fail, "competing explanations not evaluated via tournament or review"}
  end

  defp check_falsification(artifact) do
    if artifact.falsification_conditions != [],
      do: {:pass, "falsification conditions specified"},
      else: {:fail, "falsification conditions empty — not a scientific theory"}
  end

  defp competition_evaluated?(artifact) do
    # Check lineage for a tournament or documented review
    # Stub: in full implementation, queries KnowledgeLineage
    false
  end
end
