# Tiannara System Unification and Closure Program — Phase R0 Report

**Program:** Tiannara System Unification and Closure
**Phase:** R0 — Establish truth (read-only discovery)
**Repository:** `Kimiti4/Tiannara` (`https://github.com/Kimiti4/Tiannara.git`)
**Baseline:** branch `local/pr4` @ `521cb7fe513a466302ec3bb398940df3814edf2d`
**Separate repository inventoried:** `Kimiti4/autonomous-API-Gen` (ESAP) @ `main` / `062cbeb` — never merged
**Date:** 2026-10-20
**Status:** R0 discovery complete. **No production code was modified, moved, or deleted. No capability is claimed closed. No remediation has begun.** The program stops here for review, as instructed.

---

## 1. Executive summary

The repository is not a platform that is slightly broken. It is a large, well-documented, partially-connected collection of subsystems in which **most claimed capabilities have an implementation, and only a few have an operating runtime path**.

Of **117 registered capabilities**, **5 are verified operational** (4.3 %), **43 are implemented but incompletely verified**, **47 are partially connected**, **5 are specified only**, and **17 are missing or unresolved**. On the spec-vs-code-vs-runtime axis, only **6 are MATCHED**; **60 are PARTIAL**, **38 are CONTRADICTED** and **13 are UNKNOWN**.

The audit produced **130 findings** (13 critical, 48 high, 59 medium, 10 low) and grouped them into **14 root-cause clusters**. Five structural causes explain almost everything:

1. **C1 — the boot tree does not include the subsystem (24 capabilities).** The launcher never starts `:tiannara_runtime`; the whole second OTP root — including the constitutional layer, OPC, OLEF, the research and simulation stacks — is reachable only from a test setup. Every "wired" claim inside it is a *test-time* wiring claim.
2. **C3 — authority without enforcement (19 capabilities, 4 critical).** The Council computes a decision and downstream code declines to be bound by it: a policy `:approve` bypasses hard invariants, the RuleEngine can never return `:approved`, `permitted?/1` treats `:conditional` as a machine grant, human approval has no resume path, and the state machine authorizes itself.
3. **C4 — controls that cannot fire (20 capabilities).** The audit verifiers return PASS unconditionally, the invariant monitor scores an empty reporting set as 1.0, and the seven CAP gates do not exist. The "220/220 PASS" reports that downstream evidence cites were produced by verifiers that cannot fail.
4. **C5 — mock or stub data presented as runtime evidence (21 capabilities).** The historical 12-world/84-civilization/23,800-agent scale claim traces only to a hard-coded mock generator in the API, and the Python→Elixir observatory edge is permanently on the mock path. Booted cognition engines return constants and the tests assert those constants.
5. **C2 — duplicate module authority (19 capabilities).** 28 fully-qualified `Tiannara.*` modules exist in both Elixir projects; there are ≥4 Executive Memory stores, ≥5 constitution modules, ≥6 CIS authorities, ≥4 knowledge-graph namespaces, three event-bus families, three world models, and ≥10 competing memory stores branded "MindCache" with no implementation at all.

**The single most consequential fact for the operator:** the platform's own constitutional machinery — CAE, CAP, the seven gates, the UEP schema, ISD v2.0 and IF-001..IF-004 — has **no implementation and no specification inside this repository**. Twenty-two capabilities are therefore "specified only" against a document that is not here. Until those texts are imported as candidate specifications or formally deferred, no certification claim about the constitutional layer can be made at all, and the eight §7 design questions have no in-repo evidence to answer them.

**Recommended next step (deliverable 10):** one bounded batch — **constitutional enforcement integrity and fail-closed claim control** (7 items, ordering constrained, negative-test acceptance criteria, no architecture change).

---

## 2. Required deliverables — index

| # | Deliverable | Artifact | Notes |
|---|---|---|---|
| 1 | Complete file inventory with accounted-for exclusions | `certification/atlas/file_inventory.csv` (207,028 rows), `file_inventory_summary.json` | Every worktree path classified; vendor/generated/tooling exclusions carry reason codes; 470 tracked-but-absent files recorded |
| 2 | Full capability and subsystem register | `certification/atlas/capability_register.csv` (117 rows) + per-section registers (A/B/C/D/F/ESAP) | Every row: evidence state, reconciliation, owner, implementation, entry points, consumers, tests, evidence, competing implementations, confidence |
| 3 | Four dependency views | `deps_code.json` (29/29, 5 cycles), `deps_runtime.json` (117/110, 21 gaps), `deps_governance.json` (85/86, 18 discrepancies), `deps_build.json` (51/46, 13 discrepancies) | Every edge labelled documented / statically_inferred / dynamically_observed / independently_verified |
| 4 | Interface and schema compatibility report | `certification/atlas/interfaces_schemas.md` | ISD/IF absence, proto schemas, event subjects, OpenAPI surfaces, namespace drift |
| 5 | Duplicate ownership and unification report | `ownership_duplicates.csv` (28 concepts) + `ownership_duplicates.md` | Authoritative implementation, contract, state owner, permitted writers, consumers, competing copies, classification, recommended outcome |
| 6 | Specification-to-implementation discrepancy report | `certification/atlas/spec_discrepancy_report.md` | All 95 non-MATCHED capabilities grouped (a) spec absent code, (b) code absent spec, (c) disagreement, (d) spec not locatable |
| 7 | Verified / partially verified / disconnected / planned / unknown lists | `certification/atlas/capability_status_lists.md` | 5 verified · 43 partially verified · 47 disconnected · 5 planned · 17 missing |
| 8 | Ranked root-cause remediation backlog | `certification/atlas/remediation_backlog.md` | 7 batches + 5 operator actions, ordered with prerequisites, blast radius, acceptance criteria |
| 9 | Proposed target architecture with explicit ownership and dependency rules | `certification/atlas/target_architecture.md` | 6 ownership rules, 8 dependency rules, target topology, verification layer, migration path, explicit non-decisions |
| 10 | Baseline verification report and the single next remediation batch | `certification/atlas/baseline_verification_report.md` | 15 verified claims, 9 explicit non-verifications, exit-condition self-assessment, Batch 1 with acceptance criteria and risks |

**Supporting registers:** `baseline.md` / `baseline.json` · `architecture.md` (Pass-3 reconstruction with a 33-row basis ledger) · `findings_ledger.md` / `findings_ledger.csv` (Register 5) · `decisions_register.md` (Register 7) · `decisions_GOV.md` (10 open design questions) · `problems_G.md` (F-ARC-001..025) · `esap/esap_inventory.md` (separate repository) · `R0_SOURCE_PLAN.txt` (the governing operator instruction, preserved verbatim).

---

## 3. Method

1. **Baseline freeze** — repository identity, SHA, dirty-tree census, CI runs bound to the SHA, test commands, reusable prior evidence. No prior audit was redone: the 5F wiring audit, status corrections, execution contracts, GenServer inventories and the directory audit were consumed as versioned inputs and spot-verified.
2. **Full inventory** — a single `os.walk` of the worktree (excluding `.git` internals) cross-mapped against `git ls-files`, `git ls-files -o` and `git ls-files -o -i`, with content hashes for every non-vendor, non-generated file ≤ 20 MB, and reason codes for every skip.
3. **Seven parallel subsystem audits** (cognitive, epistemics, governance, world model, platform, architecture/ownership, ESAP) under a fixed evidence protocol, each writing a machine-readable register plus a narrative and draft findings.
4. **Normalisation** — the section findings were merged into one 130-row ledger with the operator's state machine, clustered into 14 root causes, with duplicates preserved and cross-section disagreements recorded explicitly (13 of them).
5. **Reconciliation** — every capability was classified on the spec / code / runtime axis as MATCHED, PARTIAL, CONTRADICTED or UNKNOWN, and on the evidence-state axis as one of the five operator categories. UNKNOWN is never counted as a pass.
6. **Consolidation** — deliverables 1–10 were assembled from the registers, and the report states what was *not* verified as explicitly as what was.

**Evidence discipline applied throughout:** Unknown is not PASS; documentation is not implementation; a test definition is not proof a test ran; a passing unit test is not proof of end-to-end operation; simulated success is not runtime evidence; a code change is not a closed finding; every verification is bound to an exact revision; every excluded path has a reason; history is preserved and superseded, never erased.

**The strongest honest limitation:** no application was booted and no test was executed during R0. Every finding rests on static or documentary evidence, and **zero dependency edges are dynamically observed**. This is a discovery phase, not a certification, and the report does not present it as one.

---

## 4. The five recurring failure patterns, tested against evidence

| Pattern (operator §2) | Verdict | Key evidence |
|---|---|---|
| 1. Specification-to-code drift | **Confirmed, dominant** | 38 capabilities CONTRADICTED; CAE/CAP/UEP/ISD/IF have no implementation *and* no in-repo spec; `rules.md` is read by no code while hard-coded structs act as authority; the 19/20 stubbed domains; the "CIS" name contradiction |
| 2. Duplicate authority | **Confirmed, dominant** | 28 duplicate fully-qualified modules across two Elixir projects; 4 Executive Memory stores; 5 constitution modules; 6 CIS authorities; 4 knowledge graphs; 3 event-bus families; 3 world models; ≥10 memory stores named MindCache with no implementation |
| 3. Disconnected implementations | **Confirmed, dominant** | The launcher never starts `:tiannara_runtime`; `Tiannara.ControlCenter` (owner of ~29 subsystems) is in no boot tree; the world-model/research stacks are test-only; `WorldProcess` exists only in Markdown; the Python→observatory edge is permanently on a mock path |
| 4. Unverified completion claims | **Confirmed** | Verifiers that cannot fail produced the cited "220/220 PASS"; tests assert that stub engines return constants; the scale claim traces to a mock generator; GRCC/MSCL have no generating artifact |
| 5. Repeated architectural rediscovery | **Confirmed as the mechanism** | Every critical cluster's root cause is "a phase added a subsystem without an ownership decision or a boot-tree step". This atlas exists to stop that recursion |
| 6. Local fixes without global closure | **Partially confirmed** | The 5F workstream closed its own items but the duplication, boot-tree and enforcement classes it touched remain open at platform scope |
| 7. Moving acceptance criteria | **Observed** | 8,000+ root-level phase/capability reports, `LAYER_6_5*`, `PHASE5*`, `CAPABILITY_12_*` and `PHASE16_*` families assert completion states the code contradicts; the documentation surface is now larger than the implementation surface |

---

## 5. What Phase R0 did **not** do

- It did not change, move, delete, rename, or merge any production file, module, process, or store.
- It did not run the application, execute the test suites, or start any long campaign.
- It did not decide the 8 open governance design questions — they are recorded with the evidence available and the review trigger that will settle them.
- It did not begin remediation of any finding; every finding is `OPEN`.
- It did not merge the ESAP inventory into the platform inventory; no cross-repo import, shared artefact, or shared schema was found between the two repositories.

---

## 6. Recommended operator decisions before R1

1. **OP-02** — do CAE v1.1 / CAP v1.0 / ISD v2.0 / IF-001..IF-004 / the UEP schema exist outside this checkout? Import them as candidate specifications or defer them formally. *(22 capabilities depend on the answer.)*
2. **OP-04** — are the root Elixir project and `tiannara_runtime` two co-deployed applications or one? *(28 duplicate module names make every unification ambiguous until this is answered.)*
3. **OP-03** — do the three frontends absent from git exist elsewhere? *(The WebGL Observatory capability in the program plan is currently unauditable.)*
4. **OP-01** — rotate the literal credential in the k8s production overlay. *(Independent of every code change; an active exposure.)*
5. **OP-05** — retire or re-derive GRCC 74.8 %, MSCL 88.5 % and the 12-world scale run. *(A number that cannot be reproduced is not evidence.)*

Then execute **Batch 1** as specified in `remediation_backlog.md` and `baseline_verification_report.md` §4, with the ordering constraint (F-GOV-007 before F-GOV-006) respected, and the acceptance criteria bound to the exact SHA.

---

## 7. Atlas maintenance rule (for R1 onwards)

The atlas is the deliverable, not the report. Every subsequent change updates the registers it touches — capability rows, ownership decisions, dependency edges, findings, verification results — in the same commit as the code change, and no capability is closed without Register 6 evidence bound to the exact revision. A closed finding cannot silently reopen: new contradicting evidence reopens it with the evidence, the reason, and a link to the original record, and the original decision is preserved.

**Phase R0 ends here, pending review.**
