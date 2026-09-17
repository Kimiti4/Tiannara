# EFDI D4 — Certification

**Gate:** EFDI-D4 · **Verdict: D4_CERTIFIED_BOUNDED** · Date: 2026-09-02

## 1. What was certified

D4 counterfactual / attribution over the canonical substrate (adapter mission): a
first-class status ontology (OBSERVED/HYPOTHETICAL/COUNTERFACTUAL + supported /
underdetermined / invalid / unknown), explicit intervention spec (OBSERVE ≠ SET),
bounded alternative-history bundles, boundary-guarded luck/skill attribution
(NOT_ATTRIBUTED default), survivorship/selection analysis with denominator registry,
non-causal regression-to-mean analysis, and a first-class D4→D3 temporal firewall.
D4 composes the existing substrate (TemporalWorldEngine, MultiWorld, CausalDo,
REA.Causal, ReplayEngine, VersionManager/SnapshotManager, EventStore) — it adds no
new causal/counterfactual engine and no execution surface.

## 2. Verification

Independent no-trust verifier `EFDI_D4_independent_verification.py` (source-scan + live
mix test). All V20–V35 gates and live regression:

```
V20..V35         PASS (16/16)
V_LIVE_REGRESSION PASS
MIX_TEST_TOTAL   300  (D1=92, D2=104, D3=73, D4=31)
MIX_TEST_FAILURES 0
D1_D2_D3_REGRESSION_PRESERVED PRESERVED (269 tests, 0 failures)
OVERALL          D4_CERTIFIED_BOUNDED
```

Full output: `certification/forecasting/verifiers/EFDI_D4_independent_verification_output.json`.

## 3. Bounds (what certification does NOT claim)

- No new causal / counterfactual **engine**; D4 adapts the canonical substrate (REUSE/ADAPTER).
- Status `OBSERVED` is assignable **only** via the D1 ingestion path; D4 can never
  construct or promote a record to OBSERVED.
- Single outcomes are never attributed; default is `:not_attributed`; thresholds carry
  provenance. D4 never infers BAD OUTCOME → BAD DECISION or GOOD OUTCOME → GOOD DECISION.
- Survivorship / selection never silently generalizes over an unknown denominator
  (`UNKNOWN_SELECTION_EFFECT` / `{:error, :denominator_unknown}`).
- Regression-to-mean analysis is non-causal **by construction** (no causal-claim field).
- D3 snapshots are read-only; the D4→D3 temporal firewall is a first-class certification
  property (no D3 writes, hindsight outcomes rejected).
- D4 exposes zero execution interfaces; `Council` remains sole authority, CIS persists,
  AEO the sole executor.
- Noise analysis (D5) and institutional/associative memory (D6) remain **deferred**
  (`status() → deferred: [:noise, :memory]`).

## 4. Interface evolution

D4 adds contract modules (`InterventionSpec`, `CounterfactualRecord`,
`AlternativeHistoryBundle`, `AttributionReport`, `SelectionEffectReport`,
`RegressionToMeanReport`) to `contracts.ex` additively. D1/D2/D3 struct positions and
semantics are unchanged (documented additive exception continues).

## 5. Artefacts

| Artefact | Path |
|----------|------|
| Contract | `certification/forecasting/contracts/EFDI_D4_CONTRACT.md` |
| Authorization | `certification/forecasting/authorization/EFDI_D4_AUTHORIZATION.md` |
| Test matrix | `certification/forecasting/EFDI_D4_TEST_MATRIX.md` |
| Evidence | `certification/forecasting/EFDI_D4_EVIDENCE.json` |
| Verifier | `certification/forecasting/verifiers/EFDI_D4_independent_verification.py` |
| Verifier output | `certification/forecasting/verifiers/EFDI_D4_independent_verification_output.json` |
| Recon | `docs/architecture/EFDI_D4_ARCHITECTURE_RECONNAISSANCE.md` |
| Classification matrix | `docs/architecture/EFDI_D4_CLASSIFICATION_MATRIX.md` |
| Audit | `docs/audit/forecasting/EFDI_D4_AUDIT.md` |
