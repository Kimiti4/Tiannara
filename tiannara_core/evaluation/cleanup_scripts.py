"""
Cleanup script for evaluation directory.

Organizes temporary debug/test scripts to reduce clutter.
"""

import shutil
from pathlib import Path

eval_dir = Path(__file__).parent

# Scripts to KEEP (useful for ongoing development/testing)
keep_scripts = [
    "validate_skill_transfer.py",      # Validates skill transfer effectiveness
    "analyze_re_skill_transfer.py",     # Analyzes RE skill transfer impact
    "test_reveng_clean.py",             # Clean RE domain test
    "error_tracker.py",                 # Core error tracking infrastructure
    "run_multi_domain_experiment.py",   # Main experiment runner
    "run_experiment.py",                # Single-domain experiment runner
]

# Scripts to ARCHIVE (move to archive/ directory for reference)
archive_scripts = [
    # Debug scripts - useful for understanding past issues
    "debug_skill_transfer.py",
    "debug_causal.py",
    "debug_causal_ep1.py",
    "debug_causal_evolver.py",
    "debug_causal_inputs.py",
    "debug_causal_tasks.py",
    "debug_branching.py",
    "debug_branching_causal.py",
    "debug_branching_regression.py",
    "debug_intervention.py",
    "debug_linear_chain.py",
    "debug_logic_specific.py",
    "debug_rev_eng_tasks.py",
    "debug_reveng_specific.py",
    "debug_piecewise_ep5.py",
    "debug_poly_episode15.py",
    "debug_ep6_piecewise.py",
    "debug_ep9_piecewise.py",
    "debug_modulo_ep3.py",
    "debug_regression.py",
    "debug_evolver_regression.py",
    
    # Test scripts - specific fixes/tests
    "test_causal_fix.py",
    "test_causal_improved.py",
    "test_ep9_rule_extraction.py",
    "test_evaluator.py",
    "test_modulo.py",
    "test_poly.py",
    "test_poly_eval.py",
    "test_rev_eng_improved.py",
    
    # Analysis scripts - one-time analyses
    "analyze_causal_failures.py",
    "analyze_counterfactual.py",
    "analyze_ensemble_performance.py",
    "analyze_logic_failures.py",
    "analyze_piecewise_failures.py",
    "analyze_reveng_failures.py",
    
    # Check scripts - verification scripts
    "check_ep9.py",
    "check_ep9_expected.py",
    "check_ep9_modulo.py",
    "check_modulo_strategy.py",
    "check_obs_vars.py",
    "check_piecewise_strategy.py",
    "check_poly_strategy.py",
]

# Scripts to DELETE (one-off debugging, no longer needed)
delete_scripts = [
    # Root level debug scripts
    "../debug_arith_search.py",
    "../debug_mutations.py",
    "../debug_task_types.py",
    "../test_closure.py",
    "../test_task_performance.py",
    "../check_correctness.py",
    "../analyze_domain_refinements.py",
    "../analyze_max_success.py",
]

def cleanup():
    """Execute the cleanup plan."""
    
    print("="*80)
    print("EVALUATION DIRECTORY CLEANUP")
    print("="*80)
    
    # Create archive directory
    archive_dir = eval_dir / "archive"
    archive_dir.mkdir(exist_ok=True)
    print(f"\nArchive directory: {archive_dir}")
    
    # Archive scripts
    print(f"\nArchiving {len(archive_scripts)} scripts...")
    archived_count = 0
    for script in archive_scripts:
        src = eval_dir / script
        if src.exists():
            dst = archive_dir / script
            shutil.move(str(src), str(dst))
            archived_count += 1
            print(f"  ✓ {script}")
        else:
            print(f"  ✗ {script} (not found)")
    
    print(f"\nArchived: {archived_count}/{len(archive_scripts)} scripts")
    
    # Delete scripts
    print(f"\nDeleting {len(delete_scripts)} obsolete scripts...")
    deleted_count = 0
    for script in delete_scripts:
        src = eval_dir / script
        if src.exists():
            src.unlink()
            deleted_count += 1
            print(f"  ✓ Deleted {src.name}")
        else:
            print(f"  ✗ {script} (not found)")
    
    print(f"\nDeleted: {deleted_count}/{len(delete_scripts)} scripts")
    
    # Summary
    print("\n" + "="*80)
    print("CLEANUP SUMMARY")
    print("="*80)
    print(f"Scripts kept:          {len(keep_scripts)}")
    print(f"Scripts archived:      {archived_count}")
    print(f"Scripts deleted:       {deleted_count}")
    print(f"\nRemaining in evaluation/:")
    
    remaining = list(eval_dir.glob("*.py"))
    remaining_names = sorted([f.name for f in remaining if f.is_file()])
    for name in remaining_names:
        marker = " [KEEP]" if name in keep_scripts else ""
        print(f"  - {name}{marker}")
    
    print(f"\nTotal Python files: {len(remaining_names)}")
    print(f"\nCleanup complete!")

if __name__ == "__main__":
    cleanup()

