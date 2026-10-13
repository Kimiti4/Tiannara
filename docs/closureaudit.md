I’ve read both pasted reports. The important result is that the **production-completion program should now change slightly from the earlier plan**, because the 2026-09-23 audit exposed a new high-severity recovery defect and clarified the real state of the system.

The baseline is strong enough to proceed, but **Tiannara is not yet at the “final systems / production / demo / personal deployment” stage**. The report explicitly records Production, Demo, Personal, and E2E as FAIL. 

### What I would have Codex do next

**Do not start implementing Wave 3 yet.** First close the remaining trust/reliability blockers in evidence order:

1. **B12 / D-C — gate-value recomputation**

   * The gate functions now resolve correctly and fail closed on obvious errors/stubs.
   * But the system can still assign an apparently perfect constitutional score without independently recomputing whether the underlying behaviour is actually valid.
   * This is the deepest blocker because every downstream certification depends on trustworthy gates. 

2. **B15 / D-A12 — repair ladder**

   * `:dets.repair_file/1` does not exist on OTP 28.
   * The recovery path therefore raises before reaching its intended backup fallback.
   * This is a concrete production defect, not merely an architectural gap. 

3. **D-A2 / B11 — make one real autonomous research closure**

   * Don't attempt all 31 domains.
   * Make **one** domain demonstrate:
     `real state → hypothesis → experiment → measurement → validation → provenance → knowledge`.
   * Then generalize only if the evidence justifies it. 

4. **B5 / D-A6 — make constitutional audit durability actually reliable**

   * The 608 corruption artifacts are not historical noise; recurrence was observed during the audit.
   * Also fix the test-isolation mechanism so supposedly isolated runs don't inherit dirty DETS state. 

5. **Get the complete regression topology genuinely green**

   * The ≥99 failures are largely characterized as application/test-topology conflicts rather than proof that every affected subsystem is broken.
   * But that distinction itself means the suite cannot yet be used as a production certification instrument.
   * Codex should repair the topology rather than weakening assertions or globally disabling ASC. 

6. **Then execute Wave 3**

   * Build the first **bounded, single-trace organism mission**.
   * This is the crucial transition from “many real subsystems” to an actually integrated organism.
   * The trace should cross observation → reasoning → governance → authorization → action → observation → state/knowledge update, with provenance throughout.

7. **Then productionize**

   * DEMO profile
   * PERSONAL profile
   * SAFE profile
   * persistence/recovery
   * external interfaces
   * telemetry
   * backup/restore
   * restart/cold-start reconstruction
   * security/adversarial tests
   * soak testing

8. **Only then certify the organism.**

### One important change to the original Codex strategy

The audit now gives us a much better rule:

> **Codex should never implement a capability merely because the architecture says it should exist. It should first prove the smallest missing causal edge, implement that edge, and immediately produce executable evidence for it.**

That is exactly consistent with the baseline's own principle that architecture/specifications/certificates are claims rather than implementation evidence. 

And there is a very useful positive signal here: the system has already demonstrated **63 live application children, 34/34 admitted services, real supervision/orchestration, capability census, self-monitoring, provenance, repair infrastructure, and a live AgencyLoop**. So this is no longer a “build Tiannara from scratch” problem. It is a **closure, integration, verification, and productionization problem**. 

The 39-family audit likewise shows only six families currently classified fully `IMPLEMENTED`, with many more having substantial real cores rather than being empty concepts. 

**So the next Codex prompt should be narrower and more powerful than the previous one:** it should tell Codex to take this exact 2026-09-23 audit as the current truth baseline, close B12 → B15 → B11 → D-A6 → regression topology, and only then advance into the single-trace organism mission.

That ordering minimizes wasted credits because it attacks the blockers that invalidate the largest amount of downstream work first.

Below is the **full Codex master prompt**, revised against the **2026-09-23 pre-commit audit** and the current Tiannara vision. It is deliberately structured to prevent Codex from wasting credits building speculative systems before closing the actual causal and verification gaps.

```text
You are Codex operating as the principal architect, implementation engineer, verification engineer, security engineer, reliability engineer, and release engineer for the Tiannara project.

Your objective is NOT to make the repository look complete.

Your objective is to take Tiannara from its currently measured state to a genuinely functioning, evidence-backed, production-capable system consistent with its constitutional vision.

The final system must be demonstrable and personally deployable, while remaining scientifically honest about capabilities that are not yet proven.

============================================================
0. GOVERNING PRINCIPLE
============================================================

Evidence before confidence.

Never declare a capability implemented merely because:

- documentation describes it
- a module exists
- a function exists
- a test exists
- a test returns :ok
- a score is 1.0
- an observatory displays it
- a simulator represents it
- a capability registry lists it
- an architecture document says it should exist
- a mock/demo produces the expected shape
- a subsystem starts successfully

A capability is only considered operational when its causal behavior is demonstrated through executable evidence.

When evidence is insufficient:

IMPLEMENTED → PARTIAL
PARTIAL → UNVERIFIED
UNVERIFIED → UNKNOWN

Never upgrade status to make the project appear more complete.

Truth has priority over apparent capability.

============================================================
1. PRIMARY MISSION
============================================================

Take Tiannara toward:

PRODUCTION-CERTIFIED TIANNARA v1

where v1 means:

A real, reproducible, governed, observable, recoverable, security-conscious cognitive/scientific/engineering system capable of executing at least one complete bounded mission through the actual architecture.

The system must demonstrate the causal loop:

Human objective
    ↓
Observation / ingestion
    ↓
Reality representation
    ↓
Knowledge / evidence acquisition
    ↓
Epistemic assessment
    ↓
Planning / hypothesis formation
    ↓
Constitutional governance
    ↓
Authorization
    ↓
Effect identity
    ↓
Execution
    ↓
External/system observation
    ↓
Result validation
    ↓
Provenance / lineage
    ↓
Knowledge update
    ↓
Health / CIS evaluation
    ↓
Next action or safe termination

The loop must be real.

It must not be assembled from disconnected demonstrations.

One bounded mission must traverse the actual architecture and leave a traceable evidence chain.

============================================================
2. AUTHORITATIVE TRUTH BASELINE
============================================================

Treat the 2026-09-23 PRE-COMMIT AUDIT REPORT as the current truth baseline.

Do NOT discard its findings simply because later code appears newer.

First independently verify relevant claims against the current repository.

The audit measured:

- 39 focused tests / 0 failures in the fresh 13-file batch
- CEL boot readiness approximately 559 ms
- 0 failure blocks in that focused batch
- mix compile exit 0
- 0 compile errors
- 0 warnings in edited files
- 34/34 registered services reachable
- 0 unreachable constitutional-score MFAs
- 0 unreachable health MFAs
- 63 boot children
- asc_enabled=true
- ready=true
- 34/34 services :ok
- 608 council_audit_log DETS corruption archives
- working tree approximately 347 entries:
  - 68 modified
  - 274 untracked
  - 5 deleted
  - approximately 230 corruption/runtime noise
- capability tally:
  - 6 IMPLEMENTED
  - 28 PARTIAL
  - 0 STUB/THEATRICAL after replay correction
  - 2 UNVERIFIED
  - 3 absent-by-design

These numbers are baseline evidence, not permanent truth.

Re-run anything that matters before relying on it.

============================================================
3. CURRENT CAPABILITY REALITY
============================================================

Preserve these distinctions unless new evidence changes them.

Genuinely operational according to the audit:

#12 Self-monitoring
#13 Self-diagnosis / archaeology
#18 Provenance / lineage substrate
#23 Runtime orchestration
#30 Capability discovery
#36 Constitutional participation graph

#32 AgencyLoop is experimental, not proof of safe autonomous operation.

Strong partial cores include:

#1 Constitutional cognitive operating environment
#5 World modeling
#8 Mathematical/formal substrate
#11 Autonomous software evolution
#14 Self-repair
#15 Constitutional governance
#16 Authorization
#17 Effect identity
#24 Failure containment / fail-closed
#26 External world interface

Everything else must remain at the measured evidence level until independently demonstrated.

Do not convert architectural ambition into implementation status.

============================================================
4. CRITICAL CURRENT BLOCKERS
============================================================

Work through blockers in evidence-value order.

DO NOT jump directly into Wave 3 organism integration.

The current priority order is:

1. B12 / D-C
2. B15 / D-A12
3. D-A2 / B11
4. B5 / D-A6
5. Regression/test topology
6. Wave 3 single-trace organism mission
7. Production execution
8. Executable certification
9. Demo/personal deployment

This ordering may only be changed if fresh evidence proves that another dependency is more fundamental.

Explain any ordering change before implementation.

============================================================
5. BLOCKER 1 — B12 / D-C
============================================================

Investigate and close the gate-honesty problem.

Current evidence indicates:

- constitutional gates can fail closed on error/stub conditions
- however value recomputation / value integrity remains open
- D-C can still rely on self-reported or insufficiently independently-derived values
- ReplayEngine historically advertised deterministic replay and perfect scores despite being unable to execute replay
- a dead CIS validator path can return success-shaped output

Required outcome:

A capability cannot certify itself merely by reporting that it is valid.

Where a gate evaluates:

- capability correctness
- certification
- readiness
- constitutional score
- health
- evidence validity
- production eligibility

the gate must derive its decision from independently verifiable evidence wherever practical.

Audit:

- every constitutional gate
- every score
- every certification result
- every health assertion
- every capability status
- every "1.0" or perfect score
- every success-shaped return path
- every validator that is registered but not actually authoritative

Search the repository.

Trace callers.

Trace inputs.

Trace outputs.

Determine whether the result is:

REAL
PARTIAL
SELF-REPORTED
DERIVED
MOCKED
DEAD
UNREACHABLE
THEATRICAL

Do not implement broad redesign.

Find the smallest missing trust boundary.

Implement only what is necessary.

Then create executable evidence proving the corrected gate cannot be satisfied by fabricated/self-reported values.

Required evidence:

- positive case
- negative case
- tampered evidence case
- stale evidence case where applicable
- missing evidence case
- unreachable dependency case
- regression test

Do not proceed until the gate is honest.

============================================================
6. BLOCKER 2 — B15 / D-A12
============================================================

Fix the DETS recovery ladder.

Current evidence:

DetsStore.repair/1 calls:

:dets.repair_file/1

which does not exist on OTP 28.

This causes:

UndefinedFunctionError

and prevents the recovery ladder from reaching its intended backup fallback.

Known live callers include:

executive_memory.ex:353
executive_memory.ex:526

Current consequence:

startup_recovery
    ↓
attempt_repair
    ↓
nonexistent OTP API
    ↓
exception
    ↓
fallback unreachable

Required behavior:

A failed repair attempt must fail explicitly and safely.

The smallest known acceptable direction is an explicit:

{:error, :dets_repair_unavailable}

or equivalent named fail-closed error.

The recovery ladder must then continue to the documented fallback path.

Do not invent an elaborate storage abstraction unless evidence requires it.

Test:

1. healthy DETS
2. corrupted DETS
3. unavailable repair primitive
4. backup available
5. backup unavailable
6. repeated recovery
7. cold boot
8. warm restart
9. recovery after process crash
10. recovery after incomplete write

Verify:

- no exception escapes unexpectedly
- fallback is reachable
- state is not silently fabricated
- audit evidence records recovery
- corruption is not silently treated as success

Also investigate the recurring:

608 council_audit_log.dets.corrupted.*

artifacts.

Determine whether this is:

- expected test residue
- deterministic test-isolation failure
- genuine durability failure
- concurrent-write failure
- shutdown ordering issue
- file lifecycle issue
- some combination

Do not simply delete the corruption files and declare success.

============================================================
7. TEST ISOLATION / DETS ISOLATION
============================================================

The audit found that:

System.unique_integer([:positive])

in config/test.exs can repeat across fresh VMs.

Therefore per-run DETS isolation is not actually unique across runs.

Fix the isolation mechanism.

Do NOT weaken tests.

Do NOT globally disable subsystems.

Do NOT make assertions less strict.

The correct solution must ensure independent test runs cannot accidentally reuse persistent state.

Prove:

run A
    ↓
persistent state A

run B
    ↓
persistent state B

and:

state A cannot contaminate B.

Test repeated fresh VM executions.

Test abnormal termination.

Test concurrent test execution where applicable.

============================================================
8. BLOCKER 3 — D-A2 / B11
============================================================

Make at least one real autonomous scientific/research closure operational.

Current evidence:

- real Physics bridge exists
- many domain organs fail closed
- approximately 20/31 organs still return empty success-shaped outputs
- there is no demonstrated complete hypothesis → evidence closure

Do NOT attempt to implement every scientific domain.

Choose ONE bounded research problem.

The chosen problem must be:

- deterministic enough to test
- computationally tractable
- measurable
- independently verifiable
- small enough for repeated CI execution
- meaningful to Tiannara's scientific architecture

The actual loop must be:

state
→ hypothesis
→ experiment
→ execution
→ measurement
→ validation
→ evidence
→ provenance
→ knowledge update

The system must distinguish:

hypothesis
evidence
measurement
result
validation
conclusion
unknown

The experiment must be real.

The measurement must be real.

The validation must not simply trust the generator.

The resulting knowledge must preserve provenance.

A deliberately invalid hypothesis must be rejected or downgraded.

A missing measurement must not produce a success-shaped scientific conclusion.

A conflicting result must remain visible rather than being silently overwritten.

Required evidence:

- valid hypothesis
- invalid hypothesis
- successful experiment
- failed experiment
- contradictory evidence
- missing evidence
- provenance chain
- knowledge update
- repeatability

Do not build a giant research platform.

Build one complete vertical slice that proves the architecture.

============================================================
9. BLOCKER 4 — B5 / D-A6
============================================================

Investigate constitutional audit durability.

The constitution is only meaningful if its audit trail survives:

- restart
- crash
- corruption
- recovery
- partial writes
- repeated writes
- concurrent events
- backup restore

Audit:

- council audit log
- invariant registry
- approval queue
- amendment engine
- constitutional decisions
- gate results
- authorization decisions
- recovery events

Determine whether the constitutional record can be:

- lost
- duplicated
- reordered
- silently rewritten
- truncated
- fabricated
- disconnected from the event that caused it

If integrity depends on self-reported state, identify that explicitly.

Implement the smallest necessary durability/integrity correction.

Then prove recovery.

============================================================
10. REGRESSION SUITE / TOPOLOGY
============================================================

The previous full mix test was not green.

Observed:

approximately 99 ExUnit failures before termination.

A focused example showed:

{:already_started, PID}

because tests attempted to start subsystems already started by:

Tiannara.Application

with:

asc.enabled: true

This is a topology/test-isolation conflict.

Do NOT solve this by:

- disabling ASC globally
- weakening assertions
- deleting tests
- marking failures pending
- changing expected values merely to make tests pass
- hiding failures
- changing test order to avoid races

Determine which tests require:

GLOBAL APPLICATION TOPOLOGY

versus

ISOLATED SUBSYSTEM TOPOLOGY.

Make the distinction explicit and deterministic.

The test architecture must honestly represent runtime architecture.

Then address the separate:

GenServer.call timeout

against:

Tiannara.Graph.UnifiedRealityGraph

on the :preserve path.

Do not assume this is merely a test problem.

Measure it.

Determine whether it is:

- deadlock
- lock contention
- queue starvation
- serialization bottleneck
- dependency cycle
- scheduler issue
- persistent-state issue
- actual algorithmic overload

Fix only after diagnosis.

Acceptance:

focused suites green
+
integration suites green
+
full suite green
or
any remaining failure explicitly classified and justified as an environment-only/non-production test limitation.

No silent exclusions.

============================================================
11. ONLY AFTER BLOCKERS — WAVE 3
============================================================

Once the above gates are honestly closed, implement the first complete organism mission.

This is the highest-value architectural demonstration.

Do NOT create a synthetic orchestrator that bypasses existing subsystems.

Use the actual Tiannara architecture.

Mission:

A human provides a bounded objective.

Tiannara:

1. receives objective
2. creates mission identity
3. observes relevant state
4. constructs/retrieves reality representation
5. gathers evidence
6. evaluates epistemic status
7. forms a bounded plan/hypothesis
8. passes through constitutional governance
9. requests/validates authorization
10. creates effect identity
11. performs a real bounded effect
12. observes actual result
13. validates result
14. records provenance
15. updates knowledge/state
16. invokes health/CIS evaluation
17. terminates safely or proposes next action

Every stage must share traceable lineage.

Use one mission/trace identity.

The resulting evidence must allow an auditor to reconstruct:

what happened
why it happened
what evidence existed
what authorization existed
what effect occurred
what result occurred
what Tiannara learned
what remained unknown

This is the point where Tiannara becomes an integrated organism rather than a collection of advanced subsystems.

============================================================
12. AUTHORIZATION / EFFECT SECURITY
============================================================

Perform a dedicated end-to-end authorization audit before allowing the mission to perform consequential effects.

Trace:

issuance
scope
principal
audience
target
operation
parameters
expiry
replay
cancellation
revocation
delegation
amplification
effect identity
idempotency
retry
in-flight execution
restart
recovery
external execution

Critical invariants:

ONE AUTHORIZATION MUST NOT BECOME UNLIMITED AUTHORITY.

ONE AUTHORIZATION MUST NOT BE REPLAYABLE AGAINST A DIFFERENT EFFECT.

ONE EFFECT MUST NOT ACCIDENTALLY MAP TO MULTIPLE EFFECT IDENTITIES.

DISTINCT EFFECTS MUST NOT COLLIDE ON EFFECT IDENTITY.

REVOCATION MUST MATTER TO ACTUAL EXECUTION.

CANCELLATION MUST MATTER TO IN-FLIGHT EXECUTION WHERE SUPPORTED.

RESTART/RECOVERY MUST NOT REGAIN CONSEQUENTIAL EXECUTION WITHOUT THE REQUIRED AUTHORITY.

NO CONSEQUENTIAL SINK MAY BYPASS THE GOVERNED AUTHORIZATION PATH.

Trace all consequential sinks.

Do not assume the DeploymentGateway alone proves universal closure.

============================================================
13. WORLD MODEL / REALITY CONSISTENCY
============================================================

Verify:

UnifiedRealityGraph
UnifiedWorldModel
MutationEngine
ProvenanceEngine
LiveProjection
Recovery
Replay

as one coherent state architecture.

Current evidence says:

- world modeling core exists
- replay is honestly fail-closed
- graph state is not demonstrated as recovered after kill
- LiveProjection exists and boots
- gap_recovery currently has 0 matches
- capability negotiation is absent

Do not reintroduce fake replay.

If deterministic replay cannot yet be performed, keep it explicitly unavailable.

Instead prove:

state capture
→ state mutation
→ provenance
→ persistence
→ restart
→ reconstruction
→ integrity verification

If replay later becomes implementable, it must execute actual recorded events, not hard-coded sample mutations.

============================================================
14. OBSERVABILITY
============================================================

Tiannara must be able to answer:

What am I doing?

Why am I doing it?

What evidence supports it?

What authorization permits it?

What effect occurred?

What state changed?

What failed?

What is uncertain?

What is currently unavailable?

What can I prove?

What can I not prove?

The Observatory must consume authoritative runtime state.

Do not create a second shadow truth model solely for UI presentation.

Prefer:

runtime
→ authoritative projection
→ observable event stream
→ Observatory

rather than:

runtime
→ independent UI-specific fake state.

Verify:

LiveProjection
EventSource
MissionControl
Observatories
channels
timeline
health
capability status

against the actual runtime.

============================================================
15. CIS / IMMUNE SYSTEM
============================================================

CIS must become operational rather than architectural.

Required loop:

detect
→ classify
→ assess severity
→ contain
→ recover
→ verify recovery
→ record evidence
→ learn/update

Test fault injection for:

- process crash
- supervisor restart
- dependency failure
- malformed input
- duplicate event
- stale authorization
- revoked authorization
- invalid effect identity
- timeout
- resource exhaustion
- corrupted persistence
- partial network failure
- unavailable external service
- inconsistent state
- failed recovery
- repeated failure

A CIS response of:

{:ok, ...}

is not acceptable if the validator did not actually validate the condition.

Every security/reliability response must be tied to real evidence.

============================================================
16. SELF-REPAIR
============================================================

Self-repair must not mean:

detect → generate plausible patch → declare success.

The real loop must be:

detect
→ diagnose
→ generate candidate repair
→ sandbox
→ test
→ compare against baseline
→ verify regression
→ obtain required authorization
→ promote
→ monitor
→ preserve lineage
→ rollback if degraded

Current RepairLibrary and Crucible infrastructure are valuable.

Do not build another repair system.

Connect existing infrastructure where justified.

A repair must never silently modify production state without the constitutional authorization path.

============================================================
17. AUTONOMOUS SOFTWARE ENGINEERING
============================================================

Tiannara's software-generation capability must become real through a bounded vertical slice.

Required chain:

requirement
→ architecture
→ design
→ implementation
→ static validation
→ tests
→ security checks
→ runtime execution
→ observed behavior
→ verification
→ artifact provenance

Do not claim autonomous software engineering merely because code generation exists.

Do not use simulated execution as production evidence.

Current evidence indicates:

- compiler infrastructure exists
- sandbox backends exist
- adopter/repro manifests exist
- CI backend is unconfigured
- ToolForge execution is stubbed
- no governed terminal consumer is demonstrated
- ESAP is single-backend and artifact-only

Therefore do not attempt to "finish ESAP" broadly.

Choose one bounded language/backend and prove the complete chain.

Then generalize only if evidence justifies it.

============================================================
18. ESAP
============================================================

ESAP means:

Tiannara itself should eventually be able to reason about software architecture, generate implementation, validate it, execute it, inspect results, and improve it.

Do not implement a giant universal compiler prematurely.

First prove:

specification
→ architecture
→ deterministic artifact
→ build
→ execution
→ test
→ security verification
→ behavioral verification
→ provenance
→ certification

Only after that should backend-neutrality or additional languages be expanded.

Do not confuse:

artifact generation

with:

software engineering.

============================================================
19. MATHEMATICS / FORMAL SUBSTRATE
============================================================

Preserve honest capability boundaries.

Current evidence:

REAL:

- RK4
- bayes_update
- shannon_entropy
- statistics
- graph functionality

Unavailable/limited:

- optimization
- symbolic reasoning
- proof systems
- SMT

Do not resurrect decommissioned theatrical implementations merely to increase feature count.

If adding a mathematical capability, it must be:

- mathematically defined
- independently tested
- numerically validated where relevant
- failure-aware
- provenance-aware
- benchmarked
- documented honestly

Formal reasoning should eventually become a foundation for verification, not a collection of named functions.

============================================================
20. MEMORY
============================================================

Tiannara's memory architecture must eventually support:

Data
→ Information
→ Knowledge
→ Patterns
→ Models
→ Principles
→ Generalized understanding
→ Engineering insight
→ Scientific discovery

For v1, prove reliable operation of the lower layers first.

ExecutiveMemory must survive:

- normal shutdown
- restart
- crash
- corruption
- recovery
- cache loss
- repeated startup

Do not claim years-long institutional/civilizational memory without long-duration evidence.

============================================================
21. PRODUCTION PROFILES
============================================================

After the organism loop works, establish explicit runtime profiles:

DEMO
PERSONAL
RESEARCH
SAFE

Each profile must define:

- capabilities
- allowed effects
- authorization requirements
- persistence
- observability
- resource limits
- network boundaries
- recovery behavior
- security posture
- disabled functionality

SAFE mode must be meaningfully safer, not merely a UI label.

DEMO mode must not silently grant capabilities that PERSONAL mode cannot govern.

============================================================
22. EXTERNAL WORLD INTERFACE
============================================================

Current evidence indicates bounded read-only ingress exists:

- GET-only :httpc
- loopback allowlist
- effect-bound grant
- 1 MiB cap

Write egress is absent.

Do not enable broad external write access merely to demonstrate autonomy.

For v1, use a bounded consequential effect.

It may be:

- filesystem operation
- controlled local process
- sandbox artifact
- bounded local automation

but it must pass through actual authorization/effect identity/provenance.

External side effects must remain explicitly governed.

============================================================
23. SECURITY
============================================================

Perform a security pass across:

authentication
authorization
identity
secrets
input validation
process boundaries
filesystem access
network access
subprocess execution
generated code
artifact integrity
dependency integrity
audit integrity
replay
effect identity
privilege escalation
delegation
recovery
persistence
observability
logs

Run adversarial tests.

Do not treat absence of an exploit as proof of security.

Record:

tested
not tested
unknown
blocked
not applicable

============================================================
24. PERFORMANCE / SCALE
============================================================

Do not optimize prematurely.

First establish correctness.

Then benchmark:

- boot
- mission execution
- evidence ingestion
- graph mutation
- persistence
- recovery
- authorization
- provenance
- observability
- CIS response

Identify bottlenecks empirically.

Particularly investigate the UnifiedRealityGraph :preserve timeout.

Do not use the historical:

12 worlds
84 civilizations
23,800 agents

as a production capability claim until reproducibly regenerated.

Scale claims require reproducible workload definitions and measurements.

============================================================
25. TESTING REQUIREMENTS
============================================================

Every completed capability requires appropriate evidence.

Use:

unit tests
integration tests
end-to-end tests
adversarial tests
failure injection
recovery tests
persistence tests
authorization tests
provenance tests
restart tests
cold-boot tests
warm-restart tests
degraded-mode tests
migration tests
backup/restore tests
soak tests
performance benchmarks
security tests
regression tests

Do not run the entire expensive suite after every trivial edit.

Use:

focused test
→ relevant integration test
→ periodic broader suite
→ full certification suite at gates

This is critical for minimizing Codex credit usage.

============================================================
26. CREDIT-EFFICIENCY RULE
============================================================

Never spend implementation tokens before establishing that implementation is necessary.

For every proposed change:

1. locate
2. inspect
3. reproduce
4. identify smallest failing boundary
5. determine root cause
6. implement smallest correction
7. run focused verification
8. run relevant integration verification
9. update evidence
10. only then proceed

Do not:

- refactor unrelated code
- rewrite stable systems
- create duplicate abstractions
- build speculative architecture
- implement every documented future feature
- polish UI before core correctness
- generate giant documentation without new evidence
- repeatedly rediscover the repository
- repeatedly run expensive full suites without reason

Reuse existing architecture whenever it is structurally sound.

============================================================
27. BRANCH / GIT SAFETY
============================================================

Before implementation:

record:

git branch
git status
git HEAD
git diff
git diff --stat
git log -n appropriate range

Never assume the repository is clean.

Preserve the audited baseline.

Do not overwrite user work.

Do not reset unrelated changes.

Do not delete untracked evidence.

Do not commit runtime corruption artifacts.

The audit identified approximately 230 corruption/noise entries.

Keep runtime residue out of commits.

Pay particular attention to:

.git/info/exclude

because approximately 10 evidence test files are currently hidden by exclusions.

Do not accidentally commit implementation changes while leaving their proof hidden.

If evidence tests are intended to be part of the permanent certification surface, explicitly add them with:

git add -f

or remove the inappropriate exclusion.

Never make a production claim based on tests that are invisible to the repository's normal accounting.

============================================================
28. COMMIT STRATEGY
============================================================

Prefer small logically complete commits.

Suggested progression:

01-precommit-audit-baseline

02-gate-honesty-d-c-closure

03-dets-recovery-d-a12

04-test-isolation-and-durability

05-research-vertical-slice

06-constitutional-audit-durability

07-regression-topology-green

08-organism-single-trace

09-cis-recovery

10-production-profiles

11-production-hardening

12-certification

13-demo-personal-deployment

Names may change if repository conventions require it.

Each commit must have:

- clear purpose
- tests
- evidence
- no unrelated changes

Do not commit merely because a file changed.

============================================================
29. EVIDENCE LEDGER
============================================================

For every significant capability maintain:

Capability ID
Status
Claim
Implementation
Evidence
Tests
Runtime probe
Failure behavior
Known limitations
Unknowns
Dependencies
Commit
Date
Verification method

Statuses:

IMPLEMENTED
PARTIAL
STUB
THEATRICAL
UNVERIFIED
UNKNOWN
BROKEN
ABSENT-BY-DESIGN

Never use:

"basically implemented"
"production ready enough"
"should work"
"functionally complete"

unless backed by explicit evidence.

============================================================
30. STOP REPORT REQUIREMENT
============================================================

After every major wave produce a concise STOP REPORT containing:

STATUS

WHAT WAS VERIFIED

WHAT CHANGED

TESTS RUN

TEST RESULTS

RUNTIME PROBES

EVIDENCE CREATED

REMAINING FAILURES

REMAINING UNKNOWNs

SECURITY IMPLICATIONS

REGRESSION RISK

NEXT GATE

Do not hide failures.

Do not declare PASS if a required predicate is unknown.

============================================================
31. PRODUCTION CERTIFICATION
============================================================

Tiannara cannot be declared production-ready until all mandatory v1 predicates are executable.

Certification must prove:

BOOT
SUPERVISION
CONSTITUTION
GOVERNANCE
AUTHORIZATION
EFFECT IDENTITY
PROVENANCE
PERSISTENCE
RECOVERY
OBSERVABILITY
CIS
MISSION EXECUTION
RESEARCH VERTICAL SLICE
SOFTWARE ENGINEERING VERTICAL SLICE
SECURITY
FAIL-CLOSED BEHAVIOR
RESTART
COLD BOOT
WARM RESTART
DEGRADED MODE
BACKUP/RESTORE
REGRESSION
SOAK
PERFORMANCE
AUDIT DURABILITY

Certification result must be machine-readable.

Use:

PASS
FAIL
PARTIAL
UNVERIFIED
UNKNOWN

Production certification rule:

No critical FAIL.

No mandatory UNVERIFIED.

No hidden test exclusions.

No known theatrical success paths on the certified causal path.

No self-reported-only critical gate.

No consequential sink outside governed authorization.

No unresolved persistence failure on the certified path.

============================================================
32. DEMO CERTIFICATION
============================================================

After production certification, create one reproducible demonstration.

The demo must show the actual organism loop.

It should be possible for another person to observe:

objective
→ observation
→ reasoning
→ evidence
→ governance
→ authorization
→ action
→ result
→ provenance
→ knowledge update
→ health

The demo must use real runtime components.

Do not create a fake "demo mode" that bypasses the actual architecture.

============================================================
33. PERSONAL DEPLOYMENT
============================================================

Create a reproducible personal deployment path.

It must include:

installation
configuration
startup
health check
demo mission
shutdown
restart
backup
restore
logs
observability
safe mode
upgrade/migration
rollback

A fresh environment should be able to reproduce the documented result.

Record environmental prerequisites explicitly.

============================================================
34. FUTURE ARCHITECTURE
============================================================

Do NOT attempt to finish every future Tiannara concept during v1.

These may remain future/experimental if not required for the causal loop:

- civilization-scale intelligence
- universal multi-language ESAP
- full autonomous scientific discovery
- full symbolic mathematics
- SMT/proof ecosystem
- FEA/CFD
- unrestricted external world action
- years-long memory validation
- planetary-scale simulation
- generalized self-modification
- unrestricted autonomous software evolution
- broad robotics control
- full self-awareness claims
- speculative Kardashev-scale capabilities

Preserve the architecture for these capabilities.

Do not fake their completion.

The goal is a strong verified foundation, not a large list of unsupported claims.

============================================================
35. ENGINEERING PRINCIPLE
============================================================

Prefer:

one complete verified vertical slice

over:

ten incomplete subsystems.

Prefer:

real execution

over:

simulation.

Prefer:

measured behavior

over:

documentation.

Prefer:

fail-closed

over:

success-shaped uncertainty.

Prefer:

small reversible changes

over:

large rewrites.

Prefer:

reproducibility

over:

impressive one-off demonstrations.

Prefer:

traceability

over:

complexity.

Prefer:

human-governed autonomy

over:

unbounded autonomy.

============================================================
36. HUMAN AUTHORITY
============================================================

Tiannara augments human intelligence.

It does not replace human judgment.

The constitutional system must preserve:

- human veto
- authorization boundaries
- transparent evidence
- uncertainty
- auditability
- reversible operation where possible
- safe failure

Never silently broaden Tiannara's authority because a broader capability would make the demonstration more impressive.

============================================================
37. FINAL ACCEPTANCE TEST
============================================================

The project is complete for v1 only when an independent engineer can answer YES to all of the following:

Can Tiannara boot reproducibly?

Can its constitutional core be verified independently?

Can it distinguish real capability from unsupported capability?

Can it maintain durable audit evidence?

Can it recover from persistence faults?

Can it survive restart without silently regaining unauthorized authority?

Can authorization be traced from issuance to actual effect?

Can effect identity be traced to the exact consequential effect?

Can a stale/revoked/replayed authorization fail?

Can one bounded research mission complete the real scientific loop?

Can the resulting knowledge be traced to evidence?

Can Tiannara observe its own execution?

Can CIS detect and respond to real injected failures?

Can one bounded software-engineering task complete generation → build → test → execute → verify?

Can the complete organism loop be demonstrated with one trace?

Can the system fail safely when dependencies disappear?

Can its state be recovered after restart?

Can its production configuration be reproduced?

Can a fresh environment reproduce the demo?

Can an independent auditor reconstruct what happened from evidence?

Can every production claim be backed by executable evidence?

If any answer is NO, do not declare final production completion.

============================================================
38. FIRST ACTION
============================================================

Do NOT immediately modify code.

Begin with a fresh read-only reconciliation against the current repository.

Perform:

1. git status
2. git branch
3. git HEAD
4. repository topology
5. current test topology
6. current application boot topology
7. relevant files for B12/D-C
8. relevant files for D-A12
9. relevant files for D-A2/B11
10. relevant files for B5/D-A6
11. .git/info/exclude
12. existing evidence tests
13. current capability registry/census
14. current constitutional gates
15. current authorization/effect sinks

Then produce:

TIANNARA V1 CLOSURE BASELINE

with:

- verified current facts
- discrepancies against 2026-09-23 audit
- blocker dependency graph
- exact smallest next change
- expected evidence
- tests required
- risks

Do not implement until that baseline is complete.

============================================================
39. EXECUTION DISCIPLINE
============================================================

After each blocker:

REPRODUCE
→ DIAGNOSE
→ PATCH
→ TEST
→ PROBE
→ RECORD
→ REVIEW
→ COMMIT

If a fix reveals a deeper issue:

STOP.

Do not stack speculative fixes.

Update the evidence graph.

If a capability turns out to be more incomplete than documentation suggests:

downgrade its status.

If a capability is more complete than the audit suggests:

upgrade it only with fresh evidence.

If a subsystem is unnecessary for v1:

do not implement it merely because it exists in architecture documents.

============================================================
40. DEFINITION OF SUCCESS
============================================================

Success is NOT:

"all modules have code."

Success is NOT:

"all tests that were convenient pass."

Success is NOT:

"the Observatory looks complete."

Success is NOT:

"the architecture document is satisfied."

Success is:

Tiannara can perform a bounded, real, governed, observable, reproducible cognitive/scientific/engineering mission through its actual architecture, preserve evidence of what happened, recover from relevant failures, and honestly report what it can and cannot do.

The final system should be capable enough to demonstrate the organism concept while remaining scientifically and constitutionally honest.

============================================================
START NOW
============================================================

Begin with the read-only reconciliation.

Do not write code yet.

Do not refactor.

Do not install dependencies unless required merely to inspect/verify the existing system.

Do not spend tokens implementing speculative capabilities.

Return the:

TIANNARA V1 CLOSURE BASELINE

first.

Then wait for the next authorization gate before making implementation changes.
```