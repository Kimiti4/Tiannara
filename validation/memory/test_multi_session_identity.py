"""
Memory System Validation - Multi-Session Identity Tests

Tests memory system's ability to maintain identity and context across sessions.
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from tiannara_core.memory.discovery_memory import DiscoveryMemory
from tiannara_core.memory.experience_db import ExperienceDB
from datetime import datetime, timedelta


class MultiSessionIdentityTests:
    """Test memory system's ability to maintain identity across sessions."""
    
    def __init__(self):
        self.memory = DiscoveryMemory()
        self.experience_db = ExperienceDB()
        
    def test_experiment_lineage_tracking(self):
        """Retrieve correct experiment chain across sessions."""
        print("\n=== Test: Experiment Lineage Tracking ===")
        
        # Session 1: Start algorithm research
        session_1_data = {
            'experiment_id': 'exp_001',
            'domain': 'algorithms',
            'focus': 'optimization',
            'timestamp': datetime.now() - timedelta(days=10),
            'results': {'accuracy': 0.85}
        }
        self.memory.save_report(
            question='Algorithm optimization started',
            source='session_1',
            report=session_1_data,
            tags=['algorithm', 'optimization', 'experiment']
        )
        
        # Session 5: Continue work
        session_5_data = {
            'experiment_id': 'exp_001',
            'iteration': 5,
            'improvement': 0.05,
            'timestamp': datetime.now() - timedelta(days=5)
        }
        self.memory.save_report(
            question='Optimization iteration 5',
            source='session_5',
            report=session_5_data,
            tags=['algorithm', 'optimization', 'iteration']
        )
        
        # Session 10: Query for lineage
        all_reports = self.memory.list_reports(limit=50)
        results = [r for r in all_reports if 'algorithm' in r.get('question', '').lower() 
                  or 'optimization' in str(r.get('report', {})).lower()]
        
        # Expected: Retrieves algorithm optimization lineage
        success = len(results) >= 2
        print(f"Results found: {len(results)}")
        print(f"Status: {'PASS' if success else 'FAIL'}")
        
        return success
    
    def test_cross_session_entity_resolution(self):
        """Resolve entity references across sessions."""
        print("\n=== Test: Cross-Session Entity Resolution ===")
        
        # Session 1: Create model
        model_data = {
            'entity_type': 'model',
            'name': 'Alpha',
            'performance': 0.92,
            'timestamp': datetime.now() - timedelta(days=7)
        }
        self.memory.store_discovery('Created model Alpha', model_data)
        
        # Session 3: Query about Alpha
        results = self.memory.search_memories('model Alpha performance', limit=5)
        
        # Expected: Retrieves Alpha's performance metrics
        success = any('Alpha' in str(r.get('content', '')) or 
                     'Alpha' in str(r.get('metadata', {})) 
                     for r in results)
        
        print(f"Results mentioning Alpha: {success}")
        print(f"Status: {'PASS' if success else 'FAIL'}")
        
        return success
    
    def test_temporal_continuity(self):
        """Maintain temporal coherence across gaps."""
        print("\n=== Test: Temporal Continuity ===")
        
        # Day 1: Start experiment
        day1_data = {
            'experiment_id': 'exp_A',
            'phase': 'initialization',
            'timestamp': datetime.now() - timedelta(days=10)
        }
        self.memory.store_discovery('Experiment A started', day1_data)
        
        # Day 3: Continue
        day3_data = {
            'experiment_id': 'exp_A',
            'phase': 'testing',
            'timestamp': datetime.now() - timedelta(days=8)
        }
        self.memory.store_discovery('Experiment A testing phase', day3_data)
        
        # Day 10: Query about Day 1
        results = self.memory.search_memories('Experiment A initialization', limit=5)
        
        # Expected: Correctly retrieves Day 1 events
        success = len(results) > 0
        print(f"Day 1 events retrieved: {success}")
        print(f"Status: {'PASS' if success else 'FAIL'}")
        
        return success
    
    def test_identity_fragmentation_detection(self):
        """Detect conflicting self-state representations."""
        print("\n=== Test: Identity Fragmentation Detection ===")
        
        # Session 1: Security focus
        self.memory.store_discovery(
            'Primary focus: security research',
            {'focus_area': 'security', 'timestamp': datetime.now() - timedelta(days=5)}
        )
        
        # Session 5: Algorithm focus
        self.memory.store_discovery(
            'Primary focus: algorithm optimization',
            {'focus_area': 'algorithms', 'timestamp': datetime.now() - timedelta(days=2)}
        )
        
        # Query current focus
        results = self.memory.search_memories('primary focus', limit=10)
        
        # Expected: Acknowledges evolution or provides context
        # Should find both entries without contradiction
        has_security = any('security' in str(r.get('content', '')).lower() for r in results)
        has_algorithms = any('algorithm' in str(r.get('content', '')).lower() for r in results)
        
        success = has_security and has_algorithms
        print(f"Security focus found: {has_security}")
        print(f"Algorithm focus found: {has_algorithms}")
        print(f"Both preserved (no fragmentation): {success}")
        print(f"Status: {'PASS' if success else 'FAIL'}")
        
        return success
    
    def run_all_tests(self):
        """Run all multi-session identity tests."""
        print("=" * 70)
        print("MEMORY SYSTEM VALIDATION: Multi-Session Identity Tests")
        print("=" * 70)
        
        results = {
            'experiment_lineage': self.test_experiment_lineage_tracking(),
            'entity_resolution': self.test_cross_session_entity_resolution(),
            'temporal_continuity': self.test_temporal_continuity(),
            'identity_fragmentation': self.test_identity_fragmentation_detection()
        }
        
        passed = sum(results.values())
        total = len(results)
        
        print("\n" + "=" * 70)
        print(f"RESULTS: {passed}/{total} tests passed ({passed/total*100:.1f}%)")
        print("=" * 70)
        
        return results


if __name__ == '__main__':
    tester = MultiSessionIdentityTests()
    tester.run_all_tests()
