"""
Variant Object Pool for Memory-Efficient Evolution.

Implements object pooling to reduce closure accumulation and memory growth.
Instead of creating new closures for each episode, we reuse variant objects
from a bounded pool.

This addresses the Python closure memory leak identified in load testing.
"""

import gc
from typing import Callable, Dict, Any, Optional
from dataclasses import dataclass, field


@dataclass
class PooledVariant:
    """
    Reusable variant wrapper that can be reconfigured.
    
    Instead of creating new closures, we reconfigure existing objects.
    This allows Python's GC to reclaim memory more effectively.
    """
    id: int
    evolver_ref: Any = None  # Reference to evolver (weak reference could be used)
    task_data: Dict[str, Any] = field(default_factory=dict)
    episode: int = 0
    variant_func: Optional[Callable] = None
    is_active: bool = False
    
    def configure(self, evolver, task: Dict[str, Any], episode: int):
        """
        Reconfigure this pooled variant with new task/episode.
        
        Args:
            evolver: The evolver instance
            task: Task definition
            episode: Episode number
        """
        self.evolver_ref = evolver
        self.task_data = task.copy()  # Shallow copy to avoid mutation
        self.episode = episode
        self.is_active = True
        
        # Create fresh variant function
        self.variant_func = evolver._create_variant_internal(task, episode)
    
    def execute(self, inputs: Dict[str, Any]) -> Any:
        """Execute the variant with given inputs."""
        if not self.is_active or self.variant_func is None:
            raise RuntimeError("Variant not configured or inactive")
        
        try:
            return self.variant_func(**inputs)
        except Exception as e:
            raise e
    
    def release(self):
        """Release this variant back to the pool."""
        self.is_active = False
        self.variant_func = None  # Allow GC to collect closure
        self.task_data.clear()
        self.evolver_ref = None


class VariantPool:
    """
    Object pool for variant functions to reduce memory allocation.
    
    Instead of creating new closures for each episode, we:
    1. Maintain a bounded pool of PooledVariant objects
    2. Reconfigure them with new tasks/episodes
    3. Release them after use to allow GC
    
    This significantly reduces memory growth from closure accumulation.
    """
    
    def __init__(self, max_size: int = 50, enable_gc: bool = True):
        """
        Initialize variant pool.
        
        Args:
            max_size: Maximum number of pooled variants
            enable_gc: Whether to force GC after releasing variants
        """
        self.max_size = max_size
        self.enable_gc = enable_gc
        
        # Pool of available variants
        self.available: list[PooledVariant] = []
        
        # Active variants (checked out)
        self.active: dict[int, PooledVariant] = {}
        
        # Statistics
        self.total_created = 0
        self.total_reused = 0
        self.total_released = 0
        self.current_pool_size = 0
    
    def get_variant(self, evolver, task: Dict[str, Any], episode: int) -> PooledVariant:
        """
        Get a variant from the pool or create new one.
        
        Args:
            evolver: The evolver instance
            task: Task definition
            episode: Episode number
            
        Returns:
            Configured PooledVariant ready for execution
        """
        if self.available:
            # Reuse existing variant from pool
            variant = self.available.pop()
            variant.configure(evolver, task, episode)
            self.total_reused += 1
        else:
            # Create new variant
            self.total_created += 1
            variant = PooledVariant(id=self.total_created)
            variant.configure(evolver, task, episode)
            
            # Track pool size
            self.current_pool_size += 1
        
        # Mark as active
        self.active[variant.id] = variant
        
        return variant
    
    def release_variant(self, variant: PooledVariant):
        """
        Release variant back to the pool.
        
        Args:
            variant: The variant to release
        """
        if variant.id in self.active:
            del self.active[variant.id]
        
        # Release the variant
        variant.release()
        self.total_released += 1
        
        # Return to pool if not at capacity
        if len(self.available) < self.max_size:
            self.available.append(variant)
        else:
            # Pool is full, let GC collect this variant
            self.current_pool_size -= 1
        
        # Force garbage collection periodically
        if self.enable_gc and self.total_released % 10 == 0:
            gc.collect()
    
    def get_statistics(self) -> Dict[str, Any]:
        """Get pool statistics."""
        return {
            "pool_size": len(self.available),
            "active_variants": len(self.active),
            "total_created": self.total_created,
            "total_reused": self.total_reused,
            "total_released": self.total_released,
            "reuse_rate": (
                self.total_reused / (self.total_created + self.total_reused)
                if (self.total_created + self.total_reused) > 0 else 0
            )
        }
    
    def cleanup(self):
        """Force cleanup of all pooled variants."""
        # Release all active variants
        for variant in list(self.active.values()):
            variant.release()
        self.active.clear()
        
        # Clear available pool
        self.available.clear()
        self.current_pool_size = 0
        
        # Force garbage collection
        if self.enable_gc:
            gc.collect()


class EvolverWithPooling:
    """
    Mixin class to add variant pooling to any evolver.
    
    Usage:
        class MyEvolver(EvolverWithPooling, BaseEvolver):
            pass
    """
    
    def __init__(self, *args, pool_size: int = 50, **kwargs):
        """Initialize with variant pool."""
        super().__init__(*args, **kwargs)
        self.variant_pool = VariantPool(max_size=pool_size)
    
    def create_variant_pooled(self, task: Dict[str, Any], episode: int, 
                              external_skills: list = None) -> PooledVariant:
        """
        Create variant using object pool.
        
        Args:
            task: Task definition
            episode: Episode number
            external_skills: Optional external skills
            
        Returns:
            PooledVariant ready for execution
        """
        return self.variant_pool.get_variant(self, task, episode)
    
    def release_variant(self, variant: PooledVariant):
        """Release variant back to pool after use."""
        self.variant_pool.release_variant(variant)
    
    def get_pool_stats(self) -> Dict[str, Any]:
        """Get variant pool statistics."""
        return self.variant_pool.get_statistics()
