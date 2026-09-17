"""
Test Football Prediction Engine
"""

import sys
from pathlib import Path

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.prediction import FootballPredictionEngine


def test_football_prediction():
    """Test the football prediction engine with sample match data"""
    
    print("=" * 80)
    print("TIANNARA FOOTBALL PREDICTION ENGINE - TEST")
    print("=" * 80)
    
    # Initialize engine
    print("\n1. Initializing Football Prediction Engine...")
    engine = FootballPredictionEngine(use_mock_data=True)
    print("   ✓ Engine initialized successfully")
    
    # Get engine status
    print("\n2. Checking engine status...")
    status = engine.get_engine_status()
    print(f"   Status: {status['status']}")
    print(f"   Agents: {status['agents_count']}")
    for agent_name in status['agent_names']:
        print(f"     - {agent_name}")
    
    # Get upcoming matches
    print("\n3. Fetching upcoming matches...")
    matches = engine.get_upcoming_matches(limit=5)
    print(f"   Found {len(matches)} upcoming matches:")
    for i, match in enumerate(matches, 1):
        print(f"   {i}. {match['home_team']} vs {match['away_team']}")
        print(f"      Competition: {match['competition']}")
        print(f"      Venue: {match['venue']}")
    
    if not matches:
        print("\n   ⚠ No matches available for testing")
        return
    
    # Test prediction on first match
    test_match_id = matches[0]['match_id']
    print(f"\n4. Generating prediction for: {matches[0]['home_team']} vs {matches[0]['away_team']}")
    print("-" * 80)
    
    prediction = engine.predict_match(test_match_id)
    
    if not prediction:
        print("   ✗ Failed to generate prediction")
        return
    
    print(f"\n   CONSENSUS PREDICTION:")
    print(f"   • Outcome: {prediction.final_outcome.upper()}")
    print(f"   • Confidence: {prediction.overall_confidence:.1%}")
    print(f"   • Agreement: {prediction.agreement_score:.1%}")
    print(f"   • Risk Level: {prediction.risk_assessment.upper()}")
    
    print(f"\n   AGENT PREDICTIONS:")
    for agent_pred in prediction.agent_predictions:
        print(f"\n   ┌─ {agent_pred.agent_name} ({agent_pred.agent_type})")
        print(f"   │  Outcome: {agent_pred.predicted_outcome.upper()}")
        print(f"   │  Confidence: {agent_pred.confidence:.1%}")
        print(f"   │  Score: {agent_pred.predicted_score['home']}-{agent_pred.predicted_score['away']}")
        print(f"   │  Processing Time: {agent_pred.processing_time_ms:.2f}ms")
        print(f"   │")
        print(f"   │  Key Reasoning:")
        for reason in agent_pred.reasoning[:2]:
            print(f"   │    • {reason}")
        print(f"   └" + "─" * 70)
    
    print(f"\n   DEBATE SUMMARY:")
    for point in prediction.debate_summary:
        print(f"   {point}")
    
    if prediction.dissenting_opinions:
        print(f"\n   DISSENTING OPINIONS:")
        for opinion in prediction.dissenting_opinions:
            print(f"   • {opinion['agent_name']} predicted {opinion['predicted_outcome'].upper()} "
                  f"(confidence: {opinion['confidence']:.1%})")
    
    if prediction.recommended_bet:
        print(f"\n   BETTING RECOMMENDATION:")
        rec = prediction.recommended_bet
        print(f"   • Type: {rec['bet_type']}")
        print(f"   • Stake: {rec['suggested_stake']}/10")
        print(f"   • Risk: {rec['risk_level'].upper()}")
        print(f"   • Value: {rec['value_rating']}")
        print(f"   • Note: {rec['note']}")
    
    # Get agent performance stats
    print(f"\n5. Agent Performance Statistics:")
    stats = engine.get_agent_stats()
    for stat in stats:
        print(f"   • {stat['name']}: {stat['prediction_count']} predictions, "
              f"avg confidence: {stat['avg_confidence']:.1%}")
    
    # Test batch prediction
    if len(matches) > 1:
        print(f"\n6. Testing batch prediction on {min(3, len(matches))} matches...")
        batch_ids = [m['match_id'] for m in matches[:3]]
        batch_predictions = engine.predict_multiple_matches(batch_ids)
        print(f"   ✓ Generated {len(batch_predictions)} predictions")
        
        for pred in batch_predictions:
            print(f"   • {pred.match_id}: {pred.final_outcome} "
                  f"(confidence: {pred.overall_confidence:.1%})")
    
    print("\n" + "=" * 80)
    print("TEST COMPLETED SUCCESSFULLY!")
    print("=" * 80)


if __name__ == "__main__":
    try:
        test_football_prediction()
    except Exception as e:
        print(f"\n✗ Test failed with error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
