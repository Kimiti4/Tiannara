"""
Test PredictionEngine Integration with Feature Engineering

Validates that the PredictionEngine correctly integrates feature engineering
for sports prediction tasks.
"""

import sys
from pathlib import Path
from datetime import datetime, timedelta

sys.path.insert(0, str(Path(__file__).parent))

from tiannara_api.engines.prediction import PredictionEngine


def print_section(title: str):
    print("\n" + "=" * 80)
    print(f"  {title}")
    print("=" * 80)


def test_engine_initialization():
    """Test 1: Engine initializes with feature engineering."""
    print_section("TEST 1: Engine Initialization")
    
    engine = PredictionEngine()
    
    print(f"Engine Name: {engine.name}")
    print(f"Engine Version: {engine.version}")
    print(f"Feature Engineering Available: {engine.feature_engineer is not None}")
    
    assert engine.feature_engineer is not None, "Feature engineer should be initialized"
    print("✅ PASSED: Feature Engineering integrated successfully")
    
    return True


def test_sports_prediction_basic():
    """Test 2: Basic sports prediction."""
    print_section("TEST 2: Basic Sports Prediction")
    
    engine = PredictionEngine()
    
    # Prepare test data for Arsenal vs Chelsea match
    now = datetime.now()
    
    request = {
        "task": "sports_prediction",
        "match_stats": {
            "shots_home": 14,
            "shots_away": 8,
            "shots_on_target_home": 7,
            "shots_on_target_away": 3,
            "dangerous_attacks_home": 18,
            "dangerous_attacks_away": 10,
            "possession_home": 62,
            "possession_away": 38,
            "red_cards": 0
        },
        "odds_history": [
            {"odds_home": 2.10, "timestamp": now - timedelta(minutes=20)},
            {"odds_home": 2.05, "timestamp": now - timedelta(minutes=15)},
            {"odds_home": 2.00, "timestamp": now - timedelta(minutes=10)},
            {"odds_home": 1.95, "timestamp": now - timedelta(minutes=5)},
            {"odds_home": 1.90, "timestamp": now}
        ],
        "news_events": [
            {
                "category": "injury",
                "sentiment": -0.7,
                "impact_weight": 0.85,
                "timestamp": now - timedelta(hours=2)
            }
        ],
        "model_probs": {"home": 0.55, "draw": 0.25, "away": 0.20},
        "market_probs": {"home": 0.48, "draw": 0.27, "away": 0.25}
    }
    
    result = engine.process(request)
    
    print(f"\nStatus: {result['status']}")
    print(f"Latency: {result['latency_ms']:.2f}ms")
    
    if result['status'] == 'success':
        prediction = result['result']['prediction']
        intelligence = result['result']['intelligence']
        
        print(f"\n📊 Prediction Results:")
        print(f"  Home Win: {prediction['home_win']:.1%}")
        print(f"  Draw: {prediction['draw']:.1%}")
        print(f"  Away Win: {prediction['away_win']:.1%}")
        print(f"  Predicted Outcome: {prediction['predicted_outcome'].upper()}")
        print(f"  Confidence: {prediction['confidence']:.1%}")
        
        print(f"\n🧠 Intelligence:")
        print(f"  Chaos Level: {intelligence['chaos_level']}")
        print(f"  Jackpot Potential: {'Yes' if intelligence['jackpot_potential'] else 'No'}")
        print(f"  Value Signal: {intelligence['value_signal']}")
        print(f"  Risk Level: {intelligence['risk_level']}")
        
        print(f"\n🔑 Key Drivers:")
        for driver in intelligence['key_drivers']:
            print(f"  • {driver}")
        
        # Validate structure
        assert 'prediction' in result['result'], "Should have prediction"
        assert 'features' in result['result'], "Should have features"
        assert 'intelligence' in result['result'], "Should have intelligence"
        assert prediction['home_win'] + prediction['draw'] + prediction['away_win'] > 0.99, "Probabilities should sum to ~1"
        
        print("\n✅ PASSED: Sports prediction generated correctly")
        return True
    else:
        print(f"\n❌ FAILED: {result.get('error', 'Unknown error')}")
        return False


def test_chaos_match_detection():
    """Test 3: High chaos match detection."""
    print_section("TEST 3: Chaos Match Detection")
    
    engine = PredictionEngine()
    
    now = datetime.now()
    
    # Create high-chaos scenario
    request = {
        "task": "sports_prediction",
        "match_stats": {
            "shots_home": 10,
            "shots_away": 10,
            "shots_on_target_home": 5,
            "shots_on_target_away": 5,
            "dangerous_attacks_home": 12,
            "dangerous_attacks_away": 12,
            "possession_home": 50,
            "possession_away": 50,
            "red_cards": 1  # Red card increases chaos
        },
        "odds_history": [
            {"odds_home": 2.50, "timestamp": now - timedelta(minutes=20)},
            {"odds_home": 2.20, "timestamp": now - timedelta(minutes=15)},
            {"odds_home": 2.80, "timestamp": now - timedelta(minutes=10)},
            {"odds_home": 2.10, "timestamp": now - timedelta(minutes=5)},
            {"odds_home": 2.60, "timestamp": now}  # Highly volatile
        ],
        "news_events": [
            {
                "category": "injury",
                "sentiment": -0.9,
                "impact_weight": 0.95,
                "timestamp": now - timedelta(minutes=30)
            },
            {
                "category": "tactical_change",
                "sentiment": -0.6,
                "impact_weight": 0.7,
                "timestamp": now - timedelta(hours=1)
            }
        ],
        "model_probs": {"home": 0.40, "draw": 0.30, "away": 0.30},
        "market_probs": {"home": 0.38, "draw": 0.32, "away": 0.30}
    }
    
    result = engine.process(request)
    
    if result['status'] == 'success':
        intelligence = result['result']['intelligence']
        
        print(f"Chaos Level: {intelligence['chaos_level']}")
        print(f"Jackpot Potential: {'✅ YES' if intelligence['jackpot_potential'] else '❌ NO'}")
        print(f"Risk Level: {intelligence['risk_level'].upper()}")
        
        # Should detect high chaos
        assert intelligence['chaos_level'] in ['moderate_uncertainty', 'chaos_match'], \
            "Should detect elevated chaos"
        
        print("\n✅ PASSED: Chaos match detected correctly")
        return True
    else:
        print(f"❌ FAILED: {result.get('error')}")
        return False


def test_value_opportunity_detection():
    """Test 4: Market inefficiency / value bet detection."""
    print_section("TEST 4: Value Opportunity Detection")
    
    engine = PredictionEngine()
    
    now = datetime.now()
    
    # Create scenario where model sees value market misses
    request = {
        "task": "sports_prediction",
        "match_stats": {
            "shots_home": 16,
            "shots_away": 6,
            "shots_on_target_home": 9,
            "shots_on_target_away": 2,
            "dangerous_attacks_home": 22,
            "dangerous_attacks_away": 7,
            "possession_home": 68,
            "possession_away": 32,
            "red_cards": 0
        },
        "odds_history": [
            {"odds_home": 2.00, "timestamp": now - timedelta(minutes=10)},
            {"odds_home": 1.95, "timestamp": now}
        ],
        "news_events": [],
        "model_probs": {"home": 0.70, "draw": 0.18, "away": 0.12},  # Model very confident
        "market_probs": {"home": 0.50, "draw": 0.28, "away": 0.22}  # Market less confident
    }
    
    result = engine.process(request)
    
    if result['status'] == 'success':
        intelligence = result['result']['intelligence']
        
        print(f"Value Signal: {intelligence['value_signal']}")
        print(f"Value Opportunity: {'✅ YES' if intelligence['value_opportunity'] else '❌ NO'}")
        
        # Should detect value opportunity (large gap between model and market)
        assert intelligence['value_opportunity'], "Should detect value opportunity"
        
        print("\n✅ PASSED: Value opportunity detected correctly")
        return True
    else:
        print(f"❌ FAILED: {result.get('error')}")
        return False


def test_health_check():
    """Test 5: Health check includes feature engineering status."""
    print_section("TEST 5: Health Check")
    
    engine = PredictionEngine()
    health = engine.get_health()
    
    print(f"Engine: {health['engine']}")
    print(f"Status: {health['status']}")
    print(f"Feature Engineering Available: {health['feature_engineering']['available']}")
    print(f"Feature Engineering Initialized: {health['feature_engineering']['initialized']}")
    
    assert health['feature_engineering']['available'], "Feature engineering should be available"
    assert health['feature_engineering']['initialized'], "Feature engineering should be initialized"
    
    print("\n✅ PASSED: Health check includes feature engineering status")
    return True


def main():
    """Run all integration tests."""
    print("=" * 80)
    print("  PREDICTION ENGINE + FEATURE ENGINEERING INTEGRATION TESTS")
    print("=" * 80)
    print("\nValidating integration of realtime.md formulas into PredictionEngine...")
    
    results = []
    
    try:
        # Test 1: Initialization
        result1 = test_engine_initialization()
        results.append(("Engine Initialization", result1))
        
        # Test 2: Basic sports prediction
        result2 = test_sports_prediction_basic()
        results.append(("Basic Sports Prediction", result2))
        
        # Test 3: Chaos detection
        result3 = test_chaos_match_detection()
        results.append(("Chaos Match Detection", result3))
        
        # Test 4: Value opportunity
        result4 = test_value_opportunity_detection()
        results.append(("Value Opportunity Detection", result4))
        
        # Test 5: Health check
        result5 = test_health_check()
        results.append(("Health Check", result5))
        
    except Exception as e:
        print(f"\n❌ Test failed with exception: {e}")
        import traceback
        traceback.print_exc()
        return False
    
    # Summary
    print_section("FINAL RESULTS")
    
    passed = sum(1 for _, r in results if r)
    total = len(results)
    
    for name, result in results:
        status = "✅ PASSED" if result else "❌ FAILED"
        print(f"  {status}: {name}")
    
    print(f"\n{'=' * 80}")
    print(f"  Total Tests: {total}")
    print(f"  Passed: {passed}")
    print(f"  Failed: {total - passed}")
    print(f"  Success Rate: {(passed/total*100) if total > 0 else 0:.1f}%")
    print(f"{'=' * 80}")
    
    if passed == total:
        print("\n🎉 ALL INTEGRATION TESTS PASSED!")
        print("   Feature Engineering successfully integrated into PredictionEngine.")
        print("\nIntegration Complete:")
        print("   ✅ FeatureEngineer initialized in PredictionEngine")
        print("   ✅ Sports prediction task route added")
        print("   ✅ Probability adjustment with momentum/chaos/news")
        print("   ✅ Confidence calculation based on feature quality")
        print("   ✅ Key drivers identification")
        print("   ✅ Risk assessment logic")
        print("   ✅ Health check updated")
    else:
        print(f"\n⚠️  {total - passed} test(s) failed. Review output above.")
    
    return passed == total


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
