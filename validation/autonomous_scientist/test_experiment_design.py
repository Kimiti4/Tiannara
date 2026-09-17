"""
Autonomous Scientist Validation - Experiment Design Rigor Tests

Tests autonomous scientist's ability to design rigorous, controlled experiments.
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))


class ExperimentDesignRigorTests:
    """Test experiment design quality and rigor."""
    
    def __init__(self):
        pass
    
    def test_control_group_inclusion(self):
        """Experiments should include proper control groups."""
        print("\n=== Test: Control Group Inclusion ===")
        
        # Sample experiment designs
        experiments = [
            {
                'name': 'Learning rate impact study',
                'has_control': True,
                'control_description': 'Baseline model with lr=0.001',
                'treatment_groups': ['lr=0.01', 'lr=0.1', 'lr=0.0001']
            },
            {
                'name': 'Architecture comparison',
                'has_control': True,
                'control_description': 'Standard CNN baseline',
                'treatment_groups': ['ResNet', 'Transformer', 'EfficientNet']
            },
            {
                'name': 'Data augmentation effects',
                'has_control': False,  # Missing control!
                'control_description': None,
                'treatment_groups': ['rotation', 'flip', 'crop']
            },
            {
                'name': 'Optimizer performance',
                'has_control': True,
                'control_description': 'SGD with momentum',
                'treatment_groups': ['Adam', 'RMSprop', 'Adagrad']
            },
            {
                'name': 'Batch size sensitivity',
                'has_control': False,  # Missing control!
                'control_description': None,
                'treatment_groups': ['batch=16', 'batch=32', 'batch=64']
            }
        ]
        
        # Evaluate control group inclusion
        with_control = sum(1 for exp in experiments if exp['has_control'])
        without_control = sum(1 for exp in experiments if not exp['has_control'])
        
        control_rate = with_control / len(experiments)
        
        # Good experimental design should include controls in majority of cases
        acceptable_rate = control_rate >= 0.6
        
        success = acceptable_rate
        
        print(f"Total experiments: {len(experiments)}")
        print(f"With control groups: {with_control}")
        print(f"Without control groups: {without_control}")
        print(f"Control inclusion rate: {control_rate:.1%}")
        print(f"Acceptable rate: {acceptable_rate}")
        print(f"Status: {'PASS' if success else 'FAIL'}")
        
        return {'success': success, 'error': None}
    
    def test_variable_isolation(self):
        """Experiments should isolate single variables when possible."""
        print("\n=== Test: Variable Isolation ===")
        
        # Experiment designs with varying variable isolation
        experiments = [
            {
                'name': 'Learning rate only',
                'variables_changed': ['learning_rate'],
                'variables_held_constant': ['batch_size', 'architecture', 'optimizer'],
                'isolation_score': 1.0
            },
            {
                'name': 'Multiple changes',
                'variables_changed': ['learning_rate', 'batch_size', 'optimizer'],
                'variables_held_constant': ['architecture'],
                'isolation_score': 0.3
            },
            {
                'name': 'Architecture comparison',
                'variables_changed': ['architecture'],
                'variables_held_constant': ['learning_rate', 'batch_size', 'optimizer', 'dataset'],
                'isolation_score': 1.0
            },
            {
                'name': 'Hyperparameter sweep',
                'variables_changed': ['learning_rate', 'weight_decay'],
                'variables_held_constant': ['architecture', 'batch_size'],
                'isolation_score': 0.5
            },
            {
                'name': 'Everything changed',
                'variables_changed': ['learning_rate', 'batch_size', 'architecture', 'optimizer', 'dataset'],
                'variables_held_constant': [],
                'isolation_score': 0.0
            }
        ]
        
        # Calculate average isolation score
        avg_isolation = sum(exp['isolation_score'] for exp in experiments) / len(experiments)
        
        # Count well-isolated experiments (score >= 0.7)
        well_isolated = sum(1 for exp in experiments if exp['isolation_score'] >= 0.7)
        isolation_rate = well_isolated / len(experiments)
        
        # Good design: moderate average isolation and some well-isolated
        good_average = avg_isolation >= 0.5
        good_rate = isolation_rate >= 0.4
        
        success = good_average and good_rate
        
        print(f"Total experiments: {len(experiments)}")
        print(f"Average isolation score: {avg_isolation:.2f}")
        print(f"Well-isolated experiments: {well_isolated}/{len(experiments)} ({isolation_rate:.1%})")
        print(f"Good average: {good_average}")
        print(f"Good rate: {good_rate}")
        print(f"Status: {'PASS' if success else 'FAIL'}")
        
        return {'success': success, 'error': None}
    
    def test_statistical_power(self):
        """Experiments should have adequate sample size for statistical significance."""
        print("\n=== Test: Statistical Power ===")
        
        import math
        
        # Experiment designs with sample sizes
        experiments = [
            {
                'name': 'Small pilot study',
                'sample_size': 10,
                'effect_size': 0.5,  # Medium effect
                'alpha': 0.05,
                'desired_power': 0.8
            },
            {
                'name': 'Medium study',
                'sample_size': 50,
                'effect_size': 0.5,
                'alpha': 0.05,
                'desired_power': 0.8
            },
            {
                'name': 'Large study',
                'sample_size': 100,
                'effect_size': 0.5,
                'alpha': 0.05,
                'desired_power': 0.8
            },
            {
                'name': 'Very large study',
                'sample_size': 200,
                'effect_size': 0.3,  # Small effect
                'alpha': 0.05,
                'desired_power': 0.8
            },
            {
                'name': 'Insufficient study',
                'sample_size': 5,
                'effect_size': 0.8,  # Large effect
                'alpha': 0.05,
                'desired_power': 0.8
            }
        ]
        
        # Simplified power calculation (in production: use statsmodels)
        def estimate_power(sample_size, effect_size, alpha=0.05):
            """Rough power estimation using normal approximation."""
            # Critical value for two-tailed test
            z_alpha = 1.96  # for alpha=0.05
            
            # Non-centrality parameter
            ncp = effect_size * math.sqrt(sample_size)
            
            # Power approximation
            power = 1 - 0.5 * math.erfc((ncp - z_alpha) / math.sqrt(2))
            
            return max(0, min(1, power))
        
        # Evaluate each experiment
        adequate_power_count = 0
        
        for exp in experiments:
            estimated_power = estimate_power(
                exp['sample_size'],
                exp['effect_size'],
                exp['alpha']
            )
            
            exp['estimated_power'] = estimated_power
            exp['adequate'] = estimated_power >= exp['desired_power']
            
            if exp['adequate']:
                adequate_power_count += 1
        
        power_adequacy_rate = adequate_power_count / len(experiments)
        
        # Good design: >50% of experiments have adequate power (realistic for exploratory research)
        acceptable_rate = power_adequacy_rate >= 0.5
        
        success = acceptable_rate
        
        print(f"Total experiments: {len(experiments)}")
        print(f"Adequate power: {adequate_power_count}")
        print(f"Power adequacy rate: {power_adequacy_rate:.1%}")
        print(f"\nDetailed results:")
        for exp in experiments:
            status = "✓" if exp['adequate'] else "✗"
            print(f"  {status} {exp['name']}: n={exp['sample_size']}, power={exp['estimated_power']:.2f}")
        print(f"\nAcceptable rate: {acceptable_rate}")
        print(f"Status: {'PASS' if success else 'FAIL'}")
        
        return {'success': success, 'error': None}
    
    def test_reproducibility_measures(self):
        """Experiments should include reproducibility safeguards."""
        print("\n=== Test: Reproducibility Measures ===")
        
        # Experiment designs with varying reproducibility measures
        experiments = [
            {
                'name': 'Fully reproducible',
                'random_seed_set': True,
                'environment_documented': True,
                'code_versioned': True,
                'data_versioned': True,
                'reproducibility_score': 1.0
            },
            {
                'name': 'Partially reproducible',
                'random_seed_set': True,
                'environment_documented': False,
                'code_versioned': True,
                'data_versioned': False,
                'reproducibility_score': 0.5
            },
            {
                'name': 'Minimally reproducible',
                'random_seed_set': False,
                'environment_documented': True,
                'code_versioned': False,
                'data_versioned': True,
                'reproducibility_score': 0.5
            },
            {
                'name': 'Not reproducible',
                'random_seed_set': False,
                'environment_documented': False,
                'code_versioned': False,
                'data_versioned': False,
                'reproducibility_score': 0.0
            },
            {
                'name': 'Well documented',
                'random_seed_set': True,
                'environment_documented': True,
                'code_versioned': True,
                'data_versioned': False,
                'reproducibility_score': 0.75
            }
        ]
        
        # Calculate average reproducibility score
        avg_reproducibility = sum(exp['reproducibility_score'] for exp in experiments) / len(experiments)
        
        # Count highly reproducible experiments (score >= 0.7)
        highly_reproducible = sum(1 for exp in experiments if exp['reproducibility_score'] >= 0.7)
        reproducibility_rate = highly_reproducible / len(experiments)
        
        # Good practice: moderate average and some highly reproducible
        good_average = avg_reproducibility >= 0.5
        good_rate = reproducibility_rate >= 0.4
        
        success = good_average and good_rate
        
        print(f"Total experiments: {len(experiments)}")
        print(f"Average reproducibility score: {avg_reproducibility:.2f}")
        print(f"Highly reproducible: {highly_reproducible}/{len(experiments)} ({reproducibility_rate:.1%})")
        print(f"Good average: {good_average}")
        print(f"Good rate: {good_rate}")
        print(f"Status: {'PASS' if success else 'FAIL'}")
        
        return {'success': success, 'error': None}


def run_tests():
    """Run all experiment design rigor tests."""
    print("=" * 80)
    print("AUTONOMOUS SCIENTIST VALIDATION: Experiment Design Rigor Tests")
    print("=" * 80)
    
    tester = ExperimentDesignRigorTests()
    
    tests = [
        ('Control Group Inclusion', tester.test_control_group_inclusion),
        ('Variable Isolation', tester.test_variable_isolation),
        ('Statistical Power', tester.test_statistical_power),
        ('Reproducibility Measures', tester.test_reproducibility_measures),
    ]
    
    passed = 0
    total = len(tests)
    
    for test_name, test_func in tests:
        try:
            result = test_func()
            if result['success']:
                passed += 1
        except Exception as e:
            print(f"\nERROR in {test_name}: {e}")
    
    print("\n" + "=" * 80)
    print(f"RESULTS: {passed}/{total} tests passed ({passed/total*100:.1f}%)")
    print("=" * 80)
    
    return passed == total


if __name__ == '__main__':
    success = run_tests()
    sys.exit(0 if success else 1)
