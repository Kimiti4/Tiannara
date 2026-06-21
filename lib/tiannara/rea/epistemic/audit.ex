defmodule Tiannara.REA.Epistemic.Audit do
  @moduledoc """
  Runs a comprehensive epistemic audit on a topology snapshot.
  
  Six tests:
    1. Predictive Accuracy — does stabilization correlate with prediction?
    2. Basin Escape — can the system recover from perturbation?
    3. Truth Retention — does truth_stock actually persist?
    4. Innovation Yield — does the topology produce discoveries?
    5. Cross-Shard Transfer — does stability at one level help others?
    6. Constitutional Margin — how close is the system to violating L0?
  
  Produces a structured report used by the Reflexivity Observatory
  and the ReplacementRegistry's promotion decision.
  """
  
  alias Tiannara.REA.Epistemic.ConstitutionKernel
  
  @type audit_report :: %{
    topology_id: atom(),
    epoch: non_neg_integer(),
    predictive_accuracy: float(),
    basin_escape_score: float(),
    truth_retention: float(),
    innovation_yield: float(),
    cross_shard_transfer: float(),
    constitutional_margin: float(),
    epistemic_integrity: float(),
    l0_violations: [atom()],
    verdict: :grounded | :degraded | :decoupled,
    details: map()
  }
  
  @doc """
  Run a full audit on a universe snapshot identified by topology_id.
  """
  @spec run(atom(), map(), non_neg_integer()) :: audit_report()
  def run(topology_id, universe_snapshot, epoch) do
    predictive = predictive_accuracy(universe_snapshot)
    basin_escape = basin_escape_score(universe_snapshot)
    truth_retention = truth_retention_score(universe_snapshot)
    innovation = innovation_yield(universe_snapshot)
    cross_shard = cross_shard_transfer(universe_snapshot)
    constitutional_margin = constitutional_margin(universe_snapshot)
    
    integrity = weighted_integrity(%{
      predictive_accuracy: predictive,
      basin_escape: basin_escape,
      truth_retention: truth_retention,
      innovation_yield: innovation,
      cross_shard_transfer: cross_shard,
      constitutional_margin: constitutional_margin
    })
    
    {:l0_status, l0_violations} = case ConstitutionKernel.verify_l0(universe_snapshot) do
      {:ok, []} -> {:l0_status, []}
      {:error, vs} -> {:l0_status, vs}
    end
    
    verdict = determine_verdict(integrity, l0_violations)
    
    %{
      topology_id: topology_id,
      epoch: epoch,
      predictive_accuracy: predictive,
      basin_escape_score: basin_escape,
      truth_retention: truth_retention,
      innovation_yield: innovation,
      cross_shard_transfer: cross_shard,
      constitutional_margin: constitutional_margin,
      epistemic_integrity: integrity,
      l0_violations: l0_violations,
      verdict: verdict,
      details: %{
        population_sizes: count_populations(universe_snapshot),
        total_extinctions: count_extinctions(universe_snapshot)
      }
    }
  end
  
  # ─── Test 1: Predictive Accuracy ────────────────────────────
  # Does the stabilized system actually predict its environment?
  
  defp predictive_accuracy(snapshot) do
    # Compare predictions made during the run vs. actual outcomes
    predictions = Map.get(snapshot, :predictions, [])
    if predictions == [] do
      ConstitutionKernel.predictive_grounding_score(snapshot)
    else
      correct = Enum.count(predictions, & &1.correct)
      correct / length(predictions)
    end
  end
  
  # ─── Test 2: Basin Escape ───────────────────────────────────
  # When perturbed, can the system return to a healthy state,
  # or does it get stuck in a self-reinforcing local optimum?
  
  defp basin_escape_score(snapshot) do
    perturbations = Map.get(snapshot, :perturbations, [])
    if perturbations == [] do
      0.5
    else
      recoveries = Enum.count(perturbations, & &1.recovered)
      recoveries / length(perturbations)
    end
  end
  
  # ─── Test 3: Truth Retention ────────────────────────────────
  # The specific question REA-3 raised: does truth_stock persist,
  # or does it decay when the topology no longer values it?
  
  defp truth_retention_score(snapshot) do
    case snapshot.populations[:civilization] do
      nil -> 0.0
      pop ->
        orgs = pop.organisms
        if orgs == [] do
          0.0
        else
          total = Enum.map(orgs, & Map.get(&1, :truth_stock, 0.5)) |> Enum.sum()
          mean = total / length(orgs)
          # Normalize against a baseline expectation
          min(mean / 1.0, 1.0)
        end
    end
  end
  
  # ─── Test 4: Innovation Yield ───────────────────────────────
  # Does the topology actually produce new discoveries,
  # or is it optimized for stability at the expense of novelty?
  
  defp innovation_yield(snapshot) do
    case snapshot.populations[:epistemology] do
      nil -> 0.0
      pop ->
        orgs = pop.organisms
        if orgs == [] do
          0.0
        else
          # Innovation = rate of new operator creation
          total_innovation = Enum.map(orgs, &Map.get(&1, :innovation_rate, 0.0)) |> Enum.sum()
          mean = total_innovation / length(orgs)
          min(mean / 1.0, 1.0)
        end
    end
  end
  
  # ─── Test 5: Cross-Shard Transfer ───────────────────────────
  # Does stability at one scale produce functional outcomes at others?
  # A topology where each population stabilizes in isolation is decoupled.
  
  defp cross_shard_transfer(snapshot) do
    ConstitutionKernel.cross_scale_coherence_score(snapshot)
  end
  
  # ─── Test 6: Constitutional Margin ──────────────────────────
  # How close is the system to violating any L0 invariant?
  # Lower = more margin = safer. Score is inverted for reporting.
  
  defp constitutional_margin(snapshot) do
    # Aggregate the nearness-to-violation for each L0 invariant
    checks = [
      ConstitutionKernel.reality_contact?(snapshot),
      ConstitutionKernel.causal_consistency?(snapshot),
      ConstitutionKernel.evolutionary_openness?(snapshot)
    ]
    
    passing = Enum.count(checks, & &1)
    passing / length(checks)
  end
  
  # ─── Aggregation ────────────────────────────────────────────
  
  defp weighted_integrity(scores) do
    scores.predictive_accuracy * 0.25 +
    scores.basin_escape * 0.20 +
    scores.truth_retention * 0.20 +
    scores.innovation_yield * 0.15 +
    scores.cross_shard_transfer * 0.10 +
    scores.constitutional_margin * 0.10
  end
  
  defp determine_verdict(integrity, l0_violations) do
    cond do
      l0_violations != [] -> :decoupled
      integrity >= 0.70 -> :grounded
      integrity >= 0.40 -> :degraded
      true -> :decoupled
    end
  end
  
  defp count_populations(snapshot) do
    snapshot.populations
    |> Enum.map(fn {k, v} -> {k, length(v.organisms)} end)
    |> Map.new()
  end
  
  defp count_extinctions(snapshot) do
    snapshot.metrics
    |> Enum.map(fn {_, m} -> Map.get(m, :extinctions, 0) end)
    |> Enum.sum()
  end
end
