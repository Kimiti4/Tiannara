import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from tiannara_core.cognitive_domains import (
    MetaCognitiveMonitor,
    CollectiveIntelligenceEngine,
    CreativeSynthesisEngine,
    SocialIntelligenceSystem,
    EthicalReasoningEngine,
    EmbodiedCognitionSystem
)

def test_all():
    print("\n" + "="*60)
    print("COGNITIVE DOMAINS TEST SUITE")
    print("="*60)
    
    # Test 1: Meta-Cognition
    print("\n[1/6] Testing Meta-Cognition...")
    monitor = MetaCognitiveMonitor()
    assessment = monitor.continuous_self_assessment()
    assert 'overall_status' in assessment
    test_results = monitor.run_comprehensive_test_suite()
    assert 'domains_tested' in test_results
    coordination = monitor.coordinate_domains('predict and analyze')
    assert 'domains_involved' in coordination
    print("[PASS] Meta-Cognition operational")
    
    # Test 2: Collective Intelligence
    print("\n[2/6] Testing Collective Intelligence...")
    ci_engine = CollectiveIntelligenceEngine()
    from tiannara_core.cognitive_domains.collective_intelligence import AgentRole
    ci_engine.register_agent("a1", AgentRole.ANALYZER, ["analysis"])
    ci_engine.register_agent("a2", AgentRole.SYNTHESIZER, ["synthesis"])
    team_id = ci_engine.form_team("test", [AgentRole.ANALYZER, AgentRole.SYNTHESIZER])
    assert team_id.startswith("team_")
    metrics = ci_engine.get_collaboration_metrics()
    assert metrics['registered_agents'] == 2
    print("[PASS] Collective Intelligence operational")
    
    # Test 3: Creative Synthesis
    print("\n[3/6] Testing Creative Synthesis...")
    from tiannara_core.cognitive_domains.creative_synthesis import Concept
    cs_engine = CreativeSynthesisEngine()
    cs_engine.register_concept(Concept("nn", "AI", ["learning"], {}))
    cs_engine.register_concept(Concept("evo", "bio", ["selection"], {}))
    result = cs_engine.synthesize_ideas(["AI", "bio"], "test problem")
    assert result['success']
    assert len(result['ideas']) > 0
    print(f"[PASS] Creative Synthesis generated {len(result['ideas'])} ideas")
    
    # Test 4: Social Intelligence
    print("\n[4/6] Testing Social Intelligence...")
    si_system = SocialIntelligenceSystem()
    si_system.register_user("u1", {'communication_style': 'casual'})
    emotion = si_system.analyze_emotion("I'm happy!")
    assert emotion.value == "happy"
    adaptation = si_system.adapt_communication("u1", "help me", {})
    assert 'recommended_style' in adaptation
    si_system.record_interaction("u1", "thanks!", "welcome")
    metrics = si_system.get_social_metrics()
    assert metrics['total_interactions'] > 0
    print("[PASS] Social Intelligence operational")
    
    # Test 5: Ethical Reasoning
    print("\n[5/6] Testing Ethical Reasoning...")
    er_engine = EthicalReasoningEngine()
    evaluation = er_engine.evaluate_decision("help user", {"domain": "edu"}, ["user"])
    assert 'ethical_score' in evaluation
    bias_result = er_engine.detect_bias("He always does better than she does")
    assert 'biases_detected' in bias_result
    safe = er_engine.enforce_safety_constraints("help learn")
    unsafe = er_engine.enforce_safety_constraints("harm someone")
    assert safe['allowed'] and not unsafe['allowed']
    print("[PASS] Ethical Reasoning operational")
    
    # Test 6: Embodied Cognition
    print("\n[6/6] Testing Embodied Cognition...")
    ec_system = EmbodiedCognitionSystem()
    ec_system.create_environment("env1", "physical", {"gravity": 9.8})
    ec_system.create_agent("agent1")
    result = ec_system.run_simulation("agent1", "env1", ["observe", "move"])
    assert result['success']
    grounded = ec_system.ground_concept("action", [{'action': 'x'}])
    assert 'concept' in grounded
    metrics = ec_system.get_embodiment_metrics()
    assert metrics['total_simulations'] > 0
    print("[PASS] Embodied Cognition operational")
    
    print("\n" + "="*60)
    print("ALL 6 COGNITIVE DOMAINS OPERATIONAL")
    print("="*60)
    return True

if __name__ == "__main__":
    try:
        test_all()
        print("\nSUCCESS: All cognitive domains passed testing!")
    except Exception as e:
        print(f"\nFAILED: {str(e)}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
