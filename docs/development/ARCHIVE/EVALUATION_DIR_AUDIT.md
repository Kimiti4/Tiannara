# Evaluation Directory Audit & Consolidation Plan

**Date**: April 30, 2026  
**Phase**: Phase 1 Day 2 - Testing Infrastructure Consolidation  
**Status**: 📋 **AUDIT COMPLETE - READY FOR CONSOLIDATION**

---

## 📊 Current State Analysis

### File Breakdown

| Category | Count | Lines (est.) | Purpose |
|----------|-------|--------------|---------|
| **Markdown Docs** | ~50 | ~500 KB | Documentation, progress reports |
| **Domain Files** | 12 | ~8,000 | Production domain implementations |
| **Test Scripts** | 12 | ~4,000 | One-off test scripts |
| **Experiment Runners** | ~15 | ~10,000 | Ad-hoc experiment execution |
| **Production Code** | ~20 | ~15,000 | Core evaluation infrastructure |
| **JSON Results** | ~3 | ~5 KB | Test output data |
| **Subdirectories** | 3 | N/A | test_suites/, archive/, logs/ |
| **Total Python** | **81** | **~37,000** | Mixed concerns |

---

## 🔍 Identified Issues

### Issue 1: Documentation Clutter
**Problem**: 50 markdown files in production code directory
**Impact**: Makes it hard to find actual code, clutters IDE
**Examples**:
- `ABSTRACTION_INTEGRATION_SUMMARY.md`
- `COMPLETE_PROJECT_SUMMARY.md`
- `DOMAIN_EXPANSION_PROGRESS_REPORT.md`
- `ECM_IMPLEMENTATION_PROGRESS.md`
- etc.

**Solution**: Move all .md files to `docs/evaluation/` directory

---

### Issue 2: Scattered Test Scripts
**Problem**: 12 test_*.py files mixed with production code
**Impact**: Unclear what's test vs production, hard to run tests systematically
**Examples**:
- `test_baseline_accuracy.py`
- `test_week21_integration.py`
- `test_nlp_integration.py`
- `test_cross_domain.py`
- etc.

**Solution**: Move all test_*.py files to `tests/evaluation/` directory

---

### Issue 3: Ad-Hoc Experiment Runners
**Problem**: ~15 run_*.py scripts for one-time experiments
**Impact**: Clutters directory, most are obsolete after experiments complete
**Examples**:
- `run_multi_domain_experiment.py` (53.7 KB - huge!)
- `run_experiment.py`
- `run_logic_experiment.py`
- `run_adaptive_experiment.py`
- etc.

**Solution**: 
- Archive completed experiment runners to `archive/experiments/`
- Keep only active/reusable ones
- Create unified experiment runner framework

---

### Issue 4: Duplicate Debugging Scripts
**Problem**: Multiple debug_*.py files for specific issues
**Impact**: Temporary debugging code left in production
**Examples**:
- `debug_bic_regression.py`
- `debug_piecewise_failures.py`
- `debug_poly_failures.py`
- `debug_poly_fit.py`
- `debug_strategy_selection.py`

**Solution**: Delete all debug_*.py files (issues already resolved)

---

### Issue 5: Redundant Summary Files
**Problem**: Multiple summary/completion reports for same work
**Impact**: Confusion about which is authoritative
**Examples**:
- `TESTING_COMPLETE_SUMMARY.md`
- `TESTING_INFRASTRUCTURE_FINAL.md`
- `TESTING_INFRASTRUCTURE_SUMMARY.md`
- `PRODUCTION_TESTING_IMPLEMENTATION_COMPLETE.md`
- `PRODUCTION_TESTING_PROGRESS.md`

**Solution**: Consolidate into single `README.md` per major feature

---

## 🎯 Consolidation Strategy

### Step 1: Reorganize Directory Structure

```
tiannara_core/evaluation/
├── __init__.py
├── README.md                          # New: Overview of evaluation system
│
├── # Production Code (keep here)
├── evaluator.py
├── metrics.py
├── scoring.py
├── history.py
├── novelty.py
├── stability.py
├── variant_pool.py
├── episode_logger.py
├── error_tracker.py
├── issue_detection_system.py
├── information_pruner.py
├── stagnation_detection.py
├── verifiable_reasoning.py
├── causal_observer.py
│
├── # Domain Implementations (keep here)
├── algorithm_domain.py
├── logic_domain.py
├── prediction_domain.py
├── temporal_domain.py
├── hybrid_domain.py
├── causal_system_domain.py
├── reverse_engineering_domain.py
├── combinatorial_optimization_domain.py
│
├── # Evolution Engines (keep here)
├── evolution_engine.py
├── logic_evolution_engine.py
├── temporal_evolution_engine.py
├── causal_system_evolver.py
├── reverse_engineering_evolver.py
├── combinatorial_optimization_evolver.py
├── hybrid_evolution_engine.py
│
├── # Advanced Features (keep here)
├── skill_abstraction_engine.py
├── skill_abstraction_integration.py
├── unified_skill_representation.py
├── ecm_forgetting_mechanism.py
├── daemon_orchestrator.py
├── multi_agent_autonomy.py
├── demonstration_projects.py
├── efficiency_features.py
├── abstraction_production_integration.py
├── unified_skill_integration_guide.py
├── combinatorial_enhancements.py
│
├── # Integration Utilities (keep here)
├── populate_skill_memory.py
├── analyze_re_skill_transfer.py
├── extended_skill_transfer_experiment.py
├── quick_skill_transfer_test.py
├── validate_skill_transfer.py
│
└── # Moved Out ↓
    
docs/evaluation/                       # NEW: All documentation
├── ABSTRACTION_INTEGRATION_SUMMARY.md
├── ADVANCED_FEATURES_SUMMARY.md
├── COMPLETE_PROJECT_SUMMARY.md
├── ... (all 50 .md files)

tests/evaluation/                      # NEW: All test scripts
├── test_baseline_accuracy.py
├── test_week21_integration.py
├── test_nlp_integration.py
├── test_cross_domain.py
├── test_causal_improvements.py
├── test_harder_logic_puzzles.py
├── test_re_improvements.py
├── test_modulo_improvements.py
├── test_phase1_improvements.py
├── test_phase1_targeted.py
├── test_bp.py
├── test_penalty.py
├── test_lagrange.py
├── test_reveng_clean.py
└── test_debug_*.py                    # Consolidated debug tests

archive/experiments/                   # NEW: Completed experiment runners
├── run_multi_domain_experiment.py
├── run_experiment.py
├── run_full_comparison.py
├── run_refined_comparison.py
├── run_comparative_abstraction_experiment.py
├── run_adaptive_experiment.py
├── run_adaptive_logic_experiment.py
├── run_hybrid_experiment.py
├── run_logic_experiment.py
├── run_refined_experiment.py
├── run_5domain_temporal_experiment.py
└── ... (other run_*.py files)

archive/debug/                         # NEW: Delete these (obsolete)
├── debug_bic_regression.py            # DELETE
├── debug_piecewise_failures.py        # DELETE
├── debug_poly_failures.py             # DELETE
├── debug_poly_fit.py                  # DELETE
└── debug_strategy_selection.py        # DELETE
```

---

### Step 2: Expected Reductions

| Action | Files Affected | Lines Removed | Notes |
|--------|---------------|---------------|-------|
| Move .md files to docs/ | 50 | 0 (just moved) | Cleaner code directory |
| Move test_*.py to tests/ | 12 | 0 (just moved) | Proper test organization |
| Archive experiment runners | 15 | 0 (just moved) | Preserved for reference |
| Delete debug scripts | 5 | ~500 | Obsolete debugging code |
| Consolidate redundant summaries | 5 .md → 1 | ~30 KB | Single source of truth |
| **Total Cleanup** | **87 files** | **~500 lines deleted** | **Much cleaner structure** |

---

### Step 3: Benefits

#### Immediate Benefits
1. ✅ **Cleaner Code Directory**: Only production code remains
2. ✅ **Proper Test Organization**: All tests in dedicated directory
3. ✅ **Documentation Centralized**: Easy to find docs
4. ✅ **Reduced Cognitive Load**: Clear separation of concerns
5. ✅ **Easier Navigation**: IDE shows relevant files only

#### Long-Term Benefits
1. ✅ **Better Maintainability**: Clear structure for future development
2. ✅ **Faster Onboarding**: New developers understand layout immediately
3. ✅ **Cleaner Git History**: No more accidental doc/test commits to code dir
4. ✅ **Easier CI/CD**: Test discovery simplified
5. ✅ **Professional Structure**: Matches industry best practices

---

## 🚀 Implementation Plan

### Phase 1: Create New Directories
```bash
mkdir -p docs/evaluation
mkdir -p tests/evaluation
mkdir -p archive/experiments
```

### Phase 2: Move Documentation
```bash
mv tiannara_core/evaluation/*.md docs/evaluation/
```

### Phase 3: Move Test Scripts
```bash
mv tiannara_core/evaluation/test_*.py tests/evaluation/
```

### Phase 4: Archive Experiment Runners
```bash
mv tiannara_core/evaluation/run_*.py archive/experiments/
```

### Phase 5: Delete Obsolete Debug Scripts
```bash
rm tiannara_core/evaluation/debug_*.py
```

### Phase 6: Update Import Paths
Files that import from moved locations need path updates:
- Check `sys.path` modifications
- Update relative imports if any
- Verify all imports still work

### Phase 7: Create README.md
Create comprehensive `tiannara_core/evaluation/README.md` documenting:
- Directory structure
- How to run tests
- How to add new domains
- How to run experiments
- Architecture overview

---

## ⚠️ Risk Mitigation

### Risk 1: Broken Imports
**Mitigation**:
- Search for all imports before moving
- Update import paths systematically
- Run full test suite after reorganization

### Risk 2: Lost Experiment Code
**Mitigation**:
- Archive instead of delete
- Document what each experiment was for
- Keep git history intact

### Risk 3: Test Discovery Issues
**Mitigation**:
- Ensure pytest configuration updated
- Verify all tests discoverable in new location
- Run test suite to confirm

---

## 📈 Success Metrics

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Files in evaluation/ | 81 .py + 50 .md | ~40 .py only | 50% reduction |
| Clarity of purpose | Mixed concerns | Clear separation | ✅ Much better |
| Test organization | Scattered | Centralized | ✅ Professional |
| Documentation access | Hard to find | Easy to locate | ✅ Improved |
| Navigation speed | Slow (many files) | Fast (relevant only) | ✅ 2x faster |

---

## 🎓 Lessons Learned

1. **Keep code directories clean**: Don't mix docs/tests with production code
2. **Archive, don't delete**: Preserve experimental code for reference
3. **Document as you go**: Prevents accumulation of summary files
4. **Separate concerns early**: Easier to maintain proper structure from start
5. **Regular cleanup**: Don't let clutter accumulate over time

---

## 📅 Next Steps

1. Execute reorganization plan
2. Update import paths
3. Run full test suite
4. Create comprehensive README.md
5. Document the new structure in project docs

---

**Status**: 📋 **PLAN DEFINED - READY TO EXECUTE**

**Expected Time**: 2-3 hours for complete reorganization

**Risk Level**: Low (mostly file moves, no code changes)
