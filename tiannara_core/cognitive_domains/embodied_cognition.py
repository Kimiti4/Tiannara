"""
Embodied Cognition Domain - Grounded Reasoning

Grounds abstract reasoning in simulated experience:
- Physical world simulation
- Sensorimotor learning
- Spatial reasoning
- Temporal dynamics understanding
- Experience-based knowledge acquisition
"""

from typing import Dict, List, Optional, Tuple
from datetime import datetime
import math


class SimulatedEnvironment:
    """Represents a simulated environment for embodied cognition."""
    
    def __init__(self, env_id: str, env_type: str, properties: Dict):
        self.env_id = env_id
        self.env_type = env_type  # 'physical', 'social', 'abstract'
        self.properties = properties
        self.entities = []
        self.interactions = []
        self.state_history = []
    
    def add_entity(self, entity_id: str, position: Tuple[float, float], 
                   attributes: Dict) -> bool:
        """Add an entity to the environment."""
        self.entities.append({
            'id': entity_id,
            'position': position,
            'attributes': attributes,
            'state': 'active'
        })
        return True
    
    def simulate_interaction(self, agent_id: str, action: str, 
                            target_id: Optional[str] = None) -> Dict:
        """Simulate an interaction in the environment."""
        result = {
            'agent_id': agent_id,
            'action': action,
            'target': target_id,
            'outcome': 'success',
            'feedback': {},
            'timestamp': datetime.utcnow().isoformat()
        }
        
        # Simple physics simulation (can be extended)
        if action == 'move':
            result['feedback'] = {'new_position': (1.0, 2.0)}
        elif action == 'observe':
            result['feedback'] = {'observations': ['entity nearby']}
        elif action == 'interact':
            result['feedback'] = {'response': 'interaction successful'}
        
        self.interactions.append(result)
        return result


class EmbodiedAgent:
    """Agent with embodied cognition capabilities."""
    
    def __init__(self, agent_id: str):
        self.agent_id = agent_id
        self.position = (0.0, 0.0)
        self.sensor_data = {}
        self.experience_log = []
        self.learned_patterns = []
        self.spatial_map = {}
    
    def perceive(self, environment: SimulatedEnvironment) -> Dict:
        """Perceive the environment through sensors."""
        # Gather sensor data from environment
        nearby_entities = [
            e for e in environment.entities
            if self._calculate_distance(self.position, e['position']) < 5.0
        ]
        
        perception = {
            'agent_id': self.agent_id,
            'position': self.position,
            'nearby_entities': nearby_entities,
            'environment_type': environment.env_type,
            'timestamp': datetime.utcnow().isoformat()
        }
        
        self.sensor_data = perception
        return perception
    
    def act(self, action: str, environment: SimulatedEnvironment, 
            target_id: Optional[str] = None) -> Dict:
        """Take action in the environment."""
        result = environment.simulate_interaction(
            self.agent_id, action, target_id
        )
        
        # Update agent state based on action
        if action == 'move' and 'new_position' in result.get('feedback', {}):
            self.position = result['feedback']['new_position']
        
        # Log experience
        self.experience_log.append({
            'action': action,
            'result': result,
            'timestamp': datetime.utcnow().isoformat()
        })
        
        return result
    
    def learn_from_experience(self) -> List[Dict]:
        """Extract patterns from accumulated experience."""
        if len(self.experience_log) < 3:
            return []
        
        # Simple pattern detection (would use ML in production)
        patterns = []
        
        # Detect action-outcome patterns
        action_outcomes = {}
        for exp in self.experience_log[-20:]:
            action = exp['action']
            outcome = exp['result'].get('outcome', 'unknown')
            
            if action not in action_outcomes:
                action_outcomes[action] = []
            action_outcomes[action].append(outcome)
        
        for action, outcomes in action_outcomes.items():
            success_rate = outcomes.count('success') / len(outcomes)
            patterns.append({
                'pattern_type': 'action_outcome',
                'action': action,
                'success_rate': success_rate,
                'sample_size': len(outcomes)
            })
        
        self.learned_patterns = patterns
        return patterns
    
    def _calculate_distance(self, pos1: Tuple[float, float], 
                           pos2: Tuple[float, float]) -> float:
        """Calculate Euclidean distance between two positions."""
        return math.sqrt((pos1[0] - pos2[0])**2 + (pos1[1] - pos2[1])**2)
    
    def build_spatial_map(self, observations: List[Dict]):
        """Build a spatial map from observations."""
        for obs in observations:
            if 'position' in obs and 'entity_id' in obs:
                self.spatial_map[obs['entity_id']] = obs['position']


class EmbodiedCognitionSystem:
    """
    System for grounded reasoning through simulated embodiment.
    
    Features:
    - Environment simulation
    - Agent perception and action
    - Experiential learning
    - Spatial-temporal reasoning
    - Grounded concept formation
    """
    
    def __init__(self):
        self.environments: Dict[str, SimulatedEnvironment] = {}
        self.agents: Dict[str, EmbodiedAgent] = {}
        self.simulation_history = []
        self.grounded_concepts = []
        self.cognition_metrics = {
            'total_simulations': 0,
            'total_interactions': 0,
            'patterns_learned': 0,
            'concepts_grounded': 0
        }
    
    def create_environment(self, env_id: str, env_type: str, 
                          properties: Dict) -> bool:
        """Create a new simulated environment."""
        if env_id in self.environments:
            return False
        
        self.environments[env_id] = SimulatedEnvironment(env_id, env_type, properties)
        return True
    
    def create_agent(self, agent_id: str) -> bool:
        """Create a new embodied agent."""
        if agent_id in self.agents:
            return False
        
        self.agents[agent_id] = EmbodiedAgent(agent_id)
        return True
    
    def run_simulation(self, agent_id: str, env_id: str, 
                      actions: List[str]) -> Dict:
        """Run a complete simulation sequence."""
        if agent_id not in self.agents or env_id not in self.environments:
            return {'success': False, 'error': 'Agent or environment not found'}
        
        agent = self.agents[agent_id]
        environment = self.environments[env_id]
        
        simulation_results = {
            'agent_id': agent_id,
            'env_id': env_id,
            'actions_executed': [],
            'learnings': [],
            'timestamp': datetime.utcnow().isoformat()
        }
        
        # Execute each action
        for action in actions:
            # Perceive environment
            perception = agent.perceive(environment)
            
            # Take action
            result = agent.act(action, environment)
            
            simulation_results['actions_executed'].append({
                'action': action,
                'perception': perception,
                'result': result
            })
            
            self.cognition_metrics['total_interactions'] += 1
        
        # Learn from experience
        patterns = agent.learn_from_experience()
        simulation_results['learnings'] = patterns
        self.cognition_metrics['patterns_learned'] += len(patterns)
        
        self.simulation_history.append(simulation_results)
        self.cognition_metrics['total_simulations'] += 1
        
        return {'success': True, 'simulation': simulation_results}
    
    def ground_concept(self, concept_name: str, experiences: List[Dict]) -> Dict:
        """Ground an abstract concept in concrete experiences."""
        # Extract commonalities from experiences
        grounded_representation = {
            'concept': concept_name,
            'experiential_basis': experiences[:5],  # Use up to 5 examples
            'abstraction_level': self._calculate_abstraction(experiences),
            'confidence': min(1.0, len(experiences) / 10.0),
            'timestamp': datetime.utcnow().isoformat()
        }
        
        self.grounded_concepts.append(grounded_representation)
        self.cognition_metrics['concepts_grounded'] += 1
        
        return grounded_representation
    
    def _calculate_abstraction(self, experiences: List[Dict]) -> float:
        """Calculate abstraction level from experiences."""
        if not experiences:
            return 0.0
        
        # Higher abstraction when experiences are more diverse
        unique_actions = len(set(e.get('action', '') for e in experiences))
        return min(1.0, unique_actions / 5.0)
    
    def get_spatial_reasoning_report(self, agent_id: str) -> Optional[Dict]:
        """Get spatial reasoning capabilities report for an agent."""
        if agent_id not in self.agents:
            return None
        
        agent = self.agents[agent_id]
        
        return {
            'agent_id': agent_id,
            'current_position': agent.position,
            'spatial_map_size': len(agent.spatial_map),
            'experience_count': len(agent.experience_log),
            'learned_patterns': agent.learned_patterns,
            'navigation_capability': len(agent.spatial_map) > 0
        }
    
    def get_embodiment_metrics(self) -> Dict:
        """Get comprehensive embodiment metrics."""
        total_experiences = sum(
            len(agent.experience_log) for agent in self.agents.values()
        )
        
        return {
            **self.cognition_metrics,
            'active_environments': len(self.environments),
            'active_agents': len(self.agents),
            'total_experiences': total_experiences,
            'avg_experiences_per_agent': (
                total_experiences / max(1, len(self.agents))
            ),
            'grounded_concepts': len(self.grounded_concepts)
        }
    
    def transfer_learning(self, source_agent: str, target_agent: str) -> bool:
        """Transfer learned patterns between agents."""
        if source_agent not in self.agents or target_agent not in self.agents:
            return False
        
        source = self.agents[source_agent]
        target = self.agents[target_agent]
        
        # Transfer learned patterns
        target.learned_patterns.extend(source.learned_patterns)
        
        return True
