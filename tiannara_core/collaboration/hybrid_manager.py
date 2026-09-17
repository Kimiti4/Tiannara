"""
Hybrid Collaboration Manager

Purpose: Enable seamless human-AI collaborative workflows
Features:
- Task handoff mechanisms (human ↔ AI)
- Shared workspace management
- Role assignment (human leads vs AI leads)
- Conflict resolution between human and AI decisions
- Multiple collaboration modes (AI-assisted, supervised, collaborative, autonomous)
- Communication layer with natural language support
- Progress transparency and decision explanation
- Real-time collaboration indicators

Date: May 8, 2026
Status: Implementation Phase - Week 21 Day 3-5
"""

import time
import uuid
from typing import Dict, List, Optional, Tuple, Callable, Any
from datetime import datetime
from enum import Enum
from dataclasses import dataclass, field


class CollaborationMode(Enum):
    """Modes of human-AI collaboration."""
    AI_ASSISTED = "ai_assisted"           # Human leads, AI assists
    HUMAN_SUPERVISED = "human_supervised" # AI leads, human oversees
    COLLABORATIVE = "collaborative"       # Equal partnership
    AUTONOMOUS = "autonomous"             # AI leads, human reviews periodically


class Role(Enum):
    """Roles in collaboration."""
    HUMAN_LEAD = "human_lead"
    AI_LEAD = "ai_lead"
    HUMAN_REVIEWER = "human_reviewer"
    AI_EXECUTOR = "ai_executor"
    CO_EQUAL = "co_equal"


class HandoffDirection(Enum):
    """Direction of task handoff."""
    HUMAN_TO_AI = "human_to_ai"
    AI_TO_HUMAN = "ai_to_human"


@dataclass
class Collaborator:
    """Represents a participant in collaboration (human or AI)."""
    
    collaborator_id: str
    name: str
    collaborator_type: str  # "human" or "ai"
    expertise_areas: List[str] = field(default_factory=list)
    availability: bool = True
    current_task: Optional[str] = None
    metadata: Dict[str, any] = field(default_factory=dict)
    
    def to_dict(self) -> Dict:
        return {
            "id": self.collaborator_id,
            "name": self.name,
            "type": self.collaborator_type,
            "expertise": self.expertise_areas,
            "available": self.availability
        }


@dataclass
class SharedWorkspace:
    """Shared workspace for collaborative work."""
    
    workspace_id: str
    session_id: str
    created_at: datetime = field(default_factory=datetime.now)
    
    # Workspace content
    artifacts: Dict[str, any] = field(default_factory=dict)
    discussion_log: List[Dict] = field(default_factory=list)
    decisions: List[Dict] = field(default_factory=list)
    
    # Access control
    active_collaborators: List[str] = field(default_factory=list)
    permissions: Dict[str, str] = field(default_factory=dict)  # collaborator_id -> permission level
    
    # State
    is_locked: bool = False
    locked_by: Optional[str] = None
    
    def add_artifact(self, name: str, content: any, author_id: str):
        """Add artifact to workspace."""
        self.artifacts[name] = {
            "content": content,
            "author": author_id,
            "timestamp": datetime.now().isoformat()
        }
    
    def log_discussion(self, speaker_id: str, message: str, context: str = ""):
        """Log discussion message."""
        self.discussion_log.append({
            "speaker": speaker_id,
            "message": message,
            "context": context,
            "timestamp": datetime.now().isoformat()
        })
    
    def record_decision(self, decision: str, rationale: str, agreed_by: List[str]):
        """Record collaborative decision."""
        self.decisions.append({
            "decision": decision,
            "rationale": rationale,
            "agreed_by": agreed_by,
            "timestamp": datetime.now().isoformat()
        })
    
    def lock(self, collaborator_id: str):
        """Lock workspace for exclusive editing."""
        self.is_locked = True
        self.locked_by = collaborator_id
    
    def unlock(self):
        """Unlock workspace."""
        self.is_locked = False
        self.locked_by = None
    
    def to_dict(self) -> Dict:
        return {
            "workspace_id": self.workspace_id,
            "session_id": self.session_id,
            "artifacts_count": len(self.artifacts),
            "discussion_entries": len(self.discussion_log),
            "decisions_count": len(self.decisions),
            "active_collaborators": self.active_collaborators,
            "is_locked": self.is_locked
        }


@dataclass
class CollaborationSession:
    """Represents an active collaboration session."""
    
    session_id: str
    task_description: str
    mode: CollaborationMode
    created_at: datetime = field(default_factory=datetime.now)
    
    # Participants
    human_collaborator: Optional[Collaborator] = None
    ai_collaborator: Optional[Collaborator] = None
    current_role: Role = Role.CO_EQUAL
    
    # Workspace
    workspace: Optional[SharedWorkspace] = None
    
    # State
    status: str = "active"  # active, paused, completed, terminated
    current_phase: str = "initialization"
    
    # Handoff tracking
    handoff_history: List[Dict] = field(default_factory=list)
    
    # Performance
    start_time: Optional[datetime] = None
    completion_time: Optional[datetime] = None
    
    def to_dict(self) -> Dict:
        return {
            "session_id": self.session_id,
            "task": self.task_description,
            "mode": self.mode.value,
            "status": self.status,
            "current_phase": self.current_phase,
            "human": self.human_collaborator.to_dict() if self.human_collaborator else None,
            "ai": self.ai_collaborator.to_dict() if self.ai_collaborator else None,
            "handoffs": len(self.handoff_history),
            "duration_seconds": (
                (self.completion_time or datetime.now() - self.start_time or datetime.now()).total_seconds()
                if self.start_time else 0
            )
        }


@dataclass
class HandoffRequest:
    """Request to transfer task responsibility."""
    
    request_id: str
    session_id: str
    from_collaborator: str
    to_collaborator: str
    direction: HandoffDirection
    reason: str
    context: Dict[str, any] = field(default_factory=dict)
    timestamp: datetime = field(default_factory=datetime.now)
    approved: bool = False
    completed: bool = False
    
    def to_dict(self) -> Dict:
        return {
            "request_id": self.request_id,
            "session_id": self.session_id,
            "from": self.from_collaborator,
            "to": self.to_collaborator,
            "direction": self.direction.value,
            "reason": self.reason,
            "approved": self.approved,
            "completed": self.completed
        }


class HybridCollaborationManager:
    """
    Manages hybrid human-AI collaboration workflows.
    
    Features:
    - Session management for collaborative tasks
    - Task handoff between human and AI
    - Shared workspace coordination
    - Role assignment and switching
    - Conflict resolution
    - Mode selection and adaptation
    - Progress tracking and transparency
    """
    
    def __init__(self):
        # Active sessions
        self.sessions: Dict[str, CollaborationSession] = {}
        
        # Registered collaborators
        self.collaborators: Dict[str, Collaborator] = {}
        
        # Handoff requests
        self.handoff_requests: Dict[str, HandoffRequest] = {}
        
        # Workspaces
        self.workspaces: Dict[str, SharedWorkspace] = {}
        
        # Collaboration patterns (for learning)
        self.collaboration_patterns: List[Dict] = []
        
        # Statistics
        self.stats = {
            "total_sessions": 0,
            "completed_sessions": 0,
            "total_handoffs": 0,
            "successful_handoffs": 0,
            "avg_session_duration_seconds": 0.0,
            "sessions_by_mode": {},
            "conflicts_resolved": 0
        }
    
    def register_collaborator(self, collaborator: Collaborator):
        """Register a collaborator (human or AI)."""
        self.collaborators[collaborator.collaborator_id] = collaborator
    
    def initiate_collaboration(self,
                              task_description: str,
                              human_id: str,
                              ai_id: str,
                              mode: CollaborationMode = CollaborationMode.COLLABORATIVE) -> CollaborationSession:
        """
        Initiate a new collaboration session.
        
        Args:
            task_description: Description of collaborative task
            human_id: ID of human collaborator
            ai_id: ID of AI collaborator
            mode: Collaboration mode
            
        Returns:
            Created CollaborationSession
        """
        if human_id not in self.collaborators or ai_id not in self.collaborators:
            raise ValueError("Both collaborators must be registered")
        
        # Create session
        session_id = f"session_{int(time.time())}_{len(self.sessions)}"
        
        human = self.collaborators[human_id]
        ai = self.collaborators[ai_id]
        
        # Determine initial roles based on mode
        initial_role = self._determine_initial_role(mode)
        
        session = CollaborationSession(
            session_id=session_id,
            task_description=task_description,
            mode=mode,
            human_collaborator=human,
            ai_collaborator=ai,
            current_role=initial_role,
            start_time=datetime.now()
        )
        
        # Create shared workspace
        workspace = SharedWorkspace(
            workspace_id=f"workspace_{session_id}",
            session_id=session_id
        )
        workspace.active_collaborators = [human_id, ai_id]
        
        session.workspace = workspace
        self.workspaces[workspace.workspace_id] = workspace
        
        # Store session
        self.sessions[session_id] = session
        self.stats["total_sessions"] += 1
        
        # Update mode statistics
        mode_key = mode.value
        self.stats["sessions_by_mode"][mode_key] = self.stats["sessions_by_mode"].get(mode_key, 0) + 1
        
        # Mark collaborators as busy
        human.current_task = session_id
        ai.current_task = session_id
        human.availability = False
        ai.availability = False
        
        return session
    
    def request_handoff(self,
                       session_id: str,
                       from_collaborator_id: str,
                       to_collaborator_id: str,
                       reason: str,
                       context: Dict[str, any] = None) -> HandoffRequest:
        """
        Request task handoff between collaborators.
        
        Args:
            session_id: Active session ID
            from_collaborator_id: Current task owner
            to_collaborator_id: Next task owner
            reason: Reason for handoff
            context: Additional context
            
        Returns:
            HandoffRequest object
        """
        if session_id not in self.sessions:
            raise ValueError(f"Session {session_id} not found")
        
        session = self.sessions[session_id]
        
        # Determine direction
        if session.human_collaborator.collaborator_id == from_collaborator_id:
            direction = HandoffDirection.HUMAN_TO_AI
        else:
            direction = HandoffDirection.AI_TO_HUMAN
        
        # Create handoff request
        request_id = f"handoff_{int(time.time())}_{len(self.handoff_requests)}"
        
        request = HandoffRequest(
            request_id=request_id,
            session_id=session_id,
            from_collaborator=from_collaborator_id,
            to_collaborator=to_collaborator_id,
            direction=direction,
            reason=reason,
            context=context or {}
        )
        
        self.handoff_requests[request_id] = request
        self.stats["total_handoffs"] += 1
        
        return request
    
    def approve_handoff(self, request_id: str) -> bool:
        """Approve a handoff request."""
        if request_id not in self.handoff_requests:
            return False
        
        request = self.handoff_requests[request_id]
        request.approved = True
        
        return True
    
    def execute_handoff(self, request_id: str) -> bool:
        """
        Execute an approved handoff.
        
        Returns:
            True if successful
        """
        if request_id not in self.handoff_requests:
            return False
        
        request = self.handoff_requests[request_id]
        
        if not request.approved:
            raise ValueError("Handoff must be approved before execution")
        
        if request.completed:
            return True  # Already completed
        
        # Update session state
        session = self.sessions.get(request.session_id)
        if not session:
            return False
        
        # Record handoff in history
        session.handoff_history.append({
            "from": request.from_collaborator,
            "to": request.to_collaborator,
            "reason": request.reason,
            "timestamp": datetime.now().isoformat()
        })
        
        # Update current role
        if request.direction == HandoffDirection.HUMAN_TO_AI:
            session.current_role = Role.AI_LEAD
        else:
            session.current_role = Role.HUMAN_LEAD
        
        # Mark request as completed
        request.completed = True
        self.stats["successful_handoffs"] += 1
        
        # Log in workspace
        if session.workspace:
            session.workspace.log_discussion(
                "system",
                f"Handoff executed: {request.from_collaborator} → {request.to_collaborator}",
                context=request.reason
            )
        
        return True
    
    def create_workspace_artifact(self,
                                 workspace_id: str,
                                 artifact_name: str,
                                 content: any,
                                 author_id: str):
        """Create artifact in shared workspace."""
        if workspace_id not in self.workspaces:
            raise ValueError(f"Workspace {workspace_id} not found")
        
        workspace = self.workspaces[workspace_id]
        
        if workspace.is_locked and workspace.locked_by != author_id:
            raise PermissionError(f"Workspace locked by {workspace.locked_by}")
        
        workspace.add_artifact(artifact_name, content, author_id)
    
    def resolve_conflict(self,
                        session_id: str,
                        human_decision: any,
                        ai_decision: any,
                        resolution_strategy: str = "human_override") -> Dict:
        """
        Resolve conflict between human and AI decisions.
        
        Args:
            session_id: Active session
            human_decision: Human's decision
            ai_decision: AI's decision
            resolution_strategy: How to resolve ("human_override", "ai_override", "compromise", "discussion")
            
        Returns:
            Resolution result
        """
        if session_id not in self.sessions:
            raise ValueError(f"Session {session_id} not found")
        
        session = self.sessions[session_id]
        
        resolution = {
            "session_id": session_id,
            "human_decision": human_decision,
            "ai_decision": ai_decision,
            "strategy": resolution_strategy,
            "final_decision": None,
            "rationale": ""
        }
        
        if resolution_strategy == "human_override":
            resolution["final_decision"] = human_decision
            resolution["rationale"] = "Human decision takes precedence"
        elif resolution_strategy == "ai_override":
            resolution["final_decision"] = ai_decision
            resolution["rationale"] = "AI decision selected based on confidence"
        elif resolution_strategy == "compromise":
            # Simple averaging for numeric decisions, otherwise prefer human
            if isinstance(human_decision, (int, float)) and isinstance(ai_decision, (int, float)):
                resolution["final_decision"] = (human_decision + ai_decision) / 2
                resolution["rationale"] = "Compromise: average of both decisions"
            else:
                resolution["final_decision"] = human_decision
                resolution["rationale"] = "Compromise: human decision preferred for non-numeric"
        elif resolution_strategy == "discussion":
            resolution["final_decision"] = None
            resolution["rationale"] = "Further discussion needed"
        
        # Record decision in workspace
        if session.workspace and resolution["final_decision"] is not None:
            session.workspace.record_decision(
                decision=str(resolution["final_decision"]),
                rationale=resolution["rationale"],
                agreed_by=[session.human_collaborator.collaborator_id, session.ai_collaborator.collaborator_id]
            )
        
        self.stats["conflicts_resolved"] += 1
        
        return resolution
    
    def complete_session(self, session_id: str, outcome: str = "success"):
        """Mark collaboration session as completed."""
        if session_id not in self.sessions:
            raise ValueError(f"Session {session_id} not found")
        
        session = self.sessions[session_id]
        session.status = "completed"
        session.completion_time = datetime.now()
        
        # Free up collaborators
        if session.human_collaborator:
            session.human_collaborator.current_task = None
            session.human_collaborator.availability = True
        
        if session.ai_collaborator:
            session.ai_collaborator.current_task = None
            session.ai_collaborator.availability = True
        
        self.stats["completed_sessions"] += 1
        
        # Record collaboration pattern for learning
        self.collaboration_patterns.append({
            "session_id": session_id,
            "mode": session.mode.value,
            "outcome": outcome,
            "handoffs": len(session.handoff_history),
            "duration": session.completion_time.timestamp() - session.start_time.timestamp() if session.start_time else 0
        })
    
    def get_session_status(self, session_id: str) -> Dict:
        """Get detailed status of a collaboration session."""
        if session_id not in self.sessions:
            raise ValueError(f"Session {session_id} not found")
        
        session = self.sessions[session_id]
        
        return {
            "session": session.to_dict(),
            "workspace": session.workspace.to_dict() if session.workspace else None,
            "recent_handoffs": session.handoff_history[-5:],  # Last 5 handoffs
            "current_phase": session.current_phase
        }
    
    def get_dashboard_data(self) -> Dict:
        """Get real-time dashboard data."""
        active_sessions = [s for s in self.sessions.values() if s.status == "active"]
        
        return {
            "active_sessions": len(active_sessions),
            "total_sessions": self.stats["total_sessions"],
            "completed_sessions": self.stats["completed_sessions"],
            "total_handoffs": self.stats["total_handoffs"],
            "successful_handoffs": self.stats["successful_handoffs"],
            "handoff_success_rate": (
                self.stats["successful_handoffs"] / max(1, self.stats["total_handoffs"])
            ),
            "conflicts_resolved": self.stats["conflicts_resolved"],
            "registered_collaborators": len(self.collaborators),
            "sessions_by_mode": self.stats["sessions_by_mode"]
        }
    
    def get_stats(self) -> Dict:
        """Get collaboration statistics."""
        return self.stats.copy()
    
    # Private helper methods
    
    def _determine_initial_role(self, mode: CollaborationMode) -> Role:
        """Determine initial role based on collaboration mode."""
        role_mapping = {
            CollaborationMode.AI_ASSISTED: Role.HUMAN_LEAD,
            CollaborationMode.HUMAN_SUPERVISED: Role.AI_LEAD,
            CollaborationMode.COLLABORATIVE: Role.CO_EQUAL,
            CollaborationMode.AUTONOMOUS: Role.AI_LEAD
        }
        
        return role_mapping.get(mode, Role.CO_EQUAL)


# Example usage and testing
if __name__ == "__main__":
    print("="*70)
    print("HYBRID COLLABORATION MANAGER - TEST")
    print("="*70)
    
    manager = HybridCollaborationManager()
    
    print("\n👥 Test 1: Registering Collaborators")
    print("-" * 70)
    
    # Register human collaborator
    human = Collaborator(
        collaborator_id="human_001",
        name="Dr. Sarah Chen",
        collaborator_type="human",
        expertise_areas=["sports_analysis", "prediction_validation"]
    )
    manager.register_collaborator(human)
    print(f"  ✓ Registered: {human.name} (Human)")
    
    # Register AI collaborator
    ai = Collaborator(
        collaborator_id="ai_analyzer_01",
        name="Tiannara Analyzer",
        collaborator_type="ai",
        expertise_areas=["data_analysis", "pattern_recognition", "prediction"]
    )
    manager.register_collaborator(ai)
    print(f"  ✓ Registered: {ai.name} (AI)")
    
    print("\n🚀 Test 2: Initiating Collaboration Session")
    print("-" * 70)
    
    session = manager.initiate_collaboration(
        task_description="Analyze football match predictions and validate accuracy",
        human_id="human_001",
        ai_id="ai_analyzer_01",
        mode=CollaborationMode.COLLABORATIVE
    )
    
    print(f"  Session ID: {session.session_id}")
    print(f"  Task: {session.task_description}")
    print(f"  Mode: {session.mode.value}")
    print(f"  Initial Role: {session.current_role.value}")
    print(f"  Workspace: {session.workspace.workspace_id if session.workspace else 'None'}")
    
    print("\n📝 Test 3: Creating Workspace Artifacts")
    print("-" * 70)
    
    if session.workspace:
        # AI creates analysis artifact
        manager.create_workspace_artifact(
            workspace_id=session.workspace.workspace_id,
            artifact_name="prediction_analysis",
            content={
                "home_win_probability": 0.65,
                "confidence": 0.78,
                "key_factors": ["Home form", "Head-to-head record"]
            },
            author_id="ai_analyzer_01"
        )
        print("  ✓ AI created: prediction_analysis")
        
        # Human adds validation notes
        manager.create_workspace_artifact(
            workspace_id=session.workspace.workspace_id,
            artifact_name="validation_notes",
            content="Analysis looks solid. Consider injury impact.",
            author_id="human_001"
        )
        print("  ✓ Human created: validation_notes")
        
        # Log discussion
        session.workspace.log_discussion(
            "ai_analyzer_01",
            "I've completed the initial analysis. Please review.",
            context="prediction_review"
        )
        
        session.workspace.log_discussion(
            "human_001",
            "Good work. Let me add some domain expertise.",
            context="feedback"
        )
        
        print(f"  Discussion entries: {len(session.workspace.discussion_log)}")
    
    print("\n🔄 Test 4: Requesting Handoff")
    print("-" * 70)
    
    # AI requests handoff to human for validation
    handoff_request = manager.request_handoff(
        session_id=session.session_id,
        from_collaborator_id="ai_analyzer_01",
        to_collaborator_id="human_001",
        reason="Need human expertise for final validation",
        context={"phase": "validation"}
    )
    
    print(f"  Handoff Request ID: {handoff_request.request_id}")
    print(f"  Direction: {handoff_request.direction.value}")
    print(f"  Reason: {handoff_request.reason}")
    print(f"  Approved: {handoff_request.approved}")
    
    # Approve handoff
    manager.approve_handoff(handoff_request.request_id)
    print(f"  ✓ Handoff approved")
    
    # Execute handoff
    success = manager.execute_handoff(handoff_request.request_id)
    print(f"  ✓ Handoff executed: {success}")
    print(f"  New role: {session.current_role.value}")
    
    print("\n⚖️  Test 5: Resolving Conflict")
    print("-" * 70)
    
    # Simulate conflicting decisions
    human_decision = {"prediction": "home_win", "confidence": 0.70}
    ai_decision = {"prediction": "draw", "confidence": 0.65}
    
    resolution = manager.resolve_conflict(
        session_id=session.session_id,
        human_decision=human_decision,
        ai_decision=ai_decision,
        resolution_strategy="human_override"
    )
    
    print(f"  Human Decision: {human_decision}")
    print(f"  AI Decision: {ai_decision}")
    print(f"  Strategy: {resolution['strategy']}")
    print(f"  Final Decision: {resolution['final_decision']}")
    print(f"  Rationale: {resolution['rationale']}")
    
    print("\n📊 Test 6: Session Status")
    print("-" * 70)
    
    status = manager.get_session_status(session.session_id)
    print(f"  Session Status: {status['session']['status']}")
    print(f"  Current Phase: {status['current_phase']}")
    print(f"  Handoffs: {status['session']['handoffs']}")
    print(f"  Workspace Artifacts: {status['workspace']['artifacts_count']}")
    print(f"  Discussion Entries: {status['workspace']['discussion_entries']}")
    
    print("\n✅ Test 7: Completing Session")
    print("-" * 70)
    
    manager.complete_session(session.session_id, outcome="success")
    print(f"  Session completed successfully")
    print(f"  Final status: {session.status}")
    print(f"  Duration: {session.completion_time.timestamp() - session.start_time.timestamp():.1f} seconds")
    
    print("\n📈 Test 8: Dashboard Data")
    print("-" * 70)
    
    dashboard = manager.get_dashboard_data()
    print(f"  Active Sessions: {dashboard['active_sessions']}")
    print(f"  Total Sessions: {dashboard['total_sessions']}")
    print(f"  Completed Sessions: {dashboard['completed_sessions']}")
    print(f"  Total Handoffs: {dashboard['total_handoffs']}")
    print(f"  Handoff Success Rate: {dashboard['handoff_success_rate']:.0%}")
    print(f"  Conflicts Resolved: {dashboard['conflicts_resolved']}")
    print(f"  Registered Collaborators: {dashboard['registered_collaborators']}")
    print(f"  Sessions by Mode: {dashboard['sessions_by_mode']}")
    
    print("\n📋 Test 9: Statistics Summary")
    print("-" * 70)
    
    stats = manager.get_stats()
    for key, value in stats.items():
        if key != "sessions_by_mode":
            print(f"  {key}: {value}")
    
    print("\n" + "="*70)
    print("✅ HYBRID COLLABORATION MANAGER TEST COMPLETE")
    print("="*70)
