# Tiannara System Atlas — Baseline Freeze (Phase R0.A)

Frozen at: 2026-10-20 (UTC), by read-only discovery pass. **No production code was modified.**

## Repository identity

| Field | Value |
|---|---|
| Platform repository | Tiannara AI (constitutional scientific discovery / engineering intelligence platform) |
| Remote URL | `https://github.com/Kimiti4/Tiannara.git` (`origin`) |
| Local path | `C:\Users\user\Tiannara\Tiannara-MindCache-Prosthetic` |
| Branch | `local/pr4` |
| Commit SHA (baseline) | `521cb7fe513a466302ec3bb398940df3814edf2d` — `docs(audit): tiannara_runtime test inventory + wiring audit §4 item 5 closed` |
| In sync with origin | yes (`origin/local/pr4` == baseline SHA) |
| Submodules | none (`git submodule status` empty) |
| ESAP repository (separate) | `https://github.com/Kimiti4/autonomous-API-Gen.git`, public, default branch `main`, last push `2026-10-20T09:21:56Z`. Inventoried separately; inventories never merged. |

## Working-tree state at freeze (dirty tree recorded, not cleaned)

`git status --porcelain`: **1819 entries**

| Status | Count | Meaning / handling |
|---|---|---|
| ` M` (modified tracked) | 31 | Almost entirely root `*.dets` runtime DB churn (e.g. `cel_memory_v2.dets`) caused by test/boot runs. Left in place, never staged. |
| ` D` (deleted tracked) | 470 | Includes long-standing root `.dets.corrupted.*` archive deletions and similar. Left in place, never staged. |
| `??` (untracked) | 1318 | Runtime artifacts (`tiannara_runtime/data/**`), logs, `.beam` drops, pytest cache dirs, `audit_output/`, scanner `audit_tiannara_directories.py`, tool outputs. Left in place, never staged. |

Rationale (operator directive): the dirty tree is historical/runtime churn with an existing audit trail; R0 records it rather than mutating it.

## Tracked-file distribution (top directories)

26,070 tracked files. Largest: `tiannara_runtime` 17,227 · `data` 1,751 · `lib` (root Elixir project) 1,659 · `tiannara_observatory` 499 · `docs` 460 · `priv` 459 · `tiannara_core` 440 · `test` (root) 387 · `council_dets_archive_20260816` 359 · `certification` 296 · `scripts` 164 · `tiannara_api` 132 · `tiannara_saas` 90 · `tiannara_pros` 47 · plus frontends, `docker`, `monitoring`, `k8s` (under tiannara_runtime), `rust_core` (untracked), `mindcache`, etc. Full enumeration: `certification/atlas/file_inventory.csv`.

## CI status at baseline (freshness bound to baseline SHA)

| Run ID | Workflow | SHA | Result | Created |
|---|---|---|---|---|
| 39392651371 | Elixir CI | `521cb7fe` (baseline) | **success** | 2026-10-20T08:20:11Z |
| 39392651343 | Cross-Platform Verification | `521cb7fe` (baseline) | **success** | 2026-10-20T08:20:11Z |
| 39388434031 | Elixir CI | `c7214a50` | success | 2026-10-20T07:43:43Z |
| 39388434039 | Cross-Platform Verification | `c7214a50` | success | 2026-10-20T07:43:43Z |

Workflow files present: `ci-cd.yml`, `cross_platform_verify.yml`, `elixir_ci.yml`, `phase_5f2_tests.yml`, `test.yml`.

Known CI scope caveats (evidence rules — historical green ≠ proof):
- `elixir_ci.yml` required jobs: root-project `compile`, `test-placement`, `suite` (387 tests), `lineage-regression`, plus **`tiannara-runtime-suite`** (`mix test --exclude quarantine`, cwd `tiannara_runtime`, seed 0, EXIT=0, 1854 tests + 40 properties at baseline) and non-blocking `tiannara-runtime-quarantine` (6 tagged; 3 fail locally, informational).
- `phase_5f2_tests.yml` only triggers on `main`/`develop` — **never runs on `local/pr4`**. Its recorded results are historical (`main` @ `e082e79a`, OTP 27, 160/160 pass on 2026-10-18). Latent issue documented in test inventory; deliberately not widened in the CI workstream.
- `ci-cd.yml` / `test.yml` triggers: `ci-cd.yml` runs on pushes to `local/pr5`, `local/pr6` only — **not on `local/pr4`** (discovered during baseline; logged as finding F-PLT-004).

## Test commands (actual, verified at baseline)

| Suite | Command | CWD | Result at baseline |
|---|---|---|---|
| Root Elixir project | `mix test` | repo root | 387 tests, 0 failures (CI `suite` job) |
| tiannara_runtime main | `MIX_ENV=test mix test --exclude quarantine --color` | `tiannara_runtime` | 40 properties, 1854 tests, 0 failures, 6 excluded; ~10–16 min; `seed: 0` |
| tiannara_runtime quarantine | `MIX_ENV=test mix test --only quarantine` | `tiannara_runtime` | 6 tagged; 3 fail locally (omega×2, reactivity) — informational only |
| Slow tier (runtime) | `mix test --only slow` | `tiannara_runtime` | EXCLUDED by default; last verified 2026-10-18 commit `61e68e8a`: 70/70 pass (~53 min) |
| tiannara_runtime verification scripts | `elixir scripts/verify_phase_5f6_opc.exs`, `verify_phase_5f5_core.exs` | `tiannara_runtime` | Honest EXIT=1 fail-closed (3 F-002 core fails; 6/7 OPC gates pass, 1 pre-existing gap). Never loosened. |
| Python services | `pytest` (root `pytest.ini` exists) | various | NOT re-run in R0 (read-only; historical runs recorded in audit_output/test_reports) |

Environment: Elixir/OTP via `mise` (root `mise.toml`; temp worktrees require `mise trust`). PowerShell 5.1 quirks noted in operator directives.

## Reused prior evidence (versioned; no rediscovery)

| Asset | Path | Role in R0 |
|---|---|---|
| Directory audit (2026-10-19) | `certification/audit/DIRECTORY_AUDIT_2026-10-19.md` | Per-directory state, k8s credential findings, stub inventories |
| Phase 5F wiring audit | `certification/audit/PHASE_5F_WIRING_AUDIT.md` | Boot trees, 23 orphaned modules, wiring decisions (§4 status) |
| Status correction (C-01..C-14) | `certification/audit/PHASE_5F_STATUS_CORRECTION.md` | Historical completion-claim corrections |
| Execution contracts (C1..C6) | `certification/audit/EXECUTION_CONTRACTS.md` | CI/verification contract history |
| GenServer ownership inventories | `certification/audit/GENSERVER_OWNERSHIP_INVENTORY.{md,csv}`, `GENSERVER_RECONCILIATION.{md,csv}` | Process/state ownership (Register 4 seed) |
| Runtime test inventory (CI workstream) | `certification/audit/TIANNARA_RUNTIME_TEST_INVENTORY.md` | Test inventory, quarantine table, CI scope evidence |
| Directory scanner outputs | `audit_output/tiannara_file_inventory*.csv/json`, `marker_findings.csv`, `secret_scan_redacted.csv` (2026-10-19, untracked) | Seed for Register 1; superseded by full inventory in R0 |
| Scanner source (untracked) | `audit_tiannara_directories.py` | Method reference; stays untracked |
| Capability scan | `certification/audit/TIANNARA_CAPABILITY_SCAN.md`, `PRODUCTION_READINESS_SCAN.md` | Earlier capability/readiness scans (superseded markers preserved where applicable) |

## Known open issues / prior remediation evidence

- CI-suite widening workstream COMPLETE at baseline (commits `c9a0306c`..`521cb7fe`): 126 test files tracked, runtime suite required in CI, 5 quarantine tags, 3 CI-found root causes fixed (loaded-vs-active, checkpoint key normalization, dead config key).
- Deferred by operator (still open, feed R0 backlog): Stage B omega isolation; OLEF field pinning; MSCL metric 0.0; passive population decay; Babel/C-08 key design; C-11/C-13 duplicate consolidation; scan items A5b/B8c/C1/C2/C11; `phase_5f2_tests.yml` latent issues; 5F.5/5F.6 honest-fail verifiers (3 core + 1 OPC gap).
- Directory audit findings carried: k8s YAML plaintext credentials (severity raised); Python stubs w/ imports never executed; 23 orphaned Elixir modules; `tiarnara_runtime` typo dir under `tiannara_runtime/lib/`.

## Exclusion policy for the audit itself

- `.git` internals: excluded (VCS metadata; reason recorded).
- `deps/`, `_build/`, `node_modules/`, `__pycache__/`, venvs, `*.beam` drops: inventoried with class `generated`/`vendor` (not silently dropped).
- ESAP repo: separate inventory (`certification/atlas/esap/`), never merged.
- No files were moved, deleted, or modified during R0.
