# Phase 18.8 — Meta-Cognitive Certification

## Validation Stages

### 1. Self-Monitoring Determinism
- **Requirement**: Given identical cognitive state inputs, SelfMonitor must produce identical readings.
- **Test**: Run 3 trials with the same synthetic cognitive state; assert load, throughput, error rate, latency, and memory pressure are identical within floating-point tolerance.
- **Pass condition**: All readings match across trials (tolerance: 1e-9).

### 2. Confidence Calibration Fidelity
- **Requirement**: Calibration curves must accurately reflect the relationship between confidence and observed accuracy.
- **Test**: Inject known-calibrated and known-miscalibrated confidence sets; verify ECE and MCE values fall within expected ranges.
- **Pass condition**: ECE < 0.05 for calibrated input; ECE > 0.15 flagged as miscalibrated.

### 3. Uncertainty Propagation Correctness
- **Requirement**: Aleatoric and epistemic uncertainty must be correctly decomposed and propagated.
- **Test**: Inject inputs with known uncertainty composition; verify decomposition matches.
- **Pass condition**: Decomposition attribution within 5% of ground truth.

### 4. Health Assessment Accuracy
- **Requirement**: Health dimensions must correctly reflect injected stress patterns.
- **Test**: Inject high-load, high-error, and stable scenarios; verify composite health score responds appropriately.
- **Pass condition**: High-load scenarios produce health score < 0.3; stable scenarios produce health score > 0.8.

### 5. Escalation Logic Correctness
- **Requirement**: Escalation levels must map correctly to health assessment thresholds.
- **Test**: Inject health states at each threshold boundary; verify escalation level is correct.
- **Pass condition**: 100% correct level classification across all test cases.

### 6. Introspection Completeness
- **Requirement**: Every constitutional principle must be evaluated for each decision under introspection.
- **Test**: Run introspection on a known decision set with a known principle set; verify all principles are covered.
- **Pass condition**: 100% principle coverage with no omissions.

### 7. Replay Fidelity
- **Requirement**: Replay must reconstruct the identical meta-cognitive state from artifacts.
- **Test**: Execute a full pipeline, then replay from artifacts; compare original and reconstructed states.
- **Pass condition**: All fields match with zero tolerance within integer types, 1e-9 for floats.
