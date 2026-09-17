"""
Centralized Error Tracking System

Provides structured error logging, monitoring, and alerting for the evaluation system.
Replaces ad-hoc exception handling with systematic error management.
"""

import logging
import json
from pathlib import Path
from datetime import datetime
from collections import defaultdict
from typing import Dict, Any, Optional


class ErrorTracker:
    """Centralized error tracking and monitoring."""
    
    def __init__(self, log_dir: str = "logs"):
        self.log_dir = Path(log_dir)
        self.log_dir.mkdir(exist_ok=True)
        
        # Error storage
        self.errors = []
        self.error_counts = defaultdict(int)
        self.domain_error_rates = defaultdict(lambda: {"total": 0, "errors": 0})
        
        # Setup logging
        self.logger = self._setup_logger()
        
        # Alert thresholds
        self.error_rate_threshold = 0.1  # Alert if >10% error rate
        self.critical_error_types = {"MemoryError", "KeyboardInterrupt"}
    
    def _setup_logger(self) -> logging.Logger:
        """Setup structured logging with file and console handlers."""
        logger = logging.getLogger("tiannara.evaluation")
        logger.setLevel(logging.DEBUG)
        
        # File handler for errors (JSON format)
        error_log_path = self.log_dir / f"errors_{datetime.now().strftime('%Y%m%d')}.jsonl"
        file_handler = logging.FileHandler(error_log_path)
        file_handler.setLevel(logging.ERROR)
        
        # Console handler for warnings and above
        console_handler = logging.StreamHandler()
        console_handler.setLevel(logging.WARNING)
        
        # Formatter
        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        file_handler.setFormatter(formatter)
        console_handler.setFormatter(formatter)
        
        logger.addHandler(file_handler)
        logger.addHandler(console_handler)
        
        return logger
    
    def log_error(self, 
                  domain: str, 
                  episode: int, 
                  error: Exception, 
                  context: Optional[Dict[str, Any]] = None):
        """
        Log an error with full context.
        
        Args:
            domain: Domain where error occurred (algorithm, logic, etc.)
            episode: Episode number
            error: The exception that was raised
            context: Additional context (task info, evolver state, etc.)
        """
        error_type = type(error).__name__
        error_msg = str(error)
        
        # Create structured error record
        error_record = {
            "timestamp": datetime.now().isoformat(),
            "domain": domain,
            "episode": episode,
            "error_type": error_type,
            "error_message": error_msg,
            "context": context or {},
            "traceback": self._get_traceback(error)
        }
        
        # Store in memory
        self.errors.append(error_record)
        self.error_counts[f"{domain}:{error_type}"] += 1
        
        # Update domain error rates
        self.domain_error_rates[domain]["total"] += 1
        self.domain_error_rates[domain]["errors"] += 1
        
        # Log to file
        self.logger.error(
            f"[{domain}] Episode {episode}: {error_type} - {error_msg}",
            extra={"error_record": error_record}
        )
        
        # Check for critical errors
        if error_type in self.critical_error_types:
            self.logger.critical(f"CRITICAL ERROR: {error_type} in {domain}")
            self._send_alert(f"Critical error in {domain}: {error_type}")
        
        # Check error rate
        self._check_error_rate(domain)
    
    def log_success(self, domain: str, episode: int):
        """Log a successful episode (for error rate calculation)."""
        self.domain_error_rates[domain]["total"] += 1
    
    def _get_traceback(self, error: Exception) -> str:
        """Extract traceback from exception."""
        import traceback
        return ''.join(traceback.format_exception(type(error), error, error.__traceback__))
    
    def _check_error_rate(self, domain: str):
        """Check if error rate exceeds threshold."""
        stats = self.domain_error_rates[domain]
        if stats["total"] > 0:
            error_rate = stats["errors"] / stats["total"]
            if error_rate > self.error_rate_threshold:
                self.logger.warning(
                    f"High error rate in {domain}: {error_rate:.1%} "
                    f"({stats['errors']}/{stats['total']} episodes)"
                )
    
    def _send_alert(self, message: str):
        """Send alert (placeholder - implement email/Slack integration)."""
        # TODO: Implement actual alerting mechanism
        self.logger.critical(f"ALERT: {message}")
        print(f"\n*** ALERT: {message} ***\n")
    
    def get_top_errors(self, n: int = 10) -> list:
        """Get the most frequent error types."""
        sorted_errors = sorted(
            self.error_counts.items(), 
            key=lambda x: x[1], 
            reverse=True
        )
        return sorted_errors[:n]
    
    def get_domain_error_rates(self) -> Dict[str, float]:
        """Get error rates by domain."""
        rates = {}
        for domain, stats in self.domain_error_rates.items():
            if stats["total"] > 0:
                rates[domain] = stats["errors"] / stats["total"]
            else:
                rates[domain] = 0.0
        return rates
    
    def get_recent_errors(self, n: int = 20) -> list:
        """Get the most recent errors."""
        return self.errors[-n:]
    
    def save_report(self, filepath: Optional[str] = None):
        """Save comprehensive error report to file."""
        if filepath is None:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filepath = self.log_dir / f"error_report_{timestamp}.json"
        else:
            filepath = Path(filepath)
        
        report = {
            "generated_at": datetime.now().isoformat(),
            "total_errors": len(self.errors),
            "top_errors": self.get_top_errors(20),
            "domain_error_rates": self.get_domain_error_rates(),
            "recent_errors": self.get_recent_errors(50),
            "all_errors": self.errors
        }
        
        with open(filepath, 'w') as f:
            json.dump(report, f, indent=2, default=str)
        
        self.logger.info(f"Error report saved to {filepath}")
        return filepath
    
    def reset(self):
        """Reset all error tracking (useful for fresh experiments)."""
        self.errors.clear()
        self.error_counts.clear()
        self.domain_error_rates.clear()
        self.logger.info("Error tracker reset")


# Global error tracker instance
_error_tracker = None


def get_error_tracker() -> ErrorTracker:
    """Get or create the global error tracker instance."""
    global _error_tracker
    if _error_tracker is None:
        _error_tracker = ErrorTracker()
    return _error_tracker


def safe_execute(func, *args, domain: str = "unknown", episode: int = 0, 
                 context: dict = None, **kwargs):
    """
    Safely execute a function with automatic error tracking.
    
    Usage:
        result = safe_execute(some_function, arg1, arg2, 
                             domain="algorithm", episode=42)
    
    Args:
        func: Function to execute
        *args: Positional arguments to pass to func
        domain: Domain name for error tracking
        episode: Episode number
        context: Additional context for error logging
        **kwargs: Keyword arguments to pass to func
    
    Returns:
        Result of func if successful, None if error occurred
    """
    try:
        return func(*args, **kwargs)
    except Exception as e:
        tracker = get_error_tracker()
        tracker.log_error(domain, episode, e, context)
        return None


# Convenience wrapper for common patterns
def track_errors(func):
    """Decorator to automatically track errors in a function."""
    from functools import wraps
    
    @wraps(func)
    def wrapper(*args, **kwargs):
        try:
            return func(*args, **kwargs)
        except Exception as e:
            # Try to extract domain and episode from context
            domain = kwargs.get('domain', 'unknown')
            episode = kwargs.get('episode', 0)
            context = {
                "function": func.__name__,
                "args": str(args[:3]),  # First 3 args for brevity
                "kwargs": {k: v for k, v in list(kwargs.items())[:5]}
            }
            
            tracker = get_error_tracker()
            tracker.log_error(domain, episode, e, context)
            raise  # Re-raise after logging
    
    return wrapper
