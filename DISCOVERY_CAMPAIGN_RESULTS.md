# Discovery Campaign Results

Status: **REQUIRED SYNTHETIC SCALE EXECUTED; EMPIRICAL GOVERNANCE CAMPAIGNS PENDING**

## Repository evidence reviewed

`scripts/phase15_validation_campaign.exs` executed the refined validation scales on 2026-07-05. The legacy `run_discovery_gauntlet.exs` remains a smoke demonstration and is not used as evidence.

| Required campaign | Required scale | Verified completed scale | Gate |
|---|---:|---:|---|
| Observation replay | 1,000,000 | 1,000,000 deterministic cases | PASS |
| Experiment replay | 100,000 | 100,000 deterministic cases | PASS |
| Hypothesis validation | 100,000 | 100,000 synthetic cases | PASS |
| Scientific experiments | 10,000 | 10,000 synthetic cases | PASS |
| Constitutional fundamentals | 100,000 empirical experiments | Synthetic mechanism coverage only | BLOCKED |
| Long-horizon governance | 1,000 100-year histories | Deterministic aggregate model only | BLOCKED |
| Civilization stability | 10,000 counterfactual histories | Not executed | BLOCKED |

Replay roots and aggregate results are retained in `PHASE15_VALIDATION_CAMPAIGN.json`; the runner deterministically regenerates every case. This establishes mechanism scalability and replayability, not the truth of candidate governance laws.

## Required result bundle

Each campaign must publish its preregistration, seed set, environment fingerprint, event ledger, exclusions, summary statistics, confidence intervals, effect sizes, replay roots, contradiction register, and independent verifier output.
