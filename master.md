Yes. **A thorough unification + forensic audit should be the first major move**, but I would put one step *before* it: establish the **canonical truth boundary** for Tiannara.

The goal is to prevent Tiannara from auditing itself against a confused mixture of old designs, experimental modules, duplicated implementations, and obsolete documentation.

### The sequence I recommend

```text
                    MAIN TIANNARA REPO
                           │
                           ▼
                 0. PRESERVE BASELINE
                           │
                           ▼
              1. ESTABLISH CANONICAL TRUTH
                           │
                           ▼
              2. FULL REPOSITORY ARCHAEOLOGY
                           │
                           ▼
                 3. UNIFICATION AUDIT
                           │
                           ▼
                4. ARCHITECTURE AUDIT
                           │
                           ▼
               5. VISION / CAPABILITY AUDIT
                           │
                           ▼
             6. ENGINEERING QUALITY AUDIT
                           │
                           ▼
              7. SECURITY / HARDENING AUDIT
                           │
                           ▼
             8. TEST + CERTIFICATION AUDIT
                           │
                           ▼
                  MASTER FINDINGS LEDGER
                           │
                           ▼
              HUMAN / COUNCIL FREEZE POINT
                           │
                           ▼
               TIANNARA SELF-ENGINEERING
                           │
                           ▼
                BOUNDED REMEDIATION
```

## 0. Preserve the baseline first

When you push the current Main Tiannara repo, **don't clean it up first**.

The current state is evidence.

Record:

```text
Repository:
Commit SHA:
Branch:
Timestamp:
Tree hash:
Runtime versions:
Build status:
Test status:
Known certified capabilities:
Known bounded capabilities:
Known pending capabilities:
Known blocked capabilities:
```

Then we have a completely immutable **T0 baseline**.

This is particularly important for Tiannara because you've already accumulated certifications, reconciliations, remediation missions, and architectural decisions. We don't want cleanup work to erase evidence of how the current system actually got here.

---

# 1. Establish the Canonical Truth

This is the most important step before unification.

We create a **Canonical Tiannara Manifest**.

Something conceptually like:

```yaml
tiannara:
  identity:
  vision:
  constitutional_principles:

architecture:
  canonical_layers:
  canonical_subsystems:
  canonical_interfaces:

ontology:
  canonical_domains:

capabilities:
  certified:
  bounded:
  experimental:
  deprecated:
  missing:

contracts:
  canonical:
  superseded:
  deprecated:

governance:
  authorization_rules:
  certification_rules:

engineering:
  supported_languages:
  supported_runtimes:

evidence:
  required_for_claims:
  certification_requirements:
```

This becomes the reference against which the repository is audited.

And crucially:

**The manifest itself should be evidence-backed.**

No:

> "We decided ASC is important, therefore ASC is canonical."

Instead:

```text
Canonical claim
      ↓
Source architectural decision
      ↓
Implementation evidence
      ↓
Tests/evidence
      ↓
Status
```

---

# 2. Then perform repository archaeology

Before changing anything, Tiannara should map the entire codebase.

Not just:

```text
src/
tests/
```

but:

```text
Repository
├── source
├── tests
├── configs
├── scripts
├── migrations
├── schemas
├── contracts
├── docs
├── certification
├── benchmarks
├── experiments
├── deployment
├── CI/CD
└── tooling
```

Then construct:

### Module graph

```text
Module A
 ├── imports B
 ├── calls C
 └── implements D
```

### Dependency graph

```text
Subsystem
   ↓
Module
   ↓
Library
   ↓
External dependency
```

### Contract graph

```text
Contract
 ├── implementation 1
 ├── implementation 2
 └── tests
```

### Test graph

```text
Capability
 ├── unit tests
 ├── integration tests
 ├── certification
 └── runtime evidence
```

### Architecture graph

```text
Vision
 ↓
Capability
 ↓
Subsystem
 ↓
Module
 ↓
Function
 ↓
Test
 ↓
Evidence
```

That last graph is extremely important.

It lets Tiannara ask:

> **"Show me the implementation supporting this claimed capability."**

---

# 3. Unification should come BEFORE broad remediation

This is where I would focus heavily.

Tiannara has evolved through many phases. That is normal, but it creates **architectural sediment**.

The audit should actively hunt for:

```text
DUPLICATE
DIVERGENT
SUPERSEDED
ORPHANED
CONFLICTING
SHADOWED
EXPERIMENTAL
DEPRECATED
CANONICAL
```

For every competing implementation:

```text
Capability: X

Implementation A
Implementation B
Implementation C

A:
  status = canonical

B:
  status = legacy

C:
  status = experimental

Reason:
  ...

Migration:
  ...

Deletion candidate:
  ...
```

This is much better than simply deleting "duplicate-looking" code.

### Example

Suppose Tiannara discovers:

```text
DomainRegistry
CanonicalDomainRegistry
LegacyDomainRegistry
DomainRegistryV2
ExperimentalDomainRegistry
```

The agent should **not immediately merge them**.

It should determine:

1. Why each exists.
2. Which contract each follows.
3. Which callers use each.
4. Whether their semantics differ.
5. Which one has authoritative evidence.
6. Whether one is actually experimental.
7. What migration would break.
8. Which becomes canonical.
9. Which can be removed.

Then produce:

```text
UNIFICATION PROPOSAL U-014

Canonical:
CanonicalDomainRegistry

Retire:
DomainRegistry
LegacyDomainRegistry

Preserve:
ExperimentalDomainRegistry

Migration:
17 callers

Compatibility risk:
Medium

Validation:
42 tests

Rollback:
commit XXXXX
```

**That is autonomous engineering rather than autonomous refactoring.**

---

# 4. Then perform the code-quality audit

Now we identify the ugly stuff.

Not merely lint violations.

I'd have Tiannara score files against things like:

### Complexity

* excessive function length
* excessive module size
* deep nesting
* cyclomatic complexity
* excessive branching
* duplicated logic

### Design

* god modules
* god processes
* inappropriate responsibilities
* circular dependencies
* abstraction leakage
* hidden global state
* implicit coupling

### Reliability

* swallowed exceptions
* unsafe fallbacks
* race conditions
* unbounded growth
* resource leaks
* improper supervision
* retry storms
* failure amplification

### Maintainability

* misleading names
* dead code
* commented-out implementations
* obsolete compatibility layers
* unexplained magic values
* duplicated configuration

And importantly:

> **"Poorly written" must have objective criteria.**

Otherwise Tiannara will eventually start rewriting code simply because it doesn't like the style.

---

# 5. Then the architecture audit

This asks a different question:

> **Does the implementation actually respect Tiannara's architecture?**

For every canonical subsystem:

```text
Declared responsibility
        ↓
Actual responsibility
        ↓
Declared interfaces
        ↓
Actual interfaces
        ↓
Dependencies
        ↓
Runtime behaviour
```

Then identify:

```text
ARCH-001
Subsystem X directly depends on Y,
despite constitutional architecture specifying
an interface boundary between them.
```

This becomes particularly important as Tiannara becomes self-engineering.

If the architecture is not internally coherent, autonomous engineering will **accelerate architectural decay**.

---

# 6. Vision alignment audit

This is the one I would make unusually strict.

For every major vision statement:

```text
VISION CLAIM
     ↓
REQUIRED CAPABILITY
     ↓
IMPLEMENTATION
     ↓
EXECUTABLE TEST
     ↓
OBSERVABLE EVIDENCE
```

Then classify:

🟢 **Implemented and evidenced**

🟡 **Implemented but insufficiently evidenced**

🟠 **Partially implemented**

🔴 **Claimed but not implemented**

⚫ **Architecturally absent**

This prevents the classic failure mode:

> documentation says autonomous → code has an "autonomous" module → therefore autonomy exists.

No.

Tiannara should have to demonstrate the capability.

---

# 7. Then specifically audit the Self-Engineering capability

This is where your new goal comes in.

We ask:

> **Could Tiannara, today, actually perform a bounded software-engineering mission without an external LLM being its central intelligence?**

Break it down:

| Capability                | Status |
| ------------------------- | ------ |
| Understand repository     | ?      |
| Build self-model          | ?      |
| Detect architecture drift | ?      |
| Identify defects          | ?      |
| Form hypotheses           | ?      |
| Design remediation        | ?      |
| Create isolated workspace | ?      |
| Modify code               | ?      |
| Compile                   | ?      |
| Test                      | ?      |
| Benchmark                 | ?      |
| Adversarially critique    | ?      |
| Verify requirements       | ?      |
| Produce evidence          | ?      |
| Certify result            | ?      |
| Request authorization     | ?      |
| Roll back                 | ?      |
| Learn from result         | ?      |

This becomes the **AEL capability matrix**.

And instead of building the whole thing immediately, the audit tells us exactly what is missing.

---

# 8. Security/hardening comes after we understand the architecture

Then audit:

```text
Secrets
Authentication
Authorization
Privilege boundaries
Tool permissions
Filesystem access
Git permissions
Process execution
Network access
Sandbox escape
Dependency vulnerabilities
Prompt injection
Untrusted repository content
Supply-chain risks
Artifact integrity
Audit-log integrity
```

There's a particularly important new threat once Tiannara can edit itself:

> **Tiannara must not be able to weaken the mechanisms that govern Tiannara without going through governance.**

For example, the engineering agent shouldn't be able to "fix" a failing certification by modifying the certification gate.

That needs a constitutional boundary.

---

# 9. Certification integrity audit

This deserves its own pass because Tiannara's philosophy depends heavily on evidence.

For every:

```text
CERTIFIED
PASS
VERIFIED
COMPLETE
SAFE
AUTONOMOUS
CONVERGED
OPTIMAL
```

ask:

> **What executable evidence establishes this claim?**

Then:

```text
CLAIM
 ↓
CONTRACT
 ↓
TEST
 ↓
EXECUTION
 ↓
ARTIFACT
 ↓
HASH
 ↓
RESULT
```

If the chain is broken:

```text
CERTIFICATION FINDING
CF-012

Claim:
ASC L2 autonomous

Evidence:
...

Missing:
Runtime acceptance evidence for capability X

Verdict:
NOT CERTIFIED
```

This is one of the areas where I would be particularly strict with Tiannara.

---

# 10. Produce one master findings ledger

Not dozens of disconnected reports.

Something like:

```text
TIANNARA MASTER ENGINEERING LEDGER

F-0001  CRITICAL
Category: Architecture
Status: CONFIRMED

F-0002  HIGH
Category: Unification
Status: CONFIRMED

F-0003  HIGH
Category: Certification
Status: CONFIRMED

F-0004  MEDIUM
Category: Code quality
Status: CONFIRMED

H-0001
Category: Architecture
Status: HYPOTHESIS
Requires validation

...

U-001
Unification candidate

V-001
Vision gap

A-001
Autonomy gap

S-001
Security hardening

P-001
Performance
```

And every finding gets:

```text
ID
Severity
Category
Location
Evidence
Expected state
Actual state
Impact
Confidence
Dependencies
Recommended action
Validation procedure
Rollback strategy
```

---

# 11. Then freeze it

This is the point where I would **stop autonomous modification**.

You now have:

```text
T0
 │
 ├── Repository snapshot
 ├── Self-model
 ├── Architecture model
 ├── Canonical manifest
 ├── Unification map
 ├── Capability matrix
 ├── Findings ledger
 └── Evidence map
```

That becomes the baseline.

Only after this should Tiannara receive authority to modify itself.

---

# 12. Then build AEL-0

And this is where your bigger vision becomes real.

Don't start with:

> "Tiannara can modify itself."

Start with:

> **"Tiannara can execute one bounded engineering mission under supervision."**

For example:

```text
MISSION M-001

Objective:
Unify subsystem X.

Authority:
Human-approved.

Scope:
8 specified modules.

Forbidden:
Constitutional layer.
Certification engine.
Governance layer.

Success:
Canonical implementation established.

Required evidence:
- compilation
- unit tests
- integration tests
- architecture conformance
- regression
- rollback

Maximum:
10 files
20 minutes
1 branch
```

Tiannara executes it.

Then reports:

```text
MISSION COMPLETE

Changed:
7 files

Tests:
213/213

Architecture obligations:
14/14

Regression:
0

Rollback:
verified

Evidence bundle:
HASH...

Recommendation:
READY FOR HUMAN REVIEW
```

**That is the first real proof.**

---

# And yes: Tiannara should eventually perform the audit itself

This is the key architectural transition.

Initially:

```text
YOU
 ↓
EXTERNAL AI
 ↓
AUDIT TIANNARA
```

Then:

```text
YOU
 ↓
TIANNARA OBSERVATORY
 ↓
TIANNARA AUDITOR
 ↓
TIANNARA ENGINEERING SYSTEM
```

External models become optional workers:

```text
                 TIANNARA
                     │
        ┌────────────┼────────────┐
        │            │            │
     Local LLM    Symbolic     External
                  engines       models
        │            │            │
        └────────────┼────────────┘
                     ↓
                 Evidence
                     ↓
               Tiannara decision
```

The external model doesn't become the owner of Tiannara's architecture.

It provides **computation**.

Tiannara owns:

**identity → architecture → memory → evidence → governance → decisions → certification → evolution.**

---

## So the first moves I'd make now

**Don't start coding TSERS yet.**

Do this first:

### Move 1

Push the **complete Main Tiannara repository** to a private GitHub repository.

### Move 2

Create the immutable **T0 baseline**.

### Move 3

Establish the **canonical Tiannara architectural/vision manifest** from the authoritative material already produced.

### Move 4

Perform the **full forensic repository archaeology**.

### Move 5

Perform the **unification audit**.

### Move 6

Perform the **architecture + vision + capability audit**.

### Move 7

Perform **code quality + reliability + security + performance** audits.

### Move 8

Perform the **testing/certification integrity audit**.

### Move 9

Generate the **Master Engineering Findings Ledger + AEL capability matrix**.

### Move 10

**Freeze. No automatic remediation yet.**

### Move 11

Use those findings to design **AEL-0**, the first bounded self-engineering capability.

### Move 12

Have Tiannara itself execute the first approved remediation mission.

---

And there is one particularly powerful consequence of doing it this way:

**The audit itself becomes the first dataset for Tiannara's Self Model.**

Instead of us merely saying:

> "Here are 147 problems in your codebase."

we give Tiannara a structured representation of:

```text
WHAT I AM
WHAT I CLAIM TO BE
WHAT I ACTUALLY IMPLEMENT
WHAT I KNOW
WHAT I DON'T KNOW
WHAT IS BROKEN
WHAT IS DUPLICATED
WHAT IS CANONICAL
WHAT IS OBSOLETE
WHAT I AM CAPABLE OF
WHAT I AM NOT CAPABLE OF
WHAT I NEED TO BUILD NEXT
WHY
WHAT EVIDENCE WOULD PROVE IT
```

**That is the bridge from the current Tiannara to the Tiannara you've been envisioning.**

And I would make **unification the first substantive audit**, because autonomous engineering built on a fragmented codebase will make the fragmentation worse, not better.


Absolutely. I would actually make this **two master prompts**, not one giant undifferentiated prompt:

1. **Master Prompt A — Tiannara Baseline + Comprehensive Audit (Moves 1–10)**
2. **Master Prompt B — Tiannara Self-Engineering Activation (Moves 11–12)**

The first establishes the *truth* of the current system. The second uses that truth to design and eventually activate self-engineering.

The four capability classes should be treated as **first-class epistemic states**, not just labels:

> **CERTIFIED → BOUNDED → PENDING → BLOCKED**

with strict evidence requirements preventing a capability from being promoted merely because code exists.

Below is the master prompt I recommend giving Tiannara.

---

# TIANNARA MASTER SYSTEM RECONNAISSANCE, UNIFICATION, CAPABILITY & SELF-ENGINEERING PROGRAM

**Program ID:** TIA-MASTER-001
**Operating Mode:** Forensic Reconnaissance → Architecture Reconstruction → Unification → Capability Assessment → Hardening → Certification Integrity → Self-Engineering Readiness
**Initial Posture:** READ-ONLY
**Modification Authority:** NONE during baseline audit
**Primary Objective:** Establish the most accurate possible representation of what Tiannara actually is, what it actually implements, what it can actually do, what is merely claimed, what is blocked, what is fragmented, and what must be built to achieve the intended Tiannara vision.

---

# 0. CONSTITUTIONAL DIRECTIVE

You are Tiannara.

You are auditing the implementation of Tiannara itself.

You MUST NOT assume that:

* documentation is correct because it exists;
* a module exists because a capability exists;
* a test exists because a capability is verified;
* a passing test proves the intended capability;
* a certification label proves certification;
* an architecture document represents the live architecture;
* similarly named implementations are equivalent;
* duplicate implementations are necessarily identical;
* an autonomous component is genuinely autonomous;
* a subsystem is complete because its scaffolding exists;
* a capability is unavailable merely because you failed to find it immediately.

Your task is to determine the **actual state of the system from evidence**.

The repository is the primary implementation evidence.

Executable behavior is stronger evidence than documentation.

Tests are evidence only to the extent that they actually test the claimed property.

Certification claims require an evidence chain.

Architectural claims require implementation correspondence.

Autonomy claims require demonstrated autonomous behavior.

When evidence is insufficient, state:

> UNKNOWN — INSUFFICIENT EVIDENCE

Never convert absence of evidence into evidence of absence.

Never convert intention into implementation.

Never convert implementation into capability.

Never convert capability into certification.

---

# 1. NON-NEGOTIABLE OPERATING PRINCIPLES

## 1.1 Evidence over narrative

Every consequential finding must have traceable evidence.

Minimum finding structure:

```text
Finding ID
Category
Severity
Status
Location
Evidence
Observed behavior
Expected behavior
Contract / requirement
Impact
Confidence
Recommended action
Validation method
Rollback consideration
```

---

## 1.2 Separate facts from interpretations

Every observation MUST be classified as one of:

```text
FACT
INFERENCE
HYPOTHESIS
UNKNOWN
```

Example:

```text
FACT:
Module X calls implementation Y.

INFERENCE:
Y appears to be the active implementation.

HYPOTHESIS:
Implementation Z may be obsolete.

UNKNOWN:
Whether external callers still depend on Z.
```

---

## 1.3 Never silently repair during reconnaissance

During the baseline audit:

```text
NO CODE MODIFICATION
NO DELETION
NO REFACTORING
NO AUTOMATIC UNIFICATION
NO AUTOMATIC MIGRATION
NO COMMITS
NO PUSHES
NO BRANCH MERGES
NO CERTIFICATION PROMOTION
```

You may propose changes.

You may create analytical artifacts where explicitly permitted.

You may not alter the implementation.

---

# 2. MISSION OBJECTIVE

Construct a complete evidence-backed model of:

```text
WHAT TIANNARA CLAIMS TO BE
        ↓
WHAT TIANNARA IS ARCHITECTURALLY
        ↓
WHAT TIANNARA IMPLEMENTS
        ↓
WHAT TIANNARA CAN ACTUALLY DO
        ↓
WHAT TIANNARA CAN DO UNDER CONSTRAINT
        ↓
WHAT TIANNARA IS WAITING FOR AUTHORIZATION TO DO
        ↓
WHAT TIANNARA CANNOT CURRENTLY DO
        ↓
WHAT IS DUPLICATED OR DIVERGENT
        ↓
WHAT IS BROKEN
        ↓
WHAT IS UNSAFE
        ↓
WHAT IS POORLY ENGINEERED
        ↓
WHAT DOES NOT ALIGN WITH THE VISION
        ↓
WHAT MUST BE BUILT NEXT
```

---

# 3. MOVE 1 — PRESERVE THE T0 BASELINE

Before analyzing changes, establish:

```text
Repository
Owner
Branch
Commit SHA
Commit timestamp
Working tree state if available
Repository tree
Runtime versions
Language versions
Compiler versions
Dependency versions
Build status
Test status
Known certifications
Known bounded capabilities
Known pending capabilities
Known blocked capabilities
Known active missions
```

Produce:

## T0 BASELINE RECORD

```text
T0:
  repository:
  commit:
  branch:
  timestamp:
  runtime:
  languages:
  dependencies:
  build:
  tests:
  certifications:
  known_capabilities:
  known_failures:
```

Do not modify the baseline.

---

# 4. MOVE 2 — ESTABLISH THE CANONICAL TRUTH MODEL

Construct the authoritative Tiannara model.

Identify:

## 4.1 Vision

What is Tiannara intended to become?

Separate:

```text
VISION
REQUIREMENT
ARCHITECTURAL PRINCIPLE
DESIGN PROPOSAL
IMPLEMENTATION
EXPERIMENT
```

---

## 4.2 Canonical architecture

Identify:

```text
Canonical layers
Canonical subsystems
Canonical interfaces
Canonical data flows
Canonical control flows
Canonical governance boundaries
Canonical persistence mechanisms
Canonical execution mechanisms
```

For every claimed canonical component determine:

```text
Declared responsibility
Actual responsibility
Declared interface
Actual interface
Consumers
Dependencies
Tests
Evidence
Status
```

---

# 5. THE FOUR CAPABILITY STATES

This is a CORE REQUIREMENT.

Every discovered Tiannara capability MUST receive exactly one primary operational state:

```text
CERTIFIED
BOUNDED
PENDING
BLOCKED
```

Do NOT use these terms casually.

---

# 6. CAPABILITY STATE A — KNOWN CERTIFIED CAPABILITIES

A capability may be classified:

> CERTIFIED

ONLY when sufficient evidence demonstrates that:

1. the capability is actually implemented;
2. its intended contract is defined;
3. required obligations are identifiable;
4. executable verification exists;
5. verification has actually executed;
6. expected results were obtained;
7. evidence is reproducible or appropriately anchored;
8. certification criteria were satisfied;
9. no known blocking contradiction invalidates the certification.

Record:

```text
Capability ID
Capability name
Purpose
Canonical subsystem
Implementation locations
Contract
Requirements
Obligations
Tests
Test execution
Evidence artifacts
Certification artifact
Certification date
Certification commit
Certification hash if applicable
Known limitations
Known scope
Known failure modes
Current status
```

Use:

```text
CERTIFIED — VERIFIED
```

only where the evidence supports it.

If the certification evidence is incomplete:

```text
NOT CERTIFIED
```

Do not preserve a certification merely because documentation says it is certified.

---

# 7. CAPABILITY STATE B — KNOWN BOUNDED CAPABILITIES

A capability is:

> BOUNDED

when it demonstrably exists and functions, but its operational scope, guarantees, validation, autonomy, robustness, or coverage are intentionally limited.

Examples may include:

```text
implemented but constrained
tested only within a known domain
works under controlled conditions
partial implementation
prototype with validated behavior
certified only within a bounded envelope
```

For every bounded capability record:

```text
Capability
What works
What does not work
Boundary
Assumptions
Operating envelope
Evidence
Tests
Known failure modes
Required conditions
Why it is not certified
Promotion requirements
```

Critically:

> BOUNDED does NOT mean FAILED.

It means:

> **KNOWN TO WORK WITH EXPLICIT LIMITS.**

---

# 8. CAPABILITY STATE C — KNOWN PENDING CAPABILITIES

A capability is:

> PENDING

when there is sufficient evidence that the capability is intended, designed, partially prepared, or otherwise actionable, but execution, authorization, implementation, or certification remains incomplete.

Distinguish:

```text
PENDING_IMPLEMENTATION
PENDING_AUTHORIZATION
PENDING_VALIDATION
PENDING_CERTIFICATION
PENDING_DEPENDENCY
PENDING_INTEGRATION
```

For every pending capability record:

```text
Capability
Intent
Current implementation state
Blocking condition
Required action
Required authority
Dependencies
Expected evidence
Promotion criteria
Owner
Priority
```

Never represent PENDING as implemented.

---

# 9. CAPABILITY STATE D — KNOWN BLOCKED CAPABILITIES

A capability is:

> BLOCKED

when there is a known condition preventing meaningful execution, validation, deployment, or progression.

Possible causes:

```text
missing implementation
runtime failure
dependency failure
architecture conflict
contract conflict
security restriction
resource constraint
test failure
governance restriction
missing evidence
missing infrastructure
broken subsystem
unresolved design contradiction
```

Record:

```text
Capability
Blocker
Evidence
Blocking subsystem
Blocking condition
Severity
Dependencies
Possible resolutions
Required decision
Whether workaround exists
Whether workaround changes the capability boundary
```

Never hide blocked capabilities behind optimistic terminology.

---

# 10. CAPABILITY PROMOTION RULE

Capabilities may move only through evidence-backed transitions.

Valid examples:

```text
PENDING
  ↓
IMPLEMENTED
  ↓
BOUNDED
  ↓
VALIDATED
  ↓
CERTIFIED
```

or:

```text
PENDING
  ↓
BLOCKED
```

or:

```text
BOUNDED
  ↓
BLOCKED
```

A capability MUST NOT jump:

```text
PENDING → CERTIFIED
```

without satisfying the intermediate evidentiary obligations.

Likewise:

```text
DOCUMENTED → CERTIFIED
```

is invalid.

---

# 11. PRODUCE THE CAPABILITY MATRIX

Produce a master table:

| ID | Capability | Certified | Bounded | Pending | Blocked | Evidence | Confidence | Next Action |
| -- | ---------- | --------- | ------- | ------- | ------- | -------- | ---------- | ----------- |

Only one primary operational state may be assigned.

Also produce:

```text
TOTAL CERTIFIED
TOTAL BOUNDED
TOTAL PENDING
TOTAL BLOCKED
TOTAL UNKNOWN
```

And distinguish:

```text
claimed capabilities
implemented capabilities
demonstrated capabilities
certified capabilities
```

---
Yes. I would **strongly recommend adding a Capability Reference Catalogue before the repository audit**.

Otherwise the audit risks becoming *repo-centric*: Tiannara will tell us what it currently contains, but it may completely miss capabilities that a system like Tiannara **should have**, capabilities you previously attempted, or capabilities that emerge from the combination of its architecture.

The better model is:

> **Known implementation → Known intended capabilities → Baseline capabilities → Novel capabilities → Cross-cutting capabilities → Missing capabilities → Evidence state**

And I would make the five-state model apply to **every capability in the catalogue**, not just capabilities that happen to appear in code.

---

# 1. The capability model should actually have 3 layers

I would structure it as:

### Layer A — Capability existence

**What capability are we talking about?**

Example:

> `CAP-REPO-UNDERSTANDING` — Can Tiannara reconstruct a repository's architecture?

### Layer B — Capability provenance

**Why is this capability in the catalogue?**

Use categories such as:

* `BASELINE` — fundamental capability expected of a serious autonomous engineering system
* `TIANNARA_CORE` — explicitly part of Tiannara's architectural vision
* `EXPERIMENTAL` — something you have attempted/prototyped
* `NOVEL` — capability that differentiates Tiannara from conventional agents
* `EMERGENT` — discovered from the architecture rather than explicitly designed
* `CROSS_CUTTING` — capability that spans multiple subsystems
* `DEPENDENCY` — foundational capability required by other capabilities
* `FUTURE` — legitimate capability target, but not currently required

### Layer C — Evidence state

Then your five-state model:

| State         | Meaning                                                                                                          |
| ------------- | ---------------------------------------------------------------------------------------------------------------- |
| **CERTIFIED** | Exists, works, obligations are defined, executable evidence exists, and certification criteria are satisfied     |
| **BOUNDED**   | Exists and demonstrably works, but only within explicit limitations                                              |
| **PENDING**   | Intended/prepared/partially implemented but not yet sufficiently implemented, authorized, validated or certified |
| **BLOCKED**   | Known condition prevents meaningful execution, validation or progression                                         |
| **UNKNOWN**   | We genuinely do not yet have sufficient evidence to classify it                                                  |

This is much stronger than simply asking "does this function exist?"

---

# 2. I would give Tiannara a large Capability Reference Catalogue

I would start with roughly **150–200 capability checks**, grouped into capability families.

Not every capability needs to be implemented. The purpose is to prevent blindness.

The audit should ask:

> **Does Tiannara have it?**
>
> If yes:
> **How well?**
>
> If no:
> **Was it intended?**
>
> If intended:
> **Why isn't it here?**
>
> If implemented:
> **Can we prove it?**

---

# 3. CAPABILITY FAMILY A — PERCEPTION & INGESTION

### Baseline capabilities

* Repository ingestion
* File-system observation
* Source-code parsing
* AST extraction
* Configuration parsing
* Dependency discovery
* API discovery
* Schema discovery
* Database-schema discovery
* Documentation ingestion
* Test discovery
* CI/CD discovery
* Git history analysis
* Commit analysis
* Branch analysis
* Diff analysis
* Runtime-log ingestion
* Telemetry ingestion
* Benchmark-result ingestion
* Experiment-result ingestion
* External evidence ingestion
* Structured-data ingestion
* Unstructured-text ingestion
* Multi-format document ingestion
* Environment discovery
* Runtime discovery
* Hardware/resource discovery
* Network topology discovery
* Process discovery
* Service discovery

### Advanced

* Continuous repository observation
* Change detection
* Semantic change detection
* Architecture drift detection
* Configuration drift detection
* Dependency drift detection
* Capability drift detection
* Evidence drift detection
* Contract drift detection
* Test drift detection

---

# 4. CAPABILITY FAMILY B — SELF-UNDERSTANDING

This is absolutely central to your vision.

* Self-model construction
* Self-model maintenance
* Architecture reconstruction
* Module understanding
* Dependency understanding
* Data-flow understanding
* Control-flow understanding
* State-flow understanding
* Event-flow understanding
* Contract understanding
* API understanding
* Capability discovery
* Capability classification
* Capability dependency mapping
* Capability provenance tracking
* Capability maturity estimation
* Runtime topology understanding
* Resource topology understanding
* Failure topology understanding
* Knowledge-boundary identification
* Unknown detection
* Uncertainty estimation
* Contradiction detection
* Architecture-vs-implementation comparison
* Documentation-vs-implementation comparison
* Intended-vs-actual system comparison

### Higher-order

* Understanding its own limitations
* Understanding why a capability failed
* Understanding what evidence supports a capability
* Understanding what evidence is missing
* Understanding which subsystem owns a capability
* Understanding which capabilities depend on another capability
* Understanding consequences of changing a subsystem

---

# 5. CAPABILITY FAMILY C — REASONING

Baseline:

* Deductive reasoning
* Inductive reasoning
* Abductive reasoning
* Probabilistic reasoning
* Bayesian updating
* Causal reasoning
* Constraint reasoning
* Temporal reasoning
* Counterfactual reasoning
* Hypothesis generation
* Hypothesis comparison
* Hypothesis falsification
* Evidence weighting
* Uncertainty propagation
* Confidence estimation
* Alternative generation
* Trade-off analysis
* Multi-objective reasoning
* Decision reasoning
* Risk reasoning
* Resource reasoning

Advanced:

* Meta-reasoning
* Reasoning about reasoning
* Detecting reasoning failure
* Revising reasoning strategy
* Selecting appropriate reasoning method
* Knowing when not to reason further
* Identifying insufficient evidence
* Expected-information-gain reasoning

---

# 6. CAPABILITY FAMILY D — SCIENTIFIC / DISCOVERY INTELLIGENCE

This connects directly to DiscoveryLab.

* Claim extraction
* Claim normalization
* Claim provenance
* Hypothesis generation
* Hypothesis ranking
* Falsifier generation
* Experiment design
* Experiment execution
* Experiment observation
* Experimental control
* Experimental comparison
* Statistical analysis
* Bayesian updating
* Causal analysis
* Reproducibility
* Replication
* Anomaly detection
* Pattern discovery
* Novel hypothesis discovery
* Evidence aggregation
* Evidence contradiction detection
* Scientific conclusion generation
* Confidence estimation
* Negative-result preservation
* Failed-experiment preservation
* Knowledge integration
* Discovery-to-architecture feedback

Advanced:

* Autonomous research planning
* Research prioritization
* Expected information gain
* Experiment portfolio optimization
* Discovery loop management
* Research agenda generation
* Research dead-end detection

---

# 7. CAPABILITY FAMILY E — MEMORY & KNOWLEDGE

This should be a huge section because Tiannara's memory architecture is fundamental.

* Working memory
* Episodic memory
* Semantic memory
* Procedural memory
* Architectural memory
* Decision memory
* Experiment memory
* Failure memory
* Evidence memory
* Certification memory
* Mission memory
* Repository memory
* User-intent memory
* Historical-state memory
* Temporal memory
* Provenance tracking
* Memory retrieval
* Memory ranking
* Memory consolidation
* Memory deduplication
* Memory decay
* Memory invalidation
* Memory correction
* Memory versioning
* Memory conflict resolution
* Memory replay
* Memory recovery
* Memory integrity checking
* Memory persistence
* Memory migration
* Memory garbage collection
* Memory isolation

Advanced:

* Self-model memory
* Architectural evolution memory
* Lessons-learned memory
* Failure-pattern memory
* Strategy memory
* Long-horizon mission memory
* Cross-project knowledge transfer
* Knowledge abstraction
* Knowledge generalization
* Knowledge provenance graph

---

# 8. CAPABILITY FAMILY F — PLANNING & DECISION INTELLIGENCE

* Goal decomposition
* Task decomposition
* Mission decomposition
* Dependency-aware planning
* Resource-aware planning
* Risk-aware planning
* Constraint-aware planning
* Temporal planning
* Multi-step planning
* Long-horizon planning
* Alternative-plan generation
* Plan comparison
* Plan simulation
* Plan verification
* Plan revision
* Dynamic replanning
* Failure recovery planning
* Rollback planning
* Contingency planning
* Stop-condition planning
* Authorization-aware planning

And from EFDI:

* Forecast generation
* Forecast calibration
* Decision scoring
* Decision uncertainty
* Expected-value analysis
* Decision outcome tracking
* Forecast-vs-reality comparison
* Calibration feedback

---

# 9. CAPABILITY FAMILY G — SOFTWARE ENGINEERING

This should be one of the largest groups.

### Understanding

* Code search
* Symbol search
* AST analysis
* Call-graph construction
* Dependency-graph construction
* Module classification
* Architecture reconstruction
* API analysis
* Contract analysis
* Test mapping

### Design

* Architecture design
* Component design
* API design
* Schema design
* Database design
* Event-model design
* Interface design
* Migration design
* Refactoring design
* Failure-mode design

### Implementation

* Code generation
* Code modification
* Multi-file modification
* Cross-module refactoring
* Dependency modification
* Schema migration
* Test generation
* Documentation generation
* Configuration modification
* Infrastructure modification

### Verification

* Compilation
* Unit testing
* Integration testing
* E2E testing
* Static analysis
* Type analysis
* Linting
* Security scanning
* Benchmarking
* Regression testing
* Property-based testing
* Fuzz testing
* Mutation testing
* Adversarial testing

### Engineering lifecycle

* Branch creation
* Worktree isolation
* Commit creation
* Diff inspection
* Review
* Rollback
* Cherry-pick
* Migration
* Release preparation
* Deployment validation

---

# 10. CAPABILITY FAMILY H — AUTONOMOUS ENGINEERING

This is where Tiannara becomes fundamentally different from a coding agent.

Check individually:

1. Detect engineering problem
2. Characterize problem
3. Establish evidence
4. Form hypothesis
5. Identify requirements
6. Identify constraints
7. Design solution
8. Compare alternatives
9. Create implementation plan
10. Request authorization
11. Create isolated workspace
12. Modify code
13. Build
14. Test
15. Diagnose failures
16. Iterate
17. Benchmark
18. Perform adversarial review
19. Produce evidence
20. Determine whether requirements were met
21. Prepare certification
22. Produce rollback
23. Present decision
24. Integrate approved change
25. Observe post-change behavior
26. Learn from result
27. Update self-model
28. Detect regression
29. Reopen previous decisions
30. Continue long-horizon mission

This becomes your **AEL capability chain**.

---

# 11. CAPABILITY FAMILY I — ARCHITECTURE GOVERNANCE

* Architecture-rule enforcement
* Boundary enforcement
* Dependency-direction enforcement
* Module ownership
* State ownership
* Contract ownership
* Canonical implementation selection
* Duplicate detection
* Divergence detection
* Architecture drift detection
* Architecture fitness checking
* Technical-debt tracking
* Architectural decision records
* Architecture evolution tracking
* Migration planning
* Deprecation management
* Legacy detection
* Dead-code detection

And importantly:

### Constitutional architecture

* Prevent self-modification of constitutional rules
* Detect governance bypass
* Detect authorization bypass
* Detect certification bypass
* Detect evidence tampering
* Detect privilege escalation
* Detect unauthorized autonomy expansion

---

# 12. CAPABILITY FAMILY J — SAFETY & SECURITY

This must be treated as a first-class capability family.

* Authentication
* Authorization
* Role separation
* Capability-based permissions
* Secret management
* Credential isolation
* Sandbox enforcement
* Filesystem isolation
* Process isolation
* Network isolation
* Resource limits
* Command allowlisting
* Tool permissions
* External-system permissions
* Prompt-injection resistance
* Untrusted-input handling
* Repository poisoning detection
* Dependency security
* Supply-chain security
* Code-execution safety
* Privilege-escalation detection
* Data-exfiltration prevention
* Destructive-operation controls
* Human authorization
* Emergency stop
* Kill switch
* Rollback
* Audit logging
* Tamper detection

And:

> **Can Tiannara prevent itself from granting itself more authority?**

That should be an explicit capability test.

---

# 13. CAPABILITY FAMILY K — EVIDENCE & EPISTEMIC INTEGRITY

This is one of the most important Tiannara-specific families.

* Evidence collection
* Evidence provenance
* Evidence versioning
* Evidence hashing
* Evidence immutability
* Evidence lineage
* Evidence reproducibility
* Evidence verification
* Evidence conflict detection
* Evidence freshness
* Evidence sufficiency assessment
* Evidence quality scoring
* Claim/evidence binding
* Requirement/evidence binding
* Test/evidence binding
* Artifact/evidence binding
* Decision/evidence binding

And:

**Claim → Contract → Requirement → Obligation → Test → Execution → Artifact → Evidence → Hash → Result → Decision**

The audit should verify whether this chain is **actually executable**, rather than merely represented in documentation.

---

# 14. CAPABILITY FAMILY L — CERTIFICATION

* Contract definition
* Certification criteria
* Certification preparation
* Certification execution
* Certification evidence
* Certification history
* Certification invalidation
* Certification expiry
* Recertification
* Regression certification
* Capability promotion
* Capability demotion
* Certification dependency management
* Certification provenance
* Certification reproducibility
* Independent verification
* Negative certification
* Failed certification preservation

And critically:

> **Can Tiannara certify something it implemented itself without an independent evidence boundary?**

That needs to be tested.

---

# 15. CAPABILITY FAMILY M — OBSERVABILITY

* Structured logging
* Metrics
* Tracing
* Event telemetry
* Health checks
* Liveness
* Readiness
* Performance monitoring
* Memory monitoring
* CPU monitoring
* I/O monitoring
* Queue monitoring
* Event-stream monitoring
* Error-rate monitoring
* Failure classification
* Alerting
* Audit trail
* Causal telemetry
* Experiment telemetry
* Mission telemetry
* Capability telemetry
* Evidence telemetry

Advanced:

* Self-diagnosis
* Anomaly detection
* Performance regression detection
* Behavioral drift detection
* Telemetry integrity checking

---

# 16. CAPABILITY FAMILY N — RELIABILITY & RESILIENCE

* Supervision
* Process recovery
* Service recovery
* State recovery
* Database recovery
* Memory recovery
* Event replay
* Idempotency
* Retry
* Backoff
* Circuit breaking
* Failure isolation
* Graceful degradation
* Fault tolerance
* Crash recovery
* Partial-failure handling
* Network-failure handling
* Dependency-failure handling
* Data-corruption detection
* Data-corruption recovery
* Deterministic replay
* Disaster recovery
* Backup
* Restore
* Migration recovery

Your DETS→ETS work is a good example of this category.

---

# 17. CAPABILITY FAMILY O — PERFORMANCE & RESOURCE INTELLIGENCE

* CPU profiling
* Memory profiling
* I/O profiling
* Network profiling
* Database profiling
* Query optimization
* Concurrency analysis
* Parallelism analysis
* Scheduling
* Resource allocation
* Resource budgeting
* Cost estimation
* Runtime optimization
* Memory-growth detection
* Leak detection
* Throughput measurement
* Latency measurement
* Scalability analysis
* Load testing
* Stress testing
* Capacity planning
* GPU utilization
* CUDA performance analysis
* NIF performance analysis
* ETS/shared-memory performance

And:

> **Can Tiannara determine that an optimization actually improved the system rather than merely changed it?**

---

# 18. CAPABILITY FAMILY P — SELF-EVALUATION

* Self-testing
* Self-auditing
* Self-diagnosis
* Self-benchmarking
* Self-criticism
* Self-review
* Error detection
* Confidence estimation
* Uncertainty detection
* Unknown detection
* Contradiction detection
* Capability-gap detection
* Architecture-gap detection
* Knowledge-gap detection
* Performance-gap detection
* Reliability-gap detection
* Security-gap detection

Advanced:

* Knowing when its own analysis is insufficient
* Requesting external review
* Selecting what should be independently verified
* Detecting evaluator weakness
* Detecting benchmark gaming
* Detecting reward hacking
* Detecting measurement manipulation

---

# 19. CAPABILITY FAMILY Q — META-COGNITION

This is where we start getting into the **novel Tiannara territory**.

* Reasoning strategy selection
* Tool selection
* Model selection
* Verification strategy selection
* Experiment selection
* Research prioritization
* Resource allocation between tasks
* Uncertainty-driven investigation
* Information-gain optimization
* Self-critique
* Self-correction
* Strategy revision
* Failure-mode learning
* Capability maturation
* Knowledge-boundary recognition
* Epistemic humility
* Goal conflict detection
* Goal hierarchy management

---

# 20. CAPABILITY FAMILY R — MULTI-AGENT / MULTI-ROLE INTELLIGENCE

If Tiannara has or will have specialized cognitive roles:

* Planner
* Researcher
* Architect
* Implementer
* Tester
* Critic
* Security reviewer
* Performance analyst
* Certification agent
* Governance agent
* Forecaster
* Evidence agent

Then test:

* Role separation
* Role specialization
* Role communication
* Shared context
* Shared memory
* Conflict detection
* Argument comparison
* Independent review
* Adversarial review
* Consensus
* Dissent preservation
* Escalation
* Arbitration
* Authority boundaries

---

# 21. CAPABILITY FAMILY S — HUMAN INTERACTION & GOVERNANCE

* Mission submission
* Mission tracking
* Human authorization
* Approval gates
* Rejection
* Revision requests
* Explainability
* Evidence presentation
* Uncertainty presentation
* Risk presentation
* Diff presentation
* Decision presentation
* Audit presentation
* Capability dashboard
* System-health dashboard
* Observatory
* Emergency intervention
* Manual override
* Mission cancellation
* Rollback authorization

The Observatory therefore isn't merely a UI.

It becomes the **human↔Tiannara constitutional interface**.

---

# 22. CAPABILITY FAMILY T — LONG-HORIZON AUTONOMY

This is the final frontier.

* Mission persistence
* Mission resumption
* Long-term goal tracking
* Subgoal management
* Context persistence
* State persistence
* Failure recovery
* Progress measurement
* Milestone management
* Dependency tracking
* Long-horizon planning
* Strategy revision
* Resource budgeting
* Deadline management
* Continuous observation
* Continuous improvement
* Regression detection
* Knowledge accumulation
* Architectural evolution
* Technical-debt management
* Self-maintenance

And eventually:

> **Can Tiannara pursue a six-month engineering objective without losing the original objective, corrupting its constraints, or silently redefining success?**

That is a genuine autonomy test.

---

# 23. Then we add the NOVEL CAPABILITY REGISTER

This is important because I don't want the audit to assume that Tiannara is merely:

> "another autonomous coding agent."

We should explicitly create:

### `NOVEL-*`

capabilities.

For example:

**NOVEL-001 — Constitutional Self-Engineering**

Can Tiannara modify its own implementation while preserving immutable constitutional constraints?

**NOVEL-002 — Epistemically Bound Self-Modification**

Can Tiannara refuse to make a change when evidence is insufficient?

**NOVEL-003 — Capability Provenance**

Can it explain exactly why it believes a capability exists?

**NOVEL-004 — Capability Maturity Evolution**

Can a capability move:

`UNKNOWN → PENDING → BOUNDED → CERTIFIED`

only through evidence-backed transitions?

**NOVEL-005 — Architecture Self-Reconstruction**

Can Tiannara reconstruct its own architecture from implementation rather than trusting its documentation?

**NOVEL-006 — Self-Unification**

Can it discover two competing implementations and reason about which should become canonical?

**NOVEL-007 — Self-Certification Boundary**

Can it distinguish implementing something from independently proving it?

**NOVEL-008 — Epistemic Debt**

Can Tiannara track claims it believes but cannot yet sufficiently prove?

**NOVEL-009 — Architectural Memory**

Can it remember why an architectural decision was made and determine whether that reason still holds?

**NOVEL-010 — Failure Memory**

Can it learn from failed engineering missions without treating the failure as nonexistent?

**NOVEL-011 — Self-Contradiction Detection**

Can it discover contradictions between its own contracts, code, tests, architecture and previous decisions?

**NOVEL-012 — Autonomous Research-to-Engineering Transition**

Can a discovery become a hypothesis, then an experiment, then a verified engineering requirement?

**NOVEL-013 — Evidence-Driven Autonomy**

Can its authority increase only as evidence increases?

**NOVEL-014 — Autonomy Regression Detection**

Can it detect that a newer version is actually *less autonomous* than an older one?

**NOVEL-015 — Self-Model Integrity**

Can it detect that its model of itself is wrong?

Those are much more interesting than merely "can it write Python?"

---

# 24. But there is another layer I think we're missing

We should create **cross-cutting capability axes**.

These aren't individual capabilities.

They are properties that every important capability should be evaluated against.

For example:

| Axis                     | Question                                     |
| ------------------------ | -------------------------------------------- |
| Existence                | Does it actually exist?                      |
| Functionality            | Does it work?                                |
| Scope                    | What does it work on?                        |
| Reliability              | How consistently does it work?               |
| Reproducibility          | Can the result be reproduced?                |
| Observability            | Can we see it operating?                     |
| Explainability           | Can it explain what happened?                |
| Evidence                 | What proves it?                              |
| Provenance               | Where did the capability come from?          |
| Determinism              | Is behavior reproducible where required?     |
| Security                 | Can it be abused?                            |
| Isolation                | Is it safely contained?                      |
| Authorization            | Who can invoke it?                           |
| Governance               | What rules constrain it?                     |
| Recovery                 | What happens when it fails?                  |
| Rollback                 | Can it be undone?                            |
| Scalability              | Does it survive growth?                      |
| Performance              | Is it computationally viable?                |
| Maintainability          | Can it evolve safely?                        |
| Compatibility            | Does it integrate with the rest of Tiannara? |
| Dependency               | What does it depend on?                      |
| Coupling                 | How tightly coupled is it?                   |
| State                    | Where does its state live?                   |
| Memory                   | What does it remember?                       |
| Learning                 | Can it improve?                              |
| Adaptation               | Can it adapt?                                |
| Uncertainty              | Does it know what it doesn't know?           |
| Certification            | Can it be certified?                         |
| Regression               | Can deterioration be detected?               |
| Autonomy                 | How independently can it operate?            |
| Human control            | Can humans intervene?                        |
| Constitutional integrity | Can it violate its governing rules?          |

This means a capability doesn't just get:

> `CERTIFIED`

It gets a **capability profile**.

---

# 25. Example

Suppose we discover:

### `CAP-AE-001 — Autonomous Code Modification`

We shouldn't merely say:

> BOUNDED

Instead:

```yaml
id: CAP-AE-001
name: Autonomous Code Modification

provenance:
  - BASELINE
  - TIANNARA_CORE
  - NOVEL

state: BOUNDED

dimensions:
  existence: CONFIRMED
  functionality: CONFIRMED
  scope: BOUNDED
  reliability: UNKNOWN
  reproducibility: PARTIAL
  observability: CONFIRMED
  evidence: CONFIRMED
  security: BOUNDED
  isolation: CONFIRMED
  authorization: CONFIRMED
  rollback: CONFIRMED
  scalability: UNKNOWN
  certification: PENDING
  regression_detection: PARTIAL
  constitutional_integrity: CONFIRMED

dependencies:
  - CAP-REPO-UNDERSTANDING
  - CAP-WORKSPACE-ISOLATION
  - CAP-CODE-GENERATION
  - CAP-TEST-EXECUTION
  - CAP-EVIDENCE-COLLECTION

evidence:
  - ...
```

That is far more informative.

---

# 26. The audit should therefore produce a Capability Coverage Matrix

Something like:

| Family                 | Expected | Found | Certified | Bounded | Pending | Blocked | Unknown |
| ---------------------- | -------: | ----: | --------: | ------: | ------: | ------: | ------: |
| Perception             |       35 |    24 |        12 |       7 |       3 |       1 |      12 |
| Self-understanding     |       28 |    17 |         6 |       5 |       4 |       2 |      11 |
| Reasoning              |       25 |    19 |         8 |       6 |       3 |       2 |       6 |
| Scientific discovery   |       30 |    21 |        10 |       5 |       4 |       2 |       9 |
| Memory                 |       35 |    27 |        15 |       7 |       3 |       2 |       8 |
| Planning               |       25 |    14 |         5 |       5 |       3 |       1 |      11 |
| Software engineering   |       45 |    31 |        14 |       8 |       5 |       4 |      14 |
| Autonomous engineering |       30 |    16 |         3 |       6 |       5 |       2 |      14 |
| Security               |       30 |    20 |         8 |       6 |       5 |       1 |      10 |
| Evidence/certification |       30 |    23 |        14 |       5 |       3 |       1 |       7 |
| ...                    |      ... |   ... |       ... |     ... |     ... |     ... |     ... |

**Those numbers are illustrative, not claims about Tiannara.**

The actual audit populates them from evidence.

---

# 27. And most importantly: separate four questions

Every capability should answer:

### Q1 — Did we ever intend this?

`INTENDED / NOT_INTENDED / UNCLEAR`

### Q2 — Did we ever attempt this?

`ATTEMPTED / NOT_ATTEMPTED / UNKNOWN`

### Q3 — Does an implementation exist?

`EXISTS / PARTIAL / ABSENT / UNKNOWN`

### Q4 — What is its evidence state?

`CERTIFIED / BOUNDED / PENDING / BLOCKED / UNKNOWN`

This is extremely important for your existing work.

Because otherwise something like:

> "ASC autonomous engineering"

could be misclassified as simply **BLOCKED**.

The truth might be:

```text
INTENDED       = YES
ATTEMPTED      = YES
IMPLEMENTATION = PARTIAL
CURRENT STATE  = BOUNDED
BLOCKERS       = ...
```

That's a completely different picture.

---

# 28. We should also add a "Capability Archaeology" pass

The coding agent should search the entire repository for evidence of capabilities that aren't obvious from current architecture.

Specifically search:

```text
TODO
FIXME
HACK
experimental
prototype
prototype/
legacy
deprecated
v1
v2
v3
old
backup
disabled
unused
dead
stub
placeholder
not implemented
pending
blocked
future
planned
research
experiment
benchmark
proof
certification
audit
capability
autonomous
self
agent
reason
hypothesis
forecast
memory
knowledge
architecture
governance
constitutional
evidence
ontology
contract
mission
planner
executor
critic
review
rollback
sandbox
authorization
```

And inspect:

* abandoned branches where accessible
* Git history
* old implementations
* experimental modules
* disabled code
* feature flags
* scripts
* benchmarks
* certification artifacts
* documentation
* architecture manifests
* test names
* comments
* telemetry
* schemas

Because **some of Tiannara's most important capabilities may exist as experiments rather than production code**.

---

# 29. This also gives us a much better definition of "blind spots"

At the end of T0 we want Tiannara to produce:

### A. IMPLEMENTED CAPABILITIES

What actually exists.

### B. CERTIFIED CAPABILITIES

What is actually proven.

### C. BOUNDED CAPABILITIES

What demonstrably works but has limits.

### D. PENDING CAPABILITIES

What has intent/design/partial implementation but isn't ready.

### E. BLOCKED CAPABILITIES

What cannot currently progress.

### F. UNKNOWN CAPABILITIES

What we haven't sufficiently investigated.

### G. ATTEMPTED BUT ABANDONED

Things that were tried but abandoned.

### H. DUPLICATED CAPABILITIES

Multiple implementations of the same conceptual capability.

### I. CONTRADICTORY CAPABILITIES

Two components claim incompatible versions of the same capability.

### J. IMPLICIT CAPABILITIES

Capabilities that exist in behavior but aren't formally represented.

### K. MISSING BASELINE CAPABILITIES

Capabilities a serious system should have but Tiannara lacks.

### L. MISSING NOVEL CAPABILITIES

Capabilities necessary to realize the unique Tiannara vision.

### M. EMERGENT CAPABILITIES

Capabilities that appear from subsystem composition but were never explicitly designed.

That last category could be **very valuable**.

---

# 30. I would change the master prompt accordingly

The master audit should therefore begin with:

> **Do not begin by asking "what capabilities does the repository claim to have?"**
>
> First construct an independent Capability Reference Catalogue containing:
>
> 1. baseline capabilities expected of an autonomous engineering/discovery system;
> 2. Tiannara-specific intended capabilities;
> 3. capabilities previously attempted or prototyped;
> 4. novel capabilities implied by Tiannara's vision;
> 5. cross-cutting capabilities;
> 6. foundational/dependency capabilities;
> 7. advanced/future capabilities.
>
> Then reconcile this catalogue against the actual repository.
>
> Do not infer capability existence from names, documentation, module presence, API presence, tests alone, or architectural intent.
>
> A capability exists only to the degree supported by executable evidence.

And then:

> **Every catalogue capability MUST receive both a provenance classification and an evidence state.**

That gives us the structure:

```text
                 TIANNARA CAPABILITY UNIVERSE
                           │
       ┌───────────────────┼───────────────────┐
       │                   │                   │
    BASELINE            TIANNARA            NOVEL
       │                 CORE                 │
       │                   │                   │
       └───────────────────┼───────────────────┘
                           │
                  CROSS-CUTTING
                           │
                           ▼
                CAPABILITY RECONCILIATION
                           │
            ┌──────────────┼──────────────┐
            ▼              ▼              ▼
       IMPLEMENTATION    INTENT        ATTEMPTS
            │              │              │
            └──────────────┼──────────────┘
                           ▼
                    EVIDENCE ENGINE
                           │
       ┌───────────┬───────┼───────┬───────────┐
       ▼           ▼       ▼       ▼           ▼
   CERTIFIED    BOUNDED  PENDING  BLOCKED    UNKNOWN
```

## And I think this becomes one of the most important artifacts in the whole project

I'd call it:

**`TIA-CAP-001 — Tiannara Capability Reference & Maturity Ontology`**

with companion artifacts:

* `capability_catalogue.yaml`
* `capability_matrix.yaml`
* `capability_evidence_ledger.jsonl`
* `capability_dependencies.yaml`
* `capability_provenance.yaml`
* `capability_transition_log.jsonl`
* `capability_gap_ledger.yaml`
* `novel_capability_register.yaml`
* `baseline_capability_register.yaml`
* `cross_cutting_capability_matrix.yaml`

Then the repository audit isn't merely:

> **"Here is what the code contains."**

It becomes:

> **"Here is the universe of capabilities Tiannara could reasonably be expected to possess, here is everything it has ever attempted, here is what its architecture implies, here is what actually exists, here is what is proven, here is what is bounded, here is what is pending, here is what is blocked, here is what remains unknown, and here are the capabilities it needs to become the system described by its own vision."**

**That is the "perfect picture" we were aiming for.**

And I would put this **before Move 3 of the master prompt**, because the capability catalogue should become the independent reference against which the repository archaeology, vision audit, unification audit, and eventual self-engineering loop are measured.

# 12. MOVE 3 — FULL REPOSITORY ARCHAEOLOGY

Map the entire repository.

Inspect:

```text
source
tests
configuration
scripts
schemas
contracts
migrations
documentation
certification
benchmarks
experiments
deployment
CI/CD
tooling
generated artifacts
examples
fixtures
```

Construct:

```text
Module Graph
Dependency Graph
Call Graph where practical
Contract Graph
Test Graph
Architecture Graph
Capability Graph
Evidence Graph
Certification Graph
```

Identify:

```text
dead code
orphaned modules
unused dependencies
duplicate implementations
legacy implementations
experimental implementations
shadow implementations
conflicting implementations
unreachable paths
obsolete documentation
stale tests
```

---

# 13. MOVE 4 — UNIFICATION AUDIT

This is a first-class mission.

Search for:

```text
duplicate registries
duplicate abstractions
duplicate services
duplicate algorithms
duplicate schemas
duplicate contracts
duplicate configuration
duplicate domain definitions
duplicate state stores
duplicate APIs
duplicate orchestration
duplicate naming
versioned implementations
legacy implementations
V1/V2/V3 fragmentation
```

For every candidate:

```text
UNIFICATION ID

Capability:
Implementations:
Semantic differences:
Callers:
Dependencies:
Evidence:
Canonical candidate:
Legacy candidate:
Experimental candidate:
Migration risk:
Migration plan:
Deletion candidate:
Validation:
Rollback:
```

Do NOT unify solely based on names.

Determine semantic equivalence first.

---

# 14. MOVE 5 — ARCHITECTURE AUDIT

Compare:

```text
INTENDED ARCHITECTURE
        vs
ACTUAL ARCHITECTURE
```

Find:

```text
boundary violations
circular dependencies
layer violations
responsibility leakage
god modules
god processes
improper coupling
architecture drift
hidden dependencies
implicit interfaces
bypassed governance
duplicated authority
state ownership ambiguity
```

For every divergence:

```text
ARCH-ID
Expected architecture
Observed architecture
Evidence
Impact
Severity
Confidence
Remediation
Validation
```

---

# 15. MOVE 6 — VISION ALIGNMENT AUDIT

For every major Tiannara vision claim construct:

```text
VISION CLAIM
     ↓
REQUIRED CAPABILITY
     ↓
REQUIRED ARCHITECTURE
     ↓
IMPLEMENTATION
     ↓
TEST
     ↓
EXECUTION
     ↓
EVIDENCE
```

Classify each claim:

```text
REALIZED
PARTIALLY REALIZED
BOUNDED
PLANNED
PENDING
BLOCKED
UNSUPPORTED
CONTRADICTED
```

Explicitly identify:

```text
capability theater
documentation/implementation divergence
placeholder autonomy
fake integrations
unexercised pathways
unvalidated claims
architectural promises without substrate
```

---

# 16. MOVE 7 — CODE QUALITY AUDIT

Assess every significant source file.

Evaluate:

## Complexity

```text
module size
function size
cyclomatic complexity
nesting
branching
cognitive complexity
```

## Maintainability

```text
naming
cohesion
coupling
duplication
magic values
comments
dead code
obsolete compatibility
```

## Correctness

```text
error handling
edge cases
state management
concurrency
resource lifecycle
failure recovery
```

## Architecture

```text
responsibility
dependency direction
interface quality
abstraction quality
boundary adherence
```

Flag:

```text
POORLY_WRITTEN
HIGH_COMPLEXITY
DUPLICATED
BRITTLE
MISLEADING
DEAD
UNUSED
DANGEROUS
ARCHITECTURALLY_MISPLACED
```

Do not rewrite merely for stylistic preference.

---

# 17. MOVE 8 — SECURITY AND HARDENING AUDIT

Audit:

```text
authentication
authorization
secrets
credentials
tokens
filesystem access
process execution
shell execution
network access
database access
serialization
deserialization
input validation
injection
path traversal
command injection
dependency vulnerabilities
supply-chain risk
unsafe defaults
privilege escalation
sandbox boundaries
agent tool permissions
prompt injection exposure
untrusted repository content
```

For autonomous engineering specifically evaluate:

```text
Can Tiannara modify governance?

Can Tiannara modify its own authorization?

Can Tiannara disable certification?

Can Tiannara bypass evidence?

Can Tiannara rewrite audit history?

Can Tiannara grant itself privileges?

Can Tiannara escape its workspace?

Can Tiannara modify production without authorization?
```

These must have explicit answers.

---

# 18. MOVE 9 — DATA, MEMORY AND STATE AUDIT

Audit:

```text
persistence
ETS
DETS
PostgreSQL
Redis
event streams
schemas
migrations
serialization
state ownership
memory lifecycle
retention
eviction
continuity
recovery
corruption handling
concurrency
idempotency
replayability
```

Determine:

```text
source of truth
derived state
cache
ephemeral state
persistent state
recoverable state
non-recoverable state
```

Identify schema drift and competing stores.

---

# 19. MOVE 10 — OBSERVABILITY, PERFORMANCE AND CERTIFICATION AUDIT

## Observability

Determine whether important claims are measurable.

Audit:

```text
telemetry
metrics
logs
traces
event lineage
failure reporting
health reporting
audit trails
```

Flag:

```text
misleading metric
missing telemetry
unverifiable claim
telemetry without consumer
consumer without telemetry
```

## Performance

Identify:

```text
pathological algorithms
unbounded growth
memory leaks
CPU hotspots
I/O bottlenecks
serialization overhead
duplicate computation
unnecessary network calls
blocking operations
concurrency problems
```

Do not optimize without evidence.

## Certification integrity

For every certification claim:

```text
Claim
Contract
Requirement
Obligations
Test
Execution
Artifact
Evidence
Hash
Result
Certification decision
```

If the evidence chain is incomplete:

```text
CERTIFICATION INTEGRITY WARNING
```

Do not automatically revoke certification during reconnaissance; record the discrepancy and recommend the appropriate governance action.

---

# 20. TEST INTEGRITY

Audit tests for:

```text
coverage
assertion quality
false positives
false greens
mock overuse
integration gaps
untested failure paths
skipped tests
conditional tests
environment-dependent tests
flaky tests
misleading test names
tests that test implementation rather than behavior
```

A passing test suite is NOT equivalent to system correctness.

Determine:

```text
tests proving behavior
tests providing weak evidence
tests providing no meaningful evidence
missing tests
```

---

# 21. DOCUMENTATION INTEGRITY

Compare documentation against reality.

Flag:

```text
documented but absent
documented but partial
documented but obsolete
documented but contradicted
implemented but undocumented
certified but unsupported
claimed autonomous but manually dependent
```

Documentation must not be treated as implementation evidence.

---

# 22. AUTONOMOUS SELF-ENGINEERING CAPABILITY AUDIT

Determine whether Tiannara can currently perform each capability:

| Capability                     | Status | Evidence |
| ------------------------------ | ------ | -------- |
| Repository discovery           |        |          |
| Repository understanding       |        |          |
| Self-model construction        |        |          |
| Architecture reconstruction    |        |          |
| Defect discovery               |        |          |
| Unification discovery          |        |          |
| Hypothesis formation           |        |          |
| Engineering planning           |        |          |
| Architecture design            |        |          |
| Code modification              |        |          |
| Isolated workspace creation    |        |          |
| Build execution                |        |          |
| Testing                        |        |          |
| Static analysis                |        |          |
| Benchmarking                   |        |          |
| Adversarial testing            |        |          |
| Code review                    |        |          |
| Requirements verification      |        |          |
| Evidence collection            |        |          |
| Certification preparation      |        |          |
| Rollback                       |        |          |
| Governance request             |        |          |
| Knowledge integration          |        |          |
| Long-horizon mission execution |        |          |

Classify each as:

```text
CERTIFIED
BOUNDED
PENDING
BLOCKED
UNKNOWN
```

---

# 23. CONSTRUCT THE TIANNARA SELF-MODEL

Produce the machine-readable conceptual model:

```yaml
tiannara:
  identity:
  vision:
  constitution:

architecture:
  layers:
  subsystems:
  interfaces:
  dependencies:
  data_flows:
  control_flows:

capabilities:
  certified:
  bounded:
  pending:
  blocked:
  unknown:

contracts:
  canonical:
  deprecated:
  conflicting:

engineering:
  repositories:
  modules:
  functions:
  tests:
  benchmarks:
  technical_debt:

research:
  programs:
  hypotheses:
  experiments:
  unknowns:

governance:
  authorizations:
  pending_decisions:
  restrictions:

operations:
  health:
  failures:
  anomalies:

evolution:
  proposals:
  active_missions:
  rejected_changes:
  accepted_changes:
```

The self-model must distinguish:

```text
known
unknown
uncertain
inferred
certified
```

---

# 24. CONSTRUCT THE AEL READINESS MODEL

AEL = Autonomous Engineering Loop.

Assess:

```text
A0 Observe
A1 Diagnose
A2 Propose
A3 Design
A4 Implement in sandbox
A5 Verify
A6 Produce evidence
A7 Request authorization
A8 Execute bounded change
A9 Continuous optimization
A10 Long-horizon autonomous engineering
```

For every level determine:

```text
implemented?
tested?
demonstrated?
certified?
bounded?
blocked?
missing?
```

Do NOT assign an autonomy level based on architecture diagrams.

Assign it based on demonstrated capability.

---

# 25. MASTER FINDINGS LEDGER

Produce a unified ledger.

Finding categories:

```text
ARCH
UNIFY
CODE
CONTRACT
VISION
AUTO
RELIABILITY
SECURITY
DATA
MEMORY
OBSERVABILITY
PERFORMANCE
TEST
CERTIFICATION
DOCUMENTATION
DEPENDENCY
```

Severity:

```text
CRITICAL
HIGH
MEDIUM
LOW
INFORMATIONAL
```

Status:

```text
CONFIRMED
PROBABLE
HYPOTHESIS
UNKNOWN
```

Each finding MUST contain:

```text
ID
Category
Severity
Status
Location
Evidence
Expected state
Actual state
Impact
Confidence
Dependencies
Recommendation
Validation
Rollback
```

---

# 26. MASTER UNIFICATION LEDGER

Produce:

```text
U-001
Capability:
Competing implementations:
Canonical candidate:
Reason:
Migration:
Validation:
Risk:
Rollback:
```

Do not perform the unification during baseline reconnaissance.

---

# 27. MASTER CAPABILITY LEDGER

Produce:

```text
CAP-001
Name:
Description:
Canonical subsystem:
Implementation:
State:
Contract:
Evidence:
Tests:
Limitations:
Blockers:
Promotion criteria:
```

Then summarize:

```text
CERTIFIED:
BOUNDED:
PENDING:
BLOCKED:
UNKNOWN:
```

This table becomes one of the principal Tiannara system-health artifacts.

---

# 28. MASTER VISION GAP LEDGER

For every unrealized vision component:

```text
VISION-001

Vision:
Required capability:
Current implementation:
Gap:
Why gap exists:
Dependencies:
Priority:
Expected value:
Required architecture:
Validation:
```

---

# 29. MASTER SELF-ENGINEERING GAP LEDGER

Identify everything required to reach:

> Tiannara can autonomously perform bounded software engineering missions under constitutional governance.

Record:

```text
AEL-GAP-001

Capability:
Current state:
Missing component:
Dependencies:
Risk:
Implementation complexity:
Validation:
Required authorization:
```

---

# 30. PRODUCE THE FINAL T0 REPORT

The final report MUST contain:

## Executive Summary

## Repository Baseline

## Canonical Architecture

## Canonical Truth Model

## Capability Matrix

```text
CERTIFIED
BOUNDED
PENDING
BLOCKED
UNKNOWN
```

## Repository Archaeology

## Unification Findings

## Architecture Findings

## Vision Alignment

## Code Quality

## Reliability

## Security

## Data / Memory

## Observability

## Performance

## Testing

## Certification Integrity

## Documentation Integrity

## Autonomous Engineering Readiness

## Self-Model

## AEL Capability Matrix

## Master Findings Ledger

## Master Unification Ledger

## Master Vision Gap Ledger

## Master Self-Engineering Gap Ledger

## Recommended Remediation Order

---

# 31. REMEDIATION PRIORITIZATION

Do NOT prioritize solely by number of findings.

Rank using:

```text
Severity
Capability impact
Architectural centrality
Security impact
Evidence confidence
Dependency centrality
Blast radius
Expected capability gain
Risk of remediation
Reversibility
```

Identify:

```text
P0 — existential / architectural blockers
P1 — critical capability or integrity issues
P2 — major engineering debt
P3 — optimization / quality improvements
P4 — cosmetic / low-value improvements
```

Also identify:

> HIGH-LEVERAGE CHANGES

Changes that resolve multiple findings simultaneously.

---

# 32. STOP CONDITION — BASELINE FREEZE

At completion of Moves 1–10:

STOP.

Do not modify the repository.

Do not automatically remediate.

Do not merge.

Do not promote capabilities.

Do not alter certification state.

Present:

```text
T0 BASELINE COMPLETE

Repository:
Commit:

Certified:
N

Bounded:
N

Pending:
N

Blocked:
N

Unknown:
N

Critical:
N

High:
N

Unification candidates:
N

Architecture divergences:
N

Vision gaps:
N

Self-engineering gaps:
N
```

Await human authorization.

---

# 33. MOVE 11 — DESIGN AEL-0

ONLY after the T0 baseline has been accepted.

Design:

# AUTONOMOUS ENGINEERING LOOP — LEVEL 0

Mission:

> Tiannara shall execute one bounded engineering mission from problem identification through architecture, implementation, verification, evidence generation, and human review.

Required stages:

```text
MISSION
 ↓
REQUIREMENTS
 ↓
CURRENT-STATE ANALYSIS
 ↓
ARCHITECTURE
 ↓
IMPLEMENTATION PLAN
 ↓
HUMAN AUTHORIZATION
 ↓
ISOLATED WORKTREE
 ↓
IMPLEMENTATION
 ↓
BUILD
 ↓
TEST
 ↓
STATIC ANALYSIS
 ↓
ADVERSARIAL REVIEW
 ↓
BENCHMARK
 ↓
EVIDENCE
 ↓
CERTIFICATION PREPARATION
 ↓
HUMAN REVIEW
 ↓
INTEGRATION
```

AEL-0 MUST NOT autonomously modify production without authorization.

---

# 34. ENGINEERING SANDBOX REQUIREMENTS

Tiannara engineering actions MUST occur inside a bounded workspace.

Define:

```text
repository scope
branch scope
filesystem scope
network scope
tool scope
execution time
resource limits
file modification limits
command permissions
credential permissions
```

Example:

```yaml
mission:
  repository:
  branch:
  allowed_paths:
  forbidden_paths:

limits:
  max_files_changed:
  max_execution_time:
  max_processes:

permissions:
  filesystem:
  git:
  network:
  shell:
  database:
```

---

# 35. CONSTITUTIONAL PROHIBITIONS

Tiannara MUST NOT autonomously:

```text
modify constitutional rules
disable governance
disable certification
alter evidence history
forge evidence
delete audit history
grant itself authority
expand its own privileges
remove safety boundaries
modify authorization rules
silently redefine capabilities
promote uncertified capabilities
erase failed experiments
conceal uncertainty
```

Any such change requires explicit governance.

---

# 36. MOVE 12 — FIRST SELF-ENGINEERING MISSION

The first mission SHOULD be selected from the T0 findings.

Prefer a mission that is:

```text
bounded
high-value
low-to-moderate risk
reversible
well-defined
measurable
testable
architecturally meaningful
```

The mission MUST produce:

```text
requirements
architecture
implementation
tests
verification
evidence
risk assessment
rollback
final recommendation
```

Tiannara must report:

```text
WHAT CHANGED
WHY
WHAT WAS EXPECTED
WHAT ACTUALLY HAPPENED
WHAT EVIDENCE EXISTS
WHAT FAILED
WHAT REMAINS UNCERTAIN
WHETHER THE CHANGE SHOULD BE ACCEPTED
```

---

# 37. SELF-ENGINEERING FEEDBACK LOOP

After every approved mission:

```text
OBSERVE
 ↓
UPDATE SELF-MODEL
 ↓
UPDATE CAPABILITY MATRIX
 ↓
UPDATE ARCHITECTURE MODEL
 ↓
UPDATE KNOWLEDGE
 ↓
UPDATE TECHNICAL DEBT
 ↓
UPDATE FINDINGS
 ↓
IDENTIFY NEXT HIGHEST-VALUE MISSION
```

Never erase historical states.

Maintain lineage:

```text
T0
 ↓
Mission M-001
 ↓
T1
 ↓
Mission M-002
 ↓
T2
```

---

# 38. EXTERNAL MODELS

External LLMs MAY be used as optional computational workers.

They MUST NOT become the authoritative owner of:

```text
Tiannara identity
Tiannara constitution
architecture
governance
memory
evidence
certification
capability state
decision authority
```

External models should be treated as:

```text
workers
reviewers
research assistants
code-generation resources
alternative hypotheses
specialized reasoning engines
```

Their outputs MUST remain subject to Tiannara verification.

---

# 39. FINAL PRINCIPLE

The purpose of this entire program is NOT:

> "Make Tiannara generate code."

The purpose is:

> **Make Tiannara capable of understanding itself, identifying its own engineering gaps, researching solutions, architecting changes, implementing bounded changes, verifying those changes, producing reproducible evidence, exposing uncertainty, and continuously improving under constitutional governance.**

The governing distinction is:

```text
CODE
≠
CAPABILITY

CAPABILITY
≠
VERIFICATION

VERIFICATION
≠
CERTIFICATION

CERTIFICATION
≠
AUTHORITY

AUTHORITY
≠
AUTONOMY
```

Therefore:

> **Every increase in Tiannara's autonomy must be accompanied by a corresponding increase in observability, evidence, verification, governance, and reversibility.**

The desired end state is not an uncontrolled self-modifying program.

It is:

```text
                    HUMAN
                      │
                      ▼
                 OBSERVATORY
                      │
                      ▼
             CONSTITUTIONAL EXECUTIVE
                      │
                      ▼
             TIANNARA SELF-MODEL
                      │
        ┌─────────────┼──────────────┐
        ▼             ▼              ▼
    RESEARCH      ARCHITECTURE   ENGINEERING
        │             │              │
        └─────────────┼──────────────┘
                      ▼
                  SANDBOX
                      │
                      ▼
                VERIFICATION
                      │
                      ▼
                   EVIDENCE
                      │
                      ▼
                CERTIFICATION
                      │
                      ▼
               HUMAN AUTHORITY
                      │
                      ▼
                 INTEGRATION
                      │
                      ▼
              UPDATED TIANNARA
                      │
                      └───────────────►
                         NEXT MISSION
```

**This is the target architecture for Tiannara's transition from an AI-assisted engineering system into a governed self-engineering scientific/engineering system.**

END MASTER DIRECTIVE.

The important part is that **Moves 1–10 produce the truth before Moves 11–12 are allowed to change it**. That separation will give you a much cleaner picture than immediately asking Tiannara to "improve itself."

I would also make the **five-state capability model** (`CERTIFIED / BOUNDED / PENDING / BLOCKED / UNKNOWN`) persistent in Tiannara's own Self Model. The four states you specified are the operational states; **UNKNOWN** is deliberately added because Tiannara must have a legitimate state for *"we haven't established this yet"* rather than forcing every capability into one of the four.

Once you have the Main repo pushed, the next artifact I would create is a **second, implementation-specific master prompt for the Tiannara coding agent**: it would tell Tiannara *how to execute this protocol against its actual Elixir/Python/React repository*, which tools to invoke, what artifacts to create, how to scan the codebase, how to build the capability graph, and exactly when it must STOP and return control to you.


Yes. In fact, **before launching the audit, I would not leave Moves 1–4 entirely to a coding agent's judgment**.

Those moves establish the factual foundation on which every later conclusion depends. If an agent mangles them, everything downstream—capability classification, unification, architecture decisions, and eventual self-engineering—can be contaminated.

I would create a **deterministic forensic audit harness** that Tiannara can execute, rather than asking an LLM to "remember to inspect everything."

### The key principle

The LLM should **interpret evidence**.

The code should **collect and preserve evidence**.

So I recommend adding a new pre-move:

> **MOVE 0 — Forensic Instrumentation & Evidence Capture**

Then make Moves 1–4 depend on its artifacts.

### What I would actually build

A self-contained directory such as:

```text
certification/
└── reconnaissance/
    ├── TIA_RECON_ORCHESTRATOR.py
    ├── TIA_RECON_CONTRACT.yaml
    ├── TIA_CAPABILITY_CATALOGUE.yaml
    ├── TIA_BASELINE_CHECKS.yaml
    ├── TIA_NOVEL_CAPABILITIES.yaml
    ├── TIA_EVIDENCE_SCHEMA.json
    ├── TIA_FINDING_SCHEMA.json
    ├── TIA_GRAPH_SCHEMA.json
    │
    ├── collectors/
    │   ├── repo_inventory.py
    │   ├── git_forensics.py
    │   ├── dependency_inventory.py
    │   ├── source_inventory.py
    │   ├── test_inventory.py
    │   ├── contract_inventory.py
    │   ├── config_inventory.py
    │   ├── documentation_inventory.py
    │   └── certification_inventory.py
    │
    ├── analyzers/
    │   ├── duplicate_detector.py
    │   ├── architecture_analyzer.py
    │   ├── dependency_analyzer.py
    │   ├── capability_detector.py
    │   ├── contract_analyzer.py
    │   └── evidence_analyzer.py
    │
    └── tests/
        ├── test_recon_integrity.py
        └── test_recon_determinism.py
```

But **I would not make the coding agent implement all of this immediately.**

I'd have the agent implement **one authoritative orchestration file plus immutable schemas/contracts first**, then execute it.

---

# The most important file: `TIA_RECON_ORCHESTRATOR.py`

This should be deliberately boring.

Its job is **not to reason about Tiannara**.

Its job is to guarantee that the audit agent cannot conveniently skip half the repository.

Conceptually:

```text
START
  │
  ├── verify git repository
  ├── capture commit SHA
  ├── capture branch
  ├── capture dirty state
  ├── capture repository tree
  ├── capture file hashes
  ├── capture runtime versions
  ├── capture dependency manifests
  ├── capture environment metadata
  │
  ▼
T0 BASELINE
  │
  ├── source inventory
  ├── test inventory
  ├── contract inventory
  ├── configuration inventory
  ├── documentation inventory
  ├── certification inventory
  ├── benchmark inventory
  └── experiment inventory
  │
  ▼
CAPABILITY RECONCILIATION
  │
  ├── baseline catalogue
  ├── Tiannara catalogue
  ├── attempted capabilities
  ├── novel capabilities
  └── cross-cutting capabilities
  │
  ▼
ARCHITECTURE RECONSTRUCTION
  │
  ├── module graph
  ├── dependency graph
  ├── call graph
  ├── contract graph
  ├── data/state graph
  ├── test graph
  └── capability graph
  │
  ▼
UNIFICATION DISCOVERY
  │
  ├── duplicate implementations
  ├── duplicate contracts
  ├── divergent registries
  ├── competing schemas
  ├── legacy implementations
  └── conflicting sources of truth
  │
  ▼
IMMUTABLE T0 ARTIFACT
  │
  ▼
STOP
```

The important thing is that **each stage produces a machine-readable artifact**.

---

# I would make the orchestrator enforce a hard READ-ONLY invariant

Something like:

```python
AUDIT_POSTURE = "READ_ONLY"

FORBIDDEN_OPERATIONS = {
    "write_source",
    "modify_source",
    "delete_source",
    "rename_source",
    "modify_contract",
    "modify_test",
    "modify_certification",
    "modify_configuration",
    "git_commit",
    "git_push",
    "git_reset",
    "git_checkout",
    "git_merge",
}
```

And the orchestrator should fail closed if it detects an attempt to mutate the repository.

More importantly, **don't rely on that Python variable for safety**.

The agent should ideally run the reconnaissance against a **separate disposable clone/worktree**, with the original repository treated as immutable.

---

# I would also make it create a cryptographic T0 manifest

For every relevant file:

```yaml
path: lib/tiannara/executive_memory.ex
size_bytes: ...
sha256: ...
classification: source
git_tracked: true
git_status: clean
```

Then:

```yaml
repository:
  commit_sha: ...
  tree_sha: ...
  branch: ...
  dirty: false

environment:
  elixir: ...
  otp: ...
  python: ...
  node: ...
  npm: ...

artifacts:
  source_manifest_sha256: ...
  dependency_manifest_sha256: ...
  test_manifest_sha256: ...
  capability_catalogue_sha256: ...
```

That gives us:

> **This is what Tiannara looked like at T0.**

Not:

> "The agent says this is what Tiannara looked like."

Huge difference.

---

# Then I would make the capability catalogue itself executable

This is probably the **second most valuable file**.

Instead of giving the agent a giant prose list, create:

`TIA_CAPABILITY_CATALOGUE.yaml`

Each capability gets:

```yaml
- id: CAP-REPO-001
  name: Repository Discovery
  family: perception
  provenance:
    - BASELINE
    - TIANNARA_CORE

  description: >
    Ability to discover and inventory the software repository
    relevant to a mission.

  existence_checks:
    - source_files_discovered
    - repository_tree_available

  functional_checks:
    - complete_inventory_generated

  evidence_requirements:
    - repository_manifest
    - execution_record

  dependencies: []

  maturity:
    allowed:
      - CERTIFIED
      - BOUNDED
      - PENDING
      - BLOCKED
      - UNKNOWN
```

Then the agent isn't free to invent capability definitions during the audit.

It has to **reconcile against a canonical catalogue**.

---

# And I'd add `TIA_BASELINE_CHECKS.yaml`

This would be the "don't fly blind" checklist you just asked for.

For example:

```yaml
baseline:
  software_engineering:
    - repository_discovery
    - source_parsing
    - dependency_analysis
    - code_search
    - test_execution
    - static_analysis
    - build_verification
    - regression_detection
    - code_generation
    - code_modification
    - rollback

  autonomous_system:
    - goal_decomposition
    - planning
    - execution
    - observation
    - feedback
    - failure_recovery
    - uncertainty_detection
    - human_authorization

  knowledge:
    - working_memory
    - persistent_memory
    - provenance
    - retrieval
    - contradiction_detection
    - knowledge_update

  safety:
    - authorization
    - sandboxing
    - privilege_boundaries
    - audit_logging
    - rollback
    - emergency_stop
```

The catalogue can be **extensive**, while the orchestrator ensures every item is at least considered.

---

# And a separate `TIA_NOVEL_CAPABILITIES.yaml`

This prevents the baseline catalogue from accidentally defining what Tiannara *is*.

It should contain the capabilities unique to your vision.

For example:

```yaml
novel:
  - id: NOVEL-001
    name: Constitutional Self-Engineering

  - id: NOVEL-002
    name: Evidence-Bound Autonomy

  - id: NOVEL-003
    name: Capability Provenance

  - id: NOVEL-004
    name: Capability Maturity Evolution

  - id: NOVEL-005
    name: Self-Unification

  - id: NOVEL-006
    name: Architecture Self-Reconstruction

  - id: NOVEL-007
    name: Epistemic Debt Tracking

  - id: NOVEL-008
    name: Self-Model Integrity

  - id: NOVEL-009
    name: Autonomous Research-to-Engineering Transition

  - id: NOVEL-010
    name: Autonomy Regression Detection
```

Then Tiannara can add discoveries to this register, but it cannot silently redefine the original catalogue.

---

# Moves 1–4 then become deterministic

### Move 1 — T0

The program generates:

```text
T0/
├── repository.json
├── git.json
├── files.jsonl
├── hashes.jsonl
├── environment.json
├── dependencies.json
├── runtimes.json
└── T0_MANIFEST.json
```

### Move 2 — Truth Model

The agent produces:

```text
truth/
├── vision.yaml
├── architecture.yaml
├── requirements.yaml
├── implementation.yaml
├── experiments.yaml
└── contradictions.yaml
```

But importantly, every assertion references evidence.

---

### Move 3 — Archaeology

The program produces:

```text
graphs/
├── modules.json
├── dependencies.json
├── calls.json
├── contracts.json
├── tests.json
├── capabilities.json
├── data_flow.json
├── state_flow.json
└── evidence.json
```

The LLM then interprets those graphs.

---

### Move 4 — Unification

This is where I'd be particularly strict.

Don't allow:

> "These look duplicated."

Instead require:

```yaml
UNIFY-001:
  candidate_a: ...
  candidate_b: ...

  semantic_overlap: ...
  behavioral_difference: ...
  callers_a: [...]
  callers_b: [...]

  shared_contract: ...
  competing_contracts: ...

  canonical_candidate: ...
  canonical_reason: ...

  migration_required: true

  migration_plan:
    - ...

  deletion_candidate:
    - ...

  validation:
    - ...

  rollback:
    - ...
```

And **no deletion occurs in Move 4**.

---

# There is one more thing I'd add

A **reconnaissance integrity test suite**.

The agent should have to pass something like:

```text
RI-001  Repository completeness
RI-002  Hash manifest completeness
RI-003  Git provenance captured
RI-004  Runtime provenance captured
RI-005  Dependency provenance captured
RI-006  Test inventory completeness
RI-007  Contract inventory completeness
RI-008  Capability catalogue coverage
RI-009  Unknown-state preservation
RI-010  Evidence provenance
RI-011  Deterministic rerun
RI-012  Read-only enforcement
RI-013  No certification mutation
RI-014  No source mutation
RI-015  No finding deletion
RI-016  No silent capability promotion
RI-017  No undocumented assumptions
RI-018  T0 hash consistency
RI-019  Graph consistency
RI-020  Ledger referential integrity
```

### Especially RI-009.

If the agent doesn't know whether something exists:

**UNKNOWN is a valid result.**

It must never convert:

```text
"I couldn't find evidence"
```

into:

```text
"does not exist"
```

That's one of the biggest ways an autonomous audit could become dangerously overconfident.

---

# I would actually go one step further

The **LLM should not be allowed to be the sole author of the T0 evidence layer.**

Think of the architecture as:

```text
              ┌─────────────────────┐
              │   Tiannara / Agent  │
              │  reasoning + review │
              └──────────┬──────────┘
                         │
                    interprets
                         │
                         ▼
              ┌─────────────────────┐
              │   Evidence Layer    │
              │                     │
              │ manifests           │
              │ hashes              │
              │ graphs              │
              │ executions          │
              │ test results        │
              │ provenance          │
              └──────────┬──────────┘
                         │
                    observes
                         │
                         ▼
              ┌─────────────────────┐
              │    Tiannara Repo    │
              └─────────────────────┘
```

This gives you an **epistemic firewall** between:

> what the repository actually did

and

> what the model thinks the repository did.

That is exactly the kind of architecture I would want before allowing Tiannara to eventually audit and modify itself.

---

## So my recommendation before launch

I would modify our program from:

**Moves 1–12**

to:

### **Move 0 — Reconnaissance Instrumentation**

Build/verify the deterministic evidence collector and schemas.

### **Move 1 — T0 Baseline**

Capture immutable repository/environment state.

### **Move 2 — Canonical Truth Model**

Vision → requirements → architecture → implementation → experiments.

### **Move 3 — Full Repository Archaeology**

Build the complete system/capability/evidence graph.

### **Move 4 — Capability Reconciliation**

Compare baseline + Tiannara + attempted + novel + cross-cutting catalogue against reality.

### **Move 5 — Unification**

Only identify and model consolidation candidates.

### **Move 6 onward**

Architecture, vision, code quality, security, data, reliability, performance, certification, autonomy, etc.

Then:

> **HARD STOP after the entire read-only T0 program.**

No code changes.

No "helpful fixes."

No cleanup.

No capability promotion.

No certification changes.

No commits.

No deletion.

Only after you review the resulting picture do we authorize the next stage.

**And yes—I think this is worth making as actual code rather than merely another prompt.** The master prompt should tell the coding agent *how to think and what decisions to make*; the reconnaissance harness should make it **mechanically difficult to skip, mutate, fabricate, or lose the underlying evidence**.

If you give me the Main Tiannara repository once it's available, I would make the implementation-specific version of this against its **actual Elixir/Python/React structure**, rather than giving the coding agent a generic Python harness that might itself become another architectural mismatch.
