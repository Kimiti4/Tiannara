defmodule Tiannara.EDM.DiseaseEngine do
  @moduledoc """
  Handles the lifecycle, mutation, and structural effects of Epistemic Diseases.
  """
  require Logger
  alias Tiannara.Core.WorldModel.EpistemicDisease

  @doc "Set disease cost formula."
  def set_disease_cost_formula(_func), do: :ok

  @doc """
  Prechecks a candidate epistemology for structural impossibilities or known pathologies
  before wasting shadow simulation resources.
  Returns :ok or {:error, reason}.
  """
  def precheck(candidate_operators) do
    # Example check: too many recursive operators lead to infinite loops
    recursive_count = Enum.count(candidate_operators, &(&1 == "recursive"))
    if recursive_count >= 3 do
      {:error, :recursive_overload}
    else
      :ok
    end
  end

  @doc """
  Generates a new disease (usually driven by ACM adversarial evolution).
  """
  def generate_disease(shard_id, target_type \\ :discovery) do
    class = Enum.random([
      :reinforcement, :novelty, :conservatism, :optimization, :contradiction, :authority
    ])
    
    disease = EpistemicDisease.new(%{
      id: "disease_#{:crypto.strong_rand_bytes(4) |> Base.encode16()}",
      class: class,
      target_type: target_type,
      origin_shard_id: shard_id,
      virulence: 0.3 + (:rand.uniform() * 0.5),
      persistence: 0.4 + (:rand.uniform() * 0.4),
      detectability: 0.1 + (:rand.uniform() * 0.5),
      mutation_rate: 0.05 + (:rand.uniform() * 0.1)
    })
    
    entity = Tiannara.Core.WorldModel.Entity.new(
      disease.id,
      "Disease",
      "Epistemic Pathogen (#{class})",
      %{disease_data: disease}
    )
    
    Tiannara.Core.WorldModel.EntityRegistry.register_entity(entity, shard_id)
    disease
  end

  @doc """
  Applies the structural effect of a disease to a civilization.
  This is typically called during the EconomyEngine tick for infected civs.
  """
  def apply_disease_effect(civ_id, %EpistemicDisease{} = disease) do
    # Fetch budget to apply effects
    case Tiannara.REL.EconomyEngine.get_budget(civ_id) do
      nil -> :ok
      budget ->
        apply_class_effect(civ_id, budget, disease.class, disease.virulence)
    end
  end

  defp apply_class_effect(civ_id, _budget, :reinforcement, virulence) do
    # Prediction accuracy decays. For now, simulate by penalizing Truth Capital
    # and maybe flagging the Entity's genome.
    Logger.debug("🦠 [EDM] #{civ_id} suffering Reinforcement: Truth decays.")
    Tiannara.REL.EconomyEngine.penalize_truth_capital(civ_id, virulence * 2.0)
  end

  defp apply_class_effect(civ_id, _budget, :novelty, virulence) do
    # Spikes maintenance burden. We do this by consuming energy directly.
    Logger.debug("🦠 [EDM] #{civ_id} suffering Novelty: Maintenance spikes.")
    drain = max(1, trunc(virulence * 10))
    Tiannara.REL.EconomyEngine.consume(civ_id, %{energy: drain})
  end

  defp apply_class_effect(civ_id, _budget, :conservatism, virulence) do
    # Declines fitness / stagnates discovery.
    Logger.debug("🦠 [EDM] #{civ_id} suffering Conservatism: Stagnation.")
    # E.g. penalizing compute so they can't make discoveries
    Tiannara.REL.EconomyEngine.consume(civ_id, %{compute: trunc(virulence * 10)})
    # Also decay fitness on the Entity directly if possible
    # We could send a message to EntityRegistry
  end

  defp apply_class_effect(civ_id, _budget, :optimization, virulence) do
    # Resource imbalance. Consume one resource heavily, inject another.
    Logger.debug("🦠 [EDM] #{civ_id} suffering Optimization: Imbalance.")
    Tiannara.REL.EconomyEngine.consume(civ_id, %{attention: trunc(virulence * 15)})
    Tiannara.REL.EconomyEngine.inject(civ_id, %{energy: trunc(virulence * 5)})
  end

  defp apply_class_effect(civ_id, _budget, :contradiction, virulence) do
    # Massive compute drain.
    Logger.debug("🦠 [EDM] #{civ_id} suffering Contradiction: Compute drain.")
    Tiannara.REL.EconomyEngine.consume(civ_id, %{compute: trunc(virulence * 20)})
  end

  defp apply_class_effect(civ_id, _budget, :authority, virulence) do
    # Truth capital falls, Influence rises (prestige capture).
    Logger.debug("🦠 [EDM] #{civ_id} suffering Authority: Prestige capture.")
    Tiannara.REL.EconomyEngine.penalize_truth_capital(civ_id, virulence * 5.0)
    Tiannara.REL.EconomyEngine.grant_influence_capital(civ_id, virulence * 5.0)
  end

  @doc """
  Record that a disease caused an extinction.
  """
  def record_extinction(%EpistemicDisease{} = disease) do
    # In a real DB, we'd update the row. For now, we return updated struct.
    %{disease | extinction_count: disease.extinction_count + 1}
  end

  @doc """
  Record a transmission.
  """
  def record_transmission(%EpistemicDisease{} = disease) do
    %{disease | transmission_count: disease.transmission_count + 1}
  end

  @doc """
  Determines if a civilization detects a disease.
  Immune adaptations (e.g. Peer Review, Replication) improve detection chance.
  """
  def detect_disease(civ_id, %EpistemicDisease{} = disease) do
    # Fetch known discoveries to see if they have immune adaptations
    known_discoveries = Tiannara.REL.DiscoveryLedger.get_known_discoveries(civ_id)
    
    # Base detection chance is the disease's detectability
    base_chance = disease.detectability

    # Immune adaptations boost detection
    immune_boost = Enum.reduce(known_discoveries, 0.0, fn disc, acc ->
      case disc.name do
        "Peer Review" -> acc + 0.2
        "Replication Science" -> acc + 0.3
        "Contradiction Audits" -> acc + 0.25
        "Adversarial Verification" -> acc + 0.35
        "Blind Validation" -> acc + 0.2
        _ -> acc
      end
    end)

    total_chance = min(0.95, base_chance + immune_boost)
    
    if :rand.uniform() < total_chance do
      Logger.info("🔬 [EDM] #{civ_id} detected disease #{disease.id}!")
      {:detected, total_chance}
    else
      {:hidden, total_chance}
    end
  end
end
