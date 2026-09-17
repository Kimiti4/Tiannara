"""
COGNITIVE FUSION ENGINE - COMPREHENSIVE TEST

Tests all 4 phases of the Cognitive Fusion Engine:
- Phase A: Debate Memory
- Phase B: Perspective Graphs
- Phase C: Partial Merge Engine
- Phase D: Emergent Solution Scoring

Validates that Tiannara can move beyond "committee selection" to true 
"emergent synthesis" as outlined in synthess.md.
"""

import sys
import time
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent
sys.path.insert(0, str(project_root))

from tiannara_core.metacognition.cognitive_fusion_engine import (
    CognitiveFusionEngine,
    DebateMemory,
    PerspectiveGraph,
    ArgumentRecord,
    PerspectiveFragment,
    RelationshipType,
)
from tiannara_core.metacognition.theory_engine import (
    Theory,
    CausalClaim,
    EvidenceItem,
    EvidenceType,
)


def test_phase_a_debate_memory():
    """Test Phase A: Debate Memory storage and retrieval."""
    print("\n" + "="*80)
    print("TEST PHASE A: DEBATE MEMORY")
    print("="*80)
    
    memory = DebateMemory()
    
    # Create session
    session = memory.create_session("test_session_1", "Test problem")
    assert session.session_id == "test_session_1"
    print("✅ Session creation works")
    
    # Add arguments
    arg1 = ArgumentRecord(
        argument_id="arg_1",
        agent_id="agent_a",
        target_agent_id="agent_b",
        argument_type="claim",
        content="Approach X is optimal",
        timestamp=time.time()
    )
    memory.add_argument("test_session_1", arg1)
    
    arg2 = ArgumentRecord(
        argument_id="arg_2",
        agent_id="agent_b",
        target_agent_id="agent_a",
        argument_type="critique",
        content="Approach X lacks evidence",
        timestamp=time.time() + 1,
        related_arguments=["arg_1"]
    )
    memory.add_argument("test_session_1", arg2)
    
    print(f"✅ Added {len(session.arguments)} arguments")
    
    # Mark survived/failed
    memory.mark_survived("arg_1")
    memory.mark_failed("arg_2")
    
    surviving = memory.get_surviving_principles("test_session_1")
    failed = memory.get_failed_claims("test_session_1")
    
    assert len(surviving) == 1
    assert len(failed) == 1
    print(f"✅ Surviving principles: {len(surviving)}, Failed claims: {len(failed)}")
    
    # Extract insights
    insights = memory.extract_debate_insights("test_session_1")
    assert len(insights) > 0
    print(f"✅ Extracted {len(insights)} insights")
    
    print("\n✅ PHASE A TEST PASSED\n")
    return True


def test_phase_b_perspective_graph():
    """Test Phase B: Perspective Graph construction and analysis."""
    print("\n" + "="*80)
    print("TEST PHASE B: PERSPECTIVE GRAPH")
    print("="*80)
    
    graph = PerspectiveGraph()
    
    # Add fragments from different agents
    frag1 = PerspectiveFragment(
        fragment_id="agent_a_assump_1",
        source_agent_id="agent_a",
        fragment_type="assumption",
        content="Data drives decisions",
        confidence=0.9
    )
    graph.add_fragment(frag1)
    
    frag2 = PerspectiveFragment(
        fragment_id="agent_b_assump_1",
        source_agent_id="agent_b",
        fragment_type="assumption",
        content="Intuition guides innovation",
        confidence=0.8
    )
    graph.add_fragment(frag2)
    
    frag3 = PerspectiveFragment(
        fragment_id="agent_a_proc_1",
        source_agent_id="agent_a",
        fragment_type="procedure",
        content="Analyze historical data",
        confidence=0.85
    )
    graph.add_fragment(frag3)
    
    print(f"✅ Added {len(graph.fragments)} fragments")
    
    # Add relationships
    from tiannara_core.metacognition.cognitive_fusion_engine import PerspectiveEdge
    
    edge1 = PerspectiveEdge(
        source_id="agent_a_assump_1",
        target_id="agent_b_assump_1",
        relationship=RelationshipType.CONFLICTS,
        strength=0.8,
        explanation="Contradictory assumptions"
    )
    graph.add_relationship(edge1)
    
    edge2 = PerspectiveEdge(
        source_id="agent_a_proc_1",
        target_id="agent_b_assump_1",
        relationship=RelationshipType.COMPLEMENTS,
        strength=0.7,
        explanation="Procedure supports alternative assumption"
    )
    graph.add_relationship(edge2)
    
    print(f"✅ Added {len(graph.edges)} relationships")
    
    # Detect conflicts
    conflicts = graph.detect_conflicts()
    assert len(conflicts) == 1
    print(f"✅ Detected {len(conflicts)} conflicts")
    
    # Find synthesis opportunities
    opportunities = graph.find_synthesis_opportunities()
    print(f"✅ Found {len(opportunities)} synthesis opportunities")
    
    # Visualize
    summary = graph.visualize_graph_summary()
    assert "Fragments:" in summary
    print(f"✅ Graph visualization works")
    
    print("\n✅ PHASE B TEST PASSED\n")
    return True


def test_phase_c_partial_merge():
    """Test Phase C: Partial Merge Engine."""
    print("\n" + "="*80)
    print("TEST PHASE C: PARTIAL MERGE ENGINE")
    print("="*80)
    
    graph = PerspectiveGraph()
    
    # Add compatible fragments
    frag1 = PerspectiveFragment(
        fragment_id="frag_1",
        source_agent_id="agent_a",
        fragment_type="heuristic",
        content="Use statistical analysis",
        confidence=0.85
    )
    graph.add_fragment(frag1)
    
    frag2 = PerspectiveFragment(
        fragment_id="frag_2",
        source_agent_id="agent_b",
        fragment_type="heuristic",
        content="Apply machine learning",
        confidence=0.80
    )
    graph.add_fragment(frag2)
    
    # Add complementary relationship
    from tiannara_core.metacognition.cognitive_fusion_engine import PerspectiveEdge
    edge = PerspectiveEdge(
        source_id="frag_1",
        target_id="frag_2",
        relationship=RelationshipType.COMPLEMENTS,
        strength=0.7,
        explanation="Complementary heuristics"
    )
    graph.add_relationship(edge)
    
    # Create merge engine
    from tiannara_core.metacognition.cognitive_fusion_engine import PartialMergeEngine
    merge_engine = PartialMergeEngine(graph)
    
    # Attempt merge
    merged = merge_engine.merge_compatible_fragments(["frag_1", "frag_2"])
    
    assert merged is not None
    assert len(merged.source_fragments) == 2
    print(f"✅ Successfully merged 2 fragments")
    print(f"   Merged content: {merged.merged_content[:80]}...")
    
    # Auto-merge
    auto_merged = merge_engine.auto_merge_compatible_groups()
    print(f"✅ Auto-merged {len(auto_merged)} component groups")
    
    print("\n✅ PHASE C TEST PASSED\n")
    return True


def test_phase_d_emergent_scoring():
    """Test Phase D: Emergent Solution Scoring."""
    print("\n" + "="*80)
    print("TEST PHASE D: EMERGENT SOLUTION SCORING")
    print("="*80)
    
    from tiannara_core.metacognition.cognitive_fusion_engine import (
        MergedComponent,
        EmergentSolutionScorer,
    )
    
    scorer = EmergentSolutionScorer()
    
    # Create mock merged components
    comp1 = MergedComponent(
        component_id="merged_1",
        component_type="heuristic",
        merged_content="Combined heuristic",
        source_fragments=["frag_1", "frag_2"],
        compatibility_score=0.85,
        confidence=0.82
    )
    
    # Mock fragments
    from tiannara_core.metacognition.cognitive_fusion_engine import PerspectiveFragment
    fragments = {
        "frag_1": PerspectiveFragment(
            fragment_id="frag_1",
            source_agent_id="agent_a",
            fragment_type="heuristic",
            content="Statistical analysis",
            confidence=0.85
        ),
        "frag_2": PerspectiveFragment(
            fragment_id="frag_2",
            source_agent_id="agent_b",
            fragment_type="heuristic",
            content="Machine learning",
            confidence=0.80
        )
    }
    
    # Individual scores
    individual_scores = {
        "agent_a": 0.75,
        "agent_b": 0.70
    }
    
    # Score emergent solution
    solution = scorer.score_emergent_solution(
        merged_components=[comp1],
        individual_scores=individual_scores,
        original_fragments=fragments
    )
    
    assert solution.novelty_score > 0
    assert solution.quality_score > 0
    assert len(solution.contribution_retention) == 2
    print(f"✅ Novelty Score: {solution.novelty_score:.3f}")
    print(f"✅ Quality Score: {solution.quality_score:.3f}")
    print(f"✅ Contributions: {solution.contribution_retention}")
    
    # Evaluate success
    success = scorer.evaluate_synthesis_success(solution)
    print(f"✅ Success metrics: {success}")
    
    assert all(success.values()), f"Not all success criteria met: {success}"
    print(f"✅ All success criteria met!")
    
    print("\n✅ PHASE D TEST PASSED\n")
    return True


def test_full_fusion_pipeline():
    """Test complete Cognitive Fusion Engine pipeline."""
    print("\n" + "="*80)
    print("TEST FULL COGNITIVE FUSION PIPELINE")
    print("="*80)
    
    engine = CognitiveFusionEngine()
    
    # Create diverse agent proposals
    proposals = {
        'agent_analytical': Theory(
            theory_id="theory_analytical",
            name="Analytical Approach",
            domain="analytical",
            description="Data-driven optimization",
            assumptions=[
                "Historical patterns predict future outcomes",
                "Statistical significance indicates causality"
            ],
            causal_claims=[
                CausalClaim(cause="data_analysis", effect="optimal_solution", strength=0.85),
                CausalClaim(cause="validation", effect="reliability", strength=0.90)
            ],
            evidence_for=[
                EvidenceItem(
                    evidence_id="e1",
                    evidence_type=EvidenceType.EXPERIMENT,
                    description="Empirical study shows correlation",
                    supports_theory=True,
                    confidence=0.90,
                    source="study_1"
                ),
                EvidenceItem(
                    evidence_id="e2",
                    evidence_type=EvidenceType.STATISTICAL_CORRELATION,
                    description="Large dataset confirms pattern",
                    supports_theory=True,
                    confidence=0.88,
                    source="dataset_1"
                )
            ]
        ),
        'agent_creative': Theory(
            theory_id="theory_creative",
            name="Creative Breakthrough",
            domain="creative",
            description="Novel paradigm shift approach",
            assumptions=[
                "Conventional methods have plateaued",
                "Risk-taking enables innovation"
            ],
            causal_claims=[
                CausalClaim(cause="novel_approach", effect="breakthrough", strength=0.70),
                CausalClaim(cause="cross_domain_inspiration", effect="innovation", strength=0.75)
            ],
            evidence_for=[
                EvidenceItem(
                    evidence_id="e3",
                    evidence_type=EvidenceType.OBSERVATION,
                    description="Analogous success in different domain",
                    supports_theory=True,
                    confidence=0.65,
                    source="analogy_1"
                )
            ]
        ),
        'agent_conservative': Theory(
            theory_id="theory_conservative",
            name="Proven Method",
            domain="conservative",
            description="Established reliable approach",
            assumptions=[
                "Proven methods minimize risk",
                "Incremental improvement is sustainable"
            ],
            causal_claims=[
                CausalClaim(cause="proven_method", effect="reliable_outcome", strength=0.92)
            ],
            evidence_for=[
                EvidenceItem(
                    evidence_id="e4",
                    evidence_type=EvidenceType.EXPERIMENT,
                    description="Successful deployment in production",
                    supports_theory=True,
                    confidence=0.95,
                    source="case_study_1"
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
        ),
        ArgumentRecord(
            argument_id="arg_3",
            agent_id="agent_conservative",
            target_agent_id="agent_creative",
            argument_type="critique",
            content="Too risky for critical infrastructure",
            timestamp=time.time() + 2,
            evidence_strength=0.90
        )
    ]
    
    # Run fusion pipeline
    solution = engine.run_fusion_pipeline(
        session_id="full_test_session",
        problem="Optimize renewable energy grid integration with reliability",
        agent_proposals=proposals,
        debate_arguments=arguments
    )
    
    if solution:
        print(f"\n{'='*80}")
        print("FULL PIPELINE TEST RESULTS")
        print(f"{'='*80}")
        print(f"✅ Synthesis successful!")
        print(f"   Components merged: {len(solution.merged_components)}")
        print(f"   Novelty: {solution.novelty_score:.3f}")
        print(f"   Quality: {solution.quality_score:.3f}")
        print(f"   Agent contributions: {solution.contribution_retention}")
        
        # Verify synthesis quality
        assert solution.novelty_score > 0.3, "Novelty too low"
        assert solution.quality_score > 0.5, "Quality too low"
        assert len(solution.contribution_retention) >= 2, "Not enough agent diversity"
        
        print(f"\n✅ FULL PIPELINE TEST PASSED")
        return True
    else:
        print(f"\n❌ FULL PIPELINE TEST FAILED - No synthesis produced")
        return False


def main():
    """Run all Cognitive Fusion Engine tests."""
    print("\n" + "="*80)
    print("COGNITIVE FUSION ENGINE - COMPREHENSIVE TEST SUITE")
    print("="*80)
    
    results = []
    
    try:
        results.append(("Phase A: Debate Memory", test_phase_a_debate_memory()))
    except Exception as e:
        print(f"❌ Phase A failed: {e}")
        results.append(("Phase A: Debate Memory", False))
    
    try:
        results.append(("Phase B: Perspective Graph", test_phase_b_perspective_graph()))
    except Exception as e:
        print(f"❌ Phase B failed: {e}")
        results.append(("Phase B: Perspective Graph", False))
    
    try:
        results.append(("Phase C: Partial Merge", test_phase_c_partial_merge()))
    except Exception as e:
        print(f"❌ Phase C failed: {e}")
        results.append(("Phase C: Partial Merge", False))
    
    try:
        results.append(("Phase D: Emergent Scoring", test_phase_d_emergent_scoring()))
    except Exception as e:
        print(f"❌ Phase D failed: {e}")
        results.append(("Phase D: Emergent Scoring", False))
    
    try:
        results.append(("Full Pipeline", test_full_fusion_pipeline()))
    except Exception as e:
        print(f"❌ Full Pipeline failed: {e}")
        results.append(("Full Pipeline", False))
    
    # Summary
    print("\n" + "="*80)
    print("TEST SUMMARY")
    print("="*80)
    
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for test_name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{test_name}: {status}")
    
    print(f"\nTotal: {passed}/{total} tests passed")
    
    if passed == total:
        print("\n🎉 ALL COGNITIVE FUSION ENGINE TESTS PASSED!")
        print("Tiannara can now perform true emergent synthesis.")
        return 0
    else:
        print(f"\n⚠️  {total - passed} tests failed")
        return 1


if __name__ == "__main__":
    exit(main())
