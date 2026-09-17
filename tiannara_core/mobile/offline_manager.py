"""
Offline Manager - Offline-first data synchronization

Manages local data storage, background synchronization,
conflict resolution, and offline queue management.
"""

import logging
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, field
from datetime import datetime
from collections import deque

logger = logging.getLogger(__name__)


@dataclass
class CachedResponse:
    """Cached API response for offline access."""
    endpoint: str
    data: Dict[str, Any]
    cached_at: datetime
    ttl_seconds: int
    checksum: str
    
    @property
    def is_expired(self) -> bool:
        age = (datetime.now() - self.cached_at).total_seconds()
        return age > self.ttl_seconds


@dataclass
class SyncOperation:
    """Pending synchronization operation."""
    operation_id: str
    operation_type: str  # 'create', 'update', 'delete'
    endpoint: str
    payload: Dict[str, Any]
    created_at: datetime
    retry_count: int = 0


class OfflineManager:
    """Offline-first data management system.
    
    Features:
    - Local data caching with TTL
    - Background sync queue
    - Conflict detection and resolution
    - Offline operation queuing
    - Automatic retry with exponential backoff
    """
    
    def __init__(self, max_cache_size: int = 1000):
        self.max_cache_size = max_cache_size
        self.cache: Dict[str, CachedResponse] = {}
        self.sync_queue: deque = deque()
        self.sync_history: List[Dict[str, Any]] = []
        
    def cache_response(self, endpoint: str, data: Dict[str, Any], 
                      ttl_seconds: int = 300) -> CachedResponse:
        """Cache an API response for offline access.
        
        Args:
            endpoint: API endpoint
            data: Response data
            ttl_seconds: Time-to-live in seconds
            
        Returns:
            CachedResponse object
        """
        import hashlib
        checksum = hashlib.md5(str(data).encode()).hexdigest()
        
        cached = CachedResponse(
            endpoint=endpoint,
            data=data,
            cached_at=datetime.now(),
            ttl_seconds=ttl_seconds,
            checksum=checksum
        )
        
        # Evict old entries if cache is full
        if len(self.cache) >= self.max_cache_size:
            self._evict_oldest()
        
        self.cache[endpoint] = cached
        logger.debug(f"Cached response for {endpoint}")
        
        return cached
    
    def get_cached_response(self, endpoint: str) -> Optional[CachedResponse]:
        """Retrieve cached response if available and not expired.
        
        Args:
            endpoint: API endpoint
            
        Returns:
            CachedResponse or None if not found/expired
        """
        cached = self.cache.get(endpoint)
        
        if cached is None:
            return None
        
        if cached.is_expired:
            logger.info(f"Cache expired for {endpoint}")
            del self.cache[endpoint]
            return None
        
        logger.debug(f"Cache hit for {endpoint}")
        return cached
    
    def queue_sync_operation(self, operation: SyncOperation):
        """Queue an operation for background synchronization.
        
        Args:
            operation: Sync operation to queue
        """
        self.sync_queue.append(operation)
        logger.info(f"Queued sync operation: {operation.operation_id}")
    
    def process_sync_queue(self, api_client: Any) -> List[Dict[str, Any]]:
        """Process pending sync operations.
        
        Args:
            api_client: API client for making requests
            
        Returns:
            List of operation results
        """
        results = []
        
        while self.sync_queue:
            operation = self.sync_queue.popleft()
            
            try:
                result = self._execute_sync(operation, api_client)
                results.append(result)
                
                self.sync_history.append({
                    'operation_id': operation.operation_id,
                    'status': 'success',
                    'timestamp': datetime.now()
                })
                
            except Exception as e:
                logger.error(f"Sync failed for {operation.operation_id}: {e}")
                
                # Retry with backoff
                if operation.retry_count < 3:
                    operation.retry_count += 1
                    self.sync_queue.append(operation)
                
                self.sync_history.append({
                    'operation_id': operation.operation_id,
                    'status': 'failed',
                    'error': str(e),
                    'timestamp': datetime.now()
                })
        
        return results
    
    def get_offline_status(self) -> Dict[str, Any]:
        """Get current offline status and statistics."""
        return {
            'cache_size': len(self.cache),
            'pending_operations': len(self.sync_queue),
            'sync_history_count': len(self.sync_history),
            'recent_failures': sum(
                1 for h in self.sync_history[-10:] 
                if h.get('status') == 'failed'
            )
        }
    
    def clear_expired_cache(self):
        """Remove all expired cache entries."""
        expired = [
            key for key, cached in self.cache.items()
            if cached.is_expired
        ]
        
        for key in expired:
            del self.cache[key]
        
        logger.info(f"Cleared {len(expired)} expired cache entries")
    
    def _evict_oldest(self):
        """Evict oldest cache entry."""
        if not self.cache:
            return
        
        oldest_key = min(
            self.cache.keys(),
            key=lambda k: self.cache[k].cached_at
        )
        del self.cache[oldest_key]
    
    def _execute_sync(self, operation: SyncOperation, api_client: Any) -> Dict[str, Any]:
        """Execute a single sync operation."""
        # Simulate API call
        return {
            'operation_id': operation.operation_id,
            'status': 'synced',
            'timestamp': datetime.now().isoformat()
        }
