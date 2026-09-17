# Archived Scripts

This directory contains historical debug, test, and analysis scripts that were used during development but are no longer actively maintained.

## Purpose

These scripts are kept for reference only. They document:
- Past debugging sessions and their solutions
- One-time analyses of domain performance
- Specific fix verification tests
- Historical experiment configurations

## Organization

### Debug Scripts (18 files)
Scripts used to investigate specific failures or issues:
- `debug_causal*.py` - Causal domain debugging
- `debug_branching*.py` - Branching prediction issues
- `debug_intervention.py` - Counterfactual intervention testing
- `debug_piecewise*.py` - Piecewise function detection issues
- `debug_modulo*.py` - Modulo pattern detection
- `debug_regression*.py` - Regression fitting problems
- `debug_skill_transfer.py` - Skill transfer integration debugging

### Test Scripts (7 files)
Verification tests for specific fixes:
- `test_causal_*.py` - Causal domain improvements
- `test_ep9_rule_extraction.py` - Rule extraction verification
- `test_evaluator.py` - Evaluator component testing
- `test_modulo.py`, `test_poly*.py` - Pattern detection tests
- `test_rev_eng_improved.py` - Reverse engineering improvements

### Analysis Scripts (6 files)
One-time performance analyses:
- `analyze_*_failures.py` - Domain-specific failure analysis
- `analyze_counterfactual.py` - Counterfactual reasoning analysis
- `analyze_ensemble_performance.py` - Ensemble method evaluation

### Check Scripts (7 files)
Quick verification scripts:
- `check_ep9*.py` - Episode 9 specific checks
- `check_*_strategy.py` - Strategy selection verification
- `check_obs_vars.py` - Observable variable validation

## Usage

These scripts are **NOT part of the active codebase**. They are preserved for:
1. Understanding past design decisions
2. Referencing debugging approaches
3. Learning from previous investigations

To use any of these scripts:
1. Copy to parent directory if needed
2. Update imports and paths as necessary
3. Be aware they may be outdated

## Active Scripts

For current development, use scripts in the parent `evaluation/` directory:
- `validate_skill_transfer.py` - Validates cross-domain skill transfer
- `analyze_re_skill_transfer.py` - Analyzes RE-specific transfer impact
- `test_reveng_clean.py` - Clean reverse engineering domain test
- `error_tracker.py` - Centralized error tracking system
- `run_multi_domain_experiment.py` - Main multi-domain experiment runner
- `run_experiment.py` - Single-domain experiment runner

## Cleanup History

**Date:** April 30, 2026  
**Action:** Moved 42 temporary scripts to archive  
**Reason:** Reduce clutter in main evaluation directory  
**Result:** Reduced from ~74 files to 32 files (57% reduction)

---

*Note: This archive can be safely deleted if disk space is needed, as all functionality has been integrated into the main codebase or is obsolete.*
