# MC-002-M5: Metrics Truthfulness Ledger

**Gate:** MC-002-M / L3
**Status:** COMPLETE (authorized aggregator clauses only)
**Date:** 2026-08-29

Documents the removal of fabricated substrate metric-domain clauses from
`Tiannara.Metrics.Aggregator`, the evidence that they only ever collected no-op
pushes from the deleted substrate families, the kept real-emitter clauses, and
the deferred metrics backlog.

---

## M5.1 `Tiannara.Metrics.Aggregator` — substrate fabricated metric clauses

**File:** `lib/tiannara/metrics/aggregator.ex`

### Previous behavior
The aggregator contained nine `handle_cast` clauses that matched
`[:tiannara, <domain>, metric]` paths for the substrate-only domains
`:euf, :gck, :hsv, :mcal, :opc, :oed, :ose, :osk, :cof`, each returning
`{:noreply, state}` (a no-op). These clauses existed solely to swallow the
fabricated metric pushes emitted by the (now deleted) substrate modules, e.g.
`[:tiannara, :ose, :selection_pressure_accuracy] 0.98`.

### Evidence of fabrication
- Every metric name in the removed clauses is a fabricated no-op domain that
  never observed real state (see `MC002-A0-LOGIC-INVENTORY.md` / M3 ledger).
- The cloned clauses are self-referential: the emitter and the consumer of
  these events have now been deleted together.
- A fallback `handle_cast({:telemetry_event, _event, _value}, state) ->
  {:noreply, state}` (aggregator.ex:178) already swallows any unmapped path,
  so removal cannot crash the aggregator.

### Mutation
The nine no-op clauses for `:euf, :gck, :hsv, :mcal, :opc, :oed, :ose, :osk,
:cof` were removed. The clauses for **real emitters are retained**:
- `:coherence` (`lib/tiannara/coherence/coherence.ex` — real emitter)
- `:iv` (`lib/tiannara/interaction_validation.ex` — real emitter)
- `:ctl`, `:ocm`, `:twp`, `:cis`, `:mirror`, `:forecasting`, `:governance`,
  `:discovery`, `:archaeology`, `:grcc`, `:orbit`, `:research`, `:domain`
  (real subsystem paths retained, outside this gate's scope).

### New unavailable semantics
Fabricated substrate metric paths are **Removed** — no clause accepts or
relays them. Any stray push of a fabricated path now reaches the truthful
fallback no-op or would be a compile-time failure of the emitter (emitters no
longer exist), distinguishing "no evidence" from "claim".

### Consumer remediation
- None required — `push_event/2` still accepts the same event-tuple interface
  and the fallback clause guarantees the GenServer never crashes on unmapped
  events.

### Tests
- `test/tiannara/metrics/` suite (passing) exercises the aggregator via
  `push_event`/`get_snapshot`; the removal is verified statically by the
  `MC002_M_logic_mutation.py` verifier (no substrate metric literals remain).

### Final disposition
**REMOVED** — fabricated substrate metric clauses deleted; real-emitter
clauses preserved.

---

## Deferred metrics backlog

- `TD-MC002-M-RUNTIME_ATLAS`: `runtime_atlas.ex:95-155` still lists
  `Tiannara.Substrate.{OSK,OED,OSE,OCM,CTL,TWP}.Supervisor` strings as
  documentation entries for non-existent modules. Strings only; no module is
  compiled or supervised. Requires a separate authorized pass to convert the
  atlas to truthful registry entries.
- `TD-MC002-M-AGGREGATOR_CLONES`: the many remaining `handle_cast` no-op
  clauses for real-but-unverified subsystems (twp/cis/mirror/forecasting/
  governance/discovery/archaeology) are outside this gate's metric scope and
  tracked under MC-003/MC-004. Keep-move decision documented here so the
  bounded L3 scope is explicit.