# Register G (§4G) — Architectural Problem Detection (Phase R0)

**Date:** 2026-10-20 · **Branch:** `local/pr4` @ `521cb7fe` · **Mode:** read-only.
Each finding: `F-ARC-nnn`, severity, confidence (confirmed/hypothesis), evidence
(path:line or named prior audit), affected capabilities, minimal remediation,
acceptance criteria. Capability *names* are used pending Register 2 IDs (R1).
Security findings reference paths only; secret values are redacted. Reused
audits are cited, not re-derived. Nothing below was executed or fixed in R0.

Severity scale: critical > high > medium > low (critical = certification-
blocking, security-exposing, or safety-chain-integrity).

---

## F-ARC-001 — Two Elixir projects compile 28 identical fully-qualified modules
- **Severity:** critical · **Confidence:** confirmed
- **Category:** duplicate implementations / conflicting authority
- **Evidence:** R0 defmodule scan: root `lib/` (1,971 modules) and
  `tiannara_runtime/lib/` (1,375) share 28 names — `Tiannara.CIS.{Supervisor,
  CollapsePredictor,ImmuneDecisionEngine,RegulationExecutor}`
  (`lib/tiannara/cis/supervisor.ex:1` vs `tiannara_runtime/lib/tiannara/supervisors.ex:114`
  + `tiannara_runtime/lib/tiannara/cis/*.ex`), `Tiannara.OED.*` (10), `Tiannara.Sentinel.*` (3),
  `Tiannara.A10.*` (6), `Tiannara.P9X{,Ecosystem}.Supervisor`,
  `Tiannara.Meta.CausalTensegrityEngine`, `Tiannara.Core.Ontology.Index`,
  `CivilizationState` (`lib/tiannara/cci/models.ex` vs
  `tiannara_runtime/lib/tiannara_runtime/civilization/kernel.ex`).
  Root `_build` contains only `:tiannara` + `:forward_provenance` — no build
  mixes them today; the hazard is beam shadowing under any future co-deployment.
- **Affected caps:** immune/CIS, observatory/sentinel, OED, A10, P9X, civilization kernel.
- **Minimal remediation:** R1 decision register must name, per subsystem, which
  OTP app owns each duplicated `Tiannara.*` namespace; freeze edits to the
  non-owner copies; add a CI check (script) that fails when a `defmodule` name
  exists in both trees without an owner-record.
- **Acceptance criteria:** (1) decision record lists all 28 names with owner +
  disposition (keep/merge/adapterize/retire); (2) CI uniqueness check green on
  every push; (3) zero *new* cross-tree defmodule collisions.

## F-ARC-002 — KillSwitch triplication + dead consumer API
- **Severity:** high · **Confidence:** confirmed
- **Category:** duplicate implementations / undocumented interface
- **Evidence:** `PHASE_5F_STATUS_CORRECTION.md:188-195` (C-11):
  `multi_world/kill_switch.ex:1` (205 LOC), `hardened_kill_switch.ex:1` (270),
  `kill_switch_causal.ex:1` (170, wrong root namespace `Tiannara.MultiWorld.*`
  inside runtime tree); `multi_world/world_supervisor.ex:111-144` calls
  `KillSwitch.get_killed_worlds/0`/`request_kill/2`/`confirm_kill/2` that do not
  exist on the unified module (dead API).
- **Affected caps:** world management, safety chain, Safe Mode.
- **Minimal remediation:** operator-approved merge of Hardened + Causal features
  into `TiannaraRuntime.MultiWorld.KillSwitch`; delete dead world_supervisor
  API calls or reimplement against the unified contract; fix namespace.
- **Acceptance criteria:** one kill-switch module remains; world_supervisor
  compiles with zero undefined-function warnings; contract tests cover
  request/confirm/get_killed round-trip; C-11 entry marked remediated.

## F-ARC-003 — Constitutional authority scattered; runtime constitution module is dead
- **Severity:** high · **Confidence:** confirmed
- **Category:** conflicting authority / unused module
- **Evidence:** four constitution modules (§1.4 of ownership_duplicates.md):
  Council (boot-wired Tier 0, `application.ex:108`, DETS
  `constitution_repository.ex:8,24-29`) vs ASC (53 LOC) vs Civics (10 LOC) vs
  `TiannaraRuntime.Shared.ConstitutionalLaws` (55 LOC, grep = **zero refs**);
  two `ConstitutionalGovernanceEngine` modules (asc/civilization + cci);
  two principle registries with disjoint consumers
  (`council/principle_registry.ex` vs `os/principle_registry.ex`).
- **Affected caps:** constitutional governance, CEL scoring, OS governance.
- **Minimal remediation:** declare Council stack canonical in the decision
  register; retire ASC/Civics stubs and ConstitutionalLaws after owner sign-off;
  merge or cross-link the two principle registries in the same decision.
- **Acceptance criteria:** one constitution module + one principle registry per
  deployed app; dead modules removed or explicitly marked `@moduledoc false`
  legacy with zero boot cost; rule-engine tests pass on the chosen registry.

## F-ARC-004 — Event bus proliferation (≥7 root buses + per-project + umbrella)
- **Severity:** medium · **Confidence:** confirmed
- **Category:** duplicate implementations
- **Evidence:** runtime canonical `Tiannara.EventBus` + `Tiannara.EventRegistry`
  (`event_bus.ex:1,9`, boot-wired Infrastructure, wiring audit:21); root cluster
  of 7 bus modules (`lib/tiannara/{asc/core,cel/services,cel,executive,runtime,crav}/…event_bus*.ex`);
  `Tiannara.CEL.EventBus` has **zero external references**
  (GENSERVER_RECONCILIATION.md:50); umbrella `observation_bus` app;
  `TiannaraRuntime.Omega.SentinelEventBus`.
- **Affected caps:** event propagation, OLEF, Meta observer stack, ASC/CEL.
- **Minimal remediation:** retire dead `Tiannara.CEL.EventBus`; document one bus
  owner per deployed app with a topic contract; forbid new bus modules without
  a Register 4 row.
- **Acceptance criteria:** dead bus removed; owner map recorded; grep shows no
  new `defmodule *EventBus` outside the owners.

## F-ARC-005 — Knowledge graph implemented four+ times across three languages
- **Severity:** medium · **Confidence:** confirmed (duplication), hypothesis (no single canonical)
- **Category:** duplicate implementations
- **Evidence:** root `Tiannara.Graph.*` (8 files; `Graph.Persistent` zero-evidence,
  reconciliation:61), root `Tiannara.KnowledgeGraph.*`, runtime 4 knowledge_graph
  modules (phase16_1, civilization manager, mathematics, audit), Python
  `tiannara_core/{autonomy,transfer}/knowledge_graph.py`, `memory/knowledge_store.py`,
  `ecm/graph_engine.py`.
- **Affected caps:** knowledge substrate, research pipelines, OMCS, civilization.
- **Minimal remediation:** Register 2 maps each capability to one graph impl;
  retire `Graph.Persistent` (zero-evidence); freeze new graph modules.
- **Acceptance criteria:** capability→graph-impl map published; retirement of
  zero-evidence module executed or justified; no fifth graph namespace added.

## F-ARC-006 — CAE, CAP, and UEP have zero implementation and zero in-repo spec
- **Severity:** high (certification-blocking) · **Confidence:** confirmed
- **Category:** documentation-vs-implementation gap / stale schema
- **Evidence:** R0 greps: no `defmodule`/class contains CAE/CAP/UEP acronyms; no
  md in docs/markdown/certification/audit contains the full names; only
  `certification/atlas/R0_SOURCE_PLAN.txt:179,223-231,253,257` reference them as
  external design inputs. Nearest analogues (OCAL, production_gates campaigns)
  are NOT CAE/CAP and must not be claimed as such.
- **Affected caps:** epistemic arbitration (CAE), promotion governance (CAP),
  payload schema (UEP), certification program.
- **Minimal remediation:** import the external specs into the repo (decision
  register) or formally defer CAE/CAP/UEP in Register 7; until then, no
  certification claim may reference them.
- **Acceptance criteria:** either specs committed + implementation plan in
  Register 2/7, or explicit deferral decision recorded with date and scope.

## F-ARC-007 — `tiannara_audit` verifiers cannot fail (P0 claim-control defect)
- **Severity:** critical · **Confidence:** confirmed
- **Category:** security bypass / missing negative tests / conflicting authority
- **Evidence:** `DIRECTORY_AUDIT:40-59`: `graph_verifier.ex:23-37` computes
  `computed_hash` then never compares it (returns `match: true` unconditionally);
  `proof_verifier.ex:21-22` passes when `expected_fingerprint == nil`. Both
  committed `INDEPENDENT_AUDIT_REPORT.md` copies (lib/ and
  tiannara_runtime/priv/audit/, "220/220 PASS") were produced by these verifiers
  and cannot establish certification. Tool is also uncalled/untested/un-CI'd
  (DIRECTORY_AUDIT:113-128).
- **Affected caps:** independent audit, certification evidence, provenance.
- **Minimal remediation:** make both verifiers fail-closed (mismatch/nil =
  FAIL); add negative tests; supersede (banner, not erase) both historical
  reports; add a CI job or scripted invocation before any citation.
- **Acceptance criteria:** verifier unit tests prove FAIL on mismatch and FAIL
  on nil expected; reports regenerated by fixed tool or marked superseded;
  `tiannara_audit` compiled+tested in CI.

## F-ARC-008 — k8s production overlay: literal credentials, broken base, orphan KEDA targets
- **Severity:** critical · **Confidence:** confirmed
- **Category:** security bypass / hidden dependency / persistence-of-secrets
- **Evidence:** `DIRECTORY_AUDIT:61-71,281-292`: tracked
  `tiannara_runtime/k8s/phase6/overlays/production/kustomization.yaml:36-37`
  contains literal release cookie + NATS token (values redacted here); overlay
  references `../../base` but `phase6/base/` has no `kustomization.yaml`;
  4 KEDA ScaledObjects target deployments (`tiannara-phase13-14`, `tiannara-ucc`,
  `tiarnara-rrm` [typo], `tiannara-tcl`) with no Deployment manifests in `k8s/`.
- **Affected caps:** deployment/ops, NATS auth, k8s scaling.
- **Minimal remediation:** rotate both values (ops action), switch to
  deployment-time secret injection, add base kustomization, locate or
  orphan-declare the 4 KEDA targets.
- **Acceptance criteria:** no literal secrets in tracked files (grep gate in
  CI); `kustomize build` succeeds on the production overlay from a clean
  checkout; every KEDA target resolves to a tracked manifest or is removed.

## F-ARC-009 — API production surface split; auth is opt-in and one admin route is unauthenticated
- **Severity:** critical · **Confidence:** confirmed
- **Category:** security bypass / duplicate implementations
- **Evidence:** `DIRECTORY_AUDIT:73-89` (§1.3): `main.py:97-105` installs 5
  security middlewares; `main_production.py:46` installs only CORS;
  `middleware/production_auth.py:71-72` enforces auth only when
  `ENVIRONMENT=production` (default development = permissive) and payment
  prefix is allowlisted (`:21`); `routes/payment.py:177-195` admin
  process-downgrades route carries `# TODO: Add admin authentication check here`
  (`:191`). Docker launches `main.py` (docker-compose.yml:51) but
  `main_production.py` remains a live footgun.
- **Affected caps:** API security, payments, production auth.
- **Minimal remediation:** delete or fold `main_production.py` into `main.py`;
  implement the admin check; make production enforcement fail-closed
  (default secure); move payment prefix off the allowlist or require auth.
- **Acceptance criteria:** single entrypoint; route test proves unauthenticated
  admin call → 401/403; auth middleware active by default in prod config;
  no second `main_*` app object.

## F-ARC-010 — Orphaned / zero-evidence module population
- **Severity:** medium · **Confidence:** confirmed (existence), hypothesis (individual dead-ness)
- **Category:** unused modules
- **Evidence:** 35 confirmed zero-evidence GenServers
  (`GENSERVER_RECONCILIATION.md:43-81`, incl. `Tiannara.CEL.{EventBus,Metrics,
  MissionDirector,Planner}`, `Tiannara.Certification.Protocol`,
  `Tiannara.Executive.Cognitive.{AttentionScheduler,ContextManager,
  HeartbeatEngine,WorkingMemory}`, `Tiannara.Graph.Persistent`,
  `TiannaraOS.ConstitutionalWatchdog`, 5× `TiannaraOS.Governance.*`,
  `Tiannara.World.{ConflictResolver,WorldConsistencyValidator}`); wiring orphans
  (`Tiannara.Meta.Supervisor` — wiring audit:50; empty
  `TiannaraRuntime.Interface.Supervisor` `children = []`; unwired
  `Tiannara.P9XEcosystem.Supervisor`; 5F.9/5F.10 absent modules — C-06/C-07);
  new R0 finds: `TiannaraRuntime.Shared.ConstitutionalLaws` (zero refs),
  `Tiarnara.Phase18.RRM.*` typo namespace (7 modules).
  Note: the "23 orphaned modules" figure cited in baseline.md:68,81 was not
  locatable as an enumeration in the wiring audit (discrepancy logged in
  deps_code.json).
- **Affected caps:** CEL, OS governance, executive cognition, world model, RRM.
- **Minimal remediation:** per-module disposition pass (owner / add supervisor
  child / retire) after Register 2 mapping; no bulk deletion.
- **Acceptance criteria:** each of the 35 + listed orphans has a recorded
  disposition; retired modules removed from compilation; typo namespace renamed
  or formally quarantined.

## F-ARC-011 — Intra-runtime duplicate module definitions (redefinition warnings)
- **Severity:** medium · **Confidence:** confirmed for 1, hypothesis for 10
- **Category:** duplicate implementations / hidden dependency
- **Evidence:** `tiannara_runtime/out.txt` (+ out_no_mocks/passive/telemetry_publisher)
  show 11 distinct "redefining module" warnings (lines 203,731,745,1154,1161,
  2255,2447,2544,2608,2738,2799). PROVEN duplicate source:
  `TiannaraRuntime.GRCC.EcologySupervisor` at
  `lib/tiannara_runtime/supervisors.ex:1` AND
  `lib/tiannara_runtime/grcc/ecology_supervisor.ex:1`. For the other 10
  (Tiannara.CIS.*, Tiannara.GRCC.*, Tiannara.P9X.*, Tiannara.RRG.EntropyRedistributor)
  single-pass grep found one source each — cause unknown (stale `_build` beam vs
  second source). Fresh-build verification not run in R0.
- **Affected caps:** GRCC, CIS immune, P9X, RRG; runtime build integrity.
- **Minimal remediation:** delete the duplicate EcologySupervisor definition
  (keep per-directory file); run one clean `_build` recompile to classify the
  remaining 10 warnings; fix any second sources found.
- **Acceptance criteria:** clean full recompile of `tiannara_runtime` produces
  zero "redefining module" warnings; CI adds a warning-count gate.

## F-ARC-012 — Python package import cycle (core ↔ pros; test-only core ↔ api)
- **Severity:** low · **Confidence:** confirmed
- **Category:** cycle / hidden dependency
- **Evidence:** `tiannara_core/integration/pros_adapter.py:3-4` imports
  `motor_controller` (tiannara_pros); 10+ `tiannara_pros` files import
  `tiannara_core` (orchestrators/analytics). Reverse leg core→api is test-only
  (`tiannara_core/compliance/test_compliance_integration.py`).
- **Affected caps:** pros integration, core packaging.
- **Minimal remediation:** extract the pros interface behind a thin adapter
  module in tiannara_core with lazy import, or move shared types to a leaf
  package; keep the api leg test-only and documented.
- **Acceptance criteria:** `python -c "import tiannara_pros"` and
  `import tiannara_core` succeed in either order in a fresh venv; cycle test
  documented in CI smoke.

## F-ARC-013 — Hidden cross-project coupling: root probes runtime processes
- **Severity:** medium · **Confidence:** confirmed (references), hypothesis (co-VM intent)
- **Category:** hidden dependency / undocumented interface
- **Evidence:** root files reference runtime process names:
  `lib/tiannara/crav/runtime_atlas.ex:582` and `crav/runtime_census.ex:246`
  (`Process.whereis(TiannaraRuntime.StartupSupervisor)`),
  `phase_omega/runtime_auditor.ex:252`
  (`TiannaraRuntime.Monitoring.TelemetryPublisher`),
  `phase_omega/runtime_discoverer.ex:151` (`Code.ensure_loaded?` guarded).
  All are guarded (no compile dep; root mix.exs has no runtime dep), but they
  imply a co-VM deployment that no launcher/compose/k8s file provides
  (unknown relationship between the two supervision roots).
- **Affected caps:** runtime census/atlas/auditor tooling, deployment model.
- **Minimal remediation:** document the intended deployment topology (one
  decision: separate processes vs future umbrella); make the census tools
  configurable (list of process names) instead of hardcoding cross-app atoms.
- **Acceptance criteria:** topology decision recorded; census/auditor accept a
  configurable probe list; no hardcoded cross-app module names outside it.

## F-ARC-014 — Runtime cannot boot in MIX_ENV=prod (missing config/prod.exs)
- **Severity:** high · **Confidence:** confirmed
- **Category:** incomplete lifecycle handling / persistence gap
- **Evidence:** `DIRECTORY_AUDIT:272-274`: `tiannara_runtime/config/config.exs:57`
  imports `"#{Mix.env()}.exs"` but `config/prod.exs` does not exist →
  prod compile/boot fails. k8s image claims `tiannara-runtime:phase6-6.0.0`
  (dir audit:264) — test-vs-production mismatch (a prod image cannot be built
  from tracked config).
- **Affected caps:** production deployment, CPL/Omega boot, observability.
- **Minimal remediation:** add a fail-closed `config/prod.exs` (env-required
  secrets, real NATS endpoint) before any prod claim.
- **Acceptance criteria:** `MIX_ENV=prod mix compile` succeeds on clean
  checkout; prod boot test (container) reaches StartupSupervisor stage 1 with
  externalized config; no secrets in the new file.

## F-ARC-015 — CI blind spots: large test surfaces never run
- **Severity:** medium · **Confidence:** confirmed
- **Category:** test-vs-production mismatch / incomplete lifecycle
- **Evidence:** `.github/workflows/ci-cd.yml:5,8` triggers only `[main, master]`
  (never `local/pr4`); its pytest step is `pytest tests/` only (`:49`) so ~80
  loose root-level `test_*.py` scripts and all of `tiannara_pros` are
  unexercised; `phase_5f2_tests.yml` only `main|develop` (wiring audit:106-107);
  `tiannara_observatory` own CI file untracked → effectively no CI
  (dir audit:219-220); `tiannara_audit` never compiled by any workflow.
  (The runtime suite itself IS required since `3d3ae924` — do not regress.)
- **Affected caps:** API/core/pros test hygiene, observatory, audit tooling.
- **Minimal remediation:** widen branch triggers or fold Python jobs into the
  branch-spanning workflow; decide root-level scripts: relocate under `tests/`
  or archive; add tiannara_audit build/test job (depends on F-ARC-007 fix).
- **Acceptance criteria:** every push to any `local/pr*` runs the Python suite
  + Elixir suites; zero loose `test_*.py` at repo root; audit job exists.

## F-ARC-016 — Systemic test-vs-production mismatch (fabrication + mock/loaded conflation)
- **Severity:** high · **Confidence:** confirmed
- **Category:** test-vs-production mismatch / undocumented interface
- **Evidence:** (a) OPC execution fabricated outputs — quarantined fail-closed
  (`7855aa6d`, C-04; `opc/runtime/gpu_execution_bridge.ex:326-338` historic);
  (b) CIS ExecutionController **delivery path is log-only** (wiring audit:49,
  C-10 note — safety chain wired but effects not delivered); (c) API→observatory
  edge has **simulation fallback** that fabricates data on outage
  (`tiannara_api/routes/observatory.py:38,:602,:622`); (d) the no_mocks lesson:
  `:code.all_loaded()` "loaded" ≠ "active" mock observatories
  (`TIANNARA_RUNTIME_TEST_INVENTORY.md:147`, fixed `d4747586`); (e) 6 quarantined
  runtime tests with re-admission conditions (test inventory §4).
- **Affected caps:** OPC execution, CIS safety delivery, observability path,
  test gate integrity.
- **Minimal remediation:** (a) keep OPC quarantine until real substrate exists;
  (b) implement real CIS delivery or explicitly certify the log-only path as
  the contract; (c) remove the simulation fallback (fail loudly); (d) apply the
  loaded-vs-active pattern to any new activity assertions.
- **Acceptance criteria:** no silent-simulation paths remain on production
  edges (grep for fallback keywords + route test); CIS delivery contract
  documented and tested; quarantine list stays visible with dates.

## F-ARC-017 — Historical completion docs overclaim (stale schema of record)
- **Severity:** medium · **Confidence:** confirmed
- **Category:** stale schema / documentation-vs-implementation
- **Evidence:** `PHASE_5F_STATUS_CORRECTION.md` C-01..C-14 — 5F completion docs
  claim auto-start/production-ready/integrated where code proves otherwise
  (e.g. `PHASE_5F4_COMPLETION_STATUS.md:96-109` vs `git log -S ChronogramMatrix`;
  `uvicorn tiannara_core.main:app` false, dir audit:136-137; achievement-MD
  "100% COMPLETE" markers in `tiannara_core/tests/`). Banners exist on flagged
  docs; the pattern of overclaiming remains the repo's dominant failure mode.
- **Affected caps:** certification program, all phase claims.
- **Minimal remediation:** certification claim template requires Register 6
  evidence binding (R0_SOURCE_PLAN:641-653); treat achievement-MDs as
  non-evidence in scanners.
- **Acceptance criteria:** no new completion doc merges without evidence binds;
  scanner flags achievement-style claims.

## F-ARC-018 — Persistence/state hygiene: tracked runtime DB churn, CWD-relative stores, no store map
- **Severity:** medium · **Confidence:** confirmed
- **Category:** persistence gap / lifecycle
- **Evidence:** baseline.md dirty-tree table: 31 modified tracked files mostly
  root `*.dets` churn (`cel_memory_v2.dets` currently modified) + 470 deleted
  `.dets.corrupted.*` archives; Python stores write SQLite/JSONL
  **relative to CWD** with no configuration boundary
  (`tiannara_core/memory/discovery_memory.py:16`, telemetry/cognitive_telemetry.py:133,
  interpretability/audit_trail.py:161; dir audit:145-147); five storage
  technologies coexist (DETS/JSON-journal/Mnesia/ETS/SQL/Postgres) with no
  ownership map (ownership_duplicates.csv row "memory/persistence (CPL)").
- **Affected caps:** CPL, executive memory, council audit log, Python memory,
  observatory state.
- **Minimal remediation:** gitignore/stop tracking runtime DB files (or pin
  fixture copies under test_data/); make Python state paths env-configurable;
  publish the store-ownership map (Register 4) in the architecture doc.
- **Acceptance criteria:** clean checkout has zero modified `*.dets` after the
  test suite; Python stores honor a `TIANNARA_DATA_DIR`-style env var; store map
  merged.

## F-ARC-019 — Observatory umbrella security posture (dev bypass, committed dev secrets, CORS *)
- **Severity:** high · **Confidence:** confirmed
- **Category:** security bypass (paths only; values redacted)
- **Evidence:** `DIRECTORY_AUDIT:210-215`: dev auth bypass grants administrator
  (`apps/observatory_api/lib/observatory_api/plugs/auth.ex:13-21`); committed
  dev secrets (`config/config.exs:14,48` secret_key_base/jwt_secret;
  `:22-23` postgres creds ×6 DBs — values redacted); CORS `*`
  (`config.exs:9`, endpoint.ex:36); umbrella has effectively no CI.
- **Affected caps:** observatory API, RBAC, data stores.
- **Minimal remediation:** gate the bypass behind explicit dev-only runtime
  check that fails in prod; rotate/remove committed dev secrets; restrict CORS;
  track the umbrella test suite or delete the dir.
- **Acceptance criteria:** prod env rejects bypass (test); no secrets in
  tracked config (grep gate); CORS restricted; umbrella tests tracked + one CI
  job.

## F-ARC-020 — Protocol/serialization authority vacuum (Babel unwired/unkeyed; dual NATS clients; no payload schema)
- **Severity:** medium · **Confidence:** confirmed
- **Category:** conflicting authority / hidden dependency
- **Evidence:** Babel `encrypt_causal_payload/4` zero production callers,
  "topological key" = unkeyed SHA-256 (C-08, wiring audit:48,
  `meta/singularity_dissolution/babel_protocol.ex`); UEP absent (F-ARC-006);
  runtime has both gnat (`mix.exs:32-49`) and a **hand-rolled raw TCP NATS
  listener** (`nats/connection.ex:15-24`, port 4222, dir audit:260-261);
  `forward_provenance` is the only shared contract library across the two
  Elixir projects (root mix.exs:67, runtime mix.exs:32).
- **Affected caps:** messaging, crypto payloads, provenance envelopes.
- **Minimal remediation:** pick one NATS client abstraction (document the raw
  listener's raison d'être or retire it); require real key material + a caller
  before any Babel integration claim; host future UEP in forward_provenance.
- **Acceptance criteria:** single documented NATS access path per app; Babel
  either wired with keys + caller test or moved to archive; UEP decision (import
  or defer) recorded per F-ARC-006.

## F-ARC-021 — Namespace hygiene: 4× "RRG", 3× supervisors.ex, typo root namespace
- **Severity:** medium · **Confidence:** confirmed
- **Category:** conflicting authority / undocumented interface
- **Evidence:** RRG = Rate-limiting Ontological Graph (booted, rrg/rrg.ex:1-3)
  + Runtime Revelation Governor (`rrg/governor.ex:1`, unsupervised, note third
  namespace `Tiannara.Runtime.RRG.*`) + root `Tiannara.Topology.RRG`
  (`lib/tiannara/topology/rrg.ex:1`) + retired doc name (C-09/C-13 + R0);
  three `supervisors.ex` inside tiannara_runtime/lib
  (`lib/tiannara/`, `lib/tiannara_runtime/`, `lib/tiannara_runtime/runtime_layers/`);
  `Tiarnara.Phase18.RRM.*` typo namespace (7 modules) mirrored by k8s
  `tiarnara-rrm` target; `Tiannara.MultiWorld.KillSwitchCausal` root-namespace
  module in runtime tree.
- **Affected caps:** RRG consumers (ccr, civilization, omce, audit), RRM phase18,
  supervision clarity.
- **Minimal remediation:** documentation must use canonical C-13 names
  (already decided); schedule an approved rename for `Tiarnara.*` and the third
  RRG namespace; consolidate the three supervisors.ex files by role.
- **Acceptance criteria:** rename plan approved + executed (or explicitly
  deferred in Register 7 with date); docs grep shows canonical names; one file
  per layer-role named consistently.

## F-ARC-022 — Competing registries (principles ×2, capabilities ×3, domain orphan)
- **Severity:** medium · **Confidence:** confirmed
- **Category:** conflicting authority
- **Evidence:** two principle registries with disjoint consumers
  (`council/principle_registry.ex` vs `os/principle_registry.ex`; consumers
  grep; both flagged dynamic-resolution manual review, reconciliation:41);
  three capability registries (CEL Services — reconciliation:41;
  `os/capability_registry.ex` historically mutated by
  `scratch/rewrite_registry.py:250`; `asc/ecology/capability_registry.ex`);
  domain registry canonical decision exists (AC-001, keep_canonical) but orphan
  `lib/tiannara/domains/computer_science.ex` self-registers `:cs` in no registry
  (TIANNARA_DOMAIN_EXECUTION_AUDIT.md:22).
- **Affected caps:** governance, CEL dispatch, ASC ecology, discovery domains.
- **Minimal remediation:** one registry per concept per app (decide in R1 with
  Register 2 data); fold or retire the others; delete/merge the orphan domain.
- **Acceptance criteria:** single consulted registry per concept in consumer
  greps; orphan domain resolved per AC-001; dynamic-resolution rows from
  reconciliation re-verified.

## F-ARC-023 — Missing negative tests on the audit/proservation critical paths
- **Severity:** medium · **Confidence:** confirmed
- **Category:** missing negative tests
- **Evidence:** `tiannara_audit` has **no test/ directory at all** (dir
  audit:115-116) — the false-positive verifiers (F-ARC-007) went undetected
  precisely because no test ever asserts a FAIL; `tiannara_pros` has **zero
  tests anywhere** despite actuator/safety IO and a "stable baseline" freeze
  claim (`docs/FREEZE_v1.md:1`, dir audit:233-235); runtime quarantine holds
  6 tests with 3 failing locally (test inventory §4) — re-admission evidence
  outstanding.
- **Affected caps:** audit tooling, prosthetic hardware safety, runtime gate.
- **Minimal remediation:** add fail-path tests for both audit verifiers (part
  of F-ARC-007 remediation); add pros actuator/safety-path tests before any
  hardware claim; track quarantine re-admission per recorded conditions.
- **Acceptance criteria:** verifier FAIL-path tests green; ≥1 pros safety test
  suite runs in CI; quarantine table updated with dates/outcomes.

## F-ARC-024 — Frontend ownership void (three UIs invisible to git)
- **Severity:** medium · **Confidence:** confirmed
- **Category:** duplicate implementations / governance gap
- **Evidence:** `tiannara_gui` (54 files on disk, `git ls-files` = 0,
  `.gitignore:25`, removed in `3f8aacda`, working tree drifted — dir audit §5);
  `tiannara_internal_dashboard` (95 files, never committed, demo auth ignores
  credentials — dir audit §6, path only); `tiannara_mobile` (6 auto-generated
  stubs, never committed — dir audit §7). Meanwhile `tiannara_saas` (tracked,
  90 files) and `apps/observatory_ui` (untracked-by-umbrella) are live UIs.
  **Five** UI surfaces, three invisible.
- **Affected caps:** operator interfaces, SaaS, observability UI.
- **Minimal remediation:** per-dir decision: restore-to-repo, explicit
  separate-repo pointer (with commit hash), or delete; never count absent-in-git
  dirs in completeness claims.
- **Acceptance criteria:** each UI has a recorded ownership decision; scanners
  exclude or flag absent-in-git dirs consistently; dashboard never exposed
  (demo auth).

## F-ARC-025 — Rust NIF substrate unlinkable (phantom `:tiannara_phase14` app)
- **Severity:** low · **Confidence:** confirmed
- **Category:** hidden dependency / incomplete lifecycle
- **Evidence:** six `native_bridge.ex` modules load NIFs via
  `:erlang.load_nif(Application.app_dir(:tiannara_phase14, "priv/native/…"))`
  (`tiannara_runtime/lib/tiannara/phase14/reg/native_bridge.ex:23` et al.);
  `:tiannara_phase14` is not a project in this checkout; `{:rustler, "~> 0.36.0"}`
  declared (`mix.exs:67`) with no `use Rustler`/`crate:` config; `rust_core/`
  crate is untracked and referenced by nothing.
- **Affected caps:** phase10-17 native bridges (MEN/CRCA/REG/SMCP/REA/UCC).
- **Minimal remediation:** decide: wire rust_core properly (rustler crate config
  + priv/native build) or archive the native bridges as aspirational stubs.
- **Acceptance criteria:** either a NIF loads in a CI smoke test, or the bridges
  are documented stubs with fail-closed behavior (no phantom app_dir).

---

## Summary

| ID | Severity | Confidence | Concept cluster |
|---|---|---|---|
| F-ARC-001 | critical | confirmed | dual Elixir projects / 28 duplicate modules |
| F-ARC-007 | critical | confirmed | audit verifiers cannot fail |
| F-ARC-008 | critical | confirmed | k8s secrets + broken overlay |
| F-ARC-009 | critical | confirmed | API entrypoint/auth split |
| F-ARC-002 | high | confirmed | KillSwitch ×3 + dead API |
| F-ARC-003 | high | confirmed | constitutional authority scatter |
| F-ARC-006 | high | confirmed | CAE/CAP/UEP absent |
| F-ARC-014 | high | confirmed | missing config/prod.exs |
| F-ARC-016 | high | confirmed | fabrication/mock-vs-production cluster |
| F-ARC-019 | high | confirmed | observatory security posture |
| F-ARC-004/005/010/011/013/015/017/018/020/012/021/022/023/024/025 | medium/low | confirmed (mostly) | duplication, orphans, cycles, CI, namespaces, registries, frontends, NIFs |

**Negative-test posture of R0 itself:** findings above rest on static evidence
and prior audits; no compile, boot, or test was run during R0 (read-only
mandate). Items marked hypothesis (individual dead-ness of the 35 zero-evidence
modules; 10/11 redefinition-warning causes; co-deployment topology) require the
verification steps named in their remediation lines.
