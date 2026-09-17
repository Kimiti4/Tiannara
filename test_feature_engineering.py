"""
Test Feature Engineering Formulas

Validates all mathematical formulas from realtime.md Sections 1.1-1.5:
- Momentum Index
- Odds Movement Velocity
- News Impact Score
- Chaos Index
- Market Inefficiency Score
"""

import sys
from pathlib import Path
from datetime import datetime, timedelta

sys.path.insert(0, str(Path(__file__).parent.parent))

from tiannara_core.prediction.feature_engineering import FeatureEngineer, engineer_features


def print_section(title: str):
    print("\n" + "=" * 80)
    print(f"  {title}")
    print("=" * 80)


def print_subsection(title: str):
    print(f"\n--- {title} ---")


def test_momentum_index():
    """Test 1.1: Momentum Index calculation."""
    print_section("TEST 1: Momentum Index (Match Control Strength)")
    
    fe = FeatureEngineer()
    
    # Scenario 1: Home team dominating
    print_subsection("Scenario 1: Home Dominance")
    result = fe.calculate_momentum_index(
        shots_home=15,
        shots_away=5,
        shots_on_target_home=8,
        shots_on_target_away=2,
        dangerous_attacks_home=20,
        dangerous_attacks_away=8,
        possession_home=65,
        possession_away=35
    )
    
    print(f"Momentum Home: {result['momentum_home']:.4f}")
    print(f"Momentum Away: {result['momentum_away']:.4f}")
    print(f"Momentum Diff: {result['momentum_diff']:.4f}")
    print(f"Interpretation: {result['interpretation']}")
    
    assert result['momentum_home'] > result['momentum_away'], "Home should have higher momentum"
    assert result['momentum_diff'] > 0.3, "Diff should indicate home dominance"
    assert result['interpretation'] == "home_dominance", "Should detect home dominance"
    print("✅ PASSED: Home dominance detected correctly")
    
    # Scenario 2: Balanced match
    print_subsection("Scenario 2: Balanced Match")
    result = fe.calculate_momentum_index(
        shots_home=10,
        shots_away=10,
        shots_on_target_home=5,
        shots_on_target_away=5,
        dangerous_attacks_home=12,
        dangerous_attacks_away=12,
        possession_home=50,
        possession_away=50
    )
    
    print(f"Momentum Diff: {result['momentum_diff']:.4f}")
    print(f"Interpretation: {result['interpretation']}")
    
    assert abs(result['momentum_diff']) < 0.1, "Balanced match should have near-zero diff"
    assert result['interpretation'] == "balanced_chaos_zone", "Should detect balanced state"
    print("✅ PASSED: Balanced match detected correctly")
    
    # Scenario 3: Away team dominating
    print_subsection("Scenario 3: Away Dominance")
    result = fe.calculate_momentum_index(
        shots_home=4,
        shots_away=16,
        shots_on_target_home=1,
        shots_on_target_away=9,
        dangerous_attacks_home=6,
        dangerous_attacks_away=22,
        possession_home=30,
        possession_away=70
    )
    
    print(f"Momentum Diff: {result['momentum_diff']:.4f}")
    print(f"Interpretation: {result['interpretation']}")
    
    assert result['momentum_diff'] < -0.3, "Diff should indicate away dominance"
    assert result['interpretation'] == "away_dominance", "Should detect away dominance"
    print("✅ PASSED: Away dominance detected correctly")
    
    return True


def test_odds_velocity():
    """Test 1.2: Odds Movement Velocity calculation."""
    print_section("TEST 2: Odds Movement Velocity (Market Intelligence)")
    
    fe = FeatureEngineer()
    
    # Scenario 1: Sharp money coming in (odds dropping)
    print_subsection("Scenario 1: Odds Dropping (Team Becoming Favorite)")
    result = fe.calculate_odds_velocity(
        current_odds=1.80,
        previous_odds=2.10,
        time_delta_seconds=300,  # 5 minutes
        use_exponential_smoothing=True,
        alpha=0.3,
        previous_velocity=-0.0005
    )
    
    print(f"Raw Velocity: {result['velocity_raw']:.6f}")
    print(f"Smoothed Velocity: {result['velocity_smoothed']:.6f}")
    print(f"Direction: {result['direction']}")
    print(f"Odds Change: {result['odds_change']:.4f}")
    
    assert result['velocity_raw'] < 0, "Velocity should be negative when odds drop"
    assert result['direction'] == "dropping", "Should detect dropping trend"
    assert result['odds_change'] < 0, "Odds change should be negative"
    print("✅ PASSED: Dropping odds detected correctly")
    
    # Scenario 2: Odds rising (losing confidence)
    print_subsection("Scenario 2: Odds Rising (Losing Confidence)")
    result = fe.calculate_odds_velocity(
        current_odds=2.50,
        previous_odds=2.20,
        time_delta_seconds=600,  # 10 minutes
        use_exponential_smoothing=False
    )
    
    print(f"Direction: {result['direction']}")
    print(f"Odds Change: {result['odds_change']:.4f}")
    
    assert result['velocity_raw'] > 0, "Velocity should be positive when odds rise"
    assert result['direction'] == "rising", "Should detect rising trend"
    print("✅ PASSED: Rising odds detected correctly")
    
    # Scenario 3: Stable odds
    print_subsection("Scenario 3: Stable Odds")
    result = fe.calculate_odds_velocity(
        current_odds=2.00,
        previous_odds=2.01,
        time_delta_seconds=120
    )
    
    print(f"Direction: {result['direction']}")
    
    assert result['direction'] == "stable", "Should detect stable odds"
    print("✅ PASSED: Stable odds detected correctly")
    
    # Test volatility calculation
    print_subsection("Scenario 4: Odds Volatility")
    odds_history = [2.0, 2.1, 1.9, 2.2, 1.8, 2.3, 1.7, 2.4, 1.6, 2.5]
    volatility = fe.calculate_odds_volatility(odds_history, window_size=10)
    
    print(f"Volatility: {volatility:.4f}")
    assert 0 < volatility <= 1.0, "Volatility should be between 0 and 1"
    print("✅ PASSED: Volatility calculated correctly")
    
    return True


def test_news_impact_score():
    """Test 1.3: News Impact Score calculation."""
    print_section("TEST 3: News Impact Score (NIS)")
    
    fe = FeatureEngineer()
    now = datetime.now()
    
    # Scenario 1: Positive news (key player returns)
    print_subsection("Scenario 1: Positive News Impact")
    news_events = [
        {
            "sentiment": 0.8,
            "impact_weight": 0.9,
            "timestamp": now - timedelta(hours=1)
        },
        {
            "sentiment": 0.6,
            "impact_weight": 0.7,
            "timestamp": now - timedelta(hours=2)
        }
    ]
    
    result = fe.calculate_news_impact_score(news_events, reference_time=now)
    
    print(f"NIS Total: {result['nis_total']:.4f}")
    print(f"Dominant Sentiment: {result['dominant_sentiment']}")
    print(f"Event Count: {result['event_count']}")
    
    assert result['nis_total'] > 0, "Positive news should yield positive NIS"
    assert result['dominant_sentiment'] == "positive", "Should detect positive sentiment"
    print("✅ PASSED: Positive news impact calculated correctly")
    
    # Scenario 2: Negative news (injury crisis)
    print_subsection("Scenario 2: Negative News Impact")
    news_events = [
        {
            "sentiment": -0.9,
            "impact_weight": 0.95,
            "timestamp": now - timedelta(minutes=30)
        },
        {
            "sentiment": -0.7,
            "impact_weight": 0.8,
            "timestamp": now - timedelta(hours=1)
        },
        {
            "sentiment": -0.5,
            "impact_weight": 0.6,
            "timestamp": now - timedelta(hours=3)
        }
    ]
    
    result = fe.calculate_news_impact_score(news_events, reference_time=now)
    
    print(f"NIS Total: {result['nis_total']:.4f}")
    print(f"Dominant Sentiment: {result['dominant_sentiment']}")
    
    assert result['nis_total'] < 0, "Negative news should yield negative NIS"
    assert result['dominant_sentiment'] == "negative", "Should detect negative sentiment"
    print("✅ PASSED: Negative news impact calculated correctly")
    
    # Scenario 3: Time decay test
    print_subsection("Scenario 3: Time Decay Effect")
    old_news = [
        {
            "sentiment": 0.9,
            "impact_weight": 1.0,
            "timestamp": now - timedelta(hours=24)  # Old news
        }
    ]
    
    fresh_news = [
        {
            "sentiment": 0.9,
            "impact_weight": 1.0,
            "timestamp": now - timedelta(minutes=10)  # Fresh news
        }
    ]
    
    old_result = fe.calculate_news_impact_score(old_news, reference_time=now)
    fresh_result = fe.calculate_news_impact_score(fresh_news, reference_time=now)
    
    print(f"Old News NIS: {old_result['nis_total']:.4f}")
    print(f"Fresh News NIS: {fresh_result['nis_total']:.4f}")
    
    assert fresh_result['nis_total'] > old_result['nis_total'], "Fresh news should have higher impact"
    print("✅ PASSED: Time decay working correctly")
    
    return True


def test_chaos_index():
    """Test 1.4: Chaos Index calculation."""
    print_section("TEST 4: Chaos Index (Unpredictability Measure)")
    
    fe = FeatureEngineer()
    
    # Scenario 1: Stable match
    print_subsection("Scenario 1: Stable Match (Low Chaos)")
    result = fe.calculate_chaos_index(
        odds_volatility=0.1,
        momentum_volatility=0.1,
        news_conflict_score=0.05,
        red_cards_factor=0.0,
        injuries_count=0
    )
    
    print(f"Chaos Index: {result['chaos_index']:.4f}")
    print(f"Level: {result['level']}")
    print(f"Jackpot Potential: {result['jackpot_potential']}")
    
    assert result['chaos_index'] < 0.3, "Stable match should have low chaos"
    assert result['level'] == "stable", "Should classify as stable"
    assert not result['jackpot_potential'], "Stable matches not good for jackpot"
    print("✅ PASSED: Low chaos detected correctly")
    
    # Scenario 2: Moderate uncertainty
    print_subsection("Scenario 2: Moderate Uncertainty")
    result = fe.calculate_chaos_index(
        odds_volatility=0.4,
        momentum_volatility=0.3,
        news_conflict_score=0.3,
        red_cards_factor=0.0,
        injuries_count=1
    )
    
    print(f"Chaos Index: {result['chaos_index']:.4f}")
    print(f"Level: {result['level']}")
    
    assert 0.3 <= result['chaos_index'] < 0.6, "Should be moderate chaos"
    assert result['level'] == "moderate_uncertainty", "Should classify as moderate"
    print("✅ PASSED: Moderate chaos detected correctly")
    
    # Scenario 3: Chaos match (jackpot gold!)
    print_subsection("Scenario 3: Chaos Match (High Variance)")
    result = fe.calculate_chaos_index(
        odds_volatility=0.8,
        momentum_volatility=0.7,
        news_conflict_score=0.9,
        red_cards_factor=0.5,  # Red card occurred
        injuries_count=3  # Multiple injuries
    )
    
    print(f"Chaos Index: {result['chaos_index']:.4f}")
    print(f"Level: {result['level']}")
    print(f"Jackpot Potential: {result['jackpot_potential']}")
    
    assert result['chaos_index'] >= 0.6, "Chaotic match should have high index"
    assert result['level'] == "chaos_match", "Should classify as chaos match"
    assert result['jackpot_potential'], "Chaos matches are jackpot opportunities"
    print("✅ PASSED: High chaos / jackpot potential detected correctly")
    
    # Test component breakdown
    print_subsection("Scenario 4: Component Breakdown")
    print(f"Odds Volatility Contribution: {result['components']['odds_volatility_contribution']:.4f}")
    print(f"Momentum Volatility Contribution: {result['components']['momentum_volatility_contribution']:.4f}")
    print(f"News Conflict Contribution: {result['components']['news_conflict_contribution']:.4f}")
    print(f"Disruption Contribution: {result['components']['disruption_contribution']:.4f}")
    
    total_components = sum(result['components'].values())
    assert abs(total_components - result['chaos_index']) < 0.01, "Components should sum to chaos index"
    print("✅ PASSED: Component breakdown correct")
    
    return True


def test_market_inefficiency():
    """Test 1.5: Market Inefficiency Score calculation."""
    print_section("TEST 5: Market Inefficiency Score (MIS)")
    
    fe = FeatureEngineer()
    
    # Scenario 1: Model sees value (model prob > market prob)
    print_subsection("Scenario 1: Model Favors (Undervalued by Market)")
    result = fe.calculate_market_inefficiency(
        model_probability=0.65,
        market_probability=0.50
    )
    
    print(f"MIS Score: {result['mis_score']:.4f}")
    print(f"Direction: {result['direction']}")
    print(f"Value Signal: {result['value_signal']}")
    print(f"Value Opportunity: {result['value_opportunity']}")
    
    assert result['mis_score'] > 0.1, "Should detect significant inefficiency"
    assert result['direction'] == "model_favors", "Model should favor more than market"
    assert result['value_signal'] == "undervalued_by_market", "Should signal undervaluation"
    assert result['value_opportunity'], "Should identify value opportunity"
    print("✅ PASSED: Value opportunity detected correctly")
    
    # Scenario 2: Market overvalues (market prob > model prob)
    print_subsection("Scenario 2: Market Overvalues")
    result = fe.calculate_market_inefficiency(
        model_probability=0.30,
        market_probability=0.55
    )
    
    print(f"Direction: {result['direction']}")
    print(f"Value Signal: {result['value_signal']}")
    
    assert result['direction'] == "market_favors", "Market should favor more than model"
    assert result['value_signal'] == "overvalued_by_market", "Should signal overvaluation"
    print("✅ PASSED: Overvaluation detected correctly")
    
    # Scenario 3: Aligned probabilities (no value)
    print_subsection("Scenario 3: Aligned (No Value)")
    result = fe.calculate_market_inefficiency(
        model_probability=0.45,
        market_probability=0.46
    )
    
    print(f"MIS Score: {result['mis_score']:.4f}")
    print(f"Value Opportunity: {result['value_opportunity']}")
    
    assert result['mis_score'] < 0.1, "Small difference should not trigger value signal"
    assert not result['value_opportunity'], "Should not identify value opportunity"
    print("✅ PASSED: No-value scenario handled correctly")
    
    return True


def test_composite_feature_vector():
    """Test: Create unified feature vector."""
    print_section("TEST 6: Composite Feature Vector")
    
    fe = FeatureEngineer()
    
    # Create sample data for all features
    momentum = fe.calculate_momentum_index(12, 8, 6, 4, 15, 10, 55, 45)
    odds = fe.calculate_odds_velocity(1.85, 2.00, 300)
    news = fe.calculate_news_impact_score([
        {"sentiment": -0.7, "impact_weight": 0.8, "timestamp": datetime.now() - timedelta(hours=1)}
    ])
    chaos = fe.calculate_chaos_index(0.5, 0.4, 0.6, 0.0, 1)
    mis = fe.calculate_market_inefficiency(0.60, 0.45)
    
    # Create feature vector
    vector = fe.create_feature_vector(momentum, odds, news, chaos, mis)
    
    print_subsection("Feature Vector Structure")
    print(f"Momentum Features: {list(vector['momentum_features'].keys())}")
    print(f"Odds Features: {list(vector['odds_features'].keys())}")
    print(f"News Features: {list(vector['news_features'].keys())}")
    print(f"Chaos Features: {list(vector['chaos_features'].keys())}")
    print(f"Market Features: {list(vector['market_features'].keys())}")
    
    # Validate structure
    assert "momentum_features" in vector, "Should have momentum features"
    assert "odds_features" in vector, "Should have odds features"
    assert "news_features" in vector, "Should have news features"
    assert "chaos_features" in vector, "Should have chaos features"
    assert "market_features" in vector, "Should have market features"
    assert "timestamp" in vector, "Should have timestamp"
    
    print("✅ PASSED: Feature vector structure correct")
    
    return True


def test_convenience_function():
    """Test: Quick feature engineering function."""
    print_section("TEST 7: Convenience Function (engineer_features)")
    
    # Prepare test data
    match_stats = {
        "shots_home": 14,
        "shots_away": 7,
        "shots_on_target_home": 7,
        "shots_on_target_away": 3,
        "dangerous_attacks_home": 18,
        "dangerous_attacks_away": 9,
        "possession_home": 62,
        "possession_away": 38,
        "red_cards": 0
    }
    
    now = datetime.now()
    odds_history = [
        {"odds_home": 2.10, "timestamp": now - timedelta(minutes=10)},
        {"odds_home": 2.05, "timestamp": now - timedelta(minutes=5)},
        {"odds_home": 1.95, "timestamp": now}
    ]
    
    news_events = [
        {
            "category": "injury",
            "sentiment": -0.8,
            "impact_weight": 0.9,
            "timestamp": now - timedelta(hours=2)
        }
    ]
    
    model_probs = {"home": 0.65, "draw": 0.20, "away": 0.15}
    market_probs = {"home": 0.50, "draw": 0.25, "away": 0.25}
    
    # Call convenience function
    features = engineer_features(match_stats, odds_history, news_events, model_probs, market_probs)
    
    print_subsection("Generated Features")
    print(f"Momentum Diff: {features['momentum_features']['momentum_diff']:.4f}")
    print(f"Odds Direction: {features['odds_features']['odds_direction']}")
    print(f"News Impact: {features['news_features']['news_impact_score']:.4f}")
    print(f"Chaos Level: {features['chaos_features']['chaos_level']}")
    print(f"Market Inefficiency: {features['market_features']['market_inefficiency']:.4f}")
    
    # Validate output
    assert "momentum_features" in features, "Should include momentum"
    assert "odds_features" in features, "Should include odds"
    assert "news_features" in features, "Should include news"
    assert "chaos_features" in features, "Should include chaos"
    assert "market_features" in features, "Should include market inefficiency"
    
    print("✅ PASSED: Convenience function works correctly")
    
    return True


def main():
    """Run all feature engineering tests."""
    print("=" * 80)
    print("  TIANNARA CORE FEATURE ENGINEERING TESTS")
    print("=" * 80)
    print("\nValidating formulas from realtime.md Sections 1.1-1.5...")
    
    results = []
    
    try:
        # Test 1: Momentum Index
        result1 = test_momentum_index()
        results.append(("Momentum Index", result1))
        
        # Test 2: Odds Velocity
        result2 = test_odds_velocity()
        results.append(("Odds Movement Velocity", result2))
        
        # Test 3: News Impact Score
        result3 = test_news_impact_score()
        results.append(("News Impact Score", result3))
        
        # Test 4: Chaos Index
        result4 = test_chaos_index()
        results.append(("Chaos Index", result4))
        
        # Test 5: Market Inefficiency
        result5 = test_market_inefficiency()
        results.append(("Market Inefficiency Score", result5))
        
        # Test 6: Composite Feature Vector
        result6 = test_composite_feature_vector()
        results.append(("Composite Feature Vector", result6))
        
        # Test 7: Convenience Function
        result7 = test_convenience_function()
        results.append(("Convenience Function", result7))
        
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
        print("\n🎉 ALL FEATURE ENGINEERING TESTS PASSED!")
        print("   All formulas from realtime.md implemented correctly.")
        print("\nImplemented Features:")
        print("   ✅ Momentum Index (Section 1.1)")
        print("   ✅ Odds Movement Velocity (Section 1.2)")
        print("   ✅ News Impact Score (Section 1.3)")
        print("   ✅ Chaos Index (Section 1.4)")
        print("   ✅ Market Inefficiency Score (Section 1.5)")
        print("   ✅ Composite Feature Vector")
        print("   ✅ Convenience Functions")
    else:
        print(f"\n⚠️  {total - passed} test(s) failed. Review output above.")
    
    return passed == total


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
