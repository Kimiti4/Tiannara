# EFDI D3 — Pre-Mortem

## 1. Purpose

A structured "assume it failed, why?" analysis performed **before** the decision is
authorized. It converts risk model arithmetic into a decision posture.

## 2. API

- `run(alternative, risk_threshold \\ 0.7)` → `%{alternative_id, blocked?, failure_modes,
  high_risk, risk_threshold}`.
- `run_all(alternatives, risk_threshold \\ 0.7)` → one result per alternative.
- `posture(results, hard_threshold \\ 0.9)` →
  `:proceed | {:require_info, [evidence, ...]} | :block`.

Failure modes carry `description`, `likelihood`, and `mitigation`. An alternative is
`blocked?` when any failure-mode likelihood exceeds the configured `risk_threshold`.

## 3. Sources of failure modes

- `:unknown` distribution → high likelihood (0.9) — acting on unknown probability.
- Irreversible commitment → high likelihood (0.9); documented assets at risk (0.5).
- Negative-utility outcomes → moderate likelihood (0.5).

## 4. Boundary

Pre-mortem is a **decision-support** posture. It informs authorization but never grants it.
At the adapter, a `:block` posture must be reflected before `Council.authorize/3`, and the
Council retains final authority (V13, V15).