# MC-002-M3: Theatrical & Fabricated Logic Decommission Ledger

**Gate:** MC-002-M / L2+L3
**Status:** COMPLETE
**Date:** 2026-08-29
**Parent:** MC-002 mutation (Logic substrate), authorized scope L4+L1+L2+L3

This ledger records the source-grounded decommission of every authorized
theatrical/fabricated logic target: implementation, previous behavior, evidence
of theatricality, callers, mutation, new unavailable semantics, consumer
remediation, tests, and final disposition. Taxonomy follows
`MC002-A0-LOGIC-TRUTH-CLASSIFICATION.md` (THEATRICAL = 8 substrate families +
`CTL.ParadoxResolver`).

---

## L2.1 `Tiannara.CTL.ParadoxResolver.resolve/2`

**File:** `lib/tiannara/ctl/paradox_resolver.ex`

### Previous behavior
```elixir
def resolve(branch_h, base_h) do
  Logger.warning("⚡ [CTL] ParadoxResolver activated.")
  Tiannara.Metrics.Aggregator.push_event([:tiannara, :ctl, :paradox_detected], 1)
  if has_contradiction?(branch_h, base_h) do
    Tiannara.Metrics.Aggregator.push_event([:tiannara, :cis, :collapse_probability], 0.9)
    {:error, :unresolvable_paradox}
  else
    if broken_chain?(branch_h) do
      {:error, :broken_causal_chain}
    else
      {:ok, :resolved}
    end
  end
end
# has_contradiction? reads Map.get(h1, :contradicts_base, false)
# broken_chain? reads Map.get(h, :broken_downstream, false)
```

### Evidence of theatrical behavior
- Reads two boolean flags (`:contradicts_base`, `:broken_downstream`) — no
  logical analysis, no entailment check, no resolution action is performed.
- Returns `{:ok, :resolved}` unconditionally when the flags are clear, selling
  "resolution" that never happened.
- Pushes fabricated metrics: `:paradox_detected 1` and CIS
  `:collapse_probability 0.9` (hardcoded, not input-derived).
- Recorded THEATRICAL in reconciliation (`MC002-A0-LOGIC-TRUTH-CLASSIFICATION.md`
  item T1) and inventory row T1.

### Callers (production)
- `branch_reconciliation.ex:22` — `attempt_merge/3` resolves stress-exceeded
  branches via `ParadoxResolver.resolve(branch_h, base_h)`.

### Mutation
```elixir
def resolve(_branch_h, _base_h) do
  {:error, :paradox_resolver_unavailable}
end
```

### New unavailable semantics
Paradox resolution is **Unavailable** — no truthful implementation exists. The
`{:error, :paradox_resolver_unavailable}` tuple is distinguishable from success
(`{:ok, :resolved}`) and from failure. The fabricated metric pushes are gone.

### Consumer remediation
- `BranchReconciliation.attempt_merge/3` already handled `{:error, _reason} ->
  HistoryIsolation.isolate(branch_id)` (branch_reconciliation.ex:25-26). No
  code change required; the stress-exceeded path now truthfully quarantines the
  branch via the REAL `HistoryIsolation.isolate/1` (emits
  `[:tiannara, :ctl, :branch_isolated]`) instead of a fake resolution.

### Tests
`test/tiannara/ctl/` (existing, passing):
- No specific ParadoxResolver test existed; `BranchReconciliation` behavior is
  covered by live integration tests. Added static verification in the
  `MC002_M_logic_mutation.py` verifier (unavailable string present, no metric
  push literal).

### Final disposition
**DECOMMISSIONED** — returns explicit unavailable state. No fabricated
success/metric-push remains.

---

## L2.2 `Tiannara.Substrate.*` — nine fabricated subsystem families

**Files (all deleted):**
- `lib/tiannara/substrate/cof.ex` (COF — Consensus of Observers Foundations)
- `lib/tiannara/substrate/euf.ex` (EUF — Epistemic Uncertainty Foundations)
- `lib/tiannara/substrate/gck.ex` (GCK — Global Consistency Kernel)
- `lib/tiannara/substrate/hsv.ex` (HSV — Holographic Singularity Verification)
- `lib/tiannara/substrate/mcal.ex` (MCAL — Model-based Causal Alternative Logic)
- `lib/tiannara/substrate/oed.ex` (OED — Ontology Evolution Dynamics)
- `lib/tiannara/substrate/opc.ex` (OPC — Observer-Physics Coupling)
- `lib/tiannara/substrate/ose.ex` (OSE — Ontological Selection Ecology)
- `lib/tiannara/substrate/osk.ex` (OSK — Observer State Kernel)
- Scratch harnesses also deleted (untracked, substrate-only):
  `run_{cof,euf,gck,hsv,mcal,oed,opc,ose,osk}_gauntlet.exs`

### Previous behavior (representative, from `ose.ex`)
```elixir
defmodule Tiannara.Substrate.OSE.SelectionEngine do
  ...
  def select(...) do
    Logger.warning("⚠️ [Substrate:OSE] Curation.")
    Tiannara.Metrics.Aggregator.push_event([:tiannara, :ose, :selection_pressure_accuracy], 0.98)
    {:ok, ...}
  end
end
```
Hardcoded metric values (`selection_pressure_accuracy 0.98`,
`niche_formation_success 0.96`, `collapse_probability 0.9`) pushed via
`Aggregator.push_event/2`; functions returned success without input-derived
computation. (See `MC002-A0-LOGIC-INVENTORY.md` for the full per-family table.)

### Evidence of theatrical behavior
- Every family functions as Logger + hardcoded `Aggregator.push_event` with
  no computation over inputs (inventory rows T2..T8; archived module bodies in
  the A0 inventory).
- No supervision tree (module `...Supervisor` does not exist; only string
  `supervisor_path` entries in `runtime_atlas.ex:95-155` reference nonexistent
  `Tiannara.Substrate.*.Supervisor` modules).
- No test files and no `config/` references (verified by source search).
- The RuntimeAtlas strings are documentation-only and do not load modules.

### Callers (production)
- **None.** No module or test in `lib/` or `test/` references any
  `Tiannara.Substrate.*` module at compile time. The only textual references
  were the deleted scratch `run_*_gauntlet.exs` scripts and the
  `runtime_atlas.ex` supervisor-path strings.

### Mutation
All nine files **deleted entirely** (strongest decommission, matching the
MC-001-M precedent in which fabricated-only modules `calculus.ex` /
`formal_verification.ex` were removed from disk). The empty
`lib/tiannara/substrate/` directory was also removed.

### New unavailable semantics
The capability is **Removed** — the modules no longer exist, so a call is an
`UndefinedFunctionError` (an explicit "does not exist" signal) rather than a
fabricated success. No metric is pushed.

### Consumer remediation
- None required (no production or test consumer).
- `runtime_atlas.ex` still lists `Tiannara.Substrate.*.Supervisor` strings as
  documentation entries; documented as deferred technical debt
  `TD-MC002-M-RUNTIME_ATLAS` (out of L2 scope, no behavioral impact).

### Tests
- Static verification in `MC002_M_logic_mutation.py` verifier: the nine files
  do not exist, `Tiannara.Substrate` is not compiled, and no substrate metric
  push literals remain in the aggregator or elsewhere.

### Final disposition
**REMOVED** — nine fabricated subsystem files deleted; no fabricated
success/metric-push remains in the runtime.

---

## Scope-control confirmation (L2/L3)

- No replacement substrate implementation introduced. ✓
- No duplicated logic implementations created. ✓
- No REAL primitive contract changed (`Contradiction.Engine` lifecycle,
  `Sentinel.Verification` evidence-link mechanism, `Epistemic.Debugger`
  queries all preserved). ✓
- No unrelated broad refactoring performed. ✓
- Fabricated metric clauses removed from the aggregator (L3, see M5 ledger). ✓
- Substrate families are unreachable by the running system after deletion. ✓