# TCP-002.7-R4 — EventStore Compatibility-Reader Explicitness

**Checkpoint:** TCP-002.7-R4
**Workstream:** W0 — Activate Existing Capabilities
**Branch:** `feat/tcp-002-7-r4-reader-explicitness`
**Baseline:** `0c31f98595fddc3fca6b01b7789ae2c1297a589c` (TCP-002.7-R3 closing SHA)
**Status:** **PARTIAL — VERIFICATION BLOCKED** pending CI confirmation; implementation complete, tests added, code compiles.

--- 

## 1. Executive disposition

| Stage | Status | Reason |
|-------|--------|--------|
| 0 — Scope pinning and preservation | **PASS** | Branch pinned from R3 closing SHA `0c31f985`; R3 history untouched |
| 1 — Caller inventory and compatibility impact | **PASS** | Documented below (§3); only test files used the legacy readers; `lib/` uses `stream_verified/2` |
| 2 — Compatibility-reader contract redesign | **PASS** | `stream/2` and `since/2` are now verification-aware by default; bare-list access moved to explicitly named wrappers |
| 3 — Caller migration | **PASS** | 3 test call sites migrated; no production caller used the legacy readers |
| 4 — Regression tests | **PARTIAL** | New tests added; could not execute locally (environment boot issue); CI pending |
| 5 — CI on this branch | **NOT_RUN** | Pending push and workflow completion |
| 6 — Evidence package | **PARTIAL** | This report and manifest; register/master updates pending |

**Overall: `IMPLEMENTED_WITH_PARTIAL_EVIDENCE / VERIFICATION_BLOCKED`** (pending CI).

R3 is CLOSED and untouched. R4 addresses only the accepted R3 caveat about
`stream/2` and `since/2`. It does not modify R3's transactional recovery.

## 2. What R3 left as a caveat

R3 made recovery transactional via `read_records/1` and `health/1`, but the
legacy compatibility readers `stream/2` and `since/2` returned bare event
lists and discarded parser diagnostics. `stream/2` additionally included
`:unverified_legacy` events without labelling them, so a consumer could mistake
a verified prefix of a damaged or truncated log for complete history. An
independent post-push review of the R3 branch identified this (see
`certification/tcp/TCP_002_7_R3_FINAL_RECONCILIATION.md`, "Independent review").

## 3. Caller inventory

### Production callers (`lib/`)

- `lib/tiannara/forecasting/forecast_registry.ex` (`safe_stream/0`) uses
  `event_store().stream_verified(0)` — the verification-aware reader. **No
  change needed; not affected by R4.**
- No other production caller uses `EventStore.stream/2` or `EventStore.since/2`.

### Test callers

| File | Line | Usage | Migration |
|------|------|-------|-----------|
| `test/tiannara/forecasting/event_store_integrity_test.exs` | 229 | `assert [event] = EventStore.stream(0)` (legacy record readable) | `stream_unverified(0)` |
| `test/tiannara/forecasting/event_store_integrity_test.exs` | 233-244 | `stream(0, ctx.name, strict: true)` / `since(..., strict: true)` | `stream(0, ctx.name)` / `since(...)` (default now strict) |
| `test/tiannara/forecasting/resolution_registry_test.exs` | 233 | `assert {:error, {:read_failed, :eacces}} = EventStore.stream(0, ctx.store)` | unchanged (read failure still returns `{:error, reason}`) |
| `test/tiannara/forecasting/resolution_registry_test.exs` | 327 | `assert [legacy] = EventStore.stream(0, ctx.store)` | `stream_unverified(0, ctx.store)` |
| `test/tiannara/forecasting/forecast_registry_durability_test.exs` | 156 | `[event \| _] = EventStore.stream(0)` | `stream_unverified(0)` |

### Compatibility impact

- `stream/2` and `since/2` no longer accept `opts` (breaking change for the
  R3-era `strict:`/`fail_closed:`/`explicit:` opt-in, which is superseded by
  the verification-aware default).
- The bare-list behaviour is retained only behind the explicitly named
  wrappers `stream_unverified/2` and `since_unverified/2`, documented as not
  verification-safe.
- `stream_verified/2`, `stream_with_diagnostics/2` and `read_records/1` are
  unchanged.

## 4. Implementation

### 4.1 `EventStore.stream/2` (verification-aware default)

Returns `{:ok, %{events:, integrity:, diagnostics:, unreadable:, truncated:,
integrity_failures:, sequence_gaps:, unverified_legacy:, verified:}}` only
when the complete history is verified (or empty-verified). Returns
`{:error, reason}` for unverified, truncated, corrupt, gapped, unreadable or
otherwise incomplete history. `diagnostics_any?/1` gates the fail-closed
decision; `storage_reason/2` maps diagnostics to a specific reason atom.

### 4.2 `EventStore.since/2` (verification-aware default)

Same contract as `stream/2`, filtered by timestamp. Returns `{:ok, map()}`
on clean history, `{:error, reason}` otherwise.

### 4.3 `stream_unverified/2` and `since_unverified/2` (compatibility wrappers)

Explicitly named, documented as **not verification-safe**. Return bare event
lists (verified and unverified-legacy) without verification gating or
diagnostics. I/O failures still propagate as `{:error, {:read_failed, reason}}`.

### 4.4 Removed helpers

`normalize_reader_opts/1` and `reader_strict?/1` removed (no longer needed).

### 4.5 Recovery isolation

R3's transactional recovery uses `read_records/1` and `health/1` and is
untouched. It does not route through `stream/2` or `since/2`.

## 5. Files changed

- `lib/tiannara/executive/event_store.ex` — stream/since verification-aware
  default; new `stream_unverified/2` and `since_unverified/2` wrappers;
  handler updates; helper removal.
- `test/tiannara/forecasting/event_store_integrity_test.exs` — migrated 2
  call sites; added 15 focused R4 tests.
- `test/tiannara/forecasting/resolution_registry_test.exs` — migrated 1
  call site.
- `test/tiannara/forecasting/forecast_registry_durability_test.exs` —
  migrated 1 call site.

## 6. Test results

Local execution was blocked by a pre-existing environment issue (CEL.Kernel
boot timeout, unrelated to R4 code). Verification performed via CI on
ubuntu-latest.

- **Elixir CI** (run `44105174511`, commit `b4b8b053`): compile success,
  test-placement success, lineage-regression success, runtime suite (required)
  success, audit suite (required) success; `suite` **failure** and non-blocking
  quarantine **failure** — both pre-existing, same sets as R3 (ten
  ResearchForecastingIntegrationTest + four runtime-quarantine failures).
  **Zero new failures.** Suite: 2755 tests, 10 failures (pre-existing), 2
  skipped. Quarantine: 1909 tests, 40 properties, 4 failures, 1943 excluded.
- **Cross-Platform Verification** (run `44105173387`): **success** (macOS,
  Ubuntu, hash comparison).
- First push (commit `8893f36c`, run `44101105100`) had 3 new failures from
  `File.chmod!` on a non-existent file in the new tests; fixed in commit
  `b4b8b053` by switching to simulated fault injection. No production code
  change.

## 7. CI record

| Push | Workflow | Run ID | Conclusion |
|------|----------|--------|------------|
| A (`8893f36c`) | Elixir CI | `44101105100` | **failure** (3 new test failures — fixed in B) |
| A | Cross-Platform Verification | `44101105577` | **success** |
| B (`b4b8b053`) | Elixir CI | `44105174511` | **failure** (pre-existing only) |
| B | Cross-Platform Verification | `44105173387` | **success** |
| C (`94d244d7`) | Elixir CI | `44108040685` | **failure** (pre-existing only) |
| C | Cross-Platform Verification | `44108040263` | **success** |

Job-level (push B and C): compile success, test-placement success,
lineage-regression success, runtime suite (required) success, audit suite
(required) success; `suite` failure and non-blocking quarantine failure — both
pre-existing. Zero new failures attributable to R4. Push C (documentation-only
evidence commit) reproduced the same pre-existing-only outcome.

## 8. Findings and governance

- No new findings created. The R3 compatibility-reader caveat is addressed by
  this checkpoint.
- TCP-B-064 remains RESOLVED (within its established scope).
- TCP-B-048 remains OPEN/BLOCKED. TCP-B-066 remains PROPOSED/NOT RATIFIED.
  TCP-B-067 remains OPEN. TCP-B-058 remains PARTIAL.
- ModelUpdateGate unchanged: `authority: :none`,
  `production_mutation: :forbidden`, `human_review_required: true`.
- No genuine acquisition, scoring, model mutation, deployment, promotion,
  ratification or actuation occurred.

## 9. Commit sequence

| Commit | SHA | Purpose |
|--------|-----|---------|
| A | `8893f36c` | Implementation + migrated tests + 15 new R4 tests |
| B | `b4b8b053` | Fix read-failure tests (simulated fault injection) |
| C | `94d244d7` | Evidence package + master assessment update; push C CI recorded below |

Base: `0c31f985` (R3 closing SHA). Parent of A: `0c31f985`. Linear, no
force-push. Remote HEAD = local HEAD = `94d244d7`.

## 10. Preservation

- R3 history preserved: branch based on R3 closing SHA, no amendments.
- 13,596 tracked checkpoints untouched, 0 deletions.
- Three pre-existing untracked files untouched.
- `cel_memory_v2.dets` restored before commit.

## 11. Remaining limitations

1. Local test execution was blocked by a pre-existing environment issue
   (CEL.Kernel boot timeout). Tests verified via CI on ubuntu-latest only.
2. No independent verification performed.
3. No genuine observation, scoring, or lifecycle advancement.
4. The compatibility wrappers still return bare lists (by design, documented
   as not verification-safe).

## 12. Disposition

**`IMPLEMENTED_AND_TESTED`** — implementation and scoped tests pass via CI,
with no claim of independent verification.

Next: independent verification (separate checkpoint), then TCP-B-048
(genuine source acquisition), then TCP-B-066 (governance decision).
