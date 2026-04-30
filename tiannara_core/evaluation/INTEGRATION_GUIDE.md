# Advanced Evaluation System - Integration Guide

## Overview

This evaluation system provides multi-dimensional intelligence scoring that transforms your Tiannara system from "interesting" into **measurably intelligent**.

### What You Get

✅ **Multi-dimensional scores** - Not just pass/fail, but nuanced metrics  
✅ **Novelty tracking** - Prevents stagnation and repetitive behavior  
✅ **Stability analysis** - Detects chaotic vs. consistent systems  
✅ **Learning memory** - Tracks improvement trends over time  
✅ **Causal + evolution feed** - Rich signals for downstream systems  

---

## Quick Start

### 1. Basic Usage

```python
from tiannara_core.evaluation import Evaluator

# Create evaluator
evaluator = Evaluator()

# Define function to evaluate
def my_function(x, y):
    result = x + y
    return {"output": result, "success": True}

# Evaluate (runs 3 times by default for stability analysis)
evaluation = evaluator.evaluate(my_function, {"x": 5, "y": 3})

# Access results
score = evaluation["score"]  # Final score (0.0-1.0)
metrics = evaluation["metrics"]  # Detailed metrics

print(f"Score: {score:.4f}")
print(f"Correctness: {metrics['correctness']:.4f}")
print(f"Runtime: {metrics['runtime']:.6f}s")
print(f"Error rate: {metrics['error']:.4f}")
print(f"Stability: {metrics['stability']:.4f}")
print(f"Novelty: {metrics['novelty']:.4f}")
```

### 2. Integration with Evolution Loop

```python
from tiannara_core.evaluation import Evaluator

evaluator = Evaluator()

for episode in range(100):
    # Generate or mutate logic
    variant = evolver.mutate(base_program)
    
    # Sample inputs
    inputs = sample_domain_inputs()
    
    # Evaluate
    evaluation = evaluator.evaluate(variant, inputs, runs=3)
    
    score = evaluation["score"]
    metrics = evaluation["metrics"]
    
    # Feed into evolution
    evolver.update(score)
    
    # Feed into causal engine
    causal_engine.observe(metrics)
    
    # Log everything
    log.store({
        "episode": episode,
        "inputs": inputs,
        "score": score,
        "metrics": metrics,
        "mutation_type": variant.type
    })
    
    # Monitor progress
    if episode % 10 == 0:
        stats = evaluator.get_history_statistics()
        print(f"Episode {episode}: Avg={stats['average_score']:.4f}, "
              f"Trend={stats['trend']}")
```

### 3. Integration with Causal Engine

```python
# After evaluation
evaluation = evaluator.evaluate(func, inputs)

# Extract feature vector for causal analysis
causal_features = {
    "correctness": evaluation["metrics"]["correctness"],
    "efficiency": 1.0 / (1.0 + evaluation["metrics"]["runtime"]),
    "stability": evaluation["metrics"]["stability"],
    "novelty": evaluation["metrics"]["novelty"],
    "error_rate": evaluation["metrics"]["error"],
}

# Observe in causal engine
causal_engine.observe(causal_features)
```

### 4. Integration with GNN

```python
# Build training data from evaluations
X = []  # Features
y = []  # Labels (scores)

for record in evaluator.history.records:
    features = [
        record["metrics"]["correctness"],
        record["metrics"]["runtime"],
        record["metrics"]["stability"],
        record["metrics"]["novelty"],
        record["metrics"]["error"],
    ]
    X.append(features)
    y.append(record["score"])

# Train GNN
gnn.train(X, y)
```

---

## Component Architecture

```
Evaluator (Master Controller)
├── Metrics (Raw signal extraction)
│   ├── correctness()
│   ├── runtime()
│   ├── error_rate()
│   ├── output_size()
│   └── consistency()
├── NoveltyTracker (Intelligence signal)
│   └── compute_novelty(vector)
├── StabilityChecker (Reliability signal)
│   └── evaluate(outputs)
├── Scorer (Weighted combination)
│   └── compute(metrics)
└── EvaluationHistory (Learning memory)
    ├── log(entry)
    ├── get_best()
    ├── get_recent(n)
    ├── improvement_rate()
    └── get_statistics()
```

---

## Configuration

### Custom Weights

```python
# Emphasize correctness over novelty
custom_weights = {
    "correctness": 0.50,      # Higher weight
    "efficiency": 0.15,
    "stability": 0.20,
    "novelty": 0.05,          # Lower weight
    "error_penalty": 0.10,
}

evaluator = Evaluator(weights=custom_weights)
```

### Default Weights

```python
{
    "correctness": 0.35,      # Most important
    "efficiency": 0.15,       # Speed matters
    "stability": 0.20,        # Consistency is key
    "novelty": 0.15,          # Exploration bonus
    "error_penalty": 0.15,    # Errors hurt
}
```

---

## Expected Behavior

### Good Signs (After 50-100 Episodes)

✅ Average score slowly increases  
✅ Variance decreases (stabilization)  
✅ Certain mutation types dominate  
✅ Causal graph forms stable edges  
✅ Novelty decreases (convergence)  

### Bad Signs

❌ Score is random noise → Evaluator issue  
❌ No improvement → Mutation too random  
❌ Collapse to constant 0.5 → No learning signal  
❌ High instability → Chaotic system  

---

## Testing

Run the test suite to verify installation:

```bash
python -m tiannara_core.evaluation.test_evaluator
```

Expected output: All 7 tests should pass.

---

## Domain Selection

**CRITICAL**: Start with ONE controlled domain for 50-100 episodes.

### Recommended Starter Domains

#### 🟢 Option A: Algorithm Tasks (Best for Stability)
- Sorting variants
- Optimization problems
- Function transformation

#### 🟡 Option B: Reverse Engineering (Best for ECM Testing)
- Input → output mapping recovery
- Black-box function inference

#### 🔵 Option C: Synthetic Causal System (Best for Causality)
- x → y → z dependencies
- Controllable ground truth

---

## Logging Strategy

Every episode MUST be logged:

```python
log_entry = {
    "episode_id": episode,
    "timestamp": time.time(),
    "inputs": inputs,
    "outputs": evaluation["outputs"],
    "score": evaluation["score"],
    "metrics": evaluation["metrics"],
    "mutation_type": variant.type,
    "execution_trace": trace,
    "causal_snapshot": causal_state,
    "runtime": evaluation["metrics"]["runtime"],
    "error_state": evaluation["metrics"]["error"] > 0,
}

# Store in JSONL format
with open("tiannara_core/logs/evolution.jsonl", "a") as f:
    f.write(json.dumps(log_entry) + "\n")
```

---

## Monitoring Dashboard

Track these metrics over time:

```python
# Every 10 episodes
stats = evaluator.get_history_statistics()

print(f"""
=== Episode {episode} Statistics ===
Total Evaluations: {stats['total_records']}
Average Score: {stats['average_score']:.4f}
Best Score: {stats['best_score']:.4f}
Worst Score: {stats['worst_score']:.4f}
Improvement Rate: {stats['improvement_rate']:.4f}
Trend: {stats['trend']}
""")
```

---

## Advanced Features

### 1. Adaptive Weights (Future)

```python
# Dynamically adjust weights based on performance
if stats['trend'] == 'stable':
    # Increase novelty weight to escape local optima
    evaluator.update_weights({
        "correctness": 0.30,
        "efficiency": 0.15,
        "stability": 0.15,
        "novelty": 0.25,  # Increased
        "error_penalty": 0.15,
    })
```

### 2. Domain-Specific Evaluators

```python
# Create separate evaluators for different domains
algorithm_evaluator = Evaluator(weights={...})
causal_evaluator = Evaluator(weights={...})

# Use appropriate evaluator per domain
if domain == "algorithm":
    result = algorithm_evaluator.evaluate(func, inputs)
else:
    result = causal_evaluator.evaluate(func, inputs)
```

### 3. Reset for New Domains

```python
# When switching domains, reset history and novelty
evaluator.reset()
```

---

## Performance Considerations

- **Runs parameter**: More runs = better stability analysis but slower
  - Quick testing: `runs=1`
  - Standard evaluation: `runs=3`
  - Critical evaluation: `runs=5-10`

- **Novelty history**: Grows unbounded
  - For long runs, consider periodic reset or sliding window

- **Memory usage**: History stores all outputs
  - For production, consider storing only metrics, not full outputs

---

## Troubleshooting

### Issue: Scores are all 0.5

**Cause**: No learning signal, random mutations  
**Fix**: Reduce mutation randomness, increase correctness weight

### Issue: Scores don't improve after 50 episodes

**Cause**: Evaluator weights misaligned with task  
**Fix**: Adjust weights, check if correctness metric is meaningful

### Issue: High variance in scores

**Cause**: Unstable system or insufficient runs  
**Fix**: Increase `runs` parameter, investigate source of instability

### Issue: Novelty stays high

**Cause**: System never converges  
**Fix**: This might be good (exploration) or bad (chaos). Check stability.

---

## Next Steps

After validating with 50-100 episodes:

1. **Analyze trends**: Is score increasing? Is stability improving?
2. **Inspect best performers**: What made them successful?
3. **Refine weights**: Adjust based on observed behavior
4. **Expand domains**: Add new domains with domain-specific evaluators
5. **Advanced features**: Implement adaptive weights, curriculum learning

---

## References

- Test suite: `tiannara_core/evaluation/test_evaluator.py`
- Main evaluator: `tiannara_core/evaluation/evaluator.py`
- Metrics: `tiannara_core/evaluation/metrics.py`
- Novelty: `tiannara_core/evaluation/novelty.py`
- Stability: `tiannara_core/evaluation/stability.py`
- Scoring: `tiannara_core/evaluation/scoring.py`
- History: `tiannara_core/evaluation/history.py`
