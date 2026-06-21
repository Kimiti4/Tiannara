defmodule Tiannara.REA.Topo.CausalMutator do
  @moduledoc """
  Handles tier-aware topological mutations.
  Constitutional = No topo changes, tight param drift.
  Structural = Param drift + replacement proposals.
  Adaptive/Experimental = Freely mutable.
  """

  alias Tiannara.REA.Causal.CausalConstitution
  alias Tiannara.REA.Topo.{CausalGenome, ReplacementProposal, ReplacementRegistry}

  @spec mutate(CausalGenome.t(), map()) :: {CausalGenome.t(), [atom()]}
  def mutate(%CausalGenome{} = genome, env) do
    {genes, param_muts} = mutate_parametric(genome.channel_genes, genome)
    {genes2, topo_muts} = mutate_topological(genes, genome)
    {genes3, novel_muts} = propose_novel_channels(genes2, genome, env)
    {genes4, replacement_muts} = propose_replacements(genes3, genome)

    mutations = param_muts ++ topo_muts ++ novel_muts ++ replacement_muts

    {%{genome |
      channel_genes: genes4,
      novel_proposals: maybe_add_proposals(genome.novel_proposals, novel_muts ++ replacement_muts)
    }, mutations}
  end

  defp mutate_parametric(genes, genome) do
    Enum.reduce(genes, {%{}, []}, fn {ch_id, gene}, {acc_g, acc_m} ->
      tier = CausalConstitution.tier(ch_id)
      elasticity = get_elasticity(ch_id)

      # Tier-specific mutation rates and radii
      {mutation_rate, weight_radius, delay_radius} = case tier do
        :constitutional ->
          # Very small radius, low rate
          {genome.mutation_rate * 0.1, 0.05 * elasticity, 0}
        :structural ->
          # Moderate radius, moderate rate
          {genome.mutation_rate * 0.3, 0.25 * elasticity, trunc(1 * elasticity)}
        :adaptive ->
          # Large radius, high rate
          {genome.mutation_rate * 0.6, 0.5 * elasticity, trunc(2 * elasticity)}
        :experimental ->
          # Maximum radius, maximum rate
          {genome.mutation_rate * 1.0, 1.0 * elasticity, trunc(3 * elasticity)}
        nil ->
          # Unknown tier, treat as experimental
          {genome.mutation_rate * 0.8, 0.8, 2}
      end

      # Apply parametric mutations with tier-specific radii
      if :rand.uniform() < mutation_rate do
        {new_gene, mutation_type} = apply_parametric_mutation_with_radius(gene, weight_radius, delay_radius)
        {Map.put(acc_g, ch_id, new_gene), [mutation_type | acc_m]}
      else
        {Map.put(acc_g, ch_id, gene), acc_m}
      end
    end)
  end

  defp apply_parametric_mutation_with_radius(gene, weight_radius, delay_radius) do
    case :rand.uniform(3) do
      1 ->
        # Weight mutation: ±weight_radius
        drift = 1.0 + (:rand.uniform() - 0.5) * 2 * weight_radius
        new_weight = max(0.1, gene.weight_modifier * drift)
        {%{gene | weight_modifier: new_weight}, :weight_mutation}
      2 ->
        # Delay mutation: ±delay_radius epochs
        if delay_radius > 0 do
          delta = Enum.random(-delay_radius..delay_radius)
          new_delay = max(0, gene.delay_modifier + delta)
          {%{gene | delay_modifier: new_delay}, :delay_mutation}
        else
          {gene, :no_mutation}
        end
      3 ->
        # Decay mutation: ±weight_radius/2 (decay is less mutable)
        drift = 1.0 + (:rand.uniform() - 0.5) * weight_radius
        new_decay = max(0.5, min(1.0, gene.decay_modifier * drift))
        {%{gene | decay_modifier: new_decay}, :decay_mutation}
    end
  end

  defp mutate_topological(genes, genome) do
    Enum.reduce(genes, {genes, []}, fn {ch_id, gene}, {acc_g, acc_m} ->
      tier = CausalConstitution.tier(ch_id)

      # Tier-gated topological mutation
      {can_toggle, toggle_rate} = case tier do
        :constitutional ->
          # NEVER toggle constitutional channels
          {false, 0.0}
        :structural ->
          # NEVER toggle structural channels (only parametric)
          {false, 0.0}
        :adaptive ->
          # Can toggle, moderate rate
          {true, genome.topological_plasticity * 0.3}
        :experimental ->
          # Can toggle, high rate
          {true, genome.topological_plasticity * 0.8}
        nil ->
          # Unknown tier, allow toggling
          {true, genome.topological_plasticity * 0.5}
      end

      protection = Map.get(gene, :mutation_protection, 0.0)
      effective_rate = toggle_rate * (1.0 - protection)

      if can_toggle and :rand.uniform() < max(0.0, effective_rate) do
        new_gene = %{gene | enabled: not gene.enabled}
        mutation_type = if new_gene.enabled, do: :channel_enabled, else: :channel_disabled
        {Map.put(acc_g, ch_id, new_gene), [mutation_type | acc_m]}
      else
        {Map.put(acc_g, ch_id, gene), acc_m}
      end
    end)
  end

  defp propose_novel_channels(genes, genome, _env) do
    # Only experimental channels can generate novel proposals
    # Adaptive channels can also propose, but at lower rate
    can_propose = CausalConstitution.by_tier(:experimental) != [] or
                  CausalConstitution.by_tier(:adaptive) != []

    if not can_propose or :rand.uniform() > genome.topological_plasticity * 0.5 do
      {genes, []}
    else
      proposal = generate_novel_proposal()
      {genes, [{:novel_proposal, proposal}]}
    end
  end

  # --- Replacement Proposals for Structural Channels ---

  defp propose_replacements(genes, genome) do
    # Only structural channels are eligible for replacement
    structural = CausalConstitution.by_tier(:structural)

    if structural == [] or :rand.uniform() > genome.topological_plasticity do
      {genes, []}
    else
      target = Enum.random(structural)
      proposal = generate_replacement_for(target)

      if proposal do
        rp = ReplacementProposal.new(genome.id, target.channel_id, proposal)
        ReplacementRegistry.submit(rp)
        {genes, [{:replacement_proposal, rp}]}
      else
        {genes, []}
      end
    end
  end

  defp generate_replacement_for(target_bounds) do
    # Propose a new channel that targets the same signal as the original
    # but from a different source population
    target_str = target_bounds.channel_name |> Atom.to_string()
    
    parts = String.split(target_str, "_to_")
    target_signal = if length(parts) == 2, do: parts |> List.last() |> String.to_atom(), else: :unknown

    populations = [:civilization, :epistemology, :law_species, :meta_genome]

    # Find the original source population
    original_channel = Tiannara.REA.Causal.Graph.all()
      |> Enum.find(&(&1.id == target_bounds.channel_id))

    case original_channel do
      nil -> nil
      orig ->
        # Try an alternative source
        alt_sources = populations -- [orig.source.population]
        alt_source = Enum.random(alt_sources)
        alt_signal = alternative_signal_for(alt_source, orig.target.signal)

        if alt_signal do
          Tiannara.REA.Causal.Channel.new(
            name: :"replacement_#{alt_source}_to_#{target_signal}",
            source: %{population: alt_source, signal: alt_signal},
            target: orig.target,
            transfer_fn: &Tiannara.REA.Causal.Channel.mean/1,
            delay: target_bounds.optimal_delay,
            decay: 0.9,
            weight: target_bounds.optimal_weight * 0.8  # start slightly weaker
          )
        else
          nil
        end
    end
  end

  defp alternative_signal_for(:civilization, _), do: Enum.random([:cohesion, :economic_output, :compute_capacity])
  defp alternative_signal_for(:epistemology, _), do: Enum.random([:operator_success, :cognitive_yield, :adaptability])
  defp alternative_signal_for(:law_species, _), do: Enum.random([:perturbation_survival, :diversity_index])
  defp alternative_signal_for(:meta_genome, _), do: Enum.random([:innovation_rate, :resilience])

  defp get_elasticity(ch_id) do
    case CausalConstitution.get_bounds(ch_id) do
      nil -> 0.5  # Default elasticity for unknown channels
      bounds -> Map.get(bounds, :elasticity, 0.5)
    end
  end

  defp generate_novel_proposal do
    populations = [:civilization, :epistemology, :law_species, :meta_genome]
    src_pop = Enum.random(populations)
    tgt_pop = Enum.random(populations -- [src_pop])
    
    src_sig = alternative_signal_for(src_pop, nil)
    tgt_sig = alternative_signal_for(tgt_pop, nil)
    
    Tiannara.REA.Causal.Channel.new(
      name: :"novel_#{src_pop}_to_#{tgt_pop}",
      source: %{population: src_pop, signal: src_sig},
      target: %{population: tgt_pop, signal: tgt_sig},
      transfer_fn: &Tiannara.REA.Causal.Channel.mean/1,
      delay: Enum.random(1..5),
      decay: 0.9,
      weight: 0.5
    )
  end

  defp maybe_add_proposals(existing, new) do
    # Extract just the actual channel maps from proposals
    novel = new 
      |> Enum.filter(fn 
          {:novel_proposal, _} -> true
          _ -> false
         end)
      |> Enum.map(fn {:novel_proposal, p} -> p end)
      
    existing ++ novel
  end
end
