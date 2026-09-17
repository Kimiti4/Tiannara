alias Tiannara.MetaEcology.{WorldRegistry, ClusterFormation, InterworldOLEF, CrossWorldCIS, CivilizationMigration}
alias Tiannara.OPC.Tier3.{IrreversibilityLedger, CommitEngine}
alias Tiannara.MCAL.{Supervisor, CognitiveKernel}
require Logger

# Boot Services
WorldRegistry.start_link()
IrreversibilityLedger.start_link()
Supervisor.start_link()

Logger.info("\n=== INITIALIZING META-ECOLOGY ===")

# Register 8 Specialized Worlds
roles = [:engineering, :cognitive_research, :energy, :governance, :chaos, :archive, :hybridization, :engineering]
world_ids = Enum.map(1..8, fn i -> 
  id = "world_#{i}"
  role = Enum.at(roles, i - 1)
  WorldRegistry.register_world(id, role)
  id
end)

# Form a cluster
{:ok, cluster} = ClusterFormation.form_cluster("alpha_cluster", world_ids)

Logger.info("\n=== INITIATING TIER 3 IRREVERSIBLE MUTATION ===")

# Create a mock high-impact AST
mock_ast = {:with_decay, 1000, {:op, :+, [{:var, :baseline_semantic_gravity}, {:const, 50.0}]}}

# Attempt to commit the mutation (current shear = 10,000, world_state = mock)
result = CommitEngine.commit_law(mock_ast, 10_000.0, %{})

case result do
  {:ok, :committed, mutation, patches} ->
    Logger.info("Mutation committed with #{length(patches)} compensatory patches.")
    
    Logger.info("\n=== TRIGGERING META-ECOLOGY RESPONSE ===")
    
    # The mutation caused stress, diffuse it via Interworld OLEF
    stress_to_diffuse = mutation.causal_impact_radius * 250.0
    InterworldOLEF.diffuse_pressure(cluster, stress_to_diffuse)
    
    # Run a CIS scan
    CrossWorldCIS.scan_cluster_immunity(cluster)
    
    # Trigger a civilization migration to adapt
    CivilizationMigration.migrate_species("civ_omicron", "world_5", "world_2")
    
    Logger.info("\n=== TRIGGERING MCAL COGNITIVE ABSTRACTION ===")
    
    # Feed the mutation trace into MCAL
    trace_state = %{
      mutation_id: mutation.id,
      divergence: (1.0 - mutation.confidence_projection) * 100,
      confidence: mutation.confidence_projection,
      cluster: cluster
    }
    
    CognitiveKernel.process_state(trace_state)
    
  {:error, reason} ->
    Logger.error("Mutation failed: #{inspect(reason)}")
end

# Small sleep to allow async MCAL Cast to finish printing logs
Process.sleep(500)

Logger.info("\n=== LINEAGE MEMORY ===")
lineage = IrreversibilityLedger.get_lineage(:law)
Logger.info("Recorded #{length(lineage)} permanent mutations in the ledger.")

Logger.info("\n=== MCAL EPISTEMIC MEMORY ===")
mcal_memory = Tiannara.MCAL.Memory.get_state()
Logger.info("Frame History: #{inspect(mcal_memory.frame_history)}")
Logger.info("Failure Archive: #{length(mcal_memory.failure_archive)} rejected abstractions")
Logger.info("Transition Graph: #{inspect(mcal_memory.transition_graph)}")
