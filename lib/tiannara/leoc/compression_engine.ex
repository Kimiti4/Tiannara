defmodule Tiannara.LEOC.CompressionEngine do
  @moduledoc """
  Phase LEOC-1: Compresses %EpochClosure{} into %EigenSeed{}.
  Lossy by design: preserves attractors, discards noise. Enables procedural re-emergence.
  """
  alias Tiannara.REL.Types.{EpochClosure, EigenSeed}

  @spec compress(EpochClosure.t()) :: {:ok, EigenSeed.t()} | {:error, term()}
  def compress(%EpochClosure{} = closure) do
    # 1. Extract attractors
    discovery_affinities = extract_discovery_affinities(closure.discoveries)
    ontology_affinities = extract_ontology_affinities(closure.final_genome)
    
    # Extract signature
    signature = %{
      empiricism_bias: Map.get(closure.final_genome, :empiricism_bias, 0.5),
      abstraction_bias: Map.get(closure.final_genome, :abstraction_bias, 0.5),
      novelty_seeking: Map.get(closure.final_genome, :novelty_seeking, 0.5),
      contradiction_tolerance: Map.get(closure.final_genome, :contradiction_tolerance, 0.5)
    }

    # Extract historical disease resistance (mocked for now)
    disease_resistance = extract_disease_resistance(closure.diseases)

    # Bridge LEOC with DFG: project the civilization into a latent topological manifold
    latent_manifold = Tiannara.DFG.TopologicalFold.project(closure)

    eigen = %EigenSeed{
      id: "eigen_#{:crypto.strong_rand_bytes(4) |> Base.encode16()}",
      source_closure_id: closure.civ_id,
      epistemic_signature: signature,
      domain_affinities: compute_domain_affinities(discovery_affinities, ontology_affinities),
      collapse_signature: closure.collapse_signature,
      fitness_profile: closure.fitness_score,
      latent_weight: latent_manifold.compression_ratio * compute_latent_weight(closure),
      historical_disease_resistance: disease_resistance,
      created_at: closure.timestamp
    }

    # Store in LatentVault
    :ok = Tiannara.LEOC.LatentVault.store(eigen)
    
    {:ok, eigen}
  end

  defp extract_discovery_affinities(discovery_ids) do
    discovery_ids
    |> Enum.map(fn _id -> 
      %{domain: Enum.random([:engineering, :construction, :materials_science, :science, :cognition, :agriculture]), impact_score: 0.7}
    end)
    |> Enum.filter(&(&1 != nil and &1.impact_score > 0.6))
    |> Enum.group_by(& &1.domain)
  end

  defp extract_ontology_affinities(_genome_snapshot) do
    %{cognition: 0.25, governance: 0.20, engineering: 0.20, construction: 0.15, science: 0.15, agriculture: 0.05}
  end

  defp extract_disease_resistance(diseases) do
    # Later this would map disease IDs to classes and count survivals
    # For now, it's a placeholder
    %{novelty: length(diseases), optimization: 0}
  end

  defp compute_domain_affinities(attractors, weights) do
    Map.merge(attractors, weights, fn _k, a, w -> 
      if is_list(a), do: length(a) * w, else: a * w 
    end)
  end

  defp compute_latent_weight(closure) do
     closure.fitness_score * (1.0 + (closure.truth_capital / 100.0))
  end
end
