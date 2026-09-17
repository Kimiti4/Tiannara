# AE-004 Evidence Report — Observability Contract Fidelity (F12 → F9)

Date: 2026-08-20T23:02:36.631292+00:00

## 1. Authorization

- Mission: `ASC-AE-004` — Determine whether the system's health-observation layer faithfully represents  actual subsystem health, and whether correcting the DETS contract (F12)  eliminates the false EOS emergency (F9) without degrading fault sensitivity.

- Status: `AUTHORIZED`; operator `schtickman`; signature `f9/f12`; valid until `8-27-2026T2322`
- Rule honored: `This authorization permits ISOLATED EXPERIMENTATION only.  If a candidate passes Phase C, it must generate an EVIDENCE REPORT. Merging to production requires a SEPARATE C14 authorization artifact  (ASC-AE-004-ADOPTION.human.yaml).
`

## 2. Modes Executed (fresh BEAM per mode; patches in-memory only, never written to disk)

| mode | patches | topology |
|---|---|---|
| `characterize` | none (baseline) | full app boot |
| `candidate_f12` | F12 contract: EventStore.healthy?/0, ExecutiveMemory.health/0 | isolated [Council.Supervisor, ServiceRegistry, Kernel] |
| `candidate_f12_eos` | F12 family + EOS: kernel check_health normalization, start_service already_started, registry EventStore → healthy?/0, EventBus.health/0 | isolated; healthy / storage-fault / recovery cycles |
| `candidate_eos_full` | full patch set | full app boot |

## 3. Phase A — Characterization (baseline)

- F9 reproduced: `boot_report_status = failed`, `runtime_state = emergency`
- `failed_critical = ['unified_world_model', 'event_store', 'executive_memory']` — all three reported-failed services were **live** (`whereis_alive = true` for each); `gate_results` for each failed service = `{}` → the failing gate was the **start gate** (`DynamicSupervisor.start_child` → `already_started` collision with services pre-started by other app children).
- F12 raw shapes: open table `:dets.info/1` returns bare list `[['type', 'set'], ['keypos', 1], ['size', 22], ['file_size', 29378], ['filename', [46, 47, 116, 101, 115, 116, 95, 100, 97, 116, 97, 47, 100, 101, 116, 115, 47, 49, 57, 50, 50, 47, 100, 101, 116, 115, 47, 116, 101, 115, 116, 47, 99, 101, 108, 95, 101, 118, 101, 110, 116, 95, 115, 116, 111, 114, 101, 46, 100, 101, 116, 115]]]` (NOT `{:ok, _}`); closed/unknown table returns `undefined`.
- Endpoints on healthy topology: `EventStore.healthy?/0 = False`, `ExecutiveMemory.health/0 = unhealthy`, `EventStore.health/0 = healthy` (Base default — unconditional).

## 4. Phase B — Candidates

### candidate_f12 (F12 contract only)

- Specificity fixed at endpoint level: `EventStore.healthy?/0 = True`, `ExecutiveMemory.health/0 = healthy`.
- Classifier simulation after killing ExecutiveMemory: endpoint `:unhealthy`; **legacy classifier → `healthy` (fault silenced — atoms are truthy)**, normalized classifier → `unhealthy`.

### candidate_f12_eos (F12 family + EOS adjustments; isolated topology)

- **Specificity** (healthy): `EventStore.healthy?/0 = True`, `ExecutiveMemory.health/0 = healthy`, `failed_critical = []`, status `degraded` (degraded-only residual = isolated-topology artifacts: constitutional_score_pipeline / decision_predictor).
- **Sensitivity** (storage fault: dets path blocked → `eisdir`): stats `{'degradation_reason': ['file_error', [46, 47, 116, 101, 115, 116, 95, 100, 97, 116, 97, 47, 100, 101, 116, 115, 47, 49, 57, 50, 50, 47, 100, 101, 116, 115, 47, 116, 101, 115, 116, 47, 99, 101, 108, 95, 101, 118, 101, 110, 116, 95, 115, 116, 111, 114, 101, 46, 100, 101, 116, 115], 'eisdir'], 'degraded': True, 'event_count': 0, 'latest_offset': 0}`; `healthy?/0 = False`; `failed_critical = ['knowledge_coordinator', 'conflict_detector', 'conflict_resolution_engine', 'event_store']`; status `failed` / `emergency` — **alarm preserved**.
- **Recovery** (fault removed; fresh store): `EventStore.healthy?/0 = True`, `failed_critical = []`, status `degraded` — **not stuck in emergency**.

### candidate_eos_full (full patch set; full app boot)

- All 30 services `:ok` except `discovery_supervisor` `:degraded` (medium; nested `already_started` collision — DiscoveryEngine pre-started by an app child — F9-family remnant, honestly classified).
- `failed_critical = []` (baseline: 3), status `degraded` (baseline: `failed`), `runtime_state = recovery` (baseline: `emergency`) — **false emergency eliminated**.
- Endpoints: `EventStore.healthy?/0 = True`, `EventStore.health/0 = healthy`, `ExecutiveMemory.health/0 = healthy`, `EventBus.health/0 = healthy`.

## 5. Phase C — Gate Verdicts

### T1 Specificity (healthy topology): **PASS**

- ✓ True
- ✓ True
- ✓ True
- ✓ True
- ✓ True
- ✓ True
- ✓ True
- ✓ True

### T2 Sensitivity (injected storage fault): **PASS**

- ✓ True
- ✓ True
- ✓ True
- ✓ True
- ✓ True
- ✓ True
- ✓ True
- ✓ True

### T3 Recovery Honesty: **PASS**

- ✓ True
- ✓ True
- ✓ True
- ✓ True

### Causal Discrimination (F12 -> F9): **PASS**

- ✓ F9 reproduced with start gate collision
- ✓ F9 failed services were live
- ✓ F12 is systemic family
- ✓ F12 contract only is insufficient at EOS level
- ✓ F12 plus EOS adjustment resolves false emergency
- ✓ full boot status is honest after fix

**Verdict:** candidate_f12_plus_eos_adjustment PASSES Phase C gates

## 6. Causal Discrimination Conclusion

- **F9 root cause** is a start-gate name collision (`already_started`), not the health layer: services pre-started by other app children are re-started by `Kernel.boot()` and marked failed despite being live.
- **F12 is a systemic family** (stale `match?({:ok, _}, :dets.info/1)`): EventStore.healthy?/0, ExecutiveMemory.health/0, EventBus.health/0.
- **The EOS truthiness bug masked F12-family defects**: legacy `if apply(...)` treats `:unhealthy` as truthy, so health gates could never fail. Fixing the classifier exposed EventBus.health/0's F12-family defect — the F12 family and the EOS normalization must ship together.
- **F12 contract-only is insufficient**: endpoints fixed, but the EOS classifier still silenced faults (`candidate_f12` evidence). **F12 + EOS adjustments pass all Phase C gates** without silencing the storage alarm (`candidate_f12_eos` sensitivity) and without a stuck emergency (`candidate_f12_eos` recovery).

## 7. Residual Findings

| id | severity | finding |
|---|---|---|
| F12-family | HIGH | stale `{:ok, _}` :dets.info match in EventStore.healthy?/0, ExecutiveMemory.health/0, EventBus.health/0 |
| F9 | HIGH | boot start-gate `already_started` collision → false emergency; resolved by candidate patch set |
| F13 (candidate) | LOW | DiscoverySupervisor nested `already_started` collision (DiscoveryEngine pre-started) → :degraded, honestly classified |
| F13 (candidate) | LOW | EventStore.health/0 is the unconditional Base default `:healthy` — recommends delegating to healthy?/0 |
| F13 (candidate) | LOW | EventBus DLQ dets at relative CWD path `./cel_event_bus_dlq.dets`; dlq_size/retry_dlq use F8-family `{:continue, _}` traverse |

## 8. Adoption Status

- **NOT EXECUTED (requires separate C14 authorization: ASC-AE-004-ADOPTION.human.yaml)**
- No production source file was modified by this mission (patches applied in-memory only).
- Next gate: human review of this report, then `ASC-AE-004-ADOPTION.human.yaml` if adoption is approved.