alias Tiannara.OSE.Evolution.{EpistemicLineageTracker, AdaptiveNicheGenerator, CausalSpeciationEngine, ObserverSurvivabilityIndex}
alias Tiannara.OSE.OGC.GarbageCollector
require Logger

Logger.info("\n🌌 === STARTING EPISTEMIC EVOLUTION & PHYLOGENETICS === 🌌")

# 1. Base Universes
ast_1 = %{
  id: "Universe_Base1",
  causal_primitives: [:strict_locality, :linear_time, :observer_independence],
  interaction_rules: :deterministic,
  observer_model: :passive,
  entropy_dynamics: :unidirectional_increase,
  time_structure: :unidirectional,
  identity_constraints: :rigid,
  budget: 80.0
}

ast_2 = %{
  id: "Universe_Base2",
  causal_primitives: [:quantum_entanglement, :linear_time],
  interaction_rules: :probabilistic,
  observer_model: :active_participant,
  entropy_dynamics: :feedback_stabilized,
  time_structure: :unidirectional,
  identity_constraints: :fluid,
  budget: 20.0
}

ecology = [ast_1, ast_2]

# 2. Adaptive Niche Generation
Logger.info("\n[1] Evaluating Niche Pressure...")
niche_gradient = AdaptiveNicheGenerator.evaluate_and_generate(ecology)

# 3. Causal Speciation
Logger.info("\n[2] Attempting Causal Speciation (Hybridization)...")
descendant = CausalSpeciationEngine.speciate(ast_1, ast_2)

# 4. Epistemic Lineage Tracking
Logger.info("\n[3] Logging Phylogenetic Ancestry...")
EpistemicLineageTracker.track_lineage(ast_1, descendant)
EpistemicLineageTracker.track_lineage(ast_2, descendant)

# 5. Observer Survivability Index
Logger.info("\n[4] Validating Observer Survivability...")
ObserverSurvivabilityIndex.filter_viable(ast_1)
ObserverSurvivabilityIndex.filter_viable(descendant)

# 6. Ontological Garbage Collection
Logger.info("\n[5] Executing Ontological Garbage Collection (Folding)...")
# Simulating the folding of extinct or redundant branches
extinct_branches = [
  %{id: "Extinct_1", causal_primitives: [:strict_locality, :exotic_heat]},
  %{id: "Extinct_2", causal_primitives: [:linear_time, :strange_matter]}
]
canonical = GarbageCollector.fold_lineages(extinct_branches)

Logger.info("\n==================================================")
Logger.info("🌌 EPISTEMIC EVOLUTION CYCLE COMPLETE 🌌")
Logger.info("-> Descendant Species Created: #{descendant.id}")
Logger.info("-> Dormant Lineages Folded: #{canonical.id}")
Logger.info("-> Novelty Preserved: #{inspect(canonical.novelty_signature)}")
Logger.info("==================================================")
