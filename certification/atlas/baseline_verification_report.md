# Baseline verification report and next recommended remediation batch (Phase R0 deliverable 10)

**Baseline under verification:** `Kimiti4/Tiannara` @ `local/pr4` @ `521cb7fe513a466302ec3bb398940df3814edf2d`
**Verified on:** 2026-10-20 (read-only discovery; no production code modified, moved, or deleted)

---

## 1. What was verified, and how

| # | Claim | Method | Result | Evidence binding |
|---|---|---|---|---|
| V-1 | The repository is at the stated SHA on the stated branch and the branch is in sync with `origin` | `git rev-parse`, `git remote -v`, `git log -1` | SHA `521cb7fe…`, branch `local/pr4`, in sync | `baseline.json` |
| V-2 | The working tree state is recorded and was not altered by the audit | `git status --porcelain` before/after | 1819 entries (31 M / 470 D / 1318 ??) before; no new modifications to tracked files during R0 | `baseline.md` §working-tree |
| V-3 | The Elixir CI required job is green at the baseline SHA | `gh run view 39392651371` | `success` | run 39392651371, sha `521cb7fe` |
| V-4 | The Cross-Platform Verification workflow is green at the baseline SHA | `gh run view 39392651343` | `success` | run 39392651343, sha `521cb7fe` |
| V-5 | The root Elixir project suite passes (387 tests) | CI job `suite` in run 39392651371 | green | run 39392651371 |
| V-6 | The `tiannara_runtime` suite passes (1854 tests + 40 properties, 6 excluded) | CI job `tiannara-runtime-suite` in run 39392651371 | green, `seed: 0` | run 39392651371 |
| V-7 | Quarantined tests are known-failing and non-blocking | CI job `tiannara-runtime-quarantine` + local `--only quarantine` | 6 tagged; 3 fail locally (omega ×2, reactivity) | `TIANNARA_RUNTIME_TEST_INVENTORY.md` |
| V-8 | The 5F.5/5F.6 verification scripts fail honestly (not loosened) | `tiannara_runtime/scripts/verify_phase_5f5_core.exs`, `verify_phase_5f6_opc.exs` | EXIT=1 (3 core failures; 1 OPC gate gap) | scripts in-repo |
| V-9 | Every in-scope path in the worktree is accounted for in the file inventory | Full `os.walk` (excluding `.git` internals) cross-mapped against `git ls-files`, `git ls-files -o`, `git ls-files -o -i` | 207,028 rows: 206,558 on disk + 470 tracked-but-absent; 0 unaccounted paths | `file_inventory.csv`, `file_inventory_summary.json` |
| V-10 | Every exclusion has a recorded reason | Classification pass over the whole tree | vendor/generated/tooling-state/oversize/deleted-tracked all carry explicit reason codes | `file_inventory_summary.json` §exclusion_policy |
| V-11 | Every capability row parses and carries the mandated classifications | Programmatic re-read of all 6 capability registers | 117 capabilities; states and reconciliations normalized to the 5 evidence states and 4 reconciliation classes | `capability_register.csv` |
| V-12 | Every finding is a real row with evidence, not a narrative claim | Cross-read of the 130 ledger rows against their source section files | 130 findings: 13 critical / 48 high / 59 medium / 10 low; 20 explicit duplicate links | `findings_ledger.csv` |
| V-13 | All four dependency views are machine-readable and internally consistent | JSON parse + node/edge reference integrity | code 29/29 · runtime 117/110 · governance 85/86 · build 51/46; 5 code cycles, 21 runtime gaps, 18 governance discrepancies, 13 build discrepancies | `deps_*.json` |
| V-14 | The ESAP repository was inventoried separately and not merged | Independent shallow clone (`main` @ `062cbeb`, 3,386 files) + 16-capability register | 16 capabilities; 10 findings; zero cross-repo imports of `MindCache`/`UEP`/`ISD v2.0`/platform protos | `esap/esap_inventory.md` |
| V-15 | The atlas registers are internally consistent with each other | Programmatic cross-check of capability ids, finding ids, cluster membership and graph references | All referenced capability ids exist; no dangling graph endpoints; section files map 1:1 to registers | this pass |

## 2. What was NOT verified (and must not be inferred as verified)

| # | Not verified | Why | Consequence |
|---|---|---|---|
| N-1 | Runtime behaviour of any capability | R0 is read-only discovery; no application was booted, no mix task run, no campaign executed | Zero dependency edges are `dynamically_observed`; all 130 findings rest on static/documentary evidence |
| N-2 | Whether either Elixir application boots end to end at this SHA | No boot performed (and `MIX_ENV=prod` cannot compile: `config/prod.exs` missing — F-ARC-014) | "Wired" claims are test-time wiring claims until Batch 2 |
| N-3 | Whether the governance test suite currently passes | Test definitions exist; no test was executed during R0 (a test definition is not proof a test ran) | Governance findings are structural, not "tests are red" |
| N-4 | Whether the Python services import cleanly / their test suites pass | No `pytest` run | F-ARC-012 (import cycle) is static-only |
| N-5 | The three frontends absent from git | They are not in the repository (F-PLT-003, F-ARC-024) | The WebGL Observatory capability is unauditable, not verified |
| N-6 | The external specifications (CAE v1.1, CAP v1.0, ISD v2.0, IF-001..004, UEP) | Not present in the checkout (OP-02) | 22 capabilities remain `specified_not_proven`; their reconciliation is UNKNOWN/CONTRADICTED, never MATCHED |
| N-7 | Historical metric claims (GRCC 74.8 %, MSCL 88.5 %, 12-world/84-civ/23 800-agent) | No generating artifact exists; observed MSCL metric is 0.0 | Retired as acceptance criteria pending OP-05 |
| N-8 | 15 findings that cannot be settled from in-repo evidence | Each names the evidence required (ledger §3) | They stay `OPEN` with a named unblocking step |
| N-9 | The working tree's 470 deleted tracked files and 31 modified `.dets` files | Pre-existing runtime churn; left untouched per operator directive | Not an audit defect; recorded so later diffs are not misread |

## 3. R0 exit condition — self-assessment

The operator's exit condition: *"the in-scope repository inventory is accounted for, the critical execution and authority paths are mapped, known discrepancies are recorded, evidence gaps are explicit, and a dependency-aware remediation backlog is ready for execution."*

| Requirement | Status | Basis |
|---|---|---|
| In-scope repository inventory accounted for | **MET** | 207,028 paths, every exclusion with a reason (V-9, V-10) |
| Critical execution and authority paths mapped | **MET (static)** | 4 dependency views; boot trees, entry points, authority chain, persistence owners, security boundaries (N-1 limits the claim to static) |
| Known discrepancies recorded | **MET** | 130 findings; 38 CONTRADICTED + 13 UNKNOWN capabilities; 13 explicit source disagreements |
| Evidence gaps explicit | **MET** | This section; N-1..N-9; ledger §3 and §5; per-capability "explicit unknowns" in all six section files |
| Dependency-aware remediation backlog ready | **MET** | `remediation_backlog.md` — 7 batches + 5 operator actions, ordered, with acceptance criteria and blast radius |

**R0 is complete for the Tiannara AI platform repository and for a separate ESAP inventory. It is not a certification of any capability.** Per the operator instruction, the work stops here for review; Phase R1 has not begun and no production code was changed.

## 4. The single next recommended remediation batch

**Batch 1 — Constitutional enforcement integrity and fail-closed claim control** (full specification in `remediation_backlog.md`).

| Item | Finding | Why in this batch |
|---|---|---|
| 1.1 | F-GOV-007 — a policy `:approve` bypasses hard invariants | Safety-relevant; the decision is made *before* the vet runs. Must be first, because item 1.2 makes `:approved` reachable and would expose the bypass |
| 1.2 | F-GOV-006 + F-GOV-023 — the Council can never return `:approved`; the plugin path is dead | Removes the "every authorization is really conditional" state, but only after 1.1 |
| 1.3 | F-GOV-003 — two policies are permanently dead (`:any` matched literally) | One-line semantics fix that makes high-risk and invariant-protection policies actually apply |
| 1.4 | F-GOV-005 — `permitted?/1` accepts `:conditional` | Closes the machine-grant path; negative test available |
| 1.5 | F-GOV-004 + F-GOV-017 — human approval has no resume path; the state machine authorizes itself | Unblocks the constitutional executive and the privileged operations; depends on 1.1–1.4 for a correct decision to resume |
| 1.6 | F-ARC-007 + F-GOV-011 — the audit verifiers cannot fail | Restores truthfulness of the evidence system that every later closure claim depends on |
| 1.7 | F-GOV-013 — the kill switch never runs; the consumer API is dead; an unguarded `send/2` raises | Safety control that must be demonstrably activatable |

**Batch 1 acceptance criteria (all required before any of these findings may move past `FIXED_PENDING_VERIFICATION`):**

1. For every item, a test that fails before the change and passes after it, in the required CI job (not a local run, not a test-only path).
2. Negative/denial-path tests for 1.1, 1.4 and 1.6 (an invariant violation, a conditional decision, and a false claim must all be denied/failed).
3. `mix test --exclude quarantine` green in `tiannara_runtime` and `mix test` green in the root project at the batch SHA; no existing test deleted or weakened.
4. Blast-radius check: every consumer of `Council.authorize/3`, `Authorization.permitted?/1`, the kill-switch API and the audit verifier is enumerated and re-tested (use `deps_code.json` consumers, not guesswork).
5. Evidence bound to the exact SHA in Register 6 (command, exit status, logs, environment), then findings moved `OPEN → FIXED_PENDING_VERIFICATION → VERIFIED_CLOSED` only after that evidence exists.

**Explicitly out of Batch 1:** certificate signing/key management (operator-deferred Babel/C-08), the ESAP track, the reachability work (Batch 2), and any architectural merge or file move — those are R2/R3 work under the operator's phase table and must not be smuggled into a stabilization batch.

## 5. Risks in executing Batch 1

| Risk | Mitigation |
|---|---|
| Fixing the RuleEngine (1.2) before the invariant bypass (1.1) exposes the bypass to live traffic | Enforced ordering; 1.1 lands and is verified first |
| Starting `PrincipleRegistry` (1.2) changes the scorer's behaviour repo-wide | Run the full runtime suite; compare the decision distribution before/after in the same run |
| `permitted?/1` (1.4) may be relied on by callers that accept conditional grants | Enumerate consumers first; migrate them to an explicit conditional API rather than loosening the predicate |
| Reviving the audit verifier (1.6) may turn existing "PASS" reports into failures elsewhere | The 220/220 reports are explicitly non-evidence (F-ARC-007); re-baseline rather than suppress |
| Human-approval resume (1.5) introduces a new concurrent path | Resume in a supervised coordinator; the resume re-evaluates the decision rather than trusting the record |
