# EFDI Signal Value

**Phase:** D1 — Signal Intelligence
**Module:** `Tiannara.Forecasting.SignalValue`

## 1. Purpose

`SignalValue.measure/2` assesses how much a signal is worth for the downstream
pipeline: its predictive value, information gain, redundancy with existing
signals, and marginal (incremental) value.

## 2. Outputs

| field | meaning |
|-------|---------|
| `predictive_value` | how predictive the signal is for an outcome |
| `information_gain` | entropy reduction from absorbing the signal |
| `redundancy` | overlap with existing signals |
| `marginal_value` | incremental value given the existing set |
| `assessment_basis` | which inputs were actually measured |

Each numeric field is `[0,1]` or `:unknown`.

## 3. D1 behavior

In D1, outcomes do not yet exist (forecasting is D2). Therefore:

- `predictive_value` and `information_gain` **against outcomes** return
  `:unknown`. Fabricating a value where no outcome has occurred would violate
  the honesty invariant.
- `redundancy` against an **empty** existing set returns `:unknown`.
- `Correlation` provides the raw redundancy/redundancy-index machinery used
  (with `SignalValue`'s guard rails) once a set exists.

## 4. Relationship to Correlation

`Correlation` computes:
- `shares_origin?/2` — same source, shared lineage, or identical content hash
- `correlation/2` — vector/cosine similarity
- `redundancy_index/1` — aggregate overlap over a set
- `redundant_with/2` — are two signals mutually redundant

`SignalValue.measure/2` combines these into the marginal-value view while
keeping D1's no-fabrication guard.

## 5. Guard rails

- Unknown inputs produce `:unknown`, never a guessed number.
- Scalars / non-comparable observations yield `:unknown` redundancy (not
  fabricated).
- Missing provenance does not crash measurement and does not falsely report
  integrity.
