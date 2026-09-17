# MC-002-M: Evidence Matrix

**Gate:** MC-002-M (Logic substrate mutation, L4+L1+L2+L3)
**Status:** COMPLETE
**Date:** 2026-08-29

Grounds every mutation claim in a file path, line, value, and test — the
standard this campaign requires ("Evidence > Confidence"). Item IDs are
`E-<scope>-<n>`.

---

## L4 — Kernel (the sole contradiction/invariant/rule/transition/complementarity engine)

| ID | Claim | Evidence | Verification |
|----|-------|----------|--------------|
| E-L4-1 | Six-function logic kernel exists | `lib/tiannara/logic/{contradiction,invariant,rule,transition,complementarity}.ex` define `Contradiction.detect/2`, `Contradiction.from_refutations/1`, `Invariant.check/2`, `Rule.evaluate/2`, `Transition.valid?/3`, `Complementarity.holds?/2` | L-AT-1 (kernel surface test); `mix test test/tiannara/logic/` = 22 tests pass |
| E-L4-2 | `detect/2` is symmetric; golden corpus (10v20 → `:contradiction`, 5v5 → `:consistent`, cross-subject → `:unknown`, nil/garbage → `:unknown`) | `logic/contradiction.ex:18-37` | L-AT-2 (symmetry + golden corpus) |
| E-L4-3 | `from_refutations/1` keeps only kernel-confirmed contradictions | `logic/contradiction.ex:41-75` | L-AT (from_refutations) |
| E-L4-4 | `Invariant.check/2` collect-all (never first-fail), structured violation tuples, supports arity-0 constitutional probes and arity-1 predicates | `logic/invariant.ex` | L-AT (Invariant) |
| E-L4-5 | `Rule.evaluate/2` `:pass/:fail/:undetermined`; missing required facts → `:undetermined` (never coerced) | `logic/rule.ex` | L-AT (Rule) |
| E-L4-6 | `Transition.valid?/3` accepts single-edge and transition-table forms | `logic/transition.ex` | L-AT (Transition) |
| E-L4-7 | `Complementarity.holds?/2` = kernel non-contradiction + context consistency | `logic/complementarity.ex` | L-AT (Complementarity) |
| E-L4-8 | Kernel sits ABOVE Math: never computes confidence; no `Tiannara.Math` reference | `logic/*.ex` source | grep — no `Tiannara.Math` in `lib/tiannara/logic/` |

## L1 — Delegation (single engine; ≤1 engine under lib outside deprecated shims)

| ID | Claim | Evidence | Verification |
|----|-------|----------|--------------|
| E-L1-1 | `Contradiction.Engine.detect/1` becomes a thin shim over the kernel (group→pair→kernel verdict), classification/severity/confidence stay in Engine | `lib/tiannara/contradiction/engine.ex:38-58` (`KernelContradiction.detect(a, b) == :contradiction`) | `test/tiannara/contradiction/engine_test.exs` 11 tests pass (golden corpus, lifecycle, event) |
| E-L1-2 | `Graph.Audit.find_contradictions/1` implemented over the kernel; walks `:claims`-labeled edges, groups by subject, pairwise kernel `detect/2`, returns `%{type: :contradiction, subject, claim_a, claim_b}` | `lib/tiannara/graph/audit.ex` (new `find_contradictions/1` + helpers) | constitution registry probe `:no_contradiction_silently_discarded` returns `:ok` (L-AT-3); `test/tiannara/graph/` passes |
| E-L1-3 | `registry.ex:118` no longer raises `UndefinedFunctionError` | `Registry.probe_no_contradiction_silently_discarded/0` now resolves via real `Audit.find_contradictions/1` | `Tiannara.Constitution.Registry.default_invariants()` probe `inv.probe.() == :ok` (L-AT-3 test) |
| E-L1-4 | BeliefSystem broken negation/topic matcher deleted; contradiction verdicts delegated to the kernel | `lib/tiannara/core/world_model/belief_system.ex` (`contradictory?/2` calls `Logic.Contradiction.detect/2`; `are_direct_contradictions?`, `find_topic_conflicts`, `has_conflicting_confidences?`, `extract_topic` deleted) | L-AT-4: structured beliefs falsified; free-text beliefs → `:unknown` (false-positive drop); ros/omcs integration 7 tests pass |
| E-L1-5 | Discovery scheduler `contradiction_pairs/1` routes through the kernel | `lib/tiannara/discovery/discovery_scheduler.ex:586-...` (`Tiannara.Logic.Contradiction.detect(claim(a), claim(b))`) | `test/tiannara/discovery/` suite passes (39 properties, 181 tests) |
| E-L1-6 | Sentinel `Verification.find_contradictions/3` KEPT as-is — REAL evidence-link mechanism (contradiction via recorded `ev.contradicts`/`ev.supports` links, not value conflicts); `Contradiction.from_refutations/1` is its canonical map-based adapter | `sentinel/verification.ex:307-349` unchanged | pre-existing `test/tiannara/sentinel/` suite (unchanged) |

## L2 — Theatrical decommission

| ID | Claim | Evidence | Verification |
|----|-------|----------|--------------|
| E-L2-1 | `CTL.ParadoxResolver.resolve/2` → `{:error, :paradox_resolver_unavailable}`; fabricated metric pushes removed | `lib/tiannara/ctl/paradox_resolver.ex` (new body) | source inspection; `mix test test/tiannara/ctl/` passes |
| E-L2-2 | Nine `Substrate.*` files deleted; no compile-time consumer | files absent; `lib/tiannara/substrate/` removed | verifier checks absence; `mix compile` succeeds "Generated tiannara app" |
| E-L2-3 | Scratch substrate gauntlets deleted | `run_{cof,euf,gck,hsv,mcal,oed,opc,ose,osk}_gauntlet.exs` absent | `Get-ChildItem` — absent |

## L3 — Fabricated metrics removal

| ID | Claim | Evidence | Verification |
|----|-------|----------|--------------|
| E-L3-1 | Aggregator no-op clauses for `:euf,:gck,:hsv,:mcal,:opc,:oed,:ose,:osk,:cof` removed | `lib/tiannara/metrics/aggregator.ex` (clauses gone; fallback at :178 kept) | `mix test test/tiannara/metrics/` passes; verifier checks no substrate literals |
| E-L3-2 | Real-emitter clauses (`:coherence`, `:iv`) retained | `aggregator.ex` still handles both domains | source inspection |

## Gate-level constraints

| ID | Claim | Evidence |
|----|-------|----------|
| E-G-1 | L5 (proof/inference) NOT mutated | no `logic/proof.ex` or inference module created; only the 6 authorized kernel functions |
| E-G-2 | Mathematics/ontology unchanged | no `:mathematics` domain introduced; CanonicalRegistry/AC-001 untouched |
| E-G-3 | No fabricated replacement success introduced | all new functions return kernel verdicts/`:undetermined`/`:unknown`/explicit `unavailable`; verifier scans for hardcoded metric literals |
| E-G-4 | Authorization honored | `priv/tiannara/authorization/ASC-MC-002-M-LOGIC-MUTATION.human.yaml` GRANTED, scope L4+L1+L2+L3, L5 excluded |

## Regression status

- Targeted suites (L-AT-1..5 + engine + graph + discovery + ctl + metrics +
  ros/omcs + logic kernel): **PASS** (see `MC002-M-CERTIFICATION.md` for numbers).
- Full cross-repo suite: **NOT_EXECUTED** (environment/time) — recorded as such,
  never as PASS → BOUNDED verdict.
- Pre-existing failures: `test/tiannara/constitution/constitutional_invariant_suite_test.exs`
  (untracked, references nonexistent `Sentinel.Authority`/`Research.Authority`)
  and the MC-001-M-baseline asc regression are documented infrastructure
  debt, not introduced by this mutation.