"""
Gateway Orchestrator

Coordinates multi-domain requests, caching, and priority queue management.
Decides which engine(s) to use and handles cross-domain collaboration.
"""

import time
import logging
from typing import Dict, Any, List, Optional
from datetime import datetime

logger = logging.getLogger(__name__)


class GatewayOrchestrator:
    """
    Orchestrates request flow through multiple domain engines.
    
    Features:
    - Multi-domain collaboration
    - Caching layer
    - Priority queue management
    - Request batching
    """
    
    def __init__(self):
        self.cache = {}  # Simple in-memory cache
        self.cache_ttl = 300  # 5 minutes cache TTL
        self.active_flows = []  # Track active orchestration flows
        
        logger.info("Gateway Orchestrator initialized")
    
    def orchestrate(self, request: Dict[str, Any], engine_sequence: List[str]) -> Dict[str, Any]:
        """
        Orchestrate a request through multiple engines in sequence.
        
        Args:
            request: Original request data
            engine_sequence: List of engine names to process in order
            
        Returns:
            Final result after all engines have processed
        """
        start_time = time.time()
        flow_id = f"flow_{datetime.utcnow().timestamp()}"
        
        flow_log = {
            "flow_id": flow_id,
            "sequence": engine_sequence,
            "steps": [],
            "started_at": datetime.utcnow().isoformat(),
        }
        
        current_data = request.copy()
        
        for engine_name in engine_sequence:
            step_start = time.time()
            
            try:
                # TODO: Get engine from registry and process
                # For now, simulate processing
                current_data[f"processed_by_{engine_name}"] = True
                
                step_latency = (time.time() - step_start) * 1000
                flow_log["steps"].append({
                    "engine": engine_name,
                    "status": "success",
                    "latency_ms": round(step_latency, 2),
                })
            
            except Exception as e:
                step_latency = (time.time() - step_start) * 1000
                flow_log["steps"].append({
                    "engine": engine_name,
                    "status": "error",
                    "error": str(e),
                    "latency_ms": round(step_latency, 2),
                })
                logger.error(f"Orchestration step failed for {engine_name}: {str(e)}")
                break
        
        total_latency = (time.time() - start_time) * 1000
        flow_log["completed_at"] = datetime.utcnow().isoformat()
        flow_log["total_latency_ms"] = round(total_latency, 2)
        
        self.active_flows.append(flow_log)
        
        # Keep only recent flows
        if len(self.active_flows) > 100:
            self.active_flows = self.active_flows[-100:]
        
        return {
            "flow_id": flow_id,
            "result": current_data,
            "latency_ms": round(total_latency, 2),
            "engines_used": engine_sequence,
            "steps": flow_log["steps"],
        }
    
    def check_cache(self, cache_key: str) -> Optional[Any]:
        """
        Check if result exists in cache.
        
        Args:
            cache_key: Unique cache key
            
        Returns:
            Cached result or None
        """
        if cache_key not in self.cache:
            return None
        
        cached = self.cache[cache_key]
        
        # Check if cache expired
        if time.time() - cached["timestamp"] > self.cache_ttl:
            del self.cache[cache_key]
            return None
        
        logger.info(f"Cache hit for: {cache_key}")
        return cached["data"]
    
    def cache_result(self, cache_key: str, data: Any):
        """
        Cache a result for future requests.
        
        Args:
            cache_key: Unique cache key
            data: Data to cache
        """
        self.cache[cache_key] = {
            "data": data,
            "timestamp": time.time(),
        }
        logger.debug(f"Result cached: {cache_key}")
    
    def clear_cache(self):
        """Clear all cached data."""
        self.cache.clear()
        logger.info("Cache cleared")
    
    def get_active_flows(self) -> List[Dict[str, Any]]:
        """Get recent orchestration flows."""
        return self.active_flows.copy()


# Create global instance
orchestrator = GatewayOrchestrator()
