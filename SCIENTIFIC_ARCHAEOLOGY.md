# Scientific Archaeology

The archaeological contract preserves observations, hypotheses, experiments, evidence, negative results, refutations, theory revisions, laws, capital reversals, and certificates as immutable versioned records.

Reconstruction procedure:

1. Verify the manifest and artifact hashes.
2. Load the frozen schema and canonical serializer version.
3. Verify ledger ordering, hash links, and referenced evidence.
4. Replay with recorded seed and logical clock.
5. Compare intermediate and final state roots.
6. Reconstruct graph nodes/edges and capital balances.
7. Report missing strata and contradictions without repair-by-deletion.

Current status: the procedure is specified, but no independent long-horizon archaeological replay bundle is present. Archaeology certification remains blocked.
