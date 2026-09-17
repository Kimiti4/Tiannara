# Metacognition System Architecture — 5-Layer Map

This document maps every metacognition component across all 5 layers of Tiannara's metacognition stack. Each layer is documented separately — they are **not** merged. This document records their distinct roles, runtime domains, and inter-layer relationships.

---

## Level 5: Constitutional Meta-Cognition (Phase 18.8)

- **Runtime domain**: Cognitive execution supervision
- **Role**: Supervises runtime cognition; **never modifies cognition, only observes**
- **Constitutional bar**: No learning, no optimization, no self-modification — pure observation

### Components

| Component | Role |
|---|---|
| MetaController | Session lifecycle management |
| SelfMonitor | Captures runtime metrics per cognitive cycle |
| ConfidenceEstimator | Compares predicted vs actual outcomes |
| UncertaintyAnalyzer | Decomposes uncertainty into aleatoric and epistemic components |
| HealthEvaluator | Assesses system health across 6 dimensions |
| EscalationEngine | Classifies and routes anomalies by severity |
| IntrospectionEngine | Verifies constitutional compliance of every execution |
| MetaMetrics | Records quantitative metacognitive metrics |
| MetaReplay | Enables deterministic replay of any session |
| MetaEvidence | Persists evidence artifacts for audit |
| MetaArchaeology | Recovers historical execution traces from archived sessions |

### Behaviours

- **MetaBehaviour** — core observation behaviour
- **ConfidenceBehaviour** — confidence calibration behaviour
- **HealthBehaviour** — health assessment behaviour
- **EscalationBehaviour** — anomaly escalation behaviour

### Structs

| Struct | Role |
|---|---|
| MetaCognitionState | Full snapshot of metacognitive state per cycle |
| ConfidenceEstimate | Predicted vs actual outcome comparison |
| UncertaintyEstimate | Decomposed aleatoric/epistemic uncertainty |
| HealthAssessment | 6-dimension health evaluation |
| EscalationDecision | Severity-classified anomaly decision |
| ReflectionSummary | Summarised reflection output |
| Introspection | Constitutional compliance record |
| MetaEvidence | Immutable evidence artifact |
| MetaReplay | Deterministic replay payload |
| MetaArchaeology | Archived session recovery payload |
| MetaMetrics | Quantitative metric record |

---

## Level 4: Reflective Metacognition (Phase 18.7)

- **Runtime domain**: Completed cognition analysis
- **Role**: Explains completed cognition, produces lessons, detects patterns and bias
- **Operates on** historical execution evidence, not live cognition

### Components

| Component | Role |
|---|---|
| ReflectionController | Orchestrates reflection sessions |
| OutcomeAnalyzer | Scores outcomes of completed cognitive cycles |
| PatternDetector | Identifies recurring patterns across sessions |
| BiasDetector | Assesses cognitive bias across multiple dimensions |
| LessonExtractor | Distills actionable lessons from reflection |
| MetaCognitionController | Coordinates meta-cognitive control flow (Phase 18.7 legacy) |
| ReflectionReplay | Deterministic replay of reflection sessions |
| ReflectionArchaeology | Recovery of archived reflection traces |
| ReflectionMetrics | Quantitative reflection metrics |

### Structs

| Struct | Role |
|---|---|
| Reflection | A single reflection record |
| ReflectionSession | Aggregates multiple reflections |
| Outcome | Result of a completed cognitive cycle |
| OutcomeScore | Scored evaluation of an outcome |
| Pattern | Recurring pattern definition |
| PatternMatch | Instance of a detected pattern |
| BiasAssessment | Full bias evaluation |
| BiasDimension | One axis of bias measurement |
| Lesson | Actionable extracted lesson |
| LessonApplication | Record of a lesson being applied |
| MetaCognitionState | Shared state struct (cross-layer) |
| ReflectionEvidence | Evidence artifact for reflection |
| ReflectionReplay | Replay payload for reflection |
| ReflectionArchaeology | Archaeology payload for reflection |

---

## Level 3: Scientific Meta-Cognition (Python: `tiannara_core/metacognition/`)

- **Domain**: Scientific discovery and epistemic integrity
- **Role**: Supervises scientific discovery, not runtime cognition
- **Future**: Becomes part of Phase 19 — Civilizational Intelligence

### Components

| Component | Role |
|---|---|
| TheoryGovernance | Governs theory lifecycle and validity |
| KnowledgeGapDetector | Identifies gaps in current knowledge |
| BeliefEcology | Manages competing beliefs and their fitness |
| EpistemicIntegrity | Ensures epistemic soundness of conclusions |
| ProvenanceTrust | Tracks and validates evidence provenance |
| FalseEvidenceDetection | Detects fabricated or corrupted evidence |
| CognitiveFusion | Integrates insights across disparate domains |
| AdaptiveBeliefInertia | Balances belief stability vs adaptability |
| TheoryEngine | Orchestrates theory construction and testing |
| UncertaintyPlanning | Plans under scientific uncertainty |
| RecursiveGovernor | Prevents infinite recursion in meta-cognition |

---

## Level 2: Runtime Services

- **Domain**: Infrastructure
- **Role**: Provides infrastructure; not metacognition itself but enables it

### Components

| Component | Role |
|---|---|
| AdaptiveRuntime | Dynamic resource allocation and execution tuning |
| ParallelWorkers | Concurrent cognitive task execution |
| MemoryReconsolidation | Long-term memory integration and restructuring |

---

## Level 1: Legacy Systems

- **Domain**: Historical evolution
- **Role**: Historical lineage, replayable artifacts, migration reference
- **Status**: Archived after Phase 18.999

### Systems

| System | Origin | Role |
|---|---|---|
| `meta_cognition/` | Historical constitutional prototype | Archived after Phase 18.999; served as the original constitutional observer |
| `metacognitive/` | Intermediate prototype | Archived; algorithm archaeology source for replay and migration |

---

## Complete Component Table

| Component | Layer | Purpose | Active | Future |
|---|---|---|---|---|
| MetaController | Constitutional Meta | Session lifecycle management | ✅ | Phase 18 |
| SelfMonitor | Constitutional Meta | Runtime metric capture | ✅ | Phase 18 |
| ConfidenceEstimator | Constitutional Meta | Predicted vs actual comparison | ✅ | Phase 18 |
| UncertaintyAnalyzer | Constitutional Meta | Aleatoric/epistemic decomposition | ✅ | Phase 18 |
| HealthEvaluator | Constitutional Meta | 6-dimension health assessment | ✅ | Phase 18 |
| EscalationEngine | Constitutional Meta | Anomaly severity classification | ✅ | Phase 18 |
| IntrospectionEngine | Constitutional Meta | Constitutional compliance verification | ✅ | Phase 18 |
| MetaMetrics | Constitutional Meta | Quantitative metacognitive metrics | ✅ | Phase 18 |
| MetaReplay | Constitutional Meta | Deterministic session replay | ✅ | Phase 18 |
| MetaEvidence | Constitutional Meta | Immutable evidence persistence | ✅ | Phase 18 |
| MetaArchaeology | Constitutional Meta | Archived session recovery | ✅ | Phase 18 |
| ReflectionController | Reflective Meta | Reflection session orchestration | ✅ | Phase 18 |
| OutcomeAnalyzer | Reflective Meta | Outcome scoring | ✅ | Phase 18 |
| PatternDetector | Reflective Meta | Cross-session pattern identification | ✅ | Phase 18 |
| BiasDetector | Reflective Meta | Multi-dimension bias assessment | ✅ | Phase 18 |
| LessonExtractor | Reflective Meta | Actionable lesson distillation | ✅ | Phase 18 |
| MetaCognitionController | Reflective Meta | Meta-cognitive control flow | ✅ | Phase 18 |
| ReflectionReplay | Reflective Meta | Reflection deterministic replay | ✅ | Phase 18 |
| ReflectionArchaeology | Reflective Meta | Archived reflection recovery | ✅ | Phase 18 |
| ReflectionMetrics | Reflective Meta | Quantitative reflection metrics | ✅ | Phase 18 |
| TheoryGovernance | Scientific Meta | Theory lifecycle governance | ✅ | Phase 19 |
| KnowledgeGapDetector | Scientific Meta | Knowledge gap identification | ✅ | Phase 19 |
| BeliefEcology | Scientific Meta | Competing belief management | ✅ | Phase 19 |
| EpistemicIntegrity | Scientific Meta | Epistemic soundness enforcement | ✅ | Phase 19 |
| ProvenanceTrust | Scientific Meta | Evidence provenance tracking | ✅ | Phase 19 |
| FalseEvidenceDetection | Scientific Meta | Fabricated evidence detection | ✅ | Phase 19 |
| CognitiveFusion | Scientific Meta | Cross-domain insight integration | ✅ | Phase 19 |
| AdaptiveBeliefInertia | Scientific Meta | Belief stability vs adaptability | ✅ | Phase 19 |
| TheoryEngine | Scientific Meta | Theory construction and testing | ✅ | Phase 19 |
| UncertaintyPlanning | Scientific Meta | Scientific uncertainty planning | ✅ | Phase 19 |
| RecursiveGovernor | Scientific Meta | Recursion prevention in meta-cognition | ✅ | Phase 19 |
| AdaptiveRuntime | Runtime Services | Dynamic resource allocation | ✅ | Ongoing |
| ParallelWorkers | Runtime Services | Concurrent task execution | ✅ | Ongoing |
| MemoryReconsolidation | Runtime Services | Long-term memory integration | ✅ | Ongoing |
| `meta_cognition/` (archive) | Legacy Systems | Historical constitutional prototype | Archived | Phase 18.999 |
| `metacognitive/` (archive) | Legacy Systems | Intermediate prototype | Archived | Phase 18.999 |

---

## Three Distinct Categories

> **Three distinct categories:**
>
> 1. **Runtime Metacognition (Phase 18.8)** — supervises cognitive execution.
> 2. **Scientific Metacognition (Python)** — supervises scientific discovery and epistemic integrity.
> 3. **Reflective Metacognition (Phase 18.7)** — supervises completed cognition by extracting lessons, detecting bias, and building reusable knowledge.

---

## Inter-Layer Relationships

- **Level 5 (Constitutional Meta)** observes Level 2 (Runtime Services) cognitive execution in real time. It is a pure observer — no feedback path exists from Level 5 into cognition.
- **Level 4 (Reflective Meta)** analyses evidence produced by Level 5 after execution completes. It operates on replay and archaeology artifacts.
- **Level 3 (Scientific Meta)** operates independently in the Python domain, supervising scientific theory construction. It does not observe runtime cognition.
- **Level 1 (Legacy Systems)** provides replayable historical artifacts that informed the design of Levels 5 and 4. No active data path exists.

No layer modifies another. Observation flows downward; analysis flows upward. The constitutional separation is absolute.
