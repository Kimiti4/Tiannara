# ASC Milestone B Audit

Duration: 1566 ms

| Module | Test | ms | Classification |
|---|---|---|---|
| Tiannara.ASC.Core.SupervisorTopologyTest | test starts the registry, metrics, and telemetry children | 560.64 | PASS |
| Tiannara.Math.ProbabilityContractTest | test bayes_update/3 computes the scalar posterior | 31.54 | PASS |
| Tiannara.Math.ProbabilityContractTest | test bayes_update/3 zero evidence probability is surfaced, never hidden | 0.0 | PASS |
| Tiannara.Math.ProbabilityContractTest | test shannon_entropy/1 uniform distribution maximizes entropy | 0.0 | PASS |
| Tiannara.Math.ProbabilityContractTest | test shannon_entropy/1 certainty has zero entropy | 0.0 | PASS |
| Tiannara.NearestNeighborTest | test find/2 returns the closest artifact by Euclidean distance | 2.25 | PASS |
| Tiannara.NearestNeighborTest | test empty corpus returns nil | 0.0 | PASS |
| Tiannara.NearestNeighborTest | test non-list corpus returns nil | 0.0 | PASS |
| Tiannara.ASC.Core.SupervisorResilienceTest | test restarts registry after crash and preserves registry survival | 164.25 | PASS |
| Tiannara.ASC.L3.ProbeTest | test bounded cross-subsystem mission completes through real interfaces | 150.63 | PASS |
| Tiannara.ASC.Core.BootTest | test ASC core boots through the production supervision tree | 166.71 | PASS |
| Tiannara.ASC.Core.BootTest | test event bus delivers across the PubSub registry | 14.64 | PASS |
| Tiannara.ASC.Core.ResilienceTest | test worker crash -> supervisor restart -> registry usable -> siblings unaffected | 32.15 | PASS |
| Tiannara.ASC.Core.ResilienceTest | test repeated failure is CONTAINED: worker subtree dies, core and shared services survive | 171.93 | PASS |

## Missing

| Module | Test | ms | Classification |
|---|---|---|---|

