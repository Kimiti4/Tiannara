# tiannara_runtime test suite inventory & CI integration (CI-suite widening)

Date: 2026-10-20 · Branch: `local/pr4` · Status: **integrated, required CI gate green**
(Elixir CI run `39388434031`, job `tiannara_runtime suite (required)` on `c7214a50`)

This is the evidence record for the operator's CI-suite widening plan (5 steps):
1. inventory & classify the untracked `tiannara_runtime` tests (no discarding;
   classify failures) — **done**;
2. Stage A deterministic / Stage B service-dependent / Stage C exploratory,
   run separately — **done** (staging by tag, see §4);
3. fix the P9X random flake by statistically sound expectations, never retries —
   **done** (§3);
4. make CI authoritative (intended suites on push+PR, nonzero exit on failure,
   non-blocking jobs visibly separate) — **done** (§5);
5. close with documented inventory, path filters, executed counts, failure
   behavior, quarantined tests — **this document**.

---

## 1. Inventory (method: `git ls-files` / `git ls-tree` at `c9a0306c^`, filesystem recount)

| Metric | Count |
|---|---|
| `*_test.exs` files under `tiannara_runtime/test/` | **166** |
| — tracked before this workstream (`c9a0306c^`) | 42 |
| — untracked before this workstream | 124 |
| support helpers (`test/support/*.exs`, untracked → tracked) | 2 |
| non-test tracked files (`test_helper.exs`, 11 meta docs, `test_helpers.ex`) | 12 |
| **tracked under `tiannara_runtime/test/` after `c9a0306c`** | **180** |
| gitignored test files | 0 |
| Tests + properties in the suite | **1854 tests + 40 properties** |
| Quarantined (excluded from the required gate) | 6 tests |

Notes on count drift across audits: `DIRECTORY_AUDIT_2026-10-19.md` §10 recorded
"166 `.exs` vs 39 tracked" (filesystem agrees: 166; tracked count moved 39 → 42
between the audit and `c9a0306c^`). The wiring audit's "127 untracked" is this
workstream's observed **124 untracked tests + 2 support helpers + test-helper
dependency** story; raw `git ls-files` numbers above are authoritative.

The tracked `test/test_helper.exs` `Code.require_file`d the two untracked
support files, so a **fresh checkout could not run `mix test` at all** (reproduced
locally: EXIT=1). That alone made the suite CI-invisible beyond the tracking gap.

## 2. Baseline causation (all 10 original failures pre-exist; zero W1–W3 regressions)

A temporary git worktree at `e7f81b97` (pre-W1 commit) ran the 6 failing files:
**12/21 failures** there — every failure observed after W1/W2/W3 exists at
pre-W1 baseline, 2 extra order/timing failures additionally proved the suite ran
with a **random ExUnit seed** (root project pins `seed: 0`; `tiannara_runtime`
did not). Worktree removed after the comparison.

## 3. Classification & Stage A fixes (commit `c9a0306c`)

Batch runs (aggregate = exact suite totals; sums verified: tests 1854, properties 40):

| Batch scope | Tests | Props | Failures |
|---|---|---|---|
| misc (audit, category_theory, kernel, l2_stabilization, os, phase5, pre_phase6, runtime_layers) | 36 | 8 | 3 (audit_framework) |
| tracked top-level | 323 | 0 | 0 |
| `test/tiannara/` | 242 | 0 | 0 |
| `test/tiannara_runtime/` | 428 | 0 | 5 (application ×2, omega ×2, startup_supervisor) |
| `world_model/` | 472 | 0 | 0 |
| `simulation/` | 0 | 32 | 0 |
| civilization + cold_ignition + oed | 96 | 0 | 2 (passive_mode, reactivity) |
| `cognitive/` | 257 | 0 | 0 |
| **Total** | **1854** | **40** | **10 original** |

Stage A fixes (findings preserved, expectations corrected):

- **track `test/support/*.exs`** — fresh-checkout prerequisite (§1).
- **`ExUnit.start(seed: 0)`** in `tiannara_runtime/test/test_helper.exs` —
  matches the root project; kills order-dependent pass/fail flips (proven at baseline).
- **audit_framework ×3** — the lib had been refactored to live-only `/0` while
  the tests call `/1` with mock states; restored the injection API
  (`CoherenceValidator.run_full_coherence_audit/1` delegates `/0`,
  `AuditReporter.generate_pre_phase6_audit_report/1` + `audit_inputs/1`).
  Purely additive.
- **application_test ×2** — `ensure_all_started` returns `{:ok, []}` when the app
  is already running (the `{:error, …}` branch never fires); `started_applications/0`
  entries are 3-tuples, not keyword pairs.
- **startup_supervisor_test** — OTP `#supervisor.state{}` record layout no longer
  matches the test's fixed-arity pattern; locate strategy atom and `{ids, map}`
  children structurally. The "is false when supervisor not started" test had an
  **unarrangeable premise** (the application boots `StartupSupervisor` as a
  permanent child; it only passed as another test's teardown side-effect) and was
  rewritten as an `all_running?`/`status/0` consistency check.
- **p9x Test 5 (operator step 3)** — OFL evaluates `:rand.uniform()` in its own
  GenServer process, so the test cannot seed it; 20 attempts left P(flake) ≈ 1.15%.
  N=20 → **N=64 gives P ≈ 6.3e-7** (statistically sound; no retries, no masking).

## 4. Quarantine inventory (6 tests, tracked, `@tag`/`@moduletag :quarantine`)

Excluded from the required gate; executed only by the non-blocking CI job.

| Test | Stage | Why | Re-admission condition |
|---|---|---|---|
| `omega_robustness` ×2 (module) | B | needs a privately-owned CPL instance; the boot tree owns the named process (`:already_started`) | isolation design for Stage B (separate boot tree / owned CPL) |
| `passive_mode` "no mutations occur in passive mode" | C | boot-wired OLEF periodic rebalancing mutates the field `core_hash` covers (product finding; pre-exists `e7f81b97`) | passive mode actually pins the OLEF field |
| `passive_mode` "no system state mutations" | C | same finding at system-state level (pre-exists `e7f81b97`) | same |
| `passive_mode` "population remains stable or only decays" | C | env-dependent: passes warm-build Windows runs (often vacuously, `initial_pop = 0`), failed Linux CI (4 → 0 in the 15s window); product question whether passive mode prevents decay | passive mode pins population, or the test establishes its own precondition |
| `reactivity` "constraint load spikes after perturbation" | C | MSCL telemetry metric stays 0.0 across perturbation (product finding; pre-exists `e7f81b97`) | metric wired and moving |

Quarantine job results vary by environment (3/6 fail locally, 4/6 on the first
Linux run) — expected: it is informational, never gating.

## 5. Authoritative CI configuration (`.github/workflows/elixir_ci.yml`, commit `3d3ae924`)

| Property | Required job | Quarantine job |
|---|---|---|
| Name | `tiannara_runtime suite (required)` | `tiannara_runtime quarantine (non-blocking)` |
| Command | `mix test --exclude quarantine --color` (cwd `tiannara_runtime`, `MIX_ENV=test`) | `mix test --only quarantine --color` |
| Failure behavior | any test/compile failure → nonzero exit → **workflow fails** (fail-closed) | `continue-on-error: true` — job shows red, **workflow stays green** |
| Triggers | same as workflow: **all branch pushes + all PRs** (no path filters — deliberate: the suite must run whenever anything changes) | same |
| Timeout / cache | 60 min; `tiannara_runtime/deps` + `_build` keyed on `hashFiles('tiannara_runtime/mix.lock')` | 30 min; same cache key |
| Observed duration | ~2m10s on Linux runners (cold cache), full suite ≈ 64–127 s of test time | ~2 min |

Executed counts on green run `39388434031`: required job = **1854 tests +
40 properties, 0 failures, 6 excluded** (asserted from the same suite totals the
local gate reports: `mix test --exclude quarantine` → EXIT=0, verified twice
locally on Windows, ~10–16 min).

Root jobs (`compile`, `test-placement`, `suite` = root project's 387 tests,
`lineage-regression`) are a **different Mix project** and remain unchanged.

### Honest finding: the historical "CI green" gap

Before `3d3ae924`, **no workflow executed `tiannara_runtime` tests on this
branch** — the root `suite` job is a different project, and
`phase_5f2_tests.yml` triggers only on `main`/`develop`. W1–W3's "CI green"
therefore exercised the root project only; runtime-suite evidence was local
until this workstream. Both are green now, on every push.

### Latent issues deliberately NOT touched (documented per operator)

- `phase_5f2_tests.yml`: `main`/`develop`-only triggers (never runs on
  `local/pr4`), OTP 27 (this suite targets OTP 28), and
  `mix compile --warnings-as-errors` — a full test-env compile currently emits
  **≈700 warning lines**, so widening that workflow without a warning-cleanup
  decision would fail immediately. Left as-is.
- Scan items A5b/B8c/C1/C2/C11, Babel/C-08, C-11/C-13 remain open per the
  operator's deferred table; audit artifact storage is a separate decision.

## 6. Failures found by CI itself (and how each was resolved)

| CI run | Commit | Result | Diagnosis | Resolution |
|---|---|---|---|---|
| `39363009648` | `3d3ae924` | 2 failures | (a) `no_mocks` filtered `:code.all_loaded()` for "Mock" — on any fresh checkout the in-VM compiler loads **every** module before ExUnit starts, so "loaded" ≠ "active" and the test failed deterministically on cold `_build` (reproduced locally by deleting `_build/test`; 7 of 8 mock observatories are pure functions with no process at all). (b) passive population test — env-dependent (now quarantined, §4). | (a) rewritten to assert actual activity: no mock observatory **process** registered + no mock certification report; (b) `@tag :quarantine`. Commit `d4747586`. |
| `39382482185` | `d4747586` | 1 failure | `no telemetry message loss` got **-1240** messages: `TelemetryPublisher.message_count` went backwards because the GenServer restarted. Restart traced to a **CPL crash**: `load_checkpoints` never normalized JSON string keys (unlike `load_events`), so the next 30 s auto-checkpoint crashed `create_checkpoint_record/3` with `key :checkpoint_id not found` (exact CI stacktrace). Local runs stayed green because 7 zero-byte local event files aborted the whole load via the rescue — on CI all tracked JSON is valid, the load succeeds, the crash fires. | `normalize_checkpoint_keys/1` at decode (same style as `normalize_event_keys/1`). Verified by probe: with the fix stashed + empties moved aside → exact KeyError; with fix → clean. Commit `c7214a50`. |
| `39388434031` | `c7214a50` | **green** | — | required job ✓, quarantine job red (expected, non-blocking) |

## 7. What remains deliberately untracked / unstaged

- Scanner: `audit_tiannara_directories.py` + `audit_output/` (operator decision).
- Root `.dets` churn (`cel_memory_v2.dets`, deleted `council_audit_log.dets.corrupted.*`).
- `tiannara_runtime/data/**` runtime artifacts — test runs mutate tracked
  checkpoint/event files and create new ones; these working-tree mutations are
  never staged (CI runs from a clean checkout).
- `probe_w2.exs`, `tools/audit/` and other pre-existing untracked files.

## 8. Commits

| Commit | Content |
|---|---|
| `c9a0306c` | Stage A: track 126 files + 2 support, seed 0, lib injection APIs, startup/application/p9x fixes, 5 quarantine tags |
| `3d3ae924` | CI: required suite job + non-blocking quarantine job |
| `d4747586` | CI-found fixes: `no_mocks` activity check, passive population quarantine |
| `c7214a50` | CPL checkpoint key normalization (CI-found crash cascade) |
| `7343f1c7` | remove dead `start_app` config key (wiring audit §4 item 5) |
