"""
Memory Store Module

Provides unified interface for memory operations.
"""

from typing import Dict, Any, List, Optional
from .knowledge_store import KnowledgeStore


class MemoryStore:
    """Unified memory store interface."""
    
    def __init__(self):
        self.knowledge_store = KnowledgeStore()
    
    def store(self, key: str, value: Any, metadata: Optional[Dict[str, Any]] = None) -> bool:
        """Store a value in memory.
        
        Args:
            key: Unique identifier
            value: Value to store
            metadata: Optional metadata
            
        Returns:
            True if successful
        """
        return self.knowledge_store.store(key, value, metadata or {})
    
    def retrieve(self, key: str) -> Optional[Any]:
        """Retrieve a value from memory.
        
        Args:
            key: Unique identifier
            
        Returns:
            Stored value or None
        """
        return self.knowledge_store.retrieve(key)
    
    def search(self, query: str, limit: int = 10) -> List[Dict[str, Any]]:
        """Search memory for relevant items.
        
        Args:
            query: Search query
            limit: Maximum results
            
        Returns:
            List of matching items
        """
        return self.knowledge_store.search(query, limit)
    
    def delete(self, key: str) -> bool:
        """Delete an item from memory.
        
        Args:
            key: Unique identifier
            
        Returns:
            True if deleted
        """
        return self.knowledge_store.delete(key)
    
    def clear(self) -> bool:
        """Clear all memory.
        
        Returns:
            True if cleared
        """
        return self.knowledge_store.clear()
    
    def get_stats(self) -> Dict[str, Any]:
        """Get memory statistics.
        
        Returns:
            Dictionary with stats
        """
        return self.knowledge_store.get_stats()


__all__ = ["MemoryStore"]
