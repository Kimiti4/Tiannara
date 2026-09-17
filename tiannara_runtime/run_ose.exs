alias Tiannara.OPC.T4.CausalAST
alias Tiannara.OSE.{CausalSandbox, Battlefield, CausalCompatibilityStress, EntropyAllocator, DormancyProtocol, CrossOntologyTranslation, NoveltyPreservation}
require Logger

Logger.info("\n🌌 === STARTING ONTOLOGICAL SELECTION ECOLOGY (OSE) === 🌌")

# 1. Instantiate Two Distinct ASTs (Universes)
ast_1 = %CausalAST{
  id: "Universe_Alpha",
  causal_primitives: [:strict_locality, :linear_time, :observer_independence],
  interaction_rules: :deterministic,
  observer_model: :passive,
  entropy_dynamics: :unidirectional_increase,
  time_structure: :unidirectional,
  identity_constraints: :rigid
}

ast_2 = %CausalAST{
  id: "Universe_Beta",
  # Contains a recursion bomb (dimensional_compression + bidirectional time)
  causal_primitives: [:dimensional_compression, :quantum_entanglement],
  interaction_rules: :probabilistic,
  observer_model: :active_participant,
  entropy_dynamics: :non_linear_fluctuation,
  time_structure: :bidirectional,
  identity_constraints: :fluid
}

Logger.info("\n[1] Instantiating via Causal Sandbox & Quarantine...")
u1 = CausalSandbox.instantiate(ast_1)
u2 = CausalSandbox.instantiate(ast_2)

battlefield = %Battlefield{active_universes: [u1, u2]}

# 2. Cross-Ontology Translation
Logger.info("\n[2] Establishing Semantic Translation...")
CrossOntologyTranslation.calculate_interoperability(u1, u2)

# 3. Causal Compatibility Stress
Logger.info("\n[3] Applying Adversarial Thermodynamic Selection (Stress Test)...")
evaluated_universes = CausalCompatibilityStress.evaluate(battlefield.active_universes)

# 4. Resource Allocation
Logger.info("\n[4] Executing Entropy-Preserving Allocation...")
battlefield = EntropyAllocator.allocate_budget(battlefield, evaluated_universes)
battlefield = %{battlefield | active_universes: NoveltyPreservation.apply_subsidy(battlefield.active_universes)}

# 5. Dormancy Protocol
Logger.info("\n[5] Enforcing Survival Thresholds & Archival...")
final_battlefield = DormancyProtocol.process_ecology(battlefield)

Logger.info("\n==================================================")
Logger.info("FINAL SURVIVING ECOLOGY:")
Logger.info("==================================================")
for u <- final_battlefield.active_universes do
  Logger.info("-> #{u.id} | Budget: #{Float.round(u.budget, 2)} | Primitives: #{inspect(u.causal_primitives)}")
end
