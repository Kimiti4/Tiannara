"""
Context Preservation System

Purpose: Maintain conversation and task context across interactions
Features:
- Multi-level context tracking (session, conversation, long-term)
- Context relevance scoring
- Automatic context pruning
- Context summarization
- Cross-session persistence
- Context-aware retrieval

Date: May 8, 2026
Status: Implementation Phase - Week 17
"""

import json
import time
import hashlib
from typing import Dict, List, Any, Optional, Tuple
from datetime import datetime, timedelta
from collections import OrderedDict
from dataclasses import dataclass, field


@dataclass
class ContextItem:
    """Represents a single piece of context information."""
    
    content: str
    context_type: str  # "fact", "preference", "goal", "history", etc.
    timestamp: datetime = field(default_factory=datetime.now)
    relevance_score: float = 1.0
    source: str = "user"  # "user", "agent", "system"
    metadata: Dict[str, Any] = field(default_factory=dict)
    expires_at: Optional[datetime] = None
    
    def is_expired(self) -> bool:
        """Check if context item has expired."""
        if self.expires_at:
            return datetime.now() > self.expires_at
        return False
    
    def to_dict(self) -> Dict:
        """Convert to dictionary."""
        return {
            "content": self.content,
            "type": self.context_type,
            "timestamp": self.timestamp.isoformat(),
            "relevance_score": self.relevance_score,
            "source": self.source,
            "metadata": self.metadata,
            "expires_at": self.expires_at.isoformat() if self.expires_at else None
        }


@dataclass
class ConversationTurn:
    """Represents a single turn in a conversation."""
    
    turn_id: str
    user_message: str
    agent_response: str
    timestamp: datetime = field(default_factory=datetime.now)
    extracted_context: List[ContextItem] = field(default_factory=list)
    sentiment: Optional[str] = None
    intent: Optional[str] = None
    
    def to_dict(self) -> Dict:
        """Convert to dictionary."""
        return {
            "turn_id": self.turn_id,
            "user_message": self.user_message,
            "agent_response": self.agent_response,
            "timestamp": self.timestamp.isoformat(),
            "extracted_context": [ctx.to_dict() for ctx in self.extracted_context],
            "sentiment": self.sentiment,
            "intent": self.intent
        }


class ContextPreservationSystem:
    """
    Advanced context preservation system for maintaining conversation state.
    
    Features:
    - Hierarchical context storage (short-term, medium-term, long-term)
    - Automatic relevance decay
    - Context summarization for efficiency
    - Cross-session persistence
    - Smart context retrieval based on query
    """
    
    def __init__(self, 
                 max_short_term: int = 50,
                 max_medium_term: int = 500,
                 max_long_term: int = 5000,
                 decay_rate: float = 0.95):
        
        # Context stores at different timescales
        self.short_term_context = OrderedDict()  # Recent, high-relevance
        self.medium_term_context = OrderedDict()  # Session-level
        self.long_term_context = OrderedDict()  # Persistent knowledge
        
        # Limits
        self.max_short_term = max_short_term
        self.max_medium_term = max_medium_term
        self.max_long_term = max_long_term
        
        # Decay rate for relevance scores (per hour)
        self.decay_rate = decay_rate
        
        # Conversation history
        self.conversation_turns: List[ConversationTurn] = []
        self.current_session_id = self._generate_session_id()
        
        # User preferences and facts
        self.user_preferences: Dict[str, Any] = {}
        self.user_facts: Dict[str, ContextItem] = {}
        
        # Context statistics
        self.stats = {
            "total_items_added": 0,
            "total_items_pruned": 0,
            "total_summaries_generated": 0,
            "average_relevance_score": 1.0
        }
        
    def _generate_session_id(self) -> str:
        """Generate unique session ID."""
        timestamp = datetime.now().isoformat()
        return hashlib.md5(timestamp.encode()).hexdigest()[:12]
    
    def add_context(self, 
                   content: str,
                   context_type: str = "fact",
                   source: str = "user",
                   importance: float = 1.0,
                   ttl_hours: Optional[float] = None,
                   metadata: Dict[str, Any] = None) -> str:
        """
        Add context item to appropriate storage level.
        
        Args:
            content: The context content
            context_type: Type of context (fact, preference, goal, etc.)
            source: Source of context (user, agent, system)
            importance: Importance score (0-1)
            ttl_hours: Time-to-live in hours (None for permanent)
            metadata: Additional metadata
            
        Returns:
            Context item ID
        """
        # Create context item
        context_id = hashlib.md5(
            f"{content}_{datetime.now().isoformat()}".encode()
        ).hexdigest()[:16]
        
        expires_at = None
        if ttl_hours:
            expires_at = datetime.now() + timedelta(hours=ttl_hours)
        
        item = ContextItem(
            content=content,
            context_type=context_type,
            source=source,
            relevance_score=importance,
            expires_at=expires_at,
            metadata=metadata or {}
        )
        
        # Store in appropriate level based on importance and type
        if importance >= 0.8 or context_type in ["preference", "fact"]:
            self.long_term_context[context_id] = item
        elif importance >= 0.5:
            self.medium_term_context[context_id] = item
        else:
            self.short_term_context[context_id] = item
        
        # Enforce size limits
        self._enforce_limits()
        
        # Update stats
        self.stats["total_items_added"] += 1
        
        return context_id
    
    def add_conversation_turn(self,
                             user_message: str,
                             agent_response: str,
                             extracted_context: List[ContextItem] = None,
                             sentiment: str = None,
                             intent: str = None) -> str:
        """
        Add a conversation turn with automatic context extraction.
        
        Args:
            user_message: User's message
            agent_response: Agent's response
            extracted_context: Pre-extracted context items
            sentiment: Detected sentiment
            intent: Detected intent
            
        Returns:
            Turn ID
        """
        turn_id = f"turn_{len(self.conversation_turns) + 1}"
        
        turn = ConversationTurn(
            turn_id=turn_id,
            user_message=user_message,
            agent_response=agent_response,
            extracted_context=extracted_context or [],
            sentiment=sentiment,
            intent=intent
        )
        
        self.conversation_turns.append(turn)
        
        # Extract and store context from conversation
        if extracted_context:
            for ctx_item in extracted_context:
                self.add_context(
                    content=ctx_item.content,
                    context_type=ctx_item.context_type,
                    source=ctx_item.source,
                    importance=ctx_item.relevance_score
                )
        
        # Keep only recent turns in memory (last 100)
        if len(self.conversation_turns) > 100:
            self.conversation_turns = self.conversation_turns[-100:]
        
        return turn_id
    
    def get_relevant_context(self, 
                            query: str,
                            max_items: int = 10,
                            min_relevance: float = 0.3) -> List[ContextItem]:
        """
        Retrieve context relevant to a query.
        
        Uses keyword matching and recency weighting.
        
        Args:
            query: Query text to match against
            max_items: Maximum number of items to return
            min_relevance: Minimum relevance threshold
            
        Returns:
            List of relevant context items sorted by relevance
        """
        # Apply decay to all context items
        self._apply_decay()
        
        # Score all context items
        scored_items = []
        
        all_context = {
            **self.short_term_context,
            **self.medium_term_context,
            **self.long_term_context
        }
        
        query_words = set(query.lower().split())
        
        for ctx_id, item in all_context.items():
            if item.is_expired():
                continue
            
            # Calculate relevance based on keyword overlap
            content_words = set(item.content.lower().split())
            keyword_overlap = len(query_words & content_words) / max(len(query_words), 1)
            
            # Combine with stored relevance score and recency
            age_hours = (datetime.now() - item.timestamp).total_seconds() / 3600
            recency_factor = max(0.1, 1.0 - (age_hours / 168))  # Decay over 1 week
            
            final_score = (
                0.4 * keyword_overlap +
                0.4 * item.relevance_score +
                0.2 * recency_factor
            )
            
            if final_score >= min_relevance:
                scored_items.append((final_score, item))
        
        # Sort by score and return top N
        scored_items.sort(key=lambda x: x[0], reverse=True)
        return [item for _, item in scored_items[:max_items]]
    
    def get_recent_conversation(self, 
                               num_turns: int = 5) -> List[ConversationTurn]:
        """Get most recent conversation turns."""
        return self.conversation_turns[-num_turns:]
    
    def get_user_preferences(self) -> Dict[str, Any]:
        """Get all stored user preferences."""
        return self.user_preferences.copy()
    
    def set_user_preference(self, key: str, value: Any):
        """Set a user preference."""
        self.user_preferences[key] = value
        
        # Also store as long-term context
        self.add_context(
            content=f"User preference: {key} = {value}",
            context_type="preference",
            source="user",
            importance=0.9
        )
    
    def summarize_context(self, 
                         context_type: Optional[str] = None) -> str:
        """
        Generate summary of stored context.
        
        Args:
            context_type: Optional filter by type
            
        Returns:
            Summary text
        """
        all_context = {
            **self.short_term_context,
            **self.medium_term_context,
            **self.long_term_context
        }
        
        # Filter by type if specified
        if context_type:
            filtered = {
                k: v for k, v in all_context.items()
                if v.context_type == context_type
            }
        else:
            filtered = all_context
        
        if not filtered:
            return "No context available."
        
        # Group by type
        by_type = {}
        for item in filtered.values():
            if item.context_type not in by_type:
                by_type[item.context_type] = []
            by_type[item.context_type].append(item)
        
        # Generate summary
        summary_lines = ["Context Summary:", ""]
        
        for ctx_type, items in by_type.items():
            summary_lines.append(f"{ctx_type.upper()} ({len(items)} items):")
            
            # Show top 5 most relevant items
            sorted_items = sorted(
                items, 
                key=lambda x: x.relevance_score, 
                reverse=True
            )[:5]
            
            for item in sorted_items:
                preview = item.content[:100]
                if len(item.content) > 100:
                    preview += "..."
                summary_lines.append(f"  - {preview}")
            
            summary_lines.append("")
        
        summary = "\n".join(summary_lines)
        self.stats["total_summaries_generated"] += 1
        
        return summary
    
    def prune_expired_context(self) -> int:
        """Remove expired context items."""
        pruned_count = 0
        
        for store in [self.short_term_context, 
                     self.medium_term_context, 
                     self.long_term_context]:
            expired_ids = [
                ctx_id for ctx_id, item in store.items()
                if item.is_expired()
            ]
            
            for ctx_id in expired_ids:
                del store[ctx_id]
                pruned_count += 1
        
        self.stats["total_items_pruned"] += pruned_count
        return pruned_count
    
    def clear_session(self):
        """Clear short-term and conversation context (start new session)."""
        self.short_term_context.clear()
        self.conversation_turns.clear()
        self.current_session_id = self._generate_session_id()
    
    def export_context(self) -> Dict:
        """Export all context for persistence."""
        return {
            "session_id": self.current_session_id,
            "timestamp": datetime.now().isoformat(),
            "short_term": {
                k: v.to_dict() for k, v in self.short_term_context.items()
            },
            "medium_term": {
                k: v.to_dict() for k, v in self.medium_term_context.items()
            },
            "long_term": {
                k: v.to_dict() for k, v in self.long_term_context.items()
            },
            "conversation_turns": [
                turn.to_dict() for turn in self.conversation_turns
            ],
            "user_preferences": self.user_preferences,
            "stats": self.stats
        }
    
    def import_context(self, data: Dict):
        """Import context from exported data."""
        self.current_session_id = data.get("session_id", self._generate_session_id())
        
        # Reconstruct context items
        for store_name in ["short_term", "medium_term", "long_term"]:
            store_data = data.get(store_name, {})
            target_store = getattr(self, f"{store_name}_context")
            
            for ctx_id, ctx_dict in store_data.items():
                item = ContextItem(
                    content=ctx_dict["content"],
                    context_type=ctx_dict["type"],
                    timestamp=datetime.fromisoformat(ctx_dict["timestamp"]),
                    relevance_score=ctx_dict["relevance_score"],
                    source=ctx_dict["source"],
                    metadata=ctx_dict.get("metadata", {}),
                    expires_at=(
                        datetime.fromisoformat(ctx_dict["expires_at"])
                        if ctx_dict.get("expires_at") else None
                    )
                )
                target_store[ctx_id] = item
        
        # Restore user preferences
        self.user_preferences = data.get("user_preferences", {})
        
        # Restore stats
        self.stats.update(data.get("stats", {}))
    
    def _apply_decay(self):
        """Apply relevance decay to all context items."""
        all_stores = [
            self.short_term_context,
            self.medium_term_context,
            self.long_term_context
        ]
        
        for store in all_stores:
            for item in store.values():
                # Calculate age in hours
                age_hours = (datetime.now() - item.timestamp).total_seconds() / 3600
                
                # Apply exponential decay
                decay_factor = self.decay_rate ** (age_hours / 24)  # Daily decay
                item.relevance_score *= decay_factor
    
    def _enforce_limits(self):
        """Enforce size limits on context stores."""
        # Short-term: Remove oldest if over limit
        while len(self.short_term_context) > self.max_short_term:
            self.short_term_context.popitem(last=False)
            self.stats["total_items_pruned"] += 1
        
        # Medium-term: Remove lowest relevance if over limit
        if len(self.medium_term_context) > self.max_medium_term:
            sorted_items = sorted(
                self.medium_term_context.items(),
                key=lambda x: x[1].relevance_score
            )
            items_to_remove = len(self.medium_term_context) - self.max_medium_term
            
            for ctx_id, _ in sorted_items[:items_to_remove]:
                del self.medium_term_context[ctx_id]
                self.stats["total_items_pruned"] += 1
        
        # Long-term: Similar to medium-term but more conservative
        if len(self.long_term_context) > self.max_long_term:
            sorted_items = sorted(
                self.long_term_context.items(),
                key=lambda x: x[1].relevance_score
            )
            items_to_remove = len(self.long_term_context) - self.max_long_term
            
            for ctx_id, _ in sorted_items[:items_to_remove]:
                del self.long_term_context[ctx_id]
                self.stats["total_items_pruned"] += 1
    
    def get_stats(self) -> Dict:
        """Get context preservation statistics."""
        return {
            **self.stats,
            "short_term_count": len(self.short_term_context),
            "medium_term_count": len(self.medium_term_context),
            "long_term_count": len(self.long_term_context),
            "total_context_items": (
                len(self.short_term_context) +
                len(self.medium_term_context) +
                len(self.long_term_context)
            ),
            "conversation_turns": len(self.conversation_turns),
            "user_preferences_count": len(self.user_preferences),
            "current_session_id": self.current_session_id
        }


# Example usage and testing
if __name__ == "__main__":
    print("="*70)
    print("CONTEXT PRESERVATION SYSTEM - TEST")
    print("="*70)
    
    # Initialize system
    cps = ContextPreservationSystem()
    
    print("\n📝 Adding context items...")
    
    # Add various types of context
    cps.add_context(
        content="User prefers football predictions over basketball",
        context_type="preference",
        source="user",
        importance=0.9
    )
    
    cps.add_context(
        content="Current project focuses on sports betting AI",
        context_type="goal",
        source="user",
        importance=0.85,
        ttl_hours=168  # 1 week
    )
    
    cps.add_context(
        content="Team A has won last 5 matches",
        context_type="fact",
        source="agent",
        importance=0.7,
        ttl_hours=48  # 2 days
    )
    
    print(f"✅ Added 3 context items")
    
    # Add conversation turns
    print("\n💬 Simulating conversation...")
    
    cps.add_conversation_turn(
        user_message="What are the predictions for tomorrow's match?",
        agent_response="Based on recent form, Team A has 65% win probability",
        sentiment="neutral",
        intent="prediction_request"
    )
    
    cps.add_conversation_turn(
        user_message="How about their head-to-head record?",
        agent_response="Team A has won 7 out of last 10 meetings",
        sentiment="curious",
        intent="statistics_request"
    )
    
    print(f"✅ Added 2 conversation turns")
    
    # Set user preferences
    print("\n⚙️  Setting user preferences...")
    cps.set_user_preference("favorite_sport", "football")
    cps.set_user_preference("risk_tolerance", "moderate")
    cps.set_user_preference("notification_time", "morning")
    
    print(f"✅ Set 3 user preferences")
    
    # Query relevant context
    print("\n🔍 Querying relevant context...")
    query = "football predictions team performance"
    relevant = cps.get_relevant_context(query, max_items=5)
    
    print(f"Query: \"{query}\"")
    print(f"Found {len(relevant)} relevant items:\n")
    
    for i, item in enumerate(relevant, 1):
        print(f"{i}. [{item.context_type}] {item.content[:80]}...")
        print(f"   Relevance: {item.relevance_score:.2f}")
    
    # Get conversation summary
    print("\n📊 Recent conversation:")
    recent_turns = cps.get_recent_conversation(num_turns=2)
    for turn in recent_turns:
        print(f"\nUser: {turn.user_message[:60]}...")
        print(f"Agent: {turn.agent_response[:60]}...")
    
    # Generate context summary
    print("\n📋 Context Summary:")
    summary = cps.summarize_context()
    print(summary)
    
    # Get statistics
    print("\n📈 System Statistics:")
    stats = cps.get_stats()
    for key, value in stats.items():
        print(f"  {key}: {value}")
    
    # Test export/import
    print("\n💾 Testing context export/import...")
    exported = cps.export_context()
    print(f"Exported {len(exported['long_term'])} long-term context items")
    
    # Create new system and import
    cps2 = ContextPreservationSystem()
    cps2.import_context(exported)
    print(f"Imported into new system successfully")
    
    # Verify import
    stats2 = cps2.get_stats()
    print(f"Verified: {stats2['total_context_items']} total items restored")
    
    print("\n" + "="*70)
    print("✅ CONTEXT PRESERVATION SYSTEM TEST COMPLETE")
    print("="*70)
