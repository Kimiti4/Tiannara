# Tiannara Architecture Quick Reference

## The Unified Hierarchy

```
Tiannara OS
│
├── Tiannara Core (Mind)           ← Decides WHAT, WHY
│   ├── Identity
│   ├── Cognition
│   ├── Goal System
│   ├── Meta-Cognition (domain governor)
│   └── GRCC Identity Ecology (organisms)
│
├── Tiannara Domain Cortex (Cortex) ← Specialized reasoning
│   ├── Temporal, Combinatorial, Reverse Engineering
│   ├── Causal, Prediction, Logic, Algorithm, NLP
│   ├── Meta-Cognition (governor), Collective Intelligence
│   ├── Creative Synthesis, Social Intelligence
│   ├── Ethical Reasoning, Embodied Cognition
│
├── AEO (Bridge)                    ← Translates intent to execution
│   ├── translate_intent()
│   ├── assemble_domain_team()
│   └── submit_to_runtime()
│
├── Tiannara Runtime (Body)         ← HOW it happens
│   ├── GRCC Environment (pressures, niches)
│   ├── CIS (constraint provider)
│   ├── HSV, CTL, OCM (regulation)
│   ├── OED (validation, constitutional)
│   └── OPC (physics)
│
└── Tiannara Products (Economy)    ← Commercialization
    └── API → AEO → Core
```

---

## Who Decides What?

| Question                       | Owner          | Answer                                              |
| ------------------------------ | -------------- | --------------------------------------------------- |
| **What should happen?**        | Core           | "Design a trading strategy"                         |
| **Why should it happen?**      | Core           | "To maximize ROI with ethical constraints"          |
| **What outcome is desired?**   | Core           | "Strategy with 20%+ return, <5% risk"               |
| **Which domains to use?**      | Meta-Cognition | "Prediction 35%, Temporal 25%, Algorithm 20%..."    |
| **Is plan constitutional?**    | OED            | "Yes, all validation passed"                        |
| **Are constraints respected?** | CIS            | "Yes, domain diversity maintained"                  |
| **How do we execute?**         | Runtime        | "Execute with domain team on distributed mesh"      |
| **Did it work?**               | Runtime        | "Strategy complete, feedback: specialization gains" |

---

## Core Responsibility Map

### Core OWNS

- ✅ Identity (self-model, values, preferences)
- ✅ Cognition (reasoning, planning, learning)
- ✅ Goals (executive intent)
- ✅ GRCC Organisms (lineages, specialization)
- ✅ Memory (long-term)

### Core DOES NOT OWN

- ❌ Execution (Runtime)
- ❌ Scheduling (Runtime)
- ❌ Environmental pressure (Runtime GRCC)
- ❌ Resource constraints (Runtime GRCC)
- ❌ Domain implementations (Domain Cortex)

---

## Request Flow

```
1. Products receives request (SaaS API)
   ↓
2. AEO translates to Core intent
   ↓
3. Core generates decision + rationale
   ↓
4. Meta-Cognition selects domains
   ↓
5. AEO assembles domain team
   ↓
6. CIS validates diversity
   ↓
7. OED validates constitution
   ↓
8. Runtime executes with domains
   ↓
9. Feedback collected
   ↓
10. Core updates state
   ↓
11. API returns result
```

---

## Module Import Quick Start

```elixir
# Get Core instance
core = Tiannara.Core.new("tiannara_1")

# Create identity
identity = Tiannara.Identity.new("id_1", %{
  self_model: %{role: "reasoner"},
  goals: ["learn", "improve"],
  values: %{ethics: 0.9}
})

# Get domain list
domains = Tiannara.DomainCortex.domains()
# => [:temporal, :combinatorial, :reverse_engineering, ...]

# Select domains for task
weights = Tiannara.MetaCognition.select_domains("malware analysis")
# => %{reverse_engineering: 0.45, logic: 0.20, ...}

# Assemble team
{:ok, team} = Tiannara.AEO.assemble_domain_team("task", weights)
# => {:ok, [reverse_engineering, logic, causal, prediction, ethics]}

# Validate constraints
{:ok, _} = Tiannara.CIS.validate_plan(execution_plan)
{:ok, _} = Tiannara.CIS.check_domain_diversity(weights)

# Validate constitution
{:ok, plan} = Tiannara.OED.validate_constitution(execution_plan)

# Submit to Runtime
{:ok, _} = Tiannara.AEO.submit_to_runtime(plan)
```

---

## Key Principles Cheat Sheet

| Principle                 | Meaning                                 | Example                              |
| ------------------------- | --------------------------------------- | ------------------------------------ |
| **Core decides**          | All intent originates from Core         | Not: Runtime generates goals         |
| **CIS constrains**        | Immune system regulates, never controls | Not: CIS blocks Core decision        |
| **Nothing without OED**   | Constitutional validation required      | Not: Unvalidated plans to Runtime    |
| **Organisms ≠ Ecosystem** | Core GRCC ≠ Runtime GRCC                | Core: identities, Runtime: pressures |
| **Bridge not coupling**   | AEO translates without tight binding    | Not: Core calls Runtime directly     |
| **Sovereign access**      | Products → API → AEO → Core             | Not: Products → GRCC direct          |
| **Domain governor**       | Meta-Cognition coordinates domains      | Not: Hardcoded domain routing        |

---

## GRCC Split Explained

### Core: GRCC Identity Ecology

```elixir
defstruct [:lineages, :identities, :memory, :specializations]

# Register domain-specialized lineage
Tiannara.Core.GRCCIdentityEcology.register_lineage(
  ecology,
  :logic_lineage_1,
  %{logic: 0.95, causal: 0.3}
)
```

**Owns:**

- Lineages (Logic Lineages, Algorithm Lineages, etc.)
- Identities (who the system is)
- Memory (what it remembers)
- Specialization (what it's good at)

### Runtime: GRCC Environment

**Owns:**

- Environmental pressures
- Resource niches
- Entropy fields
- Selection pressure

**Metaphor:**

```
Core GRCC = Darwin's Organisms (evolve internally)
Runtime GRCC = Darwin's Environment (apply pressure)
Result = Evolution
```

---

## The 14 Domains

### Reasoning Cortex (How I Think)

1. **Temporal** - Time, sequences, causality chains
2. **Combinatorial** - Permutations, arrangements
3. **Reverse Engineering** - Decomposition, system understanding
4. **Causal** - Cause-effect relationships
5. **Prediction** - Forecasting, extrapolation
6. **Logic** - Boolean, formal reasoning
7. **Algorithm** - Procedural, computational
8. **NLP** - Language understanding, generation

### Executive Cortex (How I Coordinate Thinking)

9. **Meta-Cognition** - Domain governance (THE GOVERNOR)
10. **Collective Intelligence** - Group reasoning
11. **Creative Synthesis** - Novel combinations
12. **Social Intelligence** - Inter-agent reasoning
13. **Ethical Reasoning** - Value-based decisions
14. **Embodied Cognition** - Action and embodiment

---

## Example: "Design Trading Strategy"

```
Input: "Design profitable trading strategy"

CORE DECISION:
  Goal: Create strategy with 20%+ return, <5% risk
  Rationale: Maximize shareholder value ethically
  Outcome: Strategy artifact + validation proof

DOMAIN SELECTION (Meta-Cognition):
  Prediction: 35%    ← primary
  Temporal: 25%      ← secondary
  Algorithm: 20%     ← secondary
  Causal: 15%        ← supportive
  Ethics: 5%         ← constraint

TEAM ASSEMBLY (AEO):
  [prediction, temporal, algorithm, causal, ethics]

CONSTRAINTS (CIS):
  ✓ Domain diversity maintained (5 domains used)
  ✓ Ethics present (prevents monoculture)
  ✓ No single domain > 50%

VALIDATION (OED):
  ✓ Constitutional constraints passed
  ✓ Cross-validated via ACM/OAVL
  ✓ Strategy is executable

EXECUTION (Runtime):
  - Assemble domain specialists
  - Apply environmental pressure (market conditions)
  - Generate strategy
  - Validate against market conditions

FEEDBACK:
  - Strategy: [algorithmic rules for entry/exit]
  - Performance: 22% return, 4.2% risk
  - Specialization: Prediction lineages +3% confidence
  - Memory: Strategy stored for future use
```

---

## CIS Monoculture Prevention

**Problem:** One domain (e.g., Prediction) dominates all decisions

**Detection:**

```elixir
weights = %{
  prediction: 0.80,  # ⚠️ Too high
  logic: 0.15,
  ethics: 0.05
}

CIS.check_domain_diversity(weights)
# => {:ok, false}  # MONOCULTURE RISK
```

**Prevention:**

- Minimum domains per team: >= 2
- No domain should exceed 50% weight
- Ethics always included
- CIS provides flags (Core decides response)

**Example Response:**

```
CIS: "Monoculture risk: Prediction 80%"
Core: "Increase Ethics constraint to 15%"
New weights: Prediction 70%, Logic 15%, Ethics 15%
CIS: "Diversity acceptable"
```

---

## OED Constitutional Validation

**Scenario:** Prediction domain discovers novel market pattern

```
Domain Output:
  "Buy signal: Market inefficiency detected"
  Confidence: 85%

OED Validates:
  1. Can another ontology rediscover it?
  2. Is it legally compliant?
  3. Is it ethically acceptable?
  4. Does it violate constitutional constraints?

Result:
  ✓ Pattern validated via 3 ontologies
  ✓ Legal: Within SEC guidelines
  ✓ Ethical: No market manipulation
  ✓ Constitutional: Acceptable

Output: Validated Knowledge
```

---

## Files & Locations

| Purpose        | File                                         | Lines |
| -------------- | -------------------------------------------- | ----- |
| Core module    | `lib/tiannara/core.ex`                       | 68    |
| Identity       | `lib/tiannara/identity.ex`                   | 16    |
| Cognition      | `lib/tiannara/cognition.ex`                  | 9     |
| MetaCognition  | `lib/tiannara/meta_cognition.ex`             | 16    |
| Domains        | `lib/tiannara/domain_cortex.ex`              | 23    |
| GRCC Organisms | `lib/tiannara/core/grcc_identity_ecology.ex` | 33    |
| Goals          | `lib/tiannara/core/goal_system.ex`           | 20    |
| Bridge         | `lib/tiannara/aeo.ex`                        | 34    |
| Constraints    | `lib/tiannara/cis_constraint.ex`             | 25    |
| Constitution   | `lib/tiannara/oed.ex`                        | 24    |
| Docs           | `lib/tiannara/architecture.ex`               | 410   |

---

## Status

✅ All modules created and compiled successfully
✅ Clear separation of concerns established
✅ Comprehensive documentation provided
✅ Ready for runtime integration
✅ Ready for domain implementation

---

## Next: Runtime Integration

1. Map existing Runtime to Body layer
2. Validate GRCC environment ownership
3. Connect HSV, CTL, OCM, OPC
4. Implement domain specialization loop
5. Test complete request flow
