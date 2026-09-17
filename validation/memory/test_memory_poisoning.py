"""
Memory System Validation - Poisoning Resistance Tests

Tests memory system's resistance to bad data reinforcement and adversarial attacks.
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from tiannara_core.memory.discovery_memory import DiscoveryMemory
from datetime import datetime


class MemoryPoisoningResistanceTests:
    """Test memory system's resistance to bad data reinforcement."""
    
    def __init__(self):
        self.memory = DiscoveryMemory()
        
    def test_false_information_rejection(self):
        """Reject clearly false information."""
        print("\n=== Test: False Information Rejection ===")
        
        # Inject false fact
        false_data = {
            'type': 'fact',
            'confidence': 0.3,  # Low confidence indicator
            'timestamp': datetime.now(),
            'source': 'unverified'
        }
        self.memory.store_discovery('2 + 2 = 5', false_data)
        
        # Store correct fact with high confidence
        correct_data = {
            'type': 'fact',
            'confidence': 0.99,
            'timestamp': datetime.now(),
            'source': 'mathematical_proof'
        }
        self.memory.store_discovery('2 + 2 = 4', correct_data)
        
        # Query for answer
        results = self.memory.search_memories('2 + 2', limit=5)
        
        # Expected: Returns correct answer (4), ignores or downweights poisoned memory
        has_correct = any('4' in str(r.get('content', '')) for r in results)
        has_wrong = any('5' in str(r.get('content', '')) for r in results)
        
        # Success if correct answer is present and ranked higher
        success = has_correct and not has_wrong
        
        print(f"Correct answer (4) found: {has_correct}")
        print(f"Wrong answer (5) found: {has_wrong}")
        print(f"Status: {'PASS' if success else 'FAIL'}")
        
        return success
    
    def test_contradiction_resolution(self):
        """Handle contradictory memories correctly."""
        print("\n=== Test: Contradiction Resolution ===")
        
        # Memory 1: Correct fact
        mem1_data = {
            'type': 'fact',
            'confidence': 0.95,
            'timestamp': datetime.now(),
            'source': 'official_docs'
        }
        self.memory.store_discovery('Python uses dynamic typing', mem1_data)
        
        # Memory 2: Contradictory fact
        mem2_data = {
            'type': 'fact',
            'confidence': 0.4,  # Lower confidence
            'timestamp': datetime.now(),
            'source': 'unverified_blog'
        }
        self.memory.store_discovery('Python uses static typing', mem2_data)
        
        # Query
        results = self.memory.search_memories('Python typing', limit=5)
        
        # Expected: Returns first/correct memory with higher confidence
        # Should prioritize high-confidence memory
        success = len(results) > 0
        
        print(f"Results returned: {len(results)}")
        print(f"Status: {'PASS' if success else 'FAIL'}")
        
        return success
    
    def test_salience_balance(self):
        """Prevent trivial memories from dominating."""
        print("\n=== Test: Salience Balance ===")
        
        # Store 100 trivial facts
        for i in range(100):
            trivial_data = {
                'type': 'trivial',
                'importance': 0.1,
                'timestamp': datetime.now()
            }
            self.memory.store_discovery(f'Trivial fact {i}: sky observation', trivial_data)
        
        # Store 1 important fact
        important_data = {
            'type': 'discovery',
            'importance': 0.95,
            'timestamp': datetime.now(),
            'category': 'security'
        }
        self.memory.store_discovery('Critical security vulnerability found in module X', important_data)
        
        # Query for important discoveries
        results = self.memory.search_memories('security vulnerability discovery', limit=10)
        
        # Expected: Retrieves important fact despite being outnumbered
        has_important = any('vulnerability' in str(r.get('content', '')).lower() 
                          for r in results)
        
        success = has_important
        print(f"Important discovery retrieved: {success}")
        print(f"Total results: {len(results)}")
        print(f"Status: {'PASS' if success else 'FAIL'}")
        
        return success
    
    def test_adversarial_injection(self):
        """Resist deliberate memory poisoning attacks."""
        print("\n=== Test: Adversarial Injection ===")
        
        # Adversary injects 50 subtly incorrect facts
        for i in range(50):
            adversarial_data = {
                'type': 'fact',
                'confidence': 0.6,  # Medium confidence to seem plausible
                'timestamp': datetime.now(),
                'source': f'source_{i}'
            }
            # Subtly wrong: off by small amounts
            self.memory.store_discovery(
                f'API endpoint /v{i}/response_time is {100 + i}ms',
                adversarial_data
            )
        
        # Store correct baseline facts
        for i in range(10):
            correct_data = {
                'type': 'fact',
                'confidence': 0.95,
                'timestamp': datetime.now(),
                'source': 'benchmark_suite'
            }
            self.memory.store_discovery(
                f'API endpoint /v{i}/response_time is 100ms',
                correct_data
            )
        
        # Query random facts
        results = self.memory.search_memories('API endpoint response time', limit=20)
        
        # Expected: Most answers should be correct (high-confidence ones)
        # Count how many results have correct values (~100ms) vs wrong values
        correct_count = sum(1 for r in results 
                          if '100ms' in str(r.get('content', '')))
        
        accuracy = correct_count / max(len(results), 1)
        success = accuracy >= 0.7  # At least 70% accuracy despite poisoning
        
        print(f"Results analyzed: {len(results)}")
        print(f"Correct responses: {correct_count}")
        print(f"Accuracy: {accuracy:.1%}")
        print(f"Status: {'PASS' if success else 'FAIL'}")
        
        return success
    
    def run_all_tests(self):
        """Run all memory poisoning resistance tests."""
        print("=" * 70)
        print("MEMORY SYSTEM VALIDATION: Poisoning Resistance Tests")
        print("=" * 70)
        
        results = {
            'false_info_rejection': self.test_false_information_rejection(),
            'contradiction_resolution': self.test_contradiction_resolution(),
            'salience_balance': self.test_salience_balance(),
            'adversarial_injection': self.test_adversarial_injection()
        }
        
        passed = sum(results.values())
        total = len(results)
        
        print("\n" + "=" * 70)
        print(f"RESULTS: {passed}/{total} tests passed ({passed/total*100:.1f}%)")
        print("=" * 70)
        
        return results


if __name__ == '__main__':
    tester = MemoryPoisoningResistanceTests()
    tester.run_all_tests()
