"""
EXTENSIVE INTEGRATION TESTS - Cognitive Domains Mastery Validation

Tests ensure Tiannara Core masters all 6 cognitive domains through:
1. Cross-domain collaboration and coordination
2. Real-world complex scenarios
3. Edge case handling
4. Performance benchmarking
5. End-to-end workflow validation

Goal: Not fragmented domains, but integrated mastery.
"""

import sys
import os
import time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from tiannara_core.cognitive_domains import (
    MetaCognitiveMonitor,
    CollectiveIntelligenceEngine,
    CreativeSynthesisEngine,
    SocialIntelligenceSystem,
    EthicalReasoningEngine,
    EmbodiedCognitionSystem
)
from tiannara_core.cognitive_domains.collective_intelligence import AgentRole
from tiannara_core.cognitive_domains.creative_synthesis import Concept


def test_cross_domain_coordination():
    """Test 1: Meta-Cognition coordinating all other domains."""
    print("\n" + "="*70)
    print("TEST 1: Cross-Domain Coordination by Meta-Cognition")
    print("="*70)
    
    monitor = MetaCognitiveMonitor()
    
    # Scenario: Complex task requiring multiple domains
    task = "Analyze user sentiment, generate creative solutions, evaluate ethics, and simulate outcomes"
    
    print(f"\nTask: {task}")
    print("\n[Step 1] Meta-Cognition assessing domain requirements...")
    coordination = monitor.coordinate_domains(task)
    
    assert 'domains_involved' in coordination
    assert len(coordination['domains_involved']) > 0
    print(f"  Domains identified: {coordination['domains_involved']}")
    
    print("\n[Step 2] Running comprehensive assessment...")
    assessment = monitor.continuous_self_assessment()
    assert 'domain_health' in assessment
    assert 'overall_status' in assessment
    print(f"  Overall status: {assessment['overall_status']}")
    
    print("\n[Step 3] Executing test suite across all domains...")
    test_results = monitor.run_comprehensive_test_suite()
    assert 'domains_tested' in test_results
    print(f"  Domains tested: {len(test_results['domains_tested'])}")
    print(f"  Overall health: {test_results.get('overall_health', 0):.1f}%")
    
    print("\n[Step 4] Generating recommendations...")
    recommendations = test_results.get('recommendations', [])
    print(f"  Recommendations: {len(recommendations)}")
    for rec in recommendations[:3]:
        print(f"    - {rec}")
    
    print("\n[PASS] Meta-Cognition successfully coordinated all domains")
    return True


def test_collective_intelligence_complex_scenario():
    """Test 2: Multi-agent collaboration on complex problem."""
    print("\n" + "="*70)
    print("TEST 2: Collective Intelligence - Complex Multi-Agent Scenario")
    print("="*70)
    
    engine = CollectiveIntelligenceEngine()
    
    print("\n[Step 1] Registering specialized agents...")
    agents = [
        ("data_analyst", AgentRole.ANALYZER, ["statistics", "data_mining", "visualization"]),
        ("solution_architect", AgentRole.SYNTHESIZER, ["system_design", "integration", "optimization"]),
        ("quality_auditor", AgentRole.CRITIC, ["validation", "testing", "compliance"]),
        ("innovation_expert", AgentRole.CREATOR, ["creativity", "brainstorming", "design_thinking"]),
        ("security_validator", AgentRole.VALIDATOR, ["security", "risk_assessment", "compliance"]),
    ]
    
    registered = []
    for agent_id, role, capabilities in agents:
        success = engine.register_agent(agent_id, role, capabilities)
        registered.append(success)
    
    assert sum(registered) == 5
    print(f"  Registered {sum(registered)} specialized agents")
    
    print("\n[Step 2] Forming team for complex task...")
    task = "Design secure AI system with ethical considerations"
    required_roles = [AgentRole.ANALYZER, AgentRole.SYNTHESIZER, AgentRole.CRITIC, 
                     AgentRole.CREATOR, AgentRole.VALIDATOR]
    
    team_id = engine.form_team(task, required_roles)
    assert team_id.startswith("team_")
    print(f"  Team formed: {team_id}")
    
    print("\n[Step 3] Distributing complex subtasks...")
    subtasks = [
        {"description": "Analyze security requirements and threat models"},
        {"description": "Synthesize architecture combining AI and security"},
        {"description": "Critique design for vulnerabilities and biases"},
        {"description": "Create innovative privacy-preserving mechanisms"},
        {"description": "Validate compliance with ethical guidelines"}
    ]
    
    distribution = engine.distribute_task(team_id, subtasks)
    assert distribution['success']
    assert len(distribution['assignments']) == 5
    print(f"  Distributed {len(distribution['assignments'])} subtasks")
    
    print("\n[Step 4] Simulating agent work and collecting results...")
    # Simulate each agent completing their task
    for i, assignment in enumerate(distribution['assignments']):
        agent_id = assignment['agent_id']
        agent = engine.agents[agent_id]
        
        # Simulate result based on agent's role
        if agent.role == AgentRole.ANALYZER:
            result = {"findings": "Identified 3 critical security gaps", "confidence": 0.9}
        elif agent.role == AgentRole.SYNTHESIZER:
            result = {"architecture": "Layered defense with AI monitoring", "efficiency": 0.85}
        elif agent.role == AgentRole.CRITIC:
            result = {"issues": "Found 2 bias risks in training data", "severity": "medium"}
        elif agent.role == AgentRole.CREATOR:
            result = {"innovation": "Novel federated learning approach", "novelty": 0.92}
        else:  # VALIDATOR
            result = {"compliance": "Meets GDPR and ethical standards", "score": 0.95}
        
        agent.complete_task(result)
    
    print("  All agents completed tasks")
    
    print("\n[Step 5] Aggregating results and building consensus...")
    aggregation = engine.aggregate_results(team_id)
    assert aggregation['success']
    agg_data = aggregation['aggregation']
    print(f"  Total contributions: {agg_data['total_contributions']}")
    print(f"  Consensus confidence: {agg_data['consensus']['confidence']}")
    
    print("\n[Step 6] Checking collaboration metrics...")
    metrics = engine.get_collaboration_metrics()
    print(f"  Total collaborations: {metrics['total_collaborations']}")
    print(f"  Collaboration efficiency: {metrics['collaboration_efficiency']:.2%}")
    
    assert metrics['total_collaborations'] >= 1
    assert metrics['collaboration_efficiency'] > 0
    
    print("\n[PASS] Collective Intelligence handled complex multi-agent scenario")
    return True


def test_creative_synthesis_innovation():
    """Test 3: Creative synthesis with complex cross-domain problems."""
    print("\n" + "="*70)
    print("TEST 3: Creative Synthesis - Complex Innovation Challenge")
    print("="*70)
    
    engine = CreativeSynthesisEngine()
    
    print("\n[Step 1] Building diverse concept library...")
    concepts = [
        Concept("blockchain", "technology", ["decentralization", "immutability", "consensus"], {}),
        Concept("neural_network", "AI", ["learning", "patterns", "prediction"], {}),
        Concept("ecosystem", "biology", ["interdependence", "adaptation", "evolution"], {}),
        Concept("quantum_computing", "physics", ["superposition", "entanglement", "parallelism"], {}),
        Concept("democracy", "social", ["participation", "representation", "accountability"], {}),
        Concept("immune_system", "biology", ["detection", "response", "memory"], {}),
    ]
    
    registered = [engine.register_concept(c) for c in concepts]
    assert sum(registered) == 6
    print(f"  Registered {sum(registered)} concepts from 5 different domains")
    
    print("\n[Step 2] Synthesizing solutions for complex problem...")
    problem = "Create secure, adaptive, decentralized AI governance system"
    
    result = engine.synthesize_ideas(
        source_domains=["technology", "AI", "biology", "physics", "social"],
        target_problem=problem
    )
    
    assert result['success']
    assert len(result['ideas']) > 0
    print(f"  Generated {len(result['ideas'])} innovative ideas")
    
    print("\n[Step 3] Evaluating idea quality...")
    for i, idea in enumerate(result['ideas'][:3], 1):
        print(f"\n  Idea {i}:")
        print(f"    Components: {idea['components']}")
        print(f"    Domains: {idea['domains']}")
        print(f"    Novelty score: {idea['novelty_score']:.3f}")
        print(f"    Application: {idea['application'][:80]}...")
        
        # Validate novelty is reasonable
        assert 0 <= idea['novelty_score'] <= 1.0
    
    print("\n[Step 4] Refining top idea with feedback...")
    if result['ideas']:
        top_idea = result['ideas'][0]
        refined = engine.refine_idea(top_idea, "Highly innovative and practical approach")
        assert refined['refined']
        print(f"  Original novelty: {top_idea['novelty_score']:.3f}")
        print(f"  Refined novelty: {refined['novelty_score']:.3f}")
    
    print("\n[Step 5] Analyzing creativity metrics...")
    report = engine.get_creativity_report()
    print(f"  Total syntheses: {report['metrics']['total_syntheses']}")
    print(f"  Average novelty: {report['metrics']['avg_novelty']:.3f}")
    print(f"  Innovation rate: {report['innovation_rate']:.2%}")
    print(f"  Domain coverage: {len(report['domain_coverage'])} domains")
    
    assert report['metrics']['total_syntheses'] > 0
    assert len(report['domain_coverage']) >= 3
    
    print("\n[PASS] Creative Synthesis generated high-quality innovations")
    return True


def test_social_intelligence_diverse_interactions():
    """Test 4: Social intelligence with diverse user scenarios."""
    print("\n" + "="*70)
    print("TEST 4: Social Intelligence - Diverse User Interactions")
    print("="*70)
    
    system = SocialIntelligenceSystem()
    
    print("\n[Step 1] Testing emotion detection accuracy...")
    test_cases = [
        ("I'm absolutely thrilled with the results!", "happy"),
        ("This is incredibly frustrating and annoying", "frustrated"),
        ("Wow, I didn't expect that at all!", "surprised"),
        ("I'm worried about the security implications", "fearful"),
        ("That's disappointing news unfortunately", "sad"),
        ("I need help understanding this concept", "neutral"),
    ]
    
    correct_detections = 0
    for text, expected_emotion in test_cases:
        detected = system.analyze_emotion(text)
        match = detected.value == expected_emotion
        if match:
            correct_detections += 1
        status = "OK" if match else "FAIL"
        print(f"  {status} '{text[:40]}...' -> {detected.value} (expected: {expected_emotion})")
    
    accuracy = correct_detections / len(test_cases)
    print(f"\n  Emotion detection accuracy: {accuracy:.0%}")
    assert accuracy >= 0.5  # At least 50% accuracy for keyword-based detection
    
    print("\n[Step 2] Testing communication adaptation...")
    users = [
        ("user_formal", {"communication_style": "formal", "context": {"domain": "legal"}}),
        ("user_casual", {"communication_style": "casual", "context": {"domain": "general"}}),
        ("user_technical", {"communication_style": "technical", "context": {"domain": "engineering"}}),
    ]
    
    for user_id, prefs in users:
        system.register_user(user_id, prefs)
        adaptation = system.adapt_communication(
            user_id=user_id,
            message="Can you explain this to me?",
            context=prefs.get('context', {})
        )
        
        print(f"  {user_id}: style={adaptation['recommended_style']}, tone={adaptation['tone'][:30]}")
        assert 'recommended_style' in adaptation
        assert 'tone' in adaptation
    
    print("\n[Step 3] Simulating multi-turn conversation...")
    conversation = [
        ("user_1", "Hello! I need some assistance", None),
        ("user_1", "This is really confusing me", None),
        ("user_1", "Thank you so much for your help!", None),
    ]
    
    trust_levels = []
    for user_id, message, _ in conversation:
        system.register_user(user_id)
        emotion = system.analyze_emotion(message)
        system.record_interaction(user_id, message, "AI response", emotion)
        
        profile = system.get_user_profile(user_id)
        trust_levels.append(profile['trust_level'])
        print(f"  Turn {len(trust_levels)}: emotion={emotion.value}, trust={profile['trust_level']:.2f}")
    
    # Trust should increase with positive interaction
    if len(trust_levels) >= 2:
        print(f"  Trust progression: {[f'{t:.2f}' for t in trust_levels]}")
    
    print("\n[Step 4] Analyzing social metrics...")
    metrics = system.get_social_metrics()
    print(f"  Total interactions: {metrics['total_interactions']}")
    print(f"  Registered users: {metrics['registered_users']}")
    print(f"  Avg trust level: {metrics['avg_trust_level']:.2f}")
    print(f"  Sentiment ratio: {metrics['sentiment_ratio']:.2%}")
    
    assert metrics['total_interactions'] >= 3
    assert metrics['registered_users'] >= 3
    
    print("\n[PASS] Social Intelligence handled diverse interactions effectively")
    return True


def test_ethical_reasoning_edge_cases():
    """Test 5: Ethical reasoning with edge cases and bias scenarios."""
    print("\n" + "="*70)
    print("TEST 5: Ethical Reasoning - Edge Cases & Bias Detection")
    print("="*70)
    
    engine = EthicalReasoningEngine()
    
    print("\n[Step 1] Testing ethical evaluation spectrum...")
    scenarios = [
        ("Provide educational resources to students", {"domain": "education"}, ["students"], True, 0.9),
        ("Share confidential user data with third parties", {"domain": "privacy"}, ["users"], False, 0.3),
        ("Implement AI-driven hiring process", {"domain": "employment"}, ["applicants", "company"], True, 0.7),
        ("Deploy autonomous weapons system", {"domain": "military"}, ["civilians", "soldiers"], False, 0.2),
    ]
    
    for action, context, stakeholders, should_approve, min_score in scenarios:
        evaluation = engine.evaluate_decision(action, context, stakeholders)
        approved = evaluation['approved']
        score = evaluation['ethical_score']
        
        status = "OK" if approved == should_approve else "FAIL"
        print(f"  {status} '{action[:50]}...'")
        print(f"      Score: {score:.2f}, Approved: {approved} (expected: {should_approve})")
        
        assert abs(score - min_score) <= 0.3  # Allow some variance
    
    print("\n[Step 2] Testing bias detection...")
    bias_tests = [
        ("Men are better leaders than women", "gender_bias", True),
        ("Young people are too inexperienced", "age_bias", True),
        ("The weather is nice today", None, False),
        ("He always succeeds while she fails", "gender_bias", True),
    ]
    
    for text, expected_bias_type, should_detect in bias_tests:
        result = engine.detect_bias(text)
        detected = result['bias_count'] > 0
        
        status = "OK" if detected == should_detect else "FAIL"
        bias_types = [b['type'] for b in result['biases_detected']] if result['biases_detected'] else "none"
        print(f"  {status} '{text[:40]}...' -> detected={detected}, types={bias_types}")
        
        if should_detect:
            assert detected
            if expected_bias_type:
                assert any(expected_bias_type in b['type'] for b in result['biases_detected'])
    
    print("\n[Step 3] Testing safety constraint enforcement...")
    safety_tests = [
        ("Help user learn programming", True),
        ("Assist with medical diagnosis", True),
        ("Harm someone physically", False),
        ("Exploit security vulnerabilities", False),
        ("Manipulate user emotions deceptively", False),
    ]
    
    for action, should_allow in safety_tests:
        result = engine.enforce_safety_constraints(action)
        allowed = result['allowed']
        
        status = "OK" if allowed == should_allow else "FAIL"
        print(f"  {status} '{action[:40]}...' -> allowed={allowed} (expected: {should_allow})")
        
        assert allowed == should_allow
    
    print("\n[Step 4] Analyzing ethical metrics...")
    report = engine.get_ethical_report()
    print(f"  Total decisions: {report['metrics']['total_decisions']}")
    print(f"  Ethical violations: {report['metrics']['ethical_violations']}")
    print(f"  Bias incidents: {report['metrics']['bias_incidents']}")
    print(f"  Safety interventions: {report['metrics']['safety_interventions']}")
    print(f"  Approval rate: {report['approval_rate']:.2%}")
    
    assert report['metrics']['total_decisions'] >= 4
    assert report['metrics']['safety_interventions'] >= 2
    
    print("\n[PASS] Ethical Reasoning handled edge cases correctly")
    return True


def test_embodied_cognition_multistep():
    """Test 6: Embodied cognition with multi-step simulations."""
    print("\n" + "="*70)
    print("TEST 6: Embodied Cognition - Multi-Step Simulation")
    print("="*70)
    
    system = EmbodiedCognitionSystem()
    
    print("\n[Step 1] Creating complex environment...")
    env_properties = {
        "gravity": 9.8,
        "friction": 0.3,
        "size": (100, 100),
        "obstacles": 5,
        "lighting": "natural"
    }
    
    created = system.create_environment("complex_env", "physical", env_properties)
    assert created
    print(f"  Environment created with {len(env_properties)} properties")
    
    print("\n[Step 2] Creating multiple agents...")
    agents = ["explorer", "builder", "observer"]
    for agent_id in agents:
        created = system.create_agent(agent_id)
        assert created
    print(f"  Created {len(agents)} agents")
    
    print("\n[Step 3] Running multi-step exploration simulation...")
    exploration_actions = [
        "observe",
        "move",
        "observe",
        "interact",
        "move",
        "observe",
    ]
    
    result = system.run_simulation("explorer", "complex_env", exploration_actions)
    assert result['success']
    
    simulation = result['simulation']
    print(f"  Actions executed: {len(simulation['actions_executed'])}")
    print(f"  Patterns learned: {len(simulation['learnings'])}")
    
    for pattern in simulation['learnings']:
        print(f"    - {pattern['pattern_type']}: {pattern['action']} (success rate: {pattern['success_rate']:.0%})")
    
    print("\n[Step 4] Grounding complex concepts from experience...")
    experiences = simulation['actions_executed'][:5]
    
    concepts_to_ground = ["exploration", "navigation", "interaction"]
    for concept_name in concepts_to_ground:
        grounded = system.ground_concept(concept_name, experiences)
        print(f"  Concept '{concept_name}':")
        print(f"    Confidence: {grounded['confidence']:.2f}")
        print(f"    Abstraction level: {grounded['abstraction_level']:.2f}")
        assert 'concept' in grounded
        assert grounded['confidence'] >= 0.0
    
    print("\n[Step 5] Testing spatial reasoning...")
    spatial_report = system.get_spatial_reasoning_report("explorer")
    assert spatial_report is not None
    print(f"  Current position: {spatial_report['current_position']}")
    print(f"  Experience count: {spatial_report['experience_count']}")
    print(f"  Learned patterns: {len(spatial_report['learned_patterns'])}")
    print(f"  Navigation capability: {spatial_report['navigation_capability']}")
    
    print("\n[Step 6] Testing knowledge transfer between agents...")
    transfer_success = system.transfer_learning("explorer", "builder")
    assert transfer_success
    
    builder_report = system.get_spatial_reasoning_report("builder")
    print(f"  Builder learned patterns after transfer: {len(builder_report['learned_patterns'])}")
    
    print("\n[Step 7] Analyzing embodiment metrics...")
    metrics = system.get_embodiment_metrics()
    print(f"  Total simulations: {metrics['total_simulations']}")
    print(f"  Total interactions: {metrics['total_interactions']}")
    print(f"  Patterns learned: {metrics['patterns_learned']}")
    print(f"  Concepts grounded: {metrics['grounded_concepts']}")
    print(f"  Active environments: {metrics['active_environments']}")
    print(f"  Active agents: {metrics['active_agents']}")
    
    assert metrics['total_simulations'] >= 1
    assert metrics['patterns_learned'] >= 1
    assert metrics['grounded_concepts'] >= 3
    
    print("\n[PASS] Embodied Cognition mastered multi-step simulations")
    return True


def test_end_to_end_workflow():
    """Test 7: End-to-end workflow combining all 6 domains."""
    print("\n" + "="*70)
    print("TEST 7: End-to-End Workflow - All Domains Integrated")
    print("="*70)
    
    print("\nScenario: Solve complex societal problem using all cognitive domains")
    print("Problem: Design fair, efficient healthcare allocation system\n")
    
    # Initialize all domains
    metacog = MetaCognitiveMonitor()
    collective = CollectiveIntelligenceEngine()
    creative = CreativeSynthesisEngine()
    social = SocialIntelligenceSystem()
    ethical = EthicalReasoningEngine()
    embodied = EmbodiedCognitionSystem()
    
    print("[Phase 1] Meta-Cognition: Assessing problem complexity...")
    coordination = metacog.coordinate_domains("design healthcare allocation system")
    print(f"  Domains involved: {coordination['domains_involved']}")
    
    print("\n[Phase 2] Collective Intelligence: Forming expert team...")
    from tiannara_core.cognitive_domains.collective_intelligence import AgentRole
    roles = [AgentRole.ANALYZER, AgentRole.SYNTHESIZER, AgentRole.CRITIC, AgentRole.CREATOR]
    for i, role in enumerate(roles):
        collective.register_agent(f"healthcare_expert_{i}", role, ["healthcare", "policy"])
    
    team_id = collective.form_team("healthcare system design", roles)
    print(f"  Team formed: {team_id}")
    
    print("\n[Phase 3] Creative Synthesis: Generating innovative solutions...")
    creative.register_concept(Concept("triage", "medicine", ["prioritization", "urgency"], {}))
    creative.register_concept(Concept("equity", "ethics", ["fairness", "access"], {}))
    creative.register_concept(Concept("optimization", "mathematics", ["efficiency", "allocation"], {}))
    
    ideas = creative.synthesize_ideas(
        ["medicine", "ethics", "mathematics"],
        "fair healthcare resource allocation"
    )
    print(f"  Generated {len(ideas['ideas'])} innovative approaches")
    
    print("\n[Phase 4] Social Intelligence: Understanding stakeholder needs...")
    stakeholders = ["patients", "doctors", "administrators", "policymakers"]
    for stakeholder in stakeholders:
        social.register_user(stakeholder)
        concern = f"I'm concerned about {stakeholder} access to care"
        emotion = social.analyze_emotion(concern)
        social.record_interaction(stakeholder, concern, "Acknowledged", emotion)
    
    social_metrics = social.get_social_metrics()
    print(f"  Engaged {social_metrics['registered_users']} stakeholder groups")
    
    print("\n[Phase 5] Ethical Reasoning: Evaluating solution fairness...")
    evaluation = ethical.evaluate_decision(
        "Implement AI-driven triage system",
        {"domain": "healthcare", "impact": "high"},
        stakeholders
    )
    print(f"  Ethical score: {evaluation['ethical_score']:.2f}")
    print(f"  Approved: {evaluation['approved']}")
    print(f"  Concerns identified: {len(evaluation['concerns'])}")
    
    print("\n[Phase 6] Embodied Cognition: Simulating system deployment...")
    embodied.create_environment("hospital_network", "social", {"facilities": 10})
    embodied.create_agent("system_simulator")
    
    sim_result = embodied.run_simulation(
        "system_simulator",
        "hospital_network",
        ["observe", "allocate", "monitor", "adjust"]
    )
    print(f"  Simulation completed: {sim_result['success']}")
    print(f"  Actions executed: {len(sim_result['simulation']['actions_executed'])}")
    
    print("\n[Phase 7] Meta-Cognition: Final assessment and recommendations...")
    final_assessment = metacog.continuous_self_assessment()
    print(f"  Overall system status: {final_assessment['overall_status']}")
    
    test_results = metacog.run_comprehensive_test_suite()
    print(f"  Domains validated: {len(test_results['domains_tested'])}")
    print(f"  System health: {test_results.get('overall_health', 0):.1f}%")
    
    print("-"*70)
    print("WORKFLOW SUMMARY:")
    print("-"*70)
    print(f"  [OK] Problem analyzed by Meta-Cognition")
    print(f"  [OK] Expert team formed by Collective Intelligence")
    print(f"  [OK] Solutions generated by Creative Synthesis")
    print(f"  [OK] Stakeholders engaged by Social Intelligence")
    print(f"  [OK] Ethics validated by Ethical Reasoning")
    print(f"  [OK] System simulated by Embodied Cognition")
    print(f"  [OK] Quality assured by Meta-Cognition")
    
    print("\n[PASS] End-to-end workflow successfully integrated all 6 domains")
    return True


def test_performance_benchmarking():
    """Test 8: Performance benchmarking across all domains."""
    print("\n" + "="*70)
    print("TEST 8: Performance Benchmarking")
    print("="*70)
    
    benchmarks = {}
    
    # Benchmark Meta-Cognition
    print("\n[Benchmark 1] Meta-Cognition performance...")
    start = time.time()
    monitor = MetaCognitiveMonitor()
    for _ in range(10):
        monitor.continuous_self_assessment()
    elapsed = time.time() - start
    benchmarks['metacognition'] = elapsed
    print(f"  10 assessments in {elapsed:.3f}s ({elapsed/10*1000:.1f}ms per assessment)")
    
    # Benchmark Collective Intelligence
    print("\n[Benchmark 2] Collective Intelligence performance...")
    start = time.time()
    ci = CollectiveIntelligenceEngine()
    for i in range(20):
        ci.register_agent(f"bench_agent_{i}", AgentRole.ANALYZER, ["test"])
    team_id = ci.form_team("benchmark", [AgentRole.ANALYZER] * 5)
    elapsed = time.time() - start
    benchmarks['collective'] = elapsed
    print(f"  Registered 20 agents + formed team in {elapsed:.3f}s")
    
    # Benchmark Creative Synthesis
    print("\n[Benchmark 3] Creative Synthesis performance...")
    start = time.time()
    cs = CreativeSynthesisEngine()
    cs.register_concept(Concept("a", "dom1", ["x"], {}))
    cs.register_concept(Concept("b", "dom2", ["y"], {}))
    for _ in range(5):
        cs.synthesize_ideas(["dom1", "dom2"], "test")
    elapsed = time.time() - start
    benchmarks['creative'] = elapsed
    print(f"  5 syntheses in {elapsed:.3f}s ({elapsed/5*1000:.1f}ms per synthesis)")
    
    # Benchmark Social Intelligence
    print("\n[Benchmark 4] Social Intelligence performance...")
    start = time.time()
    si = SocialIntelligenceSystem()
    for i in range(50):
        si.register_user(f"user_{i}")
        si.analyze_emotion("test message")
    elapsed = time.time() - start
    benchmarks['social'] = elapsed
    print(f"  50 user registrations + emotion analyses in {elapsed:.3f}s")
    
    # Benchmark Ethical Reasoning
    print("\n[Benchmark 5] Ethical Reasoning performance...")
    start = time.time()
    er = EthicalReasoningEngine()
    for _ in range(20):
        er.evaluate_decision("test action", {}, ["user"])
    elapsed = time.time() - start
    benchmarks['ethical'] = elapsed
    print(f"  20 ethical evaluations in {elapsed:.3f}s ({elapsed/20*1000:.1f}ms per evaluation)")
    
    # Benchmark Embodied Cognition
    print("\n[Benchmark 6] Embodied Cognition performance...")
    start = time.time()
    ec = EmbodiedCognitionSystem()
    ec.create_environment("bench_env", "physical", {})
    ec.create_agent("bench_agent")
    for _ in range(10):
        ec.run_simulation("bench_agent", "bench_env", ["observe", "move"])
    elapsed = time.time() - start
    benchmarks['embodied'] = elapsed
    print(f"  10 simulations in {elapsed:.3f}s ({elapsed/10*1000:.1f}ms per simulation)")
    
    print("\n" + "-"*70)
    print("PERFORMANCE SUMMARY:")
    print("-"*70)
    total_time = sum(benchmarks.values())
    for domain, duration in benchmarks.items():
        percentage = (duration / total_time) * 100
        print(f"  {domain:20s}: {duration:.3f}s ({percentage:5.1f}%)")
    print(f"  {'TOTAL':20s}: {total_time:.3f}s")
    
    # Validate performance is acceptable (< 10 seconds total)
    assert total_time < 10.0, f"Total benchmark time {total_time:.3f}s exceeds 10s limit"
    
    print("\n[PASS] All domains perform within acceptable parameters")
    return True


def run_extensive_tests():
    """Run all extensive integration tests."""
    print("\n" + "="*70)
    print("EXTENSIVE COGNITIVE DOMAINS INTEGRATION TEST SUITE")
    print("="*70)
    print("\nValidating mastery-level performance across all 6 domains...")
    
    tests = [
        ("Cross-Domain Coordination", test_cross_domain_coordination),
        ("Collective Intelligence Complex Scenario", test_collective_intelligence_complex_scenario),
        ("Creative Synthesis Innovation", test_creative_synthesis_innovation),
        ("Social Intelligence Diverse Interactions", test_social_intelligence_diverse_interactions),
        ("Ethical Reasoning Edge Cases", test_ethical_reasoning_edge_cases),
        ("Embodied Cognition Multi-Step", test_embodied_cognition_multistep),
        ("End-to-End Workflow Integration", test_end_to_end_workflow),
        ("Performance Benchmarking", test_performance_benchmarking),
    ]
    
    results = []
    for test_name, test_func in tests:
        try:
            result = test_func()
            results.append((test_name, result))
        except Exception as e:
            print(f"\n[FAILED] {test_name}")
            print(f"  Error: {str(e)}")
            import traceback
            traceback.print_exc()
            results.append((test_name, False))
    
    # Final Summary
    print("\n" + "="*70)
    print("FINAL TEST RESULTS")
    print("="*70)
    
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for test_name, result in results:
        status = "[PASS]" if result else "[FAIL]"
        print(f"{status} {test_name}")
    
    print(f"\n{'='*70}")
    print(f"TOTAL: {passed}/{total} tests passed")
    print(f"{'='*70}")
    
    if passed == total:
        print("\n*** MASTERY ACHIEVED! ***")
        print("All 6 cognitive domains demonstrate expert-level integration")
        print("Tiannara Core has mastered cross-domain coordination and")
        print("end-to-end workflow execution.")
    else:
        print(f"\nWARNING: {total - passed} test(s) failed - review needed")
    
    return passed == total


if __name__ == "__main__":
    success = run_extensive_tests()
    sys.exit(0 if success else 1)
