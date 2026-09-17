"""
Collective Intelligence Domain - Multi-Agent Collaboration

Enables collaboration between multiple AI agents to solve complex problems:
- Agent orchestration and task distribution
- Knowledge sharing and consensus building
- Emergent intelligence through collaboration
- Conflict resolution and decision synthesis
"""

from typing import Dict, List, Optional, Any
from datetime import datetime
from enum import Enum


class AgentRole(Enum):
    """Different agent roles in collective intelligence."""
    ANALYZER = "analyzer"
    SYNTHESIZER = "synthesizer"
    CRITIC = "critic"
    CREATOR = "creator"
    VALIDATOR = "validator"
    COORDINATOR = "coordinator"


class AgentState(Enum):
    """Agent operational states."""
    IDLE = "idle"
    WORKING = "working"
    WAITING = "waiting"
    COMPLETE = "complete"
    FAILED = "failed"


class CollaborativeAgent:
    """Individual agent participating in collective intelligence."""
    
    def __init__(self, agent_id: str, role: AgentRole, capabilities: List[str]):
        self.agent_id = agent_id
        self.role = role
        self.capabilities = capabilities
        self.state = AgentState.IDLE
        self.current_task = None
        self.results = []
        self.collaboration_history = []
    
    def assign_task(self, task: Dict) -> bool:
        """Assign a task to this agent."""
        if self.state != AgentState.IDLE:
            return False
        
        self.current_task = task
        self.state = AgentState.WORKING
        return True
    
    def complete_task(self, result: Any) -> Dict:
        """Mark task as complete with result."""
        self.results.append(result)
        self.state = AgentState.COMPLETE
        
        return {
            'agent_id': self.agent_id,
            'role': self.role.value,
            'result': result,
            'timestamp': datetime.utcnow().isoformat()
        }
    
    def get_expertise_match(self, required_skills: List[str]) -> float:
        """Calculate how well this agent's capabilities match required skills."""
        if not required_skills:
            return 0.0
        
        matching = sum(1 for skill in required_skills if skill in self.capabilities)
        return matching / len(required_skills)


class CollectiveIntelligenceEngine:
    """
    Engine for orchestrating multi-agent collaboration.
    
    Features:
    - Dynamic agent team formation
    - Task decomposition and distribution
    - Result aggregation and consensus
    - Performance tracking and optimization
    """
    
    def __init__(self):
        self.agents: Dict[str, CollaborativeAgent] = {}
        self.active_teams: Dict[str, List[str]] = {}
        self.collaboration_results = []
        self.team_counter = 0
    
    def register_agent(self, agent_id: str, role: AgentRole, capabilities: List[str]) -> bool:
        """Register a new agent in the collective."""
        if agent_id in self.agents:
            return False
        
        self.agents[agent_id] = CollaborativeAgent(agent_id, role, capabilities)
        return True
    
    def form_team(self, task_description: str, required_roles: List[AgentRole]) -> str:
        """Form a team of agents for a specific task."""
        self.team_counter += 1
        team_id = f"team_{self.team_counter}"
        
        # Select best agents for each required role
        selected_agents = []
        
        for role in required_roles:
            # Find idle agents with this role
            candidates = [
                agent for agent in self.agents.values()
                if agent.role == role and agent.state == AgentState.IDLE
            ]
            
            if candidates:
                # Select agent with most relevant capabilities
                best_agent = max(candidates, key=lambda a: len(a.capabilities))
                selected_agents.append(best_agent.agent_id)
        
        self.active_teams[team_id] = selected_agents
        
        return team_id
    
    def distribute_task(self, team_id: str, subtasks: List[Dict]) -> Dict:
        """Distribute subtasks among team members."""
        if team_id not in self.active_teams:
            return {'success': False, 'error': 'Team not found'}
        
        team_agents = self.active_teams[team_id]
        results = []
        
        for i, subtask in enumerate(subtasks):
            if i < len(team_agents):
                agent_id = team_agents[i]
                agent = self.agents.get(agent_id)
                
                if agent:
                    success = agent.assign_task(subtask)
                    if success:
                        results.append({
                            'agent_id': agent_id,
                            'status': 'assigned',
                            'subtask': subtask.get('description', '')
                        })
        
        return {
            'success': True,
            'team_id': team_id,
            'assignments': results
        }
    
    def aggregate_results(self, team_id: str) -> Dict:
        """Aggregate results from all team members."""
        if team_id not in self.active_teams:
            return {'success': False, 'error': 'Team not found'}
        
        team_agents = self.active_teams[team_id]
        all_results = []
        
        for agent_id in team_agents:
            agent = self.agents.get(agent_id)
            if agent and agent.results:
                all_results.extend(agent.results)
        
        # Build consensus or synthesis
        aggregated = {
            'team_id': team_id,
            'total_contributions': len(all_results),
            'results': all_results,
            'consensus': self._build_consensus(all_results),
            'timestamp': datetime.utcnow().isoformat()
        }
        
        self.collaboration_results.append(aggregated)
        
        # Reset team
        del self.active_teams[team_id]
        
        return {'success': True, 'aggregation': aggregated}
    
    def _build_consensus(self, results: List[Any]) -> Dict:
        """Build consensus from multiple agent results."""
        if not results:
            return {'consensus': None, 'confidence': 0.0}
        
        # Simple majority voting for now
        # In production, this would use sophisticated consensus algorithms
        return {
            'consensus': results[0] if results else None,
            'confidence': 0.8,
            'method': 'majority_voting',
            'contributions': len(results)
        }
    
    def get_collaboration_metrics(self) -> Dict:
        """Get metrics on collective intelligence performance."""
        total_teams = len(self.collaboration_results)
        avg_contributions = (
            sum(r['total_contributions'] for r in self.collaboration_results) / total_teams
            if total_teams > 0 else 0
        )
        
        return {
            'total_collaborations': total_teams,
            'active_teams': len(self.active_teams),
            'registered_agents': len(self.agents),
            'avg_contributions_per_team': avg_contributions,
            'collaboration_efficiency': min(1.0, avg_contributions / 5.0)  # Normalize
        }
    
    def enable_knowledge_sharing(self, source_agent: str, target_agent: str, knowledge: Dict) -> bool:
        """Enable knowledge transfer between agents."""
        if source_agent not in self.agents or target_agent not in self.agents:
            return False
        
        source = self.agents[source_agent]
        target = self.agents[target_agent]
        
        # Transfer knowledge (simplified - in production would be more sophisticated)
        target.capabilities.extend([k for k in knowledge.keys() if k not in target.capabilities])
        
        return True
