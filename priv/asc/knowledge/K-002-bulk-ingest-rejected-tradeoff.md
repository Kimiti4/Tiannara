# K-002 — Rejected hypothesis: bulk_ingest (high-value resource tradeoff)

Hypothesis: Per-row ETS overhead dominates archive ingestion; replacing it with
bulk ETS insertion improves boot latency.

Lineage: ASC-AE-002 (runner v2, paired counterbalanced rounds, seed
{20_260_818, 2, 1}, 15 rounds, n=5 per round).

Measured (paired, same-environment):
  latency: median +78.7% (CI [0.67, 0.82]), 0/15 negative rounds
  memory:  +31.8% vs baseline (35.3-35.4MB vs 26.8MB, consistent every round)

Verdict: REJECTED (tier `rejected_memory`; gate: memory_delta > 5%).
Status: scientifically interesting / production adoption prohibited.

Why rejected: post-boot retained memory grew in the library process. The
AE-002 instrument garbage-collected only the bench process after boot, so the
+31.8% is measured post-boot — it is NOT evidence that the heap is
unreclaimable.

Open question (assigned to ASC-AE-003): is the ~8.6MB a transient peak
(reclaimable by a forced GC) or truly retained memory?

  world 1 (transient)  -> memory contract passes, bulk_ingest eligible/adoptable
  world 2 (retained)   -> memory contract fails, bulk_ingest stays rejected

Companion records (ASC-AE-002):
  parallel_ingest    — falsified (median -25.3%, CI [-0.76, -0.12], 11/15 negative)
  recursive_ingest   — eliminated at the correctness gate (single flaky failure
                       under 100% CPU load; environmental caveat recorded)

Governance: knowledge.eterm, evidence.ledger, labels.sealed.exs in
priv/asc/missions/ASC-AE-002/.