"""
Episode Logger - Records all evaluation episodes in JSONL format with SQLite backend.

Provides structured logging for later analysis and GNN training.
Supports both JSONL (for streaming) and SQLite (for querying/provenance).
"""

import json
import time
import os
import sqlite3
import queue
import threading
from typing import Dict, Any, Optional, List
from pathlib import Path
from datetime import datetime


class EpisodeLogger:
    """Logs evaluation episodes to JSONL files and SQLite database.
    
    Supports both synchronous and asynchronous logging modes.
    Async mode uses a background writer thread for non-blocking writes.
    """

    def __init__(self, log_dir: str = None, use_sqlite: bool = True, 
                 batch_size: int = 100, async_mode: bool = False):
        """
        Initialize logger.
        
        Args:
            log_dir: Directory to store log files (default: tiannara_core/logs)
            use_sqlite: Enable SQLite backend for append-only logging (default: True)
            batch_size: Number of entries before committing to SQLite (default: 100)
            async_mode: Enable asynchronous logging with background thread (default: False)
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
        
        # SQLite backend for append-only logging
        self.use_sqlite = use_sqlite
        self.db_path = self.log_dir / "episodes.db"
        self.conn = None
        self.cursor = None
        self.batch_size = batch_size
        self.pending_writes = 0
        
        # Async logging support
        self.async_mode = async_mode
        self.write_queue = None
        self.writer_thread = None
        self._shutdown_event = None
        
        if use_sqlite:
            self._init_database()
        
        # Start async writer if enabled
        if async_mode:
            self._start_async_writer()

    def _init_database(self):
        """Initialize SQLite database with append-only schema."""
        try:
            # Enable shared cache and check_same_thread=False for async mode
            self.conn = sqlite3.connect(
                str(self.db_path),
                check_same_thread=False  # Allow access from writer thread
            )
            self.cursor = self.conn.cursor()
            
            # Create episodes table with immutable fields
            self.cursor.execute('''
                CREATE TABLE IF NOT EXISTS episodes (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    episode_id INTEGER UNIQUE NOT NULL,
                    timestamp REAL NOT NULL,
                    domain TEXT,
                    task_type TEXT,
                    correctness REAL,
                    score REAL,
                    runtime_ms REAL,
                    quality_level REAL,
                    mode TEXT,
                    difficulty TEXT,
                    metadata_json TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            ''')
            
            # Create index for common queries
            self.cursor.execute('CREATE INDEX IF NOT EXISTS idx_episode_id ON episodes(episode_id)')
            self.cursor.execute('CREATE INDEX IF NOT EXISTS idx_domain ON episodes(domain)')
            self.cursor.execute('CREATE INDEX IF NOT EXISTS idx_timestamp ON episodes(timestamp)')
            
            # Create provenance table for tracking data lineage
            self.cursor.execute('''
                CREATE TABLE IF NOT EXISTS provenance (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    episode_id INTEGER NOT NULL,
                    source_type TEXT NOT NULL,
                    source_id TEXT,
                    source_data TEXT,
                    relationship TEXT,
                    FOREIGN KEY (episode_id) REFERENCES episodes(episode_id)
                )
            ''')
            self.cursor.execute('CREATE INDEX IF NOT EXISTS idx_prov_episode ON provenance(episode_id)')
            
            self.conn.commit()
        except Exception as e:
            print(f"Warning: Failed to initialize SQLite database: {e}")
            self.use_sqlite = False
    
    def _start_async_writer(self):
        """Start background writer thread for async logging."""
        self.write_queue = queue.Queue(maxsize=1000)
        self._shutdown_event = threading.Event()
        self.writer_thread = threading.Thread(target=self._writer_loop, daemon=True)
        self.writer_thread.start()
        print(f"Async writer thread started: {self.writer_thread.name}, alive={self.writer_thread.is_alive()}")
    
    def _writer_loop(self):
        """Background thread that processes write queue."""
        processed = 0
        errors = 0
        consecutive_timeouts = 0
        max_consecutive_timeouts = 300  # Allow up to 30 seconds of no activity before exiting
        
        while not self._shutdown_event.is_set():
            try:
                # Get item from queue with timeout
                try:
                    item = self.write_queue.get(timeout=0.1)  # Shorter timeout for responsiveness
                    consecutive_timeouts = 0  # Reset on successful get
                except queue.Empty:
                    consecutive_timeouts += 1
                    if consecutive_timeouts >= max_consecutive_timeouts:
                        print(f"Async writer: {max_consecutive_timeouts} consecutive timeouts, exiting")
                        break
                    continue
                
                if item is None:  # Shutdown signal
                    print(f"Async writer received shutdown signal")
                    break
                
                try:
                    # Process write
                    episode_data = item
                    
                    print(f"Async writer processing item {processed+1}, episode_id={episode_data.get('episode_id')}")
                    
                    # Write to JSONL
                    with open(self.log_file, "a", encoding="utf-8") as f:
                        f.write(json.dumps(episode_data, default=str) + "\n")
                    
                    # Write to SQLite
                    if self.use_sqlite and self.conn:
                        try:
                            print(f"Async writer: Attempting SQLite insert for episode {episode_data.get('episode_id')}")
                            self.cursor.execute('''
                                INSERT OR IGNORE INTO episodes 
                                (episode_id, timestamp, domain, task_type, correctness, 
                                 score, runtime_ms, quality_level, mode, difficulty, metadata_json)
                                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                            ''', (
                                episode_data.get("episode_id"),
                                episode_data.get("timestamp"),
                                episode_data.get("domain"),
                                episode_data.get("task_type"),
                                episode_data.get("correctness"),
                                episode_data.get("score"),
                                episode_data.get("runtime_ms"),
                                episode_data.get("quality_level"),
                                episode_data.get("mode"),
                                episode_data.get("difficulty"),
                                episode_data.get("metadata_json", "{}")
                            ))
                            print(f"Async writer: SQLite insert succeeded for episode {episode_data.get('episode_id')}")
                            
                            self.pending_writes += 1
                            if self.pending_writes >= self.batch_size:
                                print(f"Async writer: Committing batch at {self.pending_writes} writes")
                                self.conn.commit()
                                self.pending_writes = 0
                                
                            processed += 1
                            if processed % 10 == 0:
                                print(f"Async writer progress: {processed} items processed")
                        except Exception as e:
                            errors += 1
                            print(f"Warning: Async SQLite write failed (error #{errors}): {e}")
                            import traceback
                            traceback.print_exc()
                            # Continue processing even if SQLite fails
                finally:
                    # Always mark task as done, even if processing failed
                    self.write_queue.task_done()
                    
            except Exception as e:
                errors += 1
                print(f"Warning: Writer loop error (error #{errors}): {e}")
                import traceback
                traceback.print_exc()
        
        # Final commit on shutdown
        if self.conn and self.pending_writes > 0:
            try:
                self.conn.commit()
                print(f"Async writer final commit: {self.pending_writes} pending writes")
            except Exception as e:
                print(f"Warning: Final commit failed: {e}")
        
        print(f"Async writer shutting down. Total processed: {processed}, Errors: {errors}")
    
    def log_episode(self, episode_data: Dict[str, Any]):
        """
        Log a single episode to JSONL file and SQLite database.
        
        In async mode, this returns immediately and writes happen in background.
        In sync mode, this blocks until write is complete.
        
        Args:
            episode_data: Dictionary containing all episode information
        """
        # Add metadata
        episode_data["timestamp"] = time.time()
        episode_data["episode_id"] = self.episode_count
        
        if self.async_mode:
            # Async mode: queue the write and return immediately
            try:
                # Serialize metadata for queue
                episode_data["metadata_json"] = json.dumps(episode_data, default=str)
                self.write_queue.put_nowait(episode_data.copy())
            except queue.Full:
                print("Warning: Write queue full, dropping episode")
        else:
            # Sync mode: write directly (existing logic)
            # Write to JSONL (streaming format)
            with open(self.log_file, "a", encoding="utf-8") as f:
                f.write(json.dumps(episode_data, default=str) + "\n")
            
            # Write to SQLite (queryable format) with batching
            if self.use_sqlite and self.conn:
                try:
                    self.cursor.execute('''
                        INSERT OR IGNORE INTO episodes 
                        (episode_id, timestamp, domain, task_type, correctness, 
                         score, runtime_ms, quality_level, mode, difficulty, metadata_json)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    ''', (
                        self.episode_count,
                        episode_data.get("timestamp"),
                        episode_data.get("domain"),
                        episode_data.get("task_type"),
                        episode_data.get("correctness"),
                        episode_data.get("score"),
                        episode_data.get("runtime_ms"),
                        episode_data.get("quality_level"),
                        episode_data.get("mode"),
                        episode_data.get("difficulty"),
                        json.dumps(episode_data, default=str)
                    ))
                    
                    self.pending_writes += 1
                    
                    # Batch commit: only commit every batch_size writes
                    if self.pending_writes >= self.batch_size:
                        self.conn.commit()
                        self.pending_writes = 0
                except Exception as e:
                    print(f"Warning: Failed to write to SQLite: {e}")
        
        self.episode_count += 1
    
    def add_provenance(self, episode_id: int, source_type: str, source_id: str, 
                      source_data: Any, relationship: str = "derived_from"):
        """
        Add provenance tracking for an episode.
        
        Args:
            episode_id: Episode identifier
            source_type: Type of source (skill, task, mutation, etc.)
            source_id: Identifier of the source
            source_data: Source data (will be JSON serialized)
            relationship: Relationship type (derived_from, influenced_by, etc.)
        """
        if not self.use_sqlite or not self.conn:
            return
        
        try:
            self.cursor.execute('''
                INSERT INTO provenance (episode_id, source_type, source_id, source_data, relationship)
                VALUES (?, ?, ?, ?, ?)
            ''', (
                episode_id,
                source_type,
                source_id,
                json.dumps(source_data, default=str),
                relationship
            ))
            self.conn.commit()
        except Exception as e:
            print(f"Warning: Failed to add provenance: {e}")

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

    def query_episodes(self, domain: str = None, min_correctness: float = None,
                      limit: int = None) -> List[Dict[str, Any]]:
        """
        Query episodes from SQLite database.
        
        Args:
            domain: Filter by domain (optional)
            min_correctness: Filter by minimum correctness (optional)
            limit: Maximum number of results (optional)
            
        Returns:
            List of episode dictionaries
        """
        if not self.use_sqlite or not self.conn:
            return self.read_all_episodes()[-limit:] if limit else self.read_all_episodes()
        
        try:
            query = "SELECT * FROM episodes WHERE 1=1"
            params = []
            
            if domain:
                query += " AND domain = ?"
                params.append(domain)
            
            if min_correctness is not None:
                query += " AND correctness >= ?"
                params.append(min_correctness)
            
            query += " ORDER BY episode_id DESC"
            
            if limit:
                query += " LIMIT ?"
                params.append(limit)
            
            self.cursor.execute(query, params)
            columns = [desc[0] for desc in self.cursor.description]
            
            episodes = []
            for row in self.cursor.fetchall():
                episode = dict(zip(columns, row))
                # Parse metadata_json back to dict
                if episode.get('metadata_json'):
                    try:
                        episode['metadata'] = json.loads(episode['metadata_json'])
                    except Exception:
                        episode['metadata'] = {}
                episodes.append(episode)
            
            return episodes
        except Exception as e:
            print(f"Warning: Query failed: {e}")
            return []
    
    def get_provenance_chain(self, episode_id: int) -> List[Dict[str, Any]]:
        """
        Get provenance chain for an episode.
        
        Args:
            episode_id: Episode identifier
            
        Returns:
            List of provenance records showing data lineage
        """
        if not self.use_sqlite or not self.conn:
            return []
        
        try:
            self.cursor.execute('''
                SELECT source_type, source_id, source_data, relationship
                FROM provenance
                WHERE episode_id = ?
                ORDER BY id ASC
            ''', (episode_id,))
            
            provenance = []
            for row in self.cursor.fetchall():
                prov = {
                    'source_type': row[0],
                    'source_id': row[1],
                    'relationship': row[3]
                }
                try:
                    prov['source_data'] = json.loads(row[2])
                except Exception:
                    prov['source_data'] = row[2]
                provenance.append(prov)
            
            return provenance
        except Exception as e:
            print(f"Warning: Provenance query failed: {e}")
            return []
    
    def close(self):
        """Close database connection, flushing any pending writes."""
        # Shutdown async writer if enabled
        if self.async_mode and self.writer_thread:
            try:
                # Signal shutdown
                self._shutdown_event.set()
                
                # Wait for queue to drain with manual timeout
                import time as _time
                start = _time.time()
                timeout = 10.0
                # Wait until queue is empty AND writer has had time to process
                while (_time.time() - start) < timeout:
                    if self.write_queue.empty():
                        # Give writer thread a moment to finish current item
                        _time.sleep(0.2)
                        break
                    _time.sleep(0.1)
                
                # Stop writer thread
                self.writer_thread.join(timeout=5.0)
            except Exception as e:
                print(f"Warning: Async shutdown failed: {e}")
        
        # Close database connection
        if self.conn:
            try:
                # Flush any pending batched writes
                if self.pending_writes > 0:
                    self.conn.commit()
                    self.pending_writes = 0
                self.conn.close()
            except Exception:
                pass
    
    def __del__(self):
        """Cleanup on destruction."""
        self.close()
