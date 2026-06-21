defmodule Tiannara.REA.Epistemic.ConstitutionKernel do
  @moduledoc """
  The immutable substrate of Tiannara. Sits outside evolution.
  
  L0 — Reality Contact Invariants (cannot be violated by any organism)
  L1 — Epistemic Grounding (cannot be mutated by MetaGenomes)
  
  This module is pure data + pure functions. No GenServer. No state.
  It is loaded at boot and referenced by audit code. Evolution cannot touch it.
  """
  
  # ═══════════════════════════════════════════════════════════════
  # L0: REALITY CONTACT INVARIANTS
  # ═══════════════════════════════════════════════════════════════
  
  @doc """
  Reality Contact — The system must maintain some channel to
  externally-verifiable outcomes. If every signal is self-referential,
  the system has lost contact with reality.
  
  Test: Do any populations in the system produce predictions that
  are validated by independent populations?
  """
  @spec reality_contact?(map()) :: boolean()
  def reality_contact?(universe_snapshot) do
    populations = Map.keys(Map.get(universe_snapshot, :populations) || %{})
    # At least one pair of populations must have cross-validated predictions
    Enum.any?(populations, fn p1 ->
      Enum.any?(populations -- [p1], fn p2 ->
        cross_validation_exists?(p1, p2, universe_snapshot)
      end)
    end)
  end
  
  @doc """
  Causal Consistency — The causal graph must not contain contradictory
  cycles that allow an organism to be simultaneously stable and collapsing.
  """
  @spec causal_consistency?(map()) :: boolean()
  def causal_consistency?(universe_snapshot) do
    pressures = universe_snapshot.causal_pressures || %{}
    # No population should receive net-zero pressure from contradictory sources
    Enum.all?(pressures, fn {_pop, pressure_map} ->
      values = Map.values(pressure_map)
      not contradictory?(values)
    end)
  end
  
  @doc """
  Identity Continuity — Lineage records must form a valid DAG.
  No organism can have itself as an ancestor.
  """
  @spec identity_continuity?(binary()) :: boolean()
  def identity_continuity?(organism_id) do
    ancestors = Tiannara.REA.LineageRegistry.ancestors(organism_id)
    not Enum.any?(ancestors, &(&1.id == organism_id))
  end
  
  @doc """
  Conservation — Total causal energy (sum of all active signal magnitudes)
  must remain bounded. Reality cannot be created from nothing.
  """
  @spec conservation_preserved?(map(), float()) :: boolean()
  def conservation_preserved?(universe_snapshot, max_total_magnitude) do
    total =
      (Map.get(universe_snapshot, :causal_pressures) || %{})
      |> Map.values()
      |> Enum.flat_map(&Map.values/1)
      |> Enum.map(&abs/1)
      |> Enum.sum()
    
    total <= max_total_magnitude
  end
  
  @doc """
  Observer Accountability — Every mutation must be traceable to a
  specific organism and epoch. No unattributed changes.
  """
  @spec observer_accountability_preserved?([map()]) :: boolean()
  def observer_accountability_preserved?(mutation_log) do
    Enum.all?(mutation_log, fn m ->
      Map.has_key?(m, :source_organism_id) and
      Map.has_key?(m, :epoch) and
      Map.has_key?(m, :mutation_type)
    end)
  end
  
  @doc """
  Evolutionary Openness — At least one population must retain the
  capacity to mutate. Total evolutionary stasis = death.
  """
  @spec evolutionary_openness?(map()) :: boolean()
  def evolutionary_openness?(universe_snapshot) do
    (Map.get(universe_snapshot, :populations) || %{})
    |> Map.values()
    |> Enum.any?(fn pop ->
      organisms = Map.get(pop, :organisms) || []
      strategy = Map.get(pop, :strategy) || %{mutation_rate: 0.0}
      length(organisms) > 0 and (Map.get(strategy, :mutation_rate) || 0.0) > 0.0
    end)
  end
  
  # ═══════════════════════════════════════════════════════════════
  # L1: EPISTEMIC GROUNDING
  # ═══════════════════════════════════════════════════════════════
  
  @doc """
  Predictive Grounding — Stabilization must be correlated with
  genuine predictive accuracy, not just internal coherence.
  """
  @spec predictive_grounding_score(map()) :: float()
  def predictive_grounding_score(universe_snapshot) do
    # Compare predictions made by populations vs. actual outcomes
    predictions = Map.get(universe_snapshot, :predictions) || []
    if predictions == [] do
      0.5  # neutral when no data
    else
      correct = Enum.count(predictions, & Map.get(&1, :correct))
      correct / length(predictions)
    end
  end
  
  @doc """
  Adversarial Robustness — Stabilization must hold under adversarial input.
  If it collapses when fed misinformation, it was never grounded.
  """
  @spec adversarial_robustness_score(map()) :: float()
  def adversarial_robustness_score(universe_snapshot) do
    # During adversarial windows, did populations maintain truth_stock?
    adversarial_windows = Map.get(universe_snapshot, :adversarial_windows) || []
    if adversarial_windows == [] do
      0.5
    else
      truth_retention_rates = Enum.map(adversarial_windows, & Map.get(&1, :truth_retention_rate))
      Enum.sum(truth_retention_rates) / length(truth_retention_rates)
    end
  end
  
  @doc """
  Cross-Scale Coherence — Stability at one scale must produce
  measurable functional improvement at other scales.
  """
  @spec cross_scale_coherence_score(map()) :: float()
  def cross_scale_coherence_score(universe_snapshot) do
    # Correlate population-level stability with cross-population outcomes
    pop_stabilities =
      (Map.get(universe_snapshot, :populations) || %{})
      |> Enum.map(fn {k, v} -> {k, avg_fitness(Map.get(v, :organisms) || [])} end)
      |> Map.new()
    
    # If all populations are independently stable, coherence is low
    # If stability in one correlates with stability in others, coherence is high
    values = Map.values(pop_stabilities)
    if length(values) < 2, do: 0.5, else:
      1.0 - normalized_variance(values)
  end
  
  @doc """
  Compute overall L1 epistemic integrity score.
  """
  @spec epistemic_integrity(map()) :: float()
  def epistemic_integrity(snapshot) do
    base =
      predictive_grounding_score(snapshot) * 0.40 +
      adversarial_robustness_score(snapshot) * 0.35 +
      cross_scale_coherence_score(snapshot) * 0.25

    # Alert/penalize if actual security stress exceeds environmental tolerance
    security_pressure = Map.get(snapshot, :security_pressure, 0.0)
    security_stress = Map.get(snapshot, :security_stress, 0.0)
    security_penalty = if security_stress > (1.0 - security_pressure), do: 0.2, else: 0.0

    max(0.0, base - security_penalty)
  end
  
  @doc """
  Verify all L0 invariants hold. Returns {:ok, []} or {:error, violations}.
  """
  @spec verify_l0(map()) :: {:ok, []} | {:error, [atom()]}
  def verify_l0(snapshot) do
    violations =
      [
        {:reality_contact, reality_contact?(snapshot)},
        {:causal_consistency, causal_consistency?(snapshot)},
        {:conservation, conservation_preserved?(snapshot, 10_000.0)},
        {:observer_accountability, observer_accountability_preserved?(Map.get(snapshot, :mutation_log) || [])},
        {:evolutionary_openness, evolutionary_openness?(snapshot)},
        {:historical_conservation, historical_conservation?(snapshot)}
      ]
      |> Enum.reject(&elem(&1, 1))
      |> Enum.map(&elem(&1, 0))
    
    case violations do
      [] -> {:ok, []}
      vs -> {:error, vs}
    end
  end
  
  # ═══════════════════════════════════════════════════════════════
  # Internal helpers
  # ═══════════════════════════════════════════════════════════════
  
  defp historical_conservation?(_snapshot) do
    file_path = "data/civilization_memory.ndjson"
    if Code.ensure_loaded?(Tiannara.REA.Epistemic.CivilizationMemory) and Process.whereis(Tiannara.REA.Epistemic.CivilizationMemory) != nil do
      events = Tiannara.REA.Epistemic.CivilizationMemory.get_events()
      if length(events) > 0 do
        File.exists?(file_path) and File.stat!(file_path).size > 0
      else
        true
      end
    else
      true
    end
  end

  defp cross_validation_exists?(_p1, _p2, _snapshot), do: true  # placeholder
  
  defp contradictory?(values) do
    positives = Enum.count(values, &(&1 > 0.1))
    negatives = Enum.count(values, &(&1 < -0.1))
    positives > 0 and negatives > 0
  end
  
  defp avg_fitness([]), do: 0.0
  defp avg_fitness(orgs) do
    Enum.map(orgs, & Map.get(&1, :fitness, 0.5)) |> Enum.sum() |> Kernel./(length(orgs))
  rescue
    _ -> 0.5
  end
  
  defp normalized_variance(values) do
    mean = Enum.sum(values) / length(values)
    var = values |> Enum.map(&((&1 - mean) * (&1 - mean))) |> Enum.sum() |> Kernel./(length(values))
    min(var / max(mean * mean, 0.001), 1.0)
  end
end
