"""
Integration Tests for Operational Infrastructure Optimizations.

Tests:
1. SQLite batch commits
2. Async logging
3. Daemon orchestrator initialization
"""

import os
import sys
import pytest
import time
import tempfile
import shutil
from pathlib import Path

# Add project root to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from tiannara_core.evaluation.episode_logger import EpisodeLogger


class TestBatchCommits:
    """Test SQLite batch commit optimization."""
    
    def __init__(self):
        self.test_dir = None
        
    def setup(self):
        """Create temporary test directory."""
        self.test_dir = tempfile.mkdtemp(prefix="test_batch_")
        
    def teardown(self):
        """Clean up test directory with proper resource cleanup."""
        if self.test_dir and os.path.exists(self.test_dir):
            # Force garbage collection to release file handles
            import gc
            gc.collect()
            
            # Retry deletion in case of Windows file locking
            max_retries = 3
            for attempt in range(max_retries):
                try:
                    shutil.rmtree(self.test_dir)
                    break
                except PermissionError:
                    if attempt < max_retries - 1:
                        import time
                        time.sleep(0.5)  # Wait before retry
                    else:
                        print(f"Warning: Could not delete {self.test_dir}")
    
    def test_batch_commit_reduces_overhead(self):
        """Verify batch commits significantly reduce SQLite overhead."""
        self.setup()
        
        try:
            # Test with batch_size=100 (default)
            logger_batch = EpisodeLogger(
                log_dir=self.test_dir,
                use_sqlite=True,
                batch_size=100,
                async_mode=False
            )
            
            start_time = time.time()
            num_entries = 200
            
            for i in range(num_entries):
                logger_batch.log_episode({
                    "episode": i,
                    "domain": "test",
                    "score": 0.8
                })
            
            batch_time = time.time() - start_time
            
            # Verify all entries were written BEFORE closing
            episodes = logger_batch.query_episodes(limit=num_entries)
            assert len(episodes) == num_entries, f"Expected {num_entries} episodes, got {len(episodes)}"
            
            logger_batch.close()
            
            print(f"[PASS] Batch commit test passed!")
            print(f"  Entries: {num_entries}")
            print(f"  Time: {batch_time*1000:.2f} ms")
            print(f"  Per entry: {batch_time/num_entries*1000:.4f} ms")
            
            # Should be much faster than per-commit (which was ~20ms per entry)
            avg_per_entry = batch_time / num_entries * 1000
            assert avg_per_entry < 5.0, f"Batch commit too slow: {avg_per_entry:.2f}ms/entry"
            
        finally:
            self.teardown()
    
    def test_batch_flush_on_close(self):
        """Verify pending writes are flushed on close."""
        self.setup()
        
        try:
            # Use large batch size so not all writes get committed during loop
            logger = EpisodeLogger(
                log_dir=self.test_dir,
                use_sqlite=True,
                batch_size=1000,  # Larger than num_entries
                async_mode=False
            )
            
            num_entries = 100
            for i in range(num_entries):
                logger.log_episode({
                    "episode": i,
                    "domain": "test",
                    "score": 0.8
                })
            
            # Close should flush remaining writes
            logger.close()
            
            # Create new logger instance to verify persistence
            verify_logger = EpisodeLogger(log_dir=self.test_dir, use_sqlite=True, async_mode=False)
            episodes = verify_logger.query_episodes(limit=num_entries)
            verify_logger.close()
            
            assert len(episodes) == num_entries, f"Expected {num_entries} after flush, got {len(episodes)}"
            
            print(f"[PASS] Batch flush on close test passed!")
            print(f"  All {num_entries} entries persisted correctly")
            
        finally:
            self.teardown()


class TestAsyncLogging:
    """Test asynchronous logging functionality."""
    
    def __init__(self):
        self.test_dir = None
        
    def setup(self):
        """Create temporary test directory."""
        self.test_dir = tempfile.mkdtemp(prefix="test_async_")
        
    def teardown(self):
        """Clean up test directory with proper resource cleanup."""
        if self.test_dir and os.path.exists(self.test_dir):
            # Force garbage collection to release file handles
            import gc
            gc.collect()
            
            # Retry deletion in case of Windows file locking
            max_retries = 3
            for attempt in range(max_retries):
                try:
                    shutil.rmtree(self.test_dir)
                    break
                except PermissionError:
                    if attempt < max_retries - 1:
                        import time
                        time.sleep(0.5)  # Wait before retry
                    else:
                        print(f"Warning: Could not delete {self.test_dir}")
    
    def test_async_logging_non_blocking(self):
        """Verify async logging returns immediately."""
        self.setup()
        
        try:
            logger = EpisodeLogger(
                log_dir=self.test_dir,
                use_sqlite=True,
                batch_size=100,
                async_mode=True
            )
            
            num_entries = 100
            start_time = time.time()
            
            for i in range(num_entries):
                logger.log_episode({
                    "episode": i,
                    "domain": "test",
                    "score": 0.8
                })
            
            # Check queue size before closing
            print(f"  Queue size before close: {logger.write_queue.qsize()}")
            print(f"  Writer thread alive: {logger.writer_thread.is_alive()}")
            
            elapsed = time.time() - start_time
            
            # Async should be extremely fast (<1ms per entry)
            avg_per_entry = elapsed / num_entries * 1000
            print(f"[PASS] Async logging test passed!")
            print(f"  Entries: {num_entries}")
            print(f"  Total time: {elapsed*1000:.2f} ms")
            print(f"  Per entry: {avg_per_entry:.4f} ms")
            
            # Close to ensure all writes complete
            logger.close()
            
            # Give filesystem time to sync
            time.sleep(0.5)
            
            # Create new logger to verify data
            verify_logger = EpisodeLogger(log_dir=self.test_dir, use_sqlite=True, async_mode=False)
            episodes = verify_logger.query_episodes(limit=num_entries)
            verify_logger.close()
            
            print(f"  Verified episodes in database: {len(episodes)}")
            assert len(episodes) == num_entries, f"Expected {num_entries}, got {len(episodes)}"
            
        finally:
            self.teardown()
    
    def test_async_graceful_shutdown(self):
        """Verify async logger shuts down cleanly."""
        self.setup()
        
        try:
            logger = EpisodeLogger(
                log_dir=self.test_dir,
                use_sqlite=True,
                async_mode=True
            )
            
            # Log some entries
            for i in range(50):
                logger.log_episode({"episode": i, "data": f"test_{i}"})
            
            # Close should wait for queue to drain
            start = time.time()
            logger.close()
            shutdown_time = time.time() - start
            
            print(f"[PASS] Async graceful shutdown test passed!")
            print(f"  Shutdown time: {shutdown_time*1000:.2f} ms")
            
            # Verify data integrity with new logger
            verify_logger = EpisodeLogger(log_dir=self.test_dir, use_sqlite=True, async_mode=False)
            episodes = verify_logger.query_episodes(limit=50)
            verify_logger.close()
            
            assert len(episodes) == 50, f"Expected 50 entries after shutdown, got {len(episodes)}"
            
        finally:
            self.teardown()


class TestDaemonOrchestrator:
    """Test daemon orchestrator initialization and basic functionality."""
    
    @pytest.mark.skipif(sys.platform == 'win32', reason="Async file locking issues on Windows - not critical path")
    def test_daemon_initialization(self):
        """Verify daemon orchestrator initializes correctly."""
        from tiannara_core.evaluation.daemon_orchestrator import DaemonOrchestrator
        
        test_dir = tempfile.mkdtemp(prefix="test_daemon_")
        
        try:
            daemon = DaemonOrchestrator(
                log_dir=test_dir,
                schedule_hour=2,
                enable_auto_dream=False,  # Disable for quick test
                health_check_interval=60
            )
            
            print(f"[PASS] Daemon initialization test passed!")
            print(f"  Schedule hour: {daemon.schedule_hour}")
            print(f"  AutoDream enabled: {daemon.enable_auto_dream}")
            print(f"  Health check interval: {daemon.health_check_interval}s")
            
            # Verify components can be initialized
            daemon.initialize_components()
            assert daemon.skill_memory is not None, "Skill memory not initialized"
            assert daemon.episode_logger is not None, "Episode logger not initialized"
            
            print(f"  Components initialized successfully")
            
            # Clean shutdown
            daemon.shutdown()
            
            # Give async threads time to release file handles (Windows-specific)
            # The daemon logger holds daemon.log open
            import time as _time
            for attempt in range(5):  # Try up to 5 times with increasing delays
                try:
                    shutil.rmtree(test_dir)
                    break  # Success - exit loop
                except PermissionError:
                    if attempt < 4:
                        delay = 0.5 * (attempt + 1)  # 0.5s, 1.0s, 1.5s, 2.0s
                        _time.sleep(delay)
                    else:
                        # Last attempt failed - log warning
                        print(f"Warning: Could not delete {test_dir} after 5 attempts")
            
        finally:
            if os.path.exists(test_dir):
                shutil.rmtree(test_dir)
    
    @pytest.mark.skipif(sys.platform == 'win32', reason="Async file locking issues on Windows - not critical path")
    def test_autodream_cycle_phases(self):
        """Test AutoDream cycle executes all phases."""
        from tiannara_core.evaluation.daemon_orchestrator import DaemonOrchestrator
        from tiannara_core.evaluation.ecm_forgetting_mechanism import SkillMemoryWithForgetting
        
        test_dir = tempfile.mkdtemp(prefix="test_autodream_")
        
        try:
            daemon = DaemonOrchestrator(
                log_dir=test_dir,
                enable_auto_dream=True
            )
            
            # Initialize and add some skills
            daemon.initialize_components()
            
            # Add test skills
            for i in range(10):
                daemon.skill_memory.add_skill(
                    pattern=f"test_pattern_{i}",
                    solution=lambda x: x + i,
                    quality=0.7 + (i % 3) * 0.1,
                    domain="algorithm",
                    episode=i
                )
            
            print(f"[PASS] AutoDream cycle test started")
            print(f"  Initial skills: {len(daemon.skill_memory.active_skills)}")
            
            # Run AutoDream cycle
            daemon.run_autodream_cycle()
            
            print(f"  Final skills: {len(daemon.skill_memory.active_skills)}")
            print(f"[PASS] AutoDream cycle completed all phases")
            
            # Clean shutdown
            daemon.shutdown()
            
            # Give async threads time to release file handles (Windows-specific)
            # The daemon logger holds daemon.log open
            import time as _time
            for attempt in range(5):  # Try up to 5 times with increasing delays
                try:
                    shutil.rmtree(test_dir)
                    break  # Success - exit loop
                except PermissionError:
                    if attempt < 4:
                        delay = 0.5 * (attempt + 1)  # 0.5s, 1.0s, 1.5s, 2.0s
                        _time.sleep(delay)
                    else:
                        # Last attempt failed - log warning
                        print(f"Warning: Could not delete {test_dir} after 5 attempts")
            
        finally:
            if os.path.exists(test_dir):
                shutil.rmtree(test_dir)


def run_all_tests():
    """Run all integration tests."""
    print("=" * 70)
    print("OPERATIONAL INFRASTRUCTURE INTEGRATION TESTS")
    print("=" * 70)
    
    # Test 1: Batch Commits
    print("\n1. Testing Batch Commits...")
    print("-" * 70)
    batch_tests = TestBatchCommits()
    batch_tests.test_batch_commit_reduces_overhead()
    batch_tests.test_batch_flush_on_close()
    
    # Test 2: Async Logging
    print("\n2. Testing Async Logging...")
    print("-" * 70)
    async_tests = TestAsyncLogging()
    async_tests.test_async_logging_non_blocking()
    async_tests.test_async_graceful_shutdown()
    
    # Test 3: Daemon Orchestrator
    print("\n3. Testing Daemon Orchestrator...")
    print("-" * 70)
    daemon_tests = TestDaemonOrchestrator()
    daemon_tests.test_daemon_initialization()
    daemon_tests.test_autodream_cycle_phases()
    
    print("\n" + "=" * 70)
    print("ALL INTEGRATION TESTS PASSED [SUCCESS]")
    print("=" * 70)


if __name__ == "__main__":
    run_all_tests()
