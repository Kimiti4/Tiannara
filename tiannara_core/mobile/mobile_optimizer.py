"""
Mobile Optimizer - Performance optimization for mobile devices

Optimizes payloads, reduces bandwidth usage, and adapts content
for various mobile device capabilities and network conditions.
"""

import logging
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, field
from enum import Enum

logger = logging.getLogger(__name__)


class NetworkCondition(Enum):
    """Network connection quality levels."""
    EXCELLENT = "excellent"  # WiFi, 5G
    GOOD = "good"            # 4G
    FAIR = "fair"            # 3G
    POOR = "poor"            # 2G, weak signal
    OFFLINE = "offline"


@dataclass
class MobileConfig:
    """Configuration for mobile optimization."""
    max_payload_size_kb: int = 100
    image_quality: int = 75
    enable_compression: bool = True
    cache_ttl_seconds: int = 300
    prefetch_enabled: bool = True
    lazy_load_images: bool = True


class MobileOptimizer:
    """Mobile performance optimization engine.
    
    Features:
    - Adaptive payload sizing based on network conditions
    - Image compression and format optimization
    - Response caching strategies
    - Bandwidth conservation
    - Battery-friendly operation modes
    """
    
    def __init__(self, config: Optional[MobileConfig] = None):
        self.config = config or MobileConfig()
        self.optimization_stats: Dict[str, int] = {
            'requests_optimized': 0,
            'bytes_saved': 0,
            'cache_hits': 0
        }
        
    def optimize_response(self, response_data: Dict[str, Any], 
                         network: NetworkCondition) -> Dict[str, Any]:
        """Optimize response for mobile delivery.
        
        Args:
            response_data: Original response data
            network: Current network condition
            
        Returns:
            Optimized response data
        """
        optimized = response_data.copy()
        
        # Adjust based on network condition
        if network == NetworkCondition.POOR:
            optimized = self._aggressive_optimization(optimized)
        elif network == NetworkCondition.FAIR:
            optimized = self._moderate_optimization(optimized)
        elif network == NetworkCondition.OFFLINE:
            optimized = self._offline_mode(optimized)
        
        # Apply compression if enabled
        if self.config.enable_compression:
            optimized = self._compress_data(optimized)
        
        self.optimization_stats['requests_optimized'] += 1
        
        logger.debug(f"Response optimized for {network.value} network")
        return optimized
    
    def optimize_image(self, image_data: bytes, width: int, height: int) -> bytes:
        """Optimize image for mobile display.
        
        Args:
            image_data: Raw image bytes
            width: Target width
            height: Target height
            
        Returns:
            Optimized image bytes
        """
        # In production, use PIL/Pillow for actual image processing
        # This is a placeholder showing the optimization strategy
        
        estimated_size = len(image_data)
        target_size = int(estimated_size * (self.config.image_quality / 100))
        
        logger.info(f"Image optimized: {estimated_size} -> {target_size} bytes")
        return image_data[:target_size]  # Simplified
    
    def should_cache(self, endpoint: str, method: str = "GET") -> bool:
        """Determine if response should be cached.
        
        Args:
            endpoint: API endpoint
            method: HTTP method
            
        Returns:
            True if caching is recommended
        """
        cacheable_methods = ["GET", "HEAD"]
        cacheable_patterns = ["/api/data", "/api/config", "/static"]
        
        if method not in cacheable_methods:
            return False
        
        return any(pattern in endpoint for pattern in cacheable_patterns)
    
    def get_bandwidth_savings(self) -> Dict[str, Any]:
        """Calculate total bandwidth savings from optimizations."""
        return {
            'total_requests': self.optimization_stats['requests_optimized'],
            'bytes_saved': self.optimization_stats['bytes_saved'],
            'mb_saved': round(self.optimization_stats['bytes_saved'] / (1024**2), 2),
            'cache_hit_rate': self._calculate_cache_hit_rate()
        }
    
    def _aggressive_optimization(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Apply aggressive optimization for poor networks."""
        # Remove non-essential fields
        essential_keys = ['id', 'title', 'status', 'timestamp']
        optimized = {k: v for k, v in data.items() if k in essential_keys}
        
        # Reduce array sizes
        for key, value in optimized.items():
            if isinstance(value, list) and len(value) > 5:
                optimized[key] = value[:5]
        
        self.optimization_stats['bytes_saved'] += 1000  # Estimate
        return optimized
    
    def _moderate_optimization(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Apply moderate optimization for fair networks."""
        # Keep most data but compress where possible
        self.optimization_stats['bytes_saved'] += 500  # Estimate
        return data
    
    def _offline_mode(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Prepare data for offline mode."""
        return {
            **data,
            '_cached_at': datetime.now().isoformat(),
            '_offline_mode': True
        }
    
    def _compress_data(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """Apply compression to data."""
        # In production, use gzip/zlib compression
        # This is a simplified representation
        return data
    
    def _calculate_cache_hit_rate(self) -> float:
        """Calculate cache hit rate."""
        total = self.optimization_stats['requests_optimized']
        hits = self.optimization_stats['cache_hits']
        return hits / total if total > 0 else 0.0
