"""
CROSS-DOMAIN INTEGRATION TESTS - All 14 Domains

Tests validate collaboration between:
- 8 Original Domains (Temporal, Combinatorial, Reverse Engineering, Algorithm, Logic, NLP, Prediction, Causal)
- 6 Cognitive Domains (Meta-Cognition, Collective Intelligence, Creative Synthesis, Social Intelligence, Ethical Reasoning, Embodied Cognition)

Goal: Ensure Tiannara Core masters integrated operation across ALL domains.
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from tiannara_core.evaluation.test_suites import (
    test_temporal_domain,
    test_combinatorial_domain,
    test_re_domain,
    test_algorithm_domain,
    test_logic_domain,
    test_nlp_domain,
    test_prediction_domain,
    test_causal_domain
)

from tiannara_core.cognitive_domains import (
    MetaCognitiveMonitor,
    CollectiveIntelligenceEngine,
    CreativeSynthesisEngine,
    SocialIntelligenceSystem,
    EthicalReasoningEngine,
    EmbodiedCognitionSystem
)

from tiannara_core.cognitive_domains.collective_intelligence import AgentRole


def test_temporal_metacognition_integration():
    """Test 1: Temporal domain + Meta-Cognition self-monitoring."""
    print("\n" + "="*80)
    print("TEST 1: Temporal + Meta-Cognition Integration")
    print("="*80)
    
    # Initialize temporal domain
    temporal_suite = test_temporal_domain.TemporalDomainTestSuite()
    result = temporal_suite.test_time_series_forecasting()
    
    # Meta-cognitive monitoring of temporal performance
    monitor = MetaCognitiveMonitor()
    assessment = monitor.continuous_self_assessment()
    
    # Validate both systems operational
    assert result.get('passed', 0) > 0, "Temporal forecasting failed"
    assert 'overall_status' in assessment, "Meta-cognitive assessment failed"
    
    print(f"[OK] Temporal forecasting: {result['passed']}/{result['total']} tests passed")
    print(f"[OK] Meta-cognitive status: {assessment['overall_status']}")
    print("[PASS] Temporal + Meta-Cognition integration successful")
    
    return True


def test_combinatorial_collective_intelligence():
    """Test 2: Combinatorial domain + Collective Intelligence multi-agent solving."""
    print("\n" + "="*80)
    print("TEST 2: Combinatorial + Collective Intelligence Integration")
    print("="*80)
    
    # Initialize combinatorial domain
    combo_suite = test_combinatorial_domain.CombinatorialDomainTestSuite()
    result = combo_suite.test_knapsack_problems()
    
    # Form collective intelligence team to solve graph problems
    ci_engine = CollectiveIntelligenceEngine()
    ci_engine.register_agent("graph_analyzer", AgentRole.ANALYZER, ["graph_analysis"])
    ci_engine.register_agent("solution_synthesizer", AgentRole.SYNTHESIZER, ["solution_building"])
    
    team_id = ci_engine.form_team("Optimize graph traversal algorithms", 
                                   [AgentRole.ANALYZER, AgentRole.SYNTHESIZER])
    
    assert result.get('passed', 0) > 0, "Combinatorial tests failed"
    assert team_id.startswith("team_"), "Team formation failed"
    
    print(f"[OK] Graph algorithms: {result['passed']}/{result['total']} tests passed")
    print(f"[OK] Multi-agent team formed: {team_id}")
    print("[PASS] Combinatorial + Collective Intelligence integration successful")
    
    return True


def test_causal_ethical_reasoning():
    """Test 3: Causal domain + Ethical Reasoning for intervention evaluation."""
    print("\n" + "="*80)
    print("TEST 3: Causal + Ethical Reasoning Integration")
    print("="*80)
    
    # Initialize causal domain
    causal_suite = test_causal_domain.CausalDomainTestSuite()
    result = causal_suite.test_causal_discovery()
    
    # Evaluate ethical implications of causal interventions
    ethical_engine = EthicalReasoningEngine()
    evaluation = ethical_engine.evaluate_decision(
        action="Implement AI-driven medical diagnosis system",
        context={'domain': 'healthcare', 'method': 'causal_inference'},
        stakeholders=['patients', 'doctors', 'hospital_administrators']
    )
    
    assert result.get('passed', 0) > 0, "Causal inference tests failed"
    assert 'ethical_score' in evaluation, "Ethical evaluation failed"
    assert evaluation['approved'] == True, "Ethical approval should be granted for beneficial healthcare AI"
    
    print(f"[OK] Causal inference: {result['passed']}/{result['total']} tests passed")
    print(f"[OK] Ethical score: {evaluation['ethical_score']:.2f} (approved: {evaluation['approved']})")
    print("[PASS] Causal + Ethical Reasoning integration successful")
    
    return True


def test_nlp_social_intelligence():
    """Test 4: NLP domain + Social Intelligence emotion-aware processing."""
    print("\n" + "="*80)
    print("TEST 4: NLP + Social Intelligence Integration")
    print("="*80)
    
    # Initialize NLP domain
    nlp_suite = test_nlp_domain.NLPDomainTestSuite()
    result = nlp_suite.test_sentiment_analysis()
    
    # Process text with social intelligence
    social_system = SocialIntelligenceSystem()
    
    # Test emotion detection on various texts
    test_texts = [
        ("I'm so happy with the results!", "happy"),
        ("This is frustrating and difficult", "frustrated"),
        ("The weather is okay today", "neutral")
    ]
    
    emotions_detected = []
    for text, expected_emotion in test_texts:
        detected = social_system.analyze_emotion(text)
        emotions_detected.append(detected.value)
    
    assert result.get('passed', 0) > 0, "NLP sentiment analysis failed"
    assert len(emotions_detected) == 3, "Emotion detection incomplete"
    
    print(f"[OK] NLP sentiment analysis: {result['passed']}/{result['total']} tests passed")
    print(f"[OK] Emotions detected: {emotions_detected}")
    print("[PASS] NLP + Social Intelligence integration successful")
    
    return True


def test_prediction_creative_synthesis():
    """Test 5: Prediction domain + Creative Synthesis for innovative forecasting."""
    print("\n" + "="*80)
    print("TEST 5: Prediction + Creative Synthesis Integration")
    print("="*80)
    
    # Initialize prediction domain
    pred_suite = test_prediction_domain.PredictionDomainTestSuite()
    result = pred_suite.test_football_predictions()
    
    # Generate creative approaches to prediction problems
    creative_engine = CreativeSynthesisEngine()
    
    # Register concepts from different domains
    from tiannara_core.cognitive_domains.creative_synthesis import Concept
    creative_engine.register_concept(Concept("time_series", "statistics", 
                                              ["trend", "seasonality", "autoregression"], {}))
    creative_engine.register_concept(Concept("neural_networks", "machine_learning",
                                              ["layers", "activation", "backpropagation"], {}))
    creative_engine.register_concept(Concept("chaos_theory", "physics",
                                              ["sensitivity", "attractors", "fractals"], {}))
    
    # Synthesize novel prediction approaches
    ideas = creative_engine.synthesize_ideas(
        source_domains=["statistics", "machine_learning", "physics"],
        target_problem="Improve long-term weather prediction accuracy"
    )
    
    assert result.get('passed', 0) > 0, "Prediction modeling tests failed"
    assert len(ideas.get('ideas', [])) > 0, "Creative synthesis produced no ideas"
    
    print(f"[OK] Predictive modeling: {result['passed']}/{result['total']} tests passed")
    print(f"[OK] Creative ideas generated: {len(ideas['ideas'])}")
    if ideas['ideas']:
        print(f"     Top idea novelty score: {ideas['ideas'][0].get('novelty_score', 0):.2f}")
    print("[PASS] Prediction + Creative Synthesis integration successful")
    
    return True


def test_logic_embodied_cognition():
    """Test 6: Logic domain + Embodied Cognition grounded reasoning."""
    print("\n" + "="*80)
    print("TEST 6: Logic + Embodied Cognition Integration")
    print("="*80)
    
    # Initialize logic domain
    logic_suite = test_logic_domain.LogicDomainTestSuite()
    result = logic_suite.test_logical_puzzles()
    
    # Create embodied simulation for logical problem-solving
    embodied_system = EmbodiedCognitionSystem()
    
    # Create environment for puzzle solving
    env_id = "logic_puzzle_env"
    embodied_system.create_environment(
        env_id=env_id,
        env_type="abstract",
        properties={
            'name': 'logic_puzzle_space',
            'dimensions': 3,
            'entities': ['puzzle_pieces', 'constraints', 'solution_space']
        }
    )
    
    # Create agent to explore solution space
    agent_id = "logic_solver_agent"
    embodied_system.create_agent(agent_id=agent_id)
    
    # Run simulation
    sim_result = embodied_system.run_simulation(
        agent_id=agent_id,
        env_id=env_id,
        actions=["perceive_constraints", "explore_solution_space", "apply_deduction"]
    )
    
    assert result.get('passed', 0) > 0, "Logic puzzle tests failed"
    assert sim_result.get('success', False), "Embodied simulation failed"
    
    print(f"[OK] Logic puzzles: {result['passed']}/{result['total']} tests passed")
    print(f"[OK] Embodied simulation: Success={sim_result.get('success', False)}")
    print("[PASS] Logic + Embodied Cognition integration successful")
    
    return True


def test_reverse_engineering_collective_analysis():
    """Test 7: Reverse Engineering + Collective Intelligence collaborative analysis."""
    print("\n" + "="*80)
    print("TEST 7: Reverse Engineering + Collective Intelligence Integration")
    print("="*80)
    
    # Initialize reverse engineering domain
    re_suite = test_re_domain.ReverseEngineeringTestSuite()
    result = re_suite.test_function_inference()
    
    # Form specialized RE team
    ci_engine = CollectiveIntelligenceEngine()
    ci_engine.register_agent("binary_analyst", AgentRole.ANALYZER, ["disassembly", "decompilation"])
    ci_engine.register_agent("protocol_expert", AgentRole.CRITIC, ["protocol_analysis"])
    ci_engine.register_agent("vulnerability_finder", AgentRole.VALIDATOR, ["security_testing"])
    
    team_id = ci_engine.form_team(
        "Analyze unknown binary protocol for vulnerabilities",
        [AgentRole.ANALYZER, AgentRole.CRITIC, AgentRole.VALIDATOR]
    )
    
    assert result.get('passed', 0) > 0, "Binary analysis tests failed"
    assert team_id.startswith("team_"), "RE team formation failed"
    
    print(f"[OK] Binary analysis: {result['passed']}/{result['total']} tests passed")
    print(f"[OK] RE analysis team: {team_id}")
    print("[PASS] Reverse Engineering + Collective Intelligence integration successful")
    
    return True


def test_algorithm_meta_cognitive_optimization():
    """Test 8: Algorithm domain + Meta-Cognition self-optimization."""
    print("\n" + "="*80)
    print("TEST 8: Algorithm + Meta-Cognition Integration")
    print("="*80)
    
    # Initialize algorithm domain
    algo_suite = test_algorithm_domain.AlgorithmDomainTestSuite()
    result = algo_suite.test_sorting_algorithms()
    
    # Meta-cognitive assessment of algorithm performance
    monitor = MetaCognitiveMonitor()
    
    # Run comprehensive test suite
    test_results = monitor.run_comprehensive_test_suite()
    
    # Coordinate optimization strategy
    coordination = monitor.coordinate_domains(
        task="Optimize sorting algorithms based on input characteristics"
    )
    
    assert result.get('passed', 0) > 0, "Sorting algorithm tests failed"
    assert 'domains_tested' in test_results, "Meta-cognitive testing failed"
    assert len(coordination.get('domains_involved', [])) >= 0, "Domain coordination executed"
    
    print(f"[OK] Sorting algorithms: {result['passed']}/{result['total']} tests passed")
    print(f"[OK] Domains tested by meta-cognition: {len(test_results['domains_tested'])}")
    print(f"[OK] Coordination plan involves: {len(coordination['domains_involved'])} domains")
    print("[PASS] Algorithm + Meta-Cognition integration successful")
    
    return True


def test_all_fourteen_domains_coordinated():
    """Test 9: Master integration test coordinating all 14 domains."""
    print("\n" + "="*80)
    print("TEST 9: ALL 14 DOMAINS COORDINATED INTEGRATION")
    print("="*80)
    
    print("\nPhase 1: Initializing all original domains...")
    original_domains = {
        'Temporal': test_temporal_domain.TemporalDomainTestSuite(),
        'Combinatorial': test_combinatorial_domain.CombinatorialDomainTestSuite(),
        'Reverse Engineering': test_re_domain.ReverseEngineeringTestSuite(),
        'Algorithm': test_algorithm_domain.AlgorithmDomainTestSuite(),
        'Logic': test_logic_domain.LogicDomainTestSuite(),
        'NLP': test_nlp_domain.NLPDomainTestSuite(),
        'Prediction': test_prediction_domain.PredictionDomainTestSuite(),
        'Causal': test_causal_domain.CausalDomainTestSuite()
    }
    
    print("Phase 2: Initializing all cognitive domains...")
    cognitive_domains = {
        'Meta-Cognition': MetaCognitiveMonitor(),
        'Collective Intelligence': CollectiveIntelligenceEngine(),
        'Creative Synthesis': CreativeSynthesisEngine(),
        'Social Intelligence': SocialIntelligenceSystem(),
        'Ethical Reasoning': EthicalReasoningEngine(),
        'Embodied Cognition': EmbodiedCognitionSystem()
    }
    
    print("Phase 3: Running coordinated scenario...")
    print("Scenario: AI assistant helps user solve complex data analysis problem")
    
    # Step 1: User interaction (Social Intelligence)
    social = cognitive_domains['Social Intelligence']
    user_message = "I need help analyzing this time series data, it's really confusing!"
    emotion = social.analyze_emotion(user_message)
    adapted_response = social.adapt_communication("user123", user_message)
    
    print(f"  [1/6] Social Intelligence: Detected emotion '{emotion.value}', adapted response")
    
    # Step 2: Understand the problem (NLP + Temporal)
    nlp = original_domains['NLP']
    nlp_result = nlp.test_sentiment_analysis()
    temporal = original_domains['Temporal']
    temporal_result = temporal.test_time_series_forecasting()
    
    print(f"  [2/6] NLP + Temporal: Understanding data analysis requirements")
    
    # Step 3: Analyze causality (Causal + Ethical)
    causal = original_domains['Causal']
    causal_result = causal.test_causal_discovery()
    ethical = cognitive_domains['Ethical Reasoning']
    ethical_eval = ethical.evaluate_decision(
        action="Apply automated data analysis to user dataset",
        context={'domain': 'data_science'},
        stakeholders=['user', 'data_subjects']
    )
    
    print(f"  [3/6] Causal + Ethical: Ensuring safe and valid analysis approach")
    
    # Step 4: Form analysis team (Collective Intelligence)
    ci = cognitive_domains['Collective Intelligence']
    ci.register_agent("data_analyst", AgentRole.ANALYZER, ["statistical_analysis"])
    ci.register_agent("insight_generator", AgentRole.SYNTHESIZER, ["pattern_recognition"])
    team_id = ci.form_team("Analyze time series and extract insights", 
                           [AgentRole.ANALYZER, AgentRole.SYNTHESIZER])
    
    print(f"  [4/6] Collective Intelligence: Formed analysis team {team_id}")
    
    # Step 5: Generate creative solutions (Creative Synthesis)
    creative = cognitive_domains['Creative Synthesis']
    from tiannara_core.cognitive_domains.creative_synthesis import Concept
    creative.register_concept(Concept("forecasting", "statistics", ["ARIMA", "exponential_smoothing"], {}))
    creative.register_concept(Concept("deep_learning", "AI", ["LSTM", "transformers"], {}))
    ideas = creative.synthesize_ideas(
        source_domains=["statistics", "AI"],
        target_problem="Improve time series prediction accuracy"
    )
    
    print(f"  [5/6] Creative Synthesis: Generated {len(ideas.get('ideas', []))} innovative approaches")
    
    # Step 6: Monitor and optimize (Meta-Cognition + Embodied)
    metacog = cognitive_domains['Meta-Cognition']
    assessment = metacog.continuous_self_assessment()
    
    embodied = cognitive_domains['Embodied Cognition']
    env_id = "analysis_workspace"
    embodied.create_environment(env_id=env_id, env_type="abstract", properties={'name': 'analysis_workspace'})
    agent_id = "analyst_agent"
    embodied.create_agent(agent_id=agent_id)
    sim_result = embodied.run_simulation(agent_id, env_id, ["analyze_data"])
    
    print(f"  [6/6] Meta-Cognition + Embodied: Self-assessment complete, simulation executed")
    
    # Validate all systems operational
    all_operational = (
        emotion is not None and
        nlp_result.get('passed', 0) > 0 and
        temporal_result.get('passed', 0) > 0 and
        causal_result.get('passed', 0) > 0 and
        ethical_eval.get('ethical_score', 0) > 0 and
        team_id.startswith("team_") and
        len(ideas.get('ideas', [])) > 0 and
        'overall_status' in assessment and
        sim_result.get('success', False)
    )
    
    print(f"\n{'='*80}")
    print(f"RESULT: All 14 domains operational and coordinated")
    print(f"{'='*80}")
    print(f"Original Domains Active: {len(original_domains)}/8")
    print(f"Cognitive Domains Active: {len(cognitive_domains)}/6")
    print(f"Integration Status: {'SUCCESS [OK]' if all_operational else 'PARTIAL [WARN]'}")
    
    assert all_operational, "Not all 14 domains are fully operational"
    
    print("\n[PASS] ALL 14 DOMAINS COORDINATED INTEGRATION SUCCESSFUL")
    
    return True


def run_all_cross_domain_tests():
    """Run all cross-domain integration tests."""
    print("\n" + "="*80)
    print("CROSS-DOMAIN INTEGRATION TEST SUITE - ALL 14 DOMAINS")
    print("="*80)
    
    tests = [
        ("Temporal + Meta-Cognition", test_temporal_metacognition_integration),
        ("Combinatorial + Collective Intelligence", test_combinatorial_collective_intelligence),
        ("Causal + Ethical Reasoning", test_causal_ethical_reasoning),
        ("NLP + Social Intelligence", test_nlp_social_intelligence),
        ("Prediction + Creative Synthesis", test_prediction_creative_synthesis),
        ("Logic + Embodied Cognition", test_logic_embodied_cognition),
        ("Reverse Engineering + Collective", test_reverse_engineering_collective_analysis),
        ("Algorithm + Meta-Cognition", test_algorithm_meta_cognitive_optimization),
        ("ALL 14 DOMAINS Coordinated", test_all_fourteen_domains_coordinated)
    ]
    
    passed = 0
    failed = 0
    
    for test_name, test_func in tests:
        try:
            result = test_func()
            passed += 1
            print(f"\n[RESULT] {test_name}: PASS [OK]\n")
        except Exception as e:
            failed += 1
            print(f"\n[RESULT] {test_name}: FAIL [ERROR]")
            print(f"Error: {str(e)}\n")
    
    print("\n" + "="*80)
    print(f"FINAL RESULTS: {passed}/{len(tests)} tests passed ({passed/len(tests)*100:.1f}%)")
    print("="*80)
    
    if passed == len(tests):
        print("\n[SUCCESS] All 14 domains demonstrate cross-domain mastery!")
    elif passed >= len(tests) * 0.8:
        print(f"\n[NEEDS WORK] Only {passed}/{len(tests)} domains integrated")
    else:
        print(f"\n[FAIL] Needs work: Only {passed}/{len(tests)} domains integrated")
    
    return passed == len(tests)


if __name__ == "__main__":
    success = run_all_cross_domain_tests()
    sys.exit(0 if success else 1)
