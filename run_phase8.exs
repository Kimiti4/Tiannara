# Inject dummy genome
alias Tiannara.ASC.MetaScience.ResearchGenome
genome = %ResearchGenome{
  id: "genome_dummy_1",
  name: "Dummy Repair-Physics",
  lineage: [],
  generation: 1,
  domain_weights: %{transfer_physics: 0.05, repair_ecology: 0.95},
  methodology_blend: %{targeted_experimentation: 0.05, brute_force_mutation: 0.95},
  exploration_bias: 0.5,
  risk_tolerance: 0.5,
  fitness: 500.0,
  total_utility_generated: 500.0,
  total_compute_consumed: 100,
  epochs_alive: 1,
  epochs_starving: 0,
  exploitation_bias: 0.5,
  compute_efficiency: 10,
  mutation_rate: 0.1,
  status: :active
}
Tiannara.ASC.Research.ResearchRegistry.store_surviving_genomes([genome])

Tiannara.ASC.Reality.RealityAnchoredCampaign.run()
