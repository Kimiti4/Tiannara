# EFDI-FA-001 Calibration Batch — Final Report

> status: **COMPLETE (N=100)** | generated 2026-09-17T13:27:06.345Z Z
> authorization: EFDI_FA_001_CAL_BATCH_2026-09-14_A01 (measurement-only scope; no config/model/promotion/certification changes)
> frozen config sha256: 95fddceb537dc0d964ccf097167855f4ea483fbb7f1a8d37760863cf5772367b
> frozen evidence inventory sha256: 2271735ca1c791077c745cd8eb0e2b13e4a87a3b0cf12e0b72f9d692ddc4f12d (50 NBO hour-buckets; EVIDENCE_INVENTORY_CALIBRATION.json)

## 1. Pooled metrics (all decisions combined, out-of-sample)

| Pool | N | Brier (lower=better) | Log loss (lower=better) | Brier vs B6 (issued) | Directional acc % |
|---|---:|---:|---:|---:|---:|
| ALL (BTC+NBO) | 100 | 0.1932 | 0.5685 | 0.1932 | 69 |
| BTC5M only | 50 | 0.2496 | 0.6924 | 0.2496 | 54 |
| NBO60M only | 50 | 0.1368 | 0.4445 | 0.1368 | 84 |

## 2. Baseline comparison (per-domain, B6=issued model probabilities)

[B0] BTC: b=0.25 ll=0.6931 dir=0% | NBO: b=0.25 ll=0.6931 dir=4% | n=50/50
[B1] BTC: b=0.25 ll=0.6931 dir=0% | NBO: b=0.0505 ll=0.2319 dir=96% | n=50/50
[B2] BTC: b=0.485 ll=0.0139 dir=50% | NBO: b=0.0197 ll=0.102 dir=98% | n=50/50
[B3] BTC: b=0.25 ll=0.6931 dir=0% | NBO: b=0.362 ll=1.0721 dir=56% | n=50/50
[B4] BTC: b=0 ll=0 dir=0% | NBO: b=0.3085 ll=0.8749 dir=58% | n=0/50
[B5] BTC: b=0.2496 ll=0.6924 dir=54% | NBO: b=0.1368 ll=0.4445 dir=84% | n=50/50
[B6] BTC: b=0.2496 ll=0.6924 dir=54% | NBO: b=0.1368 ll=0.4445 dir=84% | n=50/50

## 3. Calibration/reliability (issued P vs realized frequency, per domain)

BTC: all 50 legs issued frozen P(UP)=0.505 / P(DOWN)=0.495 (one fixed bin).

| Domain | Bin | N | Mean issued P(class) | Realized freq(class) |
|---|---:|---:|---:|---:|
| BTC5M | P(UP)=0.505 | 50 | 0.5050 | 0.5400 |

NBO: issued P(YES)=0.15+0.5*(ppb-0.15) per leg (frozen ppb); bin by issued P(YES) rounded to nearest 0.05.

| NBO60M | issued P(YES) bin | N | Mean issued P(YES) | Realized freq YES |
| NBO60M | 0.10 | 12 | 0.0858 | 0.1667 |
| NBO60M | 0.15 | 3 | 0.1483 | 0.0000 |
| NBO60M | 0.20 | 2 | 0.2025 | 0.0000 |
| NBO60M | 0.25 | 10 | 0.2400 | 0.0000 |
| NBO60M | 0.30 | 4 | 0.2963 | 0.0000 |
| NBO60M | 0.35 | 2 | 0.3575 | 0.0000 |
| NBO60M | 0.40 | 4 | 0.4050 | 0.0000 |
| NBO60M | 0.45 | 3 | 0.4583 | 0.0000 |
| NBO60M | 0.50 | 8 | 0.4981 | 0.0000 |
| NBO60M | 0.55 | 2 | 0.5400 | 0.0000 |

## 4. Sample composition / abstention

- Total issued (pre-registered): 100 = 50 BTC5M + 50 NBO60M
- Resolved at generation time: 100 (50 BTC, 50 NBO)
- East-west outcome split: BTC UP=27 DOWN=23 | NBO YES=2 NO=48
- Abstentions: 0 (no leg was skipped; the 5m BTC legs have no FLAT tier and every NBO window had METAR coverage in-scan at resolution time)

## 5. Interpretation & limitations

- BTC legs were issued at frozen P(UP)=0.505/P(DOWN)=0.495 (near-coin neutral tilt by design for a low-predictability 5m horizon); pooled near-coin Brier ≈ 0.25 is expected and the batch's purpose is to AUDIT that claim out-of-sample, not to show skill.
- NBO legs were issued P(YES)=0.15+0.5*(ppb-0.15) clamped [0.02,0.98] from the FROZEN open-meteo cutoff, resolved against live HKJK METAR (primary) — B4 (frozen open-meteo probability) and B6 (issued) comparisons are the informative contrast for the weather side.

### NBO baseline reading (N=50, Brier, lower=better)

- B6 (issued) = 0.1368 vs B1 (climatology 0.15) = 0.0505 and B2 (persistence) = 0.0197: the issued probabilities did NOT beat the naive baselines. With 48/50 NO and 2/50 YES, realized YES frequency (4%) sat below the locked climatology (15%) and below most issued P(YES) (0.10–0.55 across bins). The model was structurally over-forecasting rain in this dry phase — a calibration signal, delivered by the batch's baseline framework as designed.
- B3 (openmeteo mm>=0.1 flat P_pred=0.9) = 0.362 and B4 (frozen open-meteo prob) = 0.3085 were both worse than B6 and B1: the frozen open-meteo precipitation probability series was itself poorly calibrated on this dry stretch, which propagates into the issued rule P(YES)=B1+0.5*(ppb-B1).
- The reliability table (sec 3) shows issued P(YES) in [0.15,0.55] with realized YES freq 0% across every bin; only the P(YES)~0.08-0.10 bin showed any realized YES (2/12).

### BTC baseline reading (N=50, Brier, lower=better)

- B6 (issued, P(UP)=0.505) = 0.2496 vs B0/B1 coin = 0.2500: statistically indistinguishable from a fair coin, exactly as the frozen neutral-tilt design intended for the low-predictability 5m horizon. Realized UP=54% vs issued 50.5% — a small positive tilt but within sampling noise (95% CI on 50 up/down ~ ±13.6pp). No reliable directional skill claim is supported; the batch measures calibration, and BTC calibration ≈ coin is the honest audit outcome.

- Single-window scores are low-information; aggregated reliability above is the audit quantity. N<30 per finer bucket: treat per-bucket estimates as marginal.
- Measurement only. Nothing here authorizes config/model changes, promotion, or production deployment (see authorization scope).
> Ledger VERIFY at N=100: PASS.
> Not certified by this batch: N=100 out-of-sample resolution supplies validation evidence for review but does not itself certify production use.
