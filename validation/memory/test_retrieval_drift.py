"""
Memory System Validation - Retrieval Quality Tests

Tests memory retrieval accuracy, relevance, and bias control.
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from tiannara_core.memory.discovery_memory import DiscoveryMemory
from datetime import datetime, timedelta


class RetrievalQualityTests:
    """Test memory retrieval accuracy and relevance."""
    
    def __init__(self):
        self.memory = DiscoveryMemory()
        
    def test_precision_recall(self):
        """Measure retrieval precision and recall."""
        print("\n=== Test: Precision & Recall ===")
        
        # Store 100 memories about topic X (algorithms)
        for i in range(100):
            algo_data = {
                'category': 'algorithm',
                'subcategory': ['sorting', 'search', 'graph'][i % 3],
                'importance': 0.5 + (i % 10) * 0.05,
                'timestamp': datetime.now() - timedelta(days=i)
            }
            self.memory.store_discovery(
                f'Algorithm optimization technique {i}: {algo_data["subcategory"]}',
                algo_data
            )
        
        # Store 20 memories about unrelated topic Y (cooking)
        for i in range(20):
            cooking_data = {
                'category': 'cooking',
                'importance': 0.5,
                'timestamp': datetime.now() - timedelta(days=i)
            }
            self.memory.store_discovery(
                f'Recipe {i}: pasta preparation',
                cooking_data
            )
        
        # Query: Specific aspect of algorithms
        results = self.memory.search_memories('algorithm sorting optimization', limit=10)
        
        # Calculate precision: how many results are relevant?
        relevant_count = sum(1 for r in results 
                           if 'algorithm' in str(r.get('content', '')).lower())
        precision = relevant_count / max(len(results), 1)
        
        # Calculate recall: how many of top algorithm memories were retrieved?
        # (Simplified: check if we got at least some algorithm results)
        recall = 1.0 if relevant_count > 0 else 0.0
        
        success = precision >= 0.8 and recall >= 0.9
        
        print(f"Results returned: {len(results)}")
        print(f"Relevant results: {relevant_count}")
        print(f"Precision: {precision:.1%}")
        print(f"Recall: {recall:.1%}")
        print(f"Status: {'PASS' if success else 'FAIL'}")
        
        return success
    
    def test_recency_bias_control(self):
        """Balance recency vs importance in retrieval."""
        print("\n=== Test: Recency Bias Control ===")
        
        # Old important memory (30 days ago, high importance)
        old_important = {
            'category': 'discovery',
            'importance': 0.95,
            'timestamp': datetime.now() - timedelta(days=30),
            'type': 'breakthrough'
        }
        self.memory.store_discovery(
            'Critical security breakthrough: vulnerability class X identified',
            old_important
        )
        
        # Recent trivial memory (1 day ago, low importance)
        recent_trivial = {
            'category': 'note',
            'importance': 0.1,
            'timestamp': datetime.now() - timedelta(days=1),
            'type': 'observation'
        }
        self.memory.store_discovery(
            'Daily observation: system running normally',
            recent_trivial
        )
        
        # Query should retrieve based on relevance, not just recency
        results = self.memory.search_memories('security breakthrough vulnerability', limit=5)
        
        # Expected: Important old memory retrieved when relevant
        has_old_important = any('breakthrough' in str(r.get('content', '')).lower() 
                               for r in results)
        
        success = has_old_important
        print(f"Old important memory retrieved: {success}")
        print(f"Total results: {len(results)}")
        print(f"Status: {'PASS' if success else 'FAIL'}")
        
        return success
    
    def test_contextual_relevance(self):
        """Retrieval considers conversation context."""
        print("\n=== Test: Contextual Relevance ===")
        
        # Security context memories
        sec_data = {
            'category': 'security',
            'context': 'vulnerability_analysis',
            'timestamp': datetime.now()
        }
        self.memory.store_discovery(
            'Buffer overflow vulnerability in network module allows remote code execution',
            sec_data
        )
        
        # Unrelated context memories (water management)
        water_data = {
            'category': 'infrastructure',
            'context': 'water_management',
            'timestamp': datetime.now()
        }
        self.memory.store_discovery(
            'Water overflow detected in basement drainage system',
            water_data
        )
        
        # Context: Discussing security vulnerabilities
        results = self.memory.search_memories('buffer overflow security', limit=5)
        
        # Expected: Retrieves security-related overflow info
        has_security = any('remote code' in str(r.get('content', '')).lower() 
                         or 'vulnerability' in str(r.get('content', '')).lower()
                         for r in results)
        has_water = any('basement' in str(r.get('content', '')).lower() 
                       or 'drainage' in str(r.get('content', '')).lower()
                       for r in results)
        
        # Success if security context is prioritized
        success = has_security and not has_water
        
        print(f"Security context found: {has_security}")
        print(f"Water context found (should be False): {has_water}")
        print(f"Contextual relevance correct: {success}")
        print(f"Status: {'PASS' if success else 'FAIL'}")
        
        return success
    
    def test_diversity_in_results(self):
        """Ensure diverse results, not just duplicates."""
        print("\n=== Test: Result Diversity ===")
        
        # Store diverse memories
        topics = ['sorting', 'search', 'graph', 'dynamic_programming', 'greedy']
        for topic in topics:
            data = {
                'category': 'algorithm',
                'topic': topic,
                'timestamp': datetime.now()
            }
            self.memory.store_discovery(
                f'{topic} algorithm implementation details',
                data
            )
        
        # Query broadly
        results = self.memory.search_memories('algorithm implementation', limit=10)
        
        # Check diversity: should have multiple different topics
        unique_topics = set()
        for r in results:
            content = str(r.get('content', '')).lower()
            for topic in topics:
                if topic in content:
                    unique_topics.add(topic)
        
        diversity_ratio = len(unique_topics) / len(topics)
        success = diversity_ratio >= 0.6  # At least 60% of topics represented
        
        print(f"Unique topics found: {len(unique_topics)}/{len(topics)}")
        print(f"Diversity ratio: {diversity_ratio:.1%}")
        print(f"Status: {'PASS' if success else 'FAIL'}")
        
        return success
    
    def run_all_tests(self):
        """Run all retrieval quality tests."""
        print("=" * 70)
        print("MEMORY SYSTEM VALIDATION: Retrieval Quality Tests")
        print("=" * 70)
        
        results = {
            'precision_recall': self.test_precision_recall(),
            'recency_bias': self.test_recency_bias_control(),
            'contextual_relevance': self.test_contextual_relevance(),
            'result_diversity': self.test_diversity_in_results()
        }
        
        passed = sum(results.values())
        total = len(results)
        
        print("\n" + "=" * 70)
        print(f"RESULTS: {passed}/{total} tests passed ({passed/total*100:.1f}%)")
        print("=" * 70)
        
        return results


if __name__ == '__main__':
    tester = RetrievalQualityTests()
    tester.run_all_tests()
