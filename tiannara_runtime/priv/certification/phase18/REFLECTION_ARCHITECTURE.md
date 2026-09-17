# Phase 18.7 — Reflection & Meta-Cognition: Architecture

## Overview

Phase 18.7 implements a closed-loop reflection pipeline that ingests decision outcomes from Phases 18.2–18.6, analyzes them for patterns and biases, extracts actionable lessons, and updates the meta-cognition state for future decision adaptation. The architecture is strictly observational — it inspects and learns from prior decisions without performing self-modification of its own pipeline logic.

## Reflection Pipeline

```
Decision Outcomes (18.2–18.6)
        │
        ▼
   Outcome Analysis
        │
        ▼
   Pattern Detection
        │
        ▼
   Lesson Extraction
        │
        ▼
   Meta-Cognition State Update
        │
        ▼
   Bias Assessment
        │
        ▼
   Reflection Artifacts (Evidence, Replay, Archaeology)
```

### Stage 1 — Outcome Analysis
Collects decisions and their known outcomes from Phases 18.2 (Constraint Resolution), 18.3 (Ethical Bounding), 18.4 (Temporal Integration), 18.5 (Uncertainty Quantification), and 18.6 (Adaptive Decision Fusion). Each outcome is scored along correctness, efficiency, and alignment dimensions.

### Stage 2 — Pattern Detection
Analyzes the scored outcome set for recurring sequences, frequency clusters, and anomalous deviations. Identifies decision patterns that correlate with positive or negative outcomes.

### Stage 3 — Lesson Extraction
Converts detected patterns into structured lessons. Each lesson is classified as actionable (can be applied immediately), reusable (applies across contexts), or transferable (applies to other phases or systems).

### Stage 4 — Meta-Cognition State Update
Merges extracted lessons into the persistent MetaCognitionState, adjusting awareness levels, adaptation readiness, and the bias profile. The state is versioned and tracked across reflection sessions.

### Stage 5 — Bias Assessment
Evaluates the current and historical decision set for cognitive biases: confirmation bias, availability bias, anchoring bias, framing bias, and overconfidence bias. Each assessment produces a BiasDimension score indicating severity and prevalence.

## Closed-Loop Integration

- **18.2 (Constraint Resolution):** Consumes constraint satisfaction outcomes; feeds back bias-awareness metadata.
- **18.3 (Ethical Bounding):** Consumes ethical alignment scores; feeds back pattern-informed ethical heuristics.
- **18.4 (Temporal Integration):** Consumes temporal coherence metrics; feeds back timing-bias corrections.
- **18.5 (Uncertainty Quantification):** Consumes confidence intervals; feeds back overconfidence calibration signals.
- **18.6 (Adaptive Decision Fusion):** Consumes fused decision weights; feeds back meta-cognitive adaptation directives.

## Non-Modification Guarantee

Phase 18.7 does not alter any pipeline stage from 18.2–18.6. All feedback is written to a read-only reflection store that downstream phases may query voluntarily. Reflection never rewrites its own pipeline configuration or stage logic.
