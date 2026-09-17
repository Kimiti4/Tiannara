"""
Daemon Orchestrator with AutoDream Nightly Consolidation Cycle.

Implements upgrades.md requirement for persistent identity and autonomous operation:
- Background process for continuous system operation
- Nightly AutoDream cycle (reconsolidation, self-criticism, creative synthesis)
- Health monitoring and auto-restart
- Cron-like scheduling for periodic tasks

Usage:
    python daemon_orchestrator.py [--schedule-hour 2] [--auto-dream]
"""

import os
import sys
import time
import json
import signal
import logging
import threading
from typing import Dict, Any, Optional, List
from pathlib import Path
from datetime import datetime, timedelta

# Add project root to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from tiannara_core.evaluation.ecm_forgetting_mechanism import SkillMemoryWithForgetting
from tiannara_core.evaluation.episode_logger import EpisodeLogger


class DaemonOrchestrator:
    """
    Background orchestrator for continuous Tiannara system operation.
    
    Manages:
    - Scheduled task execution (cron-like)
    - AutoDream nightly consolidation cycle
    - Health monitoring and auto-recovery
    - Graceful shutdown handling
    """
    
    def __init__(
        self,
        log_dir: str = None,
        schedule_hour: int = 2,  # 2 AM default
        enable_auto_dream: bool = True,
        health_check_interval: int = 300,  # 5 minutes
        checkpoint_interval: int = 100
    ):
        """
        Initialize daemon orchestrator.
        
        Args:
            log_dir: Directory for logs and checkpoints
            schedule_hour: Hour (0-23) for nightly AutoDream cycle
            enable_auto_dream: Enable nightly consolidation (default: True)
            health_check_interval: Seconds between health checks (default: 300)
            checkpoint_interval: Episodes between automatic checkpoints (default: 100)
        """
        self.log_dir = Path(log_dir) if log_dir else Path("tiannara_core/logs")
        self.log_dir.mkdir(parents=True, exist_ok=True)
        
        self.schedule_hour = schedule_hour
        self.enable_auto_dream = enable_auto_dream
        self.health_check_interval = health_check_interval
        self.checkpoint_interval = checkpoint_interval
        
        # Logging
        self.logger = logging.getLogger("DaemonOrchestrator")
        self.logger.setLevel(logging.INFO)
        
        handler = logging.FileHandler(self.log_dir / "daemon.log")
        handler.setFormatter(logging.Formatter(
            '%(asctime)s | %(levelname)s | %(message)s'
        ))
        self.logger.addHandler(handler)
        
        # Also log to console
        console_handler = logging.StreamHandler()
        console_handler.setFormatter(logging.Formatter(
            '%(asctime)s | %(levelname)s | %(message)s'
        ))
        self.logger.addHandler(console_handler)
        
        # State
        self.running = False
        self.shutdown_event = threading.Event()
        self.last_autodream = None
        self.episode_count = 0
        
        # Components
        self.skill_memory = None
        self.episode_logger = None
        
        # Scheduled tasks
        self.scheduled_tasks: List[Dict[str, Any]] = []
        
        # Register signal handlers for graceful shutdown
        signal.signal(signal.SIGINT, self._signal_handler)
        signal.signal(signal.SIGTERM, self._signal_handler)
        
        self.logger.info("Daemon orchestrator initialized")
    
    def _signal_handler(self, signum, frame):
        """Handle shutdown signals gracefully."""
        self.logger.info(f"Received signal {signum}, initiating graceful shutdown...")
        self.shutdown()
    
    def initialize_components(self):
        """Initialize system components (skill memory, logger, etc.)."""
        self.logger.info("Initializing system components...")
        
        # Initialize skill memory
        self.skill_memory = SkillMemoryWithForgetting(
            max_skills=1000,
            decay_rate=0.01,
            salience_threshold=0.05,
            consolidation_threshold=0.85,
            checkpoint_interval=self.checkpoint_interval
        )
        
        # Initialize episode logger with async mode
        self.episode_logger = EpisodeLogger(
            log_dir=str(self.log_dir),
            use_sqlite=True,
            batch_size=100,
            async_mode=True  # Non-blocking writes
        )
        
        # Load latest checkpoint if available
        self._load_checkpoint()
        
        self.logger.info("Components initialized successfully")
    
    def _load_checkpoint(self):
        """Load latest checkpoint to restore state."""
        try:
            checkpoint_file = self.log_dir / "daemon_checkpoint.json"
            if checkpoint_file.exists():
                with open(checkpoint_file, 'r') as f:
                    checkpoint = json.load(f)
                
                self.episode_count = checkpoint.get("episode_count", 0)
                self.last_autodream = checkpoint.get("last_autodream")
                
                self.logger.info(f"Loaded checkpoint: episode {self.episode_count}")
            else:
                self.logger.info("No checkpoint found, starting fresh")
        except Exception as e:
            self.logger.error(f"Failed to load checkpoint: {e}")
    
    def _save_checkpoint(self):
        """Save current state to checkpoint file."""
        try:
            checkpoint = {
                "episode_count": self.episode_count,
                "last_autodream": self.last_autodream,
                "timestamp": datetime.now().isoformat(),
                "skill_count": len(self.skill_memory.active_skills) if self.skill_memory else 0
            }
            
            checkpoint_file = self.log_dir / "daemon_checkpoint.json"
            with open(checkpoint_file, 'w') as f:
                json.dump(checkpoint, f, indent=2)
            
            self.logger.debug(f"Checkpoint saved: episode {self.episode_count}")
        except Exception as e:
            self.logger.error(f"Failed to save checkpoint: {e}")
    
    def schedule_task(self, name: str, func, interval_seconds: int, **kwargs):
        """
        Schedule a recurring task.
        
        Args:
            name: Task name for logging
            func: Function to execute
            interval_seconds: Execution interval in seconds
            **kwargs: Arguments to pass to func
        """
        self.scheduled_tasks.append({
            "name": name,
            "func": func,
            "interval": interval_seconds,
            "kwargs": kwargs,
            "last_run": 0
        })
        self.logger.info(f"Scheduled task '{name}' every {interval_seconds}s")
    
    def run_scheduled_tasks(self):
        """Execute tasks that are due based on their intervals."""
        current_time = time.time()
        
        for task in self.scheduled_tasks:
            if current_time - task["last_run"] >= task["interval"]:
                try:
                    self.logger.debug(f"Executing scheduled task: {task['name']}")
                    task["func"](**task["kwargs"])
                    task["last_run"] = current_time
                except Exception as e:
                    self.logger.error(f"Task '{task['name']}' failed: {e}")
    
    def check_autodream_schedule(self):
        """Check if it's time for nightly AutoDream cycle."""
        if not self.enable_auto_dream:
            return
        
        now = datetime.now()
        
        # Check if we're in the scheduled hour and haven't run today
        if now.hour == self.schedule_hour:
            today = now.date()
            
            if self.last_autodream is None or self.last_autodream != str(today):
                self.logger.info(f"Starting nightly AutoDream cycle (hour {self.schedule_hour})...")
                self.run_autodream_cycle()
                self.last_autodream = str(today)
                self._save_checkpoint()
    
    def run_autodream_cycle(self):
        """
        Execute the AutoDream nightly consolidation cycle.
        
        Phases:
        1. Reconsolidation - Find patterns the agent didn't know it was learning
        2. Self-Criticism - Audit against stated principles
        3. Creative Synthesis - Lateral, non-literal connection-making
        4. Entropy-Based Forgetting - Remove low-salience skills
        """
        start_time = time.time()
        self.logger.info("=" * 70)
        self.logger.info("AUTODREAM CYCLE STARTED")
        self.logger.info("=" * 70)
        
        try:
            # Phase 1: Reconsolidation
            self.logger.info("\nPhase 1: Reconsolidation")
            self._autodream_reconsolidation()
            
            # Phase 2: Self-Criticism
            self.logger.info("\nPhase 2: Self-Criticism")
            self._autodream_self_criticism()
            
            # Phase 3: Creative Synthesis
            self.logger.info("\nPhase 3: Creative Synthesis")
            self._autodream_creative_synthesis()
            
            # Phase 4: Entropy-Based Forgetting
            self.logger.info("\nPhase 4: Entropy-Based Forgetting")
            self._autodream_entropy_forgetting()
            
            elapsed = time.time() - start_time
            self.logger.info(f"\nAutoDream cycle completed in {elapsed:.1f}s")
            self.logger.info("=" * 70)
            
        except Exception as e:
            self.logger.error(f"AutoDream cycle failed: {e}", exc_info=True)
    
    def _autodream_reconsolidation(self):
        """Find patterns across skills that weren't explicitly learned."""
        if not self.skill_memory:
            self.logger.warning("Skill memory not initialized, skipping reconsolidation")
            return
        
        skills = list(self.skill_memory.active_skills.values())
        self.logger.info(f"Analyzing {len(skills)} skills for hidden patterns...")
        
        # Group skills by domain
        domain_groups: Dict[str, list] = {}
        for skill in skills:
            domain_groups.setdefault(skill.domain, []).append(skill)
        
        # Find cross-domain patterns
        patterns_found = 0
        for domain, domain_skills in domain_groups.items():
            if len(domain_skills) < 5:
                continue
            
            # Look for common quality ranges, usage patterns
            avg_quality = sum(s.quality for s in domain_skills) / len(domain_skills)
            high_performers = [s for s in domain_skills if s.quality > avg_quality + 0.1]
            
            if high_performers:
                self.logger.info(f"  {domain}: Found {len(high_performers)} high-performing skills")
                patterns_found += 1
        
        self.logger.info(f"Reconsolidation complete: {patterns_found} patterns identified")
    
    def _autodream_self_criticism(self):
        """Audit system behavior against stated principles."""
        self.logger.info("Performing self-criticism audit...")
        
        if not self.skill_memory:
            return
        
        # Check for principle violations
        violations = []
        
        # Principle 1: Skills should have minimum quality
        low_quality_skills = [
            s for s in self.skill_memory.active_skills.values()
            if s.quality < 0.5
        ]
        if low_quality_skills:
            violations.append(f"Found {len(low_quality_skills)} skills below quality threshold")
        
        # Principle 2: Skills should be used regularly
        unused_skills = [
            s for s in self.skill_memory.active_skills.values()
            if s.usage_count == 0
        ]
        if unused_skills:
            violations.append(f"Found {len(unused_skills)} completely unused skills")
        
        if violations:
            self.logger.warning("Principle violations detected:")
            for v in violations:
                self.logger.warning(f"  - {v}")
        else:
            self.logger.info("No principle violations detected ✓")
    
    def _autodream_creative_synthesis(self):
        """Make lateral connections between unrelated skills."""
        self.logger.info("Performing creative synthesis...")
        
        if not self.skill_memory:
            return
        
        skills = list(self.skill_memory.active_skills.values())
        
        # Find skills from different domains with similar patterns
        synthesis_opportunities = 0
        
        for i, skill1 in enumerate(skills[:50]):  # Limit to first 50 for performance
            for skill2 in skills[i+1:50]:
                if skill1.domain != skill2.domain:
                    # Check if patterns are semantically similar
                    # (In production, use vector embeddings for this)
                    if self._patterns_similar(skill1.pattern, skill2.pattern):
                        synthesis_opportunities += 1
                        self.logger.debug(
                            f"  Potential synthesis: {skill1.domain} ↔ {skill2.domain}"
                        )
        
        self.logger.info(f"Creative synthesis complete: {synthesis_opportunities} opportunities found")
    
    def _patterns_similar(self, pattern1: str, pattern2: str) -> bool:
        """Simple heuristic for pattern similarity."""
        # In production, use cosine similarity on vector embeddings
        # For now, just check if they share key terms
        words1 = set(pattern1.lower().split())
        words2 = set(pattern2.lower().split())
        
        if not words1 or not words2:
            return False
        
        overlap = len(words1.intersection(words2))
        total = len(words1.union(words2))
        
        return overlap / total > 0.3 if total > 0 else False
    
    def _autodream_entropy_forgetting(self):
        """Remove low-salience skills to reduce noise."""
        if not self.skill_memory:
            return
        
        initial_count = len(self.skill_memory.active_skills)
        
        # Apply decay mechanism
        self.skill_memory.apply_decay(self.episode_count)
        
        # Consolidate similar skills
        self.skill_memory.consolidate_similar_skills()
        
        final_count = len(self.skill_memory.active_skills)
        removed = initial_count - final_count
        
        self.logger.info(f"Forgetting complete: removed {removed} low-salience skills")
        self.logger.info(f"Active skills: {initial_count} → {final_count}")
    
    def health_check(self):
        """Perform system health check."""
        health_status = {
            "timestamp": datetime.now().isoformat(),
            "running": self.running,
            "episode_count": self.episode_count,
            "skill_count": len(self.skill_memory.active_skills) if self.skill_memory else 0,
            "last_autodream": self.last_autodream,
            "scheduled_tasks": len(self.scheduled_tasks)
        }
        
        # Log health status
        self.logger.info(f"Health check: {json.dumps(health_status, indent=2)}")
        
        # Save health report
        health_file = self.log_dir / "health_report.json"
        with open(health_file, 'w') as f:
            json.dump(health_status, f, indent=2)
        
        return health_status
    
    def start(self):
        """Start the daemon orchestrator."""
        self.logger.info("Starting daemon orchestrator...")
        self.running = True
        
        # Initialize components
        self.initialize_components()
        
        # Schedule default tasks
        self.schedule_task(
            "health_check",
            self.health_check,
            interval_seconds=self.health_check_interval
        )
        
        self.schedule_task(
            "save_checkpoint",
            self._save_checkpoint,
            interval_seconds=3600  # Every hour
        )
        
        self.logger.info("Daemon orchestrator started")
        self.logger.info(f"AutoDream scheduled for {self.schedule_hour}:00 daily")
        
        # Main loop
        try:
            while not self.shutdown_event.is_set():
                # Run scheduled tasks
                self.run_scheduled_tasks()
                
                # Check AutoDream schedule
                self.check_autodream_schedule()
                
                # Sleep briefly to avoid busy-waiting
                self.shutdown_event.wait(timeout=60)  # Check every minute
        
        except KeyboardInterrupt:
            self.logger.info("Keyboard interrupt received")
        finally:
            self.shutdown()
    
    def shutdown(self):
        """Gracefully shutdown the daemon."""
        if not self.running:
            return
        
        self.logger.info("Shutting down daemon orchestrator...")
        self.running = False
        
        # Signal shutdown
        self.shutdown_event.set()
        
        # Save final checkpoint
        self._save_checkpoint()
        
        # Close episode logger (flushes async queue)
        if self.episode_logger:
            self.episode_logger.close()
        
        self.logger.info("Daemon orchestrator shut down gracefully")


def main():
    """Main entry point for daemon orchestrator."""
    import argparse
    
    parser = argparse.ArgumentParser(description='Tiannara Daemon Orchestrator')
    parser.add_argument(
        '--schedule-hour',
        type=int,
        default=2,
        help='Hour (0-23) for nightly AutoDream cycle (default: 2)'
    )
    parser.add_argument(
        '--no-auto-dream',
        action='store_true',
        help='Disable nightly AutoDream cycle'
    )
    parser.add_argument(
        '--log-dir',
        type=str,
        default=None,
        help='Directory for logs and checkpoints'
    )
    
    args = parser.parse_args()
    
    # Create and start daemon
    daemon = DaemonOrchestrator(
        log_dir=args.log_dir,
        schedule_hour=args.schedule_hour,
        enable_auto_dream=not args.no_auto_dream
    )
    
    daemon.start()


if __name__ == "__main__":
    main()
