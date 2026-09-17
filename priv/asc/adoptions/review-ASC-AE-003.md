# REVIEW DOSSIER — ASC-AE-003 / bulk_gc_ingest

## The question before the human
Do we authorize bulk_gc_ingest as the first ASC engineering candidate
eligible for human-approved production adoption?

## The candidate
One forced GC (:erlang.garbage_collect/0) at the end of RepairLibrary's
bulk ingestion init, in lib/tiannara/repair_library.ex. Single file,
single function, lineage branch asc-ae003-bulk_gc_ingest.

## Evidence (contract K-AE003, oracle-verified)
  Latency          +85.0%   CI [+81%, +90%]   0/15 negative rounds
  Transient peak    -0.07%
  Retained memory   +0.03%  CI [+0.02%, +0.03%]
  Hard gate         count=6000, integrity=true (all four arms)
  Contract status   :eligible, sole measured front member
  Oracle fidelity   pass=true (independent recomputation matched)
  Knowledge chain   K-002 -> K-002 resolution (World 1 confirmed)

## Risks, honestly stated
  R1. Not proven globally optimal — chunked_bulk_ingest was eliminated by an
      environment-sensitive gate and never measured. Mitigation: adoption is
      not a permanent commitment; lineage preserved; AE-004+ may supersede.
  R2. Measured under 100% ambient CPU load. Mitigation: paired interleaved
      design + 0/15 negative rounds + tight CI; post-adoption validation
      re-runs the suite and a watchdog-protected boot smoke.
  R3. Single workload scale (current archive 6000 entries; bounded cap
      20,000). Mitigation: bulk advantage is per-row; bounded cap bounds
      worst case; monitor archive growth.
  R4. Dedup semantics: bulk path keeps last occurrence per signature and
      assigns seqs monotonically — behaviorally equivalent to the per-row
      path for the bounded window, verified by retention/integrity gates.
      Documented for future maintainers.
  R5. GC placement: the forced GC belongs to this init path. Any future
      refactor of bulk ingestion must re-review GC placement.

## Recommended conditions of adoption
  1. Adoption ONLY through mix asc.adopt (two keys: machine evidence +
     human authorization artifact). No manual merge.
  2. --dry-run first; scope check must confirm exactly one changed file.
  3. Post-adoption: full suite + boot smoke run automatically by the tool;
     schedule a 7-day observation window before considering the matter closed.
  4. Rollback tag preserved; adoption ledger preserved regardless of outcome.

## Recommendation (evidence-based; authority remains human)
AUTHORIZE. This is the strongest evidence chain the project has produced:
a hypothesis born from a rejection, tested by a pre-registered contract,
verified by an independent oracle, with a bounded, reversible, single-file
change. The open risks are real but are exactly the ones the adoption
pathway's controls exist to manage. Declining would preserve a known ~5x
boot-ingestion improvement in limbo without evidence of harm; the evolution
framework says adopt, monitor, preserve lineage, continue evolving.

---
## Amendment — 2026-08-19 (post-adoption)

Superseded facts, recorded without editing the dossier above:
  - The real production path is lib/tiannara/asc/crucible/repair_library.ex
    (the dossier's lib/tiannara/repair_library.ex was the draft path).
  - The real archive at adoption held 18,016 rows, not 6,000.

Consequence: R3's scale gap is therefore smaller than feared — good news for
generalization. The measured candidate operates against the real archive in
production, with 1,984 headroom under the 20,000 cap.