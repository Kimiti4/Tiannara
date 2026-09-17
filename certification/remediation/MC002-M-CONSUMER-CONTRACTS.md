# MC-002-M: Consumer Contracts Ledger

**Gate:** MC-002-M
**Status:** COMPLETE
**Date:** 2026-08-29

Documents every production consumer of the mutated capabilities, the contract
observed before and after, and the remediation decision (rewrite / delegate /
preserve). Follows the MC-001-M consumer-verification pattern.

---

## C1. `Tiannara.Contradiction.Engine` → `Tiannara.Logic.Contradiction`

- **Consumers:** `lib/tiannara/omega/dry_run.ex:26,77` (calls `Engine.detect/1`);
  Sentinel/Ω.2 research director consumes the emitted `:contradiction_detected`
  epistemic events; `Contradiction.Director` lifecycle users.
- **Contract before:** `Engine.detect(claims) :: [%Record{}]`.
- **Contract after:** unchanged — same `detect/1` API, same `%Record{}`
  (type/severity/confidence/lifecycle). Internal verdict now delegated to the
  kernel `Logic.Contradiction.detect/2`.
- **Remediation:** none required (API preserved).
- **Semantics:** prior behavior `a.value != b.value` could flag nil-vs-value as
  a contradiction; kernel `detect/2` returns `:unknown` and drops those
  non-comparable pairs — a false-positive reduction, not a contract change.

## C2. `Tiannara.Constitution.Registry` probe

- **Consumer:** `probe_no_contradiction_silently_discarded/0`
  (`lib/tiannara/constitution/registry.ex:110-121`) called from
  `default_invariants/0` when the invariant suite runs.
- **Contract before:** raised `UndefinedFunctionError` (called the missing
  `Graph.Audit.find_contradictions/1`).
- **Contract after:** resolves — `Audit.find_contradictions/1` now exists and
  returns the kernel-confirmed conflict list; `inv.probe.() == :ok`.
- **Remediation:** real function added.

## C3. `Tiannara.Graph.Audit.find_contradictions/1`

- **Consumers:** `Registry` probe (above); the invariant suite test
  `test/tiannara/constitution/constitutional_invariant_suite_test.exs:71`.
- **Contract after:** `find_contradictions(g) :: [%{type: :contradiction,
  subject, claim_a, claim_b}]`, backed by kernel `detect/2`. Returns non-empty
  for the registry fixture (1 vs 2 on `:x`).

## C4. BeliefSystem (World Model)

- **Consumers:** `Core.WorldModel.API.add_belief/4` (`api.ex:38-40`),
  `query_high_confidence_beliefs/1` (`api.ex:70-72`); ros/omcs integration
  shards; `detect_contradictions/0` GenServer call.
- **Contract before (broken):** `find_all_contradictions/1` used a negation
  keyword matcher (`"not ","no ","never","false","incorrect"`) and a
  confidence-delta topic matcher producing fabricated `{id,id}` pairs.
- **Contract after:** `contradictory?/2` delegates to
  `Logic.Contradiction.detect/2` over `%{subject: belief.subject,
  value: belief.value}`. Free-text beliefs (no subject/value) return `:unknown`
  → no fabricated contradiction. Deleted theatrical helpers.
- **Remediation:** delegated; old matcher removed.
- **Semantics:** false-positive drop (L-AT-4). ros/omcs integration tests pass.

## C5. Discovery scheduler

- **Consumer:** `DiscoveryScheduler` Loop B (`contradiction_pairs/1`,
  `:586-608`, called by `count_contradiction_pairs/1` and gap analysis).
- **Contract before:** manual `same_observation_key?` + `entity_value` inequality.
- **Contract after:** same output shape (`%{type: :direct, domain, entity_ids,
  description}`) but the pair verdict is the kernel's `detect/2`.
- **Remediation:** rerouted through kernel; no consumer of the output map
  needed changing (verified discovery suite passes).

## C6. `Tiannara.CTL` pipeline

- **Consumer:** `BranchReconciliation.attempt_merge/3` (`branch_reconciliation.ex:22`).
- **Contract before:** `ParadoxResolver.resolve/2` returned `{:ok, :resolved}` /
  `{:error, :unresolvable_paradox}` / `{:error, :broken_causal_chain}`.
- **Contract after:** `{:error, :paradox_resolver_unavailable}` always.
- **Remediation:** none required — `{:error, _reason}` already routes to
  `HistoryIsolation.isolate(branch_id)` (real: emits
  `[:tiannara, :ctl, :branch_isolated]`). Truthful failure now causes
  quarantine instead of fake resolution.
- **Semantics:** no fabricated `{:ok, :resolved}` or metric push remains.

## C7. `Tiannara.Metrics.Aggregator`

- **Consumers:** every `Aggregator.push_event/2` caller across `lib/`.
- **Contract after:** `push_event([:tiannara, domain, metric], value)` unchanged;
  substrate-domain clauses removed, fallback clause retained → no crash.
- **Remediation:** none required.

## C8. Substrate families / gauntlet scripts

- **Consumers:** none in `lib/` or `test/` (verified by search).
- **Remediation:** deleted with the modules (untracked scratch harnesses).