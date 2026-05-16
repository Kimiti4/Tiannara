"""
Redis Caching Layer for Tiannara Core

Provides high-performance caching for:
- Live match features (sports predictions)
- System integrity metrics (1,000-step mission)
- Feature store snapshots
- Real-time state management

Supports both sports prediction pipeline and cognitive health monitoring.
"""

import json
import logging
from typing import Optional, Dict, Any, List
from datetime import datetime, timedelta

try:
    import redis.asyncio as redis
    REDIS_AVAILABLE = True
except ImportError:
    REDIS_AVAILABLE = False
    import asyncio
    
logger = logging.getLogger(__name__)


class TiannaraRedisCache:
    """
    Unified Redis caching layer for Tiannara Core.
    
    Handles:
    - Live match feature caching (30s TTL)
    - System integrity metrics (persistent)
    - Feature store snapshots (hourly/daily)
    - Real-time state management
    """
    
    def __init__(self, host: str = "localhost", port: int = 6379, db: int = 0):
        self.host = host
        self.port = port
        self.db = db
        self.redis_client = None
        self._memory_store = {}  # Initialize in-memory fallback
        
        if REDIS_AVAILABLE:
            logger.info(f"✅ Redis cache initialized (host={host}, port={port})")
        else:
            logger.warning("⚠️  redis-py not available - using in-memory fallback")
    
    async def connect(self):
        """Establish Redis connection."""
        if REDIS_AVAILABLE:
            try:
                self.redis_client = redis.Redis(
                    host=self.host,
                    port=self.port,
                    db=self.db,
                    decode_responses=True
                )
                # Test connection
                await self.redis_client.ping()
                logger.info("✅ Redis connection established")
            except Exception as e:
                logger.error(f"❌ Redis connection failed: {e}")
                self.redis_client = None
        else:
            # In-memory fallback for development
            self._memory_store = {}
            logger.info("ℹ️  Using in-memory fallback cache")
    
    async def disconnect(self):
        """Close Redis connection."""
        if self.redis_client:
            await self.redis_client.close()
            logger.info("Redis connection closed")
    
    # =========================================================================
    # SPORTS PREDICTION CACHE METHODS
    # =========================================================================
    
    async def cache_match_features(self, match_id: str, features: Dict, ttl: int = 30):
        """
        Cache feature vector for live match.
        
        Args:
            match_id: Unique match identifier
            features: Feature vector from engineer_features()
            ttl: Time-to-live in seconds (default 30s for live updates)
        """
        key = f"sports:match:{match_id}:features"
        
        try:
            if self.redis_client:
                await self.redis_client.setex(
                    key,
                    ttl,
                    json.dumps(features)
                )
            else:
                # Fallback
                self._memory_store[key] = {
                    "data": features,
                    "expires": datetime.now() + timedelta(seconds=ttl)
                }
            
            logger.debug(f"Cached features for match {match_id} (TTL={ttl}s)")
        except Exception as e:
            logger.error(f"Failed to cache match features: {e}")
    
    async def get_match_features(self, match_id: str) -> Optional[Dict]:
        """Retrieve cached feature vector for match."""
        key = f"sports:match:{match_id}:features"
        
        try:
            if self.redis_client:
                data = await self.redis_client.get(key)
                return json.loads(data) if data else None
            else:
                # Fallback
                if key in self._memory_store:
                    entry = self._memory_store[key]
                    if datetime.now() < entry["expires"]:
                        return entry["data"]
                    else:
                        del self._memory_store[key]
                return None
        except Exception as e:
            logger.error(f"Failed to retrieve match features: {e}")
            return None
    
    async def cache_odds_snapshot(self, match_id: str, odds_data: Dict, ttl: int = 60):
        """Cache latest odds snapshot."""
        key = f"sports:match:{match_id}:odds"
        
        try:
            if self.redis_client:
                await self.redis_client.setex(
                    key,
                    ttl,
                    json.dumps({
                        "odds": odds_data,
                        "timestamp": datetime.now().isoformat()
                    })
                )
            else:
                self._memory_store[key] = {
                    "data": {"odds": odds_data, "timestamp": datetime.now().isoformat()},
                    "expires": datetime.now() + timedelta(seconds=ttl)
                }
        except Exception as e:
            logger.error(f"Failed to cache odds: {e}")
    
    async def get_odds_snapshot(self, match_id: str) -> Optional[Dict]:
        """Retrieve latest odds snapshot."""
        key = f"sports:match:{match_id}:odds"
        
        try:
            if self.redis_client:
                data = await self.redis_client.get(key)
                return json.loads(data) if data else None
            else:
                if key in self._memory_store:
                    entry = self._memory_store[key]
                    if datetime.now() < entry["expires"]:
                        return entry["data"]
                return None
        except Exception as e:
            logger.error(f"Failed to retrieve odds: {e}")
            return None
    
    # =========================================================================
    # SYSTEM INTEGRITY MONITORING (1,000-STEP MISSION)
    # =========================================================================
    
    async def record_integrity_metric(self, metric_name: str, value: float, timestamp: Optional[datetime] = None):
        """
        Record system integrity metric for 1,000-step mission tracking.
        
        Metrics tracked:
        - identity_drift: Deviation from core identity/constraints
        - causal_degradation: Quality of causal reasoning over time
        - memory_corruption: Data integrity issues in memory systems
        - confidence_inflation: Overconfidence in predictions
        - contradiction_accumulation: Logical inconsistencies
        
        Args:
            metric_name: One of the 5 integrity metrics
            value: Metric value (typically 0-1 scale, higher = worse)
            timestamp: When metric was recorded (default: now)
        """
        if timestamp is None:
            timestamp = datetime.now()
        
        key = f"integrity:{metric_name}:{timestamp.strftime('%Y%m%d_%H%M%S')}"
        
        try:
            if self.redis_client:
                # Store as sorted set for time-series queries
                await self.redis_client.zadd(
                    f"integrity:{metric_name}:timeline",
                    {json.dumps({"value": value, "timestamp": timestamp.isoformat()}): timestamp.timestamp()}
                )
                
                # Keep only last 1000 measurements
                await self.redis_client.zremrangebyrank(
                    f"integrity:{metric_name}:timeline",
                    0,
                    -1001
                )
                
                # Also store latest value for quick access
                await self.redis_client.set(
                    f"integrity:{metric_name}:latest",
                    json.dumps({
                        "value": value,
                        "timestamp": timestamp.isoformat(),
                        "status": self._assess_metric_status(metric_name, value)
                    })
                )
            else:
                # Fallback
                timeline_key = f"integrity:{metric_name}:timeline"
                if timeline_key not in self._memory_store:
                    self._memory_store[timeline_key] = []
                
                self._memory_store[timeline_key].append({
                    "value": value,
                    "timestamp": timestamp.isoformat()
                })
                
                # Keep last 1000
                if len(self._memory_store[timeline_key]) > 1000:
                    self._memory_store[timeline_key] = self._memory_store[timeline_key][-1000:]
                
                self._memory_store[f"integrity:{metric_name}:latest"] = {
                    "value": value,
                    "timestamp": timestamp.isoformat(),
                    "status": self._assess_metric_status(metric_name, value)
                }
            
            logger.debug(f"Recorded {metric_name} = {value:.4f}")
        except Exception as e:
            logger.error(f"Failed to record integrity metric: {e}")
    
    async def get_integrity_metrics_summary(self) -> Dict[str, Any]:
        """
        Get summary of all 5 integrity metrics.
        
        Returns:
            Dictionary with current status of each metric
        """
        metrics = [
            "identity_drift",
            "causal_degradation", 
            "memory_corruption",
            "confidence_inflation",
            "contradiction_accumulation"
        ]
        
        summary = {}
        
        for metric in metrics:
            latest = await self.get_latest_integrity_metric(metric)
            trend = await self.get_metric_trend(metric, window_hours=24)
            
            summary[metric] = {
                "current_value": latest.get("value", 0.0) if latest else 0.0,
                "status": latest.get("status", "unknown") if latest else "unknown",
                "trend_24h": trend,
                "last_updated": latest.get("timestamp") if latest else None
            }
        
        # Overall system health score
        summary["overall_health"] = self._calculate_overall_health(summary)
        
        return summary
    
    async def get_latest_integrity_metric(self, metric_name: str) -> Optional[Dict]:
        """Get most recent measurement for a specific metric."""
        key = f"integrity:{metric_name}:latest"
        
        try:
            if self.redis_client:
                data = await self.redis_client.get(key)
                return json.loads(data) if data else None
            else:
                return self._memory_store.get(key)
        except Exception as e:
            logger.error(f"Failed to retrieve latest metric: {e}")
            return None
    
    async def get_metric_trend(self, metric_name: str, window_hours: int = 24) -> Dict[str, Any]:
        """
        Calculate trend for metric over time window.
        
        Args:
            metric_name: Which metric to analyze
            window_hours: Time window in hours
        
        Returns:
            Trend analysis with direction and magnitude
        """
        timeline_key = f"integrity:{metric_name}:timeline"
        
        try:
            if self.redis_client:
                # Get measurements from last N hours
                cutoff = datetime.now() - timedelta(hours=window_hours)
                measurements = await self.redis_client.zrangebyscore(
                    timeline_key,
                    cutoff.timestamp(),
                    "+inf",
                    withscores=True
                )
                
                if not measurements:
                    return {"direction": "stable", "magnitude": 0.0, "samples": 0}
                
                # Parse values
                values = [json.loads(m[0])["value"] for m in measurements]
                
                # Calculate trend
                if len(values) >= 2:
                    avg_first_half = sum(values[:len(values)//2]) / (len(values)//2)
                    avg_second_half = sum(values[len(values)//2:]) / (len(values) - len(values)//2)
                    
                    change = avg_second_half - avg_first_half
                    
                    if abs(change) < 0.05:
                        direction = "stable"
                    elif change > 0:
                        direction = "increasing"  # Getting worse
                    else:
                        direction = "decreasing"  # Improving
                    
                    return {
                        "direction": direction,
                        "magnitude": round(abs(change), 4),
                        "samples": len(values),
                        "avg_value": round(sum(values) / len(values), 4)
                    }
                else:
                    return {"direction": "insufficient_data", "magnitude": 0.0, "samples": len(values)}
            else:
                # Fallback
                if timeline_key not in self._memory_store:
                    return {"direction": "no_data", "magnitude": 0.0, "samples": 0}
                
                measurements = self._memory_store[timeline_key]
                cutoff = datetime.now() - timedelta(hours=window_hours)
                
                recent = [
                    m for m in measurements 
                    if datetime.fromisoformat(m["timestamp"]) > cutoff
                ]
                
                if len(recent) >= 2:
                    values = [m["value"] for m in recent]
                    avg_first = sum(values[:len(values)//2]) / (len(values)//2)
                    avg_second = sum(values[len(values)//2:]) / (len(values) - len(values)//2)
                    
                    change = avg_second - avg_first
                    
                    return {
                        "direction": "stable" if abs(change) < 0.05 else ("increasing" if change > 0 else "decreasing"),
                        "magnitude": round(abs(change), 4),
                        "samples": len(recent)
                    }
                
                return {"direction": "insufficient_data", "magnitude": 0.0, "samples": len(recent)}
                
        except Exception as e:
            logger.error(f"Failed to calculate metric trend: {e}")
            return {"direction": "error", "magnitude": 0.0, "samples": 0}
    
    def _assess_metric_status(self, metric_name: str, value: float) -> str:
        """Assess metric status based on threshold."""
        # All metrics use 0-1 scale where higher = worse
        if value < 0.3:
            return "healthy"
        elif value < 0.6:
            return "warning"
        else:
            return "critical"
    
    def _calculate_overall_health(self, metrics_summary: Dict) -> Dict[str, Any]:
        """Calculate overall system health score."""
        metric_values = [
            metrics_summary[m]["current_value"]
            for m in ["identity_drift", "causal_degradation", "memory_corruption",
                     "confidence_inflation", "contradiction_accumulation"]
            if m in metrics_summary
        ]
        
        if not metric_values:
            return {"score": 1.0, "status": "unknown"}
        
        # Average across all metrics (lower is better)
        avg_degradation = sum(metric_values) / len(metric_values)
        health_score = 1.0 - avg_degradation
        
        if health_score > 0.8:
            status = "healthy"
        elif health_score > 0.5:
            status = "degraded"
        else:
            status = "critical"
        
        return {
            "score": round(health_score, 4),
            "status": status,
            "avg_degradation": round(avg_degradation, 4)
        }
    
    # =========================================================================
    # FEATURE STORE (HISTORICAL DATA FOR ML TRAINING)
    # =========================================================================
    
    async def store_feature_snapshot(self, match_id: str, features: Dict, timestamp: Optional[datetime] = None):
        """Store feature snapshot for historical analysis and model training."""
        if timestamp is None:
            timestamp = datetime.now()
        
        key = f"feature_store:{match_id}:{timestamp.strftime('%Y%m%d_%H%M%S')}"
        
        try:
            if self.redis_client:
                await self.redis_client.set(
                    key,
                    json.dumps({
                        "match_id": match_id,
                        "timestamp": timestamp.isoformat(),
                        "features": features
                    }),
                    ex=86400 * 30  # Keep for 30 days
                )
            else:
                self._memory_store[key] = {
                    "match_id": match_id,
                    "timestamp": timestamp.isoformat(),
                    "features": features
                }
        except Exception as e:
            logger.error(f"Failed to store feature snapshot: {e}")
    
    async def get_health_status(self) -> Dict[str, Any]:
        """Get cache health status."""
        try:
            if self.redis_client:
                info = await self.redis_client.info()
                return {
                    "status": "connected",
                    "redis_version": info.get("redis_version", "unknown"),
                    "used_memory_human": info.get("used_memory_human", "unknown"),
                    "connected_clients": info.get("connected_clients", 0)
                }
            else:
                return {
                    "status": "fallback_mode",
                    "memory_entries": len(self._memory_store) if hasattr(self, '_memory_store') else 0
                }
        except Exception as e:
            return {
                "status": "error",
                "error": str(e)
            }


# Singleton instance for easy import
cache = TiannaraRedisCache()
