# Alpha Long-Horizon Experiments

## Experiment Design Principles
- Each experiment: hypothesis, variables, checkpoints, stopping criteria, expected evidence, certification requirements
- Experiments run in parallel with normal discovery operations
- Experiments use dedicated resource budgets (not competing with operational)
- All experiments replayable, certified, and archaeologically preserved

## Experiment 1: 24-Hour Runtime Stability

### Hypothesis
Tiannara can maintain continuous operation for 24 hours with stable memory, deterministic replay, and no degradation.

### Variables
- Memory usage over 24h (should plateau)
- Cycle duration over 24h (should not increase)
- Queue depth over 24h (should not accumulate)
- Replay integrity (should remain 100%)
- Checkpoint success rate (should remain 100%)

### Checkpoints
- Hourly full checkpoints
- Every 5-minute incremental checkpoints

### Stopping Criteria
- Memory growth exceeding 10% after first 4 hours
- Replay integrity below 99.9%
- Any unrecoverable checkpoint failure
- Cycle duration increasing >50% over baseline

### Expected Evidence
- Memory plateau demonstrated (growth <1% after 4h)
- All checkpoints verified
- Replay integrity = 100%
- Zero unrecoverable events
- Complete telemetry record

### Certification
- Runtime certification after 24h
- Replay certification for entire period
- Observatory certification for telemetry completeness

## Experiment 2: 7-Day Scientific Continuity

### Hypothesis
Over 7 days, Tiannara generates a measurable scientific output: hypotheses, evidence, validated/falsified predictions, and knowledge growth.

### Variables
- Hypotheses generated per day
- Hypotheses validated vs. refuted ratio
- Knowledge growth rate
- Discovery pipeline throughput
- Evidence quality distribution

### Checkpoints
- Daily full checkpoints
- Hourly incremental checkpoints

### Stopping Criteria
- Zero hypotheses generated for 48 hours
- Prediction accuracy below 40% for 72 hours
- Knowledge growth zero for 72 hours
- Pipeline stall >24 hours

### Expected Evidence
- ≥70 hypotheses generated
- ≥7 hypotheses validated or refuted
- Measurable knowledge growth (≥35 entries)
- Complete evidence lineage for all hypotheses
- Pipeline throughput documented

### Certification
- Scientific workflow certification
- Evidence lineage certification
- Knowledge integrity certification

## Experiment 3: 30-Day Engineering Output

### Hypothesis
Over 30 days of operation, Tiannara produces verified engineering designs with measurable optimization improvement.

### Variables
- Engineering designs generated per day
- Verification success rate
- Optimization yield per design
- Technology readiness progression

### Checkpoints
- Weekly full checkpoints
- Daily incremental checkpoints

### Stopping Criteria
- Zero designs for 14 days
- Verification success rate below 40% for 14 days
- Optimization yield negative for 14 days

### Expected Evidence
- ≥30 engineering designs generated
- ≥60% verification success rate
- ≥5% average optimization yield
- Design pipeline throughput documented
- Verification reproducibility demonstrated

### Certification
- Engineering workflow certification
- Optimization reproducibility certification
- Verification integrity certification

## Experiment 4: 90-Day Complete Alpha

### Hypothesis
Over 90 days, Tiannara demonstrates all Alpha exit criteria: replay integrity, recovery, scientific output, engineering output, observatory metrics, constitutional stability.

### Variables
- All Alpha metrics tracked over 90 days
- Trend analysis for all metrics
- Failure and recovery events tracked

### Checkpoints
- Weekly full checkpoints
- Daily incremental checkpoints
- Special checkpoints before/after any experiment

### Stopping Criteria
- Any unrecoverable failure
- Replay integrity below 99.9% for >7 days
- Constitutional compliance below 95% for >7 days
- Observatory metrics unavailable for >24 hours

### Expected Evidence
- 90 days of continuous telemetry
- All Alpha exit criteria met
- Failure recovery demonstrated (minimum 3 recovery events)
- Complete archaeology reconstruction at end
- Observatory historical playback verified

### Certification
- Full Alpha Stage certification
- Exit readiness certification
- Stage Beta readiness certification

## Experiment 5: Failure Recovery (Run at Any Point)

### Hypothesis
Tiannara can survive simulated failures with zero knowledge loss and complete recovery.

### Failure Scenarios
- Process kill (SIGKILL) mid-operation
- Checkpoint corruption during write
- Memory exhaustion (simulated)
- Queue overflow (simulated)
- Network partition (simulated)
- Multiple simultaneous failures

### Recovery Verification
- After each recovery: verify replay integrity from last valid checkpoint
- Verify knowledge base intact
- Verify all pending operations preserved or properly terminated
- Verify observatory telemetry continuous (no gaps)

### Expected Evidence
- Zero knowledge loss across all failure scenarios
- Recovery time within limits (<30s)
- Replay integrity verified after each recovery
- Observatory gap analysis (acceptable: <1s)

### Certification
- Recovery certification
- Resilience certification
- Zero-loss certification
