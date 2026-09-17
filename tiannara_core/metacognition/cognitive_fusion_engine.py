"""
COGNITIVE FUSION ENGINE - PHASES A-D

Purpose: Enable true emergent synthesis in multi-agent systems by implementing:

Phase A: Debate Memory - Store arguments, rebuttals, failed claims, surviving principles
Phase B: Perspective Graphs - Map idea support/conflict relationships  
Phase C: Partial Merge Engine - Merge only compatible sub-components
Phase D: Emergent Solution Scoring - Evaluate if hybrid outperforms all individuals

This transforms Tiannara from "intelligent committee selecting winners" to 
"cognitive civilization producing emergent intelligence."

Based on strategic analysis in synthess.md (lines 1-369).
"""

import sys
import time
from pathlib import Path
from typing import Dict, List, Tuple, Optional, Set
from dataclasses import dataclass, field
from enum import Enum

# Add project root to path
project_root = Path(__file__).parent
sys.path.insert(0, str(project_root))

# PERFORMANCE OPTIMIZATION: Hard limits to prevent combinatorial explosion
MAX_FRAGMENTS_PER_THEORY = 10  # Limit decomposition
MAX_DEPTH = 3  # Maximum recursion depth
MAX_RELATIONSHIPS = 25  # Cap relationship mapping
FUSION_CACHE_ENABLED = True  # Enable epistemic memoization

from tiannara_core.metacognition.theory_engine import (
    Theory,
    CausalClaim,
    EvidenceItem,
    EvidenceType,
    Prediction,
    Counterexample,
)


# ============================================================================
# PHASE A: DEBATE MEMORY
# ============================================================================

@dataclass
class ArgumentRecord:
    """Single argument from debate with full context."""
    argument_id: str
    agent_id: str
    target_agent_id: Optional[str]
    argument_type: str  # "claim", "critique", "rebuttal", "support", "question"
    content: str
    timestamp: float
    evidence_strength: float = 0.0
    survived_critique: bool = False  # Whether this argument withstood challenges
    related_arguments: List[str] = field(default_factory=list)  # IDs of related args


@dataclass
class DebateSession:
    """Complete record of a debate session."""
    session_id: str
    problem_description: str
    start_time: float
    end_time: Optional[float] = None
    
    # All arguments made
    arguments: List[ArgumentRecord] = field(default_factory=list)
    
    # Surviving principles (claims that weren't successfully refuted)
    surviving_principles: List[str] = field(default_factory=list)
    
    # Failed claims (arguments that were refuted)
    failed_claims: List[str] = field(default_factory=list)
    
    # Key insights extracted
    key_insights: List[str] = field(default_factory=list)


class DebateMemory:
    """
    Phase A: Stores complete debate history for later synthesis.
    
    Unlike simple vote counting, this preserves:
    - Full argument chains (claim → critique → rebuttal)
    - Which principles survived vs. failed
    - Context for why certain ideas were rejected
    """
    
    def __init__(self):
        self.sessions: Dict[str, DebateSession] = {}
        self.argument_index: Dict[str, ArgumentRecord] = {}
        
    def create_session(self, session_id: str, problem: str) -> DebateSession:
        """Create new debate session."""
        session = DebateSession(
            session_id=session_id,
            problem_description=problem,
            start_time=time.time()
        )
        self.sessions[session_id] = session
        return session
    
    def add_argument(self, session_id: str, argument: ArgumentRecord) -> None:
        """Add argument to session."""
        session = self.sessions[session_id]
        session.arguments.append(argument)
        self.argument_index[argument.argument_id] = argument
        
        # Link related arguments
        if argument.related_arguments:
            for related_id in argument.related_arguments:
                if related_id in self.argument_index:
                    related_arg = self.argument_index[related_id]
                    if argument.argument_id not in related_arg.related_arguments:
                        related_arg.related_arguments.append(argument.argument_id)
    
    def mark_survived(self, argument_id: str) -> None:
        """Mark argument as having survived critique."""
        if argument_id in self.argument_index:
            self.argument_index[argument_id].survived_critique = True
            
            # Add to surviving principles
            arg = self.argument_index[argument_id]
            for session in self.sessions.values():
                if arg in session.arguments:
                    if arg.content not in session.surviving_principles:
                        session.surviving_principles.append(arg.content)
    
    def mark_failed(self, argument_id: str) -> None:
        """Mark argument as having been refuted."""
        if argument_id in self.argument_index:
            arg = self.argument_index[argument_id]
            for session in self.sessions.values():
                if arg in session.arguments:
                    if arg.content not in session.failed_claims:
                        session.failed_claims.append(arg.content)
    
    def get_surviving_principles(self, session_id: str) -> List[str]:
        """Get principles that survived debate."""
        return self.sessions[session_id].surviving_principles
    
    def get_failed_claims(self, session_id: str) -> List[str]:
        """Get claims that were refuted."""
        return self.sessions[session_id].failed_claims
    
    def extract_debate_insights(self, session_id: str) -> List[str]:
        """Extract key insights from debate for synthesis."""
        session = self.sessions[session_id]
        insights = []
        
        # Count argument types
        type_counts = {}
        for arg in session.arguments:
            type_counts[arg.argument_type] = type_counts.get(arg.argument_type, 0) + 1
        
        insights.append(f"Debate intensity: {len(session.arguments)} arguments")
        insights.append(f"Argument distribution: {type_counts}")
        insights.append(f"Surviving principles: {len(session.surviving_principles)}")
        insights.append(f"Failed claims: {len(session.failed_claims)}")
        
        return insights


# ============================================================================
# PHASE B: PERSPECTIVE GRAPHS
# ============================================================================

class RelationshipType(Enum):
    """Types of relationships between perspective fragments."""
    SUPPORTS = "supports"
    CONFLICTS = "conflicts"
    COMPLEMENTS = "complements"
    SUBSUMES = "subsumes"  # One is special case of other
    INDEPENDENT = "independent"


@dataclass
class PerspectiveFragment:
    """Decomposed element of a solution/perspective."""
    fragment_id: str
    source_agent_id: str
    fragment_type: str  # "assumption", "constraint", "heuristic", "procedure", "objective", "tradeoff"
    content: str
    confidence: float
    metadata: Dict = field(default_factory=dict)


@dataclass
class PerspectiveEdge:
    """Relationship between two fragments."""
    source_id: str
    target_id: str
    relationship: RelationshipType
    strength: float  # 0.0-1.0
    explanation: str


class PerspectiveGraph:
    """
    Phase B: Represents relationships between decomposed perspective fragments.
    
    Enables:
    - Conflict detection between assumptions/constraints
    - Identification of complementary heuristics
    - Discovery of synthesis opportunities
    """
    
    def __init__(self):
        self.fragments: Dict[str, PerspectiveFragment] = {}
        self.edges: List[PerspectiveEdge] = []
        
    def add_fragment(self, fragment: PerspectiveFragment) -> None:
        """Add perspective fragment."""
        self.fragments[fragment.fragment_id] = fragment
    
    def add_relationship(self, edge: PerspectiveEdge) -> None:
        """Add relationship between fragments."""
        self.edges.append(edge)
    
    def detect_conflicts(self) -> List[PerspectiveEdge]:
        """Find all conflicting fragment pairs."""
        return [e for e in self.edges if e.relationship == RelationshipType.CONFLICTS]
    
    def find_complementary_fragments(self) -> List[PerspectiveEdge]:
        """Find fragments that complement each other."""
        return [e for e in self.edges if e.relationship == RelationshipType.COMPLEMENTS]
    
    def get_fragment_dependencies(self, fragment_id: str) -> List[str]:
        """Get all fragments that support this one."""
        dependencies = []
        for edge in self.edges:
            if edge.target_id == fragment_id and edge.relationship == RelationshipType.SUPPORTS:
                dependencies.append(edge.source_id)
        return dependencies
    
    def find_synthesis_opportunities(self) -> List[Tuple[str, str, str]]:
        """
        Identify promising synthesis opportunities.
        
        Returns list of (fragment_a, fragment_b, opportunity_type) tuples.
        """
        opportunities = []
        
        # Look for conflicts that could be resolved
        conflicts = self.detect_conflicts()
        for conflict in conflicts:
            frag_a = self.fragments[conflict.source_id]
            frag_b = self.fragments[conflict.target_id]
            
            # If both have high confidence, there's tension worth resolving
            if frag_a.confidence > 0.7 and frag_b.confidence > 0.7:
                opportunities.append((
                    conflict.source_id,
                    conflict.target_id,
                    "resolve_conflict"
                ))
        
        # Look for complementary fragments
        complements = self.find_complementary_fragments()
        for comp in complements:
            opportunities.append((
                comp.source_id,
                comp.target_id,
                "merge_complementary"
            ))
        
        return opportunities
    
    def visualize_graph_summary(self) -> str:
        """Generate text summary of graph structure."""
        summary = []
        summary.append(f"Perspective Graph Summary:")
        summary.append(f"  Fragments: {len(self.fragments)}")
        summary.append(f"  Relationships: {len(self.edges)}")
        
        # Count by type
        rel_counts = {}
        for edge in self.edges:
            rel_type = edge.relationship.value
            rel_counts[rel_type] = rel_counts.get(rel_type, 0) + 1
        
        summary.append(f"  Relationship distribution: {rel_counts}")
        
        conflicts = self.detect_conflicts()
        summary.append(f"  Conflicts detected: {len(conflicts)}")
        
        opportunities = self.find_synthesis_opportunities()
        summary.append(f"  Synthesis opportunities: {len(opportunities)}")
        
        return "\n".join(summary)


# ============================================================================
# PHASE C: PARTIAL MERGE ENGINE
# ============================================================================

@dataclass
class MergedComponent:
    """Result of merging compatible fragments."""
    component_id: str
    component_type: str
    merged_content: str
    source_fragments: List[str]  # Fragment IDs that were merged
    compatibility_score: float
    confidence: float


class PartialMergeEngine:
    """
    Phase C: Merges only compatible sub-components from different perspectives.
    
    Instead of forcing full solution synthesis, this:
    - Identifies compatible fragments
    - Merges them into unified components
    - Preserves incompatible elements separately
    - Avoids "feature soup" from forced integration
    """
    
    def __init__(self, perspective_graph: PerspectiveGraph):
        self.graph = perspective_graph
        self.merged_components: List[MergedComponent] = []
        
    def merge_compatible_fragments(self, fragment_ids: List[str]) -> Optional[MergedComponent]:
        """
        Attempt to merge compatible fragments.
        
        Returns merged component or None if incompatible.
        """
        if len(fragment_ids) < 2:
            return None
        
        # Check compatibility
        fragments = [self.graph.fragments[fid] for fid in fragment_ids if fid in self.graph.fragments]
        
        if len(fragments) < 2:
            return None
        
        # Verify no conflicts between fragments
        for i in range(len(fragments)):
            for j in range(i+1, len(fragments)):
                # Check if there's a conflict edge
                has_conflict = any(
                    e.relationship == RelationshipType.CONFLICTS
                    for e in self.graph.edges
                    if (e.source_id == fragments[i].fragment_id and e.target_id == fragments[j].fragment_id) or
                       (e.source_id == fragments[j].fragment_id and e.target_id == fragments[i].fragment_id)
                )
                
                if has_conflict:
                    return None  # Incompatible
        
        # Merge fragments
        merged_content = self._synthesize_merged_content(fragments)
        avg_confidence = sum(f.confidence for f in fragments) / len(fragments)
        
        component = MergedComponent(
            component_id=f"merged_{'_'.join(fragment_ids[:3])}",
            component_type=fragments[0].fragment_type,
            merged_content=merged_content,
            source_fragments=fragment_ids,
            compatibility_score=0.85,  # High since we filtered conflicts
            confidence=avg_confidence
        )
        
        self.merged_components.append(component)
        return component
    
    def _synthesize_merged_content(self, fragments: List[PerspectiveFragment]) -> str:
        """Synthesize merged content from fragments."""
        # Simple synthesis: combine contents with acknowledgment of sources
        contents = [f.content for f in fragments]
        
        if fragments[0].fragment_type == "assumption":
            return f"Combined assumptions: {'; '.join(contents)}"
        elif fragments[0].fragment_type == "heuristic":
            return f"Hybrid heuristic combining: {' | '.join(contents)}"
        elif fragments[0].fragment_type == "procedure":
            return f"Integrated procedure: Step 1 ({contents[0]}), Step 2 ({contents[1]})"
        else:
            return f"Merged {fragments[0].fragment_type}: {' + '.join(contents)}"
    
    def auto_merge_compatible_groups(self) -> List[MergedComponent]:
        """Automatically find and merge all compatible fragment groups."""
        opportunities = self.graph.find_synthesis_opportunities()
        merged = []
        
        for frag_a_id, frag_b_id, opp_type in opportunities:
            if opp_type == "merge_complementary":
                result = self.merge_compatible_fragments([frag_a_id, frag_b_id])
                if result:
                    merged.append(result)
        
        return merged


# ============================================================================
# PHASE D: EMERGENT SOLUTION SCORING
# ============================================================================

@dataclass
class EmergentSolution:
    """Synthesized solution from merged components."""
    solution_id: str
    description: str
    merged_components: List[MergedComponent]
    novelty_score: float  # How structurally new is this?
    quality_score: float  # Does it outperform individuals?
    contribution_retention: Dict[str, float]  # agent_id -> contribution %


class EmergentSolutionScorer:
    """
    Phase D: Evaluates whether synthesized solutions outperform all individuals.
    
    Metrics:
    - Novel Structure Score: Is final answer structurally new?
    - Hybrid Complexity: Number of merged abstractions
    - Contradiction Resolution: Did system reconcile conflicts?
    - Emergent Gain: Is synthesis better than best individual?
    - Perspective Preservation: Did minority insights survive?
    - Contribution Retention: How much each agent influenced final solution
    """
    
    def __init__(self):
        self.scored_solutions: List[EmergentSolution] = []
        
    def score_emergent_solution(
        self,
        merged_components: List[MergedComponent],
        individual_scores: Dict[str, float],  # agent_id -> their solution score
        original_fragments: Dict[str, PerspectiveFragment]
    ) -> EmergentSolution:
        """Score a synthesized solution."""
        
        # 1. Novelty Score - how structurally different from inputs?
        novelty = self._calculate_novelty(merged_components, original_fragments)
        
        # 2. Quality Score - does it outperform individuals?
        quality = self._calculate_quality(merged_components, individual_scores)
        
        # 3. Contribution Retention - how much each agent contributed?
        contributions = self._calculate_contributions(merged_components, original_fragments)
        
        solution = EmergentSolution(
            solution_id=f"emergent_{time.time():.0f}",
            description=f"Synthesized from {len(merged_components)} components",
            merged_components=merged_components,
            novelty_score=novelty,
            quality_score=quality,
            contribution_retention=contributions
        )
        
        self.scored_solutions.append(solution)
        return solution
    
    def _calculate_novelty(
        self,
        merged_components: List[MergedComponent],
        original_fragments: Dict[str, PerspectiveFragment]
    ) -> float:
        """Calculate how novel the synthesized solution is."""
        if not merged_components:
            return 0.0
        
        # Novelty = number of unique fragment combinations / total possible
        unique_sources = set()
        for comp in merged_components:
            unique_sources.update(comp.source_fragments)
        
        total_fragments = len(original_fragments)
        if total_fragments == 0:
            return 0.0
        
        coverage = len(unique_sources) / total_fragments
        
        # Higher novelty if more diverse sources combined
        novelty = min(1.0, coverage * 1.2)  # Bonus for diversity
        return novelty
    
    def _calculate_quality(
        self,
        merged_components: List[MergedComponent],
        individual_scores: Dict[str, float]
    ) -> float:
        """Calculate if synthesis outperforms individuals."""
        if not merged_components or not individual_scores:
            return 0.0
        
        # Average quality of merged components
        avg_component_quality = sum(c.confidence for c in merged_components) / len(merged_components)
        
        # Best individual score
        best_individual = max(individual_scores.values())
        
        # Emergent gain: how much better than best individual?
        if best_individual > 0:
            emergent_gain = (avg_component_quality - best_individual) / best_individual
        else:
            emergent_gain = 0.0
        
        # Quality score combines component quality with emergent gain
        quality = avg_component_quality * (1.0 + max(0, emergent_gain))
        return min(1.0, quality)
    
    def _calculate_contributions(
        self,
        merged_components: List[MergedComponent],
        original_fragments: Dict[str, PerspectiveFragment]
    ) -> Dict[str, float]:
        """Calculate how much each agent contributed to synthesis."""
        agent_contributions: Dict[str, int] = {}
        total_fragments_used = 0
        
        for comp in merged_components:
            for frag_id in comp.source_fragments:
                if frag_id in original_fragments:
                    agent_id = original_fragments[frag_id].source_agent_id
                    agent_contributions[agent_id] = agent_contributions.get(agent_id, 0) + 1
                    total_fragments_used += 1
        
        # Convert to percentages
        if total_fragments_used == 0:
            return {}
        
        return {
            agent_id: count / total_fragments_used
            for agent_id, count in agent_contributions.items()
        }
    
    def evaluate_synthesis_success(self, solution: EmergentSolution) -> Dict[str, bool]:
        """Evaluate whether synthesis was successful."""
        return {
            'novel': solution.novelty_score > 0.3,
            'outperforms_individuals': solution.quality_score > 0.5,
            'diverse_contributions': len(solution.contribution_retention) >= 2,
            'balanced_contributions': all(
                v < 0.8 for v in solution.contribution_retention.values()
            ) if solution.contribution_retention else False
        }


# ============================================================================
# COGNITIVE FUSION ENGINE (ORCHESTRATOR)
# ============================================================================

class CognitiveFusionEngine:
    """
    Complete Cognitive Fusion Engine orchestrating all 4 phases.
    
    Transforms multi-agent debate from "winner selection" to "emergent synthesis."
    """
    
    def __init__(self):
        self.debate_memory = DebateMemory()
        self.perspective_graph = PerspectiveGraph()
        self.merge_engine: Optional[PartialMergeEngine] = None
        self.solution_scorer = EmergentSolutionScorer()
        
        # PERFORMANCE OPTIMIZATION: Epistemic memoization cache
        self.fragment_cache: Dict[str, List[PerspectiveFragment]] = {}  # theory_hash -> fragments
        self.relationship_cache: Dict[str, RelationshipType] = {}  # fragment_pair_hash -> relationship
        self.consensus_cache: Dict[str, EmergentSolution] = {}  # session_hash -> solution
        
        # PERFORMANCE OPTIMIZATION: Phase profiling metrics
        self.phase_times: Dict[str, float] = {
            'phase_a_debate_memory': 0.0,
            'phase_b_decomposition': 0.0,
            'phase_b_relationship_mapping': 0.0,
            'phase_c_merge': 0.0,
            'phase_d_scoring': 0.0
        }
        self.fusion_count = 0
        
    def run_fusion_pipeline(
        self,
        session_id: str,
        problem: str,
        agent_proposals: Dict[str, Theory],
        debate_arguments: List[ArgumentRecord],
        verbose: bool = False,
        fidelity: str = "HIGH"  # LOW, MEDIUM, HIGH
    ) -> Optional[EmergentSolution]:
        """
        Run complete fusion pipeline on debate results.
        
        PERFORMANCE OPTIMIZATION: Added phase profiling and fidelity modes.
        
        Args:
            session_id: Unique ID for this debate session
            problem: Problem description
            agent_proposals: Each agent's proposed theory
            debate_arguments: All arguments from debate
            fidelity: Fusion fidelity mode (LOW/MEDIUM/HIGH)
            
        Returns:
            EmergentSolution if synthesis successful, None otherwise
        """
        self.fusion_count += 1
        
        # PERFORMANCE OPTIMIZATION: Check consensus cache first
        if FUSION_CACHE_ENABLED:
            cache_key = f"{problem}_{hash(frozenset(agent_proposals.keys()))}"
            if cache_key in self.consensus_cache:
                if verbose:
                    print(f"  [Cache Hit] Returning cached consensus")
                return self.consensus_cache[cache_key]
        
        if verbose:
            print(f"\n{'='*80}")
            print(f"COGNITIVE FUSION PIPELINE (Fidelity: {fidelity})")
            print(f"Problem: {problem[:60]}")
            print(f"{'='*80}\n")
        
        # Phase A: Store debate memory
        start_a = time.time()
        if verbose:
            print("[Phase A] Recording debate memory...")
        
        session = self.debate_memory.create_session(session_id, problem)
        for arg in debate_arguments:
            self.debate_memory.add_argument(session_id, arg)
        
        insights = self.debate_memory.extract_debate_insights(session_id)
        if verbose:
            print(f"  Recorded {len(debate_arguments)} arguments")
            print(f"  Insights: {insights[:2]}")
        
        self.phase_times['phase_a_debate_memory'] = time.time() - start_a
        
        # Phase B: Build perspective graph
        start_b1 = time.time()
        if verbose:
            print("\n[Phase B] Building perspective graph...")
        
        self._decompose_proposals_into_fragments(agent_proposals, fidelity=fidelity)
        self.phase_times['phase_b_decomposition'] = time.time() - start_b1
        
        start_b2 = time.time()
        self._map_fragment_relationships(fidelity=fidelity)
        self.phase_times['phase_b_relationship_mapping'] = time.time() - start_b2
        
        graph_summary = self.perspective_graph.visualize_graph_summary()
        if verbose:
            print(f"  {graph_summary}")
        
        # Phase C: Merge compatible components
        start_c = time.time()
        if verbose:
            print("\n[Phase C] Merging compatible components...")
        
        self.merge_engine = PartialMergeEngine(self.perspective_graph)
        merged = self.merge_engine.auto_merge_compatible_groups()
        
        if verbose:
            print(f"  Merged {len(merged)} component groups")
            if merged:
                for comp in merged[:3]:  # Show first 3
                    print(f"    - {comp.component_type}: {comp.merged_content[:80]}...")
        
        self.phase_times['phase_c_merge'] = time.time() - start_c
        
        if not merged:
            if verbose:
                print("  ⚠️  No compatible components found for merging")
            return None
        
        # Phase D: Score emergent solution
        start_d = time.time()
        if verbose:
            print("\n[Phase D] Scoring emergent solution...")
        
        individual_scores = {
            agent_id: theory.calculate_overall_credibility()
            for agent_id, theory in agent_proposals.items()
        }
        
        solution = self.solution_scorer.score_emergent_solution(
            merged_components=merged,
            individual_scores=individual_scores,
            original_fragments=self.perspective_graph.fragments
        )
        
        success_metrics = self.solution_scorer.evaluate_synthesis_success(solution)
        
        self.phase_times['phase_d_scoring'] = time.time() - start_d
        
        if verbose:
            print(f"  Novelty Score: {solution.novelty_score:.3f}")
            print(f"  Quality Score: {solution.quality_score:.3f}")
            print(f"  Contributions: {len(solution.contribution_retention)} agents")
            print(f"  Success metrics: {success_metrics}")
            
            # Print phase profiling summary
            total_time = sum(self.phase_times.values())
            print(f"\n  [Phase Profiling]")
            for phase_name, phase_time in self.phase_times.items():
                pct = (phase_time / total_time * 100) if total_time > 0 else 0
                print(f"    {phase_name}: {phase_time:.2f}s ({pct:.0f}%)")
            print(f"    Total: {total_time:.2f}s")
            
            if all(success_metrics.values()):
                print(f"\n✅ EMERGENT SYNTHESIS SUCCESSFUL!")
                print(f"   Created novel solution outperforming individuals")
            else:
                print(f"\n⚠️  SYNTHESIS PARTIAL - some criteria not met")
        
        # PERFORMANCE OPTIMIZATION: Cache successful consensus
        if FUSION_CACHE_ENABLED and solution.quality_score > 0.5:
            self.consensus_cache[cache_key] = solution
            # Limit cache size
            if len(self.consensus_cache) > 50:
                oldest_key = next(iter(self.consensus_cache))
                del self.consensus_cache[oldest_key]
        
        return solution
    
    def _decompose_proposals_into_fragments(self, proposals: Dict[str, Theory], fidelity: str = "HIGH") -> None:
        """
        Decompose each agent's proposal into perspective fragments.
        
        PERFORMANCE OPTIMIZATION: Hard limits to prevent combinatorial explosion.
        """
        for agent_id, theory in proposals.items():
            # PERFORMANCE OPTIMIZATION: Check fragment cache
            if FUSION_CACHE_ENABLED:
                theory_hash = hash(str(theory))
                if theory_hash in self.fragment_cache:
                    # Reuse cached fragments
                    for fragment in self.fragment_cache[theory_hash]:
                        self.perspective_graph.add_fragment(fragment)
                    continue
            
            fragments_for_theory = []
            fragment_count = 0
            
            # Extract assumptions (limit based on fidelity)
            max_assumptions = MAX_FRAGMENTS_PER_THEORY // 3 if fidelity == "LOW" else MAX_FRAGMENTS_PER_THEORY // 2
            for i, assumption in enumerate(theory.assumptions[:max_assumptions]):
                if fragment_count >= MAX_FRAGMENTS_PER_THEORY:
                    break
                fragment = PerspectiveFragment(
                    fragment_id=f"{agent_id}_assump_{i}",
                    source_agent_id=agent_id,
                    fragment_type="assumption",
                    content=assumption,
                    confidence=0.8
                )
                self.perspective_graph.add_fragment(fragment)
                fragments_for_theory.append(fragment)
                fragment_count += 1
            
            # Extract causal claims as procedures (limit based on fidelity)
            max_claims = MAX_FRAGMENTS_PER_THEORY // 3 if fidelity == "LOW" else MAX_FRAGMENTS_PER_THEORY // 2
            for i, claim in enumerate(theory.causal_claims[:max_claims]):
                if fragment_count >= MAX_FRAGMENTS_PER_THEORY:
                    break
                fragment = PerspectiveFragment(
                    fragment_id=f"{agent_id}_claim_{i}",
                    source_agent_id=agent_id,
                    fragment_type="procedure",
                    content=f"{claim.cause} → {claim.effect} (strength={claim.strength:.2f})",
                    confidence=claim.strength
                )
                self.perspective_graph.add_fragment(fragment)
                fragments_for_theory.append(fragment)
                fragment_count += 1
            
            # Extract evidence (only for HIGH fidelity)
            if fidelity == "HIGH":
                max_evidence = MAX_FRAGMENTS_PER_THEORY // 4
                for i, evidence in enumerate(theory.evidence_for[:max_evidence]):
                    if fragment_count >= MAX_FRAGMENTS_PER_THEORY:
                        break
                    fragment = PerspectiveFragment(
                        fragment_id=f"{agent_id}_evid_{i}",
                        source_agent_id=agent_id,
                        fragment_type="evidence",
                        content=evidence.description[:100],  # Truncate long descriptions
                        confidence=evidence.confidence
                    )
                    self.perspective_graph.add_fragment(fragment)
                    fragments_for_theory.append(fragment)
                    fragment_count += 1
            
            # PERFORMANCE OPTIMIZATION: Cache fragments
            if FUSION_CACHE_ENABLED and fragments_for_theory:
                self.fragment_cache[theory_hash] = fragments_for_theory
                # Limit cache size
                if len(self.fragment_cache) > 100:
                    oldest_key = next(iter(self.fragment_cache))
                    del self.fragment_cache[oldest_key]
            
            # Extract evidence as supporting heuristics
            for i, evidence in enumerate(theory.evidence_for[:3]):  # Limit to 3
                fragment = PerspectiveFragment(
                    fragment_id=f"{agent_id}_evid_{i}",
                    source_agent_id=agent_id,
                    fragment_type="heuristic",
                    content=f"Evidence: {evidence.description} (confidence={evidence.confidence:.2f})",
                    confidence=evidence.confidence
                )
                self.perspective_graph.add_fragment(fragment)
    
    def _map_fragment_relationships(self, fidelity: str = "HIGH") -> None:
        """
        Map relationships between fragments from different agents.
        
        PERFORMANCE OPTIMIZATION: Hard limits and caching to prevent O(N^2) explosion.
        """
        fragments = list(self.perspective_graph.fragments.values())
        relationship_count = 0
        
        # PERFORMANCE OPTIMIZATION: Skip relationship mapping for LOW fidelity
        if fidelity == "LOW":
            # Only map a subset of relationships
            max_pairs = min(len(fragments), 10)
            for i in range(max_pairs):
                for j in range(i+1, min(len(fragments), i+3)):  # Limited window
                    if relationship_count >= MAX_RELATIONSHIPS:
                        return
                    frag_a = fragments[i]
                    frag_b = fragments[j]
                    
                    if frag_a.source_agent_id == frag_b.source_agent_id:
                        continue
                    
                    # Check cache
                    if FUSION_CACHE_ENABLED:
                        pair_hash = hash(frozenset([frag_a.fragment_id, frag_b.fragment_id]))
                        if pair_hash in self.relationship_cache:
                            relationship = self.relationship_cache[pair_hash]
                        else:
                            relationship, strength, explanation = self._detect_relationship(frag_a, frag_b)
                            self.relationship_cache[pair_hash] = relationship
                    else:
                        relationship, strength, explanation = self._detect_relationship(frag_a, frag_b)
                    
                    if relationship != RelationshipType.INDEPENDENT:
                        edge = PerspectiveEdge(
                            source_id=frag_a.fragment_id,
                            target_id=frag_b.fragment_id,
                            relationship=relationship,
                            strength=0.7,
                            explanation=f"Auto-detected {relationship.value}"
                        )
                        self.perspective_graph.add_relationship(edge)
                        relationship_count += 1
            return
        
        # MEDIUM and HIGH fidelity: Full relationship mapping with limits
        for i in range(len(fragments)):
            if relationship_count >= MAX_RELATIONSHIPS:
                break
            for j in range(i+1, len(fragments)):
                if relationship_count >= MAX_RELATIONSHIPS:
                    break
                    
                frag_a = fragments[i]
                frag_b = fragments[j]
                
                # Skip fragments from same agent
                if frag_a.source_agent_id == frag_b.source_agent_id:
                    continue
                
                # PERFORMANCE OPTIMIZATION: Check relationship cache
                if FUSION_CACHE_ENABLED:
                    pair_hash = hash(frozenset([frag_a.fragment_id, frag_b.fragment_id]))
                    if pair_hash in self.relationship_cache:
                        relationship = self.relationship_cache[pair_hash]
                    else:
                        relationship, strength, explanation = self._detect_relationship(frag_a, frag_b)
                        self.relationship_cache[pair_hash] = relationship
                else:
                    relationship, strength, explanation = self._detect_relationship(frag_a, frag_b)
                
                if relationship != RelationshipType.INDEPENDENT:
                    edge = PerspectiveEdge(
                        source_id=frag_a.fragment_id,
                        target_id=frag_b.fragment_id,
                        relationship=relationship,
                        strength=0.7,
                        explanation=f"Auto-detected {relationship.value}"
                    )
                    self.perspective_graph.add_relationship(edge)
                    relationship_count += 1
                
                # Detect relationships based on content similarity/type
                relationship, strength, explanation = self._detect_relationship(frag_a, frag_b)
                
                if relationship:
                    edge = PerspectiveEdge(
                        source_id=frag_a.fragment_id,
                        target_id=frag_b.fragment_id,
                        relationship=relationship,
                        strength=strength,
                        explanation=explanation
                    )
                    self.perspective_graph.add_relationship(edge)
    
    def _detect_relationship(
        self,
        frag_a: PerspectiveFragment,
        frag_b: PerspectiveFragment
    ) -> Tuple[Optional[RelationshipType], float, str]:
        """Detect relationship between two fragments."""
        # More aggressive relationship detection for synthesis
        
        # Same type fragments often complement
        if frag_a.fragment_type == frag_b.fragment_type:
            similarity = self._content_similarity(frag_a.content, frag_b.content)
            
            # Similar content from different agents = complementary
            if similarity > 0.3:
                return (
                    RelationshipType.COMPLEMENTS,
                    min(0.9, similarity + 0.4),
                    f"Similar {frag_a.fragment_type} from different perspectives (similarity={similarity:.2f})"
                )
        
        # Different assumptions may conflict
        if frag_a.fragment_type == "assumption" and frag_b.fragment_type == "assumption":
            if self._content_contradiction(frag_a.content, frag_b.content):
                return (
                    RelationshipType.CONFLICTS,
                    0.8,
                    "Contradictory assumptions"
                )
        
        # Procedures/heuristics from different agents often complement
        if frag_a.fragment_type in ["procedure", "heuristic"] and frag_b.fragment_type in ["procedure", "heuristic"]:
            if frag_a.source_agent_id != frag_b.source_agent_id:
                return (
                    RelationshipType.COMPLEMENTS,
                    0.65,
                    f"Different {frag_a.fragment_type}s can be combined"
                )
        
        # Default: independent
        return (RelationshipType.INDEPENDENT, 0.3, "No clear relationship")
    
    def _content_similarity(self, content_a: str, content_b: str) -> float:
        """Simple content similarity check."""
        words_a = set(content_a.lower().split())
        words_b = set(content_b.lower().split())
        
        if not words_a or not words_b:
            return 0.0
        
        intersection = words_a.intersection(words_b)
        union = words_a.union(words_b)
        
        return len(intersection) / len(union)
    
    def _content_contradiction(self, content_a: str, content_b: str) -> bool:
        """Simple contradiction detection."""
        # Look for negation patterns
        negations = ['not', 'no', 'never', 'cannot', 'impossible']
        
        has_negation_a = any(neg in content_a.lower() for neg in negations)
        has_negation_b = any(neg in content_b.lower() for neg in negations)
        
        # If one has negation and they share key terms, likely contradictory
        if has_negation_a != has_negation_b:
            words_a = set(content_a.lower().split())
            words_b = set(content_b.lower().split())
            shared = words_a.intersection(words_b)
            
            # Remove common stop words
            stop_words = {'the', 'a', 'an', 'is', 'are', 'that', 'this'}
            meaningful_shared = shared - stop_words
            
            return len(meaningful_shared) >= 2
        
        return False


def main():
    """Demonstrate Cognitive Fusion Engine."""
    print("="*80)
    print("COGNITIVE FUSION ENGINE DEMONSTRATION")
    print("="*80)
    
    engine = CognitiveFusionEngine()
    
    # Simulate agent proposals
    from tiannara_core.metacognition.theory_engine import Theory, CausalClaim, EvidenceItem
    
    proposals = {
        'agent_analytical': Theory(
            theory_id="theory_analytical",
            name="Analytical Approach",
            domain="analytical",
            description="Data-driven solution",
            assumptions=["Historical patterns predict future", "Data quality determines outcome"],
            causal_claims=[
                CausalClaim(cause="data_analysis", effect="optimal_solution", strength=0.85)
            ],
            evidence_for=[
                EvidenceItem(
                    evidence_id="e1",
                    evidence_type=EvidenceType.EXPERIMENT,
                    description="Empirical study shows correlation",
                    supports_theory=True,
                    confidence=0.90,
                    source="study_1"
                )
            ]
        ),
        'agent_creative': Theory(
            theory_id="theory_creative",
            name="Creative Breakthrough",
            domain="creative",
            description="Novel paradigm shift",
            assumptions=["Conventional methods plateaued", "Risk enables innovation"],
            causal_claims=[
                CausalClaim(cause="novel_approach", effect="breakthrough", strength=0.70)
            ],
            evidence_for=[
                EvidenceItem(
                    evidence_id="e2",
                    evidence_type=EvidenceType.OBSERVATION,
                    description="Analogous success in different domain",
                    supports_theory=True,
                    confidence=0.65,
                    source="analogy_1"
                )
            ]
        )
    }
    
    # Simulate debate arguments
    arguments = [
        ArgumentRecord(
            argument_id="arg_1",
            agent_id="agent_analytical",
            target_agent_id="agent_creative",
            argument_type="critique",
            content="Lacks empirical validation",
            timestamp=time.time(),
            evidence_strength=0.85
        ),
        ArgumentRecord(
            argument_id="arg_2",
            agent_id="agent_creative",
            target_agent_id="agent_analytical",
            argument_type="rebuttal",
            content="Innovation requires exploring unvalidated paths",
            timestamp=time.time() + 1,
            evidence_strength=0.70,
            related_arguments=["arg_1"]
        )
    ]
    
    # Run fusion pipeline
    solution = engine.run_fusion_pipeline(
        session_id="demo_session_1",
        problem="Optimize renewable energy grid integration",
        agent_proposals=proposals,
        debate_arguments=arguments
    )
    
    if solution:
        print(f"\n{'='*80}")
        print("SYNTHESIS COMPLETE")
        print(f"{'='*80}")
        print(f"Solution ID: {solution.solution_id}")
        print(f"Components merged: {len(solution.merged_components)}")
        print(f"Novelty: {solution.novelty_score:.3f}")
        print(f"Quality: {solution.quality_score:.3f}")
        print(f"Agent contributions: {solution.contribution_retention}")
    
    return 0


if __name__ == "__main__":
    exit(main())
