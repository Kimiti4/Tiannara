# EFDI D3 — Authorization

**Gate:** EFDI-D3

D3 is authorized as a bounded dependency: immutable, hindsight-isolated decision
intelligence that composes existing Tiannara authority (Council), execution (AEO /
Executive Command), immune monitoring (CIS), and research (Research Director)
without replacing any canonical system.

D3 does NOT authorize:
- **Authorization itself** — D3 recommends; only `Council.authorize/3` authorizes.
  The adapter returns `{:error, :authorization_unavailable}` when the Council runtime
  is absent; authorization is never fabricated (V15).
- **Execution** — execution flows through `AEO.submit_to_runtime` /
  `Executive.Command` at the adapter only after authorization (extend at boundary).
- **Immunity overrides** — CIS retains authority to constrain/block/modify/require
  evidence (V17).
- **Research as permission** — `to_research_priorities` requests information; it
  never grants permission to act (V16).
- **Luck/skill attribution** — postmortem attribution is frozen to `:not_attributed`
  (D4 territory, deliberately deferred).

## D2 dependency justification (additive contract fields)

D3 adds new contract modules (`Alternative`, `DecisionRequest`, `Decision`,
`DecisionOutcome`) to `contracts.ex`. D1/D2 fields remain unchanged in position and
semantics. This continues the documented additive interface-evolution exception.

## Verification procedure

Independent no-trust verifier: `EFDI_D3_independent_verification.py`.
Runs V1–V19 + live regression; verdict = `CERTIFIED_BOUNDED` only if ALL gates pass;
otherwise the established non-certified vocabulary applies (NOT_CERTIFIED).