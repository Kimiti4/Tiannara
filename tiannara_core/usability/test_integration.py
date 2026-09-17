"""
Usability Integration Test

Purpose: Test all usability components working together
Date: May 8, 2026
"""

from tiannara_core.usability.temporal_parser import TemporalExpressionParser
from tiannara_core.usability.context_preservation import ContextPreservationSystem
from tiannara_core.usability.intent_recognition import IntentRecognizer
from tiannara_core.usability.ux_enhancements import UXEnhancementEngine


def test_integrated_workflow():
    """Test complete user interaction workflow."""
    
    print("="*70)
    print("INTEGRATED USABILITY WORKFLOW TEST")
    print("="*70)
    
    # Initialize all systems
    parser = TemporalExpressionParser()
    cps = ContextPreservationSystem()
    recognizer = IntentRecognizer()
    ux_engine = UXEnhancementEngine()
    
    print("\n✅ All systems initialized\n")
    
    # Simulate user interactions
    conversations = [
        "Hi there!",
        "I prefer football predictions over basketball",
        "Predict tomorrow's match between Team A and Team B",
        "What are their recent stats?",
        "Show me the analysis in detail",
        "Thanks for the help!"
    ]
    
    print("🗣️  Simulating conversation flow:\n")
    
    for i, user_input in enumerate(conversations, 1):
        print(f"--- Turn {i} ---")
        print(f"User: {user_input}\n")
        
        # Step 1: Recognize intent
        intent = recognizer.recognize_intent(user_input)
        print(f"Intent: {intent.primary_intent} ({intent.category.value})")
        print(f"Confidence: {intent.confidence:.0%}")
        
        # Step 2: Extract temporal information
        temporal_results = parser.extract_all_temporal(user_input)
        if temporal_results:
            print("Temporal expressions found:")
            for t in temporal_results:
                print(f"  - '{t.original_text}' → {t.time_type.value}")
        
        # Step 3: Extract entities
        if intent.entities:
            print("Entities extracted:")
            for entity in intent.entities:
                print(f"  - {entity.entity_type}: {entity.value}")
        
        # Step 4: Store in context
        cps.add_context(
            content=user_input,
            context_type="conversation",
            source="user",
            importance=0.7
        )
        
        # Step 5: Generate simulated response
        if intent.primary_intent == "greeting":
            response_data = {"message": "Hello! How can I help you today?"}
            response_type = "information"
        elif intent.primary_intent == "set_preference":
            response_data = {"message": "Preference saved successfully"}
            response_type = "information"
        elif intent.primary_intent == "get_sports_prediction":
            response_data = {
                "sport": "Football",
                "outcome": "Team A Win",
                "confidence": 0.68,
                "reasoning": "Based on recent form and home advantage",
                "factors": ["Home record: 8W-1D-1L", "Away injuries: 2 key players"],
                "recommendation": "Moderate confidence prediction"
            }
            response_type = "prediction"
        elif intent.primary_intent == "get_team_analysis":
            response_data = {
                "subject": "Team A vs Team B Analysis",
                "key_finding": "Team A has strong home advantage",
                "details": "Last 5 home matches: 4W-1D, Goals: 12 scored, 3 conceded",
                "recommendations": ["Consider home form heavily", "Check away team injuries"]
            }
            response_type = "analysis"
        elif intent.primary_intent == "provide_feedback":
            response_data = {"message": "You're welcome! Happy to help anytime."}
            response_type = "information"
        else:
            response_data = {"message": "I understand your request. Processing..."}
            response_type = "information"
        
        # Step 6: Format response
        formatted = ux_engine.format_response(
            response_data,
            response_type=response_type,
            detail_level="medium"
        )
        
        # Step 7: Personalize
        user_ctx = {
            "name": "User",
            "interaction_count": i,
            "timezone": "UTC"
        }
        personalized = ux_engine.personalize_response(formatted, user_ctx)
        
        print(f"\nAgent Response:\n{personalized}\n")
        
        # Step 8: Store conversation turn
        cps.add_conversation_turn(
            user_message=user_input,
            agent_response=personalized,
            intent=intent.primary_intent
        )
        
        print()
    
    # Show final statistics
    print("="*70)
    print("FINAL STATISTICS")
    print("="*70)
    
    print("\n📊 Intent Recognition Stats:")
    intent_stats = recognizer.get_stats()
    print(f"  Total recognized: {intent_stats['total_recognized']}")
    print(f"  Average confidence: {intent_stats['average_confidence']:.0%}")
    
    print("\n💾 Context Preservation Stats:")
    context_stats = cps.get_stats()
    print(f"  Total context items: {context_stats['total_context_items']}")
    print(f"  Conversation turns: {context_stats['conversation_turns']}")
    print(f"  User preferences: {context_stats['user_preferences_count']}")
    
    print("\n✨ UX Enhancement Stats:")
    ux_stats = ux_engine.get_ux_stats()
    print(f"  Responses formatted: {ux_stats['responses_formatted']}")
    print(f"  Help requests served: {ux_stats['help_requests_served']}")
    print(f"  Personalizations applied: {ux_stats['personalization_applied']}")
    
    # Test context retrieval
    print("\n🔍 Testing Context Retrieval:")
    relevant = cps.get_relevant_context("football prediction preferences", max_items=3)
    print(f"Query: 'football prediction preferences'")
    print(f"Found {len(relevant)} relevant items:")
    for item in relevant:
        print(f"  - [{item.context_type}] {item.content[:60]}...")
    
    # Test context summary
    print("\n📋 Context Summary:")
    summary = cps.summarize_context()
    print(summary[:300] + "...")
    
    print("\n" + "="*70)
    print("✅ INTEGRATED WORKFLOW TEST COMPLETE")
    print("="*70)


if __name__ == "__main__":
    test_integrated_workflow()
