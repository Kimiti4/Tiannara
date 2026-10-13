# TIANNARA V1 CLOSURE BASELINE

**Type:** read-only reconciliation — Codex master program §38, first action
**Executed:** 2026-09-24 · **Consumes:** 2026-09-23 pre-commit audit, `docs/capability_ledger.md`, `docs/production_completion_baseline.md`
**Scope honored:** no code written, no refactors, no dependencies installed, no commits. The only writes are this file and one citation correction in the capability ledger (§2.4).

---

## 0. Method

- All 15 §38 inspection surfaces executed: git branch/HEAD/status/log · repository topology · test topology · application boot topology · B12/D-C files · D-A12 files · D-A2/B11 files · B5/D-A6 files · `.git/info/exclude` · evidence tests · capability registry/census · constitutional gates · authorization/effect sinks.
- Nothing expensive re-run: the fresh 13-file batch (**39 tests / 0 failures**, boot `Status: ready (559 ms)`) and both audit probes were executed earlier in this same working tree; today's pass adds only read-only commands.
- **Tooling caveat discovered:** `git grep` does not see *untracked* files. `lib/tiannara/external/`, `lib/tiannara/observatory/live_projection.ex`, `tools/audit/`, `docs/*` and all git-excluded tests are invisible to it. Claims touching those paths were re-verified with filesystem grep (§1.9, §1.10).

---

## 1. Verified current facts (fresh)

### 1.1 VCS & working tree

| Fact | Value |
|---|---|
| Branch | `local/pr4` |
| HEAD | `b564fbe9` — *"fix: retained-failure remediation — register KEE/EV, start ValidationCampaigns, CRE rotation, KC evidence persistence, lifecycle API completion"* |
| Recent history | `cc01fd6e`, `de0368d0`, `c7826235`, `f2cf36d2` — prior remediation commits already exist on this branch |
| `git status` | **68 modified / 275 untracked / 5 deleted / 348 total** |
| Corruption-noise entries | **232** (audit counted 230; Δ explained in §2.1) |
| Real commit set | ≈50 source/doc files (see §5) |
| Council corruption archives (root) | **608**, newest **2026-09-22 04:16**, oldest 2026-08-16 |

### 1.2 Fresh proof (this working tree, unchanged since)

| Proof | Result | Artifact |
|---|---|---|
| 13-file combined batch | **39 tests, 0 failures**, boot `Status: ready (559 ms)` | `tools/audit/evidence_2026-09-23_precommit_audit_39_green.out` |
| `mix compile` | EXITCODE=0, 0 errors, 0 warnings in edited files | verified in-session |
| Gate-integrity probe (34 services) | **0 unreachable constitutional-score MFAs, 0 unreachable health MFAs** | `evidence_2026-09-23_precommit_gate_integrity.out` |
| Theatrical probe (post-remediation world) | D-B/D-A1 closures live-proven; ReplayEngine all-1.0; CIS accepts `%{evil: true}`; `:dets.repair_file` missing | `evidence_2026-09-23_precommit_theatrical_probe.out` |
| Dev boot probe | **63 children**, `asc_enabled=true`, 34/34 `:ok` | `evidence_2026-09-23_gatefix_dev_boot_63_children.out` |

### 1.3 Test topology

| Fact | Value |
|---|---|
| Test files | **343** |
| Evidence tests hidden by `.git/info/exclude` (L42–52: `/test/`, `**/test/`, `**/*_test.exs`, …) | **10 / 10** (all named in §5) |
| Tests using `start_supervised!` (bang — the topology-conflict class) | **31 files** |
| Proven adopt-or-start anchor pattern | `test/tiannara/asc/core/supervisor_topology_test.exs` (`Process.whereis → adopt, else start_supervised`) |
| Test isolation key | `config/test.exs:25` → `"./test_data/dets/#{System.unique_integer([:positive])}"` — **per-VM, repeats across fresh VMs (D-A5 confirmed)** |
| Test storage routing | `storage_context: "test"`, `dets_base_path` per-run, `test_helper.exs` wipes only the *current* run's dir |

### 1.4 Boot topology

| Fact | Value |
|---|---|
| `config/config.exs:159-160` | `config :tiannara, :asc, enabled: true` — ASC boots **globally in every env including test** (root of the ≥99-failure class) |
| Application children | `core_children ++ loop_children ++ asc_children(asc_enabled?)`; CEL boot runs synchronously under `test_mode: true` |
| Registry | **34** specs (`%{id:` count in `service_registry.ex`), each with `health_check` + `constitutional_score_check` MFA — all resolvable (§1.2) |

### 1.5 Constitutional gates (B12 surface)

| Fact | Value |
|---|---|
| Gate sequence | dependency → start → health → **constitution** → **capability** → resource (`boot_sequencer.ex`) |
| Fail-closed mechanics (added 2026-09-23) | raising/non-struct/uncomputable score → `ConstitutionalScore.unavailable/1` (zeros); exceptions → named `{:fail, … — fail closed}`; explicit stubs refused at the constitution gate |
| **Value-level self-report (B12/D-C — OPEN)** | gate still trusts whatever `constitutional_score/0` returns; `ReplayEngine` returned **all-1.0 + 4 advertised capabilities** in today's probe while replay returns `:replay_source_unavailable` |
| On-path `ConstitutionalScore.default` (all-1.0) users | **2 registered services**: `capability_graph.ex:123` (unhealthy branch → perfect score!), `discovery_supervisor.ex:34` (rescue → perfect score) |
| Dormant (unregistered) `default` users | 4: `cel/{metrics,planner,scheduler,resource_governor}.ex` — score-shaped but not in the registry |
| `def constitutional_score` implementations repo-wide | **55 files** (34 registered services + others) |

### 1.6 D-A12 / recovery ladder (B15 surface)

| Fact | Value |
|---|---|
| `executive/dets_store.ex:68-70` | `repair/1` calls `:dets.repair_file/1` |
| OTP 28 measurement (today) | `function_exported?(:dets, :repair_file, 1) → false`; `repair_continuation/1 → false` |
| Blast radius | `recovery.ex:31-41 attempt_repair` (case on the raise → **backup-promotion fallback unreachable**); callers `executive_memory.ex:353` (manual `:recover`) and `:526` (`startup/1` → raise escapes toward init) |
| **Council audit log does NOT use the broken primitive** | `audit_log.ex:241-266` uses the real mechanism `:dets.open_file(…, repair: true/false)` + `archive_corrupted_file/1` (L274-291) + `record_corruption_event/1` — D-A12 scope is **ExecutiveMemory only** |

### 1.7 Corruption classification evidence (B5/D-A6 surface)

| Fact | Value |
|---|---|
| Root archives | 608 static across **all of today's runs** (newest root archive = 2026-09-22 04:16) |
| **Recurrence TODAY: confirmed — 2 new files** | `dev_data/…/council_audit_log.dets.corrupted.2026-09-23T23-11-18Z` + `dev_data/…/cel_event_store.dets.corrupt.20260923T231124` (written 02:11 local this session) |
| Clean-start observation (baseline §5.1) | `AuditLog: DETS file requires repair. Archiving corrupted file.` observed on clean starts |
| Classification | **mixed**: historical residue (root, 08-16→09-22) **+ live recurrence** (dev tree, today). Not test residue alone — the dev-context write proves production-path corruption still occurs. Do not delete-and-declare (program §6) |

### 1.8 Authorization / effect-identity sinks (traced)

| Sink | Evidence |
|---|---|
| Ω deployment | `deployment_gateway.ex:53-80,241` — `effect_identity/1`, `check_not_already_deployed` via `DeploymentRegistry` (same-auth/same-effect rejection) |
| External read | `external/read_only_http.ex:39-42` — `effect_identity(url) = sha256({:read_only_get, url})`; grant bound via `valid_for?(grant, {:external_read, url})`; loopback allowlist (L57); `autoredirect: false` (L78); 1 MiB cap; authenticated identity required — **verified in source today** (file is untracked → invisible to `git grep`, see §0) |
| Human grant minting | `Authorization.human_grant/2-3` + `AuthenticatedHumanIdentity` (B4, 2/2 tests) |
| Known open | D165-class closure proven only at these 2 sinks; no universal authorization→effect invariant (ledger rows 16/17 pending edges) |

### 1.9 Knowledge-recovery claims re-verified (filesystem grep, whole `lib/`)

- `gap_recovery` → **0 matches** (ledger row 22 claim **holds**)
- `capability_negotiation` → **0 matches** (row 22 second half **holds**)

### 1.10 Reality-graph topology (target of the §5.1 timeout)

- **Two distinct modules, both wired:** `Tiannara.World.UnifiedRealityGraph` (CEL registry `service_registry.ex:184-189`; `control_center.ex:19`) **and** `Tiannara.Graph.UnifiedRealityGraph` (`control_center.ex:20` as `:graph_unified_reality_graph`; aliased by knowledge-workflow, discovery, coherence, reality paths).
- The recorded **5,000 ms `GenServer.call` timeout on the `:preserve` path** (baseline §5.1) names the Graph variant under test load; the `:preserve` call itself is `cci/civilizational_memory_engine.ex:14/25` (in-memory state). Neither graph module implements `:preserve` — the timeout sits in the call chain *into* the Graph variant. Diagnosis target §4.6; **measure before touching**.

---

## 2. Discrepancies against the 2026-09-23 pre-commit audit

| # | Audit claim | Today's measurement | Verdict |
|---|---|---|---|
| 2.1 | 68 M / 274 ?? / 5 D / 347 total; noise 230 | 68 / **275** / 5 / **348**; noise **232** | **Δ explained:** +2 corruption archives written today (§1.7), −1 transient scratch log deleted. No material drift. |
| 2.2 | Corruption 608, recurrence unresolved | 608 root static **+ 2 new dev-tree archives today** | **Sharpened:** recurrence live on dev path — B5/D-A6 = "residue **+ live recurrence**". |
| 2.3 | 39/0, compile 0, 34 services, 63 children, tally 6/28/0/2/3 | re-measured identical | **MATCH** |
| 2.4 | Ledger D-A8 path `lib/tiannara/cis.ex` | module is `lib/tiannara/cis_constraint.ex:17-20` | **CORRECTED in the ledger this pass** (only ledger write made) |
| 2.5 | `gap_recovery: 0 matches repo-wide` | filesystem grep 0 (`git grep` would false-negative: live_projection.ex untracked) | **HOLDS** (method corrected) |
| 2.6 | — | `git grep` blind to all untracked paths | **NEW process finding:** repo-wide claims must use filesystem grep until paths are committed (§5) |

---

## 3. Blocker dependency graph

```text
B12 / D-C  (gate value recomputation) ─────────────┐
                                                    ▼
B15 / D-A12 (repair ladder) ──► recovery proofs ──► B5 / D-A6 (audit durability proof)
        │                                    ▲
        └── needs ▼                          │
D-A5 test isolation ─────────────────────────┘  (clean proof runs for BOTH)

D-A2 / B11 (one real research closure) ── soft-depends on B12 (validation gate must be trusted)

Regression topology green ── independent of code fixes (test-pattern work);
    includes :preserve timeout diagnosis (§1.10)
        │
        ▼
Wave 3: single-trace organism mission (consumes all of the above)
        │
        ▼
Production profiles (DEMO/PERSONAL/RESEARCH/SAFE) → executable certification → demo/personal
```

Ordering unchanged from the program: **B12 → B15 → D-A5/proofs → B11 → D-A6 → topology → Wave 3 → productionize → certify.** No fresh evidence justifies reordering; D-A5 is slotted adjacent to B15 because B15's recovery proofs are untrustworthy without it.

## 4. Blocker dossiers — exact smallest next change, evidence, tests, risks

### 4.1 B12 / D-C — gate value recomputation (DEEPEST BLOCKER)

**Current evidence (today):** fail-closed mechanics landed 09-23 (exceptions, non-structs, explicit stubs) but the gate still *credits whatever value* `constitutional_score/0` returns. Probe today: `ReplayEngine` = all-1.0 + 4 advertised capabilities while `replay/3 → :replay_source_unavailable`. On-path perfect-score fabrication: `capability_graph.ex:123` (unhealthy→default 1.0), `discovery_supervisor.ex:34` (rescue→default 1.0).

**Exact smallest next change:** add an **independent corroboration step** inside `BootSequencer.check_constitution/2` (and/or a new evidence-gate step fed by CRAV signals — `ParticipationGraph` activity, telemetry-handler counts, process liveness — per the F-A prescription already written in the baseline): a claimed score is *corroborated* or it is not boot-ready. **Forbidden shortcut (B12 row):** editing any service's `constitutional_score/0` to be "honest" instead of fixing the gate. Calibration case that MUST flip: `ReplayEngine` fails admission. Registered services with real observable activity must still pass.

**Files:** `cel/kernel/boot_sequencer.ex` (`check_constitution/2`, public for tests), possibly a small evidence-adapter reading `crav/participation_graph.ex` outputs; **no service score functions touched**.

**Required evidence (program §5):** positive (real service passes) · negative (fabricated-perfect with zero corroborating activity fails) · tampered (score mutated upward → still fails) · stale (old `computed_at`) · missing (no evidence source) · unreachable dependency · regression (39-test batch stays green).

**Tests:** new `boot_sequencer_value_gate_test.exs` (calibration: ReplayEngine fails; controlled fake service cases) + full focused batch.

**Risks:** idle-but-legitimate services could false-fail → scope corroboration to *perfect-score claims* or to advertised `provides:` primitives, and record any service whose status flips as a finding, not as a test to weaken. Boot may go `ready → degraded` honestly; that is an acceptable, evidence-backed outcome.

### 4.2 B15 / D-A12 — DETS recovery ladder

**Current evidence (today):** OTP 28: `:dets.repair_file/1` and `:dets.repair_continuation/1` both **false** (measured). `recovery.ex:31-41` cases on the result → `UndefinedFunctionError` escapes → `attempt_backup_promotion/1` unreachable. Live callers: `executive_memory.ex:353` (manual `:recover`) and `:526` (`startup/1` — raise escapes toward init). **Scope narrowed:** Council audit log uses the real `:dets.open_file(…, repair: …)` mechanism (§1.6) — unaffected.

**Exact smallest next change:** `DetsStore.repair/1` → return named fail-closed `{:error, :dets_repair_unavailable}` (one-line contract change); `attempt_repair`'s existing `{:error, reason}` arm then routes to backup promotion — the documented ladder order is restored without inventing a storage abstraction. Real repair (delete/restore semantics) stays separate work, recorded as a residual.

**Files:** `executive/dets_store.ex:68-70`, `executive/recovery.ex` (verify arms only).

**Required tests (program §6's 10):** healthy DETS · corrupted DETS · repair primitive unavailable · backup available → promotion runs · backup unavailable → fresh start (`{:ok, nil}` path already exists at `recovery.ex:50-53`) · repeated recovery · cold boot · warm restart · recovery after process crash · recovery after incomplete write. Plus: no exception escapes, fallback reachable, no fabricated state, recovery recorded (telemetry/log evidence), corruption never reported as success.

**Risks:** masking that real repair is missing (mitigate: named error + ledger residual note); `startup/1`'s `{:error, _}` arm already degrades to `:active`-fresh — verify it stays honest (`:degraded` status, not silently `:active`).

### 4.3 D-A5 — test/DETS isolation (proof enabler for B15 + B5)

**Current evidence (today):** `config/test.exs:25` → `"./test_data/dets/#{System.unique_integer([:positive])}"` — unique *within* a VM, **repeats across fresh VMs**; `test_helper.exs` wipes only the current run's path, so prior-run residue can be inherited. Also observed: a dev-context corruption pair written at 02:11 this session (§1.7) while ostensibly-isolated runs were executing — cross-context write routing itself needs diagnosis as part of this blocker.

**Exact smallest next change:** make the run directory identity genuinely unique across VMs (e.g. `#{System.system_time(:microsecond)}_#{:erlang.unique_integer([:positive, :monotonic])}` or a `TEST_PARTITION`-style env var), add stale-run directory GC policy, and audit `Storage.Paths` context resolution so test runs cannot write `dev_data/**` or root paths.

**Required proof (program §7):** run A → state A; fresh-VM run B → different path; A invisible to B; repeated fresh VMs never collide; abnormal termination leaves residue that the next run does not inherit; concurrent execution (if applicable).

**Risks:** tests asserting literal paths (search before changing); `storage_context: "test"` routing gaps — treat any test-env write outside `test_data/`+`data/test/` as a defect, not a nuisance.

### 4.4 D-A2 / B11 — ONE real research closure (vertical slice)

**Current evidence (today):** 34 organ verdicts quarantined fail-closed; 20/31 `generate_hypotheses` still `{:ok, []}`; ADE (`asc/autonomous_discovery.ex`) already wires **Physics** (real pilot) + Chemistry candidates, already handles `{:error, reason}` arms, already calls `KnowledgeRepresentation.assert_fact` on validation success (L35-51). `domains/physics.ex` provides the real chain: `pilot_experiment/0` (damped oscillator spec) → `simulate/2` (real RK4 + provenance) → `validate/1` (structural energy checks, independent of the generator, fail-closed `{:error, :formal_verification_unavailable}`).

**Domain chosen: Physics** — deterministic, tractable, CI-repeatable, already bridged (`execute_experiment/1`), zero new platform required.

**Exact smallest next change:** close the loop *in ADE for the physics candidate only*: form one explicit hypothesis *from the pilot's real state* → run `simulate/2` → measure (trajectory/energy from RK4 output) → `validate/1` (already independent) → record provenance (`Provenance.build` already attached in physics) → `assert_fact` **with one trace/mission id** flowing through all steps → knowledge update. Add the honesty cases: an *invalid* hypothesis (unstable parameters) must be rejected/downgraded by validation; a missing measurement must not produce success-shaped conclusion; conflicting result stays visible.

**Required evidence (program §8):** valid hypothesis · invalid hypothesis · successful experiment · failed experiment · contradictory evidence · missing evidence · provenance chain · knowledge update · repeatability (CI-run twice → same verdicts).

**Risks:** scope creep into all 31 domains (forbidden — one slice); letting ADE's `{:ok, :hypothesis_rejected, …}` path masquerade as success (assert it is *recorded as rejection*, not counted as discovery).

### 4.5 B5 / D-A6 — constitutional audit durability

**Current evidence (today):** root = 608 historical archives (08-16 → 09-22), static through all of today's runs; **but 2 NEW dev-tree archives written today at 02:11** (council audit log + cel_event_store) → live recurrence on the production path. Mechanism audited: `audit_log.ex` opens strict (`repair: false`, L241) → on `{:error, {:needs_repair, _}}` archives the file (L246-247) → retries with `repair: true` (L249) → falls back to remove-and-fresh (L256-266); chain-hash + Merkle + `verify_integrity/0` exist. So detection/containment/archival are real; **the open question is why DETS files arrive `needs_repair` at all** (kill-without-sync? concurrent writers? rotation ordering? strict-open false positives after normal shutdown?).

**Exact smallest next change:** *diagnose before fixing* — instrument one dev cold-boot cycle: archive count + file state before/after N clean boots and one kill-during-write reproduction; classify each new archive against (a) abnormal termination residue, (b) shutdown ordering/sync gap, (c) concurrent append, (d) rotation/lifecycle bug. Only then apply the smallest durability correction (likely sync/close ordering or single-writer enforcement — B5's prior work already added sync-on-termination; verify it is actually on every exit path).

**Required proof (program §9 + B5†):** zero new archives across N≥10 cold boots + 1 kill-reproduction that *archives without loss* + `verify_integrity/0` = `:ok` across restart + corruption never silently rewritten + degraded mode exercised (append returns `{:error, :storage_degraded}`, chain tip genesis visible).

**Forbidden:** deleting the 608 as a "fix"; declaring durability because archives exist.

### 4.6 Regression suite topology + the `:preserve` timeout

**Current evidence (today):** `config.exs:160` `:asc, enabled: true` globally (incl. test) + **31 test files use `start_supervised!`** (bang → `{:already_started}` raise class ≥99 failures); the adopt-or-start anchor pattern already exists (`supervisor_topology_test.exs:4-21`); D-A5 cross-run residue is a second, interacting cause. The **5 s `GenServer.call` timeout on `Tiannara.Graph.UnifiedRealityGraph` / `:preserve` path** (§5.1) is *not yet re-measured* — target chain identified in §1.10.

**Exact smallest next change:** (i) classify the 31 bang-files into **global-topology** (need the booted app — adopt-if-running helper, exactly the anchor pattern, extracted to a shared test support function) vs **isolated-subsystem** (must own their supervisor — start under a unique test name or `--no-start`-style local boot); apply the helper to the global class only; (ii) reproduce the timeout in isolation (focused run of `graph/unified_reality_graph_test` + civilizational-memory path under load), measure mailbox/scheduler/lock state, classify cause, fix only after diagnosis.

**Forbidden (program §10):** disabling ASC globally, weakening/deleting/pending assertions, reordering to dodge races, silent exclusions.

**Acceptance:** focused suites green → integration green → full `mix test` green **or** every remaining failure individually classified as environment-only with written justification. UnifiedRealityGraph: no timeout under the reproduced load, with before/after measurement recorded.

## 5. Commit readiness (decisions reserved for the authorization gate)

**Suggested first commit — `01-precommit-audit-baseline`:**

| Include | Contents |
|---|---|
| `docs/` | `capability_ledger.md`, `production_capability_ledger.md` (pointer), `production_completion_baseline.md`, **`tiannara_v1_closure_baseline.md` (this file)** |
| `tools/audit/` | 4 probes + diag script + **11 dated evidence `.out` files** |
| Evidence tests (**require `git add -f` or exclude-line removal — your §27 decision**) | `ctl_branch_validator_test.exs`, `boot_sequencer_gate_honesty_test.exs`, `domain_quarantine_test.exs`, `observatory/live_projection_test.exs`, `external/read_only_http_test.exs`, `omega/deployment_effect_identity_test.exs`, `omega/human_authorization_identity_test.exs`, `council/audit_log_durability_test.exs`, `crav/runtime_census_activation_test.exs`, `mix/tasks/tiannara_start_test.exs` — **10/10 currently hidden** by `.git/info/exclude` L42-52 |

**Follow-on implementation commits (after each blocker closes, program §28):** `02-gate-honesty-d-c` → `03-dets-recovery-d-a12` → `04-test-isolation` → `05-research-vertical-slice` → `06-audit-durability` → `07-regression-topology-green` → …

**Never commit:** the 232 corruption-noise entries, modified `*.dets` / `data/*` runtime residue, root scratch logs (`focused*.out`, `t1.out`, `full_suite.*`, `ledger_verify.*`, `remediation_*`, `gate_probe.out`, `tfull.*`, `compile_v2.out`), `Mnesia*`, `scratch/`, `dev_data_archive_*`.

**Process rule adopted (§2.6):** until paths are committed, all repo-wide code claims must be verified with filesystem grep, not `git grep`.

---

## 6. Stop — awaiting the authorization gate

Per program §38: *read-only reconciliation complete; no implementation performed.*

- **Deliverable:** this `TIANNARA V1 CLOSURE BASELINE` (facts, discrepancies, dependency graph, smallest-next-change per blocker, required evidence/tests/risks).
- **Writes made this pass:** this file + one citation correction in `capability_ledger.md` D-A8 (path `cis.ex` → `cis_constraint.ex`, §2.4). No source, config, or test files touched.
- **First implementation action on authorization:** Blocker 1 (§4.1, B12/D-C independent corroboration gate) — or an explicitly justified reorder per program §4.
- **Stop conditions active:** any authorization decision (commits, exclude-file changes, git add -f), any destructive action, any external consequential effect, any conflict between two constitutional requirements.

**STATUS: BASELINE COMPLETE — AWAITING AUTHORIZATION GATE.**






