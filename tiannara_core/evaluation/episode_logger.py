"""
Episode Logger - Records all evaluation episodes in JSONL format.

Provides structured logging for later analysis and GNN training.
"""

import json
import time
import os
from typing import Dict, Any
from pathlib import Path


class EpisodeLogger:
    """Logs evaluation episodes to JSONL files."""

    def __init__(self, log_dir: str = None):
        """
        Initialize logger.
        
        Args:
            log_dir: Directory to store log files (default: tiannara_core/logs)
        """
        if log_dir is None:
            # Default to project logs directory
            log_dir = os.path.join(
                os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                "logs"
            )
        
        self.log_dir = Path(log_dir)
        self.log_dir.mkdir(parents=True, exist_ok=True)
        
        self.log_file = self.log_dir / "evaluation_episodes.jsonl"
        self.episode_count = 0

    def log_episode(self, episode_data: Dict[str, Any]):
        """
        Log a single episode to JSONL file.
        
        Args:
            episode_data: Dictionary containing all episode information
        """
        # Add metadata
        episode_data["timestamp"] = time.time()
        episode_data["episode_id"] = self.episode_count
        
        # Write to JSONL
        with open(self.log_file, "a", encoding="utf-8") as f:
            f.write(json.dumps(episode_data, default=str) + "\n")
        
        self.episode_count += 1

    def get_log_path(self) -> str:
        """Get path to current log file."""
        return str(self.log_file)

    def get_episode_count(self) -> int:
        """Get number of episodes logged."""
        return self.episode_count

    def read_all_episodes(self) -> list:
        """
        Read all logged episodes.
        
        Returns:
            List of episode dictionaries
        """
        if not self.log_file.exists():
            return []
        
        episodes = []
        with open(self.log_file, "r", encoding="utf-8") as f:
            for line in f:
                if line.strip():
                    episodes.append(json.loads(line))
        
        return episodes

    def clear_logs(self):
        """Clear all log files."""
        if self.log_file.exists():
            self.log_file.unlink()
        self.episode_count = 0
