# EFDI D4 — Authorization

**Gate:** EFDI-D4

D4 is authorized as a bounded **adapter** mission: counterfactual / attribution
analysis that composes Tiannara's existing canonical substrate
(TemporalWorldEngine, MultiWorld, CausalDo, REA.Causal, ReplayEngine,
VersionManager/SnapshotManager, Executive EventStore). The genuinely-NEW surface is
limited to: the status ontology, bounded luck/skill attribution, survivorship /
denominator registry, regression-to-mean analyzer, and the D4→D3 temporal firewall.

D4 does NOT authorize:
- **A new causal/counterfactual engine** — D4 REUSES/ADAPTS the canonical substrate;
  it adds no new causal engine, no new probability system, no new authorization
  mechanism.
- **Autonomous execution** — D4 exposes zero execution interfaces; AEO remains the
  sole executor.
- **Authorization itself** — D4 does not bypass `Council.authorize/3`; CIS retains
  authority.
- **Status fabrication** — `:observed` is assignable only via the D1 ingestion path;
  D4 can never construct or promote a record to `:observed`.
- **Unbounded attribution** — single outcomes are never attributed; default is
  `:not_attributed`; thresholds carry provenance; no BAD/GOOD outcome inference.
- **Silent generalization** — unknown-denominator selection yields first-class
  `UNKNOWN_SELECTION_EFFECT` (no speculative generalization).
- **Causal RTM claims** — regression-to-mean is non-causal by construction.
- **D3 mutation** — D3 snapshots are read-only; the D4→D3 temporal firewall is a
  certification property, not a runtime bypass.
- **D5 noise / D6 memory** — both remain deferred.

## Additive contract extension justification

D4 adds new contract modules (`InterventionSpec`, `CounterfactualRecord`,
`AlternativeHistoryBundle`, `AttributionReport`, `SelectionEffectReport`,
`RegressionToMeanReport`) to `contracts.ex`. D1/D2/D3 fields remain unchanged in
position and semantics. This continues the documented additive interface-evolution
exception.

## Verification procedure

Independent no-trust verifier: `EFDI_D4_independent_verification.py`.
Runs V20–V35 + live regression (D1+D2+D3+D4); verdict = `D4_CERTIFIED_BOUNDED` only
if ALL gates pass and D1-D3 regression (269) is preserved; otherwise the established
non-certified vocabulary applies (NOT_CERTIFIED).
