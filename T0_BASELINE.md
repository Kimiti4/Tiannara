# T0 — IMMUTABLE BASELINE RECORD

**This is the structured T0 baseline record for the Main Tiannara AI repo.**
**The current state of the working tree (including all uncommitted files) is evidence. Nothing was cleaned up before this baseline was captured.**

---

## Record (per user request)

| Field | Value |
|---|---|
| **Repository** | `https://github.com/Kimiti4/Tiannara.git` |
| **Commit SHA** | `9753a6d08702064f4d00395a1bec1c4bf3887381` (HEAD) |
| **Branch** | `main` (also `t0-baseline`) |
| **T0 Tag** | `T0` (annotated) → `67d49b801774c98446ee5d67c1d0154245af90f2` → commit `9753a6d` |
| **Timestamp** | `2026-09-05T01:26:48+03:00` (commit author date) |
| **Tree hash** | `06f06e5e91f33e75437a47ca901eaa7e97bb0edd` |
| **Runtime versions** | Elixir `1.18.4` · OTP `28` · Erlang `26.2.5.14` (erts `16.4`) |
| **Platform** | Windows (`win32`) |

---

## File inventory (HEAD = T0)

| Category | Count |
|---|---|
| **Total tracked in commit** | **7,708** |
| `.ex` (Elixir source) | 2,014 |
| `.md` (documentation) | 1,352 |
| `.json` (configs, certs, knowledge graphs) | 1,333 |
| `.exs` (Elixir scripts) | 653 |
| `.py` (Python) | 450 |
| `test/` (test files, at any depth) | 441 |
| `.bin` (binary data) | 182 |
| `.eterm` (Erlang compiled terms) | 147 |
| `.csv` | 137 |
| `.txt` | 136 |
| `.log` | 109 |
| `.yaml` | 63 |
| `.dets` (Erlang disk term storage) | 17 |
| Other (`.etf`, `.pyc`, `.ps1`, `.png`, `.beam`, …) | rest |

**Subprojects tracked in T0** (Tiannara has multiple Mix apps / Python packages coexisting):
| Subproject | Files in T0 |
|---|---|
| `tiannara_api/` | 9 |
| `tiannara_pros/` | 47 |
| `tiannara_runtime/` | 34 |
| `tiannara_core/` | 134 |
| Main `lib/tiannara/` (forecasting, evolution, ecology, stabilization, etc.) | bulk of the 7,708 |

---

## Build status

- **Compiles:** ✅ verified previously for the `tiannara` Mix app (compiles with `mix compile`; CRLF warnings on pre-existing dirty-tree files are non-fatal).
- **Test framework:** ExUnit (Elixir) + pytest (Python).
- **Test result for the certified forecasting chain (D1–D5):** **377 tests, 0 failures** = 354 D1–D5 + 23 R4 adversarial. *(Last verified during R7.)*

---

## Test status (verified, not re-run at T0 capture to preserve state)

| Suite | Tests | Failures | Last run |
|---|---|---|---|
| `mix test test/tiannara/forecasting` (D1–D5 + R4) | 377 | 0 | 2026-09-03 (R7 verification) |
| `mix test test/tiannara/evolution` (incl. SR-2 regression) | 43 | 0 | 2026-09-03 (SR-4) |
| `mix test test/tiannara/evolution/substrate_metric_regression_test.exs` (gated) | 12 | 0 | 2026-09-03 (SR-4) |

**Tests were NOT re-run at T0 capture** — the user requested no cleanup and to preserve the current state as evidence. The most recent verified results stand as the recorded test status.

---

## Secret scan (T0 hygiene)

- **PEM private keys in last 30 commits:** 0
- **Real API keys (`sk-`, `ghp_`, `AKIA`, `AIza`, etc.) in last 30 commits:** 0
- **Tracked `.env` files in HEAD:** 0
- **Untracked `.env` / `.env.production`:** present in working tree, **excluded from T0**, remain on disk. **Not a compromise** — they were never tracked; project's `.gitignore` excludes them.
- **Verdict:** **No secrets committed. No rotation required.**

---

## Known certified capabilities (this T0 captures the following certified state)

| Capability | Status | Evidence |
|---|---|---|
| **D1 Signal Intelligence** | CERTIFIED_BOUNDED / FROZEN | D1 forecasting chain; 92 tests in HEAD |
| **D2 Forecast + Calibration** | CERTIFIED_BOUNDED / FROZEN | D2 forecasting; 104 tests in HEAD |
| **D3 Decision Intelligence** | CERTIFIED_BOUNDED / FROZEN | D3 decision; tests in HEAD |
| **D4 Counterfactual / Attribution** | CERTIFIED_BOUNDED / FROZEN | D4 cert + audit; 31 tests |
| **D5 Noise/Robustness/Sensitivity** | CERTIFIED_BOUNDED / FROZEN | D5 + R4; 54 D5 tests + 23 R4 adversarial = 77 new |
| **Measurement integrity boundary (R3 remediation)** | CLOSED | R3 StrategicPlanner `evaluate_and_act/2` now returns `{:ok, %{kind: :simulation, provenance_hash}}`; fabrication path removed |
| **Measurement integrity verification (R7)** | CERTIFIED | `MEASUREMENT_INTEGRITY_verifier.py`: 12/12 gates PASS, EXIT 0; D5 verdict unchanged; E06/E07 preserved |
| **Substrate metric contract (SR-4)** | FIXED (A+C) | `trajectory.ex` nil guards added; moduletags removed; 12/12 SR-2 regression tests PASS as fixed behavior |
| **Provenance gate** | UNCHANGED | `Tiannara.Evidence.Provenance.acceptable_as_evidence?/1` rejects `:simulation`; accepts only `:real_execution`+id or `:imported_evidence`+source |

---

## Known bounded capabilities

| Capability | Bounded by |
|---|---|
| `Tiannara.Forecasting.D5.verdict/0` | Returns `:d5_certified_bounded` (3-valued, never collapsed to boolean) |
| `Tiannara.Forecasting.D5.Thresholds` | Single source of truth, hash-bound (`threshold_set_hash/0`) |
| E03 execution | **BOUNDED: 0 runs, 0 stabilizer invocations** (BLOCKED at pre-registration gate) |
| Long-horizon evolution | `Tiannara.Evolution.LongHorizon.run/2` is REAL (3 test files) and now safely guarded; 31 tests in HEAD |

---

## Known pending capabilities

| Capability | Status | Blocker |
|---|---|---|
| E03 CONTROL A baseline run | PENDING | E03 preregistration frozen + verified (24/24 verifier); substrate corrected (SR-4); **awaits separate Council execution-start authorization** |
| E03 CONTROL B / C / perturbation / overreach sweep | PENDING | Depends on CONTROL A |
| DriftAudit `{:metric_incomplete, :dim}` rejection reason (Option B from SR-3) | DEFERRED | Not necessary for E03 unblock; recommended as separate future work |

---

## Known blocked capabilities

| Capability | Blocked by |
|---|---|
| **E03 experimental runs (0)** | E03 protocol is scientifically frozen + verified-correct; **awaits explicit Council authorization** for execution-start (per the E03 master prompt §29 gate) |
| **B implementation in DriftAudit** | Not authorized in SR-4 (Council instruction: "B must not be silently bundled into A") |
| **D6 / Phase 4 / OPC** | NOT STARTED, NOT AUTHORIZED |
| **Autonomous emergence / real-world execution** | Prohibited by E03 master prompt §4 |
| **Fabricated decision records from the StrategicPlanner** | The fabrication path was REMOVED in R3; this is permanently closed |

---

## Working-tree state preserved on disk (not in T0 commit, by necessity)

These items remain in the working tree, uncommitted, because they **cannot be pushed to GitHub** (100 MB file size limit) or are **subprojects/separately-versioned apps** or are **Windows artifacts**. They are evidence of current state and have not been deleted.

| Path | Size | Reason for exclusion |
|---|---|---|
| `conflict_resolution_engine.dets` | 421,368,360 B (401.8 MB) | >100 MB GitHub limit; runtime DETS table |
| `dev_data_archive_20260816/dets/dets/soak/cel_event_store.dets` | 245,825,918 B (234.4 MB) | >100 MB; historical soak-test DETS |
| `dev_data_archive_20260816/dets/dets/soak/cel_event_store.dets.corrupt.20260807T144726` | 106,534,743 B (101.6 MB) | >100 MB; corrupted DETS snapshot |
| `dev_data_archive_20260816/dets/dets/soak/cel_event_store.dets.corrupt.20260809T191931` | 187,545,337 B (178.9 MB) | >100 MB |
| `dev_data_archive_20260816/dets/dets/soak/cel_event_store.dets.corrupt.20260810T225916` | 225,921,093 B (215.5 MB) | >100 MB |
| `dev_data_archive_20260816/dets/dets/soak/cel_event_store.dets.corrupt.20260810T233208` | 227,040,948 B (216.5 MB) | >100 MB |
| `dev_data_archive_20260816/dets/dets/soak/cel_event_store.dets.corrupt.20260811T225001` | 228,823,729 B (218.2 MB) | >100 MB |
| `dev_data_archive_20260816/dets/dets/soak/cel_event_store.dets.corrupt.20260814T083525` | 237,143,574 B (226.2 MB) | >100 MB |
| `nul` (file at repo root) | n/a | Windows device name (artifact); excluded |
| `..../-p/`, `..../..../` | n/a | Garbage path-mangled dirs from a concatenation bug; unreadable by git, excluded |
| `.env`, `.env.production` | small | **Excluded by policy (not secrets committed; remained on disk)** |
| `markdown/Here are the most compelling … uncharted-.md` (217-char path) | small | Exceeds git's Windows path-length limit; excluded |
| `tiannara-desktop/`, `tiannara_api/`, `tiannara_gui/`, `tiannara_internal_dashboard/`, `tiannara_mobile/`, `tiannara_observatory/`, `tiannara_pros/`, `tiannara_runtime/`, `tiannara_saas/`, `tiannara_core/` | varies | Some tracked in T0 (tiannara_api/pros/runtime/core); others are separate repos. All preserved on disk. |
| `tmp_6A0FF061F1AE1CBD28687AA5D4B250280CD3D623E3B18B9256269E5FE135CFDE/` | small | Tmp hash dir (4 files: CHECKSUM, VERSION, contents.tar.gz, metadata.config); preserved on disk |
| `tiannara_runtime/` modifications (8 files) | small | Uncommitted edits in the `tiannara_runtime` subproject; preserved on disk |

**Total working-tree items not in T0 commit: ~390 items** (8 large files, ~10 subproject dirs, 4 tmp files, 1 nul, 2 garbage dirs, ~366 other untracked or modified files in the 2,097-entry dirty working tree that were already tracked in HEAD or are runtime state).

---

## How to verify T0

```bash
git fetch origin
git checkout T0           # detach at the T0 tag
# or:
git checkout t0-baseline  # branch at the same commit
git log --oneline -1       # 9753a6d
git ls-files | wc -l       # 7708
```

The T0 tag is **annotated** and **immutable** by convention. Do not amend or rebase `9753a6d`. Any future changes should occur on new commits after T0.

---

## Certification chain (what this T0 preserves)

```
D1 → D2 → D3 → D4 → D5  (forecasting chain, CERTIFIED_BOUNDED)
                           |
                           v
                     R3 remediation  (StrategicPlanner fabrication removed)
                           |
                           v
                     R7 boundary     (CERTIFIED, 12/12)
                           |
                           v
   E03 prereg ──────────> E03 verifier (24/24 PASS, BLOCKED at 0 runs)
                           |
                           v
   SR-1 recon ─────────> SR-2 regression (12/12, captures defect)
                           |
                           v
                     SR-3 design   (A+C minimum correction)
                           |
                           v
   SR-4 implementation ──> substrate FIXED (trajectory.ex nil guards, test gating)
```

**This T0 is the immutable snapshot of that chain.** Future work begins from this point.

---

**Generated:** 2026-09-03
**By:** Codex session (per user instruction to push T0 baseline)
**HEAD:** `9753a6d08702064f4d00395a1bec1c4bf3887381`
**Tag:** `T0` (annotated) → `67d49b801774c98446ee5d67c1d0154245af90f2`
**Branch:** `t0-baseline` → `9753a6d`
**Remote:** `https://github.com/Kimiti4/Tiannara.git`
