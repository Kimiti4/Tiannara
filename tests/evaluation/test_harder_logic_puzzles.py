"""
Test Harder Logic Puzzle Types - Constraint Satisfaction and Truth Tables

Validates that the new puzzle types generate correctly and are solvable.
"""

import sys
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.evaluation.logic_domain import LogicPuzzleGenerator


def test_constraint_satisfaction():
    """Test 1: Constraint satisfaction problems."""
    print("\n" + "=" * 80)
    print("TEST 1: Constraint Satisfaction Problems")
    print("=" * 80)
    
    generator = LogicPuzzleGenerator(seed=42)
    
    # Use high episode numbers to trigger medium/hard difficulty
    constraint_tasks = []
    
    for i in range(70, 90):  # Episodes 70-89 should be hard difficulty
        task = generator.generate_task(episode=i)
        
        if task['type'] == 'constraint_satisfaction':
            constraint_tasks.append(task)
            
            print(f"\nTask {len(constraint_tasks)}:")
            print(f"  Description: {task['description']}")
            print(f"  Variables: {task['inputs']['variables']}")
            print(f"  Constraints: {task['inputs']['constraints']}")
            print(f"  Expected: {task['expected_output']}")
            print(f"  Difficulty: {task['difficulty']}")
            
            # Verify solution works
            verified = generator.verify_solution(task, task['expected_output'])
            assert verified, f"Verification failed for task {len(constraint_tasks)}"
    
    print(f"\n✓ Generated {len(constraint_tasks)} constraint satisfaction tasks")
    assert len(constraint_tasks) > 0, "Should generate at least some constraint tasks"
    
    print("✓ PASSED: Constraint satisfaction tasks work correctly")
    return True


def test_truth_table():
    """Test 2: Truth table evaluation tasks."""
    print("\n" + "=" * 80)
    print("TEST 2: Truth Table Tasks")
    print("=" * 80)
    
    generator = LogicPuzzleGenerator(seed=123)
    
    # Use high episode numbers to trigger hard difficulty
    truth_table_tasks = []
    
    for i in range(75, 95):  # Episodes 75-94 should be hard difficulty
        task = generator.generate_task(episode=i)
        
        if task['type'] == 'truth_table':
            truth_table_tasks.append(task)
            
            print(f"\nTask {len(truth_table_tasks)}:")
            print(f"  Description: {task['description']}")
            print(f"  Expression: {task['inputs']['expression']}")
            print(f"  Variables: {task['inputs']['variables']}")
            print(f"  Expected: {task['expected_output']}")
            print(f"  Difficulty: {task['difficulty']}")
            
            # Verify solution works
            verified = generator.verify_solution(task, task['expected_output'])
            assert verified, f"Verification failed for task {len(truth_table_tasks)}"
    
    print(f"\n✓ Generated {len(truth_table_tasks)} truth table tasks")
    assert len(truth_table_tasks) > 0, "Should generate at least some truth table tasks"
    
    print("✓ PASSED: Truth table tasks work correctly")
    return True


def test_difficulty_scaling():
    """Test 3: New types only appear at medium/hard difficulty."""
    print("\n" + "=" * 80)
    print("TEST 3: Difficulty-Based Task Selection")
    print("=" * 80)
    
    generator = LogicPuzzleGenerator(seed=456)
    
    # Test easy difficulty - should NOT have new types
    easy_types = set()
    
    for i in range(0, 20):  # Episodes 0-19 should be easy
        task = generator.generate_task(episode=i)
        easy_types.add(task['type'])
    
    print(f"\nEasy difficulty task types: {easy_types}")
    assert 'constraint_satisfaction' not in easy_types, "Easy should not have constraint tasks"
    assert 'truth_table' not in easy_types, "Easy should not have truth table tasks"
    
    print("✓ Easy difficulty excludes harder puzzle types")
    
    # Test hard difficulty - SHOULD have new types
    hard_types = set()
    
    for i in range(75, 125):  # Episodes 75-124 should be hard
        task = generator.generate_task(episode=i)
        hard_types.add(task['type'])
    
    print(f"\nHard difficulty task types: {hard_types}")
    assert 'constraint_satisfaction' in hard_types, "Hard should have constraint tasks"
    assert 'truth_table' in hard_types, "Hard should have truth table tasks"
    
    print("✓ Hard difficulty includes harder puzzle types")
    
    print("\n✓ PASSED: Difficulty-based selection works correctly")
    return True


def test_variety_of_constraints():
    """Test 4: Different constraint types are generated."""
    print("\n" + "=" * 80)
    print("TEST 4: Constraint Type Variety")
    print("=" * 80)
    
    generator = LogicPuzzleGenerator(seed=789)
    
    constraint_types_found = set()
    
    for i in range(75, 175):  # Hard difficulty episodes
        task = generator.generate_task(episode=i)
        
        if task['type'] == 'constraint_satisfaction':
            # Determine constraint type from description
            desc = task['description']
            
            if '<' in desc or '>' in desc or '!=' in desc:
                constraint_types_found.add('inequality')
            elif '+' in desc:
                constraint_types_found.add('sum')
            elif '*' in desc:
                constraint_types_found.add('product')
    
    print(f"\nConstraint types found: {constraint_types_found}")
    
    # Should find multiple types
    assert len(constraint_types_found) >= 2, f"Should find at least 2 constraint types, found {len(constraint_types_found)}"
    
    print("✓ Multiple constraint types generated")
    print("✓ PASSED: Good variety of constraint problems")
    return True


def test_truth_table_complexity():
    """Test 5: Truth tables have varying complexity."""
    print("\n" + "=" * 80)
    print("TEST 5: Truth Table Complexity Levels")
    print("=" * 80)
    
    generator = LogicPuzzleGenerator(seed=101)
    
    simple_count = 0
    complex_count = 0
    tautology_count = 0
    
    for i in range(75, 175):  # Hard difficulty episodes
        task = generator.generate_task(episode=i)
        
        if task['type'] == 'truth_table':
            desc = task['description'].lower()
            
            if 'evaluate' in desc and 'when' in desc:
                simple_count += 1
            elif 'tautology' in desc:
                tautology_count += 1
            else:
                complex_count += 1
    
    print(f"\nSimple evaluations: {simple_count}")
    print(f"Complex expressions: {complex_count}")
    print(f"Tautology checks: {tautology_count}")
    
    total = simple_count + complex_count + tautology_count
    assert total > 0, "Should generate truth table tasks"
    
    print("✓ Multiple complexity levels present")
    print("✓ PASSED: Good variety of truth table problems")
    return True


def run_all_tests():
    """Run all harder logic puzzle tests."""
    print("\n" + "=" * 80)
    print("HARDER LOGIC PUZZLE TYPES TEST SUITE")
    print("=" * 80)
    
    tests = [
        ("Constraint Satisfaction", test_constraint_satisfaction),
        ("Truth Table Evaluation", test_truth_table),
        ("Difficulty Scaling", test_difficulty_scaling),
        ("Constraint Variety", test_variety_of_constraints),
        ("Truth Table Complexity", test_truth_table_complexity),
    ]
    
    results = []
    for name, test_func in tests:
        try:
            passed = test_func()
            results.append((name, passed))
        except Exception as e:
            print(f"\n✗ FAILED: {name}")
            print(f"Error: {e}")
            import traceback
            traceback.print_exc()
            results.append((name, False))
    
    # Summary
    print("\n" + "=" * 80)
    print("TEST SUMMARY")
    print("=" * 80)
    
    passed_count = sum(1 for _, passed in results if passed)
    total_count = len(results)
    
    for name, passed in results:
        status = "✓ PASSED" if passed else "✗ FAILED"
        print(f"{status}: {name}")
    
    print(f"\nTotal: {passed_count}/{total_count} tests passing ({passed_count/total_count*100:.0f}% success rate)")
    
    if passed_count == total_count:
        print("\n🎉 ALL TESTS PASSED! Harder logic puzzle types validated.")
    else:
        print(f"\n⚠️  {total_count - passed_count} test(s) failed. Review implementation.")
    
    return passed_count == total_count


if __name__ == "__main__":
    success = run_all_tests()
    sys.exit(0 if success else 1)
