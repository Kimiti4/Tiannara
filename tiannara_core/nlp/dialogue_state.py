"""
Dialogue State Manager for NLP Domain

Maintains persistent conversational state across multiple turns,
tracking context, entities, and user intent.
"""

from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass, field
from datetime import datetime


@dataclass
class DialogueTurn:
    """Represents a single turn in a conversation."""
    turn_id: str
    timestamp: datetime
    speaker: str  # 'user' or 'assistant'
    message: str
    intent: Optional[str] = None
    entities: Dict[str, Any] = field(default_factory=dict)
    context_references: List[str] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    def to_dict(self):
        return {
            'turn_id': self.turn_id,
            'timestamp': self.timestamp.isoformat(),
            'speaker': self.speaker,
            'message': self.message,
            'intent': self.intent,
            'entities': self.entities
        }


@dataclass
class ConversationContext:
    """Maintains context for an ongoing conversation."""
    session_id: str
    user_id: str
    turns: List[DialogueTurn] = field(default_factory=list)
    active_entities: Dict[str, Any] = field(default_factory=dict)
    topic_history: List[str] = field(default_factory=list)
    unresolved_references: List[Tuple[str, str]] = field(default_factory=list)  # (reference, target)
    
    def add_turn(self, turn: DialogueTurn):
        """Add a new turn to the conversation."""
        self.turns.append(turn)
        
        # Update active entities
        for entity_name, entity_value in turn.entities.items():
            self.active_entities[entity_name] = entity_value
        
        # Track topic changes
        if turn.metadata.get('topic'):
            self.topic_history.append(turn.metadata['topic'])
    
    def get_recent_turns(self, n: int = 5) -> List[DialogueTurn]:
        """Get the most recent n turns."""
        return self.turns[-n:]
    
    def get_context_summary(self) -> Dict[str, Any]:
        """Get a summary of current conversation context."""
        return {
            'session_id': self.session_id,
            'num_turns': len(self.turns),
            'active_entities': self.active_entities,
            'recent_topics': self.topic_history[-3:] if self.topic_history else [],
            'last_message': self.turns[-1].message if self.turns else None
        }
    
    def resolve_reference(self, reference: str) -> Optional[Any]:
        """Resolve a pronoun or reference to an entity."""
        # Simple resolution - would use coreference resolution in production
        pronoun_map = {
            'it': self.active_entities.get('last_object'),
            'this': self.active_entities.get('current_topic'),
            'that': self.active_entities.get('previous_topic'),
            'he': self.active_entities.get('male_person'),
            'she': self.active_entities.get('female_person'),
            'they': self.active_entities.get('group')
        }
        return pronoun_map.get(reference.lower())
    
    def to_dict(self):
        return {
            'session_id': self.session_id,
            'user_id': self.user_id,
            'num_turns': len(self.turns),
            'active_entities': self.active_entities,
            'context_summary': self.get_context_summary()
        }


class DialogueStateManager:
    """
    Manages dialogue state across multiple conversations and users.
    
    Provides:
    - Session management
    - Context persistence
    - Reference resolution
    - Turn tracking
    """
    
    def __init__(self):
        self.sessions: Dict[str, ConversationContext] = {}
        self._turn_counter = 0
    
    def create_session(self, session_id: str, user_id: str) -> ConversationContext:
        """Create a new conversation session."""
        context = ConversationContext(
            session_id=session_id,
            user_id=user_id
        )
        self.sessions[session_id] = context
        return context
    
    def get_session(self, session_id: str) -> Optional[ConversationContext]:
        """Retrieve an existing conversation session."""
        return self.sessions.get(session_id)
    
    def add_user_turn(self, session_id: str, message: str, 
                     intent: Optional[str] = None,
                     entities: Optional[Dict] = None) -> DialogueTurn:
        """Add a user message turn."""
        context = self.get_session(session_id)
        if not context:
            raise ValueError(f"Session not found: {session_id}")
        
        self._turn_counter += 1
        turn = DialogueTurn(
            turn_id=f"turn_{self._turn_counter}",
            timestamp=datetime.now(),
            speaker='user',
            message=message,
            intent=intent,
            entities=entities or {}
        )
        
        context.add_turn(turn)
        return turn
    
    def add_assistant_turn(self, session_id: str, message: str,
                          metadata: Optional[Dict] = None) -> DialogueTurn:
        """Add an assistant response turn."""
        context = self.get_session(session_id)
        if not context:
            raise ValueError(f"Session not found: {session_id}")
        
        self._turn_counter += 1
        turn = DialogueTurn(
            turn_id=f"turn_{self._turn_counter}",
            timestamp=datetime.now(),
            speaker='assistant',
            message=message,
            metadata=metadata or {}
        )
        
        context.add_turn(turn)
        return turn
    
    def resolve_context_reference(self, session_id: str, reference: str) -> Optional[Any]:
        """Resolve a contextual reference (pronoun, etc.) in a session."""
        context = self.get_session(session_id)
        if not context:
            return None
        
        return context.resolve_reference(reference)
    
    def get_conversation_history(self, session_id: str, 
                                max_turns: int = 10) -> List[Dict]:
        """Get conversation history for a session."""
        context = self.get_session(session_id)
        if not context:
            return []
        
        recent_turns = context.get_recent_turns(max_turns)
        return [turn.to_dict() for turn in recent_turns]
    
    def close_session(self, session_id: str):
        """Close and archive a conversation session."""
        if session_id in self.sessions:
            del self.sessions[session_id]
    
    def get_active_sessions(self, user_id: str) -> List[str]:
        """Get all active sessions for a user."""
        return [
            sid for sid, ctx in self.sessions.items()
            if ctx.user_id == user_id
        ]
    
    def clear_all_sessions(self):
        """Clear all active sessions."""
        self.sessions.clear()
        self._turn_counter = 0


if __name__ == "__main__":
    # Example usage
    manager = DialogueStateManager()
    
    # Create session
    session = manager.create_session("session_1", "user_123")
    
    # Add turns
    manager.add_user_turn(
        "session_1",
        "I'm building Tiannara AI system",
        intent="statement",
        entities={'project': 'Tiannara', 'domain': 'AI architecture'}
    )
    
    manager.add_assistant_turn(
        "session_1",
        "That sounds interesting! What aspects are you working on?",
        metadata={'topic': 'project_discussion'}
    )
    
    # Resolve reference
    resolved = manager.resolve_context_reference("session_1", "it")
    print(f"Resolved 'it': {resolved}")
    
    # Get history
    history = manager.get_conversation_history("session_1")
    print(f"\nConversation history ({len(history)} turns):")
    for turn in history:
        print(f"  {turn['speaker']}: {turn['message']}")
