# TCP-002.5 — Outcome Integrity, Independent Verification, and Durable Forecast Resolution

**Checkpoint:** TCP-002.5
**Workstream:** W0 — Activate Existing Capabilities
**Baseline:** `367036321659f91562c469ba3f36fe0c3b5142b4`
**Status:** **PARTIAL** — Stages 0–3 and 9 delivered against real durable implementations; Stages 4–8 and 10–13 open.

---

## 1. Executive disposition

| Stage | Status | Reason |
|-------|--------|--------|
| 0 — Baseline | **PASS** | Baseline pinned; the three pre-existing untracked files preserved; the canonical implementations mapped |
| 1 — Event ordering (TCP-B-057) | **PASS** | Sequence numbers, chain linkage, origin establishment and gap detection, proven against real files on disk |
| 2 — Record integrity (TCP-B-058) | **PARTIAL** | Per-record SHA-256 digest and previous-digest chain linkage, verified on append and recovery; **authenticity is not established and is not claimed** |
| 3 — Typed horizon (TCP-B-059) | **PARTIAL** | Typed, validated, persisted, immutable horizon; **the canonical resolution path does not yet read it**, so enforcement at resolution is not proven |
| 4 — Observation binding (TCP-B-060) | **OPEN** | Not started |
| 5 — Real source acquisition | **BLOCKED** | No live external source is reachable from this environment |
| 6 — Independent verification | **OPEN** | Not started |
| 7 — Temporal resolution | **OPEN** | The canonical `OutcomeResolution` is unchanged and unused by any caller |
| 8 — Durable outcome | **OPEN** | Not started |
| 9 — Scoring | **PASS (implementation)** | Canonical `Calibration.score/2` verified against independently calculated vectors; **no eligible resolved forecast exists to score** |
| 10 — Calibration readiness | **OPEN** | Depends on 6–9 |
| 11 — Spine / transport | **PARTIAL** | The Spine's confidence/probability separation holds; the NATS transport remains unexecuted |
| 12 — End-to-end lifecycle | **PARTIAL** | The lifecycle is demonstrated to `FORECAST_REGISTERED`; no observation exists |
| 13 — Evidence / register | **PASS** | This report, the manifest and the append-only register update |

**Overall: `IMPLEMENTED_WITH_PARTIAL_EVIDENCE` / `VERIFICATION_BLOCKED`.**

Per the directive's own guidance, this checkpoint closes the integrity and
contract defects **where proven**, and leaves the lifecycle at its last
evidence-supported state.

## 2. The decisive architectural fact

Two source facts shaped everything below.

**The forecast lifecycle's temporal guard is not `TemporalFirewall`.**
`TemporalFirewall.verify/3` operates on `Decision`, `DecisionSnapshot` and
decision artefacts. The forecast lifecycle's temporal isolation lives in
`Tiannara.Forecasting.Outcome` (`hindsight_clean?/2`, `guard!/2` →
`{:error, :hindsight_contamination}`). Using `TemporalFirewall` for forecasts
would have meant building a second time validator.

**`Calibration.score/2` is numerically correct under a documented convention.**
It selects the probability of the *realised* outcome and encodes that outcome
as `y = 1`, so Brier is `(p − 1)²` and log loss is `−ln p`. Under the
multi-outcome convention the Brier score would additionally include the
`p_i²` terms of the non-realised outcomes. The implementation is therefore
correct for a binary forecast and its convention is now **documented and
pinned by independent known-answer vectors** rather than left ambiguous.

## 3. What was implemented

### 3.1 Stage 1 — deterministic ordering (TCP-B-057)

The durable event log previously had **no ordering identity at all**: frames
were `<<size, payload>>` and the parser stopped silently at the first frame it
could not read.

The frame format is now versioned:

```
<<"EFD2", size::32, sequence::64, digest::32, previous_digest::32, payload::binary>>
```

* `sequence` — assigned by the store at append time. It is **append order**,
  not delivery order; a caller cannot choose it.
* `previous_digest` — the preceding record's digest, binding the history into
  a chain.
* The first record must be sequence `1`. If the log's origin is wrong, **no
  later record can establish one either**: the ordering of the whole log is
  unestablished and nothing is applied.

### 3.2 Stage 2 — record integrity (TCP-B-058)

* Each record carries a SHA-256 digest over a canonical, versioned
  representation of `(sequence, previous_digest, payload)`.
* The digest is verified on **append** and on **recovery**.
* `EventStore.stream_verified/0` returns only records whose integrity *and*
  ordering could be established, together with counts of unreadable frames,
  integrity failures, sequence gaps and legacy records.
* `Tiannara.Forecasting.Integrity` provides the canonical digest helpers and
  states the limit explicitly: **a digest establishes integrity, not
  authenticity.** Anyone with write access to the log can recompute it. No
  signature is claimed, and the assurance level is stated rather than implied.

**Legacy compatibility.** A legacy frame has no sequence and no digest. It is
read and reported as `unverified_legacy`; it is **never** presented as
integrity-verified, and it remains visible to the plain `stream/0` so that
existing consumers do not silently lose history.

### 3.3 Stage 3 — typed horizon (TCP-B-059)

`Contracts.Horizon` is the enforceable temporal contract:

| Field | Meaning |
|---|---|
| `start_at` | the beginning of the target period, UTC-normalised |
| `end_at` | the end of the target period, and the resolution deadline |
| `policy` | `:closed` — only evidence published within the period may resolve; `:open` — later publication may resolve if it attests an in-period event |
| `label` | explanatory text. **Never used to decide eligibility.** |
| `version` | the horizon contract version |

A free-text horizon is no longer sufficient: the bridge requires
`horizon_start` and `horizon_end`. The horizon is persisted inside the
registered forecast, is covered by the forecast's outcome-definition digest,
and is therefore immutable with the forecast.

A forecast registered before this contract existed has no typed horizon. It
remains readable and auditable, and it is **not eligible** for normal
resolution — the compatibility policy is explicit rather than implicit.

**What is not yet proven.** The horizon is validated, persisted and immutable,
but the canonical resolution path (`OutcomeResolution`) does not yet read it.
Enforcement at resolution is therefore **not** demonstrated, and TCP-B-059 is
recorded as partial, not closed.

### 3.4 Stage 9 — scoring verified against independent vectors

`Calibration.score/2` is unchanged and is reused as the canonical
implementation. `horizon_contract_test.exs` pins it against hand-calculated
vectors:

| Case | Expected | Source |
|---|---|---|
| Brier, p = 0.7, "yes" realised | 0.09 | `(0.7 − 1)²` |
| Brier, p = 0.3, "no" realised | 0.49 | `(0.3 − 1)²` |
| Log loss, p = 0.7 | 1.2039728043259361 | `−ln(0.7)` |
| Log loss, p = 0.3 | 1.2039728043259361 → `−ln(0.3)` | `−ln(0.3)` |
| Log loss at p = 1.0 | `:unknown`, `sample_size: 0` | the implementation's documented boundary convention |

The vectors are computed from the formula in the test, not from the
implementation, so this is a known-answer test rather than a self-consistency
check.

## 4. Findings

### TCP-B-057 — out-of-order event delivery

* **Original condition.** the durable log had no sequence number, no chain and
  no origin; the parser stopped silently at the first unreadable frame.
* **Source change.** `lib/tiannara/executive/event_store.ex` — versioned frame
  envelope, sequence assignment at append, chain linkage, origin establishment,
  gap and break detection; `stream_verified/0` exposes only established
  records; the registry consumes only those.
* **Regression test.** `test/tiannara/forecasting/event_store_integrity_test.exs`
  — 11 tests.
* **Result.** 11 tests, 0 failures. Sequence gap, out-of-order delivery,
  duplicate delivery, middle-record removal, payload modification, digest
  modification, truncation and legacy records are each proven **not to be
  applied**, with the exact expected state preserved.
* **Remaining limitation.** the store is a single-writer append-only file; it
  does not support concurrent writers, and the digest chain is an integrity
  mechanism, not an authenticity mechanism.
* **Disposition.** **RESOLVED** for ordering and chain integrity.

### TCP-B-058 — record-level integrity

* **Original condition.** no per-record digest; `Event.from_binary/1` used an
  unsafe `binary_to_term` that could construct executable terms from a
  tampered log.
* **Source change.** `EventStore.record_digest/3` and the frame envelope;
  `Event.from_binary/1` now uses `[:safe]`; `Tiannara.Forecasting.Integrity`
  provides the canonical digest helpers and documents the integrity versus
  authenticity distinction.
* **Regression test.** the same 11 tests, plus the payload- and digest-alteration
  cases.
* **Result.** 11 tests, 0 failures. A modified payload, a modified digest, a
  removed middle record and a truncated tail are each detected and **not
  applied**; the registry reports `recovery_failures` and `durable: false`.
* **Remaining limitation.** **authenticity is not established.** A digest
  detects change; it does not prove who wrote the record. No trusted anchor
  exists outside the storage boundary, so a wholesale replacement of the log
  with recomputed digests would not be detected. This is stated in the module
  documentation and must not be reported as signature verification.
* **Disposition.** **PARTIAL** — integrity established and verified;
  authenticity not established and not claimed.

### TCP-B-059 — enforceable forecast horizon

* **Original condition.** the horizon was free text and could not be enforced.
* **Source change.** `Contracts.Horizon` (typed, validated, UTC-normalised,
  digest-bound); the bridge requires it; the forecast carries it and its
  outcome-definition digest; the research adapter builds it from the forecast
  specification.
* **Regression test.** `test/tiannara/forecasting/horizon_contract_test.exs` —
  23 tests covering construction, refusal reasons, temporal eligibility,
  publication policy under `:closed` and `:open`, digest stability, and the
  canonical scoring vectors.
* **Result.** 23 tests, 0 failures.
* **Remaining limitation.** **the resolution path does not yet enforce the
  horizon.** `OutcomeResolution` is unchanged and reads no typed horizon, so
  a resolution could still be made against a forecast whose window has
  elapsed. Enforcing it requires Stage 4's observation contract and Stage 7's
  temporal work.
* **Disposition.** **PARTIAL** — the contract is typed, validated, persisted and
  immutable; enforcement at resolution is not yet proven.

### TCP-B-060 — observation binding

* **Original condition.** `Tiannara.Forecasting.Outcome` carries
  `{id, forecast_id, observed_outcome, observed_at, source}`. It has no
  forecast digest, no outcome-definition digest, no horizon reference, no
  event/publication/acquisition timestamps, no evidence digest and no
  verification status. There is no observation record at all.
* **Status.** **OPEN** — not started in this checkpoint.
* **Disposition.** **OPEN.**

## 5. Actual lifecycle evidence

The furthest genuinely proven state:

```
FORECAST_REGISTERED
```

- **Proven.** A research input with an explicit forecast specification
  produces a probabilistic forecast through the supervised Research Director,
  registered with the canonical EFDI authority, persisted to the durable log
  with a sequence number, a digest and a chain link, and recoverable after a
  restart with identical canonical fields.
- **Not proven.** `OBSERVATION_ACQUIRED`, `OUTCOME_VERIFIED`,
  `OUTCOME_RESOLVED`, `FORECAST_SCORED`, `CALIBRATION_ASSESSED`.

There is **no real-world predictive performance claim of any kind** in this
checkpoint. The scoring implementation is verified against independent
vectors; it has not been applied to an eligible resolved forecast, because no
such forecast exists.

## 6. Test results

| Suite | Command | Seed 0 | Seed 123456 |
|-------|---------|--------|--------------|
| Application forecasting + research | `MIX_ENV=test mix test test/tiannara/forecasting test/tiannara/research --no-deps-check` | **491 tests, 0 failures** | 491 tests, 0 failures |
| Runtime regression | `MIX_ENV=test mix test test/simulation test/runtime_layers test/kernel test/cognitive test/world_model --no-deps-check` (cwd `tiannara_runtime`) | **792 tests, 32 properties, 0 failures** | 792 tests, 32 properties, 0 failures |

New suites in this checkpoint: `event_store_integrity_test.exs` (11 tests) and
`horizon_contract_test.exs` (23 tests).

**Not executed:** the NATS transport (no NATS server is available in this
environment). It is compiled and its absent-authority behaviour is covered by
the refusing default. No mocked transport evidence is reported as real
transport execution.

**Environment.** PostgreSQL is running but its databases were not required by
the suites in this checkpoint. The durable log was exercised against real
files under an isolated temporary directory in every durability test.

## 7. Residual risks and blockers

| Item | State |
|---|---|
| TCP-B-046 — cross-stack compile-time boundary | **OPEN**, unchanged |
| TCP-B-048 — outcome acquisition | **OPEN**, unchanged; no live source reachable |
| TCP-B-050 — adversarial persistence suite | **RESOLVED**, preserved and extended |
| TCP-B-056 — hardcoded pseudo-measurements | **OPEN**, unchanged and visible |
| TCP-B-057 — event ordering | **RESOLVED** |
| TCP-B-058 — record integrity | **PARTIAL** — integrity yes, authenticity no |
| TCP-B-059 — typed horizon | **PARTIAL** — contract yes, enforcement at resolution no |
| TCP-B-060 — observation binding | **OPEN** |
| NATS transport | compiled, unexecuted |
| D6 institutional forecasting memory | deferred |
| Calendar outcome-definition digest | computed over the question, outcome space and typed horizon |
| Duplicate `Contracts.Horizon` definitions | removed |
| Concurrent writers to the durable log | unsupported; single-writer append only |
| Trusted integrity anchor | absent; a wholesale log replacement with recomputed digests would not be detected |

## 8. Governance confirmation

* `Tiannara.Forecasting.ModelUpdateGate` — **unchanged**. It still returns
  `authority: :none`, `authorization: :not_granted`,
  `deployment: :not_granted`, `production_mutation: :forbidden`,
  `human_review_required: true`, `certification_eligible: false`.
* Human-review and constitutional controls — **intact**. No gate was weakened.
* No production mutation, deployment, registry promotion or physical actuation
  occurred.
* The three pre-existing untracked files were **preserved** and not staged.
* `RL-565` remains `HIGH / OPEN`; `RL-564` and `F-ARC-018` remain `OPEN`.

## 9. Next checkpoint

**TCP-002.6 — Observation binding, independent verification, and the first
resolution.**

The dependency order is now unambiguous:

1. **Extend `Tiannara.Forecasting.Outcome`** into the observation contract:
   forecast digest, outcome-definition digest, horizon reference, event /
   publication / acquisition timestamps kept distinct, evidence digest,
   source identity and verification status. The existing struct is extended;
   no parallel observation framework is created.
2. **Bind the observation to the immutable forecast.** Evidence for another
   forecast must be rejected; a substituted horizon or digest must be
   detected.
3. **Build the independent verification boundary.** The verifier must inspect
   the underlying evidence rather than trust the acquisition adapter's parsed
   result, and it must not be able to certify its own observation. The
   assurance level achieved must be reported exactly, including the absence of
   cryptographic source authenticity.
4. **Wire the typed horizon into `OutcomeResolution`**, so the Stage 3
   contract is finally enforced and TCP-B-059 can close.
5. **Acquire a real observation** — or report the gate as blocked.
6. **Resolve, score, and record the score** against the canonical
   implementations.
