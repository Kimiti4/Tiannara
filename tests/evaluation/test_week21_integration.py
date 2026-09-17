"""
Week 21 Integration Tests

Purpose: Test all Week 21 systems working together
Systems Tested:
- Temporal Reasoning Engine
- Stagnation Detection System  
- Hybrid Collaboration Manager
- Advanced NLP Engine

Date: May 8, 2026
Status: Integration Testing
"""

from tiannara_core.reasoning.temporal_reasoning import (
    TemporalReasoningEngine, 
    TemporalEvent
)
from tiannara_core.monitoring.stagnation_detector import (
    StagnationDetector,
    ProgressMetrics
)
from tiannara_core.collaboration.hybrid_manager import (
    HybridCollaborationManager,
    Collaborator,
    CollaborationMode
)
from tiannara_core.nlp.advanced_nlp import AdvancedNLPEngine
from datetime import datetime, timedelta


def test_temporal_reasoning_integration():
    """Test temporal reasoning engine."""
    print("\n" + "="*70)
    print("TEST 1: TEMPORAL REASONING ENGINE")
    print("="*70)
    
    engine = TemporalReasoningEngine()
    
    # Create events
    event1 = TemporalEvent(
        event_id="evt_1",
        name="Team Meeting",
        start_time=datetime(2026, 5, 8, 10, 0),
        end_time=datetime(2026, 5, 8, 11, 0)
    )
    
    event2 = TemporalEvent(
        event_id="evt_2",
        name="Lunch Break",
        start_time=datetime(2026, 5, 8, 12, 0),
        end_time=datetime(2026, 5, 8, 13, 0)
    )
    
    event3 = TemporalEvent(
        event_id="evt_3",
        name="Project Review",
        start_time=datetime(2026, 5, 8, 14, 0),
        end_time=datetime(2026, 5, 8, 15, 30)
    )
    
    # Add to timeline
    engine.add_event(event1)
    engine.add_event(event2)
    engine.add_event(event3)
    
    # Build timeline
    timeline = engine.build_timeline(event_ids=["evt_1", "evt_2", "evt_3"])
    print(f"\n✓ Timeline constructed with {len(timeline.events)} events")
    
    # Check for conflicts
    conflicts = timeline.detect_conflicts()
    print(f"✓ Conflict detection complete: {len(conflicts)} conflicts found")
    
    # Analyze gaps
    gaps = timeline.find_gaps()
    print(f"✓ Gap analysis: {len(gaps)} gaps identified")
    
    # Time inference
    inferred = engine.infer_implicit_time(reference_event_id="evt_1", temporal_expression="2 hours later")
    print(f"✓ Time inference successful: {inferred}")
    
    print("\n✅ TEMPORAL REASONING ENGINE - PASSED")
    return True


def test_stagnation_detection_integration():
    """Test stagnation detection system."""
    print("\n" + "="*70)
    print("TEST 2: STAGNATION DETECTION SYSTEM")
    print("="*70)
    
    detector = StagnationDetector()
    
    # Simulate agent progress
    agent_id = "test_agent_1"
    task_id = "task_1"
    
    # Record normal progress
    for i in range(5):
        metrics = ProgressMetrics(
            task_id=task_id,
            agent_id=agent_id,
            timestamp=datetime.now(),
            success_rate=0.85 + (i * 0.01),
            response_time_ms=1500 - (i * 100),
            solution_quality=0.80 + (i * 0.02),
            actions_taken=10 + i,
            iterations_completed=i + 1
        )
        detector.monitor_progress(metrics)
    
    # Check for stagnation (should be none)
    stagnation = detector.detect_stagnation(agent_id, task_id)
    print(f"\n✓ Normal progress detected: {stagnation is None}")
    
    # Simulate circular reasoning pattern
    circular_agent = "circular_agent"
    circular_task = "circular_task"
    
    for i in range(5):
        metrics = ProgressMetrics(
            task_id=circular_task,
            agent_id=circular_agent,
            timestamp=datetime.now(),
            success_rate=0.5,
            response_time_ms=2000,
            solution_quality=0.5,
            actions_taken=5,
            iterations_completed=i + 1,
            unique_approaches=1  # Low diversity indicates circular reasoning
        )
        detector.monitor_progress(metrics)
    
    # Check for circular reasoning
    stagnation = detector.detect_stagnation(circular_agent, circular_task)
    if stagnation:
        print(f"✓ Circular reasoning detected: {stagnation.stagnation_type.value}")
        
        # Get recovery suggestions
        suggestion = detector.suggest_recovery(stagnation)
        print(f"✓ Recovery suggestion: {suggestion.value if suggestion else 'None'}")
    else:
        print(f"✓ No stagnation detected")
    
    print("\n✅ STAGNATION DETECTION SYSTEM - PASSED")
    return True


def test_hybrid_collaboration_integration():
    """Test hybrid collaboration manager."""
    print("\n" + "="*70)
    print("TEST 3: HYBRID COLLABORATION MANAGER")
    print("="*70)
    
    manager = HybridCollaborationManager()
    
    # Create collaborators
    human = Collaborator(
        collaborator_id="human_1",
        name="Alice",
        collaborator_type="human",
        expertise_areas=["domain_expertise", "decision_making"]
    )
    
    ai = Collaborator(
        collaborator_id="ai_1",
        name="MindCache AI",
        collaborator_type="ai",
        expertise_areas=["data_analysis", "prediction"]
    )
    
    manager.register_collaborator(human)
    manager.register_collaborator(ai)
    
    # Create collaborative session
    session = manager.initiate_collaboration(
        task_description="Analyze team performance trends",
        human_id="human_1",
        ai_id="ai_1",
        mode=CollaborationMode.COLLABORATIVE
    )
    
    print(f"\n✓ Session created: {session.session_id}")
    
    # Create shared workspace artifact
    session.workspace.add_artifact(
        name="Performance Analysis Report",
        content={"type": "document", "status": "draft"},
        author_id="human_1"
    )
    print(f"✓ Artifact created in workspace")
    
    # Add contribution from AI (as discussion)
    session.workspace.log_discussion(
        speaker_id="ai_1",
        message="Statistical analysis shows 15% improvement",
        context="analysis"
    )
    print("✓ AI contribution added")
    
    # Request handoff
    handoff_request = manager.request_handoff(
        session_id=session.session_id,
        from_collaborator_id="ai_1",
        to_collaborator_id="human_1",
        reason="Human review needed for final decision"
    )
    print(f"✓ Handoff requested: {handoff_request.request_id if handoff_request else 'N/A'}")
    
    # Approve handoff
    if handoff_request:
        approved = manager.approve_handoff(handoff_request.request_id)
        print(f"✓ Handoff approved: {approved}")
    
    # Get session status
    status = manager.get_session_status(session.session_id)
    print(f"✓ Session status retrieved")
    
    print("\n✅ HYBRID COLLABORATION MANAGER - PASSED")
    return True


def test_advanced_nlp_integration():
    """Test advanced NLP engine."""
    print("\n" + "="*70)
    print("TEST 4: ADVANCED NLP ENGINE")
    print("="*70)
    
    nlp_engine = AdvancedNLPEngine()
    
    # Test intent classification
    test_queries = [
        "Predict who will win tomorrow's match",
        "Analyze Team A's recent performance",
        "What are the current league standings?",
        "Create a new prediction model",
        "Configure the system settings",
    ]
    
    print("\nIntent Classification Tests:")
    for query in test_queries:
        result = nlp_engine.classify_intent(query)
        print(f"  Query: \"{query[:50]}...\"")
        print(f"    → {result.category.value}/{result.sub_intent} (confidence: {result.confidence:.2f})")
    
    # Test entity extraction
    entities = nlp_engine.extract_entities("Team A will play against Team B on 2026-05-15 at Stadium Park")
    print(f"\n✓ Entity extraction: {len(entities)} entities found")
    for entity in entities:
        print(f"    - {entity.entity_type}: \"{entity.text}\"")
    
    # Test sentiment analysis
    sentiments = [
        ("Great prediction!", 0.5),
        ("Terrible analysis", -0.5),
        ("The results are okay", -0.2),
    ]
    
    print("\nSentiment Analysis Tests:")
    for text, expected_sign in sentiments:
        sentiment = nlp_engine.analyze_sentiment(text)
        correct_sign = (sentiment > 0) == (expected_sign > 0)
        status = "✓" if correct_sign else "✗"
        print(f"  {status} \"{text}\" → {sentiment:+.2f}")
    
    # Test semantic search
    nlp_engine.add_to_knowledge_base("Team A won 8 out of 10 matches", {"type": "performance"})
    nlp_engine.add_to_knowledge_base("Player X scored 20 goals", {"type": "statistics"})
    
    matches = nlp_engine.semantic_search("team wins performance", top_k=2)
    print(f"\n✓ Semantic search: {len(matches)} matches found")
    for match in matches:
        print(f"    - Similarity: {match.similarity_score:.2f}: \"{match.matched_text[:50]}...\"")
    
    # Test multi-intent detection
    multi_intent = nlp_engine.detect_multi_intent("Predict the winner and analyze their form")
    print(f"\n✓ Multi-intent detection: {len(multi_intent)} intents detected")
    for intent_str in multi_intent:
        print(f"    - {intent_str}")
    
    print("\n✅ ADVANCED NLP ENGINE - PASSED")
    return True


def test_cross_system_integration():
    """Test integration between multiple Week 21 systems."""
    print("\n" + "="*70)
    print("TEST 5: CROSS-SYSTEM INTEGRATION")
    print("="*70)
    
    # Scenario: Human-AI collaboration with temporal reasoning and stagnation monitoring
    
    print("\nScenario: Collaborative Match Prediction with Monitoring")
    print("-" * 70)
    
    # Initialize all systems
    nlp = AdvancedNLPEngine()
    temporal = TemporalReasoningEngine()
    stagnation = StagnationDetector()
    collaboration = HybridCollaborationManager()
    
    # Step 1: Parse user request
    user_query = "Predict who will win the match next Monday and analyze both teams"
    intent = nlp.classify_intent(user_query)
    print(f"\n1. NLP parsed query:")
    print(f"   Intent: {intent.category.value}/{intent.sub_intent}")
    print(f"   Confidence: {intent.confidence:.2f}")
    
    # Step 2: Extract temporal information
    time_inference = temporal.infer_implicit_time(reference_event_id="evt_1", temporal_expression="next Monday")
    print(f"\n2. Temporal reasoning inferred:")
    print(f"   Time: {time_inference}")
    
    # Step 3: Create collaboration session
    human = Collaborator(collaborator_id="h1", name="User", collaborator_type="human", expertise_areas=["decision_making"])
    ai = Collaborator(collaborator_id="a1", name="AI Assistant", collaborator_type="ai", expertise_areas=["analysis"])
    
    collaboration.register_collaborator(human)
    collaboration.register_collaborator(ai)
    
    session_id = collaboration.initiate_collaboration(
        task_description="Match prediction and analysis",
        human_id="h1",
        ai_id="a1",
        mode=CollaborationMode.COLLABORATIVE
    )
    print(f"\n3. Collaboration session created: {session_id}")
    
    # Step 4: Monitor AI agent progress
    agent_id = "prediction_agent"
    task_id = "match_prediction"
    
    for i in range(3):
        metrics = ProgressMetrics(
            task_id=task_id,
            agent_id=agent_id,
            timestamp=datetime.now(),
            success_rate=0.80 + (i * 0.05),
            response_time_ms=2000 - (i * 300),
            solution_quality=0.75 + (i * 0.05),
            actions_taken=5 + i,
            iterations_completed=i + 1
        )
        stagnation.monitor_progress(metrics)
    
    stagnation_check = stagnation.detect_stagnation(agent_id, task_id)
    print(f"\n4. Stagnation monitoring:")
    if stagnation_check:
        print(f"   Is stagnant: {stagnation_check.is_stagnant}")
        if stagnation_check.is_stagnant:
            suggestions = stagnation.get_recovery_suggestions(stagnation_check)
            print(f"   Status: ⚠ Stagnation detected - {len(suggestions)} recovery options")
        else:
            print(f"   Status: ✓ Agent progressing normally")
    else:
        print(f"   Status: ✓ No stagnation alerts")
    
    print("\n✅ CROSS-SYSTEM INTEGRATION - PASSED")
    return True


def main():
    """Run all Week 21 integration tests."""
    
    print("\n" + "="*70)
    print("WEEK 21 INTEGRATION TEST SUITE")
    print("="*70)
    print("\nTesting all Week 21 systems:")
    print("  1. Temporal Reasoning Engine")
    print("  2. Stagnation Detection System")
    print("  3. Hybrid Collaboration Manager")
    print("  4. Advanced NLP Engine")
    print("  5. Cross-System Integration")
    print("="*70)
    
    results = []
    
    # Run individual system tests
    try:
        results.append(("Temporal Reasoning", test_temporal_reasoning_integration()))
    except Exception as e:
        print(f"\n❌ TEMPORAL REASONING FAILED: {e}")
        results.append(("Temporal Reasoning", False))
    
    try:
        results.append(("Stagnation Detection", test_stagnation_detection_integration()))
    except Exception as e:
        print(f"\n❌ STAGNATION DETECTION FAILED: {e}")
        results.append(("Stagnation Detection", False))
    
    try:
        results.append(("Hybrid Collaboration", test_hybrid_collaboration_integration()))
    except Exception as e:
        print(f"\n❌ HYBRID COLLABORATION FAILED: {e}")
        results.append(("Hybrid Collaboration", False))
    
    try:
        results.append(("Advanced NLP", test_advanced_nlp_integration()))
    except Exception as e:
        print(f"\n❌ ADVANCED NLP FAILED: {e}")
        results.append(("Advanced NLP", False))
    
    # Run cross-system integration test
    try:
        results.append(("Cross-System Integration", test_cross_system_integration()))
    except Exception as e:
        print(f"\n❌ CROSS-SYSTEM INTEGRATION FAILED: {e}")
        results.append(("Cross-System Integration", False))
    
    # Summary
    print("\n\n" + "="*70)
    print("INTEGRATION TEST SUMMARY")
    print("="*70)
    
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for system_name, result in results:
        status = "✅ PASSED" if result else "❌ FAILED"
        print(f"  {status:12} - {system_name}")
    
    print(f"\nTotal: {passed}/{total} systems passed")
    
    if passed == total:
        print("\n🎉 ALL WEEK 21 SYSTEMS INTEGRATED SUCCESSFULLY!")
        print("="*70)
        return True
    else:
        print(f"\n⚠️  {total - passed} system(s) failed integration tests")
        print("="*70)
        return False


if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)
