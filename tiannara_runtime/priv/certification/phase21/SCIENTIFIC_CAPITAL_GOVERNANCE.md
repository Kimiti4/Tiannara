# Scientific Capital Governance (Phase 21.0)

## Purpose

Define the governance framework for scientific capital — the currency of the research civilization. Scientific capital measures and governs resource allocation for all research activities.

## Capital Components

Scientific capital is computed from seven components:

| Component | Weight | Description | Measurement |
|-----------|--------|-------------|-------------|
| Reproducibility | 0.20 | Results independently reproducible | Replay verification count |
| Impact | 0.20 | Citations, reuse, derivative work | Citation chain depth |
| Novelty | 0.15 | Original contribution | Prior art distance |
| Cross-domain influence | 0.15 | Applicability across domains | Domain adoption count |
| Engineering utility | 0.10 | Practical engineering value | Engineering artifact references |
| Mathematical depth | 0.10 | Mathematical sophistication | Proof complexity measure |
| Scientific longevity | 0.10 | Enduring relevance | Time since discovery still cited |

## Capital Formula

```
scientific_capital = Σ(weight[i] × normalized_score[i])
```

All scores are normalized to 0.0–1.0. Capital is tracked per institute, per program, and per discovery.

## Capital Lifecycle

```
Discovery → Capital Assessment → Capital Award → Capital Pool → Reinvestment
                                                                       ↓
                                                              New Programs / Missions
```

## Capital Governance Rules

1. Capital is awarded deterministically based on discovery characteristics
2. Capital cannot be created or destroyed outside constitutional process
3. Capital pools are managed per institute
4. Reinvestment prioritizes programs with highest capital efficiency
5. Capital allocation is reviewed at each generation boundary
6. All capital transactions are recorded in the Scientific Capital Ledger

## Capital Ledger

The Scientific Capital Ledger (`SCIENTIFIC_CAPITAL_LEDGER_SCHEMA.json`) records:
- All capital entries and deltas
- Per-institute capital balances
- Per-program capital allocation
- Discovery capital awards
- Reinvestment decisions
- Ledger hash for integrity verification
