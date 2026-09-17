"""
Semantic Memory Module

Provides long-term knowledge storage and retrieval for the NLP domain,
enabling persistent conversational cognition across sessions.
"""

from dataclasses import dataclass, field
from typing import List, Dict, Optional, Any
from datetime import datetime
import hashlib


@dataclass
class MemoryNode:
    """Represents a unit of semantic knowledge."""
    node_id: str
    content: str
    category: str
    timestamp: datetime
    importance: float = 0.5  # 0-1 scale
    connections: List[str] = field(default_factory=list)  # IDs of related nodes
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    def to_dict(self) -> dict:
        return {
            'node_id': self.node_id,
            'content': self.content,
            'category': self.category,
            'timestamp': self.timestamp.isoformat(),
            'importance': self.importance,
            'connections': self.connections,
            'metadata': self.metadata
        }


@dataclass
class TemporalIndex:
    """Indexes memories by time for temporal context resolution."""
    date: str  # YYYY-MM-DD
    event_descriptions: List[str] = field(default_factory=list)
    memory_ids: List[str] = field(default_factory=list)
    
    def add_event(self, description: str, memory_id: str):
        self.event_descriptions.append(description)
        self.memory_ids.append(memory_id)


class SemanticMemory:
    """Manages long-term semantic knowledge with temporal indexing."""
    
    def __init__(self, max_capacity: int = 10000):
        self.memories: Dict[str, MemoryNode] = {}
        self.temporal_index: Dict[str, TemporalIndex] = {}
        self.category_index: Dict[str, List[str]] = {}  # category -> [memory_ids]
        self.max_capacity = max_capacity
        self.access_log: Dict[str, int] = {}  # memory_id -> access_count
    
    def store(self, content: str, category: str, 
              metadata: Optional[Dict] = None,
              importance: float = 0.5) -> str:
        """
        Store a semantic memory.
        
        Args:
            content: The knowledge/content to store
            category: Category label (e.g., 'experiment', 'algorithm', 'concept')
            metadata: Additional metadata
            importance: Importance score (0-1)
            
        Returns:
            Memory node ID
        """
        # Generate unique ID
        node_id = hashlib.md5(f"{content}_{datetime.now().isoformat()}".encode()).hexdigest()[:12]
        
        # Create memory node
        now = datetime.now()
        node = MemoryNode(
            node_id=node_id,
            content=content,
            category=category,
            timestamp=now,
            importance=importance,
            metadata=metadata or {}
        )
        
        # Store in memory
        self.memories[node_id] = node
        
        # Update indexes
        self._index_by_category(node_id, category)
        self._index_by_time(node_id, content, now)
        
        # Initialize access log
        self.access_log[node_id] = 0
        
        # Enforce capacity limit
        if len(self.memories) > self.max_capacity:
            self._prune_least_important()
        
        return node_id
    
    def retrieve(self, query: str, category: Optional[str] = None,
                top_k: int = 5) -> List[MemoryNode]:
        """
        Retrieve relevant memories based on query.
        
        Args:
            query: Search query
            category: Optional category filter
            top_k: Number of results to return
            
        Returns:
            List of relevant memory nodes
        """
        candidates = []
        
        # Simple keyword-based retrieval (can be enhanced with embeddings)
        query_words = set(query.lower().split())
        
        for node_id, node in self.memories.items():
            # Apply category filter if specified
            if category and node.category != category:
                continue
            
            # Calculate relevance score
            content_words = set(node.content.lower().split())
            overlap = len(query_words.intersection(content_words))
            
            # Score combines keyword overlap, importance, and recency
            recency_score = self._calculate_recency(node.timestamp)
            access_score = min(self.access_log.get(node_id, 0) / 10.0, 1.0)
            
            relevance = (overlap * 0.4 + 
                        node.importance * 0.3 + 
                        recency_score * 0.2 + 
                        access_score * 0.1)
            
            if relevance > 0:
                candidates.append((node, relevance))
        
        # Sort by relevance and return top_k
        candidates.sort(key=lambda x: x[1], reverse=True)
        result_nodes = [node for node, _ in candidates[:top_k]]
        
        # Update access counts
        for node in result_nodes:
            self.access_log[node.node_id] = self.access_log.get(node.node_id, 0) + 1
        
        return result_nodes
    
    def retrieve_temporal(self, time_reference: str) -> List[MemoryNode]:
        """
        Retrieve memories based on temporal reference.
        
        Args:
            time_reference: Temporal reference like "yesterday", "last week", "third experiment"
            
        Returns:
            List of relevant memory nodes
        """
        # Parse temporal reference
        target_date = self._resolve_temporal_reference(time_reference)
        
        if not target_date:
            return []
        
        # Look up in temporal index
        if target_date in self.temporal_index:
            index = self.temporal_index[target_date]
            return [self.memories[mid] for mid in index.memory_ids if mid in self.memories]
        
        return []
    
    def connect_memories(self, source_id: str, target_id: str):
        """Create a connection between two memories."""
        if source_id in self.memories and target_id in self.memories:
            if target_id not in self.memories[source_id].connections:
                self.memories[source_id].connections.append(target_id)
            if source_id not in self.memories[target_id].connections:
                self.memories[target_id].connections.append(source_id)
    
    def get_related_memories(self, memory_id: str, depth: int = 1) -> List[MemoryNode]:
        """Get memories connected to a given memory."""
        if memory_id not in self.memories:
            return []
        
        related = []
        visited = {memory_id}
        current_level = [memory_id]
        
        for _ in range(depth):
            next_level = []
            for node_id in current_level:
                if node_id in self.memories:
                    node = self.memories[node_id]
                    for conn_id in node.connections:
                        if conn_id not in visited and conn_id in self.memories:
                            related.append(self.memories[conn_id])
                            visited.add(conn_id)
                            next_level.append(conn_id)
            current_level = next_level
        
        return related
    
    def update_importance(self, memory_id: str, new_importance: float):
        """Update the importance score of a memory."""
        if memory_id in self.memories:
            self.memories[memory_id].importance = max(0.0, min(1.0, new_importance))
    
    def forget(self, memory_id: str):
        """Remove a memory from storage."""
        if memory_id in self.memories:
            node = self.memories[memory_id]
            
            # Remove from indexes
            if node.category in self.category_index:
                if memory_id in self.category_index[node.category]:
                    self.category_index[node.category].remove(memory_id)
            
            # Remove from temporal index
            date_str = node.timestamp.strftime('%Y-%m-%d')
            if date_str in self.temporal_index:
                if memory_id in self.temporal_index[date_str].memory_ids:
                    self.temporal_index[date_str].memory_ids.remove(memory_id)
            
            # Remove from memory
            del self.memories[memory_id]
            if memory_id in self.access_log:
                del self.access_log[memory_id]
    
    def get_statistics(self) -> Dict[str, Any]:
        """Get memory system statistics."""
        category_counts = {}
        for cat, ids in self.category_index.items():
            category_counts[cat] = len(ids)
        
        return {
            'total_memories': len(self.memories),
            'capacity': self.max_capacity,
            'utilization': len(self.memories) / self.max_capacity,
            'categories': category_counts,
            'temporal_entries': len(self.temporal_index),
            'avg_importance': sum(n.importance for n in self.memories.values()) / max(len(self.memories), 1)
        }
    
    def _index_by_category(self, memory_id: str, category: str):
        """Index memory by category."""
        if category not in self.category_index:
            self.category_index[category] = []
        self.category_index[category].append(memory_id)
    
    def _index_by_time(self, memory_id: str, content: str, timestamp: datetime):
        """Index memory by timestamp."""
        date_str = timestamp.strftime('%Y-%m-%d')
        
        if date_str not in self.temporal_index:
            self.temporal_index[date_str] = TemporalIndex(date=date_str)
        
        self.temporal_index[date_str].add_event(content[:100], memory_id)
    
    def _calculate_recency(self, timestamp: datetime) -> float:
        """Calculate recency score (0-1, where 1 is most recent)."""
        now = datetime.now()
        age_hours = (now - timestamp).total_seconds() / 3600
        
        # Exponential decay: half-life of 24 hours
        recency = 2 ** (-age_hours / 24)
        return max(0.0, min(1.0, recency))
    
    def _resolve_temporal_reference(self, reference: str) -> Optional[str]:
        """Resolve temporal reference to a date string."""
        now = datetime.now()
        reference_lower = reference.lower()
        
        if 'yesterday' in reference_lower:
            from datetime import timedelta
            target = now - timedelta(days=1)
            return target.strftime('%Y-%m-%d')
        
        elif 'today' in reference_lower:
            return now.strftime('%Y-%m-%d')
        
        elif 'last week' in reference_lower:
            from datetime import timedelta
            target = now - timedelta(days=7)
            return target.strftime('%Y-%m-%d')
        
        elif 'third' in reference_lower or '3rd' in reference_lower:
            # This would need more sophisticated tracking
            # For now, return None (not implemented)
            return None
        
        return None
    
    def _prune_least_important(self):
        """Remove least important memories when at capacity."""
        if len(self.memories) <= self.max_capacity:
            return
        
        # Find least important memories
        sorted_memories = sorted(
            self.memories.items(),
            key=lambda x: x[1].importance
        )
        
        # Remove bottom 10%
        num_to_remove = max(1, len(self.memories) // 10)
        for memory_id, _ in sorted_memories[:num_to_remove]:
            self.forget(memory_id)
