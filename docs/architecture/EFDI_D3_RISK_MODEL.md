# EFDI D3 — Risk Model

## 1. Per-alternative risk

For an alternative with decision-time distribution `p` and utilities `u`:

- `expected_value = Σ pᵢ·uᵢ`
- `variance = Σ pᵢ·(uᵢ − EV)²`
- `stddev = √variance`
- `risk_score` ∈ [0,1]: blends the coefficient of variation with reversibility:
  - irreversibility carries `risk_score = 1.0` for determinate EV (highest exposure),
  - otherwise `base = min(1.0, |stddev|/|EV|)` (or `stddev` when EV = 0)
    plus a reversibility penalty (`:partially_reversible → +0.5`, `:reversible → +0.0`),
    capped at `1.0`.

`:unknown` distributions propagate to EV → variance → stddev → risk as `:unknown`.
The engine never replaces unknown risk with a fabricated number.

## 2. Pre-mortem posture (PreMortem)

`run/2` identifies failure modes per alternative with likelihood and mitigation.
Likelihood bands: `:unknown` distribution → 0.9; irreversible commitment → 0.9;
assets at risk → 0.5; negative-utility outcomes → 0.5.

`posture/2` over the alternative set returns:
- `:proceed` — no alternative blocked,
- `{:require_info, [...]}` — blocked alternatives exist but below the hard threshold,
- `:block` — a high-likelihood failure mode exists.

Pre-mortem is an **input to** the decision and authorization flow; it never authorizes by itself.

## 3. Reversibility

`Alternative.reversibility`: `:reversible | :partially_reversible | :irreversible`.
Reversibility informs `risk_score`, pre-mortem likelihood, and postmortem framing.
It is evaluated at decision time — rollback feasibility may change later, but the risk
memo reflects the decision-time belief.