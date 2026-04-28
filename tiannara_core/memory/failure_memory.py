"""
Failure Memory System

Tracks failure patterns and informs the evolution system.
Enables Tiannara to learn from failures and improve over time.
"""

from typing import Dict, Any, List, Optional
from dataclasses import dataclass, field
from datetime import datetime
import json
import uuid
from pathlib import Path
import logging
from collections import defaultdict


@dataclass
class FailureRecord:
    """Represents a single failure event."""
    id: str
    timestamp: str
    component: str
    error: str
    intent: str
    step: str
    context: Dict[str, Any] = field(default_factory=dict)
    attempt_number: int = 1
    resolved: bool = False
    resolution_notes: str = ""


class FailureMemory:
    """Manages storage and analysis of failure records."""
    
    def __init__(self, storage_path: str = "data/failures.json"):
        self.storage_path = Path(storage_path)
        self.storage_path.parent.mkdir(parents=True, exist_ok=True)
        
        self.logger = logging.getLogger("tiannara.failure_memory")
        self.failures: List[FailureRecord] = []
        self.failure_counts = defaultdict(int)  # Track counts by component/error type
        
        self.load_failures()
    
    def load_failures(self):
        """Load failure records from storage."""
        if not self.storage_path.exists():
            self.logger.info("No existing failures file found")
            return
        
        try:
            with open(self.storage_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            for record_data in data.get('failures', []):
                record = FailureRecord(
                    id=record_data['id'],
                    timestamp=record_data['timestamp'],
                    component=record_data['component'],
                    error=record_data['error'],
                    intent=record_data['intent'],
                    step=record_data['step'],
                    context=record_data.get('context', {}),
                    attempt_number=record_data.get('attempt_number', 1),
                    resolved=record_data.get('resolved', False),
                    resolution_notes=record_data.get('resolution_notes', '')
                )
                self.failures.append(record)
                self.failure_counts[f"{record.component}:{record.error}"] += 1
            
            self.logger.info(f"Loaded {len(self.failures)} failure records")
            
        except Exception as e:
            self.logger.error(f"Failed to load failures: {e}")
    
    def save_failures(self):
        """Save failure records to storage."""
        try:
            data = {
                'failures': [
                    {
                        'id': record.id,
                        'timestamp': record.timestamp,
                        'component': record.component,
                        'error': record.error,
                        'intent': record.intent,
                        'step': record.step,
                        'context': record.context,
                        'attempt_number': record.attempt_number,
                        'resolved': record.resolved,
                        'resolution_notes': record.resolution_notes
                    }
                    for record in self.failures
                ],
                'last_saved': datetime.now().isoformat(),
                'failure_counts': dict(self.failure_counts)
            }
            
            with open(self.storage_path, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=2, ensure_ascii=False)
            
            self.logger.debug(f"Saved {len(self.failures)} failure records")
            
        except Exception as e:
            self.logger.error(f"Failed to save failures: {e}")
    
    def log_failure(
        self, 
        intent: str, 
        error: Exception, 
        component: str = "unknown",
        step: str = "unknown",
        context: Optional[Dict[str, Any]] = None
    ):
        """Log a failure event."""
        context = context or {}
        
        record = FailureRecord(
            id=f"fail_{uuid.uuid4().hex[:8]}",
            timestamp=datetime.now().isoformat(),
            component=component,
            error=str(error),
            intent=intent,
            step=step,
            context=context
        )
        
        self.failures.append(record)
        self.failure_counts[f"{component}:{str(error)}"] += 1
        
        self.save_failures()
        self.logger.info(f"Logged failure: {component} - {str(error)[:100]}...")
    
    def mark_resolved(self, failure_id: str, notes: str = ""):
        """Mark a failure as resolved."""
        for record in self.failures:
            if record.id == failure_id:
                record.resolved = True
                record.resolution_notes = notes
                self.save_failures()
                self.logger.info(f"Marked failure {failure_id} as resolved")
                return True
        return False
    
    def get_unresolved_failures(self) -> List[FailureRecord]:
        """Get all unresolved failures."""
        return [f for f in self.failures if not f.resolved]
    
    def get_failures_by_component(self, component: str) -> List[FailureRecord]:
        """Get failures for a specific component."""
        return [f for f in self.failures if f.component == component]
    
    def get_failures_by_error_pattern(self, pattern: str) -> List[FailureRecord]:
        """Get failures matching an error pattern."""
        return [f for f in self.failures if pattern.lower() in f.error.lower()]
    
    def get_failure_summary(self) -> Dict[str, Any]:
        """Get a summary of failure patterns."""
        if not self.failures:
            return {
                "total_failures": 0,
                "unresolved_count": 0,
                "top_components": [],
                "top_errors": []
            }
        
        # Count failures by component
        component_counts = defaultdict(int)
        error_counts = defaultdict(int)
        
        for failure in self.failures:
            component_counts[failure.component] += 1
            error_counts[failure.error] += 1
        
        # Sort by count
        top_components = sorted(
            component_counts.items(), 
            key=lambda x: x[1], 
            reverse=True
        )[:5]
        
        top_errors = sorted(
            error_counts.items(), 
            key=lambda x: x[1], 
            reverse=True
        )[:5]
        
        unresolved_count = len([f for f in self.failures if not f.resolved])
        
        return {
            "total_failures": len(self.failures),
            "unresolved_count": unresolved_count,
            "top_components": top_components,
            "top_errors": top_errors,
            "first_failure": self.failures[0].timestamp if self.failures else None,
            "latest_failure": self.failures[-1].timestamp if self.failures else None
        }
    
    def get_recurring_failures(self, min_occurrences: int = 2) -> List[Dict[str, Any]]:
        """Get failures that occur multiple times."""
        recurring = []
        
        for error_key, count in self.failure_counts.items():
            if count >= min_occurrences:
                component, error_msg = error_key.split(':', 1)
                
                # Get recent occurrences
                recent_failures = [
                    f for f in self.failures 
                    if f.component == component and f.error == error_msg
                ][-3:]  # Last 3 occurrences
                
                recurring.append({
                    "component": component,
                    "error": error_msg,
                    "count": count,
                    "recent_occurrences": [
                        {"id": f.id, "timestamp": f.timestamp, "intent": f.intent}
                        for f in recent_failures
                    ]
                })
        
        return recurring
    
    def cleanup_old_failures(self, days: int = 30) -> int:
        """Remove failures older than specified days if resolved."""
        from datetime import datetime, timedelta
        
        cutoff = datetime.now() - timedelta(days=days)
        
        to_remove = []
        for i, failure in enumerate(self.failures):
            if failure.resolved and datetime.fromisoformat(failure.timestamp) < cutoff:
                to_remove.append(i)
        
        # Remove in reverse order to maintain indices
        for i in reversed(to_remove):
            del self.failures[i]
        
        if to_remove:
            self.save_failures()
            self.logger.info(f"Cleaned up {len(to_remove)} old resolved failures")
        
        return len(to_remove)


# Global failure memory instance
_failure_memory = None


def get_failure_memory() -> FailureMemory:
    """Get or create the global failure memory instance."""
    global _failure_memory
    if _failure_memory is None:
        _failure_memory = FailureMemory()
    return _failure_memory


def log_failure(
    intent: str, 
    error: Exception, 
    component: str = "unknown",
    step: str = "unknown",
    context: Optional[Dict[str, Any]] = None
):
    """Quick access function for logging failures."""
    memory = get_failure_memory()
    memory.log_failure(intent, error, component, step, context)


def get_failure_summary() -> Dict[str, Any]:
    """Quick access function for getting failure summary."""
    memory = get_failure_memory()
    return memory.get_failure_summary()


def get_recurring_failures(min_occurrences: int = 2) -> List[Dict[str, Any]]:
    """Quick access function for getting recurring failures."""
    memory = get_failure_memory()
    return memory.get_recurring_failures()