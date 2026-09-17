# ASC-AE-001 — D1 Statistical Verification Addendum

**Verdict: FAIL_BELOW_GATE**

The original C6 verdict (ACCEPT, first-PASS rule) is preserved unchanged.
This addendum answers one question: *Does D1 reliably satisfy the declared
gate under repeated measurement?*

## Statistics
- Median improvement: **-24.39%**
- 95% CI: [-48.78%, -19.608%]
- Baseline p50 median: 0.41 ms | Candidate p50 median: 0.61 ms
- p95 (median of per-run p95): baseline 0.61 ms | candidate 0.72 ms
- Memory: 47.0 MB -> 47.0 MB (delta 0%)


## Paired rounds
| Round | Order | Baseline p50 (ms) | Candidate p50 (ms) | Improvement |
|---|---|---|---|---|
| 1 | [:baseline, :candidate] | 0.61 | 0.72 | -18.03% |
| 2 | [:candidate, :baseline] | 0.72 | 0.61 | 15.28% |
| 3 | [:baseline, :candidate] | 0.41 | 0.82 | -100.0% |
| 4 | [:candidate, :baseline] | 0.51 | 0.51 | 0.0% |
| 5 | [:baseline, :candidate] | 0.51 | 0.72 | -41.18% |
| 6 | [:candidate, :baseline] | 0.41 | 0.51 | -24.39% |
| 7 | [:baseline, :candidate] | 0.41 | 0.51 | -24.39% |
| 8 | [:candidate, :baseline] | 0.41 | 0.51 | -24.39% |
| 9 | [:baseline, :candidate] | 0.41 | 0.61 | -48.78% |
| 10 | [:candidate, :baseline] | 0.41 | 0.61 | -48.78% |
| 11 | [:baseline, :candidate] | 0.41 | 0.61 | -48.78% |
| 12 | [:candidate, :baseline] | 0.41 | 0.61 | -48.78% |
| 13 | [:baseline, :candidate] | 0.41 | 0.61 | -48.78% |
| 14 | [:candidate, :baseline] | 0.51 | 0.61 | -19.61% |
| 15 | [:baseline, :candidate] | 0.41 | 0.51 | -24.39% |

## Interpretation
- ROBUST_PASS -> eligible for human merge review (human authorizes merge; ASC never merges).
- INSUFFICIENT_EVIDENCE -> merge held; recorded as "passed original gate, insufficient statistical evidence for adoption."
- FAIL_BELOW_GATE / FAIL_MEMORY / FAIL_CORRECTNESS -> candidate rejected under repeated measurement; lineage preserved.
