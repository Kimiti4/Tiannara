defmodule Tiannara.EDM.MetaDiseaseEngine do
  @moduledoc """
  Phase 9.75: Meta-Diseases.
  These diseases do not kill instantly, but paralyze epistemic feedback.
  They act as evolutionary pressures, driving natural economic decay.
  """
  require Logger
  alias Tiannara.REL.EconomyEngine

  @doc "Evaluates a civilization's meta-cognitive actions and triggers diseases if unbalanced."
  def evaluate_meta_health(civ_id, meta_action_history) do
    # Assess if the recent history displays pathology
    case detect_pathology(meta_action_history) do
      :optimization_mania ->
        Logger.warn("🧬 [MetaDisease] #{civ_id} contracted Optimization Mania. Predictability rising, novelty crashing.")
        apply_optimization_mania(civ_id)

      :mutation_addiction ->
        Logger.warn("🧬 [MetaDisease] #{civ_id} contracted Mutation Addiction. Operator churn critical.")
        apply_mutation_addiction(civ_id)

      :recursive_self_reference ->
        Logger.warn("🧬 [MetaDisease] #{civ_id} contracted Recursive Self-Reference. Meta-cognition loop detected.")
        apply_recursive_self_reference(civ_id)

      :healthy ->
        :ok
    end
  end

  defp detect_pathology(history) do
    prunes = Enum.count(history, &(&1.action == :prune))
    mutates = Enum.count(history, &(&1.action == :mutate))
    total = length(history)

    cond do
      total > 5 and (prunes / total) > 0.8 -> :optimization_mania
      total > 5 and (mutates / total) > 0.8 -> :mutation_addiction
      # Mock logic for recursive self-reference (e.g. meta-ops targeting meta-ops)
      total > 10 and Enum.all?(history, &(&1.action in [:synthesize, :mutate])) -> :recursive_self_reference
      true -> :healthy
    end
  end

  defp apply_optimization_mania(civ_id) do
    # Paralyze novelty: Extreme cost to discovering new truths
    EconomyEngine.consume(civ_id, %{compute: 200})
    EconomyEngine.penalize_truth_capital(civ_id, 10.0)
    # The civ is now less capable of generating truth capital over time, leading to starvation
  end

  defp apply_mutation_addiction(civ_id) do
    # Destroys truth retention: Compute is wasted, predictions fail
    EconomyEngine.consume(civ_id, %{attention: 300, compute: 100})
    EconomyEngine.penalize_truth_capital(civ_id, 25.0)
  end

  defp apply_recursive_self_reference(civ_id) do
    # Wastes compute entirely on the meta-layer, ignoring actual science
    EconomyEngine.consume(civ_id, %{compute: 500, attention: 500})
  end
end
