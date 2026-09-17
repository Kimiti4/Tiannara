"""
PARALLEL COGNITIVE WORKERS - PRIORITY 2 OPTIMIZATION

Implements parallel processing for:
1. Contradiction detection (VERY HIGH priority)
2. Belief validation (VERY HIGH priority)  
3. Memory consolidation (HIGH priority)
4. Sleep replay segmentation (VERY HIGH priority)

Uses ThreadPoolExecutor for CPU-bound tasks with proper chunking.
"""

import time
from typing import Dict, List, Any, Callable, Tuple
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass


@dataclass
class WorkerPoolConfig:
    """Configuration for parallel cognitive workers."""
    max_workers: int = 8
    chunk_size: int = 50
    timeout_seconds: int = 300
    enable_contradiction_workers: bool = True
    enable_memory_workers: bool = True
    enable_fusion_workers: bool = True
    enable_audit_workers: bool = True


class ParallelCognitiveWorkers:
    """
    Manages parallel worker pools for cognitive operations.
    
    Architecture:
    Coordinator
        ↓
    Worker Pools
        ├── contradiction workers (detect contradictions in parallel)
        ├── memory workers (validate/consolidate memories)
        ├── fusion workers (merge belief fragments)
        └── audit workers (run integrity checks)
    
    Important: Final consensus remains hierarchical (not parallelized)
    to avoid synchronization chaos.
    """
    
    def __init__(self, config: WorkerPoolConfig = None):
        self.config = config or WorkerPoolConfig()
        self.execution_stats: Dict[str, Dict] = {}
        
    def parallel_contradiction_detection(
        self,
        memory_registry: Dict[str, Any],
        detect_function: Callable,
        similarity_threshold: float = 0.7
    ) -> List[Any]:
        """
        PERFORMANCE OPTIMIZATION: Parallel contradiction detection.
        
        Partitions memory registry into chunks and detects contradictions
        in each chunk concurrently.
        
        Args:
            memory_registry: Dictionary of memory_id -> memory_data
            detect_function: Function to detect contradictions in a chunk
            similarity_threshold: Threshold for contradiction detection
            
        Returns:
            List of all detected contradictions (aggregated from all workers)
        """
        if not self.config.enable_contradiction_workers:
            # Fallback to sequential
            return detect_function(memory_registry, similarity_threshold)
        
        print(f"🚀 Starting parallel contradiction detection with {self.config.max_workers} workers...")
        start_time = time.time()
        
        # Partition memories into chunks
        memory_ids = list(memory_registry.keys())
        chunks = self._partition_list(memory_ids, self.config.chunk_size)
        
        print(f"   Partitioned {len(memory_ids)} memories into {len(chunks)} chunks")
        
        all_contradictions = []
        
        # Process chunks in parallel
        with ThreadPoolExecutor(max_workers=self.config.max_workers) as executor:
            # Submit tasks
            future_to_chunk = {
                executor.submit(
                    self._process_chunk,
                    detect_function,
                    {mid: memory_registry[mid] for mid in chunk},
                    similarity_threshold,
                    idx
                ): idx
                for idx, chunk in enumerate(chunks)
            }
            
            # Collect results as they complete
            for future in as_completed(future_to_chunk, timeout=self.config.timeout_seconds):
                chunk_idx = future_to_chunk[future]
                try:
                    chunk_contradictions = future.result()
                    all_contradictions.extend(chunk_contradictions)
                    print(f"   ✅ Chunk {chunk_idx} completed: {len(chunk_contradictions)} contradictions")
                except Exception as e:
                    print(f"   ❌ Chunk {chunk_idx} failed: {e}")
        
        elapsed = time.time() - start_time
        print(f"✅ Parallel detection complete: {len(all_contradictions)} total contradictions in {elapsed:.2f}s")
        
        # Track stats
        self.execution_stats['contradiction_detection'] = {
            'total_memories': len(memory_ids),
            'chunks_processed': len(chunks),
            'total_contradictions': len(all_contradictions),
            'elapsed_seconds': elapsed,
            'throughput': len(memory_ids) / max(0.001, elapsed)
        }
        
        return all_contradictions
    
    def parallel_belief_validation(
        self,
        beliefs: List[Dict],
        validate_function: Callable
    ) -> List[Tuple[str, bool]]:
        """
        PERFORMANCE OPTIMIZATION: Parallel belief validation.
        
        Validates multiple beliefs concurrently.
        
        Args:
            beliefs: List of belief dictionaries
            validate_function: Function to validate a single belief
            
        Returns:
            List of (belief_id, is_valid) tuples
        """
        if not self.config.enable_contradiction_workers:
            # Fallback to sequential
            return [(b.get('id', str(i)), validate_function(b)) for i, b in enumerate(beliefs)]
        
        print(f"🚀 Starting parallel belief validation for {len(beliefs)} beliefs...")
        start_time = time.time()
        
        results = []
        
        with ThreadPoolExecutor(max_workers=self.config.max_workers) as executor:
            # Submit validation tasks
            future_to_belief = {
                executor.submit(validate_function, belief): belief.get('id', str(i))
                for i, belief in enumerate(beliefs)
            }
            
            # Collect results
            for future in as_completed(future_to_belief, timeout=self.config.timeout_seconds):
                belief_id = future_to_belief[future]
                try:
                    is_valid = future.result()
                    results.append((belief_id, is_valid))
                except Exception as e:
                    print(f"   ❌ Validation failed for {belief_id}: {e}")
                    results.append((belief_id, False))
        
        elapsed = time.time() - start_time
        valid_count = sum(1 for _, is_valid in results if is_valid)
        print(f"✅ Validation complete: {valid_count}/{len(results)} valid in {elapsed:.2f}s")
        
        return results
    
    def parallel_memory_consolidation(
        self,
        memory_ids: List[str],
        consolidate_function: Callable,
        memory_registry: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        PERFORMANCE OPTIMIZATION: Parallel memory consolidation.
        
        Consolidates multiple memories concurrently during sleep cycles.
        
        Args:
            memory_ids: List of memory IDs to consolidate
            consolidate_function: Function to consolidate a single memory
            memory_registry: Full memory registry
            
        Returns:
            Dictionary of consolidation results
        """
        if not self.config.enable_memory_workers:
            # Fallback to sequential
            results = {}
            for mem_id in memory_ids:
                results[mem_id] = consolidate_function(mem_id, memory_registry)
            return results
        
        print(f"🚀 Starting parallel memory consolidation for {len(memory_ids)} memories...")
        start_time = time.time()
        
        results = {}
        
        with ThreadPoolExecutor(max_workers=self.config.max_workers) as executor:
            # Submit consolidation tasks
            future_to_mem = {
                executor.submit(consolidate_function, mem_id, memory_registry): mem_id
                for mem_id in memory_ids
            }
            
            # Collect results
            for future in as_completed(future_to_mem, timeout=self.config.timeout_seconds):
                mem_id = future_to_mem[future]
                try:
                    result = future.result()
                    results[mem_id] = result
                except Exception as e:
                    print(f"   ❌ Consolidation failed for {mem_id}: {e}")
                    results[mem_id] = {'error': str(e)}
        
        elapsed = time.time() - start_time
        success_count = sum(1 for r in results.values() if 'error' not in r)
        print(f"✅ Consolidation complete: {success_count}/{len(results)} successful in {elapsed:.2f}s")
        
        return results
    
    def parallel_sleep_replay_segmentation(
        self,
        episodic_memories: List[Dict],
        process_segment_function: Callable,
        segment_size: int = 100
    ) -> List[Any]:
        """
        PERFORMANCE OPTIMIZATION: Parallel sleep replay segmentation.
        
        Divides episodic memories into segments and processes them concurrently.
        
        Args:
            episodic_memories: List of episodic memory records
            process_segment_function: Function to process a segment
            segment_size: Number of memories per segment
            
        Returns:
            List of processed segment results
        """
        if not self.config.enable_contradiction_workers:
            # Fallback to sequential processing
            segments = [episodic_memories[i:i+segment_size] 
                       for i in range(0, len(episodic_memories), segment_size)]
            return [process_segment_function(seg) for seg in segments]
        
        print(f"🚀 Starting parallel sleep replay for {len(episodic_memories)} memories...")
        start_time = time.time()
        
        # Segment memories
        segments = [episodic_memories[i:i+segment_size] 
                   for i in range(0, len(episodic_memories), segment_size)]
        
        print(f"   Created {len(segments)} segments of size {segment_size}")
        
        results = []
        
        with ThreadPoolExecutor(max_workers=self.config.max_workers) as executor:
            # Submit segment processing tasks
            future_to_segment = {
                executor.submit(process_segment_function, segment): idx
                for idx, segment in enumerate(segments)
            }
            
            # Collect results
            for future in as_completed(future_to_segment, timeout=self.config.timeout_seconds):
                segment_idx = future_to_segment[future]
                try:
                    result = future.result()
                    results.append((segment_idx, result))
                except Exception as e:
                    print(f"   ❌ Segment {segment_idx} failed: {e}")
        
        # Sort by segment index to maintain order
        results.sort(key=lambda x: x[0])
        
        elapsed = time.time() - start_time
        print(f"✅ Sleep replay complete: {len(results)} segments processed in {elapsed:.2f}s")
        
        return [result for _, result in results]
    
    def _partition_list(self, items: List, chunk_size: int) -> List[List]:
        """Partition a list into chunks of specified size."""
        return [items[i:i + chunk_size] for i in range(0, len(items), chunk_size)]
    
    def _process_chunk(
        self,
        detect_function: Callable,
        chunk_registry: Dict[str, Any],
        similarity_threshold: float,
        chunk_idx: int
    ) -> List[Any]:
        """Process a single chunk of memories for contradiction detection."""
        try:
            return detect_function(chunk_registry, similarity_threshold)
        except Exception as e:
            print(f"Error in chunk {chunk_idx}: {e}")
            return []
    
    def get_execution_stats(self) -> Dict[str, Dict]:
        """Get execution statistics for all parallel operations."""
        return self.execution_stats.copy()
    
    def shutdown(self):
        """Clean shutdown of worker pools."""
        print("🛑 Shutting down parallel cognitive workers...")
        # ThreadPoolExecutor handles cleanup automatically via context manager


# ============================================================================
# USAGE EXAMPLES
# ============================================================================

def example_parallel_contradiction_detection():
    """Example: Using parallel contradiction detection."""
    from tiannara_core.metacognition.sleep_cycle.memory_reconsolidation import ContradictionResolver
    
    # Initialize
    workers = ParallelCognitiveWorkers(WorkerPoolConfig(max_workers=8))
    resolver = ContradictionResolver()
    
    # Create mock memory registry
    memory_registry = {
        f"mem_{i}": {"id": f"mem_{i}", "confidence": 0.9, "content": f"Memory {i}"}
        for i in range(1000)
    }
    
    # Run parallel detection
    contradictions = workers.parallel_contradiction_detection(
        memory_registry=memory_registry,
        detect_function=resolver.detect_contradictions_sparse,
        similarity_threshold=0.7
    )
    
    print(f"Detected {len(contradictions)} contradictions")
    print(f"Stats: {workers.get_execution_stats()}")


if __name__ == "__main__":
    example_parallel_contradiction_detection()
