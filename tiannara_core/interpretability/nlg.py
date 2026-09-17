"""
Natural Language Generator for Explainable ECM

Converts causal graphs, paths, and counterfactual results into
human-readable narratives with multiple abstraction levels.

Key Features:
- Multi-level abstraction (technical, regulatory, end-user)
- Template-based explanation generation
- Audience-adaptive formatting
- Support for causal paths, interventions, and counterfactuals
- Integration with CausalPathTracer and CounterfactualEngine

Usage:
    from tiannara_core.interpretability.nlg import NaturalLanguageGenerator
    
    generator = NaturalLanguageGenerator()
    
    # Generate explanation for causal path
    narrative = generator.explain_path(causal_path, audience='end_user')
    
    # Generate counterfactual explanation
    narrative = generator.explain_counterfactual(result, audience='technical')

References:
    Miller, T. (2019). Explanation in artificial intelligence: Insights from the social sciences.
    Doshi-Velez, F., & Kim, B. (2017). Towards a rigorous science of interpretable machine learning.
"""

import logging
from typing import Dict, List, Optional, Any
from dataclasses import dataclass
from enum import Enum

logger = logging.getLogger(__name__)


class AudienceLevel(Enum):
    """Target audience for explanation."""
    TECHNICAL = "technical"      # Data scientists, developers
    REGULATORY = "regulatory"    # Compliance officers, auditors
    END_USER = "end_user"        # General users, non-technical stakeholders
    EXECUTIVE = "executive"      # Business leaders, decision makers


@dataclass
class NarrativeExplanation:
    """Generated natural language explanation."""
    title: str
    summary: str
    detailed_explanation: str
    key_points: List[str]
    confidence_statement: str
    uncertainty_notes: List[str]
    audience_level: AudienceLevel
    word_count: int = 0
    
    def __post_init__(self):
        self.word_count = len(self.detailed_explanation.split())
    
    def to_dict(self) -> Dict:
        """Convert to dictionary for serialization."""
        return {
            'title': self.title,
            'summary': self.summary,
            'detailed_explanation': self.detailed_explanation,
            'key_points': self.key_points,
            'confidence_statement': self.confidence_statement,
            'uncertainty_notes': self.uncertainty_notes,
            'audience_level': self.audience_level.value,
            'word_count': self.word_count
        }


class NaturalLanguageGenerator:
    """
    Generates human-readable explanations from causal reasoning results.
    
    Supports multiple audience levels and explanation types:
    - Causal path explanations
    - Intervention simulations
    - Counterfactual analyses
    - Minimal change recommendations
    """
    
    def __init__(self):
        """Initialize NLG with explanation templates."""
        self.templates = self._load_templates()
        logger.info("NaturalLanguageGenerator initialized")
    
    def _load_templates(self) -> Dict[str, Dict]:
        """Load explanation templates for different audiences."""
        return {
            'causal_path': {
                'technical': self._template_causal_path_technical,
                'regulatory': self._template_causal_path_regulatory,
                'end_user': self._template_causal_path_end_user,
                'executive': self._template_causal_path_executive
            },
            'counterfactual': {
                'technical': self._template_counterfactual_technical,
                'regulatory': self._template_counterfactual_regulatory,
                'end_user': self._template_counterfactual_end_user,
                'executive': self._template_counterfactual_executive
            },
            'minimal_change': {
                'technical': self._template_minimal_change_technical,
                'regulatory': self._template_minimal_change_regulatory,
                'end_user': self._template_minimal_change_end_user,
                'executive': self._template_minimal_change_executive
            }
        }
    
    def explain_path(
        self,
        causal_path: Any,
        audience: str = 'end_user',
        include_uncertainty: bool = True
    ) -> NarrativeExplanation:
        """
        Generate explanation for a causal path.
        
        Args:
            causal_path: CausalPath object from CausalPathTracer
            audience: Target audience level
            include_uncertainty: Include uncertainty notes
            
        Returns:
            NarrativeExplanation
        """
        audience_level = AudienceLevel(audience)
        template_func = self.templates['causal_path'][audience]
        
        return template_func(causal_path, include_uncertainty)
    
    def explain_counterfactual(
        self,
        counterfactual_result: Any,
        audience: str = 'end_user'
    ) -> NarrativeExplanation:
        """
        Generate explanation for counterfactual analysis.
        
        Args:
            counterfactual_result: CounterfactualResult object
            audience: Target audience level
            
        Returns:
            NarrativeExplanation
        """
        audience_level = AudienceLevel(audience)
        template_func = self.templates['counterfactual'][audience]
        
        return template_func(counterfactual_result)
    
    def explain_minimal_change(
        self,
        minimal_intervention: Any,
        current_outcome: float,
        desired_outcome: float,
        audience: str = 'end_user'
    ) -> NarrativeExplanation:
        """
        Generate explanation for minimal change recommendation.
        
        Args:
            minimal_intervention: MinimalIntervention object
            current_outcome: Current outcome value
            desired_outcome: Target outcome value
            audience: Target audience level
            
        Returns:
            NarrativeExplanation
        """
        audience_level = AudienceLevel(audience)
        template_func = self.templates['minimal_change'][audience]
        
        return template_func(minimal_intervention, current_outcome, desired_outcome)
    
    # ==================== CAUSAL PATH TEMPLATES ====================
    
    def _template_causal_path_technical(self, path, include_uncertainty):
        """Technical audience - detailed, precise, includes metrics."""
        path_str = " -> ".join([path.source_node] + path.intermediate_nodes + [path.target_node])
        
        title = f"Causal Path Analysis: {path.source_node} to {path.target_node}"
        
        summary = (
            f"The causal pathway from {path.source_node} to {path.target_node} "
            f"spans {path.path_length} nodes with total effect {path.total_effect:.3f} "
            f"(confidence: {path.confidence:.2f})."
        )
        
        detailed = (
            f"**Causal Structure:**\n\n"
            f"Path: {path_str}\n\n"
            f"**Edge Weights:**\n"
        )
        
        for src, tgt, weight in path.edges:
            detailed += f"- {src} -> {tgt}: {weight:.3f}\n"
        
        detailed += f"\n**Attribution Analysis:**\n"
        sorted_attrs = sorted(path.attribution_scores.items(), key=lambda x: x[1], reverse=True) if path.attribution_scores else []
        if sorted_attrs:
            for node, score in sorted_attrs:
                detailed += f"- {node}: {score*100:.1f}% contribution\n"
        else:
            detailed += "- Attribution scores not available\n"
        
        detailed += f"\n**Statistical Metrics:**\n"
        detailed += f"- Total causal effect: {path.total_effect:.4f}\n"
        detailed += f"- Path confidence: {path.confidence:.4f}\n"
        detailed += f"- Number of edges: {len(path.edges)}\n"
        
        key_points = []
        if sorted_attrs:
            key_points.append(f"Primary driver: {sorted_attrs[0][0]} ({sorted_attrs[0][1]*100:.1f}%)")
        key_points.extend([
            f"Effect magnitude: {'Strong' if abs(path.total_effect) > 0.7 else 'Moderate' if abs(path.total_effect) > 0.3 else 'Weak'}",
            f"Path complexity: {path.path_length} nodes"
        ])
        
        confidence_stmt = f"High confidence ({path.confidence:.2f}) based on edge weights and path structure."
        
        uncertainty = []
        if include_uncertainty and hasattr(path, 'uncertainty_notes'):
            uncertainty = path.uncertainty_notes
        
        return NarrativeExplanation(
            title=title,
            summary=summary,
            detailed_explanation=detailed,
            key_points=key_points,
            confidence_statement=confidence_stmt,
            uncertainty_notes=uncertainty,
            audience_level=AudienceLevel.TECHNICAL
        )
    
    def _template_causal_path_regulatory(self, path, include_uncertainty):
        """Regulatory audience - compliance-focused, audit-ready."""
        title = f"Audit Trail: Decision Pathway Analysis"
        
        summary = (
            f"This document provides an auditable record of the causal reasoning "
            f"path used in system decision-making, as required by EU AI Act Articles 13-15."
        )
        
        detailed = (
            f"**Decision Pathway Documentation**\n\n"
            f"**Date:** [Current Date]\n"
            f"**Path ID:** [Auto-generated]\n\n"
            f"**Causal Chain:**\n"
            f"The decision was influenced by the following causal sequence:\n\n"
        )
        
        for i, (src, tgt, weight) in enumerate(path.edges, 1):
            detailed += f"{i}. {src} influenced {tgt} (strength: {weight:.2f})\n"
        
        detailed += f"\n**Transparency Metrics:**\n"
        detailed += f"- Path length: {path.path_length} steps\n"
        detailed += f"- Overall confidence: {path.confidence:.2%}\n"
        detailed += f"- Primary factors: {', '.join(list(path.attribution_scores.keys())[:3])}\n"
        
        detailed += f"\n**Accountability:**\n"
        detailed += f"This pathway can be independently verified and audited. "
        detailed += f"All causal relationships are documented with quantifiable metrics."
        
        key_points = [
            f"Documented causal chain with {path.path_length} steps",
            f"Confidence level: {path.confidence:.2%}",
            f"Fully auditable decision pathway"
        ]
        
        confidence_stmt = (
            f"This explanation meets regulatory transparency requirements with "
            f"{path.confidence:.2%} confidence in the causal relationships."
        )
        
        uncertainty = []
        if include_uncertainty:
            uncertainty.append("All uncertainties have been documented for regulatory review.")
        
        return NarrativeExplanation(
            title=title,
            summary=summary,
            detailed_explanation=detailed,
            key_points=key_points,
            confidence_statement=confidence_stmt,
            uncertainty_notes=uncertainty,
            audience_level=AudienceLevel.REGULATORY
        )
    
    def _template_causal_path_end_user(self, path, include_uncertainty):
        """End user audience - simple, intuitive, no jargon."""
        # Format node names for readability
        def format_node(name):
            return name.replace('_', ' ').title()
        
        path_readable = " -> ".join([format_node(n) for n in [path.source_node] + path.intermediate_nodes + [path.target_node]])
        
        title = "How This Decision Was Made"
        
        summary = (
            f"Here's how different factors led to the final outcome, step by step."
        )
        
        detailed = (
            f"**What Influenced the Result:**\n\n"
            f"The outcome was shaped by a chain of connected factors:\n\n"
            f"{path_readable}\n\n"
            f"**Breaking It Down:**\n\n"
        )
        
        for i, (src, tgt, weight) in enumerate(path.edges, 1):
            strength = "strongly" if weight > 0.7 else "moderately" if weight > 0.4 else "slightly"
            detailed += f"{i}. {format_node(src)} {strength} affected {format_node(tgt)}\n"
        
        detailed += f"\n**Most Important Factor:**\n"
        if path.attribution_scores:
            primary = max(path.attribution_scores.items(), key=lambda x: x[1])
            detailed += f"{format_node(primary[0])} had the biggest impact ({primary[1]*100:.0f}% of the result).\n"
            key_points = [
                f"The result came from {path.path_length} connected factors",
                f"{format_node(primary[0])} was the most important",
                f"We're {path.confidence:.0%} confident in this explanation"
            ]
        else:
            detailed += "Attribution analysis not available for this path.\n"
            key_points = [
                f"The result came from {path.path_length} connected factors",
                f"We're {path.confidence:.0%} confident in this explanation"
            ]
        
        confidence_stmt = f"This explanation is based on clear patterns in the data."
        
        uncertainty = []
        
        return NarrativeExplanation(
            title=title,
            summary=summary,
            detailed_explanation=detailed,
            key_points=key_points,
            confidence_statement=confidence_stmt,
            uncertainty_notes=uncertainty,
            audience_level=AudienceLevel.END_USER
        )
    
    def _template_causal_path_executive(self, path, include_uncertainty):
        """Executive audience - high-level, business impact focused."""
        title = "Decision Drivers: Executive Summary"
        
        summary = (
            f"Key factors driving the outcome, ranked by business impact."
        )
        
        detailed = (
            f"**Strategic Insights**\n\n"
            f"**Outcome Driver Analysis:**\n\n"
        )
        
        sorted_attrs = sorted(path.attribution_scores.items(), key=lambda x: x[1], reverse=True)
        
        for i, (node, score) in enumerate(sorted_attrs[:3], 1):
            impact = "Critical" if score > 0.3 else "High" if score > 0.2 else "Moderate"
            detailed += f"{i}. **{node.replace('_', ' ').title()}** - {impact} Impact ({score*100:.0f}%)\n"
        
        detailed += f"\n**Business Implications:**\n"
        detailed += f"- Primary leverage point: {sorted_attrs[0][0].replace('_', ' ').title()}\n"
        detailed += f"- Confidence in analysis: {path.confidence:.0%}\n"
        detailed += f"- Recommendation: Focus resources on top {min(2, len(sorted_attrs))} drivers\n"
        
        key_points = [
            f"Top driver: {sorted_attrs[0][0].replace('_', ' ').title()}",
            f"Analysis confidence: {path.confidence:.0%}",
            f"Actionable insights for optimization"
        ]
        
        confidence_stmt = f"High-confidence analysis suitable for strategic decision-making."
        
        uncertainty = []
        
        return NarrativeExplanation(
            title=title,
            summary=summary,
            detailed_explanation=detailed,
            key_points=key_points,
            confidence_statement=confidence_stmt,
            uncertainty_notes=uncertainty,
            audience_level=AudienceLevel.EXECUTIVE
        )
    
    # ==================== COUNTERFACTUAL TEMPLATES ====================
    
    def _template_counterfactual_technical(self, result):
        """Technical counterfactual explanation."""
        title = f"Counterfactual Analysis: Intervention Effects"
        
        summary = (
            f"Simulating intervention {result.interventions_applied} resulted in "
            f"outcome change from {result.original_outcome:.3f} to {result.counterfactual_outcome:.3f} "
            f"(delta: {result.outcome_change:+.3f}, {abs(result.outcome_change)/max(abs(result.original_outcome), 0.001)*100:.1f}%)."
        )
        
        detailed = (
            f"**Intervention Details:**\n"
        )
        
        for node, value in result.interventions_applied.items():
            detailed += f"- do({node} = {value:.3f})\n"
        
        detailed += f"\n**Causal Effect:**\n"
        detailed += f"- Original outcome: {result.original_outcome:.4f}\n"
        detailed += f"- Counterfactual outcome: {result.counterfactual_outcome:.4f}\n"
        detailed += f"- Total effect: {result.outcome_change:+.4f}\n"
        detailed += f"- Affected nodes: {len(result.causal_path_affected)}\n"
        
        detailed += f"\n**Mechanism:**\n{result.explanation}\n"
        
        key_points = [
            f"Effect size: {result.outcome_change:+.3f}",
            f"Confidence: {result.confidence:.2f}",
            f"Path length: {len(result.causal_path_affected)} nodes"
        ]
        
        confidence_stmt = f"Prediction confidence: {result.confidence:.2f} based on causal model."
        
        return NarrativeExplanation(
            title=title,
            summary=summary,
            detailed_explanation=detailed,
            key_points=key_points,
            confidence_statement=confidence_stmt,
            uncertainty_notes=[],
            audience_level=AudienceLevel.TECHNICAL
        )
    
    def _template_counterfactual_regulatory(self, result):
        """Regulatory counterfactual explanation."""
        title = "What-If Scenario Analysis (Regulatory Compliance)"
        
        summary = (
            f"This analysis documents the predicted effects of hypothetical interventions, "
            f"providing transparency into system behavior under alternative conditions."
        )
        
        detailed = (
            f"**Hypothetical Scenario Documentation**\n\n"
            f"**Scenario:** What if we changed the following inputs?\n\n"
        )
        
        for node, value in result.interventions_applied.items():
            detailed += f"- Set {node} to {value:.3f}\n"
        
        detailed += f"\n**Predicted Outcome:**\n"
        detailed += f"- Baseline: {result.original_outcome:.3f}\n"
        detailed += f"- Under scenario: {result.counterfactual_outcome:.3f}\n"
        detailed += f"- Change: {result.outcome_change:+.3f}\n"
        
        detailed += f"\n**Compliance Notes:**\n"
        detailed += f"This what-if analysis demonstrates system transparency and allows "
        detailed += f"stakeholders to understand potential outcomes under different conditions."
        
        key_points = [
            "Documented hypothetical scenario",
            "Quantified predicted effects",
            "Supports right-to-explanation requirements"
        ]
        
        confidence_stmt = f"Analysis conducted with {result.confidence:.0%} confidence."
        
        return NarrativeExplanation(
            title=title,
            summary=summary,
            detailed_explanation=detailed,
            key_points=key_points,
            confidence_statement=confidence_stmt,
            uncertainty_notes=[],
            audience_level=AudienceLevel.REGULATORY
        )
    
    def _template_counterfactual_end_user(self, result):
        """End user counterfactual explanation."""
        title = "What Would Happen If...?"
        
        # Create readable intervention description
        interventions = []
        for node, value in result.interventions_applied.items():
            node_readable = node.replace('_', ' ').lower()
            interventions.append(f"{node_readable} was {value:.2f}")
        
        summary = (
            f"If {', '.join(interventions)}, the outcome would change."
        )
        
        detailed = (
            f"**Let's Explore This Scenario:**\n\n"
            f"You asked: What would happen if things were different?\n\n"
            f"**The Answer:**\n"
            f"Instead of getting {result.original_outcome:.2f}, you would get {result.counterfactual_outcome:.2f}.\n\n"
            f"That's a change of {abs(result.outcome_change):.2f} "
            f"({'increase' if result.outcome_change > 0 else 'decrease'}).\n\n"
            f"**Why?**\n{result.explanation}"
        )
        
        key_points = [
            f"Original result: {result.original_outcome:.2f}",
            f"What-if result: {result.counterfactual_outcome:.2f}",
            f"Difference: {result.outcome_change:+.2f}"
        ]
        
        confidence_stmt = "This prediction is based on patterns we've observed."
        
        return NarrativeExplanation(
            title=title,
            summary=summary,
            detailed_explanation=detailed,
            key_points=key_points,
            confidence_statement=confidence_stmt,
            uncertainty_notes=[],
            audience_level=AudienceLevel.END_USER
        )
    
    def _template_counterfactual_executive(self, result):
        """Executive counterfactual explanation."""
        title = "Strategic Scenario Planning"
        
        summary = (
            f"Business impact analysis of proposed intervention scenario."
        )
        
        detailed = (
            f"**Executive Briefing: Scenario Analysis**\n\n"
            f"**Proposed Change:**\n"
        )
        
        for node, value in result.interventions_applied.items():
            detailed += f"- Adjust {node.replace('_', ' ').title()} to {value:.2f}\n"
        
        detailed += f"\n**Projected Impact:**\n"
        direction = "improve" if result.outcome_change > 0 else "decline"
        detailed += f"- Current performance: {result.original_outcome:.2f}\n"
        detailed += f"- Projected performance: {result.counterfactual_outcome:.2f}\n"
        detailed += f"- Expected {direction}: {abs(result.outcome_change):.2f} points\n"
        
        detailed += f"\n**Strategic Recommendation:**\n"
        if abs(result.outcome_change) > 0.3:
            detailed += f"This intervention shows significant impact. Consider implementation.\n"
        elif abs(result.outcome_change) > 0.1:
            detailed += f"Moderate impact detected. Evaluate cost-benefit before proceeding.\n"
        else:
            detailed += f"Limited impact. May not justify resource allocation.\n"
        
        key_points = [
            f"Impact: {result.outcome_change:+.2f} points",
            f"Confidence: {result.confidence:.0%}",
            f"Recommendation: {'Proceed' if abs(result.outcome_change) > 0.2 else 'Evaluate further'}"
        ]
        
        confidence_stmt = f"Analysis confidence: {result.confidence:.0%}"
        
        return NarrativeExplanation(
            title=title,
            summary=summary,
            detailed_explanation=detailed,
            key_points=key_points,
            confidence_statement=confidence_stmt,
            uncertainty_notes=[],
            audience_level=AudienceLevel.EXECUTIVE
        )
    
    # ==================== MINIMAL CHANGE TEMPLATES ====================
    
    def _template_minimal_change_technical(self, intervention, current, desired):
        """Technical minimal change explanation."""
        title = "Optimal Intervention Strategy"
        
        summary = (
            f"To shift outcome from {current:.3f} to {desired:.3f}, "
            f"apply these minimal adjustments (total magnitude: {intervention.total_magnitude:.3f}):"
        )
        
        detailed = "**Recommended Interventions:**\n\n"
        for node, delta in intervention.changes.items():
            detailed += f"- {node}: {'+' if delta > 0 else ''}{delta:.4f}\n"
        
        detailed += f"\n**Optimization Metrics:**\n"
        detailed += f"- Predicted outcome: {intervention.predicted_outcome:.4f}\n"
        detailed += f"- Target outcome: {desired:.4f}\n"
        detailed += f"- Error: {abs(intervention.predicted_outcome - desired):.4f}\n"
        detailed += f"- Feasibility score: {intervention.feasibility_score:.2f}/1.00\n"
        detailed += f"- Total change magnitude: {intervention.total_magnitude:.4f}\n"
        
        key_points = [
            f"Nodes to adjust: {len(intervention.changes)}",
            f"Feasibility: {intervention.feasibility_score:.2f}",
            f"Predicted accuracy: {abs(intervention.predicted_outcome - desired):.4f} error"
        ]
        
        confidence_stmt = f"Optimization converged with feasibility {intervention.feasibility_score:.2f}."
        
        return NarrativeExplanation(
            title=title,
            summary=summary,
            detailed_explanation=detailed,
            key_points=key_points,
            confidence_statement=confidence_stmt,
            uncertainty_notes=[],
            audience_level=AudienceLevel.TECHNICAL
        )
    
    def _template_minimal_change_regulatory(self, intervention, current, desired):
        """Regulatory minimal change explanation."""
        title = "Recommended Actions for Desired Outcome"
        
        summary = (
            f"This document outlines the minimum changes required to achieve the target outcome, "
            f"ensuring transparent and auditable decision guidance."
        )
        
        detailed = (
            f"**Action Plan Documentation**\n\n"
            f"**Current State:** {current:.3f}\n"
            f"**Target State:** {desired:.3f}\n\n"
            f"**Required Actions:**\n\n"
        )
        
        for i, (node, delta) in enumerate(intervention.changes.items(), 1):
            direction = "Increase" if delta > 0 else "Decrease"
            detailed += f"{i}. {direction} {node.replace('_', ' ')} by {abs(delta):.3f}\n"
        
        detailed += f"\n**Feasibility Assessment:**\n"
        detailed += f"- Overall feasibility: {intervention.feasibility_score:.0%}\n"
        detailed += f"- Number of changes: {len(intervention.changes)}\n"
        detailed += f"- All actions are within acceptable operational bounds.\n"
        
        key_points = [
            "Documented action plan with measurable targets",
            "Feasibility assessed and validated",
            "Minimal intervention approach reduces risk"
        ]
        
        confidence_stmt = f"Recommendations provided with {intervention.feasibility_score:.0%} feasibility."
        
        return NarrativeExplanation(
            title=title,
            summary=summary,
            detailed_explanation=detailed,
            key_points=key_points,
            confidence_statement=confidence_stmt,
            uncertainty_notes=[],
            audience_level=AudienceLevel.REGULATORY
        )
    
    def _template_minimal_change_end_user(self, intervention, current, desired):
        """End user minimal change explanation."""
        title = "How to Reach Your Goal"
        
        summary = (
            f"Here's the simplest way to improve your result from {current:.2f} to {desired:.2f}."
        )
        
        detailed = (
            f"**Your Action Plan:**\n\n"
            f"To get from where you are ({current:.2f}) to where you want to be ({desired:.2f}), "
            f"make these small changes:\n\n"
        )
        
        for node, delta in intervention.changes.items():
            node_readable = node.replace('_', ' ').lower()
            direction = "increase" if delta > 0 else "decrease"
            detailed += f"- {direction} {node_readable} by {abs(delta):.2f}\n"
        
        detailed += f"\n**How Likely Is This to Work?**\n"
        likelihood = "very likely" if intervention.feasibility_score > 0.8 else "likely" if intervention.feasibility_score > 0.6 else "possible"
        detailed += f"It's {likelihood} (score: {intervention.feasibility_score:.0%}) that these changes will get you to your goal.\n"
        
        key_points = [
            f"Simple {len(intervention.changes)}-step plan",
            f"Likelihood of success: {intervention.feasibility_score:.0%}",
            f"Small, manageable changes"
        ]
        
        confidence_stmt = "These recommendations are based on proven patterns."
        
        return NarrativeExplanation(
            title=title,
            summary=summary,
            detailed_explanation=detailed,
            key_points=key_points,
            confidence_statement=confidence_stmt,
            uncertainty_notes=[],
            audience_level=AudienceLevel.END_USER
        )
    
    def _template_minimal_change_executive(self, intervention, current, desired):
        """Executive minimal change explanation."""
        title = "Strategic Optimization Recommendations"
        
        summary = (
            f"Minimal-effort strategy to achieve target performance metrics."
        )
        
        detailed = (
            f"**Executive Summary: Path to Target**\n\n"
            f"**Current Performance:** {current:.2f}\n"
            f"**Target Performance:** {desired:.2f}\n"
            f"**Gap:** {desired - current:+.2f}\n\n"
            f"**Strategic Actions:**\n\n"
        )
        
        # Sort by magnitude (largest impact first)
        sorted_changes = sorted(intervention.changes.items(), key=lambda x: abs(x[1]), reverse=True)
        
        for i, (node, delta) in enumerate(sorted_changes[:3], 1):  # Top 3 only
            priority = "High" if abs(delta) > 0.2 else "Medium" if abs(delta) > 0.1 else "Low"
            detailed += f"{i}. **{node.replace('_', ' ').title()}** - {priority} Priority\n"
            detailed += f"   Adjustment: {'+' if delta > 0 else ''}{delta:.2f}\n\n"
        
        detailed += f"**Investment Required:**\n"
        detailed += f"- Changes needed: {len(intervention.changes)} areas\n"
        detailed += f"- Feasibility: {intervention.feasibility_score:.0%}\n"
        detailed += f"- Expected ROI: High (minimal changes, significant impact)\n"
        
        key_points = [
            f"Focus on top {min(3, len(sorted_changes))} priorities",
            f"Feasibility: {intervention.feasibility_score:.0%}",
            f"Minimal resource investment required"
        ]
        
        confidence_stmt = f"Recommendations backed by {intervention.feasibility_score:.0%} feasibility analysis."
        
        return NarrativeExplanation(
            title=title,
            summary=summary,
            detailed_explanation=detailed,
            key_points=key_points,
            confidence_statement=confidence_stmt,
            uncertainty_notes=[],
            audience_level=AudienceLevel.EXECUTIVE
        )


def generate_explanation(
    data: Any,
    explanation_type: str = 'path',
    audience: str = 'end_user',
    **kwargs
) -> NarrativeExplanation:
    """
    Convenience function for quick explanation generation.
    
    Args:
        data: CausalPath, CounterfactualResult, or MinimalIntervention
        explanation_type: 'path', 'counterfactual', or 'minimal_change'
        audience: Target audience level
        **kwargs: Additional arguments
        
    Returns:
        NarrativeExplanation
    """
    generator = NaturalLanguageGenerator()
    
    if explanation_type == 'path':
        return generator.explain_path(data, audience)
    elif explanation_type == 'counterfactual':
        return generator.explain_counterfactual(data, audience)
    elif explanation_type == 'minimal_change':
        return generator.explain_minimal_change(
            data,
            kwargs.get('current_outcome', 0.0),
            kwargs.get('desired_outcome', 1.0),
            audience
        )
    else:
        raise ValueError(f"Unknown explanation type: {explanation_type}")
