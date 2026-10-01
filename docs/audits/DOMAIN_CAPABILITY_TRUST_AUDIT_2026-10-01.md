# Domain Capability Trust Audit — Evidence Remediation

Date: 2026-10-01
Base: release/final-product-closure (256c8cb94e59e598bd9a8da74bc1207bc9b722d7)

## Scope

This tranche audits executable domain surfaces that previously returned successful placeholder values or converted unmeasured state into apparently verified capability.

Disposition:

- **A — Implemented now:** bounded deterministic logic; API adapters connected to existing implemented core NLP and scientific backends.
- **B — Explicit failure:** unavailable generation/planning/discovery paths now fail rather than fabricate output.
- **C — Simulation:** must remain explicitly labelled as simulation and must not enter epistemic certification as real evidence.
- **D — Documentation/tests:** historical claims are not runtime evidence.

## Changes

### NLP API

`tiannara_api/engines/nlp.py` now delegates to `AdvancedNLPEngine`.

Supported operations:

- intent analysis
- sentiment
- entity extraction
- semantic search

Unknown tasks, missing text, and malformed requests return errors. The adapter no longer reports a synthetic "processing pending implementation" result as success.

### Logic API

`tiannara_api/engines/logic.py` now implements bounded forward chaining over explicit facts and Horn-style rules.

A query is entailed only when it is present as an explicit fact or is derivable through supplied rules. The response includes the supporting proof step. No confidence score is fabricated.

### Causal API

`tiannara_api/engines/causal.py` now delegates:

- effect estimation to the DoWhy integration;
- temporal discovery to PCMCI/Tigramite.

Missing scientific dependencies fail closed. Temporal discovery does not silently downgrade to correlation.

The legacy DoWhy graph-discovery helper was also hardened: residual correlation is no longer treated as evidence of causal direction, and the helper refuses to return an oriented graph without a valid discovery method.

Causal assumption validation no longer returns `validated=True` merely because a model object was constructed. Unverified assumptions are represented as unknown.

### Unified Reasoner

`tiannara_core/reasoning/unified_reasoner.py` no longer fabricates Python/FastAPI code or generic responses when no real generation backend exists. Refinement also fails explicitly when no real refinement backend is connected.

## Required next tranche

The next audit should target:

1. ASC adoption/validation paths — ensure adoption requires measured benefit, provenance, reproducibility, falsification evidence and governance authorization.
2. Research/discovery paths — distinguish observation, hypothesis, experiment, replication and certified discovery.
3. Legacy topology builders — remove hard-coded topology/metric claims from active execution paths.
4. Civilization/legal simulation — ensure simulated law/governance never becomes empirical world evidence.
5. Autonomy/evolution — require real before/after execution evidence, rollback proof, constitutional checks and human authorization where required.
6. Heartbeat/immune/nervous-system closure — verify liveness, message delivery, intervention state transitions and observed effects end-to-end.
7. World → Math → Research → Discovery loop — build the canonical evidence packet that ACL/OAVL can independently audit.

## Evidence rule

A runtime result may be:

`OBSERVED`, `DERIVED`, `SIMULATED`, `UNVERIFIED`, `FAILED`, or `UNKNOWN`.

It must never be promoted to `VERIFIED` merely because a function returned `{:ok, ...}`, `status=success`, a test file exists, or a metric was synthetically generated.

## Verification note

This branch was modified through repository APIs. Full Elixir/Python test execution has not been performed in this environment; CI/local runtime execution remains a required gate before merge.
