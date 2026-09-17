"""
Creative Synthesis Domain - Innovation Engine

Drives innovation through novel combinations of concepts:
- Cross-domain pattern recognition
- Conceptual blending and metaphor generation
- Novel idea synthesis
- Creativity evaluation and refinement
"""

from typing import Dict, List, Optional, Tuple
from datetime import datetime
import random


class Concept:
    """Represents a conceptual element for creative synthesis."""
    
    def __init__(self, name: str, domain: str, attributes: List[str], relationships: Dict[str, str]):
        self.name = name
        self.domain = domain
        self.attributes = attributes
        self.relationships = relationships
        self.novelty_score = 0.0
    
    def to_dict(self) -> Dict:
        return {
            'name': self.name,
            'domain': self.domain,
            'attributes': self.attributes,
            'relationships': self.relationships,
            'novelty_score': self.novelty_score
        }


class CreativeSynthesisEngine:
    """
    Engine for generating innovative ideas through creative synthesis.
    
    Features:
    - Cross-domain concept combination
    - Pattern recognition and transfer
    - Novelty assessment
    - Idea refinement and evolution
    """
    
    def __init__(self):
        self.concept_library: Dict[str, Concept] = {}
        self.synthesis_history = []
        self.creativity_metrics = {
            'total_syntheses': 0,
            'avg_novelty': 0.0,
            'successful_innovations': 0
        }
    
    def register_concept(self, concept: Concept) -> bool:
        """Add a concept to the library."""
        if concept.name in self.concept_library:
            return False
        
        self.concept_library[concept.name] = concept
        return True
    
    def synthesize_ideas(self, source_domains: List[str], target_problem: str) -> Dict:
        """
        Generate novel ideas by synthesizing concepts from different domains.
        
        Args:
            source_domains: Domains to draw concepts from
            target_problem: Problem statement to solve
            
        Returns:
            Dictionary containing synthesized ideas with novelty scores
        """
        # Gather concepts from specified domains
        domain_concepts = [
            c for c in self.concept_library.values()
            if c.domain in source_domains
        ]
        
        if len(domain_concepts) < 2:
            return {
                'success': False,
                'error': 'Need at least 2 concepts from different domains',
                'ideas': []
            }
        
        # Generate novel combinations
        synthesized_ideas = []
        
        # Create cross-domain blends
        num_combinations = min(5, len(domain_concepts) * (len(domain_concepts) - 1) // 2)
        
        for _ in range(num_combinations):
            # Select two random concepts from different domains
            concept1, concept2 = random.sample(domain_concepts, 2)
            
            if concept1.domain == concept2.domain:
                continue
            
            # Blend concepts
            blended_idea = self._blend_concepts(concept1, concept2, target_problem)
            synthesized_ideas.append(blended_idea)
        
        # Evaluate novelty
        for idea in synthesized_ideas:
            idea['novelty_score'] = self._evaluate_novelty(idea)
        
        # Sort by novelty
        synthesized_ideas.sort(key=lambda x: x['novelty_score'], reverse=True)
        
        # Update metrics
        self.creativity_metrics['total_syntheses'] += len(synthesized_ideas)
        if synthesized_ideas:
            avg_novelty = sum(i['novelty_score'] for i in synthesized_ideas) / len(synthesized_ideas)
            self.creativity_metrics['avg_novelty'] = avg_novelty
            self.creativity_metrics['successful_innovations'] += sum(
                1 for i in synthesized_ideas if i['novelty_score'] > 0.7
            )
        
        result = {
            'success': True,
            'target_problem': target_problem,
            'source_domains': source_domains,
            'ideas': synthesized_ideas,
            'timestamp': datetime.utcnow().isoformat()
        }
        
        self.synthesis_history.append(result)
        
        return result
    
    def _blend_concepts(self, concept1: Concept, concept2: Concept, problem: str) -> Dict:
        """Create a novel blend of two concepts."""
        # Combine attributes
        combined_attributes = list(set(concept1.attributes + concept2.attributes))
        
        # Merge relationships (prioritize concept1's structure)
        merged_relationships = concept1.relationships.copy()
        merged_relationships.update(concept2.relationships)
        
        # Generate novel name
        blend_name = f"{concept1.name}_{concept2.name}_synthesis"
        
        # Apply to problem context
        application = self._apply_to_problem(blend_name, combined_attributes, problem)
        
        return {
            'name': blend_name,
            'components': [concept1.name, concept2.name],
            'domains': [concept1.domain, concept2.domain],
            'attributes': combined_attributes[:10],  # Limit attributes
            'application': application,
            'novelty_score': 0.0  # Will be calculated later
        }
    
    def _apply_to_problem(self, concept_name: str, attributes: List[str], problem: str) -> str:
        """Generate application description for the synthesized concept."""
        return f"Apply {concept_name} with attributes {', '.join(attributes[:3])} to address: {problem}"
    
    def _evaluate_novelty(self, idea: Dict) -> float:
        """Evaluate the novelty of a synthesized idea."""
        # Factors contributing to novelty:
        # 1. Cross-domain combination (different domains = more novel)
        domain_novelty = 1.0 if len(set(idea.get('domains', []))) > 1 else 0.3
        
        # 2. Attribute diversity
        attr_diversity = min(1.0, len(idea.get('attributes', [])) / 10.0)
        
        # 3. Uniqueness (check against history)
        uniqueness = self._calculate_uniqueness(idea)
        
        # Weighted combination
        novelty = (0.4 * domain_novelty + 0.3 * attr_diversity + 0.3 * uniqueness)
        
        return round(novelty, 3)
    
    def _calculate_uniqueness(self, idea: Dict) -> float:
        """Calculate how unique this idea is compared to past syntheses."""
        if not self.synthesis_history:
            return 1.0
        
        # Simple uniqueness check based on component similarity
        idea_components = set(idea.get('components', []))
        
        similar_count = 0
        for past_result in self.synthesis_history[-20:]:  # Check last 20 results
            for past_idea in past_result.get('ideas', []):
                past_components = set(past_idea.get('components', []))
                if idea_components & past_components:  # Intersection
                    similar_count += 1
        
        uniqueness = 1.0 - (similar_count / max(1, len(self.synthesis_history[-20:]) * 5))
        return max(0.0, uniqueness)
    
    def refine_idea(self, idea: Dict, feedback: str) -> Dict:
        """Refine an idea based on feedback."""
        refined_idea = idea.copy()
        
        # Adjust novelty based on feedback sentiment
        if 'innovative' in feedback.lower() or 'novel' in feedback.lower():
            refined_idea['novelty_score'] = min(1.0, idea.get('novelty_score', 0) + 0.1)
        elif 'common' in feedback.lower() or 'typical' in feedback.lower():
            refined_idea['novelty_score'] = max(0.0, idea.get('novelty_score', 0) - 0.1)
        
        refined_idea['refined'] = True
        refined_idea['feedback_applied'] = feedback
        
        return refined_idea
    
    def get_creativity_report(self) -> Dict:
        """Generate comprehensive creativity metrics report."""
        return {
            'metrics': self.creativity_metrics,
            'recent_syntheses': self.synthesis_history[-5:],
            'concept_library_size': len(self.concept_library),
            'domain_coverage': list(set(c.domain for c in self.concept_library.values())),
            'innovation_rate': (
                self.creativity_metrics['successful_innovations'] / 
                max(1, self.creativity_metrics['total_syntheses'])
            )
        }
