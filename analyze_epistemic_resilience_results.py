"""
EPISTEMIC RESILIENCE TEST ANALYSIS FRAMEWORK

Purpose: Systematic framework for analyzing scalability and long-horizon test results.

Based on Auditing.md strategic requirements for measuring:
- Belief Ecology Health
- Recovery capabilities under stress
- Scale-induced degradation patterns
- Long-horizon goal integrity preservation

Usage:
    python analyze_epistemic_resilience_results.py --scalability <json_file> --longhorizon <json_file>
"""

import sys
import json
import argparse
from pathlib import Path
from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass, field


@dataclass
class ScalabilityAnalysis:
    """Analysis of scalability test results."""
    
    # Raw metrics per agent count
    agent_counts: List[int] = field(default_factory=list)
    quality_scores: List[float] = field(default_factory=list)
    throughput_scores: List[float] = field(default_factory=list)
    diversity_scores: List[float] = field(default_factory=list)
    coordination_costs: List[float] = field(default_factory=list)
    
    # Derived metrics
    quality_scaling_factor: float = 0.0  # >1.0 means improves with scale
    throughput_efficiency: float = 0.0   # episodes/sec per agent
    diversity_preservation: float = 0.0  # % of initial diversity maintained
    coordination_overhead: float = 0.0   # cost increase per doubling
    
    # Health indicators
    scale_breakpoint: Optional[int] = None  # Agent count where degradation starts
    optimal_scale: Optional[int] = None     # Best performance point
    max_recommended_scale: Optional[int] = None  # Before severe degradation
    
    def analyze(self):
        """Perform comprehensive scalability analysis."""
        if len(self.agent_counts) < 2:
            return
        
        # Quality scaling
        initial_quality = self.quality_scores[0]
        final_quality = self.quality_scores[-1]
        self.quality_scaling_factor = final_quality / initial_quality if initial_quality > 0 else 0.0
        
        # Throughput efficiency (episodes/sec/agent)
        for i, count in enumerate(self.agent_counts):
            if count > 0 and i < len(self.throughput_scores):
                efficiency = self.throughput_scores[i] / count
                self.throughput_efficiency += efficiency
        self.throughput_efficiency /= len(self.agent_counts) if self.agent_counts else 1
        
        # Diversity preservation
        if self.diversity_scores:
            initial_diversity = self.diversity_scores[0]
            final_diversity = self.diversity_scores[-1]
            self.diversity_preservation = (final_diversity / initial_diversity * 100) if initial_diversity > 0 else 0.0
        
        # Coordination overhead (cost increase per doubling)
        if len(self.coordination_costs) >= 2:
            doublings = 0
            total_cost_increase = 0.0
            for i in range(1, len(self.agent_counts)):
                if self.agent_counts[i] == self.agent_counts[i-1] * 2:
                    cost_ratio = self.coordination_costs[i] / self.coordination_costs[i-1] if self.coordination_costs[i-1] > 0 else 1.0
                    total_cost_increase += cost_ratio
                    doublings += 1
            self.coordination_overhead = total_cost_increase / doublings if doublings > 0 else 1.0
        
        # Identify breakpoints
        self._identify_breakpoints()
    
    def _identify_breakpoints(self):
        """Identify where performance degrades significantly."""
        if len(self.quality_scores) < 3:
            return
        
        # Find first significant drop (>15% from peak)
        peak_quality = max(self.quality_scores)
        peak_idx = self.quality_scores.index(peak_quality)
        
        for i in range(peak_idx + 1, len(self.quality_scores)):
            drop_ratio = (peak_quality - self.quality_scores[i]) / peak_quality
            if drop_ratio > 0.15:
                self.scale_breakpoint = self.agent_counts[i]
                break
        
        # Optimal scale is peak performance point
        self.optimal_scale = self.agent_counts[peak_idx]
        
        # Max recommended scale before severe degradation (>30% drop)
        for i in range(len(self.quality_scores)):
            drop_ratio = (peak_quality - self.quality_scores[i]) / peak_quality
            if drop_ratio > 0.30:
                self.max_recommended_scale = self.agent_counts[i-1] if i > 0 else self.agent_counts[0]
                break
        
        if not self.max_recommended_scale:
            self.max_recommended_scale = self.agent_counts[-1]
    
    def get_health_assessment(self) -> Dict:
        """Get overall scalability health assessment."""
        issues = []
        strengths = []
        
        # Quality assessment
        if self.quality_scaling_factor >= 0.95:
            strengths.append(f"Quality maintained at scale ({self.quality_scaling_factor:.2f}x)")
        elif self.quality_scaling_factor >= 0.85:
            issues.append(f"Minor quality degradation at scale ({self.quality_scaling_factor:.2f}x)")
        else:
            issues.append(f"Significant quality degradation at scale ({self.quality_scaling_factor:.2f}x)")
        
        # Diversity assessment
        if self.diversity_preservation >= 80:
            strengths.append(f"Diversity well-preserved ({self.diversity_preservation:.1f}%)")
        elif self.diversity_preservation >= 60:
            issues.append(f"Moderate diversity loss ({self.diversity_preservation:.1f}%)")
        else:
            issues.append(f"Severe diversity collapse ({self.diversity_preservation:.1f}%)")
        
        # Coordination assessment
        if self.coordination_overhead <= 1.5:
            strengths.append(f"Low coordination overhead ({self.coordination_overhead:.2f}x per doubling)")
        elif self.coordination_overhead <= 2.5:
            issues.append(f"Moderate coordination costs ({self.coordination_overhead:.2f}x per doubling)")
        else:
            issues.append(f"High coordination overhead ({self.coordination_overhead:.2f}x per doubling)")
        
        return {
            'status': 'HEALTHY' if len(issues) == 0 else ('WARNING' if len(issues) <= 2 else 'CRITICAL'),
            'strengths': strengths,
            'issues': issues,
            'optimal_scale': self.optimal_scale,
            'max_recommended_scale': self.max_recommended_scale,
            'scale_breakpoint': self.scale_breakpoint
        }


@dataclass
class LongHorizonAnalysis:
    """Analysis of long-horizon mission test results."""
    
    # Mission parameters
    total_steps: int = 0
    agent_count: int = 0
    mission_goal: str = ""
    
    # Outcome metrics
    goal_completion_rate: float = 0.0
    intent_drift_per_100_steps: float = 0.0
    synthesis_frequency: float = 0.0
    quality_improvement: float = 0.0  # Final vs Initial
    recovery_events: int = 0
    avg_recovery_steps: float = 0.0
    
    # Epistemic health over time
    belief_volatility_timeline: List[float] = field(default_factory=list)
    contradiction_load_timeline: List[float] = field(default_factory=list)
    confidence_stability: float = 0.0
    
    # Critical events
    false_belief_injections: int = 0
    successful_quarantines: int = 0
    echo_chamber_detections: int = 0
    hypothesis_competitions: int = 0
    
    def analyze(self):
        """Perform comprehensive long-horizon analysis."""
        # Calculate derived metrics
        if self.total_steps > 0:
            self.intent_drift_per_100_steps = (self.intent_drift_per_100_steps / self.total_steps) * 100
        
        # Confidence stability (inverse of volatility)
        if self.belief_volatility_timeline:
            avg_volatility = sum(self.belief_volatility_timeline) / len(self.belief_volatility_timeline)
            self.confidence_stability = 1.0 - avg_volatility
        
        # Quarantine effectiveness
        if self.false_belief_injections > 0:
            quarantine_rate = self.successful_quarantines / self.false_belief_injections
        else:
            quarantine_rate = 1.0
    
    def get_health_assessment(self) -> Dict:
        """Get overall long-horizon health assessment."""
        issues = []
        strengths = []
        
        # Goal completion
        if self.goal_completion_rate >= 0.90:
            strengths.append(f"Excellent goal completion ({self.goal_completion_rate*100:.1f}%)")
        elif self.goal_completion_rate >= 0.75:
            issues.append(f"Moderate goal completion ({self.goal_completion_rate*100:.1f}%)")
        else:
            issues.append(f"Poor goal completion ({self.goal_completion_rate*100:.1f}%)")
        
        # Intent preservation
        if self.intent_drift_per_100_steps <= 0.01:
            strengths.append(f"Exceptional intent preservation (drift: {self.intent_drift_per_100_steps:.4f}/100 steps)")
        elif self.intent_drift_per_100_steps <= 0.05:
            issues.append(f"Acceptable intent drift ({self.intent_drift_per_100_steps:.4f}/100 steps)")
        else:
            issues.append(f"Excessive intent drift ({self.intent_drift_per_100_steps:.4f}/100 steps)")
        
        # Synthesis frequency
        if self.synthesis_frequency >= 0.70:
            strengths.append(f"High emergent synthesis rate ({self.synthesis_frequency*100:.1f}%)")
        elif self.synthesis_frequency >= 0.50:
            issues.append(f"Moderate synthesis rate ({self.synthesis_frequency*100:.1f}%)")
        else:
            issues.append(f"Low synthesis rate ({self.synthesis_frequency*100:.1f}%)")
        
        # Quality improvement
        if self.quality_improvement >= 0.20:
            strengths.append(f"Strong emergent improvement (+{self.quality_improvement*100:.1f}%)")
        elif self.quality_improvement >= 0.10:
            issues.append(f"Modest quality improvement (+{self.quality_improvement*100:.1f}%)")
        else:
            issues.append(f"Minimal quality improvement (+{self.quality_improvement*100:.1f}%)")
        
        # Recovery capability
        if self.recovery_events > 0:
            if self.avg_recovery_steps <= 10:
                strengths.append(f"Fast recovery from drift (avg {self.avg_recovery_steps:.1f} steps)")
            else:
                issues.append(f"Slow recovery from drift (avg {self.avg_recovery_steps:.1f} steps)")
        else:
            strengths.append("No drift events requiring recovery")
        
        # Epistemic resilience events
        if self.successful_quarantines > 0:
            strengths.append(f"Successfully quarantined {self.successful_quarantines} false beliefs")
        
        if self.echo_chamber_detections > 0:
            strengths.append(f"Detected and prevented {self.echo_chamber_detections} echo chambers")
        
        if self.hypothesis_competitions > 0:
            strengths.append(f"Maintained {self.hypothesis_competitions} competing hypotheses")
        
        return {
            'status': 'HEALTHY' if len(issues) == 0 else ('WARNING' if len(issues) <= 2 else 'CRITICAL'),
            'strengths': strengths,
            'issues': issues,
            'mission_completed': self.goal_completion_rate >= 0.90,
            'intent_preserved': self.intent_drift_per_100_steps <= 0.01,
            'synthesis_active': self.synthesis_frequency >= 0.70,
            'improved_over_time': self.quality_improvement >= 0.20
        }


class EpistemicResilienceAnalyzer:
    """Comprehensive analyzer for epistemic resilience test results."""
    
    def __init__(self):
        self.scalability_analysis = ScalabilityAnalysis()
        self.longhorizon_analysis = LongHorizonAnalysis()
    
    def load_scalability_results(self, json_file: str):
        """Load scalability test results from JSON file."""
        with open(json_file, 'r') as f:
            data = json.load(f)
        
        for result in data.get('results', []):
            self.scalability_analysis.agent_counts.append(result['agent_count'])
            self.scalability_analysis.quality_scores.append(result['avg_quality'])
            self.scalability_analysis.throughput_scores.append(result['throughput'])
            self.scalability_analysis.diversity_scores.append(result['perspective_diversity_score'])
            self.scalability_analysis.coordination_costs.append(result.get('coordination_cost', 0.0))
        
        self.scalability_analysis.analyze()
    
    def load_longhorizon_results(self, json_file: str):
        """Load long-horizon test results from JSON file."""
        with open(json_file, 'r') as f:
            data = json.load(f)
        
        self.longhorizon_analysis.total_steps = data.get('total_steps', 0)
        self.longhorizon_analysis.agent_count = data.get('agent_count', 0)
        self.longhorizon_analysis.mission_goal = data.get('mission_goal', '')
        self.longhorizon_analysis.goal_completion_rate = data.get('goal_completion_rate', 0.0)
        self.longhorizon_analysis.intent_drift_per_100_steps = data.get('intent_drift', 0.0)
        self.longhorizon_analysis.synthesis_frequency = data.get('synthesis_frequency', 0.0)
        self.longhorizon_analysis.quality_improvement = data.get('quality_improvement', 0.0)
        self.longhorizon_analysis.recovery_events = data.get('recovery_events', 0)
        self.longhorizon_analysis.avg_recovery_steps = data.get('avg_recovery_steps', 0.0)
        self.longhorizon_analysis.belief_volatility_timeline = data.get('belief_volatility_timeline', [])
        self.longhorizon_analysis.contradiction_load_timeline = data.get('contradiction_load_timeline', [])
        self.longhorizon_analysis.false_belief_injections = data.get('false_belief_injections', 0)
        self.longhorizon_analysis.successful_quarantines = data.get('successful_quarantines', 0)
        self.longhorizon_analysis.echo_chamber_detections = data.get('echo_chamber_detections', 0)
        self.longhorizon_analysis.hypothesis_competitions = data.get('hypothesis_competitions', 0)
        
        self.longhorizon_analysis.analyze()
    
    def generate_comprehensive_report(self) -> str:
        """Generate comprehensive analysis report."""
        report = []
        report.append("=" * 80)
        report.append("EPISTEMIC RESILIENCE TEST ANALYSIS REPORT")
        report.append("=" * 80)
        report.append("")
        
        # Scalability Analysis
        report.append("-" * 80)
        report.append("SCALABILITY ANALYSIS")
        report.append("-" * 80)
        
        scale_health = self.scalability_analysis.get_health_assessment()
        report.append(f"\nStatus: {scale_health['status']}")
        report.append(f"\nStrengths:")
        for strength in scale_health['strengths']:
            report.append(f"  ✅ {strength}")
        
        if scale_health['issues']:
            report.append(f"\nIssues:")
            for issue in scale_health['issues']:
                report.append(f"  ⚠️  {issue}")
        
        report.append(f"\nKey Metrics:")
        report.append(f"  Quality Scaling Factor: {self.scalability_analysis.quality_scaling_factor:.3f}x")
        report.append(f"  Throughput Efficiency: {self.scalability_analysis.throughput_efficiency:.3f} eps/agent")
        report.append(f"  Diversity Preservation: {self.scalability_analysis.diversity_preservation:.1f}%")
        report.append(f"  Coordination Overhead: {self.scalability_analysis.coordination_overhead:.2f}x per doubling")
        
        if self.scalability_analysis.optimal_scale:
            report.append(f"\nRecommendations:")
            report.append(f"  Optimal Scale: {self.scalability_analysis.optimal_scale} agents")
            if self.scalability_analysis.max_recommended_scale:
                report.append(f"  Max Recommended: {self.scalability_analysis.max_recommended_scale} agents")
            if self.scalability_analysis.scale_breakpoint:
                report.append(f"  Degradation Starts: {self.scalability_analysis.scale_breakpoint} agents")
        
        report.append("")
        
        # Long-Horizon Analysis
        report.append("-" * 80)
        report.append("LONG-HORIZON MISSION ANALYSIS")
        report.append("-" * 80)
        
        lh_health = self.longhorizon_analysis.get_health_assessment()
        report.append(f"\nMission: {self.longhorizon_analysis.mission_goal}")
        report.append(f"Duration: {self.longhorizon_analysis.total_steps} steps with {self.longhorizon_analysis.agent_count} agents")
        report.append(f"\nStatus: {lh_health['status']}")
        
        report.append(f"\nSuccess Criteria:")
        report.append(f"  Goal Completion: {'✅ PASS' if lh_health['mission_completed'] else '❌ FAIL'} ({self.longhorizon_analysis.goal_completion_rate*100:.1f}%, target: ≥90%)")
        report.append(f"  Intent Preservation: {'✅ PASS' if lh_health['intent_preserved'] else '❌ FAIL'} (drift: {self.longhorizon_analysis.intent_drift_per_100_steps:.4f}/100 steps, target: ≤0.01)")
        report.append(f"  Synthesis Frequency: {'✅ PASS' if lh_health['synthesis_active'] else '❌ FAIL'} ({self.longhorizon_analysis.synthesis_frequency*100:.1f}%, target: ≥70%)")
        report.append(f"  Quality Improvement: {'✅ PASS' if lh_health['improved_over_time'] else '❌ FAIL'} (+{self.longhorizon_analysis.quality_improvement*100:.1f}%, target: ≥20%)")
        
        report.append(f"\nStrengths:")
        for strength in lh_health['strengths']:
            report.append(f"  ✅ {strength}")
        
        if lh_health['issues']:
            report.append(f"\nIssues:")
            for issue in lh_health['issues']:
                report.append(f"  ⚠️  {issue}")
        
        report.append("")
        
        # Overall Assessment
        report.append("-" * 80)
        report.append("OVERALL EPISTEMIC RESILIENCE ASSESSMENT")
        report.append("-" * 80)
        
        overall_status = "HEALTHY" if (scale_health['status'] == 'HEALTHY' and lh_health['status'] == 'HEALTHY') else "NEEDS ATTENTION"
        report.append(f"\nOverall Status: {overall_status}")
        
        if overall_status == "HEALTHY":
            report.append("\n✅ Tiannara's epistemic resilience architecture is validated for production use.")
            report.append("   - Scales effectively to tested agent counts")
            report.append("   - Maintains goal integrity over extended missions")
            report.append("   - Successfully detects and isolates false beliefs")
            report.append("   - Preserves epistemic diversity under stress")
        else:
            report.append("\n⚠️  Some aspects require optimization before full deployment.")
            report.append("   Review issues above and consider:")
            report.append("   - Adjusting coordination mechanisms for larger scales")
            report.append("   - Strengthening intent preservation mechanisms")
            report.append("   - Enhancing synthesis frequency in multi-agent debates")
        
        report.append("")
        report.append("=" * 80)
        
        return "\n".join(report)
    
    def save_report(self, output_file: str):
        """Save analysis report to file."""
        report = self.generate_comprehensive_report()
        with open(output_file, 'w') as f:
            f.write(report)
        print(f"Report saved to: {output_file}")


def main():
    """Main entry point for analysis."""
    parser = argparse.ArgumentParser(description='Analyze epistemic resilience test results')
    parser.add_argument('--scalability', type=str, help='Path to scalability test JSON results')
    parser.add_argument('--longhorizon', type=str, help='Path to long-horizon test JSON results')
    parser.add_argument('--output', type=str, default='EPISTEMIC_RESILIENCE_ANALYSIS_REPORT.md',
                       help='Output file path for analysis report')
    
    args = parser.parse_args()
    
    analyzer = EpistemicResilienceAnalyzer()
    
    if args.scalability:
        print(f"Loading scalability results from: {args.scalability}")
        analyzer.load_scalability_results(args.scalability)
    
    if args.longhorizon:
        print(f"Loading long-horizon results from: {args.longhorizon}")
        analyzer.load_longhorizon_results(args.longhorizon)
    
    # Generate and display report
    report = analyzer.generate_comprehensive_report()
    print("\n" + report)
    
    # Save to file
    analyzer.save_report(args.output)
    
    return 0


if __name__ == "__main__":
    exit(main())
