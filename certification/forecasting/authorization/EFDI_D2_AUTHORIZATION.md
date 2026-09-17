# EFDI D2 — Authorization

**Gate:** EFDI-D2

D2 is authorized as a bounded dependency: immutable, evidence-linked,
explicitly uncertain forecasts that compose existing Tiannara math without
replacing any canonical system.

D2 does NOT authorize:
- Decision-making (D3)
- Confidence as authorization (forecast confidence ≠ CIS authority)
- Fabrication of uniform distributions as "justified"
- Modifying D1 certified contracts beyond additive field extension

## D1 dependency justification (additive contract fields)

D2 extends `Contracts.Forecast`, `Contracts.BaseRate`, and
`Contracts.ForecastRequest` with new fields at the end of the struct list.
The D1 fields (`id`, `question`, `probability`, `distribution`, `uncertainty`,
`evidence_id`, `created_at`, `models`, `disagreement`, `lineage`) remain
unchanged in position and semantics. This is the documented additive exception
per the D1→D2 interface evolution contract.

## Verification procedure

Independent no-trust verifier: `EFDI_D2_independent_verification.py`.
Runs V1–V12; verdict = PASS only if ALL gates pass; otherwise NOT_CERTIFIED.