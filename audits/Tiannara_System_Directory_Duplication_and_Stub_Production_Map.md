# Tiannara System Directory, Stub and Production-Implementation Map

**Document ID:** TMSOS-MAP-001  
**Version:** 1.0  
**Status:** ACTIVE / INCOMPLETE — source inventory, not production certification  
**Repository:** `Kimiti4/Tiannara`  
**Audited branch:** `main`  
**Source commit:** `b829254d032f9e0b5cf4c44725c8cf451800dad0`  
**Git tree:** `eaafe82e14e0cccccfbdd75a512f387b5564081a`  
**Scope:** `lib/tiannara/`, `tiannara_runtime/lib/tiannara/`, and `tiannara_runtime/lib/tiannara_runtime/`  
**Audit mode:** Read-only. No production files, runtime configuration, tests or state were changed.

## 1. Why this inventory exists

Directory duplication is not proof of duplicate functionality. A system can have several folders with the same name but different module namespaces, APIs, state stores and authority. Conversely, one directory can contain a mixture of real code, compatibility wrappers and stubs.

This map separates:
- **Directory match** — same basename appears more than once.
- **Module duplicate** — same fully qualified Elixir module name is defined in separate Mix projects or files.
- **Stub** — a placeholder or deterministic fallback instead of the promised capability.
- **Production candidate** — a substantive implementation that may perform the intended work.
- **Production-connected** — the actual application startup or consumer path invokes it.
- **Verified production** — runtime evidence confirms its behavior. No runtime verification was performed in this inventory.

A large file, GenServer, supervisor, passing unit test or module name does not by itself prove production capability.

## 2. Repository distribution

The recursive Git tree contains **27,948 entries**. Across the three requested roots:

| Root | Files | Directories |
|---|---:|---:|
| `lib/tiannara/` | 1,641 | 263 |
| `tiannara_runtime/lib/tiannara/` | 254 | 65 |
| `tiannara_runtime/lib/tiannara_runtime/` | 980 | 167 |

There are **97 repeated directory basenames** across these three trees. Of the requested system names, the inventory identifies the matches below. The count is a directory-name count, not 97 proven duplicate implementations.

## 3. Requested system directory map

A dash means no directory with that basename was found under the three audited roots. File counts are descendants beneath the matching directory, not counts of compiled modules.

| Requested name | Directory matches |
|---|---|
| A10 | `lib/tiannara/a10` (1 files)<br>`tiannara_runtime/lib/tiannara/a10` (6 files) |
| AAL | `lib/tiannara/aal` (4 files) |
| ACE | `lib/tiannara/ace` (8 files) |
| ACM | `lib/tiannara/acm` (2 files)<br>`tiannara_runtime/lib/tiannara/oed/acm` (11 files) |
| ALES | `lib/tiannara/ales` (1 files)<br>`tiannara_runtime/lib/tiannara_runtime/ales` (1 files) |
| ASC | `lib/tiannara/asc` (268 files) |
| CCI | `lib/tiannara/cci` (11 files) |
| CI | `lib/tiannara/ci` (7 files) |
| CIS | `lib/tiannara/cis` (8 files)<br>`tiannara_runtime/lib/tiannara/cis` (3 files)<br>`tiannara_runtime/lib/tiannara_runtime/cis` (2 files)<br>`tiannara_runtime/lib/tiannara_runtime/legacy/cis` (2 files) |
| CRAV | `lib/tiannara/crav` (21 files) |
| CTL | `lib/tiannara/ctl` (7 files)<br>`tiannara_runtime/lib/tiannara_runtime/ctl` (5 files) |
| DFG | `lib/tiannara/dfg` (2 files)<br>`lib/tiannara/topology/dfg` (5 files)<br>`tiannara_runtime/lib/tiannara_runtime/dfg` (6 files) |
| EDM | `lib/tiannara/edm` (3 files) |
| EOS | `lib/tiannara/eos` (10 files) |
| ERO | `lib/tiannara/ero` (1 files) |
| EUF | `lib/tiannara/euf` (1 files)<br>`tiannara_runtime/lib/tiannara_runtime/euf` (1 files) |
| HAI | `lib/tiannara/hai` (10 files) |
| IRD | `lib/tiannara/ird` (1 files)<br>`lib/tiannara/physics/ird` (5 files)<br>`tiannara_runtime/lib/tiannara_runtime/ird` (7 files) |
| LEOC | `lib/tiannara/leoc` (2 files) |
| MSG | `lib/tiannara/msg` (1 files)<br>`tiannara_runtime/lib/tiannara_runtime/msg` (3 files) |
| NDE | `lib/tiannara/nde` (3 files)<br>`lib/tiannara/physics/nde` (5 files) |
| OAVL | `lib/tiannara/oavl` (1 files)<br>`tiannara_runtime/lib/tiannara/oed/oavl` (8 files) |
| OCM | `lib/tiannara/ocm` (8 files)<br>`lib/tiannara/stabilization/ocm` (5 files)<br>`tiannara_runtime/lib/tiannara_runtime/ocm` (5 files) |
| OED | `lib/tiannara/oed` (2 files)<br>`tiannara_runtime/lib/tiannara/oed` (33 files)<br>`tiannara_runtime/lib/tiannara_runtime/oed` (5 files) |
| OMCE | `lib/tiannara/omce` (1 files)<br>`tiannara_runtime/lib/tiannara_runtime/omce` (5 files) |
| OMCS | `lib/tiannara/omcs` (7 files)<br>`tiannara_runtime/lib/tiannara_runtime/omcs` (2 files) |
| P9X | `tiannara_runtime/lib/tiannara/p9x` (3 files) |
| OS | `lib/tiannara/os` (219 files)<br>`tiannara_runtime/lib/tiannara_runtime/os` (58 files) |
| REA | `lib/tiannara/rea` (43 files)<br>`tiannara_runtime/lib/tiannara/phase16/rea` (8 files) |
| REL | `lib/tiannara/rel` (12 files) |
| ROS | `lib/tiannara/ros` (7 files) |
| RSME | `lib/tiannara/rsme` (1 files) |
| SOPL | `lib/tiannara/sentinel/sopl` (1 files)<br>`lib/tiannara/sopl` (28 files) |
| TWP | `lib/tiannara/physics/twp` (5 files)<br>`lib/tiannara/twp` (9 files) |
| UCC | `lib/tiannara/ucc` (10 files)<br>`tiannara_runtime/lib/tiannara/phase17/ucc` (8 files) |
| omega | `lib/tiannara/omega` (44 files)<br>`tiannara_runtime/lib/tiannara_runtime/omega` (12 files) |
| Operations | `lib/tiannara/asc/operations` (1 files)<br>`lib/tiannara/operations` (8 files) |
| Orbital | `lib/tiannara/orbital` (1 files) |
| Meta | `lib/tiannara/meta` (6 files)<br>`tiannara_runtime/lib/tiannara_runtime/meta` (42 files) |
| meta-science | `lib/tiannara/asc/meta_science` (4 files)<br>`lib/tiannara/meta_science` (3 files) |
| meta-governance | `lib/tiannara/os/governance` (103 files)<br>`tiannara_runtime/lib/tiannara_runtime/meta/governance` (1 files)<br>`tiannara_runtime/lib/tiannara_runtime/os/governance` (45 files) |
| math | `lib/tiannara/math` (6 files) |
| interface | `lib/tiannara/asc/interface` (18 files)<br>`lib/tiannara/interface` (10 files) |
| integration | `lib/tiannara/integration` (7 files) |
| empirical validation | `lib/tiannara/empirical_validation` (1 files) |
| engineering | `lib/tiannara/asc/engineering` (14 files)<br>`lib/tiannara/engineering` (13 files)<br>`tiannara_runtime/lib/tiannara/world_model/engineering` (1 files) |
| epistemic | `lib/tiannara/epistemic` (3 files)<br>`lib/tiannara/rea/epistemic` (7 files) |
| epistemic mirror | `lib/tiannara/epistemic_mirror` (6 files) |
| Chaos | `lib/tiannara/chaos` (4 files) |
| certification | `lib/tiannara/certification` (11 files)<br>`lib/tiannara/os/governance/certification` (10 files)<br>`tiannara_runtime/lib/tiannara_runtime/certification` (1 files)<br>`tiannara_runtime/lib/tiannara_runtime/os/governance/certification` (45 files) |
| archaeology | `lib/tiannara/archaeology` (1 files) |
| architecture | `lib/tiannara/architecture` (2 files)<br>`lib/tiannara/asc/architecture` (2 files) |
| agency | `lib/tiannara/agency` (8 files)<br>`lib/tiannara/asc/agency` (2 files) |
| autonomy | `lib/tiannara/autonomy` (7 files) |
| base_reality | `lib/tiannara/base_reality` (1 files) |
| Causal | `lib/tiannara/causal` (1 files)<br>`lib/tiannara/rea/causal` (13 files)<br>`tiannara_runtime/lib/tiannara_runtime/causal` (1 files) |
| coherence | `lib/tiannara/coherence` (1 files) |
| constitution | `lib/tiannara/constitution` (6 files)<br>`lib/tiannara/eos/constitution` (2 files)<br>`tiannara_runtime/lib/tiannara_runtime/constitution` (5 files) |
| core | `lib/tiannara/asc/core` (8 files)<br>`lib/tiannara/core` (32 files)<br>`tiannara_runtime/lib/tiannara/core` (2 files)<br>`tiannara_runtime/lib/tiannara/sentinel/observatories/core` (6 files) |
| cosmology | `lib/tiannara/cosmology` (1 files) |
| council | `lib/tiannara/council` (19 files) |
| diagnostics | `lib/tiannara/diagnostics` (2 files) |
| discoveries | `lib/tiannara/discoveries` (35 files) |
| discovery | `lib/tiannara/discovery` (51 files) |
| ecology | `lib/tiannara/asc/ecology` (4 files)<br>`lib/tiannara/ecology` (3 files)<br>`tiannara_runtime/lib/tiannara_runtime/ecology` (7 files) |
| economics | `lib/tiannara/economics` (2 files) |
| evidence | `lib/tiannara/evidence` (3 files) |
| evolution | `lib/tiannara/asc/evolution` (5 files)<br>`lib/tiannara/evolution` (11 files)<br>`tiannara_runtime/lib/tiannara_runtime/evolution` (11 files)<br>`tiannara_runtime/lib/tiannara_runtime/ose/evolution` (4 files) |
| executive | `lib/tiannara/asc/executive` (5 files)<br>`lib/tiannara/eos/executive` (2 files)<br>`lib/tiannara/executive` (31 files) |
| external | — |
| forecasting | `lib/tiannara/asc/forecasting` (4 files)<br>`lib/tiannara/forecasting` (51 files)<br>`tiannara_runtime/lib/tiannara/sentinel/forecasting` (3 files) |
| foundations | `lib/tiannara/foundations` (3 files) |
| funnel | `lib/tiannara/funnel` (1 files) |
| graph | `lib/tiannara/graph` (12 files) |
| intent | `lib/tiannara/intent` (2 files) |
| knowledge graph | `lib/tiannara/knowledge_graph` (2 files) |
| lineage | `lib/tiannara/lineage` (2 files) |
| logic | `lib/tiannara/logic` (5 files) |
| memory | `lib/tiannara/asc/memory` (1 files)<br>`lib/tiannara/memory` (8 files)<br>`lib/tiannara/research/memory` (1 files)<br>`tiannara_runtime/lib/tiannara_runtime/memory` (1 files)<br>`tiannara_runtime/lib/tiannara_runtime/meta/memory` (1 files) |
| observatory | `lib/tiannara/asc/observatory` (3 files)<br>`lib/tiannara/observatory` (13 files)<br>`lib/tiannara/rea/observatory` (1 files)<br>`tiannara_runtime/lib/tiannara_runtime/os/observatory` (6 files) |
| physics | `lib/tiannara/physics` (25 files)<br>`tiannara_runtime/lib/tiannara_runtime/physics` (2 files) |
| protobuf | `lib/tiannara/protobuf` (2 files) |
| principles | `lib/tiannara/council/principles` (2 files)<br>`lib/tiannara/principles` (1 files) |
| provenance | `lib/tiannara/provenance` (1 files) |
| reality | `lib/tiannara/asc/reality` (24 files)<br>`lib/tiannara/reality` (3 files) |
| reasoning | `lib/tiannara/reasoning` (2 files) |
| repro | `lib/tiannara/integration/repro` (1 files)<br>`lib/tiannara/repro` (3 files) |
| research | `lib/tiannara/asc/research` (16 files)<br>`lib/tiannara/research` (14 files) |
| self improvement | `lib/tiannara/self_improvement` (10 files) |
| sentinel | `lib/tiannara/sentinel` (63 files)<br>`tiannara_runtime/lib/tiannara/sentinel` (89 files) |
| simulation | `lib/tiannara/simulation` (12 files)<br>`tiannara_runtime/lib/tiannara/world_model/simulation` (1 files) |
| soak | `lib/tiannara/soak` (7 files) |
| specialists | `lib/tiannara/asc/civilization/specialists` (4 files)<br>`lib/tiannara/specialists` (4 files) |
| stabilization | `lib/tiannara/stabilization` (19 files)<br>`tiannara_runtime/lib/tiannara_runtime/meta/opc/stabilization` (8 files) |
| storage | `lib/tiannara/storage` (4 files) |
| system health | `lib/tiannara/system_health` (3 files) |
| tech debt | `lib/tiannara/tech_debt` (4 files) |
| Telemetry | `lib/tiannara/telemetry` (6 files)<br>`tiannara_runtime/lib/tiannara/telemetry` (1 files)<br>`tiannara_runtime/lib/tiannara_runtime/meta/opc/telemetry` (3 files)<br>`tiannara_runtime/lib/tiannara_runtime/telemetry` (1 files) |
| temporal decay | `lib/tiannara/temporal_decay` (1 files) |
| tool forge | `lib/tiannara/tool_forge` (7 files) |
| topology | `lib/tiannara/topology` (31 files)<br>`tiannara_runtime/lib/tiannara_runtime/topology` (1 files) |
| EID | `tiannara_runtime/lib/tiannara/eid` (5 files) |
| GRCC | `tiannara_runtime/lib/tiannara/grcc` (3 files)<br>`tiannara_runtime/lib/tiannara_runtime/grcc` (3 files) |
| MSCL | `tiannara_runtime/lib/tiannara/mscl` (4 files)<br>`tiannara_runtime/lib/tiannara_runtime/legacy/mscl` (7 files) |
| OLEF | `lib/tiannara/stabilization/olef` (4 files)<br>`tiannara_runtime/lib/tiannara/olef` (6 files)<br>`tiannara_runtime/lib/tiannara_runtime/legacy/olef` (10 files)<br>`tiannara_runtime/lib/tiannara_runtime/opc/v3/olef` (8 files) |
| phase8 | `tiannara_runtime/lib/tiannara/phase8` (7 files) |
| phase9 | `tiannara_runtime/lib/tiannara/phase9` (7 files) |
| phase10 | `tiannara_runtime/lib/tiannara/phase10` (5 files) |
| phase11 | `tiannara_runtime/lib/tiannara/phase11` (6 files) |
| phase12 | — |
| phase13 | `tiannara_runtime/lib/tiannara/phase13` (1 files) |
| phase14 | `tiannara_runtime/lib/tiannara/phase14` (12 files) |
| phase15 | `tiannara_runtime/lib/tiannara/phase15` (7 files) |
| phase16 | `tiannara_runtime/lib/tiannara/phase16` (8 files) |
| phase17 | `tiannara_runtime/lib/tiannara/phase17` (8 files) |
| phase18 | `tiannara_runtime/lib/tiannara/phase18` (1 files) |
| phase19 | `tiannara_runtime/lib/tiannara/phase19` (9 files) |
| pre_phase6 | `tiannara_runtime/lib/tiannara/pre_phase6` (4 files) |
| ACF | `lib/tiannara/topology/acf` (5 files)<br>`tiannara_runtime/lib/tiannara_runtime/acf` (3 files) |
| autonomous research | `tiannara_runtime/lib/tiannara_runtime/autonomous_research` (26 files)<br>`tiannara_runtime/lib/tiannara_runtime/world_model/autonomous_research` (32 files) |
| bridge | `tiannara_runtime/lib/tiannara_runtime/bridge` (10 files) |
| causality | `tiannara_runtime/lib/tiannara_runtime/causality` (5 files) |
| CCOS | `tiannara_runtime/lib/tiannara_runtime/ccos` (9 files) |
| CCR | `lib/tiannara/topology/ccr` (5 files)<br>`tiannara_runtime/lib/tiannara_runtime/ccr` (4 files) |
| civilization | `lib/tiannara/asc/civilization` (26 files)<br>`tiannara_runtime/lib/tiannara_runtime/civilization` (61 files)<br>`tiannara_runtime/lib/tiannara_runtime/cognitive/civilization` (15 files) |
| CLSL | `tiannara_runtime/lib/tiannara_runtime/clsl` (2 files) |
| cognitive | `lib/tiannara/executive/cognitive` (8 files)<br>`tiannara_runtime/lib/tiannara_runtime/cognitive` (161 files) |
| contracts | `tiannara_runtime/lib/tiannara/sentinel/contracts` (10 files)<br>`tiannara_runtime/lib/tiannara_runtime/contracts` (4 files) |
| core_stack | `tiannara_runtime/lib/tiannara_runtime/core_stack` (4 files) |
| cortex | `tiannara_runtime/lib/tiannara_runtime/cortex` (2 files) |
| CRA | `tiannara_runtime/lib/tiannara_runtime/cra` (5 files) |
| cross_dimensional | `tiannara_runtime/lib/tiannara_runtime/cross_dimensional` (5 files) |
| EPC | `tiannara_runtime/lib/tiannara_runtime/epc` (9 files) |
| GCK | `tiannara_runtime/lib/tiannara_runtime/gck` (1 files)<br>`tiannara_runtime/lib/tiannara_runtime/meta/opc/gck` (1 files) |
| genetics | `tiannara_runtime/lib/tiannara_runtime/genetics` (1 files) |
| god_loop | `tiannara_runtime/lib/tiannara_runtime/god_loop` (5 files) |
| HSV | `lib/tiannara/stabilization/hsv` (5 files)<br>`tiannara_runtime/lib/tiannara_runtime/hsv` (3 files) |
| identity | `tiannara_runtime/lib/tiannara_runtime/identity` (5 files) |
| l1_physics | `tiannara_runtime/lib/tiannara_runtime/l1_physics` (3 files) |
| legacy | `tiannara_runtime/lib/tiannara_runtime/legacy` (19 files) |
| mathematics | `lib/tiannara/foundations/mathematics` (1 files)<br>`tiannara_runtime/lib/tiannara_runtime/mathematics` (29 files) |
| MCAL | `tiannara_runtime/lib/tiannara_runtime/mcal` (10 files) |
| MCAL_v2 | `tiannara_runtime/lib/tiannara_runtime/mcal_v2` (7 files) |
| meta_ecology | `tiannara_runtime/lib/tiannara_runtime/meta_ecology` (6 files) |
| meta_stability | `tiannara_runtime/lib/tiannara_runtime/meta_stability` (3 files) |
| monitoring | `tiannara_runtime/lib/tiannara_runtime/monitoring` (5 files) |
| multi_World | `tiannara_runtime/lib/tiannara_runtime/multi_world` (10 files) |
| multi history | — |
| native | `tiannara_runtime/lib/tiannara_runtime/native` (1 files) |
| NATS | `tiannara_runtime/lib/tiannara_runtime/nats` (19 files) |
| observability | `lib/tiannara/rea/observability` (2 files)<br>`tiannara_runtime/lib/tiannara_runtime/observability` (3 files) |
| OP | — |
| Öse | — |
| OSK | `tiannara_runtime/lib/tiannara_runtime/osk` (2 files) |
| POF | `tiannara_runtime/lib/tiannara_runtime/pof` (7 files) |
| predictive | `tiannara_runtime/lib/tiannara_runtime/predictive` (2 files) |
| resources | `tiannara_runtime/lib/tiannara_runtime/resources` (1 files) |
| RODL | `tiannara_runtime/lib/tiannara_runtime/rodl` (2 files) |
| RRG | `lib/tiannara/topology/rrg` (5 files)<br>`tiannara_runtime/lib/tiannara_runtime/rrg` (19 files) |
| runtime_layers | `tiannara_runtime/lib/tiannara_runtime/runtime_layers` (1 files) |
| SCL | `tiannara_runtime/lib/tiannara_runtime/scl` (3 files) |
| self compilation | `tiannara_runtime/lib/tiannara_runtime/self_compilation` (5 files) |
| shared | `tiannara_runtime/lib/tiannara_runtime/shared` (2 files) |
| speciation | `tiannara_runtime/lib/tiannara_runtime/speciation` (1 files) |
| world_model | `lib/tiannara/core/world_model` (20 files)<br>`tiannara_runtime/lib/tiannara/world_model` (4 files)<br>`tiannara_runtime/lib/tiannara_runtime/world_model` (175 files) |

### 3.1 Top-level duplicates across the three roots

The following **29** basenames occur as top-level directories in more than one of the three roots:

| Directory basename | Locations |
|---|---|
| `a10` | `lib/tiannara/a10`<br>`tiannara_runtime/lib/tiannara/a10` |
| `ales` | `lib/tiannara/ales`<br>`tiannara_runtime/lib/tiannara_runtime/ales` |
| `audit` | `lib/tiannara/audit`<br>`tiannara_runtime/lib/tiannara/audit` |
| `causal` | `lib/tiannara/causal`<br>`tiannara_runtime/lib/tiannara_runtime/causal` |
| `certification` | `lib/tiannara/certification`<br>`tiannara_runtime/lib/tiannara_runtime/certification` |
| `cis` | `lib/tiannara/cis`<br>`tiannara_runtime/lib/tiannara/cis`<br>`tiannara_runtime/lib/tiannara_runtime/cis` |
| `constitution` | `lib/tiannara/constitution`<br>`tiannara_runtime/lib/tiannara_runtime/constitution` |
| `core` | `lib/tiannara/core`<br>`tiannara_runtime/lib/tiannara/core` |
| `ctl` | `lib/tiannara/ctl`<br>`tiannara_runtime/lib/tiannara_runtime/ctl` |
| `debug` | `lib/tiannara/debug`<br>`tiannara_runtime/lib/tiannara_runtime/debug` |
| `dfg` | `lib/tiannara/dfg`<br>`tiannara_runtime/lib/tiannara_runtime/dfg` |
| `ecology` | `lib/tiannara/ecology`<br>`tiannara_runtime/lib/tiannara_runtime/ecology` |
| `euf` | `lib/tiannara/euf`<br>`tiannara_runtime/lib/tiannara_runtime/euf` |
| `evolution` | `lib/tiannara/evolution`<br>`tiannara_runtime/lib/tiannara_runtime/evolution` |
| `ird` | `lib/tiannara/ird`<br>`tiannara_runtime/lib/tiannara_runtime/ird` |
| `memory` | `lib/tiannara/memory`<br>`tiannara_runtime/lib/tiannara_runtime/memory` |
| `meta` | `lib/tiannara/meta`<br>`tiannara_runtime/lib/tiannara_runtime/meta` |
| `msg` | `lib/tiannara/msg`<br>`tiannara_runtime/lib/tiannara_runtime/msg` |
| `ocm` | `lib/tiannara/ocm`<br>`tiannara_runtime/lib/tiannara_runtime/ocm` |
| `oed` | `lib/tiannara/oed`<br>`tiannara_runtime/lib/tiannara/oed`<br>`tiannara_runtime/lib/tiannara_runtime/oed` |
| `omce` | `lib/tiannara/omce`<br>`tiannara_runtime/lib/tiannara_runtime/omce` |
| `omcs` | `lib/tiannara/omcs`<br>`tiannara_runtime/lib/tiannara_runtime/omcs` |
| `omega` | `lib/tiannara/omega`<br>`tiannara_runtime/lib/tiannara_runtime/omega` |
| `os` | `lib/tiannara/os`<br>`tiannara_runtime/lib/tiannara_runtime/os` |
| `physics` | `lib/tiannara/physics`<br>`tiannara_runtime/lib/tiannara_runtime/physics` |
| `sentinel` | `lib/tiannara/sentinel`<br>`tiannara_runtime/lib/tiannara/sentinel` |
| `telemetry` | `lib/tiannara/telemetry`<br>`tiannara_runtime/lib/tiannara/telemetry`<br>`tiannara_runtime/lib/tiannara_runtime/telemetry` |
| `topology` | `lib/tiannara/topology`<br>`tiannara_runtime/lib/tiannara_runtime/topology` |
| `grcc` | `tiannara_runtime/lib/tiannara/grcc`<br>`tiannara_runtime/lib/tiannara_runtime/grcc` |
| `world_model` | `tiannara_runtime/lib/tiannara/world_model`<br>`tiannara_runtime/lib/tiannara_runtime/world_model` |

### 3.2 Important nested duplicates

The requested names also occur inside other system boundaries. Examples include:
- `lib/tiannara/asc/agency` and `lib/tiannara/agency`.
- `lib/tiannara/asc/architecture` and `lib/tiannara/architecture`.
- `lib/tiannara/asc/core`, `lib/tiannara/core`, and runtime core directories.
- `lib/tiannara/rea/causal`, `lib/tiannara/causal`, and runtime causal.
- `lib/tiannara/asc/research` and `lib/tiannara/research`.
- `lib/tiannara/asc/meta_science` and `lib/tiannara/meta_science`.
- `lib/tiannara/asc/operations` and `lib/tiannara/operations`.
- `lib/tiannara/asc/observatory`, `lib/tiannara/observatory`, and `lib/tiannara/rea/observatory`.
- `lib/tiannara/physics/twp` and `lib/tiannara/twp`.
- `lib/tiannara/sentinel/sopl` and `lib/tiannara/sopl`.
- `lib/tiannara/os/governance/certification` and the root/runtime certification directories.

These may be legitimate bounded subdomains, old versions, adapters or competing implementations. Their ownership must be determined from module declarations, call sites and startup wiring.

## 4. Explicit stub inventory

The `lib/tiannara/stubs/` directory contains ten functional stub modules plus `stub.ex` and `stub_registry.ex`. Two additional modules outside that folder also use `Tiannara.Stub`: `Tiannara.ASC.Interface.Protocol` and `Tiannara.REA.TheoryNiches`.

| Stub module / function | Stub behavior | Production counterpart / candidate | Consumer / integration finding |
|---|---|---|---|
| `Tiannara.Ctl.CausalRegistry.get_branch/1` | Returns `{:ok, %{stress: 0.0}}` | `lib/tiannara/ctl/causal_registry.ex` defines `Tiannara.CTL.CausalRegistry`, not the exact `Tiannara.Ctl` module; its active-branch count is hardcoded to 10,000 and it has no matching `get_branch/1` | `Tiannara.Ctl.BranchValidator` aliases and calls the stub; merge stress defaults to zero |
| `Tiannara.Meta.CausalDataLayer.Traversal.get_sparse_snapshot/1` | Returns empty nodes and edges | No exact production module found in the three audited roots | Used by `Tiannara.Sentinel.EpistemicShadowGraph`; only test usage of ESG was found |
| `Tiannara.ASC.Crucible.Supervisor.run/1` | Returns `{:ok, :stub}` | No production `Tiannara.ASC.Crucible.Supervisor` found; actual crucible engine modules exist under `lib/tiannara/asc/crucible/`, but no corresponding supervisor | `Pipeline.Phases.handler(:crucible)` resolves to this stub; `SubCiv.Supervisor` comments it out; Pipeline.Worker treats `{:ok, :stub}` as completion and advances |
| `GenerationHistory` | `new/1` delegates to real constructor; `calculate_cai/1` returns 0.0; `append_to_file/2` returns :ok without writing | `lib/tiannara/os/kernel/generation_history.ex` defines `TiannaraOS.Kernel.GenerationHistory` | Stage-6 runner calls unqualified `GenerationHistory`; its CSV append is routed to the stub |
| `Graph.out_edges/2` | Returns an empty list | `Tiannara.Graph.UnifiedRealityGraph` exists but is a different module/API; no exact global `Graph` implementation found in root application | No production consumer of this stub established in this pass |
| `TiannaraOS.LifecycleRegistry.track_entity/4` | Returns `{:ok, :tracked}` | `lib/tiannara/lifecycle_registry.ex` defines `Tiannara.LifecycleRegistry` with a different module name and API | `TiannaraOS.PrincipleRegistry` aliases the stub namespace; root app starts the differently named registry |
| `Tiannara.Meta.Epistemics.LongitudinalMemory.get_compressed_state/1` | Returns a fixed LEOC vector | No exact production module found; `Tiannara.LEOC.LatentVault` is a separate service/API | Used by ESG; only test caller found |
| `TiannaraOS.ScientificCapitalLedger.calculate_delta/2` | Returns `{:ok, 0}` | `lib/tiannara/os/kernel/scientific_capital_ledger.ex` defines `TiannaraOS.Kernel.ScientificCapitalLedger`; runtime also has `TiannaraRuntime.Civilization.Economy.ScientificCapitalLedger` | Stage-6 runner calls the stub namespace, then performs numeric addition with the returned tuple |
| `Tiannara.Sentinel.PressureMonitor.get_latest_deltas/0` | Returns current tick and empty worlds | Runtime has `Tiannara.Sentinel.Monitors.PressureMonitor`, a different module | TelemetryChannel checks `Process.whereis(Tiannara.Sentinel.PressureMonitor)`; no process-start path for the stub was found, so its empty fallback is used |
| `Tiannara.Twp.SurvivabilityEstimator.estimate/1` | Returns 0.5 | No exact production counterpart found | `Tiannara.Twp.WavefunctionSolver.solve/1` consumes it and defaults to `:continue` at 0.5 |
| `Tiannara.ASC.Interface.Protocol.hybrid/2` | Returns a generic map rather than the Protocol struct | Same file implements other protocol helpers; this is a partially stubbed module, not a fully missing implementation | Consumers must not assume `hybrid/2` returns the same shape as other protocol constructors |
| `Tiannara.REA.TheoryNiches.classify_theories/1` | Returns `{:ok, []}` | Same file has a separate real `classify_niches/1`; no replacement for `classify_theories/1` found | Partial stub inside an otherwise implemented theory-selection module |

## 5. Stub observability is not wired

`Tiannara.Stub` records a call only when `Process.whereis(Tiannara.StubRegistry)` returns a process. The root `Tiannara.Application.core_children/0` does not start `Tiannara.StubRegistry`; the runtime application/startup tree does not start it either. Repository search found no `Tiannara.StubRegistry.start_link/1` call site.

Therefore the registry's advertised call-count/telemetry behavior is not established in normal startup. A stub can return its configured default without being recorded in the registry. The configured defaults include success-shaped values such as `{:ok, :tracked}`, `{:ok, 0}`, `:ok` and `{:ok, :stub}`.

**Conclusion:** the registry is a useful intended audit mechanism, but the current startup wiring does not make it an operational stub-usage ledger.

## 6. Confirmed production-path stub bypasses

### 6.1 Scientific capital and generation history

The Stage-6 runner calls `TiannaraOS.ScientificCapitalLedger.calculate_delta/2`, whose stub returns `{:ok, 0}`. The runner then adds the returned value to numeric previous capital. The tuple return is incompatible with that arithmetic.

The same runner calls unqualified `GenerationHistory.calculate_cai/1` and `GenerationHistory.append_to_file/2`. The global `GenerationHistory` stub returns 0.0 for CAI and :ok for append without writing. The substantive implementations exist under `TiannaraOS.Kernel.GenerationHistory` and `TiannaraOS.Kernel.ScientificCapitalLedger`, but the runner's calls do not target those modules.

A third ledger implementation exists in the runtime project at `TiannaraRuntime.Civilization.Economy.ScientificCapitalLedger`; it is a separate in-memory transaction model. These three namespaces must not be treated as one canonical ledger.

### 6.2 ASC Crucible phase

The pipeline phase table routes `:crucible` to `Tiannara.ASC.Crucible.Supervisor`, which is the stub returning `{:ok, :stub}`. The sub-civilization supervisor explicitly comments out that supervisor with a TODO. The pipeline worker interprets `{:ok, :stub}` as a completed phase and automatically advances the project.

Thus a pipeline can move past the Crucible phase without executing the intended Crucible verification. This is an executable bypass, not merely an unused placeholder.

### 6.3 CTL branch stress validation

`Tiannara.Ctl.BranchValidator` aliases `Tiannara.Ctl.CausalRegistry`. That exact module is the stub returning stress 0.0. The similarly named file `lib/tiannara/ctl/causal_registry.ex` defines `Tiannara.CTL.CausalRegistry` (different capitalization/module atom), and its `get_active_branches/0` returns a hardcoded mock count of 10,000. It does not implement the stub's `get_branch/1` API.

The branch validator consequently receives a zero-stress record from the stub rather than an authoritative branch record. Its merge stress check then passes for that default.

## 7. Additional behavioral placeholders discovered

### 7.1 A10 — duplicate module definitions and competing algorithms

- Root: `lib/tiannara/a10/supervisor.ex`.
- Runtime: `tiannara_runtime/lib/tiannara/a10/supervisor.ex` plus separate analyzer/tensor/memory/sampler/emitter files.
- Both projects define the same `Tiannara.A10.*` module names, but the algorithms differ.
- Root `AttractorAnalyzer` derives stability using `Enum.random(60..100)`; root `Sampler` uses random coordinates.
- Runtime A10 uses event-count approximations to form a five-dimensional drift vector, computes covariance and classifies phases. It is more substantive but the sampler itself explicitly describes its values as approximations.
- Root application does not include A10 in its ordinary `core_children`; Phase Ω activation is invoked by the explicit Mix task `phase_omega_scan`. Runtime `RootSupervisor` does not include the legacy `Tiannara.Governance.Supervisor` that starts A10.

**Disposition:** duplicate implementation and startup ownership unresolved; neither variant is certified as the sole production A10.

### 7.2 CIS — multiple implementations and safety authorities

Relevant locations:
- `lib/tiannara/cis/` and `lib/tiannara/cis/supervisor.ex`.
- `tiannara_runtime/lib/tiannara/cis/` and `tiannara_runtime/lib/tiannara/supervisors.ex`.
- `tiannara_runtime/lib/tiannara_runtime/cis/`.
- `tiannara_runtime/lib/tiannara_runtime/legacy/cis/`.
- `tiannara_runtime/lib/tiannara_runtime/core_stack/cis_supervisor.ex`.

The root application starts `Tiannara.CIS.Supervisor`. The runtime application separately starts `TiannaraRuntime.CIS.Supervisor` and `TiannaraRuntime.CIS.ExecutionController`. The latter supervisor is a small safety-mode GenServer; the separate legacy supervisor contains a richer arbitration API but is not part of the current `RootSupervisor`. The deprecated core-stack supervisor starts no children. The runtime project also contains another `Tiannara.CIS.Supervisor` under its older namespace.

**Disposition:** CIS requires a single role/authority map. Do not merge or retire variants until their callers, kill-switch paths, authorization semantics and test coverage are traced.

### 7.3 OED — same module namespace, different application implementations

- Root `lib/tiannara/oed/supervisor.ex` defines `Tiannara.OED.Supervisor` and many child modules inline; several are in-memory scaffolds, and the ACM Crucible and OAVL validation supervisors start empty child lists.
- Runtime `tiannara_runtime/lib/tiannara/oed/supervisor.ex` defines the same `Tiannara.OED.Supervisor` module in the separate runtime Mix project and splits its children into separate files.
- `tiannara_runtime/lib/tiannara_runtime/oed/oed.ex` defines `Tiannara.Runtime.OED.OED`, a distinct Ontological Escape Dynamics component, not the same Ontological Evolution & Defense subsystem.

The root Phase Ω wiring refers to the root OED supervisor. The runtime `RootSupervisor` does not include the legacy `Tiannara.OED.Supervisor`.

**Disposition:** module identity, runtime owner and intended meaning of OED must be made explicit.

### 7.4 OCM — three separate consensus implementations

- `lib/tiannara/ocm/` contains modules that simulate drift, lineage and translation, return fixed values, or start empty supervisors.
- `lib/tiannara/stabilization/ocm/` contains a separate ETS-based consensus/voting system started by `Tiannara.Stabilization.OCM.Supervisor`.
- `tiannara_runtime/lib/tiannara_runtime/ocm/` contains `TiannaraRuntime.OCM.Registry`, drift analysis and a consensus engine. The runtime Ecology supervisor includes this OCM supervisor as an optional child.

These systems have different APIs, storage, consensus semantics and ownership. They cannot be treated as one production OCM merely because they share a directory basename.

### 7.5 IRD, NDE and DFG — main engines plus status-only auxiliary workers

The root physics and topology supervisors start auxiliary GenServers whose inspected implementations only initialize counters and answer `:status`:
- IRD: `Coordinator`, `DampeningEngine`, `NATSIntegration`, `ResonanceCalculator`.
- NDE: `ChaosAnalyzer`, `DifferentiationEngine`, `NegentropyCalculator`, `PatternOptimizer`.
- DFG: `Folder`, `HomologyComputer`, `TransformationEngine`, `IntegrityValidator`.

The larger main modules `lib/tiannara/physics/ird.ex`, `lib/tiannara/physics/nde.ex` and `lib/tiannara/topology/dfg.ex` do exist. The finding is not that the entire IRD/NDE/DFG systems are empty; it is that several named child capabilities are supervised shells rather than implemented services.

## 8. Preliminary production ownership and startup matrix

| System | Root application | Runtime application | Initial disposition |
|---|---|---|---|
| CIS | Starts `Tiannara.CIS.Supervisor` | Starts `TiannaraRuntime.CIS.Supervisor` and ExecutionController | Multiple active/legacy models; authority not unified |
| A10 | Not in ordinary core children; Phase Ω activation can start root variant | Legacy Governance supervisor is outside current RootSupervisor | Startup/owner unresolved |
| OED | Phase Ω wiring can start root variant | Runtime OED supervisor exists but is not a RootSupervisor child | Competing definitions; active route must be established |
| OCM | Stabilization supervisor starts root stabilization OCM; root `lib/tiannara/ocm` is separate | Runtime Ecology supervisor includes runtime OCM | Three APIs/implementations; canonical authority unresolved |
| Crucible | ASC pipeline resolves to explicit stub | OED/ACM runtime Crucible is a different subsystem | ASC Crucible not implemented as the pipeline's handler |
| StubRegistry | Not in root core children | Not in runtime RootSupervisor | Stub call tracking not wired |

“Starts” here is based on static supervision-tree declarations, not an observed runtime boot.

## 9. Remediation and unification rules

1. Do not delete duplicate folders solely because their names match.
2. For each system, select one canonical module namespace and authority owner after tracing all consumers.
3. Move legitimate variants behind explicit adapters and versioned contracts.
4. Replace stub success-shaped returns with typed `UNIMPLEMENTED` / `BLOCKED` results until the production contract exists.
5. Start the stub registry under supervision or remove claims that it provides runtime tracking.
6. Make pipeline workers block or fail when a required phase is stubbed; never auto-advance as if the phase executed.
7. Health probes must verify required operations and postconditions, not merely process liveness.
8. Retire legacy variants only after consumers and state have been migrated and independently verified.
9. Preserve specialized engines when they have legitimate distinct responsibilities; unify authority and contracts, not every implementation.

## 10. Scope limits and next audit work

- This is a static tree/source inspection of the three named roots on `main` at `b829254d032f9e0b5cf4c44725c8cf451800dad0`.
- No compile, tests, runtime boot, call tracing, fault injection or deployment was performed.
- Search results were used to locate candidate call sites; exact source files were then read at the named commit.
- Directory presence, module loadability and a supervisor child declaration do not prove successful startup or production use.
- Some systems in the user's list have nested directories or alternate naming; the full directory map above preserves those paths.
- Further work must trace all consumers and runtime startup for the remaining systems, including AAL, ACE, ACM, ALES, CCI, CI, CRAV, EDM, EOS, ERO, EUF, HAI, LEOC, MSG, OAVL, OMCE, OMCS, P9X, REL, ROS, RSME, SOPL, UCC, Council, CEL, Meta-SOPL, GRCC, MSCL, OLEF, ASC, REA, hardware, Sentinel and the phase directories.

**Next checkpoint:** trace exact module definitions, all direct callers, and actual boot ownership for every duplicated system. Build a canonical authority/production/stub/legacy matrix before proposing any retirement or code changes.
