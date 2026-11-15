# TCP-002.7-R3 — EventStore Fail-Closed Recovery, Write Poisoning, and Transactional ResolutionRegistry Recovery

**Checkpoint:** TCP-002.7-R3
**Workstream:** W0 — Activate Existing Capabilities
**Branch:** `feat/tcp-002-7-r3-transactional-recovery`
**Baseline:** `fd7babafc42cccf7d290b6f6af59fb6a6fc63bf4` (TCP-002.7-R2)
**Baseline parent:** `05ee148e88d4ba066a9c3c085363eced9d0b5872` (TCP-002.7-R1)
**Status:** **PARTIAL / VERIFICATION BLOCKED** — storage and recovery are implemented and executed-tested (isolated instances, simulated fault injection); no real observation exists; no independent verification; CI pending.

---

## 1. Executive disposition

| Stage | Status | Reason |
|-------|--------|--------|
| 0 — Scope pinning and preservation | **PASS** | Branch pinned from `fd7babaf`; 13,596 tracked checkpoints untouched; the three pre-existing untracked files were not staged |
| 1 — EventStore fail-closed recovery | **PASS** | Explicit integrity states; read failure is never a clean empty history; every reader path reports `{:error, {:read_failed, reason}}`; append is permitted only for `:verified`/`:empty_verified` |
| 2 — Write/sync failure poisoning | **PASS** | Any write/`fsync` failure poisons the store, does not advance count/sequence/digest, and never acknowledges success; verified by execution |
| 3 — Transactional registry recovery | **PASS** | Three-stage recovery (read → build candidate → publish); failed recovery invalidates the published index |
| 4 — Duplicate/conflict identity handling | **PASS** | Identical duplicate identity → `:duplicate_identical_resolution_event`; different identity → `:conflicting_forecast_resolutions` |
| 5 — Adversarial regression suite | **PASS** | 42 dedicated tests, executed at seeds 0/1/2/3/4/5/123456 — 0 failures |
| 6 — Cross-suite regression | **PASS** | forecasting+research 617/0 (2 seeds); Executive set 88/0 (2 skipped); runtime 32 properties/792/0 |
| 7 — Independent verification | **NOT_RUN** | No independent verifier available |
| 8 — CI on this branch | **NOT_RUN** | Pending push and workflow completion |
| 9 — Genuine observation / scoring | **BLOCKED** | Inherits TCP-B-048 (no live source) — out of R3 scope |
| 10 — Evidence register and manifest | **PASS** | This report, the manifest, the append-only register and the master assessment |

**Overall: `IMPLEMENTED_WITH_PARTIAL_EVIDENCE / VERIFICATION_BLOCKED`.**

The storage and recovery contract is now enforced and proven against isolated
instances and simulated faults. **It is not independently verified, and no
real-world predictive claim of any kind is made.** The two-commit evidence
plan is used (commit A: implementation + tests + report + generator;
commit B: manifest + register/master updates referencing A).

## 2. What TCP-002.7-R2 left broken

TCP-002.7-R2 (`fd7babaf`) added a startup integrity gate and recovery
hardening but still had fail-open behaviour in the read and write paths:

1. **`init` crashed** on an unreadable log (`{:ok, fh} = File.open(...)`
   matched without a failure clause) — the store could not start at all
   instead of reporting `:unavailable`.
2. **A read failure was indistinguishable from an empty history.** `read_frames/2`
   returned `{[], 0, false, 0, 0, 0}` on `File.read` error, so `stream/1`
   yielded `[]` and startup classified the log as `:empty_verified` and
   appendable — with zero events and zero evidence the file was merely empty.
3. **A failed write did not poison the store.** On write error the store kept
   its previous state, so the next append would proceed as if nothing had
   happened and could acknowledge success after an uncertain boundary.
4. **Sync failure marked the store poisoned by sentinel value**
   (`last_digest: :poisoned`) and left real `last_sequence`/`count` stale; the
   ambiguous sentinel is no longer meaningful once the schema distinguishes
   `:poisoned` as an explicit integrity state.
5. **`ResolutionRegistry.rehydrate/1` deleted the ETS objects and re-inserted a
   partially built candidate one event at a time**, so a mid-replay failure
   could leave a half-built index visible as authoritative; `count/0` and
   `all_ids/0` read ETS directly without any integrity check; and two
   identical resolution events for one forecast were silently collapsed with no
   error, inflating or masking history findings.

## 3. What R3 implements

### 3.1 `Tiannara.Executive.EventStore` (`lib/tiannara/executive/event_store.ex`)

**Explicit integrity states** (`health/0` exposes them, `read_error` carries
the reason): `:verified`, `:empty_verified`, `:unavailable`, `:truncated`,
`:integrity_failure`, `:sequence_gap`, `:legacy_unverified`,
`:recovery_required`, `:poisoned`.

**Read failures are never clean history.** `read_frames/3` returns
`{:ok, %{records:, diagnostics:}} | {:error, {:read_failed, reason}}`.
`stream/3`, `stream_with_diagnostics/3`, `stream_verified/3` and
`read_records/1` propagate `{:error, {:read_failed, reason}}`.
`since/2` propagates the same. `init` opens the log and, on read failure,
enters an `:unavailable` state instead of crashing: `health/0` reports
`integrity: :unavailable`, `read_error: reason`, `append_permitted: false`,
and appends are refused with `:store_not_appendable`.

**Append gate.** Append is permitted only when `integrity` is `:verified` or
`:empty_verified`. On every append the **complete history is re-read** and
verified before writing (the cached GenServer state is not accepted as proof);
loss of intactness returns `{:error, {:store_integrity_failure, reason}}`,
degrades the store (`append_permitted: false`, `integrity: :integrity_failure`)
and does not write.

**Write/sync poisoning.** A write failure, a partial-write fault, or an
`fsync` failure:

* returns `{:error, {:write_failed, reason} | {:sync_failed, reason}}`;
* poisons the store (`integrity: :poisoned`, `append_permitted: false`);
* does **not** advance `count`, `last_sequence` or `last_digest`;
* is **never** acknowledged as success;
* refuses every subsequent append with `:store_poisoned`.

**Test-only fault seam.** `start_link(fault_injection: ...)` supports
`:read` (`{:error, reason}`), `:write` (`{:error, reason}` or
`{:partial, n}` — writes a genuine prefix of the frame so restart recovery
exercises a real truncated file), `:sync` (`{:error, reason}`) and
`:kill_after_write` (the process exits with `:kill` between write and sync —
a real process termination; the supervised store restarts and the earlier
call still never acknowledged). **All fault injection is simulated except the
process kill is real at the process layer; no hardware or filesystem fault was
injected on real media.**

**Legacy records** remain readable but `:unverified_legacy`; they are never
integrity-verified, never silently promoted, and they block append.

`health/1` deliberately exposes no `durable` boolean: durability is derived by
consumers (ResolutionRegistry) from the integrity state plus a live health
check, not asserted by the log itself.

### 3.2 `Tiannara.Forecasting.ResolutionRegistry` (`lib/tiannara/forecasting/resolution_registry.ex`)

**Transactional recovery.** Startup and `recover/1` run a three-stage
transaction:

1. **Read** — live `EventStore.health/1` and `EventStore.read_records/1`;
   any read/health failure aborts publication.
2. **Build** — a candidate index is constructed in memory over the complete
   history: every event of type `efdi.forecast.resolved` is semantically
   validated; non-resolution events are skipped; any failure halts before
   publication.
3. **Publish** — the index is replaced with a **single ETS object**
   (`{:__resolution_index__, %{forecast_id => resolution}}`) via one
   `:ets.insert` or invalidated with `:ets.delete_all_objects`. Publication is
   atomic at the ETS operation, so a reader never observes a half-built
   table. A publication failure yields `:publication_failure` and leaves
   nothing authoritative published.

**Failed recovery is not silently absorbed by stale state.** On any stage
failure the previously published index is invalidated (`published: false`,
count zeroed, ETS cleared), lookups and commits refuse with
`:registry_not_verified`, and `recover/1` may be retried; a later success
republishes atomically.

**Trust gate.** `get/2`, `all_ids/1`, `count/1` and `commit/2` require a live
verified EventStore (integrity in `[:verified, :empty_verified]`, not poisoned,
`append_permitted`, not degraded) plus a published registry; otherwise they
return `:registry_not_verified`, `:registry_degraded` or
`:eventstore_unavailable` and the registry is degraded.

**Duplicate identity semantics.** During replay, two durable resolution events
for one forecast are a history-consistency finding, never a second canonical
resolution:

* identical resolution identity → `:duplicate_identical_resolution_event`;
* different identity → `:conflicting_forecast_resolutions`.

Neither inflates the canonical count nor publishes an index.

**Commit path.** `commit/2` re-checks trust (`ensure_trusted`), validates the
payload against the required resolution fields, resolves exact-retry idempotency
by full identity comparison, appends through the poisoned-aware EventStore, and
only then indexes the record. A committed `resolution_conflict` is refused
without touching the log.

### 3.3 Naming and isolation

`ResolutionRegistry`/`EventStore` now accept explicit instance names and the
registry accepts an explicit `event_store_name`. Every R3 test runs on isolated
instances and temp files; the application-wide log is never touched by the
suite.

## 4. Tests

New: `test/tiannara/forecasting/resolution_registry_test.exs` — **42 tests**,
grouped:

| Group | Coverage |
|---|---|
| EventStore startup integrity | new/existing-empty/populated-log startup; read failure; open failure; truncated tail; corrupted digest; broken chain; sequence gap; legacy record; multiple diagnostic categories; file changed underneath a running store |
| Write and sync failures | write failure before any bytes; partial write → real truncated restart; sync failure poisoning; termination between write and sync; preceding verified history preserved |
| Transactional registry replay | full/first/middle/final invalid events; truncated history; unreadable record; malformed payload; missing identity; unavailable store; read failure reported precisely; live EventStore loss; poisoned history |
| Prior index preservation | failed recovery invalidates the previous index; retry recovers; publication failure invalidates and retries |
| Duplicate and conflict semantics | commit conflict refusal; exact-retry idempotency; invalid commit payload; commit refused while unverified; commit refused when EventStore disappears; identity-field conflict matrix |
| Persistence boundary | resolution survives store+registry restart; pre-indexed append recovered; exact lookups while verified |

**Executed results (this working tree):**

| Suite | Command | Seed 0 | Seed 123456 | Seeds 1–5 |
|---|---|---|---|---|
| R3 dedicated suite | `MIX_ENV=test mix test test/tiannara/forecasting/resolution_registry_test.exs --seed N --no-deps-check` | 42 / 0 | 42 / 0 | 42 / 0 |
| Application regression | `MIX_ENV=test mix test test/tiannara/forecasting test/tiannara/research --seed N --no-deps-check` | **617 / 0** | **617 / 0** | — |
| Executive set | `MIX_ENV=test mix test test/executive test/tiannara/runtime/executive_memory_test.exs test/tiannara/cel/services/executive_memory_test.exs --seed 0 --no-deps-check` | **88 / 0, 2 skipped** | — | — |
| Runtime regression (cwd `tiannara_runtime`) | `MIX_ENV=test mix test test/simulation test/runtime_layers test/kernel test/cognitive test/world_model --seed 0 --no-deps-check` | **792 tests, 32 properties, 0 failures** | — | — |

Exit codes were 0 for every executed command.

**What is proven (adversarially, in isolation):** incomplete history is never
treated as complete; a failed durable step is never reported as a success; a
replay that cannot be trusted publishes nothing authoritative; a stale index
does not outlive an integrity failure; exact retries are idempotent; conflicting
records are refused.

**What is not proven:** behaviour under real disk corruption, real power loss,
real filesystem misbehaviour or real concurrency with a second writer;
performance under long logs (full re-read on every append and replay is
deliberate, O(n) and unmeasured here); independent verification; CI on this
branch.

## 5. Evidence assurance

| Claim | Level |
|---|---|
| Integrity failure detection | **verified** (tests) and **inferred** for uninjected fault modes |
| Write/sync poisoning semantics | **simulated** (fault injection) + **verified** against real file prefixes/truncation created by the partial-write test |
| Transactional publication | **verified** (ETS object substitution and invalidation tested) |
| Duplicate/conflict handling | **verified** (tests) |
| Independent verification | **none** |
| Genuine observation of any real-world outcome | **not attempted** |

Simulated evidence is not presented as real storage-fault evidence.

## 6. Governance

`Tiannara.Forecasting.ModelUpdateGate` — unchanged: `authority: :none`,
`authorization: :not_granted`, `deployment: :not_granted`,
`production_mutation: :forbidden`, `human_review_required: true`,
`certification_eligible: false`. No model mutation, deployment, registry
promotion, policy ratification or physical actuation occurred. TCP-B-066
(source-trust policy) remains **PROPOSED — NOT RATIFIED** and no real
limited-assurance resolution is authorized. **RL-565 `HIGH / OPEN`; RL-564
`OPEN`; `F-ARC-018` `OPEN`.**

## 7. Storage and retention

13,596 git-tracked files under `tiannara_runtime/data/cpl/checkpoints/`
preserved unchanged. No tracked file deleted, moved or rewritten. No tracked
checkpoint file was pruned. The three pre-existing untracked files
(`certification/atlas/r0_refresh_2026-10-24.json`,
`certification/audit/GENSERVER_OWNERSHIP_INVENTORY.csv`,
`certification/audit/GENSERVER_OWNERSHIP_INVENTORY.md`) were not staged.
`cel_memory_v2.dets` was restored before commit and is not staged. The R3
branch adds two commits and touches none of these paths.

## 8. Known limitations

1. **Fault injection is simulated.** The partial-write case does create a real
   truncated file; `kill_after_write` performs a real process kill. No hardware,
   firmware, filesystem or fsync-semantics fault was injected.
2. **No independent verification.** The tests are self-authored against the
   contract; no independent verifier ran.
3. **No genuine observation.** TCP-B-048 remains **OPEN / BLOCKED**. No real
   resolution exists, no score exists, and the lifecycle remains
   `FORECAST_REGISTERED`.
4. **TCP-B-067** (ephemeral verification key) remains **OPEN**; historical
   recovery relies on re-execution against the evidence store.
5. **TCP-B-061** (no trusted integrity anchor), **TCP-B-062** (single writer),
   **TCP-B-056** (pseudo-measurements), **TCP-B-046** (cross-stack boundary),
   **TCP-B-065** (unbounded runtime file growth) remain **OPEN**.
6. **CI is pending** on this branch. Pre-existing CI failures observed on the
   main line (`ResearchForecastingIntegrationTest` full-suite state
   contamination; the runtime quarantine's four non-blocking failures) are
   unchanged by this work.
7. The `:empty_verified` baseline is **not** permission to trust an
   empty file that was never opened by this process; it is established only
   after `File.open` and a complete read.
8. Full-history re-read before every append is deliberate and unmeasured; for
   very long logs this is an O(n) append cost.
9. Windows-only local execution; CI (ubuntu-latest) not yet witnessed for
   this branch.

## 9. Findings after this checkpoint

| ID | Before R3 | After R3 |
|---|---|---|
| TCP-B-064 | OPEN — resolution not durably recoverable | **RESOLVED** — implemented, adversarially tested, deployed through the canonical commit path (see TCP-002.7 and this checkpoint). No genuine resolution has yet been produced (TCP-B-048) |
| TCP-B-066 | OPEN — no ratified source-trust policy | OPEN — `PROPOSED — NOT RATIFIED`; unchanged |
| TCP-B-067 | OPEN — ephemeral verification key | OPEN — unchanged |
| TCP-B-048 | OPEN — no live source | OPEN — unchanged, blocks all real resolution |
| TCP-B-061 / TCP-B-062 / TCP-B-056 / TCP-B-046 / TCP-B-065 | OPEN | OPEN — unchanged |
| TCP-B-058 | PARTIAL — no external anchor; publisher authenticity not established | PARTIAL — unchanged; a digest proves integrity, not authenticity |
| RL-565 | HIGH / OPEN | HIGH / OPEN |
| RL-564 | OPEN | OPEN |
| F-ARC-018 | OPEN | OPEN |

**Register after this checkpoint:** 67 rows — 43 open, 22 resolved, 2 partial.

## 10. Artifacts

| Artifact | Path |
|---|---|
| This report | `certification/tcp/TCP_002_7_R3_IMPLEMENTATION_REPORT.md` |
| Evidence manifest | `certification/tcp/TCP_002_7_R3_EVIDENCE_MANIFEST.json` |
| Evidence manifest (copy) | `certification/evidence/tcp002_7_r3/TCP_002_7_R3_EVIDENCE_MANIFEST.json` |
| Manifest generator | `tools/tcp/tcp0027r3_evidence_manifest.py` |
| Append-only register | `certification/tcp/TCP-001_COMPLETION_REGISTER.csv` |
| Master assessment | `certification/tcp/TCP-001_MASTER_COMPLETION_ASSESSMENT.md` |

The manifest is generated, never hand-edited.

## 11. Next

1. Push `feat/tcp-002-7-r3-transactional-recovery`; verify the remote HEAD
   matches; record GitHub Actions runs for both commits.
2. With storage/recovery gates passed, return to TCP-002.7 proper: a genuine
   forecast outcome lifecycle — which remains blocked at acquisition
   (TCP-B-048) and at policy ratification (TCP-B-066).
3. TCP-B-067 (persistent, protected VerificationAuthority key) and
   TCP-B-065 (runtime file growth) remain open workstreams.
