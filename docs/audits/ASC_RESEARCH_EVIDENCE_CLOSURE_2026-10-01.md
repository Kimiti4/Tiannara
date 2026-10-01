# ASC Adoption + Research Evidence Closure — 2026-10-01

## Audit result

The repository contains a substantially more rigorous ASC C-mission adoption path, including paired measurements, bootstrap confidence intervals, correctness gates, falsification records, sealed labels and a human-authorized adoption boundary.

However, a separate legacy institutional `AdoptionEngine` and the ASC agency orchestrator still contained false-success behavior.

### Closed

- ASC agency no longer creates `mock_observations`, `mock_hypotheses`, `mock_execute` or synthetic integration results.
- A complete research cycle now requires real observation, hypothesis, experiment and integration providers.
- Missing providers fail explicitly.
- Adoption governance now requires an injected governance provider rather than unconditional approval.
- Artifact validation now computes `valid` from the actual checks instead of hard-coding `true`.
- Provenance checksum presence/format is required.
- Local replication no longer returns fabricated evidence; it fails until an executable replication backend is connected.
- Adoption without replication confirmation is no longer justified by a confidence number alone.
- Synthetic kernel tick `0` was removed; the current adapter uses live process state and therefore does not claim a fake global clock.

### Remaining bounded gaps

The legacy `AdoptionEngine` still needs integration with the canonical CEL/CIS governance interfaces and a real experiment executor. Those are deliberately represented as unavailable rather than simulated.

The canonical C-mission runner remains the more mature adoption path: it performs real sandboxed candidate execution and statistical comparison, but its final `adoption_eligible` state must continue to mean **eligible for human authorization**, never automatic production mutation.

## Research/discovery contract

A future canonical discovery artifact should contain:

1. observation IDs and acquisition provenance;
2. exact world/simulation configuration;
3. hypothesis and preregistered prediction;
4. experiment design and executable identity;
5. raw observations;
6. derived quantities and mathematical transformations;
7. replication results;
8. negative/falsification attempts;
9. alternative explanations considered;
10. ACL findings;
11. OAVL findings;
12. unresolved uncertainty;
13. final epistemic state;
14. immutable evidence hashes.

A discovery must therefore never enter the knowledge graph merely because a research function returned `{:ok, result}`.

## Next gate

Audit the remaining executable surfaces listed by MC003-A0, prioritizing:

- ToolForge execution;
- SOPL/evolution deployment;
- governance deployment/rollback;
- legacy topology generation;
- civilization/legal simulations;
- autonomy/evolution metrics.

Every surface should be assigned one of:

`REAL`, `SIMULATED`, `UNAVAILABLE`, `FIXTURE`, or `HISTORICAL`.

Only `REAL` evidence may feed the World → Math → Research → Discovery certification path.
