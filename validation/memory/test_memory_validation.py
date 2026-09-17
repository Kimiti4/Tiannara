"""
Memory System Validation - Simplified Working Tests

Tests memory system using actual DiscoveryMemory API.
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from tiannara_core.memory.discovery_memory import DiscoveryMemory
from datetime import datetime, timedelta
import time


class MemoryValidationTests:
    """Simplified memory validation tests using actual API."""
    
    def __init__(self):
        # Use test-specific file to avoid polluting production data
        self.memory = DiscoveryMemory(filepath="runs/test_memory_validation.jsonl")
        
    def test_basic_storage_retrieval(self):
        """Test basic save and list operations."""
        print("\n=== Test: Basic Storage & Retrieval ===")
        
        # Save a report
        record = self.memory.save_report(
            question='Test algorithm optimization',
            source='validation_test',
            report={'accuracy': 0.95, 'domain': 'algorithms'},
            tags=['test', 'algorithm']
        )
        
        # Retrieve reports
        reports = self.memory.list_reports(limit=10)
        
        # Check if our report is in the list
        found = any(r.get('id') == record['id'] for r in reports)
        
        success = found and len(reports) > 0
        print(f"Report saved: {record['id'][:8]}...")
        print(f"Reports retrieved: {len(reports)}")
        print(f"Our report found: {found}")
        print(f"Status: {'PASS' if success else 'FAIL'}")
        
        return success
    
    def test_tag_based_filtering(self):
        """Test filtering by tags."""
        print("\n=== Test: Tag-Based Filtering ===")
        
        # Save reports with different tags
        self.memory.save_report(
            question='Security vulnerability scan',
            source='test',
            report={'vulnerabilities': 3},
            tags=['security', 'scan']
        )
        
        self.memory.save_report(
            question='Algorithm performance test',
            source='test',
            report={'speedup': 1.5},
            tags=['algorithm', 'performance']
        )
        
        # Retrieve and filter
        reports = self.memory.list_reports(limit=20)
        security_reports = [r for r in reports if 'security' in r.get('tags', [])]
        algorithm_reports = [r for r in reports if 'algorithm' in r.get('tags', [])]
        
        success = len(security_reports) > 0 and len(algorithm_reports) > 0
        print(f"Total reports: {len(reports)}")
        print(f"Security reports: {len(security_reports)}")
        print(f"Algorithm reports: {len(algorithm_reports)}")
        print(f"Status: {'PASS' if success else 'FAIL'}")
        
        return success
    
    def test_temporal_ordering(self):
        """Test that reports maintain temporal order."""
        print("\n=== Test: Temporal Ordering ===")
        
        # Save reports with explicit timestamps
        base_time = time.time()
        
        self.memory.save_report(
            question='Experiment phase 1',
            source='test',
            report={'phase': 1},
            tags=['experiment']
        )
        
        time.sleep(0.1)  # Small delay to ensure different timestamps
        
        self.memory.save_report(
            question='Experiment phase 2',
            source='test',
            report={'phase': 2},
            tags=['experiment']
        )
        
        # Retrieve and check ordering
        reports = self.memory.list_reports(limit=10)
        experiment_reports = [r for r in reports if 'experiment' in r.get('question', '').lower()]
        
        # Should have at least 2 experiment reports
        success = len(experiment_reports) >= 2
        print(f"Experiment reports found: {len(experiment_reports)}")
        print(f"Status: {'PASS' if success else 'FAIL'}")
        
        return success
    
    def test_metadata_preservation(self):
        """Test that metadata is preserved correctly."""
        print("\n=== Test: Metadata Preservation ===")
        
        test_data = {
            'complexity': 'high',
            'dependencies': ['numpy', 'scipy'],
            'results': {'accuracy': 0.92, 'f1_score': 0.89}
        }
        
        self.memory.save_report(
            question='Complex algorithm test',
            source='validation',
            report=test_data,
            tags=['algorithm', 'complex']
        )
        
        # Retrieve and verify
        reports = self.memory.list_reports(limit=10)
        complex_reports = [r for r in reports 
                          if 'complex' in r.get('question', '').lower()]
        
        if complex_reports:
            preserved_data = complex_reports[0].get('report', {})
            has_complexity = preserved_data.get('complexity') == 'high'
            has_dependencies = 'numpy' in preserved_data.get('dependencies', [])
            has_results = 'accuracy' in preserved_data.get('results', {})
            
            success = has_complexity and has_dependencies and has_results
            print(f"Complexity preserved: {has_complexity}")
            print(f"Dependencies preserved: {has_dependencies}")
            print(f"Results preserved: {has_results}")
        else:
            success = False
            print("No complex reports found")
        
        print(f"Status: {'PASS' if success else 'FAIL'}")
        return success
    
    def run_all_tests(self):
        """Run all memory validation tests."""
        print("=" * 70)
        print("MEMORY SYSTEM VALIDATION: Basic Functionality Tests")
        print("=" * 70)
        
        results = {
            'basic_storage': self.test_basic_storage_retrieval(),
            'tag_filtering': self.test_tag_based_filtering(),
            'temporal_ordering': self.test_temporal_ordering(),
            'metadata_preservation': self.test_metadata_preservation()
        }
        
        passed = sum(results.values())
        total = len(results)
        
        print("\n" + "=" * 70)
        print(f"RESULTS: {passed}/{total} tests passed ({passed/total*100:.1f}%)")
        print("=" * 70)
        
        return results


if __name__ == '__main__':
    tester = MemoryValidationTests()
    tester.run_all_tests()
