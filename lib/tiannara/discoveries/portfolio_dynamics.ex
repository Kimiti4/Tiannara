defmodule Tiannara.REA.GovernanceEpisode do
  @derive Jason.Encoder
  defstruct [:mode, :trigger, :timestamp, :notes]
end

defmodule Tiannara.REA.TheoryPortfolio do
  @derive Jason.Encoder
  defstruct [
    :weights,                  # map of theory_id => float
    :yields,                   # map of theory_id => float
    :tracking_error,           # float
    :hhi,                      # float
    :capture_index,            # float
    :correlation_risk,         # float
    :extinction_risk,          # float
    :dependency_risk,          # float
    :recovery_capacity,        # float
    :cascading_failure_risk,   # float
    :adaptation_velocity,      # float
    :security_score,           # float
    :history,                  # list of past maps/snapshots
    :governance_history,       # list of GovernanceEpisode
    :current_mode              # atom (:exploration, :exploitation, :balanced, :emergency)
  ]
end

defmodule Tiannara.REA.PortfolioRebalancer do
  @moduledoc """
  Manages portfolio rebalancing targets based on operating Governance Modes.
  """
  alias Tiannara.REA.TheoryPortfolio
  alias Tiannara.REA.GovernanceEpisode
  alias Tiannara.REA.MetaTheoryPredictor
  alias Tiannara.REA.PortfolioRiskAnalyzer

  @doc """
  Rebalances weights dynamically using the selected governance mode and friction threshold.
  """
  def rebalance(%TheoryPortfolio{} = portfolio, meta_tensor, target_context, target_domain, mode \\ :balanced, threshold \\ 0.05) do
    # 1. Retrieve quarantined theories to exclude them
    quarantined =
      if Code.ensure_loaded?(Tiannara.REA.Epistemic.QuarantineManager) and Process.whereis(Tiannara.REA.Epistemic.QuarantineManager) != nil do
        Tiannara.REA.Epistemic.QuarantineManager.quarantined_theories()
      else
        []
      end

    # Determine target weights based on mode
    raw_targets = MetaTheoryPredictor.get_adaptive_portfolio_weights(meta_tensor, target_context, target_domain)

    # Apply security pressure coordinate penalty to high-CFR and high-DR choices
    sp = Map.get(target_context, :security_pressure, 0.0)
    raw_targets =
      if sp > 0.0 do
        Map.new(raw_targets, fn {tid, w} ->
          single_weights = %{tid => 1.0}
          cfr_val = PortfolioRiskAnalyzer.calculate_cfr(single_weights, meta_tensor)
          dr_val = PortfolioRiskAnalyzer.calculate_dependency_risk(single_weights, meta_tensor)
          penalty = 1.0 - sp * (0.5 * cfr_val + 0.5 * dr_val)
          {tid, w * max(0.01, penalty)}
        end)
      else
        raw_targets
      end
    
    # Filter raw_targets by quarantined status
    raw_targets =
      Map.new(raw_targets, fn {tid, w} ->
        if Enum.member?(quarantined, tid) or Enum.member?(quarantined, to_string(tid)) do
          {tid, 0.0}
        else
          {tid, w}
        end
      end)
      |> normalize_weights(quarantined)

    target_weights =
      case mode do
        :exploitation ->
          # Concentrate 100% on the single highest-scoring non-quarantined theory
          rec = MetaTheoryPredictor.recommend(meta_tensor, target_context, target_domain)
          
          # Pick the recommended theory if not quarantined, otherwise the highest scoring non-quarantined
          best_tid =
            if Enum.member?(quarantined, rec.recommended_theory) or Enum.member?(quarantined, to_string(rec.recommended_theory)) do
              raw_targets
              |> Enum.reject(fn {tid, _} -> Enum.member?(quarantined, tid) or Enum.member?(quarantined, to_string(tid)) end)
              |> Enum.max_by(fn {_, w} -> w end, fn -> nil end)
              |> case do
                {tid, _} -> tid
                nil -> rec.recommended_theory
              end
            else
              rec.recommended_theory
            end

          Map.new(raw_targets, fn {tid, _} ->
            if tid == best_tid and not (Enum.member?(quarantined, tid) or Enum.member?(quarantined, to_string(tid))) do
              {tid, 1.0}
            else
              {tid, 0.0}
            end
          end)

        :exploration ->
          # Blend target weights with uniform distribution to maximize diversity (70/30 blend)
          non_quar_targets = Map.keys(raw_targets) |> Enum.reject(&(Enum.member?(quarantined, &1) or Enum.member?(quarantined, to_string(&1))))
          n = length(non_quar_targets)
          uniform_val = if n > 0, do: 1.0 / n, else: 0.0
          blended = Map.new(raw_targets, fn {tid, w} ->
            if Enum.member?(quarantined, tid) or Enum.member?(quarantined, to_string(tid)) do
              {tid, 0.0}
            else
              {tid, 0.70 * w + 0.30 * uniform_val}
            end
          end)
          # Normalize to sum to exactly 1.0
          normalize_weights(blended, quarantined)

        :emergency ->
          # Prioritize low extinction risk: target proportional to (1.0 - HazardRatio)
          raw_emergency =
            Map.new(raw_targets, fn {tid, _} ->
              if Enum.member?(quarantined, tid) or Enum.member?(quarantined, to_string(tid)) do
                {tid, 0.0}
              else
                hr = Map.get(meta_tensor.hazard_ratios, tid, 0.10)
                {tid, max(0.01, 1.0 - hr)}
              end
            end)
          normalize_weights(raw_emergency, quarantined)

        _balanced ->
          raw_targets
      end

    # 2. Check rebalancing friction threshold
    should_rebalance? =
      Enum.any?(target_weights, fn {tid, target_w} ->
        current_w = Map.get(portfolio.weights || %{}, tid, 0.0)
        abs(current_w - target_w) > threshold
      end)

    updated_weights = if should_rebalance?, do: target_weights, else: portfolio.weights || %{}

    # 3. Calculate adaptation velocity (PAV)
    pav =
      if should_rebalance? and portfolio.weights do
        Enum.sum(Enum.map(target_weights, fn {tid, target_w} ->
          current_w = Map.get(portfolio.weights, tid, 0.0)
          abs(current_w - target_w)
        end))
      else
        0.0
      end

    # 4. Handle Governance Mode Transition Episode
    current_mode = portfolio.current_mode || :balanced
    new_gov_history =
      if mode != current_mode do
        episode = %GovernanceEpisode{
          mode: mode,
          trigger: if(mode == :emergency, do: :coordinated_attack, else: :manual_regime_shift),
          timestamp: System.system_time(:millisecond),
          notes: "Transitioned to #{mode} mode from #{current_mode}."
        }
        [episode | portfolio.governance_history || []]
      else
        portfolio.governance_history || []
      end

    # 5. Recompute all risks under updated weights
    hhi = PortfolioRiskAnalyzer.calculate_hhi(updated_weights)
    ci = PortfolioRiskAnalyzer.calculate_capture_index(updated_weights)
    dr = PortfolioRiskAnalyzer.calculate_dependency_risk(updated_weights, meta_tensor)
    cfr = PortfolioRiskAnalyzer.calculate_cfr(updated_weights, meta_tensor)
    prc = PortfolioRiskAnalyzer.calculate_prc(updated_weights, meta_tensor, target_context, target_domain)
    
    # Static focus profile correlation risk
    corr_risk = PortfolioRiskAnalyzer.calculate_correlation_risk(updated_weights, meta_tensor)
    
    # Portfolio extinction risk
    pe =
      Enum.reduce(updated_weights, 0.0, fn {tid, w}, acc ->
        hr = Map.get(meta_tensor.hazard_ratios, tid, 0.10)
        acc + w * hr
      end)
      |> Float.round(4)

    # Base security score
    prc_adj = 0.1 + 0.9 * prc
    base_security_score =
      (1.0 - hhi) * (1.0 - corr_risk) * (1.0 - pe) * (1.0 - ci) * (1.0 - dr) * (1.0 - cfr) * prc_adj

    # 6. Apply Active Pathogen & Vaccine protection scale
    active_pathogens =
      if Code.ensure_loaded?(Tiannara.REA.Epistemic.PathogenRegistry) and Process.whereis(Tiannara.REA.Epistemic.PathogenRegistry) != nil do
        Tiannara.REA.Epistemic.PathogenRegistry.active_pathogens()
      else
        []
      end

    protection_factor =
      if Code.ensure_loaded?(Tiannara.REA.Epistemic.VaccineRegistry) and Process.whereis(Tiannara.REA.Epistemic.VaccineRegistry) != nil do
        if Enum.empty?(active_pathogens) do
          1.0
        else
          avg =
            active_pathogens
            |> Enum.map(&Tiannara.REA.Epistemic.VaccineRegistry.calculate_protection(&1.signature))
            |> Enum.sum()
            
          avg / length(active_pathogens)
        end
      else
        1.0
      end

    pathogen_penalty = min(0.9, length(active_pathogens) * 0.1 * (1.0 - protection_factor))
    security_score = Float.round(base_security_score * (1.0 - pathogen_penalty), 4)

    new_portfolio = %TheoryPortfolio{
      weights: updated_weights,
      yields: target_weights, # estimated potential yield
      tracking_error: if(should_rebalance?, do: Float.round(pav / 2.0, 4), else: 0.0),
      hhi: hhi,
      capture_index: ci,
      correlation_risk: corr_risk,
      extinction_risk: pe,
      dependency_risk: dr,
      recovery_capacity: prc,
      cascading_failure_risk: cfr,
      adaptation_velocity: Float.round(pav, 4),
      security_score: security_score,
      governance_history: new_gov_history,
      current_mode: mode
    }

    # Append to snapshots
    snapshot = %{
      weights: updated_weights,
      security_score: security_score,
      mode: mode,
      timestamp: System.system_time(:millisecond)
    }
    %{new_portfolio | history: [snapshot | portfolio.history || []]}
  end
  defp normalize_weights(map, quarantined) do
    total = Map.drop(map, quarantined) |> Map.values() |> Enum.sum()
    if total > 0.0 do
      Map.new(map, fn {tid, w} ->
        if Enum.member?(quarantined, tid) or Enum.member?(quarantined, to_string(tid)) do
          {tid, 0.0}
        else
          {tid, w / total}
        end
      end)
    else
      non_quar_keys = Map.keys(map) |> Enum.reject(&(&1 in quarantined or to_string(&1) in quarantined))
      n = length(non_quar_keys)
      val = if n > 0, do: 1.0 / n, else: 0.0
      Map.new(map, fn {tid, _} ->
        if tid in non_quar_keys or to_string(tid) in non_quar_keys do
          {tid, val}
        else
          {tid, 0.0}
        end
      end)
    end
  end
end

defmodule Tiannara.REA.PortfolioRiskAnalyzer do
  @moduledoc """
  Computes Portfolio Governance metrics: HHI, Capture Index, Dependency Graphs, CFR, and PRC.
  """
  alias Tiannara.REA.MetaTheoryPredictor

  def calculate_hhi(weights) do
    Enum.sum(Enum.map(weights, fn {_, w} -> w * w end)) |> Float.round(4)
  end

  def calculate_capture_index(weights) do
    if weights == %{} do
      0.0
    else
      Enum.max(Map.values(weights)) |> Float.round(4)
    end
  end

  def calculate_correlation_risk(weights, _meta_tensor) do
    tids = Map.keys(weights)
    
    # Compute similarity between context focus coordinates
    pairs = for t1 <- tids, t2 <- tids, t1 != t2, do: {t1, t2}
    
    sum =
      Enum.reduce(pairs, 0.0, fn {t1, t2}, acc ->
        w1 = Map.get(weights, t1, 0.0)
        w2 = Map.get(weights, t2, 0.0)
        
        f1 = MetaTheoryPredictor.theory_focus_context(t1)
        f2 = MetaTheoryPredictor.theory_focus_context(t2)
        
        v_diff = :math.pow(f1.volatility - f2.volatility, 2)
        c_diff = :math.pow(f1.complexity - f2.complexity, 2)
        a_diff = :math.pow(f1.adversariality - f2.adversariality, 2)
        dist = :math.sqrt(v_diff + c_diff + a_diff)
        
        similarity = max(0.01, 1.0 - dist)
        acc + w1 * w2 * similarity
      end)
      
    Float.round(sum, 4)
  end

  def get_ancestors(theory_id, all_theories \\ []) do
    theories = if all_theories == [], do: Tiannara.REA.TheorySelection.load_theories(), else: all_theories
    theory = Enum.find(theories, & &1.theory_id == theory_id)
    parents = if theory, do: theory.parent_theories || [], else: []
    
    Enum.reduce(parents, MapSet.new([theory_id]), fn p, acc ->
      MapSet.union(acc, get_ancestors(p, theories))
    end)
  end

  def calculate_dependency_risk(weights, _meta_tensor, all_theories \\ []) do
    tids = Map.keys(weights)
    ancestor_maps = Map.new(tids, & {&1, get_ancestors(&1, all_theories)})
    
    pairs = for t1 <- tids, t2 <- tids, t1 != t2, do: {t1, t2}
    
    sum =
      Enum.reduce(pairs, 0.0, fn {t1, t2}, acc ->
        w1 = Map.get(weights, t1, 0.0)
        w2 = Map.get(weights, t2, 0.0)
        
        a1 = Map.get(ancestor_maps, t1)
        a2 = Map.get(ancestor_maps, t2)
        
        intersection = MapSet.intersection(a1, a2) |> MapSet.size()
        union = MapSet.union(a1, a2) |> MapSet.size()
        
        jaccard = if union > 0, do: intersection / union, else: 0.0
        acc + w1 * w2 * jaccard
      end)
      
    Float.round(sum, 4)
  end

  def calculate_cfr(weights, _meta_tensor, all_theories \\ []) do
    tids = Enum.filter(Map.keys(weights), &(Map.get(weights, &1, 0.0) > 0.0))
    n = length(tids)
    
    if n > 0 do
      ancestor_maps = Map.new(tids, & {&1, get_ancestors(&1, all_theories)})
      
      cfr_scores =
        Map.new(tids, fn target_id ->
          affected_count =
            Enum.count(tids, fn other_id ->
              ancestors = Map.get(ancestor_maps, other_id)
              MapSet.member?(ancestors, target_id)
            end)
          
          {target_id, affected_count / n}
        end)
        
      sum = Enum.reduce(tids, 0.0, fn tid, acc ->
        w = Map.get(weights, tid, 0.0)
        acc + w * Map.get(cfr_scores, tid, 0.0)
      end)
      
      Float.round(sum, 4)
    else
      0.0
    end
  end

  def calculate_prc(weights, meta_tensor, context, domain, all_theories \\ []) do
    state =
      try do
        case Process.whereis(TiannaraOS.CivilizationKernel) do
          nil -> nil
          pid ->
            if Process.alive?(pid) do
              apply(TiannaraOS.CivilizationKernel, :get_state, [])
            else
              nil
            end
        end
      rescue
        _ -> nil
      end

    if state do
      twin_worlds = Enum.filter(Map.values(state.worlds), &(&1.twin != nil))
      events = Enum.flat_map(twin_worlds, fn w -> w.twin.world_events end)

      passed_count = Enum.count(events, &(&1.type == :ci_passed))
      failed_count = Enum.count(events, &(&1.type == :ci_failed))
      total = passed_count + failed_count

      if total > 0 do
        Float.round(passed_count / total, 4)
      else
        insts = Map.values(state.institutions)
        if length(insts) > 0 do
          Float.round(Enum.sum(Enum.map(insts, &(&1.efficiency || 1.0))) / length(insts), 4)
        else
          0.8
        end
      end
    else
      # Pre-shock yield using current weights
      theories = if all_theories == [], do: Tiannara.REA.TheorySelection.load_theories(), else: all_theories
      theory_map = Map.new(theories, & {&1.theory_id, &1})

      yield_pre =
        Enum.reduce(weights, 0.0, fn {tid, w}, acc ->
          t = Map.get(theory_map, tid)
          fit = if t, do: Tiannara.REA.TheorySelection.calculate_fitness(t, Map.get(context, :volatility, 0.5), Map.get(context, :complexity, 0.5)), else: 0.5
          acc + w * fit
        end)

      # Shock context
      shock_context = %{
        volatility: min(1.0, Map.get(context, :volatility, 0.5) + 0.3),
        complexity: min(1.0, Map.get(context, :complexity, 0.5) + 0.3),
        adversariality: min(1.0, Map.get(context, :adversariality, 0.5) + 0.3)
      }

      # Target rebalanced weights under shock context
      shock_weights = MetaTheoryPredictor.get_adaptive_portfolio_weights(meta_tensor, shock_context, domain)

      # Recovered yield under shock context using the new weights
      yield_recovered =
        Enum.reduce(shock_weights, 0.0, fn {tid, w}, acc ->
          t = Map.get(theory_map, tid)
          fit = if t, do: Tiannara.REA.TheorySelection.calculate_fitness(t, shock_context.volatility, shock_context.complexity), else: 0.5
          acc + w * fit
        end)

      prc =
        if yield_pre > 0.0 do
          yield_recovered / yield_pre
        else
          1.0
        end

      Float.round(max(0.01, min(1.0, prc)), 4)
    end
  end

  @doc """
  Computes Truth Maintenance Index (TMI).
  Tracks epistemic quality based on accuracy, replication success, validation, and refutations.
  """
  def calculate_tmi(predictions \\ [], _replication_rate \\ 0.85, _refutation_rate \\ 0.05) do
    state =
      try do
        case Process.whereis(TiannaraOS.CivilizationKernel) do
          nil -> nil
          pid ->
            if Process.alive?(pid) do
              apply(TiannaraOS.CivilizationKernel, :get_state, [])
            else
              nil
            end
        end
      rescue
        _ -> nil
      end

    if state do
      evs = Map.values(state.evidence_graph)
      replications = Enum.filter(evs, &(&1.type == :replication))
      successful_replications = Enum.count(replications, &(&1.value == 1.0))

      rep_rate = if length(replications) > 0, do: successful_replications / length(replications), else: 0.8

      refuted_theories = Enum.count(evs, &(&1.type == :theory and &1.value < 0.4))
      total_theories = Enum.count(evs, &(&1.type == :theory))
      ref_rate = if total_theories > 0, do: refuted_theories / total_theories, else: 0.0

      accuracy =
        if predictions == [] do
          0.80
        else
          correct = Enum.count(predictions, & Map.get(&1, :correct))
          correct / length(predictions)
        end

      validation = 0.85
      refutation_penalty = max(0.0, 1.0 - ref_rate)

      Float.round((accuracy * 0.4) + (rep_rate * 0.3) + (validation * 0.1) + (refutation_penalty * 0.2), 4)
    else
      accuracy =
        if predictions == [] do
          0.80
        else
          correct = Enum.count(predictions, & Map.get(&1, :correct))
          correct / length(predictions)
        end

      validation = 0.85
      refutation_penalty = max(0.0, 1.0 - 0.05)

      Float.round((accuracy * 0.4) + (0.85 * 0.3) + (validation * 0.1) + (refutation_penalty * 0.2), 4)
    end
  end

  @doc """
  Computes Civilization Diversity Index (CDI).
  Tracks diversity across theories (HHI), institutions, goals, and domains.
  """
  def calculate_cdi(weights, institutions, goals) do
    # 1. Theory diversity
    theory_hhi = calculate_hhi(weights)
    theory_div = 1.0 - theory_hhi

    # 2. Institution diversity
    inst_shares = Enum.map(institutions, & &1.compute_share)
    inst_hhi = Enum.sum(Enum.map(inst_shares, & &1 * &1))
    inst_div = 1.0 - inst_hhi

    # 3. Goal diversity: count target domains
    goal_domains = Enum.map(goals, & &1.target_domain) |> Enum.uniq()
    goal_div = if length(goals) > 0, do: length(goal_domains) / 20.0, else: 0.0

    # 4. Domain diversity: knowledge capital variance
    domain_capitals =
      if Code.ensure_loaded?(Tiannara.Domains.CanonicalRegistry) do
        Tiannara.Domains.CanonicalRegistry.all() |> Enum.map(& Tiannara.Domains.KnowledgeCapitalBoundary.get(&1))
      else
        [1.0]
      end
    
    mean = Enum.sum(domain_capitals) / length(domain_capitals)
    var = domain_capitals |> Enum.map(&((&1 - mean) * (&1 - mean))) |> Enum.sum() |> Kernel./(length(domain_capitals))
    domain_div = 1.0 - min(var / max(mean * mean, 0.001), 1.0)

    # Average blended CDI
    Float.round((theory_div + inst_div + goal_div + domain_div) / 4.0, 4)
  end
end
