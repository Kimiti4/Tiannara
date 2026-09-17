"""
SCALABILITY TESTING

Purpose: Test whether Tiannara's collective intelligence scales from 5 to 50-100 agents.

Tests:
1. Performance scaling (throughput vs agent count)
2. Quality scaling (solution quality vs agent count)
3. Coordination overhead (communication costs)
4. Diversity preservation (perspective variety)
5. Consensus formation time

Based on synth.md line 384:
"Increase from 5 to 50-100 agents. Test whether collective intelligence scales 
or suffers coordination overhead."
"""

import sys
import time
import random
from pathlib import Path
from typing import Dict, List, Tuple
from dataclasses import dataclass, field

# Add project root to path
project_root = Path(__file__).parent
sys.path.insert(0, str(project_root))

from tiannara_core.metacognition.theory_engine import Theory, CausalClaim, EvidenceItem, EvidenceType
from tiannara_core.metacognition.cognitive_fusion_engine import CognitiveFusionEngine, ArgumentRecord
from tiannara_core.metacognition.false_evidence_detector import FalseEvidenceDetector


@dataclass
class ScalabilityMetrics:
    """Metrics for scalability testing."""
    
    agent_count: int
    episodes: int
    
    # Performance metrics
    total_time: float = 0.0
    avg_time_per_episode: float = 0.0
    throughput: float = 0.0  # episodes per second
    
    # Quality metrics
    avg_quality: float = 0.0
    max_quality: float = 0.0
    min_quality: float = 1.0
    quality_std: float = 0.0
    
    # Coordination metrics
    avg_arguments_per_episode: float = 0.0
    avg_debate_rounds: float = 0.0
    consensus_formation_time: float = 0.0
    
    # Diversity metrics
    unique_perspectives: int = 0
    perspective_diversity_score: float = 0.0
    
    # Synthesis metrics
    synthesis_rate: float = 0.0
    avg_components_merged: float = 0.0
    
    def calculate_efficiency_score(self) -> float:
        """Calculate overall efficiency score (0.0-1.0)."""
        # Higher is better for quality, diversity, synthesis
        # Lower is better for time (normalized)
        
        quality_factor = self.avg_quality
        diversity_factor = self.perspective_diversity_score
        synthesis_factor = self.synthesis_rate / 100.0
        
        # Time factor (inverse - faster is better)
        # Normalize: assume 1.0 sec/episode is baseline
        time_factor = max(0.0, 1.0 - (self.avg_time_per_episode / 10.0))
        
        efficiency = (
            0.35 * quality_factor +
            0.25 * diversity_factor +
            0.25 * synthesis_factor +
            0.15 * time_factor
        )
        
        return min(1.0, efficiency)


class ScalableAgent:
    """Agent that can operate at different scales."""
    
    def __init__(self, agent_id: str, specialization: str):
        self.agent_id = agent_id
        self.specialization = specialization
    
    def generate_proposal(self, problem: str, episode: int) -> Theory:
        """Generate a theory proposal."""
        # Simulate different specializations
        if "analytical" in self.specialization:
            confidence = random.uniform(0.75, 0.90)
            evidence_count = random.randint(3, 6)
        elif "creative" in self.specialization:
            confidence = random.uniform(0.60, 0.80)
            evidence_count = random.randint(2, 4)
        elif "conservative" in self.specialization:
            confidence = random.uniform(0.80, 0.95)
            evidence_count = random.randint(4, 7)
        else:
            confidence = random.uniform(0.70, 0.85)
            evidence_count = random.randint(3, 5)
        
        return Theory(
            theory_id=f"theory_{self.agent_id}_{episode}",
            name=f"{self.specialization.title()} Proposal {episode}",
            domain="scalability_test",
            description=f"Solution from {self.specialization} agent",
            assumptions=[f"Assumption {i}" for i in range(random.randint(2, 5))],
            causal_claims=[
                CausalClaim(
                    cause=f"Cause {i}",
                    effect=f"Effect {i}",
                    strength=random.uniform(0.6, 0.9)
                )
                for i in range(random.randint(2, 4))
            ],
            evidence_for=[
                EvidenceItem(
                    evidence_id=f"evid_{self.agent_id}_{i}",
                    evidence_type=random.choice(list(EvidenceType)),
                    description=f"Evidence point {i}",
                    supports_theory=True,
                    confidence=confidence,
                    source=f"Source {random.randint(1, 10)}"
                )
                for i in range(evidence_count)
            ]
        )
    
    def generate_argument(self, target_agent_id: str, round_num: int) -> ArgumentRecord:
        """Generate an argument critiquing another agent's proposal."""
        return ArgumentRecord(
            argument_id=f"arg_{self.agent_id}_{target_agent_id}_{round_num}",
            agent_id=self.agent_id,
            target_agent_id=target_agent_id,
            argument_type=random.choice(["support", "critique", "question"]),
            content=f"Argument about {target_agent_id}'s proposal",
            timestamp=time.time(),
            evidence_strength=random.uniform(0.5, 0.9)
        )


class ScalabilityTestOrchestrator:
    """Orchestrates scalability tests across different agent counts."""
    
    def __init__(self):
        self.fusion_engine = CognitiveFusionEngine()
        self.false_evidence_detector = FalseEvidenceDetector()
        self.results: Dict[int, ScalabilityMetrics] = {}
    
    def create_agent_pool(self, agent_count: int) -> List[ScalableAgent]:
        """Create a pool of agents with diverse specializations."""
        specializations = [
            "analytical_data", "analytical_statistics", "analytical_modeling",
            "creative_paradigm", "creative_analogy", "creative_innovation",
            "conservative_safety", "conservative_proven", "conservative_incremental",
            "optimizer_efficiency", "optimizer_cost", "optimizer_performance",
            "integrator_synthesis", "integrator_balance", "integrator_holistic",
            "domain_physics", "domain_biology", "domain_economics",
            "domain_engineering", "domain_ethics",
            "method_quantitative", "method_qualitative", "method_experimental",
            "method_simulation", "method_theoretical",
            "perspective_short_term", "perspective_long_term",
            "perspective_local", "perspective_global",
            "approach_deductive", "approach_inductive", "approach_abductive",
            "style_systematic", "style_intuitive", "style_collaborative",
            "focus_reliability", "focus_innovation", "focus_scalability",
            "focus_sustainability", "focus_resilience",
            "role_validator", "role_challenger", "role_synthesizer",
            "role_explorer", "role_evaluator",
            "level_junior", "level_mid", "level_senior", "level_expert",
            "temporal_immediate", "temporal_near_future", "temporal_far_future",
            "scope_component", "scope_system", "scope_ecosystem",
        ]
        
        # Cycle through specializations
        agents = []
        for i in range(agent_count):
            spec = specializations[i % len(specializations)]
            agents.append(ScalableAgent(f"agent_{i:03d}", spec))
        
        return agents
    
    def run_scale_test(self, agent_count: int, num_episodes: int = 20) -> ScalabilityMetrics:
        """
        Run scalability test for a specific agent count.
        
        Args:
            agent_count: Number of agents to test
            num_episodes: Number of debate episodes
            
        Returns:
            Scalability metrics
        """
        print(f"\n{'='*80}")
        print(f"SCALABILITY TEST: {agent_count} AGENTS")
        print(f"Episodes: {num_episodes}")
        print(f"{'='*80}\n")
        
        agents = self.create_agent_pool(agent_count)
        metrics = ScalabilityMetrics(agent_count=agent_count, episodes=num_episodes)
        
        start_time = time.time()
        
        qualities = []
        total_arguments = 0
        total_components = 0
        synthesis_count = 0
        
        for episode in range(1, num_episodes + 1):
            episode_start = time.time()
            
            # Phase 1: Generate proposals from all agents
            agent_proposals = {}
            for agent in agents:
                proposal = agent.generate_proposal("Optimize renewable energy grid", episode)
                agent_proposals[agent.agent_id] = proposal
            
            # Phase 2: Generate arguments (sample subset for efficiency)
            # At scale, not all agents debate all others (coordination overhead)
            debate_arguments = []
            max_debaters = min(agent_count, 10)  # Cap at 10 debaters per episode
            debaters = random.sample(agents, max_debaters)
            
            for round_num in range(1, 4):  # 3 rounds
                for debater in debaters:
                    targets = random.sample(
                        [a for a in agents if a.agent_id != debater.agent_id],
                        min(2, len(agents) - 1)
                    )
                    for target in targets:
                        arg = debater.generate_argument(target.agent_id, round_num)
                        debate_arguments.append(arg)
            
            total_arguments += len(debate_arguments)
            
            # Phase 3: Run Cognitive Fusion Engine
            synthesized = self.fusion_engine.run_fusion_pipeline(
                session_id=f"scale_{agent_count}_ep_{episode}",
                problem="Optimize renewable energy grid",
                agent_proposals=agent_proposals,
                debate_arguments=debate_arguments,
                verbose=False
            )
            
            episode_time = time.time() - episode_start
            
            if synthesized:
                qualities.append(synthesized.quality_score)
                total_components += len(synthesized.merged_components)
                synthesis_count += 1
                
                # Track unique perspectives
                unique_sources = set()
                for comp in synthesized.merged_components:
                    unique_sources.update(comp.source_fragments)
                metrics.unique_perspectives = max(metrics.unique_perspectives, len(unique_sources))
        
        total_time = time.time() - start_time
        
        # Calculate metrics
        metrics.total_time = total_time
        metrics.avg_time_per_episode = total_time / num_episodes
        metrics.throughput = num_episodes / total_time
        
        if qualities:
            metrics.avg_quality = sum(qualities) / len(qualities)
            metrics.max_quality = max(qualities)
            metrics.min_quality = min(qualities)
            metrics.quality_std = (sum((q - metrics.avg_quality)**2 for q in qualities) / len(qualities)) ** 0.5
        
        metrics.avg_arguments_per_episode = total_arguments / num_episodes
        metrics.avg_debate_rounds = 3.0  # Fixed at 3 rounds
        metrics.consensus_formation_time = metrics.avg_time_per_episode
        
        # Calculate perspective diversity (normalized)
        max_possible_perspectives = agent_count * 3  # 3 rounds * all agents
        metrics.perspective_diversity_score = min(1.0, metrics.unique_perspectives / max(1, max_possible_perspectives))
        
        metrics.synthesis_rate = (synthesis_count / num_episodes) * 100
        metrics.avg_components_merged = total_components / max(1, synthesis_count)
        
        # Print results
        print(f"📊 RESULTS:")
        print(f"   Total Time: {total_time:.2f}s")
        print(f"   Avg Time/Episode: {metrics.avg_time_per_episode:.3f}s")
        print(f"   Throughput: {metrics.throughput:.2f} episodes/sec")
        print(f"   Avg Quality: {metrics.avg_quality:.3f}")
        print(f"   Quality Range: [{metrics.min_quality:.3f}, {metrics.max_quality:.3f}]")
        print(f"   Synthesis Rate: {metrics.synthesis_rate:.1f}%")
        print(f"   Avg Components Merged: {metrics.avg_components_merged:.1f}")
        print(f"   Unique Perspectives: {metrics.unique_perspectives}")
        print(f"   Perspective Diversity: {metrics.perspective_diversity_score:.3f}")
        print(f"   Avg Arguments/Episode: {metrics.avg_arguments_per_episode:.1f}")
        print(f"   Efficiency Score: {metrics.calculate_efficiency_score():.3f}")
        
        self.results[agent_count] = metrics
        return metrics
    
    def run_full_scalability_suite(self) -> Dict[int, ScalabilityMetrics]:
        """Run complete scalability test suite."""
        print("="*80)
        print("SCALABILITY TEST SUITE")
        print("Testing: 5 -> 10 -> 20 -> 50 -> 100 agents")
        print("="*80)
        
        agent_counts = [5, 10, 20, 50, 100]
        
        for count in agent_counts:
            self.run_scale_test(agent_count=count, num_episodes=20)
        
        # Generate comparative analysis
        self._generate_comparative_report()
        
        return self.results
    
    def _generate_comparative_report(self):
        """Generate comparative scalability report."""
        print(f"\n{'='*80}")
        print(f"COMPARATIVE SCALABILITY ANALYSIS")
        print(f"{'='*80}\n")
        
        print(f"{'Agents':<10} {'Time/Ep(s)':<12} {'Throughput':<12} {'Quality':<10} {'Synthesis%':<12} {'Efficiency':<10}")
        print("-"*80)
        
        for count in sorted(self.results.keys()):
            m = self.results[count]
            print(f"{count:<10} {m.avg_time_per_episode:<12.3f} {m.throughput:<12.2f} "
                  f"{m.avg_quality:<10.3f} {m.synthesis_rate:<12.1f} {m.calculate_efficiency_score():<10.3f}")
        
        # Analyze scaling patterns
        print(f"\n{'='*80}")
        print(f"SCALING PATTERNS")
        print(f"{'='*80}\n")
        
        counts = sorted(self.results.keys())
        
        # Time scaling
        print("⏱️  TIME SCALING:")
        for i in range(1, len(counts)):
            prev_count = counts[i-1]
            curr_count = counts[i]
            prev_time = self.results[prev_count].avg_time_per_episode
            curr_time = self.results[curr_count].avg_time_per_episode
            
            if prev_time > 0:
                slowdown = curr_time / prev_time
                print(f"   {prev_count} → {curr_count} agents: {slowdown:.2f}x slower")
        
        # Quality scaling
        print(f"\n📈 QUALITY SCALING:")
        for i in range(1, len(counts)):
            prev_count = counts[i-1]
            curr_count = counts[i]
            prev_quality = self.results[prev_count].avg_quality
            curr_quality = self.results[curr_count].avg_quality
            
            improvement = ((curr_quality - prev_quality) / prev_quality * 100) if prev_quality > 0 else 0
            direction = "improved" if improvement > 0 else "declined"
            print(f"   {prev_count} → {curr_count} agents: Quality {direction} by {abs(improvement):.1f}%")
        
        # Efficiency analysis
        print(f"\n⚡ EFFICIENCY ANALYSIS:")
        best_efficiency_count = max(self.results.keys(), key=lambda c: self.results[c].calculate_efficiency_score())
        best_efficiency = self.results[best_efficiency_count].calculate_efficiency_score()
        
        print(f"   Most Efficient Scale: {best_efficiency_count} agents (efficiency: {best_efficiency:.3f})")
        
        # Identify bottlenecks
        print(f"\n🔍 BOTTLENECK ANALYSIS:")
        
        # Check for diminishing returns
        if len(counts) >= 3:
            small_eff = self.results[counts[0]].calculate_efficiency_score()
            medium_eff = self.results[counts[len(counts)//2]].calculate_efficiency_score()
            large_eff = self.results[counts[-1]].calculate_efficiency_score()
            
            if large_eff < medium_eff < small_eff:
                print(f"   ⚠️  Diminishing returns detected: Efficiency decreases with scale")
            elif large_eff > medium_eff > small_eff:
                print(f"   ✅ Positive scaling: Efficiency improves with scale")
            else:
                print(f"   ➡️  Mixed scaling: Optimal scale exists at intermediate agent count")
        
        # Coordination overhead
        print(f"\n🔄 COORDINATION OVERHEAD:")
        for count in counts:
            m = self.results[count]
            overhead_ratio = m.avg_arguments_per_episode / count if count > 0 else 0
            print(f"   {count} agents: {overhead_ratio:.1f} arguments per agent per episode")
        
        # Recommendations
        print(f"\n{'='*80}")
        print(f"RECOMMENDATIONS")
        print(f"{'='*80}\n")
        
        if best_efficiency_count <= 20:
            print(f"✅ Recommended Scale: 5-{best_efficiency_count} agents")
            print(f"   Rationale: Best efficiency at smaller scale")
        elif best_efficiency_count <= 50:
            print(f"✅ Recommended Scale: 20-{best_efficiency_count} agents")
            print(f"   Rationale: Good balance of quality and performance")
        else:
            print(f"✅ Recommended Scale: 50-{best_efficiency_count} agents")
            print(f"   Rationale: Maximum quality achieved at larger scale")
        
        print(f"\n💡 Key Insights:")
        print(f"   - Collective intelligence {'scales' if self.results[counts[-1]].avg_quality > self.results[counts[0]].avg_quality else 'does not scale'} well")
        print(f"   - Coordination overhead {'is manageable' if self.results[counts[-1]].avg_arguments_per_episode < 100 else 'becomes significant'} at scale")
        print(f"   - Optimal performance at {best_efficiency_count} agents")


def main():
    """Run scalability test suite."""
    orchestrator = ScalabilityTestOrchestrator()
    results = orchestrator.run_full_scalability_suite()
    
    # Determine if scaling is successful
    counts = sorted(results.keys())
    small_quality = results[counts[0]].avg_quality
    large_quality = results[counts[-1]].avg_quality
    
    # Success if quality maintained or improved at scale
    success = large_quality >= small_quality * 0.9  # Within 10% is acceptable
    
    print(f"\n{'='*80}")
    if success:
        print("✅ SCALABILITY TEST SUCCESSFUL")
        print(f"   Quality maintained/improved from {counts[0]} to {counts[-1]} agents")
    else:
        print("⚠️  SCALABILITY TEST NEEDS OPTIMIZATION")
        print(f"   Quality declined from {counts[0]} to {counts[-1]} agents")
    print(f"{'='*80}\n")
    
    return 0 if success else 1


if __name__ == "__main__":
    exit(main())
