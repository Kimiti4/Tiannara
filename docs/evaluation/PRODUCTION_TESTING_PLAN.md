# Production Testing Infrastructure Plan

## Executive Summary

Current testing infrastructure provides solid foundation (79 tests, 100% pass rate) but lacks production-grade features needed for reliable deployment and continuous integration.

**Goal:** Build comprehensive production testing infrastructure that enables:
- Automated CI/CD pipeline
- Code coverage monitoring
- Performance benchmarking
- End-to-end validation
- Regression prevention
- Production deployment verification

---

## Current Status vs Production Requirements

| Feature | Current Status | Production Requirement | Gap |
|---------|---------------|----------------------|-----|
| Unit Tests | ✅ 79 tests | ✅ Complete | None |
| Integration Tests | ✅ 14 domain tests | ⚠️ Partial | Need full pipeline tests |
| Property-Based Tests | ✅ 8 Hypothesis tests | ✅ Complete | None |
| CI/CD Pipeline | ❌ Not implemented | ✅ Required | **Critical Gap** |
| Code Coverage | ❌ Not measured | ✅ >80% required | **Critical Gap** |
| Performance Tests | ❌ None | ✅ Benchmarks needed | **High Priority** |
| E2E Tests | ❌ None | ✅ Full workflow tests | **High Priority** |
| Regression Tests | ❌ None | ✅ Baseline comparisons | **Medium Priority** |
| Load Tests | ❌ None | ✅ Scalability validation | **Medium Priority** |
| Security Tests | ❌ None | ✅ Input validation | **Low Priority** |

---

## Phase 1: Critical Production Features (Week 1)

### 1.1 CI/CD Pipeline Setup

**Objective:** Automated test execution on every commit

**Tasks:**
1. Create GitHub Actions workflow
2. Configure test matrix (Python versions, OS)
3. Add status badges to README
4. Set up branch protection rules

**Files to Create:**
```yaml
# .github/workflows/test.yml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: ["3.10", "3.11", "3.12"]
    steps:
      - uses: actions/checkout@v3
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: ${{ matrix.python-version }}
      - name: Install dependencies
        run: pip install -r requirements.txt
      - name: Run tests
        run: pytest tests/ -v --cov=tiannara_core.evaluation
      - name: Upload coverage
        uses: codecov/codecov-action@v3
```

**Estimated Effort:** 3-4 hours

---

### 1.2 Code Coverage Measurement

**Objective:** Track and enforce minimum code coverage thresholds

**Tasks:**
1. Install pytest-cov
2. Configure coverage thresholds
3. Generate HTML reports
4. Integrate with CI/CD
5. Identify uncovered critical paths

**Implementation:**
```bash
pip install pytest-cov coverage

# Run with coverage
pytest tests/ --cov=tiannara_core.evaluation --cov-report=html --cov-report=term-missing

# Enforce minimum coverage
pytest tests/ --cov=tiannara_core.evaluation --cov-fail-under=80
```

**Configuration (.coveragerc):**
```ini
[run]
source = tiannara_core/evaluation
omit = 
    */tests/*
    */debug_*.py
    */archive/*

[report]
fail_under = 80
show_missing = True
exclude_lines =
    pragma: no cover
    def __repr__
    raise NotImplementedError
```

**Estimated Effort:** 2-3 hours

---

### 1.3 End-to-End Pipeline Tests

**Objective:** Validate complete episode execution workflow

**Tasks:**
1. Test full episode lifecycle (task → variant → evaluate → score → log)
2. Test multi-domain experiment execution
3. Test skill memory integration end-to-end
4. Test cross-domain skill transfer in real scenario

**Example Test:**
```python
# tests/test_e2e_pipeline.py
def test_full_episode_execution():
    """Validate complete episode from task generation to scoring."""
    # Setup
    gen = ReverseEngineeringGenerator(seed=42)
    evolver = ReverseEngineeringEvolver(seed=123)
    evaluator = Evaluator()
    
    # Execute full episode
    task = gen.generate_task(episode=1)
    variant = evolver.create_variant(task, episode=1)
    result = evaluator.evaluate(variant, task["inputs"])
    
    # Verify
    assert "metrics" in result
    assert "score" in result
    assert isinstance(result["score"], float)
    assert 0.0 <= result["score"] <= 1.0

def test_multi_domain_experiment():
    """Run small multi-domain experiment end-to-end."""
    results = run_multi_domain_experiment(num_episodes=5)
    
    assert len(results) == 5
    for result in results:
        assert "domain" in result
        assert "success" in result
        assert "metrics" in result
```

**Estimated Effort:** 6-8 hours

---

## Phase 2: Performance & Quality (Week 2)

### 2.1 Performance Benchmarking

**Objective:** Establish performance baselines and detect regressions

**Tasks:**
1. Create benchmark suite for critical operations
2. Measure execution time for each evolver
3. Track memory usage
4. Compare against historical baselines
5. Alert on performance degradation

**Implementation:**
```python
# tests/test_performance.py
import pytest
import time
from contextlib import contextmanager

@contextmanager
def benchmark(name: str, threshold_ms: float):
    start = time.perf_counter()
    yield
    elapsed_ms = (time.perf_counter() - start) * 1000
    assert elapsed_ms < threshold_ms, f"{name} took {elapsed_ms:.1f}ms (threshold: {threshold_ms}ms)"

def test_polynomial_fitting_performance():
    """Polynomial fitting should complete within 100ms."""
    evolver = ReverseEngineeringEvolver()
    inputs = list(range(10))
    outputs = [x**2 for x in inputs]
    
    with benchmark("polynomial_fit", threshold_ms=100):
        for _ in range(100):
            evolver._polynomial_fit(inputs, outputs, 15)

def test_episode_execution_performance():
    """Single episode should complete within 5 seconds."""
    gen = AlgorithmTaskGenerator(seed=42)
    evolver = AlgorithmEvolver(seed=123)
    
    task = gen.generate_task(episode=1)
    
    with benchmark("full_episode", threshold_ms=5000):
        variant = evolver.create_variant(task, episode=1)
        result = variant(**task["inputs"])
```

**Benchmark Report Generation:**
```python
# scripts/generate_benchmark_report.py
import json
from datetime import datetime

def generate_benchmark_report(results: dict):
    report = {
        "timestamp": datetime.now().isoformat(),
        "benchmarks": results,
        "summary": {
            "total_tests": len(results),
            "passed": sum(1 for r in results.values() if r["passed"]),
            "failed": sum(1 for r in results.values() if not r["passed"]),
            "avg_time_ms": sum(r["time_ms"] for r in results.values()) / len(results)
        }
    }
    
    with open("benchmarks/latest.json", "w") as f:
        json.dump(report, f, indent=2)
    
    return report
```

**Estimated Effort:** 4-6 hours

---

### 2.2 Regression Test Suite

**Objective:** Detect unintended behavior changes

**Tasks:**
1. Capture baseline results for key scenarios
2. Create regression tests comparing against baselines
3. Allow configurable tolerance for numerical differences
4. Track regression history over time

**Implementation:**
```python
# tests/test_regression.py
import json
from pathlib import Path

BASELINE_DIR = Path("tests/baselines")

def load_baseline(name: str) -> dict:
    """Load baseline results for comparison."""
    baseline_file = BASELINE_DIR / f"{name}.json"
    if not baseline_file.exists():
        pytest.skip(f"No baseline found for {name}")
    with open(baseline_file) as f:
        return json.load(f)

def save_baseline(name: str, data: dict):
    """Save current results as new baseline."""
    BASELINE_DIR.mkdir(parents=True, exist_ok=True)
    with open(BASELINE_DIR / f"{name}.json", "w") as f:
        json.dump(data, f, indent=2)

def test_reverse_engineering_accuracy_regression():
    """RE evolver accuracy should not degrade below baseline."""
    baseline = load_baseline("re_evolver_accuracy")
    
    # Run current implementation
    evolver = ReverseEngineeringEvolver(seed=42)
    success_count = 0
    total = 20
    
    for i in range(total):
        task = {"function_type": "linear", "inputs": {"examples": [...]}}
        variant = evolver.create_variant(task, episode=i)
        # ... evaluate ...
        if success:
            success_count += 1
    
    current_accuracy = success_count / total
    baseline_accuracy = baseline["accuracy"]
    
    # Allow 5% degradation tolerance
    assert current_accuracy >= baseline_accuracy * 0.95, \
        f"Accuracy dropped from {baseline_accuracy:.1%} to {current_accuracy:.1%}"
```

**Estimated Effort:** 4-6 hours

---

### 2.3 Load Testing

**Objective:** Validate system behavior under stress

**Tasks:**
1. Test concurrent episode execution
2. Measure scalability with increasing load
3. Identify bottlenecks and resource limits
4. Test memory stability over long runs

**Implementation:**
```python
# tests/test_load.py
import pytest
from concurrent.futures import ThreadPoolExecutor, as_completed

def test_concurrent_episode_execution():
    """System should handle 10 concurrent episodes."""
    def run_episode(episode_id):
        gen = AlgorithmTaskGenerator(seed=episode_id)
        evolver = AlgorithmEvolver(seed=episode_id)
        task = gen.generate_task(episode=episode_id)
        variant = evolver.create_variant(task, episode=episode_id)
        return variant(**task["inputs"])
    
    num_concurrent = 10
    with ThreadPoolExecutor(max_workers=num_concurrent) as executor:
        futures = [executor.submit(run_episode, i) for i in range(num_concurrent)]
        results = [f.result(timeout=30) for f in as_completed(futures)]
    
    assert len(results) == num_concurrent

def test_memory_stability_long_run():
    """Memory usage should remain stable over 100 episodes."""
    import psutil
    import os
    
    process = psutil.Process(os.getpid())
    initial_memory = process.memory_info().rss
    
    # Run 100 episodes
    for i in range(100):
        gen = LogicPuzzleGenerator(seed=i)
        evolver = LogicPuzzleEvolver(seed=i)
        task = gen.generate_task(episode=i)
        variant = evolver.create_variant(task, episode=i)
        variant(**task["inputs"])
    
    final_memory = process.memory_info().rss
    memory_growth_mb = (final_memory - initial_memory) / (1024 * 1024)
    
    # Memory growth should be less than 100MB
    assert memory_growth_mb < 100, f"Memory grew by {memory_growth_mb:.1f}MB"
```

**Estimated Effort:** 3-4 hours

---

## Phase 3: Advanced Features (Week 3-4)

### 3.1 Mutation Testing

**Objective:** Verify test effectiveness by introducing bugs

**Tasks:**
1. Install mutmut or similar tool
2. Run mutation analysis on critical modules
3. Identify weakly tested code paths
4. Improve tests to catch mutations

**Implementation:**
```bash
pip install mutmut

# Run mutation testing
mutmut run --paths-to-mutate tiannara_core/evaluation/metrics.py

# Show results
mutmut results
```

**Estimated Effort:** 6-8 hours

---

### 3.2 Integration with External Systems

**Objective:** Test integration points with API, database, distributed computing

**Tasks:**
1. Mock external dependencies
2. Test API route handlers
3. Test database interactions
4. Test distributed worker communication

**Estimated Effort:** 8-12 hours

---

### 3.3 Security Testing

**Objective:** Validate input sanitization and resource limits

**Tasks:**
1. Test for injection attacks in task inputs
2. Validate resource limit enforcement
3. Test timeout mechanisms
4. Verify output sanitization

**Estimated Effort:** 4-6 hours

---

## Implementation Roadmap

### Week 1: Foundation (11-15 hours)
- [ ] CI/CD pipeline setup (3-4h)
- [ ] Code coverage measurement (2-3h)
- [ ] End-to-end pipeline tests (6-8h)

### Week 2: Performance & Quality (11-16 hours)
- [ ] Performance benchmarking (4-6h)
- [ ] Regression test suite (4-6h)
- [ ] Load testing (3-4h)

### Week 3-4: Advanced (18-26 hours)
- [ ] Mutation testing (6-8h)
- [ ] External system integration (8-12h)
- [ ] Security testing (4-6h)

**Total Estimated Effort:** 40-57 hours

---

## Success Criteria

Production testing infrastructure is complete when:

1. ✅ **Automated Testing**: All tests run automatically on every commit via CI/CD
2. ✅ **Coverage Threshold**: Minimum 80% code coverage enforced
3. ✅ **Performance Baselines**: All critical operations have performance benchmarks
4. ✅ **E2E Validation**: Full pipeline execution validated end-to-end
5. ✅ **Regression Prevention**: Baseline comparisons detect accuracy degradation
6. ✅ **Load Testing**: System validated under concurrent load
7. ✅ **Documentation**: Testing procedures documented in developer guide

---

## Next Steps

**Immediate Action (This Session):**
1. Set up code coverage measurement
2. Create end-to-end pipeline tests
3. Add basic performance benchmarks

**Follow-up Sessions:**
1. Configure CI/CD pipeline
2. Build regression test suite
3. Implement load testing
4. Add mutation testing

---

## Files to Create

```
tests/
├── test_e2e_pipeline.py          # End-to-end workflow tests
├── test_performance.py           # Performance benchmarks
├── test_regression.py            # Regression test suite
├── test_load.py                  # Load and stress tests
├── baselines/                    # Baseline results directory
│   ├── re_evolver_accuracy.json
│   ├── logic_evolver_accuracy.json
│   └── causal_evolver_accuracy.json
└── conftest.py                   # Shared test fixtures

.github/
└── workflows/
    └── test.yml                  # CI/CD pipeline

.coveragerc                       # Coverage configuration
pyproject.toml                    # Modern Python project config
scripts/
├── generate_benchmark_report.py  # Benchmark reporting
└── update_baselines.py           # Baseline management
```

---

## Conclusion

Current testing infrastructure provides excellent foundation (79 tests, 100% pass rate) but needs production-grade enhancements for reliable deployment. The planned additions will provide:

- **Automated quality gates** via CI/CD
- **Visibility** into code coverage and performance
- **Confidence** through regression and load testing
- **Scalability** validation for large experiments

Investment of 40-57 hours will transform the testing infrastructure from development-grade to production-ready.
