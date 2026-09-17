# Capability manifest for the ASC Milestone B audit (MISSING detection).
# Append test modules as they are located — this manifest is the source of
# truth for MISSING classification.
[
  %{capability: :probability_bayes, module: Tiannara.Math.ProbabilityContractTest},
  %{capability: :nearest_neighbor, module: Tiannara.NearestNeighborTest},
  %{capability: :asc_core_topology, module: Tiannara.ASC.Core.SupervisorTopologyTest},
  %{capability: :asc_core_resilience, module: Tiannara.ASC.Core.SupervisorResilienceTest},
  %{capability: :asc_core_boot, module: Tiannara.ASC.Core.BootTest},
  %{capability: :asc_resilience, module: Tiannara.ASC.Core.ResilienceTest},
  %{capability: :l3_probe, module: Tiannara.ASC.L3.ProbeTest}
]