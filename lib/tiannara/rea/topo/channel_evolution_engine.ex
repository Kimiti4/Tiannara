defmodule Tiannara.REA.Topo.ChannelEvolutionEngine do
  alias Tiannara.REA.Topo.{ChannelApplicator, ReplacementRegistry}
  alias Tiannara.REA.Causal.Graph

  @spec evolve(non_neg_integer(), [map()]) :: {:ok, list()}
  def evolve(epoch, meta_genomes) do
    genomes = Enum.map(meta_genomes, &extract_genome/1)

    # 1. Apply aggregated genome to graph (respects constitution)
    # Note: For REA-3, we need an Applicator that aggregates topologies or we just 
    # take the dominant one. We assume ChannelApplicator.apply_population_genomes exists.
    # We will mock/implement it shortly if not.
    apply_population_genomes(genomes)

    # 2. Evaluate active replacement proposals
    evaluate_replacement_proposals(epoch)

    # 3. Promote proven replacements
    promoted = ReplacementRegistry.promote_proven()

    # 4. Record topological events
    events = record_topological_changes(epoch, genomes, promoted)

    {:ok, events}
  end

  defp evaluate_replacement_proposals(_epoch) do
    active = ReplacementRegistry.all_active()

    Enum.each(active, fn proposal ->
      # Measure stabilization effect of proposed channel vs. original
      repl_effect = measure_stabilization(proposal.proposed_channel)
      baseline_effect = measure_stabilization_of_original(proposal.target_channel_id)

      ReplacementRegistry.update_evaluation(proposal.id, repl_effect, baseline_effect)
    end)
  end

  defp measure_stabilization(channel) do
    # Query recent propagated pressure from this channel
    case Graph.observe_channel(channel.id) do
      nil -> 0.0
      obs -> Map.get(obs, :delivered_pressure, 0.0)
    end
  end

  defp measure_stabilization_of_original(channel_id) do
    case Graph.observe_channel(channel_id) do
      nil -> 0.0
      obs -> Map.get(obs, :delivered_pressure, 0.0)
    end
  end

  defp extract_genome(%{causal_genome: cg}), do: cg
  defp extract_genome(_), do: Tiannara.REA.Topo.CausalGenome.random()

  defp record_topological_changes(_epoch, _genomes, promoted) do
    Enum.map(promoted, fn id ->
      %{epoch: 0, event_type: :channel_superseded, details: %{proposal_id: id}}
    end)
  end
  
  # Stub for applicability until we build the full graph decentralization
  defp apply_population_genomes(genomes) do
    if genomes == [] do
      :ok
    else
      # Take average of parameter genes across the dominant genomes
      dom = hd(genomes)
      Enum.each(dom.channel_genes, fn {ch_id, gene} ->
        case Graph.all() |> Enum.find(&(&1.id == ch_id)) do
          nil -> :ok
          ch -> 
            updated = %{ch | 
              weight: ch.weight * gene.weight_modifier,
              delay: gene.delay_modifier,
              decay: ch.decay * gene.decay_modifier,
              enabled: gene.enabled
            }
            # Only register if it passes constitution (the applicator logic)
            case Tiannara.REA.Causal.CausalConstitution.validate_mutation(ch_id, weight: updated.weight, delay: updated.delay, delete: not updated.enabled) do
              :ok -> Graph.register(updated)
              _ -> :ok # Clamp/ignore if invalid
            end
        end
      end)
      
      # Register any novel proposals as new channels
      Enum.each(dom.novel_proposals, fn ch -> 
        Graph.register(ch)
      end)
    end
  end
end
