# Phase 18.8 — Metacognition Certification

## Validation Stages

### Stage 1 — Session Determinism

Given identical cognitive session inputs, two invocations of the MetaController must produce identical `MetaCognitionState` lifecycles. All tick boundaries must align exactly.

**Pass condition:** 100% match across 1,000 paired runs.

### Stage 2 — Self-Monitor Determinism

Given identical cognitive execution traces, two SelfMonitor passes must produce identical `SelfMonitorReading` sequences. Any variance indicates a probe non-determinism.

**Pass condition:** All 5 metric dimensions match within floating-point epsilon (1e-9) across 5,000 paired ticks.

### Stage 3 — Confidence Reproducibility

The ConfidenceEstimator must produce identical `ConfidenceEstimate` values for identical predicted/actual input pairs. Calibration must be invariant under re-execution.

**Pass condition:** score, calibrated_score, and prediction_interval match exactly across 10,000 input pairs.

### Stage 4 — Uncertainty Propagation

The UncertaintyAnalyzer must decompose uncertainty identically for identical confidence inputs. The aleatoric/epistemic split must be reproducible.

**Pass condition:** aleatoric, epistemic, total all match within floating-point epsilon across 5,000 decompositions.

### Stage 5 — Health Assessment Consistency

The HealthEvaluator must produce identical 6-dimension assessments for identical input vectors. The aggregate score must be a deterministic function.

**Pass condition:** All 7 values (6 dimensions + aggregate) match exactly across 10,000 assessments.

### Stage 6 — Escalation Logic

The EscalationEngine must map identical health assessments to identical decisions. Severity classification must be invariant.

**Pass condition:** severity, reason, and dimension match across 10,000 evaluations spanning all 4 severity levels.

### Stage 7 — Introspection Completeness

The IntrospectionEngine must enumerate all constitutional violations for a given execution. No false positives, no false negatives.

**Pass condition:** Full coverage of the constitutional rule set (verified by mutation testing). Zero undetected violations in 1,000 seeded compliance failures.

### Stage 8 — Replay / Archaeology Fidelity

MetaReplay must perfectly reconstruct a session from its evidence chain. MetaArchaeology must reconstruct with quantified confidence and complete gap reporting for degraded inputs.

**Pass condition:** Replay achieves 100% event match for complete evidence chains. Archaeology reports confidence >= 0.95 for sessions with >= 90% evidence retention; all gaps accurately enumerated.
