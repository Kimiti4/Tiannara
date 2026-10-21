# Register 5 — Findings and Evidence Ledger (Phase R0 normalisation)

**Date:** 2026-10-21 · **Branch:** `local/pr4` @ `521cb7fe` · **Mode:** read-only discovery / normalisation.
**Scope:** consolidation of the completed section audits into one normalised findings ledger. No new discovery was performed; no production code, git state, or test result was touched.
**Companion machine-readable file:** `certification/atlas/findings_ledger.csv` (130 data rows, header exactly
`finding_id,title,domain,severity,confidence,status,evidence_state_basis,affected_capabilities,evidence,root_cause,remediation,acceptance_criteria,prerequisites,blast_radius,source_section,duplicate_of,notes`, fully quoted so it parses with any RFC-4180 reader).

---

## 0. What this document is

This is the R0 **normalisation** of the section audits into one ledger. It does **not** re-derive findings.
Every row below already existed in a source file; the work done here was to (a) give every finding one
canonical row, (b) map the source vocabulary onto the Register 5 vocabulary, (c) record the duplicates
explicitly rather than deleting them, and (d) cluster them by root cause.

**Field-level authority.** `findings_ledger.csv` is the authoritative record for the long free-text fields
(`evidence`, `root_cause`, `remediation`, `acceptance_criteria`, `prerequisites`, `blast_radius`).
This document carries the same 131 findings with their normalised attributes, the clustering, and the
explicit disagreements, and points at the CSV for the verbatim field text.

### 0.1 Sources consolidated

| Source file | Section | Findings contributed | Notes |
|---|---|---|---|
| `certification/atlas/capabilities_A_cognitive.md` + `.csv` | A cognitive | 22 (`F-COG-001`–`016`, `018`, `101`–`105`) | `F-COG-017` does not exist in any source; the numbering gap is recorded on `F-COG-018` |
| `certification/atlas/capabilities_B_epistemics.md` + `.csv` | B epistemics | 12 (`F-EPI-001`–`012`) | |
| `certification/atlas/capabilities_C_governance.md` + `.csv` | C governance | 23 (`F-GOV-001`–`023`) | Section C also carries its own cross-check table of sibling disagreements |
| `certification/atlas/capabilities_D_worldmodel.md` + `.csv` | D world model | 10 (`F-WRD-001`–`010`) | The Section D source states severity but **no** confidence; confidence was assigned in normalisation (see §1.3) |
| `certification/atlas/capabilities_F_platform.md` + `.csv` | F platform | 16 (`F-PLT-001`–`016`) | |
| `certification/atlas/problems_G.md` | G architectural problems | 25 (`F-ARC-001`–`025`) | |
| `certification/atlas/architecture.md` | G boot / flow gaps | 11 (`F-ARC-226`–`236`) | |
| `certification/atlas/ownership_duplicates.md` + `.csv` | Register 4 | 1 new row (`F-ARC-237`) | Register 4's duplicate clusters carry no finding ids of their own; they are cross-referenced onto the `F-ARC-*` rows they duplicate rather than duplicated as new rows |
| `certification/atlas/esap/esap_inventory.md` | E ESAP (separate repository) | 10 (`F-ESP-001`–`010`) | Kept in a clearly separated group; never merged into the platform findings |
| **Total** | | **130** | |

### 0.2 Evidence rules applied (from `R0_SOURCE_PLAN.txt:1401-1427`)

- Unknown is not PASS. · Documentation is not implementation. · A test definition is not proof that a test ran. ·
  A passing unit test is not proof of end-to-end operation. · Simulated success is not runtime evidence. ·
  A code change is not a closed finding. · Every excluded path has a reason. · No broad rewrites.

**Consequence for this ledger:** `status` is `OPEN` for all 130 rows. Nothing was fixed, and under the R0
rules a code change would not close a finding anyway — only verification of the acceptance criteria does.
Cross-references, duplicates and disagreements are recorded in `notes` and `duplicate_of`.

### 0.3 Normalisation rules

1. **Identifiers are preserved.** The original `finding_id` is kept everywhere so that every cross-reference
   in the source files (`open_findings` columns, decision register, dependency graphs) stays valid.
2. **One exception:** Register 4 (`ownership_duplicates.md` §4, the flattened-path garbage directories) is a
   finding with no identifier in its source. It is recorded as `F-ARC-237`, continuing the `architecture.md`
   draft series, and the row states in `notes` that the identifier was assigned during normalisation.
3. **Severity** uses the source severity verbatim. Section A's discovered-system bullets (`F-COG-101`–`105`)
   and Section D's list carry no explicit severity; those rows state in `notes` that severity was assigned
   in normalisation from the Section A scale.
4. **Confidence mapping** (source → ledger): `confirmed` → `confirmed`; `high` → `confirmed`; `medium` → `probable`;
   `low` → `hypothesis`; `hypothesis` → `hypothesis`; a mixed source confidence
   (`confirmed … , hypothesis …`) → `probable`, with the hypothesis component preserved in `notes`
   (this applies to `F-ARC-005`, `F-ARC-010`, `F-ARC-011`, `F-ARC-013`).
5. **`evidence_state_basis`** is the nature of the *primary* evidence:
   `statically_inferred` = derived by reading or grepping source in this checkout;
   `independently_verified` = corroborated by a second independent artefact (a prior audit, the GenServer
   inventories, the interface report, another section's independent re-read) or re-verified twice in one section;
   `documented` = the primary evidence is a repository document, not code;
   `dynamically_observed` = an executed test or CI run at the baseline SHA;
   `none` = no sufficient evidence.
   **No row is `dynamically_observed`:** no test suite and no CI job was executed during R0, so no finding in
   this ledger rests on a run performed in R0. Historical CI green at `521cb7fe` is recorded as *documented*
   evidence, not as a current dynamic observation.
6. **Duplicates are kept, not deleted.** Where two sections recorded the same root phenomenon, both rows remain,
   the later row carries `duplicate_of` pointing at the canonical row, and `notes` records why. 20 rows carry
   `duplicate_of`. The canonical row is the one with the most complete evidence or the highest severity; where
   the sections disagreed on severity, that disagreement is recorded in `notes` rather than silently resolved.
7. **`prerequisites`** is populated only where a source states an ordering constraint; otherwise the value is
   `none recorded in source`. **`blast_radius`** is derived from the source's *Affected caps* line plus the
   downstream consumers the source names; where the source names none, the field says so.

---

## 1. Summary

### 1.1 Severity × domain

| Domain | critical | high | medium | low | **Total** |
|---|---:|---:|---:|---:|---:|
| COG — cognitive | 0 | 8 | 12 | 2 | **22** |
| EPI — epistemics | 1 | 3 | 8 | 0 | **12** |
| GOV — governance | 7 | 12 | 4 | 0 | **23** |
| WRD — world model / research | 0 | 5 | 5 | 0 | **10** |
| PLT — platform / operations | 0 | 5 | 8 | 3 | **16** |
| ARC — architecture-wide | 5 | 11 | 17 | 4 | **37** |
| ESP — ESAP (separate repository) | 0 | 4 | 5 | 1 | **10** |
| **Total** | **13** | **48** | **59** | **10** | **130** |

Totals per severity: **critical 13 · high 48 · medium 59 · low 10 · 130 rows.**

Concentration: 24 of the 37 `ARC` rows are duplicates or cross-section restatements of a platform finding, so the
architecture-wide domain overstates the number of *distinct* defects. The 13 critical rows are the governance
and safety chain (7), the architecture domain (5) and one epistemics row (`F-EPI-001`, the absent UEP).

### 1.2 By source section

| Source section | Rows | By severity |
|---|---:|---|
| A_cognitive | 22 | 0 critical · 8 high · 12 medium · 2 low |
| B_epistemics | 12 | 1 critical · 3 high · 8 medium · 0 low |
| C_governance | 23 | 7 critical · 12 high · 4 medium · 0 low |
| D_worldmodel | 10 | 0 critical · 5 high · 5 medium · 0 low |
| F_platform | 16 | 0 critical · 5 high · 8 medium · 3 low |
| G_problems | 25 | 5 critical · 8 high · 9 medium · 3 low |
| G_architecture | 11 | 1 critical · 3 high · 5 medium · 2 low |
| G_ownership (Register 4) | 1 | 0 critical · 0 high · 0 medium · 1 low |
| E_esap (separate repository) | 10 | 0 critical · 4 high · 5 medium · 1 low |

### 1.3 By evidence basis and confidence

| Evidence basis | Rows | | Confidence | Rows |
|---|---:|---|---|---:|
| `statically_inferred` | 61 | | `confirmed` | 108 |
| `independently_verified` | 65 | | `probable` | 22 |
| `documented` | 4 | | `hypothesis` | 0 |
| `dynamically_observed` | 0 | | | |
| `none` | 0 | | | |

Four rows are `documented` because their primary evidence is a repository document rather than code:
`F-EPI-007` (evidence-gate wiring rests on `PRODUCTION_READINESS_SCAN.md`), `F-WRD-002` (the GRCC/MSCL figures
exist only as plan text), `F-ESP-008` (the D01–D08 fix register), `F-ARC-237` (the Register 4 artefact list).

---

## 2. Root-cause clusters

Fourteen clusters. Each finding has exactly one **primary** cluster; secondary memberships are noted in prose
and cross-referenced in the CSV `notes`. "Minimal upstream fix" is the smallest change that clears the whole
cluster, not the smallest change per finding.

### C1 — Boot tree does not include the subsystem
- **Members (16):** `F-ARC-002`, `F-ARC-010`, `F-ARC-025`, `F-ARC-226`, `F-ARC-234`, `F-ARC-235`, `F-WRD-003`, `F-WRD-004`, `F-WRD-010`, `F-COG-001`, `F-COG-103`, `F-COG-104`, `F-GOV-013`, `F-GOV-023`, `F-EPI-008`, `F-EPI-012`
- **Affected capabilities:** CAP-WRD-001/003/004/005/006/007/102/103, CAP-COG-001/102/103/104, CAP-GOV-013/114/115, CAP-EPI-005/009/014 — 24 distinct registered capability ids
- **Why they share a cause:** in every case the code exists, is often unit-tested, and is reachable only from a test setup, a `GenServer.init`, a dead `Process.whereis` path, a `send/2` to an unregistered name, or not at all. The common cause is that no supervision tree, launcher or application start path reaches the module. This is failure pattern 3 (disconnected implementations) applied uniformly.
- **Minimal upstream fix:** one topology decision (which OTP application owns which subsystem, and which launcher starts it) plus a Register 4 ownership table, then add the selected subsystems as supervised children of an existing supervisor. `F-ARC-226` is the upstream instance: until a launcher starts `:tiannara_runtime`, nothing inside that application can be reached by a product path, whatever the supervision tree says. A CI check that fails when a module has tests but no supervisor child closes the class.

### C2 — Duplicate module authority (one capability, many implementations)
- **Members (15):** `F-ARC-001`, `F-ARC-003`, `F-ARC-004`, `F-ARC-005`, `F-ARC-022`, `F-ARC-236`, `F-COG-003`, `F-COG-012`, `F-COG-015`, `F-EPI-010`, `F-EPI-011`, `F-GOV-019`, `F-GOV-020`, `F-WRD-006`, `F-PLT-014`
- **Affected capabilities:** CAP-COG-003/012/013, CAP-EPI-012/013, CAP-GOV-001/009/011/110/117, CAP-WRD-001/006/008/009, CAP-PLT-013/014 — 19 distinct registered capability ids
- **Why they share a cause:** each subsystem was extended in place by a later phase, and no owner was ever named. The result is ≥4 Executive Memory stores, ≥5 constitution modules, ≥4 knowledge-graph namespaces, ≥4 RRG meanings, three event-bus families, three world models, two principle registries, two policy evaluators. Register 4 exists precisely to stop this: merging by file similarity would be the failure mode.
- **Minimal upstream fix:** a Register 4 ownership decision per concept per deployed application (keep / merge / adapterise / retire / preserve-independent), enforced by a CI check that fails on a new duplicate `defmodule` or a new registry. `F-ARC-001` is the structural instance: 28 fully-qualified module names exist in both Elixir projects, and until the per-namespace owner is chosen every unification is guesswork.

### C3 — Authority without enforcement (governance decides, but the decision does not bind)
- **Members (11):** `F-GOV-003`, `F-GOV-004`, `F-GOV-005`, `F-GOV-006`, `F-GOV-007`, `F-GOV-010`, `F-GOV-015`, `F-GOV-017`, `F-GOV-018`, `F-GOV-021`, `F-COG-004`
- **Affected capabilities:** CAP-GOV-001/005/006/007/008/009/015/021/109/110, CAP-COG-004 — 19 distinct registered capability ids
- **Why they share a cause:** the Council computes a decision and then something downstream declines to be bound by it. `score_auth/3` decorates but never re-derives the decision (`F-GOV-007`); `permitted?/1` accepts `:conditional` (`F-GOV-005`); the RuleEngine cannot reach `:approved` (`F-GOV-006`); an approved human decision is never resumed (`F-GOV-004`); the state machine authorises itself (`F-GOV-017`); an amendment changes a version string only (`F-GOV-018`); the quorum is computed with `trunc` against its own documented `ceil` guarantee and votes carry no identity (`F-GOV-015`).
- **Minimal upstream fix:** one change in `Council.authorize/3` — make the hard-invariant check authoritative and the policy action advisory — plus one resume path that re-evaluates a parked `:requires_human` decision on approval. Ordering matters: `F-GOV-007` must be fixed *before* the dead plugin path in `F-GOV-006` is revived, because starting `PrincipleRegistry` makes `:approved` reachable and would expose the bypass.
- **Remediation in progress (2026-10-21, R1/Batch 1 step 1):** `F-GOV-007` is **VERIFIED_CLOSED** — the rule engine is now authoritative over a policy action and an approval that rests on a violated hard invariant is withdrawn into a rejection. Evidence: `certification/atlas/closure_records/R1-B1-01_F-GOV-007.md` and `certification/atlas/verification_r1.md` (denial-path suite: 4 failures on the baseline code, 6/6 after the change; CI run `39634396854` at sha `5dcc9ebd`, root suite 2,491 tests / 0 failures). The remaining members of this cluster (`F-GOV-003`, `F-GOV-004`, `F-GOV-005`, `F-GOV-006`, `F-GOV-010`, `F-GOV-015`, `F-GOV-017`, `F-GOV-018`, `F-GOV-021`, `F-COG-004`) are **OPEN** and are addressed by Batch 1 steps 2–4.

### C4 — Controls that cannot fire (verifiers, gates and inert mechanisms)
- **Members (11):** `F-ARC-007`, `F-GOV-008`, `F-GOV-009`, `F-GOV-011`, `F-GOV-012`, `F-PLT-012`, `F-EPI-002`, `F-EPI-003`, `F-EPI-007`, `F-WRD-008`, `F-COG-101`
- **Affected capabilities:** CAP-GOV-004/006/007/012/115, CAP-PLT-007/012, CAP-EPI-004/005/007, CAP-WRD-007/008, CAP-COG-101 — 20 distinct registered capability ids
- **Why they share a cause:** the check exists, returns a success-shaped result, and is never able to return failure. The two `tiannara_audit` verifiers return `match: true` unconditionally and treat a `nil` expectation as a PASS (`F-ARC-007`); the constitutional monitor scores an empty reporting set as `1.0` and has no enforced consequence (`F-GOV-008`); the audit-log Merkle root has no consumer and degraded reads fail soft (`F-GOV-012`); the trust engine feeds a constant `0.7` into a real exchange gate (`F-EPI-003`); evidence ageing configures a decay rate that nothing applies (`F-EPI-002`); the seven CAP gates do not exist (`F-GOV-009`).
- **Minimal upstream fix:** one fail-closed contract for every verifier and gate — *missing expectation, mismatch or absent input is FAIL, not PASS* — applied uniformly and then executed in a required CI job. `F-ARC-007` is the upstream instance: two verifiers that cannot fail produced the `220/220 PASS` reports that downstream evidence streams cite.

### C5 — Mock or stub data presented as runtime evidence
- **Members (10):** `F-WRD-001`, `F-WRD-007`, `F-WRD-009`, `F-COG-002`, `F-COG-006`, `F-COG-010`, `F-ARC-016`, `F-ARC-227`, `F-PLT-015`, `F-PLT-006`
- **Affected capabilities:** CAP-WRD-002/003/005/008/009/012/104/105, CAP-COG-001/006/010, CAP-PLT-002/014/015, CAP-GOV-005 — 21 distinct registered capability ids
- **Why they share a cause:** a fabricated value is produced somewhere upstream and is then indistinguishable from a measured one downstream. The 12-world / 84-civilisation / 23 800-agent figure is generated by `MOCK_WORLDS` in the API (`F-WRD-001`) and the API never reaches the runtime, so the mock path is the *only* path (`F-ARC-227`); booted cognition engines return constants and the tests assert those constants (`F-COG-002`, `F-COG-006`); notification "delivery" is a log line (`F-COG-010`); the observatory API fabricates data on outage (`F-PLT-015`); the STAGE6 lineage inputs are hard-coded (`F-WRD-007`).
- **Minimal upstream fix:** tag every generated artefact at write time with a synthetic flag and its generator identity, propagate that tag to every consumer, and remove the silent fallback branches (fail loudly). `F-ARC-227` is the upstream instance: with the mock fallback deleted, the observatory edge either returns live data or fails, and the "high-fidelity simulation" claim can no longer be produced accidentally.

### C6 — Authentication and authorisation fail open
- **Members (8):** `F-GOV-016`, `F-ARC-008`, `F-ARC-009`, `F-ARC-019`, `F-ARC-228`, `F-PLT-002`, `F-PLT-005`, `F-PLT-016`
- **Affected capabilities:** CAP-GOV-009/101, CAP-PLT-001/002/004/005/009/010/014 — 7 distinct registered capability ids
- **Why they share a cause:** the permissive case is the default, so the safe path requires configuration that nobody sets. Production auth is skipped unless `ENVIRONMENT=production` and the default is `development` (`F-PLT-002`, `F-ARC-009`); the observatory dev bypass grants administrator (`F-ARC-019`); a human identity accepts any non-empty credential (`F-GOV-016`); a raw TCP listener accepts anonymous JSON from any local client and republishes it into the event fabric (`F-ARC-228`); credentials are committed literally into a k8s overlay (`F-ARC-008`); key-shaped files sit untracked in the workspace root (`F-PLT-016`).
- **Minimal upstream fix:** invert the defaults — authentication on unless explicitly disabled, deny on mismatch, secrets only from a secret manager or the environment — and route every entry point through one authentication/authorisation library. The k8s secret rotation in `F-ARC-008` is an operations action and is independent of the code fix.

### C7 — Persistence without recovery
- **Members (7):** `F-GOV-014`, `F-PLT-009`, `F-ARC-018`, `F-COG-013`, `F-COG-014`, `F-EPI-005`, `F-EPI-006`
- **Affected capabilities:** CAP-GOV-014, CAP-PLT-008/009/010, CAP-COG-012/013, CAP-EPI-003/008/009 — 12 distinct registered capability ids
- **Why they share a cause:** state is written but cannot be restored, and where it is stored the path is not owned. Rollback flips a record and reverts nothing (`F-GOV-014`); the knowledge graph rewrites the whole file without a lock (`F-EPI-006`); the contradiction registry has no store at all (`F-EPI-005`); sixteen DETS files and a binary are committed to git (`F-PLT-009`, `F-ARC-018`); paths are hard-coded to `/tmp` or the working directory (`F-COG-014`); the only recovery tests are quarantined out of the required gate (`F-COG-013`).
- **Minimal upstream fix:** publish the store-ownership map (Register 4) and make every store path environment-configurable, then implement real restoration for one effect class and prove it with a state-and-data-integrity test. Checkpointing (`ConstitutionalPersistenceLayer`, `SafeCPL`) is availability-over-fidelity and must not be counted as rollback.

### C8 — Specification-only capability
- **Members (10):** `F-ARC-006`, `F-GOV-001`, `F-EPI-001`, `F-PLT-001`, `F-COG-005`, `F-COG-007`, `F-COG-009`, `F-COG-011`, `F-WRD-005`, `F-PLT-013`
- **Affected capabilities:** CAP-GOV-001/002/003/006/011/015, CAP-EPI-001/010, CAP-PLT-001/013, CAP-COG-005/006/007/009/011, CAP-WRD-009/010 — 22 distinct registered capability ids
- **Why they share a cause:** the capability exists as text — in the R0 plan, in `markdown/5j.md`, in a phase completion document — and the code either does not exist or was deliberately disabled. CAE v1.1, CAP v1.0, ISD v2.0, IF-001..IF-004 and the UEP schema are absent from the checkout (`F-ARC-006`, `F-GOV-001`, `F-PLT-001`, `F-EPI-001`); the Context Graph, Completion Evaluator and POMDP dialogue state have no implementation (`F-COG-005`, `F-COG-007`, `F-COG-009`); the twenty canonical domains are 19 fail-closed stubs by design (`F-WRD-005`).
- **Minimal upstream fix:** import the external specification texts (CAE v1.1, CAP v1.0, ISD v2.0, IF-001..IF-004) into the atlas as *candidate specifications* with an owner and a version, or formally defer them in Register 7 with a date and scope. Until then no certification claim may reference them, and every capability whose only specification is the plan text is recorded as `specified_not_proven` rather than as a gap to be implemented.

### C9 — Test-only wiring (the verification path never runs)
- **Members (10):** `F-ARC-015`, `F-ARC-023`, `F-ARC-233`, `F-PLT-004`, `F-PLT-011`, `F-GOV-022`, `F-COG-008`, `F-COG-018`, `F-COG-102`, `F-COG-105`
- **Affected capabilities:** CAP-COG-008/003/102/105, CAP-GOV-005/101, CAP-PLT-004/007/009/010/014, CAP-ARC and audit tooling — 11 distinct registered capability ids
- **Why they share a cause:** the code and its tests exist, but the job that would execute them does not run on the working branch, or the code has no production caller at all. The Python, Docker and release workflows trigger only on `main`/`master` (`F-PLT-004`, `F-ARC-015`); the observatory umbrella's own CI file is untracked (`F-ARC-233`); the strongest fail-closed contract in the repository has zero production callers (`F-GOV-022`); the Ontological Bridge and the root CIS have no production caller or no dedicated test (`F-COG-008`, `F-COG-018`).
- **Minimal upstream fix:** widen the branch filters or fold the Python and audit jobs into the branch-spanning workflow, and route at least one production path through each contract that is currently only exercised by a test. `F-ARC-015` is the upstream instance: while the workflows exclude the branch under remediation, no other verification improvement can be observed.

### C10 — Build, packaging and deployment gap
- **Members (8):** `F-ARC-014`, `F-ARC-229`, `F-ARC-230`, `F-ARC-231`, `F-ARC-232`, `F-COG-016`, `F-PLT-008`, `F-PLT-010`
- **Affected capabilities:** CAP-PLT-003/008/010, CAP-COG-002, CAP-PLT-004/005 — 6 distinct registered capability ids
- **Why they share a cause:** no deployable unit is ever produced, and the artefacts that do exist were written against a different runtime configuration. `config/prod.exs` is missing while `config/config.exs:57` imports it (`F-ARC-014`, `F-COG-016`, `F-PLT-008`); no workflow invokes `mix release` and the runtime project has no `releases/0` (`F-ARC-229`); the API health check probes a route that does not exist (`F-ARC-230`); the SaaS image copies `/app/out` that `next build` never produces (`F-ARC-231`, `F-PLT-010`); the launcher's "required services" are consumed by no Elixir process (`F-ARC-232`).
- **Minimal upstream fix:** one release path for both Elixir applications — a fail-closed `config/prod.exs`, `releases/0` in both projects, a CI job that produces the tarball, and a container build whose health check and static-export assumptions match the actual application configuration.

### C11 — Unreproducible claims and documentation overclaim
- **Members (4):** `F-WRD-002`, `F-ARC-017`, `F-EPI-004`, `F-GOV-002`
- **Affected capabilities:** CAP-WRD-003/005, CAP-GOV-001/002/110, CAP-EPI-002/010 — 7 distinct registered capability ids
- **Why they share a cause:** a document is treated as evidence. GRCC 74.8 % and MSCL 88.5 % have no generating code, dataset or definition anywhere and the observed MSCL metric is 0.0 (`F-WRD-002`); phase completion documents claim production-ready and integrated states that the code contradicts (`F-ARC-017`); the GenServer inventories and the boot tree disagree about two start paths (`F-EPI-004`); `rules.md` is prose that no code reads, while the real authority is a hard-coded struct (`F-GOV-002`).
- **Minimal upstream fix:** bind every certification claim to Register 6 evidence (commit SHA, artefact hash, command, result) as the plan already requires at `R0_SOURCE_PLAN.txt:641-653`, and treat achievement-markdown and stale inventories as non-evidence. Where a metric cannot be reproduced, retire the figure rather than restate it.

### C12 — Interface, payload and event-contract vacuum
- **Members (4):** `F-ARC-020`, `F-ARC-021`, `F-PLT-007`, `F-EPI-009`
- **Affected capabilities:** CAP-PLT-002/007/011, CAP-EPI-011/012, CAP-PLT-001 — 5 distinct registered capability ids
- **Why they share a cause:** the wire format is defined by whoever happened to write the caller. There is no event registry, no payload schema, no canonical replay-package format, and the "protocol authority" is split between an unwired unkeyed crypto helper, a raw TCP listener and the JSON ad-hoc subject list (`F-ARC-020`, `F-PLT-007`, `F-EPI-009`). Subject and namespace drift (`tiarnara.*` versus `tiannara.*`) is the visible symptom (`F-ARC-021`).
- **Minimal upstream fix:** publish one event registry (name, version, payload schema, producers, consumers) and one canonical replay-package format, classify every existing transport as registered, bridged or legacy, and give the schemas an owner and a compatibility test.

### C13 — Ownership, namespace and version-control void
- **Members (6):** `F-PLT-003`, `F-ARC-024`, `F-ARC-237`, `F-ARC-011`, `F-ARC-012`, `F-ARC-013`
- **Affected capabilities:** CAP-PLT-005/006/010, CAP-GUI and dashboard surfaces — 2 distinct registered capability ids (the `F-ARC-*` rows use capability *names* because Register 2 ids do not yet exist)
- **Why they share a cause:** artefacts exist on disk, in a namespace, or in a build artefact that no inventory, ownership decision or compilation reaches. Three of five frontends are absent from git (`F-ARC-024`, `F-PLT-003`); the runtime compiles 28 duplicate module names and warns about 11 redefinitions (`F-ARC-011`); the Python packages form an import cycle (`F-ARC-012`); the root application probes runtime process names that no launcher provides (`F-ARC-013`); a path-join bug wrote absolute paths as directory names at the repository root (`F-ARC-237`).
- **Minimal upstream fix:** an ownership register entry per directory, namespace and package (in-repo, submodule with a pinned SHA, or external with a recorded boundary and interface pin), plus a CI check that fails on a new cross-project `defmodule` collision, a new import cycle, or a new untracked directory artefact.

### C14 — ESAP compiler pipeline gaps (separate repository, never merged into the platform ledger)
- **Members (10):** `F-ESP-001` … `F-ESP-010`
- **Affected capabilities:** CAP-ESP-001 … CAP-ESP-016 — 14 distinct capability ids
- **Why they share a cause:** in `Kimiti4/autonomous-API-Gen` the fail-closed *machinery* was built first and the *wiring* was deferred: typed ISR semantics are not consumed by the certified emitters (`F-ESP-001`); the RBAC/ABAC engine is not wired into generated enforcement points (`F-ESP-002`); retries, dead-letter and ordering are not generated (`F-ESP-003`); no browser-level frontend verification runs in CI (`F-ESP-004`); the remediation register is stale against the merged state (`F-ESP-005`); deployment has no runtime executor (`F-ESP-006`); selection scores are analyst-assigned (`F-ESP-007`); the D01–D08 fail-open defects are genuinely closed and must be protected (`F-ESP-008`); the evidence ledger records pass verdicts with empty test inventories (`F-ESP-009`); three ISR representations and three emitter stacks coexist without an authority (`F-ESP-010`).
- **Minimal upstream fix:** wire the fail-closed machinery into the certified emitters — one ISR authority, one emitter authority, and the policy engine plus the async semantics emitted from the ISR — and require candidate-bound test inventories before a pass verdict can be written to the evidence ledger. **No import or shared artefact links the ESAP repository to the Tiannara AI platform: a cross-repo import search returned zero references to `MindCache`, `Tiannara-MindCache`, `UEP`, `ISD v2.0` or the platform protobuf schemas.**

### 2.1 Top five root causes by affected capability count

Ranked strictly by the number of distinct registered capability ids the cluster touches.

| Rank | Cluster | Findings | Distinct registered capability ids affected | Severity profile |
|---:|---|---:|---:|---|
| 1 | C1 — Boot tree does not include the subsystem | 16 | 24 | 2 critical · 7 high · 6 medium · 1 low |
| 2 | C8 — Specification-only capability | 10 | 22 | 1 critical · 5 high · 3 medium · 1 low |
| 3 | C5 — Mock or stub data presented as runtime evidence | 10 | 21 | 5 high · 5 medium |
| 4 | C4 — Controls that cannot fire | 11 | 20 | 2 critical · 5 high · 4 medium |
| 5 | C2 — Duplicate module authority | 15 | 19 | 1 critical · 5 high · 7 medium · 2 low |

Two caveats on this ranking, because it is a breadth metric and not a risk metric:

- **C3 — Authority without enforcement ties with C2 at 19 capability ids and would rank sixth on count alone**,
  but it carries the highest severity profile of any cluster (4 critical · 5 high · 2 medium) and is the only
  cluster whose members are safety-relevant. By severity weight C3 is first.
- The five clusters above carry 62 of the 130 findings; adding C3 brings the total to 73. C6 (8 findings, 7
  capability ids), C7 (7 findings, 12 ids) and C9 (10 findings, 11 ids) are narrower but are the clusters with
  the cheapest upstream fixes.
- The `F-ARC-*` rows record capability *names* rather than ids (Register 2 ids do not exist yet), so their
  contribution to the capability counts is under-represented. C1, C2 and C13 would gain ids once Register 2
  lands.

---

## 3. Findings lacking evidence

**Rows with `confidence = hypothesis`: none.** No source finding was recorded with a purely hypothetical
confidence. Four findings carried a *mixed* source confidence (`confirmed` for one aspect, `hypothesis` for
another) and were normalised to `probable`: `F-ARC-005` (duplication confirmed; no canonical graph chosen),
`F-ARC-010` (existence confirmed; individual dead-ness is a hypothesis), `F-ARC-011` (1 of 11 redefinition
warnings proven), `F-ARC-013` (the references are confirmed; the co-VM intent is a hypothesis).

The findings below cannot be settled by any evidence available inside this checkout. For each, the evidence
that would settle it is named.

| Finding | What is unproven | Evidence that would settle it |
|---|---|---|
| `F-EPI-007` | That the certification gate actually runs and produces verdicts; the claim rests on `PRODUCTION_READINESS_SCAN.md` alone | A dated CI run or test log invoking `CertificationGate.evaluate/1` and showing verdicts |
| `F-WRD-002` | GRCC 74.8 % and MSCL 88.5 % — no definition, dataset, producing script or result artefact exists | A metric definition, a dataset and a reproducible calculation, or a recorded decision retiring the figures |
| `F-EPI-004` (UnknownRegistry half) | Whether `TiannaraOS.UnknownRegistry` is started at all; six modules call it | The actual start site in `control_center.ex` / `service_registry.ex`, or a `Process.whereis` assertion after application start |
| `F-ARC-010` | Whether each of the 35 zero-evidence modules is genuinely dead | A per-module disposition record plus a consumer grep under a known configuration |
| `F-ARC-011` | The cause of 10 of the 11 redefinition warnings (stale `_build` beam versus a second source) | One clean `_build` recompile of `tiannara_runtime` producing the warning list |
| `F-ARC-013` | The intended deployment topology (separate processes versus one VM) | A topology decision record, plus a configurable probe list in the census tools |
| `F-ARC-005` | Which of the ≥20 knowledge-graph modules is canonical | A Register 2 capability-to-implementation map across the three languages |
| `F-ARC-227` / `F-WRD-001` | Whether any real scale measurement exists behind the 12-world claim | A reproducible measurement whose generator, dataset and re-runnable script are identified |
| `F-ARC-022` | Which registry is consulted for each concept, and whether the orphan `:cs` domain has a consumer | A consumer grep per registry under a known configuration, plus the AC-001 domain decision |
| `F-COG-008` | Whether the Ontological Bridge has a real production consumer outside the repository | A production-path call trace, or a classification of the module as a standalone tool |
| `F-ESP-009` | Whether the ESAP evidence ledger's `pass` verdicts ever corresponded to real test runs | The candidate-bound test inventories and scan results behind each ledger entry |
| `F-ESP-005` | Whether the ESAP remediation register's dispositions match the merged history | Re-derivation of every register entry against merged commits at HEAD |
| `F-PLT-010` / `F-ARC-231` | Whether the SaaS image build actually fails (statically inferred, not executed) | One `docker build -f docker/saas/Dockerfile .` result |
| `F-ARC-236` | Whether co-VM deployment of the two Elixir applications is intended | A topology decision record |
| `F-ARC-237` | Whether the flattened-path directories are stale scanner artefacts or live | Confirmation that no scanner or script writes them |

---

## 4. Explicit disagreements between sources (findings about the audit)

Recorded rather than resolved, per the instruction that "where the sources disagree, record the disagreement
explicitly".

1. **Severity disagreement — the missing `config/prod.exs`.** `F-ARC-014` rates it **high**; `F-PLT-008` and
   `F-COG-016` rate the same missing file **medium**. Canonical row `F-ARC-014`.
2. **Severity disagreement — the `tiannara_audit` verifiers.** `F-ARC-007` and `F-GOV-011` rate them
   **critical**; `F-PLT-012` rates the same defect **medium** (claim control). Canonical row `F-ARC-007`.
3. **Severity disagreement — the kill switch.** `F-ARC-002` rates it **high**; `F-GOV-013` and `F-ARC-234`
   rate it **critical**. Canonical row `F-GOV-013`.
4. **Severity disagreement — the k8s production overlay.** `F-ARC-008` rates it **critical**;
   `F-PLT-005` rates the same overlay **high**. Canonical row `F-ARC-008`.
5. **Scope disagreement — missing negative tests.** `F-ARC-023` asserts missing negative tests on the audit
   critical paths; Section C records **AGREE but NARROW**: the root application's authorisation chain has
   substantial real denial-path coverage (`CAP-GOV-104`, `d127_authorization_attack_test.exs`), so the gap is
   tool-specific (the `tiannara_audit` and `tiannara_pros` surfaces) rather than systemic.
6. **Reconciliation disagreement — runtime supervision.** `CAP-PLT-003` is classified **MATCHED** and Section F
   describes boot wiring as dynamically observed in CI, while `F-ARC-226` shows that `:tiannara_runtime` is never
   started by any launcher, compose file, Dockerfile, k8s manifest or release. The two are compatible only if a CI
   test run is treated as a deployment path, which it is not.
7. **Reconciliation disagreement — the observatory edge.** Section D (`CAP-WRD-104`) records the API→runtime
   observatory path as an unknown fallback; `F-ARC-227` resolves it: the target path exists in no Elixir
   application, so the mock fallback is *always* taken. Section D's unknown is closed by Section G.
8. **Inventory disagreement — process start paths.** `GENSERVER_RECONCILIATION.csv:118` and
   `GENSERVER_OWNERSHIP_INVENTORY.csv:211` say `UnknownRegistry` and `ExecutiveBlackboard` have no start path;
   `lib/tiannara/application.ex:230` boots the latter. Recorded as `F-EPI-004`.
9. **Baseline disagreement — CI branch filter.** `baseline.md:48` states `ci-cd.yml` runs on `local/pr5` and
   `local/pr6`; `.github/workflows/ci-cd.yml:5,8` states `[main, master]`. Recorded as `F-PLT-004`.
10. **Baseline disagreement — the orphan count.** `baseline.md:68,81` and `capabilities_F_platform.md:33` cite
    "23 orphaned modules" against the wiring audit; Register 4 records that no enumeration of exactly 23 was
    found in the audit text. Recorded in `F-ARC-010` notes.
11. **Stale prior-CSV claims corrected by Section C.** A prior Section C CSV claimed `rules.md` is 473 lines
    (it is 225) and claimed the audit log has no tamper-detection test (`audit_log_recovery_test.exs:269` proves
    one). Recorded in `F-GOV-002` and in the Section C narrative; the stale CSV must not be cited.
12. **Registry of ownership vs capability register — the executive-state split.** Register 4 records the
    executive-state canonical owner as **UNKNOWN** while `F-COG-012` records four Executive Memory
    implementations with no authority rule. Compatible, and both are carried.
13. **ESAP register vs merged history.** The ESAP remediation register still states PR 139 is unmerged and
    PR 137 is a draft, while HEAD `062cbeb` merges both. Recorded as `F-ESP-005`.

---

## 5. Explicit unknowns carried by this ledger

- No test suite and no CI job was executed during R0. **Zero findings are `dynamically_observed`.**
- Whether the CAE v1.1 and CAP v1.0 specification texts exist outside this checkout is unknown; if they were
  never written, `D-GOV-001`–`D-GOV-003` have nothing to reconcile against and must be authored.
- Whether ISD v2.0 and IF-001..IF-004 exist in the ESAP repository or another repository is unknown.
- Whether either Elixir application boots end-to-end in a clean checkout of `521cb7fe` is unknown.
- The state of the 31 modified tracked `.dets` files and the real content of the `data/cpl/**` checkpoints are
  unknown; the files were not read.
- The current pass status of the `lineage-regression` CI job is unknown.
- Whether any promotion has passed an independent-verification gate on real, non-seeded discovery input is
  unknown.
- Whether the `tiannara_observatory` UI is served by anything in production is unknown.
- Whether the four orphan KEDA ScaledObjects ever bound to live workloads outside this checkout is unknown.
- The actual run status (green/red) of the 32 ESAP workflows was not fetched; workflow definitions only.
- Whether any `pem*.txt` file contains a real private key is unknown; only the header shape was read.

---

## 6. Complete findings index (all 130 rows)

Every row below is present in `findings_ledger.csv` with its full `evidence`, `root_cause`, `remediation`, `acceptance_criteria`, `prerequisites` and `blast_radius` text. `Affected capabilities` is condensed here; the CSV carries it verbatim.

### 6.1 Section A — Cognitive architecture (22 findings)

| ID | Finding | Sev | Conf | Basis | Affected capabilities | Root cause | duplicate_of |

|---|---|---|---|---|---|---|---|
| `F-COG-001` | No canonical cognitive orchestrator: three parallel stacks coexist with no control flow between them | high | probable | statically_inferred | CAP-COG-001; CAP-COG-005; CAP-COG-006 | Repeated architectural rediscovery (failure pattern 5): each phase added a new stack without an ownership decision | - |
| `F-COG-002` | Booted cognition stubs return constants and the tests assert those constants | high | confirmed | statically_inferred | CAP-COG-001; CAP-COG-005; CAP-COG-006 | Unverified completion claims (failure pattern 4): tests written against scaffolds, converting stubs into verified evidence | - |
| `F-COG-003` | CIS has duplicate authorities in at least six locations and the specification name contradicts the implementation | high | confirmed | independently_verified | CAP-COG-003 | Duplicate authority (failure pattern 2) plus documentation-to-code drift | - |
| `F-COG-004` | AEO runtime adapter is configured only in tests, so submit_to_runtime always fails in production | medium | confirmed | statically_inferred | CAP-COG-004 | Adapter boundary left unwired after the hardening pass | - |
| `F-COG-005` | Context Graph does not exist; at least four context implementations and two working memories share no store | high | confirmed | statically_inferred | CAP-COG-005 | Spec-to-code drift (failure pattern 1) caused by premature parallel modules | - |
| `F-COG-006` | Anticipation engine is missing; the booted PredictiveEngine returns one fixed forecast for every input | high | confirmed | independently_verified | CAP-COG-006 | Same root cause as F-COG-002 and F-COG-005: stub-as-implementation | - |
| `F-COG-007` | Completion Evaluator is missing; only research early-stopping exists | medium | confirmed | statically_inferred | CAP-COG-007 | No acceptance-criteria contract in executive or workflow result types | - |
| `F-COG-008` | Ontological Bridge is implemented but has zero production callers | medium | probable | statically_inferred | CAP-COG-008 | Disconnected implementation (failure pattern 3) | - |
| `F-COG-009` | POMDP and belief-state tracking are unsupported; only turn-level dialogue state exists and it is in-memory | medium | confirmed | independently_verified | CAP-COG-009 | Specification written from markdown/5j.md design without an implementation plan | - |
| `F-COG-010` | ProactiveNotifier delivery is log and telemetry only, state is in-memory, and priority bypass trusts the caller | medium | confirmed | statically_inferred | CAP-COG-010 | Decision-versus-delivery conflation | - |
| `F-COG-011` | Lexical Tensegrity covers 7 of the 20 canonical domains and an unused competing engine exists | medium | confirmed | independently_verified | CAP-COG-011 | Feature-hashing shortcut adopted in place of a domain model | - |
| `F-COG-012` | Four Executive Memory implementations exist, three are booted, and no authority rule is recorded | high | confirmed | independently_verified | CAP-COG-012 | Duplicate authority (failure pattern 2): more than one module claims the canonical store | - |
| `F-COG-013` | Omega executive-memory recovery behaviour is only exercised by quarantined tests | medium | confirmed | independently_verified | CAP-COG-012; CAP-COG-106 | Test isolation design gap in the required-gate policy | - |
| `F-COG-014` | Executive memory persistence paths are non-portable and environment-dependent | low | confirmed | independently_verified | CAP-COG-012; CAP-COG-013 | No storage-path configuration boundary | - |
| `F-COG-015` | MindCache has no implementation and no owner; at least ten competing memory stores exist repository-wide | high | confirmed | independently_verified | CAP-COG-013 | Branding reused as a capability name; memory accreted per phase without an ownership decision | - |
| `F-COG-016` | Runtime production configuration is missing, so MIX_ENV=prod cannot compile or boot | medium | confirmed | independently_verified | CAP-COG-002 | Configuration import written before the prod file | `F-ARC-014` |
| `F-COG-018` | The booted root CIS has effectively no dedicated unit tests | low | probable | statically_inferred | CAP-COG-003 | Test concentration on the runtime safety chain rather than the root implementation | - |
| `F-COG-101` | OPC production-ready claim is disproven and the execution path is quarantined fail-closed | high | confirmed | statically_inferred | CAP-COG-101 | Claim/documentation not reconciled with the implementation | - |
| `F-COG-102` | OED modules start only in test setup and the claimed supervisor does not exist | medium | probable | statically_inferred | CAP-COG-102 | Completion claim not reconciled with the implementation | - |
| `F-COG-103` | RODL claimed supervisor and GradientSolver are absent and the only match is a different language | medium | confirmed | statically_inferred | CAP-COG-103 | Claimed completion of a capability that was never implemented | - |
| `F-COG-104` | The EPC control-law stack is completely orphaned | medium | probable | statically_inferred | CAP-COG-104 | Module written without a consumer, a supervisor or a test | - |
| `F-COG-105` | CRA GenServers run only in tests, the claimed supervisor is absent and the external scope is entirely missing | medium | confirmed | statically_inferred | CAP-COG-105 | Test-only implementation presented as a capability | - |

### 6.2 Section B — Knowledge, epistemics and evidence (12 findings)

| ID | Finding | Sev | Conf | Basis | Affected capabilities | Root cause | duplicate_of |

|---|---|---|---|---|---|---|---|
| `F-EPI-001` | The Universal Epistemic Payload does not exist anywhere in the codebase | critical | confirmed | independently_verified | CAP-EPI-001; CAP-EPI-003; CAP-EPI-004; CAP-EPI-006; CAP-EPI-008; CAP-EPI-009; CAP-EPI-010; CAP-EPI-012 | HYPOTHESIS: the canonical list was authored against an external architecture document and the schema was never instantiated in this checkout (or ... | - |
| `F-EPI-002` | Evidence Ageing is inert: a decay rate is configured but never applied | high | confirmed | independently_verified | CAP-EPI-007; CAP-EPI-004; CAP-EPI-006 | Scaffold written with intended configuration, wiring never completed, module later orphaned | - |
| `F-EPI-003` | Detector trust scoring feeds a hard-coded mock ground truth | high | confirmed | statically_inferred | CAP-EPI-006; CAP-EPI-005 | The Sentinel accuracy metric was never implemented and the placeholder survived integration | - |
| `F-EPI-004` | Process-start truth conflicts: UnknownRegistry has consumers but no recorded start path, and the Blackboard inventory row is stale | high | probable | independently_verified | CAP-EPI-010; CAP-EPI-002 | The inventory generator did not traverse the ECR hand-written child maps; UnknownRegistry may be started only by control-centre paths not captured as ... | - |
| `F-EPI-005` | Contradiction registry is non-durable and unwired; the Bayesian prioritizer is unwired and untested | medium | probable | statically_inferred | CAP-EPI-008; CAP-EPI-009 | Both implemented as libraries with lifecycle and math but never integrated into a persisted registry or a decision loop | - |
| `F-EPI-006` | Knowledge Graph uses non-atomic full-file persistence with linear-scan queries and a single writer | medium | probable | statically_inferred | CAP-EPI-003 | Prototype storage chosen before query requirements; the provenance and path audit focus was never built | - |
| `F-EPI-007` | The evidence-gate wiring claim rests on prior-audit documentation only | medium | probable | documented | CAP-EPI-004 | No adverse cause; the documentation is credible but stale-prone under the evidence rules | - |
| `F-EPI-008` | Calibration exists but no system-wide drift or feedback loop is evidenced | medium | probable | statically_inferred | CAP-EPI-005; CAP-EPI-009 | Calibration was built as a reporting tool inside the forecasting silo; cross-system feedback was designed but not integrated | - |
| `F-EPI-009` | Replay is spec-level only, at least five competing stacks exist and seeds are handled in two unconnected places | medium | probable | statically_inferred | CAP-EPI-011; CAP-EPI-012 | Replay evolved per subsystem (governance, sentinel, forecasting, multi-world, observatory) without a canonical package format | - |
| `F-EPI-010` | Provenance is fragmented across at least four stores, one of which has zero references | medium | probable | independently_verified | CAP-EPI-012; CAP-EPI-002; CAP-EPI-011 | Layered accretion across phase-era stores plus the forward_provenance programme; consolidation deferred as destructive | - |
| `F-EPI-011` | Ontology management is fragmented and versioning, migration and rollback are only partially evidenced | medium | probable | statically_inferred | CAP-EPI-013 | Ontologies grew per domain (world, mathematics, civilization) with no registry authority | - |
| `F-EPI-012` | The active learning loop is incomplete: the planned experiment_selection module is absent and selection-to-validation is unproven | medium | probable | statically_inferred | CAP-EPI-014; CAP-EPI-005; CAP-EPI-009 | The planner was built (with strong fail-closed behaviour and deterministic seeds) before the selection and execution stages | - |

### 6.3 Section C — Constitutional governance and safety (23 findings)

| ID | Finding | Sev | Conf | Basis | Affected capabilities | Root cause | duplicate_of |

|---|---|---|---|---|---|---|---|
| `F-GOV-001` | CAE and CAP have zero implementation and zero in-repo specification | high | confirmed | independently_verified | CAP-GOV-002; CAP-GOV-003; CAP-GOV-006; CAP-GOV-011; CAP-GOV-015 | The CAE v1.1 and CAP v1.0 design documents were produced outside this repository and never landed here; the plan treats them as inputs so their ... | `F-ARC-006` |
| `F-GOV-002` | rules.md is never read by any code and is not the runtime policy authority | high | confirmed | statically_inferred | CAP-GOV-001; CAP-GOV-109; CAP-GOV-110 | The runtime constitution was implemented as hard-coded Elixir structs and a policy registry; rules.md remained a design document and the two were ... | - |
| `F-GOV-003` | Two PolicyRegistry policies are permanently dead because the matcher treats :any as a literal decision type | critical | confirmed | statically_inferred | CAP-GOV-005; CAP-GOV-009; CAP-GOV-110 | The :any wildcard was intended in applies_to but the matcher implements membership, not a wildcard | - |
| `F-GOV-004` | Human approval is a one-way record with no resume path | critical | confirmed | independently_verified | CAP-GOV-009; CAP-GOV-008; CAP-GOV-109 | The approval record was implemented; the approval effect (re-running the gated decision with the grant) was never implemented | - |
| `F-GOV-005` | Authorization.permitted?/1 accepts :conditional, so a conditional decision can be minted into a machine grant | high | confirmed | statically_inferred | CAP-GOV-005; CAP-GOV-010; CAP-GOV-101 | permitted? was written as a not-explicitly-rejected predicate while the real invariant is conditions satisfied | - |
| `F-GOV-006` | The Council RuleEngine can never return :approved for any real caller decision type | critical | confirmed | independently_verified | CAP-GOV-005; CAP-GOV-008; CAP-GOV-010; CAP-GOV-113; CAP-GOV-114 | The 0.8 approval threshold was calibrated against a plugin-based scorer that could emit :strengthened; the built-in fallback scorer cannot, and the ... | - |
| `F-GOV-007` | A policy :approve bypasses the RuleEngine hard invariants | critical | confirmed | statically_inferred | CAP-GOV-005; CAP-GOV-009; CAP-GOV-013; CAP-GOV-110 | score_auth was designed to decorate an authorization, not to vet it; the policy branch pre-commits the decision before the vet runs | - |
| `F-GOV-008` | The constitutional invariant monitor has no enforced consequence and fails open on missing data | high | confirmed | statically_inferred | CAP-GOV-004; CAP-GOV-008; CAP-GOV-108 | The monitor was built as a telemetry aggregator; the enforced-consequence half of the audit focus was never implemented, and absence of data was ... | - |
| `F-GOV-009` | The seven CAP gates do not exist and three unrelated gate families compete for the name | high | confirmed | statically_inferred | CAP-GOV-006; CAP-GOV-005; CAP-GOV-106; CAP-GOV-108 | Gate-like machinery was built for three unrelated purposes and never mapped onto the CAP contract | - |
| `F-GOV-010` | No certificate carries a cryptographic signature, a validity period or a subject-version binding | high | confirmed | statically_inferred | CAP-GOV-007; CAP-GOV-105; CAP-GOV-115 | Signature was implemented as a content hash and used as a label, so verify_certificate/1 returns :valid for anything self-consistent | - |
| `F-GOV-011` | tiannara_audit verifiers cannot fail and the tool is untested and un-CI'd | critical | confirmed | independently_verified | CAP-GOV-007; CAP-GOV-115; every Section C capability that might cite an independent audit report | The verifiers were written to produce a report rather than to test a claim; the comparison step was never implemented | `F-ARC-007` |
| `F-GOV-012` | The audit-log Merkle root has no consumer and degraded-mode reads fail soft | medium | confirmed | statically_inferred | CAP-GOV-012; CAP-GOV-015 | The Merkle root was built for future cross-node verification that was never built; degraded-mode readers were written to be tolerant because the ... | - |
| `F-GOV-013` | The kill switch is not running, the consumer API is dead and the freeze path raises | critical | confirmed | independently_verified | CAP-GOV-013; CAP-GOV-007; CAP-GOV-015 | The 5F.3.5 kill-switch consolidation produced a unified module but the wiring and the consumer migration were deferred and the duplicate set was ... | - |
| `F-GOV-014` | No rollback restores state and the CBAC gate and authority verifier are dead code | critical | confirmed | independently_verified | CAP-GOV-014; CAP-GOV-010; CAP-GOV-111 | Two independent gaps: the flip-a-record shape was mistaken for restoration, and the institutional access-control model was built to a specification ... | - |
| `F-GOV-015` | The federation quorum contradicts its own documented guarantee and votes are replayable | high | confirmed | independently_verified | CAP-GOV-015; CAP-GOV-012 | The quorum constant was transcribed as a fraction and applied with trunc; the Byzantine voter model was documented in prose and never implemented | - |
| `F-GOV-016` | Authenticated human identity accepts any non-empty credential and is forgeable | high | confirmed | statically_inferred | CAP-GOV-009; CAP-GOV-101 | The struct was treated as a capability rather than as a claim requiring verification against a credential store that does not exist | - |
| `F-GOV-017` | The CEL kernel state machine authorises itself and its privileged operations are unreachable | high | confirmed | statically_inferred | CAP-GOV-008; CAP-GOV-009; CAP-GOV-005 | The transition table and the authorisation gate were designed as two independent mechanisms and never joined; the join depends on the human-approval ... | - |
| `F-GOV-018` | An approved constitutional amendment changes nothing and never reaches the effective constitution | high | confirmed | statically_inferred | CAP-GOV-109; CAP-GOV-001; CAP-GOV-009 | The amendment state machine was implemented for its lifecycle; the effect of an amendment (applying changes and publishing the new constitution) was ... | - |
| `F-GOV-019` | Two unreconciled policy evaluators operate in the same application | medium | confirmed | statically_inferred | CAP-GOV-011; CAP-GOV-110; CAP-GOV-117 | CEL was built as a parallel executive stack with its own policy layer and was never reconciled with the Council | - |
| `F-GOV-020` | Constitutional authority is scattered across at least five constitution modules | high | confirmed | independently_verified | CAP-GOV-001; CAP-GOV-004; CAP-GOV-011; CAP-GOV-109 | Repeated constitutional work in separate subsystems with no canonical declaration | `F-ARC-003` |
| `F-GOV-021` | The five-minute audit timeout requirement has no implementation | medium | confirmed | statically_inferred | CAP-GOV-006; CAP-GOV-106; CAP-GOV-005 | The requirement is a design-input constraint with no owning subsystem | - |
| `F-GOV-022` | The strongest fail-closed contract in the repository has zero production callers | medium | confirmed | independently_verified | CAP-GOV-005; CAP-GOV-101; CAP-GOV-010 | The sink was built and proved in isolation as a template, then the production effect paths were wired to a different human-grant flavoured clone ... | - |
| `F-GOV-023` | The dynamic principle plugin path is dead and two principle registries have disjoint consumers | high | confirmed | independently_verified | CAP-GOV-006; CAP-GOV-011; CAP-GOV-113; CAP-GOV-114 | The registry was built as an extension point but never added to the supervision tree, so the RuleEngine silently uses its fallback scorer | - |

### 6.4 Section D — World model, simulation and research (10 findings)

| ID | Finding | Sev | Conf | Basis | Affected capabilities | Root cause | duplicate_of |

|---|---|---|---|---|---|---|---|
| `F-WRD-001` | The historical scale claim (12 worlds, 84 civilizations, 23800 agents) traces only to a mock generator | high | confirmed | independently_verified | CAP-WRD-002; CAP-WRD-003; CAP-WRD-004; CAP-WRD-104 | Historical claim is unreproducible: it is partially traceable to a mock generator and is not a runtime result | - |
| `F-WRD-002` | GRCC 74.8 percent and MSCL 88.5 percent are untraceable to any code, dataset or definition | high | confirmed | documented | CAP-WRD-003; CAP-WRD-005 | The two figures were reported externally with no generating artifact in this repository; they cannot be reproduced or refuted from in-repo evidence | - |
| `F-WRD-003` | The tiannara_runtime research and simulation stacks are absent from every boot tree | high | confirmed | independently_verified | CAP-WRD-001; CAP-WRD-003; CAP-WRD-004; CAP-WRD-005; CAP-WRD-006; CAP-WRD-007; CAP-WRD-102; CAP-WRD-103 | Systems built per phase without a boot-tree integration step; the dependency is only expressed through test setup | - |
| `F-WRD-004` | TiannaraRuntime.MultiWorld.WorldProcess does not exist while the supervisor supervises it | high | confirmed | independently_verified | CAP-WRD-004 | The multi-world control plane was consolidated in documents without the source module ever being written | `F-GOV-013` |
| `F-WRD-005` | Cross-domain capability is specified, registered and constitutionally disabled | high | confirmed | statically_inferred | CAP-WRD-009; CAP-WRD-010 | The domain registry was frozen and the modules quarantined deliberately, so the registry claims a capability the code forbids | - |
| `F-WRD-006` | No single authoritative implementation exists anywhere in Section D | medium | confirmed | statically_inferred | CAP-WRD-001; CAP-WRD-006; CAP-WRD-008; CAP-WRD-009 | Parallel per-phase implementations with no ownership decision; the one-capability-one-implementation closure rule is violated across the section | - |
| `F-WRD-007` | Simulation-over-simulation laundering risk: fabricated inputs feed artefacts that circulate as results | medium | confirmed | independently_verified | CAP-WRD-002; CAP-WRD-003; CAP-WRD-005; CAP-WRD-012; CAP-WRD-105; CAP-WRD-106 | Pipeline stages were written with fabricated inputs to produce plausible outputs, and self-labelled disclaimers are not enforced by any machine check | - |
| `F-WRD-008` | Discovery and theory novelty is falsified at function level and archived laws show the promotion gate never fired | medium | confirmed | independently_verified | CAP-WRD-007; CAP-WRD-008; CAP-WRD-107 | No independent verification step is enforced before promotion, and the novelty function is not discriminating | - |
| `F-WRD-009` | The booted DiscoveryRunner seeds canned challenges with non-canonical domain atoms | medium | confirmed | statically_inferred | CAP-WRD-008; CAP-WRD-009 | Seed fixtures were written without reference to the canonical domain ontology | - |
| `F-WRD-010` | ControlCenter boots about 29 subsystems from inside GenServer.init, outside OTP supervision | medium | probable | statically_inferred | CAP-WRD-001; CAP-WRD-005; CAP-WRD-006; CAP-WRD-010 | Systems were started directly rather than through a supervision tree, so crash-restart semantics are undefined | - |

### 6.5 Section F — Platform, interfaces and operations (16 findings)

| ID | Finding | Sev | Conf | Basis | Affected capabilities | Root cause | duplicate_of |

|---|---|---|---|---|---|---|---|
| `F-PLT-001` | Interface contracts ISD v2.0 and IF-001 to IF-004 do not exist in the repository | high | confirmed | independently_verified | CAP-PLT-001; CAP-PLT-012 | The interface contract set was specified in programme documents but never landed in this repository (it may live in the ESAP repository or another ... | - |
| `F-PLT-002` | Divergent and duplicated API entrypoints with divergent security posture | high | confirmed | independently_verified | CAP-PLT-001; CAP-PLT-004; CAP-PLT-009 | The monetization workstream forked main_production.py instead of extending main.py, and authentication is opt-in by environment rather than ... | `F-ARC-009` |
| `F-PLT-003` | Frontend platform is mostly absent from git, so the WebGL Observatory cannot be audited | high | confirmed | independently_verified | CAP-PLT-005; CAP-PLT-006 | A move to a separate repository (commit 3f8aacda) was executed without vendoring or a pointer, and the dashboard and mobile directories were never ... | `F-ARC-024` |
| `F-PLT-004` | The Python, Docker and release pipeline never executes on this branch and the baseline records the branch filter incorrectly | high | confirmed | independently_verified | CAP-PLT-010; CAP-PLT-001; CAP-PLT-004; CAP-PLT-009 | Workflow branch filters were written for mainline; candidate-branch work never widened them, and the baseline discovery transcribed an incorrect ... | `F-ARC-015` |
| `F-PLT-005` | The Kubernetes production overlay contains plaintext credentials and cannot build | high | confirmed | independently_verified | CAP-PLT-009; CAP-PLT-010; CAP-PLT-002 | Secrets were hand-written into the overlay and the kustomize base was never completed | `F-ARC-008` |
| `F-PLT-006` | NATS integration includes an emulated TCP transport with ambiguous fallback semantics | medium | confirmed | independently_verified | CAP-PLT-002; CAP-PLT-004; CAP-PLT-011 | The listener is a development and test fallback that hardened into integration, and nothing documents when it is active instead of gnat | `F-ARC-228` |
| `F-PLT-007` | Event infrastructure is fragmented across four or more transports with no registry or schema authority | medium | confirmed | independently_verified | CAP-PLT-002; CAP-PLT-007; CAP-PLT-011 | Organic phase-by-phase growth: each phase added a bus instead of extending one | `F-ARC-004` |
| `F-PLT-008` | Runtime production boot is impossible because config/prod.exs is missing | medium | confirmed | independently_verified | CAP-PLT-003; CAP-PLT-008; CAP-PLT-010 | Dev and test only runtime configuration history | `F-ARC-014` |
| `F-PLT-009` | Runtime state databases and a binary are committed to git | medium | confirmed | independently_verified | CAP-PLT-008; CAP-PLT-010; CAP-PLT-009 | Runtime writes opened tables in the repository root before ignore rules were written | `F-ARC-018` |
| `F-PLT-010` | tiannara_saas is misclassified as a Python service and its static-export Docker build is incompatible with server rewrites | medium | confirmed | statically_inferred | CAP-PLT-004; CAP-PLT-005; CAP-PLT-010 | The Dockerfile was written for a static-export variant while the configuration later switched to rewrites (or the reverse) | `F-ARC-231` |
| `F-PLT-011` | No dependency or secret scanning exists in CI | medium | confirmed | independently_verified | CAP-PLT-009; CAP-PLT-010 | CI scope was historically limited to test suites and security was left to manual audit | - |
| `F-PLT-012` | The audit-correlation component cannot fail because the verifiers return success unconditionally | medium | confirmed | independently_verified | CAP-PLT-007; CAP-PLT-012 | The verifier was implemented as a report generator and the missing-failure path was never tested | `F-ARC-007` |
| `F-PLT-013` | Protobuf schemas are unversioned, minimal and disconnected from the runtime bus | low | probable | statically_inferred | CAP-PLT-001; CAP-PLT-002 | The protos are a visualisation-channel artefact rather than a platform contract | - |
| `F-PLT-014` | The desktop shell name collides with the Observatory and has zero verification | low | confirmed | statically_inferred | CAP-PLT-013; CAP-PLT-014 | Parallel prototype whose ownership was never assigned | - |
| `F-PLT-015` | Observatory security posture: dev bypass, committed dev secrets and a fail-open API fallback | medium | confirmed | independently_verified | CAP-PLT-014; CAP-PLT-009; CAP-PLT-007; CAP-PLT-005 | Development ergonomics were shipped as defaults | `F-ARC-019` |
| `F-PLT-016` | Key-shaped files at the repository root and a tracked binary create a secret hygiene risk | low | confirmed | statically_inferred | CAP-PLT-009 | Local key material was placed in the workspace root where a future git add -A would stage it | - |

### 6.6 Section G — Architectural problems, boot and flow gaps (37 findings)

| ID | Finding | Sev | Conf | Basis | Affected capabilities | Root cause | duplicate_of |

|---|---|---|---|---|---|---|---|
| `F-ARC-001` | Two Elixir projects compile 28 identical fully-qualified modules | critical | confirmed | independently_verified | CIS immune subsystem, observatory and sentinel, OED, A10, P9X, civilization kernel (capability names used ... | The runtime project copied a Tiannara.* subtree from the root project to boot independently and then diverged, without an ownership decision per ... | - |
| `F-ARC-002` | KillSwitch triplication and a dead consumer API | high | confirmed | independently_verified | World management, safety chain, Safe Mode | The 5F.3.5 consolidation produced a unified module but deferred the merge and the consumer migration; deletions were never approved | `F-GOV-013` |
| `F-ARC-003` | Constitutional authority is scattered and the runtime constitution module is dead | high | confirmed | independently_verified | Constitutional governance, CEL scoring, OS governance | Repeated constitutional work in separate subsystems with no canonical declaration | - |
| `F-ARC-004` | Event bus proliferation across seven root buses plus per-project and umbrella buses | medium | confirmed | independently_verified | Event propagation, OLEF, Meta observer stack, ASC and CEL | Organic phase-by-phase growth: each phase added a bus instead of extending one | `F-PLT-007` |
| `F-ARC-005` | The knowledge graph is implemented four or more times across three languages | medium | probable | statically_inferred | Knowledge substrate, research pipelines, OMCS, civilization | Parallel per-language implementation without a capability mapping | - |
| `F-ARC-006` | CAE, CAP and UEP have zero implementation and zero in-repo specification | high | confirmed | independently_verified | Epistemic arbitration, promotion governance, payload schema, certification programme | The design inputs were produced outside this repository and never landed here | - |
| `F-ARC-007` | The tiannara_audit verifiers cannot fail, which is a P0 claim-control defect | critical | confirmed | independently_verified | Independent audit, certification evidence, provenance | The verifiers were written to produce a report rather than to test a claim; the comparison step was never implemented | - |
| `F-ARC-008` | The k8s production overlay contains literal credentials, a broken base and orphan KEDA targets | critical | confirmed | independently_verified | Deployment and operations, NATS authentication, k8s scaling | Secrets were hand-written into the overlay and the kustomize base was never completed | - |
| `F-ARC-009` | The API production surface is split and authentication is opt-in with one unauthenticated admin route | critical | confirmed | independently_verified | API security, payments, production authentication | The monetization workstream forked a second application instead of extending the first, and authentication defaults to permissive | - |
| `F-ARC-010` | The orphaned and zero-evidence module population | medium | probable | independently_verified | CEL, OS governance, executive cognition, world model, RRM | Modules written per phase without a consumer, a supervisor or a test, and no disposition pass | - |
| `F-ARC-011` | Intra-runtime duplicate module definitions produce redefinition warnings | medium | probable | statically_inferred | GRCC, CIS immune, P9X, RRG, runtime build integrity | Either duplicated source files or stale build artefacts; the cause for 10 of 11 warnings is undetermined | - |
| `F-ARC-012` | The Python packages have an import cycle between core and pros and a test-only cycle to api | low | confirmed | statically_inferred | Pros integration, core packaging | Bidirectional package dependency created by hardware adapter integration without a leaf package | - |
| `F-ARC-013` | Hidden cross-project coupling: the root application probes runtime process names | medium | probable | statically_inferred | Runtime census and atlas tooling, deployment model | Tooling was written against an intended co-VM topology that was never realised or documented | - |
| `F-ARC-014` | The runtime cannot boot under MIX_ENV=prod because config/prod.exs is missing | high | confirmed | independently_verified | Production deployment, CPL and Omega boot, observability | The configuration import was written before the production file and the gap was never closed | - |
| `F-ARC-015` | CI blind spots: large test surfaces never run | medium | confirmed | independently_verified | API, core and pros test hygiene, observatory, audit tooling | Workflow branch filters were written for mainline and the umbrella and audit tool were never wired into the branch-spanning workflow | - |
| `F-ARC-016` | Systemic test-versus-production mismatch through fabrication and mock or loaded conflation | high | confirmed | independently_verified | OPC execution, CIS safety delivery, observability path, test gate integrity | Individual subsystems were hardened in isolation with simulated success, and the hardening was not propagated to the production edges | - |
| `F-ARC-017` | Historical completion documents overclaim, making the schema of record stale | medium | confirmed | statically_inferred | Certification programme, all phase claims | Completion documents were written from intent rather than from reconciled evidence | - |
| `F-ARC-018` | Persistence and state hygiene: tracked runtime database churn, CWD-relative stores and no store map | medium | confirmed | independently_verified | CPL, executive memory, council audit log, Python memory, observatory state | Runtime stores were opened in default locations before a store ownership boundary and a path configuration policy existed | - |
| `F-ARC-019` | The Observatory umbrella security posture is unsafe: dev bypass, committed dev secrets and wildcard CORS | high | confirmed | independently_verified | Observatory API, RBAC, data stores | Development ergonomics were shipped as defaults in a tracked, deployed-adjacent configuration | - |
| `F-ARC-020` | Protocol and serialisation authority vacuum: Babel is unwired and unkeyed, NATS has two clients and there is no payload schema | medium | confirmed | independently_verified | Messaging, crypto payloads, provenance envelopes | Several independent protocol authorities were introduced without a canonical owner | - |
| `F-ARC-021` | Namespace hygiene: four meanings of RRG, three supervisors.ex files and a typo root namespace | medium | confirmed | statically_inferred | RRG consumers (ccr, civilization, omce, audit), the RRM phase 18 modules, supervision clarity | Acronyms were reused across subsystems and directory structures were copied between the two projects | - |
| `F-ARC-022` | Competing registries: two principle registries, three capability registries and one orphan domain | medium | confirmed | independently_verified | Governance, CEL dispatch, ASC ecology, discovery domains | Registries were introduced per subsystem without a single consulted registry per concept | - |
| `F-ARC-023` | Missing negative tests on the audit and proservation critical paths | medium | confirmed | independently_verified | Audit tooling, prosthetic hardware safety, runtime gate | No fail-path test culture in the tools that are supposed to prove correctness | - |
| `F-ARC-024` | Frontend ownership void: three of five user interfaces are invisible to git | medium | confirmed | independently_verified | Operator interfaces, SaaS, observability UI | A move to a separate repository was executed without vendoring or a pointer, and two directories were never committed by oversight | - |
| `F-ARC-025` | The Rust NIF substrate is unlinkable because the :tiannara_phase14 application does not exist | low | confirmed | independently_verified | Phase 10 to 17 native bridges (MEN, CRCA, REG, SMCP, REA, UCC) | A native substrate was declared as a dependency before the application, the crate wiring and the build step existed | - |
| `F-ARC-226` | The launcher never starts the runtime application, so the entire second OTP root is unreachable | high | confirmed | statically_inferred | All runtime capabilities; the whole W1, W2 and W3 wiring workstream | The runtime application was never integrated into any deployment or launcher path, so all of its boot wiring is test-time wiring only | - |
| `F-ARC-227` | The Python to Elixir observatory edge is permanently on the mock path | high | confirmed | independently_verified | Observatory and observability, world-model reporting, the 12-worlds claim | The API client targets a path that was never implemented and the fallback silently masks it | - |
| `F-ARC-228` | The boot-wired NATS is an in-VM loopback with an anonymous TCP injector and the real client is hard-disabled | high | confirmed | independently_verified | Messaging, mesh and reality bus, OLEF pressure stream, OPC bus, observer stack | An in-VM broadcast was given a NATS-shaped network surface, and the real client was disabled without the status reporting being corrected | - |
| `F-ARC-229` | No artifact is produced for any deployable unit and the runtime cannot be packaged at all | high | confirmed | statically_inferred | Deployment and operations, all Elixir capabilities | The build pipeline was never extended to produce an Elixir artefact | - |
| `F-ARC-230` | The API container health check probes a route that does not exist | medium | confirmed | statically_inferred | Deployment and operations, API availability | The health probe was written against a route layout that was never implemented | - |
| `F-ARC-231` | The SaaS container image cannot be built because the static-export assumption conflicts with the server-rewrite reality | medium | confirmed | statically_inferred | SaaS user interface, deployment | The Dockerfile was written for a static-export variant while the configuration uses server rewrites | - |
| `F-ARC-232` | The launcher required services (Postgres, Redis) are not consumed by any Elixir code | medium | confirmed | statically_inferred | Platform, deployment | The launcher declared an intended infrastructure set that no process in the started tree consumes | - |
| `F-ARC-233` | The Observatory umbrella is outside every build and CI path | medium | confirmed | independently_verified | Observatory API, RBAC, telemetry gateway, event and replay and state stores | The umbrella was moved or copied without its CI file being version-controlled | `F-ARC-015` |
| `F-ARC-234` | The multi-world runtime surface is unreachable because the supervised module exists only in Markdown | critical | confirmed | independently_verified | World management, safety chain, Safe Mode, CAP-WRD-004 | The multi-world control plane was documented and consolidated in Markdown without the source module being written or the wiring being done | `F-GOV-013` |
| `F-ARC-235` | Tiannara.ControlCenter, the documented owner of about 29 subsystems, is in no boot tree | high | confirmed | independently_verified | Discovery pipeline, capability graph, operations self-healing, Section D research | The control centre was written as an implicit boot authority and was never added to a supervision tree, so its documented ordering contract is ... | - |
| `F-ARC-236` | Phoenix.PubSub and Registry ownership is duplicated across two Elixir applications with colliding intent | low | confirmed | statically_inferred | Messaging, cross-project coupling | The two projects were developed independently with no shared topology decision | - |
| `F-ARC-237` | Flattened-path garbage directories and files at the repository root produced by a path-join bug | low | confirmed | documented | none: the artefacts are inert and no capability depends on them | A path-concatenation bug in a collector wrote absolute paths as relative directory names | - |

### 6.7 Section E — ESAP, separate repository, never merged into the platform ledger (10 findings)

| ID | Finding | Sev | Conf | Basis | Affected capabilities | Root cause | duplicate_of |

|---|---|---|---|---|---|---|---|
| `F-ESP-001` | The historical source-intent to ISR to downstream derivation issue is only partially closed | high | confirmed | statically_inferred | CAP-ESP-001; CAP-ESP-002; CAP-ESP-003 | Typed behavioural ISR semantics merged in PR 137 are, per the repository own register, not consumed by the certified emitters | - |
| `F-ESP-002` | The RBAC and ABAC engine is not wired into generated route, service or data enforcement | high | confirmed | statically_inferred | CAP-ESP-011 | The policy engine was implemented and merged but not connected to the generated enforcement points | - |
| `F-ESP-003` | Event and asynchronous generation is incomplete and API versioning, pagination and idempotency are not ISR-driven | high | confirmed | statically_inferred | CAP-ESP-010; CAP-ESP-008 | The asynchronous codegen surface was emitted before the delivery-semantics model was defined | - |
| `F-ESP-004` | No generated UI to API to persistence end-to-end journey exists and frontend browser verification is absent from CI | high | confirmed | statically_inferred | CAP-ESP-007; CAP-ESP-012 | The frontend was merged as a generator before the browser-level verification tier existed | - |
| `F-ESP-005` | The remediation register is stale relative to the merged state of the repository | medium | confirmed | independently_verified | CAP-ESP-013 | The register was not re-derived after the merge wave | - |
| `F-ESP-006` | Deployment fails closed with no shipped runtime executor and generated workflows are never executed | medium | confirmed | statically_inferred | CAP-ESP-014 | The fail-closed design was completed but the executor was never provided | - |
| `F-ESP-007` | Architecture selection scores are analyst-assigned and legacy-repository analysis is regex-only | medium | probable | statically_inferred | CAP-ESP-004; CAP-ESP-015 | The scoring was filled in by hand because candidate-content derivation was not implemented | - |
| `F-ESP-008` | Eight historical fail-open defects are verified fixed with regression tests | low | confirmed | documented | CAP-ESP-013 | Historical fail-open defects were fixed; the register itself is the evidence | - |
| `F-ESP-009` | The run evidence ledger records pass verdicts with essentially empty test inventories | medium | probable | statically_inferred | CAP-ESP-005; CAP-ESP-013 | The evidence ledger was populated by a reporting path that did not require real test inventories | - |
| `F-ESP-010` | Three parallel ISR representations and three emitter stacks coexist with no clear single authority | medium | confirmed | statically_inferred | CAP-ESP-002; CAP-ESP-005; CAP-ESP-006 | The compiler was extended in place across three generations of the project layout without an authority decision | - |

### 6.8 R1/OP-01 — operator disposition (1 finding)

| ID | Finding | Sev | Conf | Basis | Affected capabilities | Root cause | duplicate_of |
|---|---|---|---|---|---|---|---|
| \F-SEC-001\ | Rotated credential and git history for the phase-6 production secret are not yet remediated | critical | confirmed | documented | CAP-PLT-009; CAP-PLT-010 | The literal values entered the tracked repository through a hand-written kustomize overlay; the rotation is an environment action that the repository cannot perform on its own | - |

---

## 7. Machine-readable companion

`certification/atlas/findings_ledger.csv` — 130 data rows, RFC-4180 quoting (every field quoted), columns exactly:

```
"finding_id","title","domain","severity","confidence","status","evidence_state_basis","affected_capabilities","evidence","root_cause","remediation","acceptance_criteria","prerequisites","blast_radius","source_section","duplicate_of","notes"
```

Controlled vocabularies: `domain` in {COG, EPI, GOV, WRD, PLT, ARC, ESP}; `severity` in {critical, high, medium, low}; `confidence` in {confirmed, probable, hypothesis}; `status` = OPEN for all 130 rows; `evidence_state_basis` in {documented, statically_inferred, dynamically_observed, independently_verified, none}. `duplicate_of` is empty for 110 canonical rows and set on the 20 rows that restate an existing finding.
