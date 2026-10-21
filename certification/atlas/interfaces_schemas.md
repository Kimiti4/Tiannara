# Interface & Schema Compatibility Report (R0 deliverable #4 — Section F)

Date: 2026-10-20 · Branch `local/pr4` @ `521cb7fe` · Read-only discovery.
Scope: every interface artifact located in this checkout (contracts, schemas, wire formats), with version, location, producers, consumers, compatibility risks, and UNKNOWNs.
Redaction policy: secrets are referenced by path only; no key/credential material is reproduced.

---

## 0. Executive reconciliation

| # | Artifact class | Expected by plan (`R0_SOURCE_PLAN.txt:186-187`) | Found in repo | Reconciliation |
|---|---|---|---|---|
| 1 | ISD v2.0 | yes | **0 files** (only mention = the plan itself) | **UNKNOWN / missing** |
| 2 | IF-001..IF-004 contracts | yes | **0 files** (only mention = the plan itself) | **UNKNOWN / missing** |
| 3 | Protobuf schemas (`lib/tiannara/telemetry/*.proto`) | yes | **2 files** + 2 generated Elixir modules | PARTIAL (exists; unversioned, narrow) |
| 4 | Event registry / event schemas | yes | no central registry; 3 ad hoc taxonomies | PARTIAL |
| 5 | UEP (universal event protocol) schema | "if present" | **not found** (grep `UEP|Universal Event Protocol` = 0) | missing |
| 6 | OpenAPI/Swagger | implied by API layer | runtime-generated only; no checked-in spec | PARTIAL |
| 7 | WebSocket contracts | implied | 4 implemented endpoints (code-level only) | PARTIAL |
| 8 | Observability/data contracts | implied | 4 tracked observatory contract docs + CanonicalWorldState schema | PARTIAL |

Plan-named contracts missing → finding **F-PLT-001**. Interface-level conclusions therefore rest on *implemented* boundaries, not on a spec-vs-implementation match.

---

## 1. ISD v2.0 — `missing_or_unresolved`

- **Version:** unknown (never materialized).
- **Location:** none. Search performed: case-aware grep for `ISD[- _]?v?2\.0?`, `Interface System Design` across `*.md,*.txt,*.ex,*.exs,*.py,*.proto,*.json,*.yml,*.yaml` → sole hit `certification/atlas/R0_SOURCE_PLAN.txt:186`.
- **Producers / consumers:** UNKNOWN (artifact absent).
- **Compatibility risk:** any statement of the form "system complies with ISD v2.0" is unverifiable here; stale/never-landed specification.
- **UNKNOWN:** whether ISD v2.0 exists in the separate ESAP repository or another remote (ESAP not examined in Section F).

## 2. IF-001 .. IF-004 interface contracts — `missing_or_unresolved`

- **Version:** unknown.
- **Location:** none; grep `IF-00[1-4]` across md/txt/ex/exs/py/proto/json → sole hit `R0_SOURCE_PLAN.txt:186`.
- **Producers / consumers:** UNKNOWN.
- **Compatibility risk:** the numbering implies a contract set that downstream phases may cite; today the only candidates to *become* IF-00n are the implemented boundaries listed in §3–§8 below.
- **Remediation hook:** F-PLT-001 acceptance criteria (locate/import or re-derive + pin).

## 3. Protobuf schemas — `implemented_incompletely_verified`

| Field | Value |
|---|---|
| Version | proto3 syntax; **no message versioning field, no compat policy** |
| Location | `lib/tiannara/telemetry/world_state.proto` (17 lines, `package tiannara.telemetry`); `lib/tiannara/telemetry/report_slice.proto` (19 lines, `package tiannara.report`) |
| Generated code | `lib/tiannara/protobuf/world_state.pb.ex`, `lib/tiannara/protobuf/report_slice.pb.ex` (committed; regeneration pipeline NOT found — UNKNOWN whether protoc runs anywhere) |
| Producers | `lib/tiannara/web/telemetry_channel.ex:43-45` (encodes `WorldState`), `lib/tiannara/web/report_channel.ex:25` (pushes `ReportSlice` binary frame) |
| Consumers | Phoenix channel subscribers in the root Elixir app; presumed GUI/observatory renderers — **but `tiannara_gui` is gitignored** (F-PLT-003), so the consumer side cannot be pinned from this checkout |
| Compatibility risks | **Unkeyed** (no version on the wire beyond field numbers); **duplicated schema claim**: `tiannara_gui/src/5f/causal_manifold.ts:5` declares "Single shared schema between Elixir, TypeScript, WebGL, and NATS" — a *different*, untracked schema authority; proto coverage does not extend to any event-bus payload (bus traffic is JSON) |
| Tests | none found for encode/decode round-trip |
| UNKNOWN | channel runtime wiring/testing status; whether other language clients exist |

## 4. OpenAPI / Swagger — `implemented_incompletely_verified`

- **Version:** implicit — `FastAPI(title="Tiannara API", version="1.3.0-phase5")` (`tiannara_api/main.py:84,92`) generates `/docs` + `/openapi.json` at runtime; `rate_limiter.py:144` confirms those paths are served.
- **Checked-in spec:** none. `tiannara_api/schemas/` contains only `moderation_schemas.py`. The only `openapi.json` files in-repo are generated fixtures under `data/asc_projects/phase3_5_test_*/` (test data, not authority).
- **Producers/consumers:** producers = FastAPI route decorators (~45 routers, `main.py:212-255`); consumers = `tiannara_saas` (`next.config.ts:5-17` rewrites `/api/v1/*` → upstream `:8004`), `tiannara_internal_dashboard` (untracked rewrite to `:8004` while its `.env.local.example` says `:8000` — port conflict, `DIRECTORY_AUDIT:171-173`), `tiannara_gui` (vite proxy `:8004`, untracked).
- **Compatibility risks:** **duplicated/divergent specs** — three FastAPI apps (`main.py` v1.3.0, `main_production.py` v1.4.0 with 9 routers, `gateway/main.py` third app) each generate a *different* OpenAPI surface with no recorded precedence (F-PLT-002); no consumer-driven contract test; spec version changes unrecorded.
- **UNKNOWN:** whether any client pins the generated schema (no swagger export step in CI).

## 5. Event registry & event schemas — `partially_connected` (no single registry)

Transport-level schema artifacts found:

| Schema/registry | Version | Location | Producers | Consumers | Risks |
|---|---|---|---|---|---|
| `CivilizationalEvent` normalized event (CEL bus) | bus v2.0.0 (`event_bus.ex:38`) | `lib/tiannara/cel/services/event_bus.ex:14-108` + `cel/services/event_store.ex` | `EventBus.publish/3` call sites across `lib/tiannara/world/*` (40+), `world_mutation_engine.ex:197,460`, `knowledge_coordinator.ex`, etc. | subscribers registered per topic (`:111-119`); DLQ `cel_event_bus_dlq.dets` opened **CWD-relative** (`:70`) | payload shape per-topic unenforced; replay offsets vs subscriber loss ordering UNKNOWN; CWD-relative state |
| Runtime Registry bus (`{event_name, payload}` tuples) | unversioned | `tiannara_runtime/lib/tiannara/event_bus.ex:1-41`; registry `Tiannara.EventRegistry` booted in Infrastructure layer (`PHASE_5F_WIRING_AUDIT.md:21`) | `broadcast/3` from OLEF/MSCL/CIS/GRCC stacks | e.g. PressureSolver round-trip test `boot_wiring_w3_test.exs:33-34` | untyped tuple payloads; telemetry event names built by `String.to_atom` (`:26-29` — dynamic atom creation from topic strings) |
| NATS world-event serializer | Phase 5A Layer 2, unversioned | `tiannara_runtime/lib/tiannara_runtime/nats/world_event_serializer.ex:1-40` — fixed type list (`world_state_update`, `cal_decision`, `cis_intervention`, `memory_snapshot`, `world_fork`, `fitness_update`) | runtime NATS publishers (`nats/publisher.ex`, phase8-19 `Gnat.pub` sites) | `nats/subscriber.ex`, gnat subscribers (`event_gateway.ex:188`, `causal_data_layer.ex:296`, …) | **partial coverage** — many `Gnat.pub` subjects exist outside this list; JSON-only; subject taxonomy (`tiannara.*`, `tiarnara.*` typo namespace!) not centrally registered |
| Observatory event taxonomy | docs-level | `tiannara_observatory/docs/08_EVENT_TAXONOMY.md` (+ `06_DATA_CONTRACT.md`, `09_METRIC_REGISTRY.md`, `11_API_CONSTITUTION.md`, all tracked) | observatory umbrella | observatory apps (`event_store`, `observation_bus`, …) | covers only the umbrella; not referenced by root/runtime buses — **duplicated taxonomy authority** |
| Python event registry | ad hoc | `tiannara_core/causal/global_consistency_kernel.py:317-368` (`self.event_registry` — causal event index, not a transport registry) | GCK internals | GCK internals | name collision with "event registry" concept; unrelated to bus registration |

- **UEP schema:** not present (grep `UEP|Universal Event Protocol` = 0 hits) → missing.
- **Unified registry:** none. → finding **F-PLT-007**.
- **UNKNOWN:** delivery/ordering/retry semantics contract for any bus (see §9); whether `tiarnara.*` subject namespace (misspelled, `rule_evolution.ex:31`, `fallback_router.ex:19`) is intentional protocol or drift.

## 6. WebSocket contracts — `implemented_incompletely_verified`

| Endpoint | File:line | Payload | Auth | Consumers | Risks |
|---|---|---|---|---|---|
| `/ws/metrics` | `tiannara_api/routes/websocket_metrics.py:28-91` | JSON metrics snapshots + ping/pong | `require_websocket_auth` (`security/websocket_auth.py:44-48`, closes 1008) | dashboard/GUI (untracked frontends) | no schema/version on messages; consumers unverifiable |
| `/workflow/{execution_id}` | `routes/websocket_streaming.py:64-122` | JSON execution progress events; example URL documented in docstring (`:77`) | same | `routes/workflow_executor.py:230-449` emits start/complete/fail/node events | event vocabulary defined only in code; drift risk vs any client |
| `/ws/presence` | `routes/collaboration.py:165-202` | JSON presence + ping/pong | same | UNKNOWN | none found |
| `/stream` (meta ecology) | `routes/meta_ecology.py:24-38` | pushes module-global `ELIXIR_TELEMETRY_STATE` | **none found** (no `require_websocket_auth` in file) | UNKNOWN | unauthenticated data feed; static snapshot semantics UNKNOWN |

- Legacy/parallel channels: root Elixir Phoenix channels (`telemetry_channel.ex`, `report_channel.ex`) — separate protocol from FastAPI websockets; **duplicated real-time channel layers** (Elixir channels vs API websockets).
- **UNKNOWN:** client implementations of any of the four; no contract tests located.

## 7. Canonical data schemas (cross-language contracts) — `implemented_incompletely_verified`

- **`CanonicalWorldState` entity schema** — required fields `id, confidence, uncertainty, provenance, owner_subsystem, version, created_at, updated_at, status`; enforced by `validate_entity/1` (`docs/probes/U4_findings.md:35` records it as a real interface contract). Probes exercise it (`priv/tiannara/probes/u4_chain.exs:77-84`); property tests exist and run in root CI (`test/tiannara/world/property/canonical_schema_properties_test.exs:9-55`). This is the **strongest implemented, versioned (`version` field), test-backed contract** in the checkout.
- **tiannara_gui shared schema claim** — `src/5f/causal_manifold.ts:5` ("Elixir, TypeScript, WebGL, NATS"): untracked, no matching Elixir struct name found → compatibility UNKNOWN (F-PLT-003).
- **Observatory docs contracts** — `docs/06_DATA_CONTRACT.md`, `09_METRIC_REGISTRY.md`, `11_API_CONSTITUTION.md` (tracked, umbrella-scoped). Consumers: observatory apps only. Risk: no evidence they are enforced by code/tests in CI (umbrella Elixir tests remain untracked, 0 tracked files under `tiannara_observatory/test/`).
- **UEP:** absent (see §5).

## 8. gnat/NATS subject conventions (de facto interface) — `partially_connected`

- Producers/consumers: subjects of the form `tiannara.<phase>.<domain>.<action>` published from ~15 `Gnat.pub` sites (e.g. `phase14/formal/byzantine_consensus.ex:38,62`, `kernel/deployment_orchestrator.ex:37`, `speciation/telemetry_buffer.ex:161`); requests via `Gnat.request` (`ucc/trajectory_tensor.ex:108`, subject `tiannara.ucc.trajectory_tensor.request`, 120 s timeout).
- Misspelled parallel namespace `tiarnara.*` under `lib/tiarnara/phase18/rrm/*` (`rule_evolution.ex:31`, `fallback_router.ex:19`) → **duplication/typo namespace risk**; k8s KEDA target `tiarnara-rrm` shares the misspelling (`DIRECTORY_AUDIT:288`).
- Auth: NATS token appears literally in the k8s production overlay (path only: `tiannara_runtime/k8s/phase6/overlays/production/kustomization.yaml:36-37`, F-PLT-005).
- JetStream: `nats/jet_stream_helper.ex:20-39` degrades to a warning when `Gnat.JetStream` is unavailable (fail-soft, not fail-closed).
- **UNKNOWN:** subject-level ordering/durability guarantees; whether a NATS server vs the emulated TCP listener (`nats/connection.ex:14-30`, F-PLT-006) serves each subject in any real environment.

## 9. Cross-cutting compatibility risk register

| Risk | Instances | Finding |
|---|---|---|
| **Stale / never-landed spec** | ISD v2.0, IF-001..IF-004; docs claiming `uvicorn tiannara_core.main:app` (`DIRECTORY_AUDIT:136-137`); baseline branch-filter claim (`baseline.md:48` vs `ci-cd.yml:5,8`) | F-PLT-001, F-PLT-004 |
| **Unkeyed schemas** | both protos (no version field); NATS JSON subjects; WebSocket message payloads; CEL per-topic payloads | F-PLT-013, F-PLT-007 |
| **Duplicated authorities** | 3 FastAPI apps → 3 OpenAPI surfaces; 2 real-time channel layers (Elixir vs FastAPI WS); ≥3 event taxonomies (CEL topics, runtime serializer list, observatory docs); 2 "shared schema" claims (proto vs causal_manifold.ts) | F-PLT-002, F-PLT-007 |
| **Unverifiable consumers** | GUI/dashboard/mobile frontends untracked; desktop renderer not analyzed | F-PLT-003, F-PLT-014 |
| **Typo/namespace drift** | `tiarnara.*` subjects + `tiarnara-rrm` k8s target vs `tiannara.*` | (recorded; rename needs approval) |
| **Fail-soft compatibility paths** | observatory simulation fallback in API (`observatory.py:602,622`); JetStream helper skip | F-PLT-015, §8 |

## 10. UNKNOWNs (explicit)

1. ISD v2.0 and IF-001..004 location anywhere (incl. ESAP repo — not scanned in this report).
2. Proto regeneration pipeline (protoc/protobuf-elixir task) — none found; regenerability UNKNOWN.
3. Client-side pinning of OpenAPI or WebSocket message schemas by any frontend (consumers untracked).
4. Delivery/ordering/retry contract of every event transport (definition absent; only code paths observed).
5. Whether any real deployment serves the emulated TCP "NATS" listener or a genuine nats-server (both artifacts exist: `nats/connection.ex`, root `nats-server.log`).
6. Whether observatory contract docs (06/08/09/11) are enforced by any executed test (umbrella Elixir tests untracked; UI has vitest config but no CI).
7. Semantics/auth of `/stream` meta-ecology websocket (`meta_ecology.py:24-38` — no auth found in file; deeper route-registration auth UNKNOWN).
