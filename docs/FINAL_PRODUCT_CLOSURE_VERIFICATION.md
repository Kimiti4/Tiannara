# Final Product Closure Verification

## What this release pass changed

- CEL constitutional-score failures now fail closed.
- CEL capability gate rejects services with no capability contract.
- CEL resource checks can consume explicit service resource checks.
- CIS plan validation now requires identity, steps, authority, evidence and provenance.
- Research programs no longer fabricate goals, experiments, evidence, or successful discoveries.
- Evidence scoring requires an executed result, observations and provenance and derives reproducibility/consistency from observations.
- Discovery assets require an existing evidence-backed discovery rather than defaulting confidence/value.
- World CAL and CIS engines are concrete bounded runtime components.
- World forks inherit and mutate WorldGenome lineage.
- Sentinel live intervention remains unavailable unless a real executor exists.
- Observatory headline health/progress figures are no longer fabricated constants.
- Native dialogue remains the product conversation path; no external LLM is required.

## Run

From the repository root:

    python3 scripts/final_release_verify.py

Then, when the full environment is available:

    bash scripts/final_release_verify.sh

The shell runner attempts:
1. Python native-dialogue verification.
2. Elixir formatting.
3. Targeted Elixir tests.
4. Full Elixir test suite.
5. Python native-dialogue tests.
6. Observatory production build.
7. SaaS production build.

Missing toolchains are reported as SKIPPED.

## Important interpretation

A green local verification run does not certify that every scientific domain is capable of proof or that every world can autonomously discover new science. Those capabilities remain bounded by the actual domain executors, mathematical solvers, validators, evidence stores and CEL authorization paths available at runtime.

The release principle is:

    unavailable capability -> explicit unavailable state
    simulated experiment -> simulation, not empirical fact
    candidate discovery -> candidate, not validated knowledge
    structural check -> verification, not theorem proof
    authorization request -> pending/denied/approved, never implied approval
