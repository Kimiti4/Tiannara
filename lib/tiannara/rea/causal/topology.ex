defmodule Tiannara.REA.Causal.Topology do
  @moduledoc """
  The canonical causal topology for Tiannara.
  
  This wiring encodes the deep architectural hypothesis:
  civilizations generate truth and compute, which feed epistemic
  and legal stability, which in turn enables meta-genomic innovation,
  which cascades back down as resilience and diversity pressure.
  
  The graph is cyclic, multi-scale, and bidirectional.
  """
  
  alias Tiannara.REA.Causal.Channel
  
  @doc "Build the full default topology."
  @spec default() :: [Channel.t()]
  def default() do
    [
      # --- Bottom-up: Civilization → Epistemology ---
      Channel.new(
        name: :civilization_truth_to_epistemic_stability,
        source: %{population: :civilization, signal: :truth_retention},
        target: %{population: :epistemology, signal: :symmetry_stability},
        transfer_fn: &Channel.mean/1,
        delay: 2,
        decay: 0.95,
        weight: 0.8
      ),
      
      # --- Bottom-up: Civilization → Law Species ---
      Channel.new(
        name: :civilization_compute_to_law_mutation,
        source: %{population: :civilization, signal: :compute_capacity},
        target: %{population: :law_species, signal: :innovation_rate},
        transfer_fn: &Channel.mean/1,
        delay: 3,
        decay: 0.9,
        weight: 0.6
      ),
      
      # --- Bottom-up: Civilization → MetaGenome ---
      Channel.new(
        name: :civilization_cohesion_to_meta_resilience,
        source: %{population: :civilization, signal: :cohesion},
        target: %{population: :meta_genome, signal: :resilience},
        transfer_fn: &Channel.min_signal/1,
        delay: 4,
        decay: 0.85,
        weight: 0.5
      ),
      
      # --- Top-down: Epistemology → Civilization ---
      Channel.new(
        name: :epistemic_yield_to_civilization_growth,
        source: %{population: :epistemology, signal: :cognitive_yield},
        target: %{population: :civilization, signal: :economic_output},
        transfer_fn: &Channel.mean/1,
        delay: 1,
        decay: 0.97,
        weight: 1.0
      ),
      
      # --- Lateral: Epistemology → Law Species ---
      Channel.new(
        name: :epistemic_coherence_to_law_stability,
        source: %{population: :epistemology, signal: :coherence},
        target: %{population: :law_species, signal: :symmetry_stability},
        transfer_fn: &Channel.mean/1,
        delay: 2,
        decay: 0.92,
        weight: 0.7
      ),
      
      # --- Lateral: Epistemology → MetaGenome ---
      Channel.new(
        name: :epistemic_success_to_meta_innovation,
        source: %{population: :epistemology, signal: :operator_success},
        target: %{population: :meta_genome, signal: :innovation_rate},
        transfer_fn: &Channel.max_signal/1,
        delay: 2,
        decay: 0.9,
        weight: 0.8
      ),
      
      # --- Top-down: Law Species → Civilization ---
      Channel.new(
        name: :law_stability_to_civilization_cohesion,
        source: %{population: :law_species, signal: :symmetry_stability},
        target: %{population: :civilization, signal: :cohesion},
        transfer_fn: &Channel.mean/1,
        delay: 2,
        decay: 0.93,
        weight: 0.9
      ),
      
      # --- Top-down: Law Species → MetaGenome ---
      Channel.new(
        name: :law_resilience_to_meta_diversity,
        source: %{population: :law_species, signal: :perturbation_survival},
        target: %{population: :meta_genome, signal: :diversity_index},
        transfer_fn: &Channel.mean/1,
        delay: 3,
        decay: 0.88,
        weight: 0.6
      ),
      
      # --- Top-down: MetaGenome → Law Species ---
      Channel.new(
        name: :meta_diversity_to_law_floor,
        source: %{population: :meta_genome, signal: :diversity_index},
        target: %{population: :law_species, signal: :diversity_index},
        transfer_fn: &Channel.mean/1,
        delay: 3,
        decay: 0.9,
        weight: 0.7
      ),
      
      # --- Top-down: MetaGenome → Epistemology ---
      Channel.new(
        name: :meta_innovation_to_epistemic_adaptability,
        source: %{population: :meta_genome, signal: :innovation_rate},
        target: %{population: :epistemology, signal: :adaptability},
        transfer_fn: &Channel.mean/1,
        delay: 2,
        decay: 0.92,
        weight: 0.8
      )
    ]
  end
  
  @doc "Minimal topology for testing."
  @spec minimal() :: [Channel.t()]
  def minimal() do
    [
      Channel.new(
        name: :test_civ_to_meta,
        source: %{population: :civilization, signal: :truth_retention},
        target: %{population: :meta_genome, signal: :innovation_rate},
        delay: 1,
        decay: 1.0,
        weight: 1.0
      )
    ]
  end
end
