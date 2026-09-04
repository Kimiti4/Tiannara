"""
Feature Engineering Integration Example

Demonstrates how to integrate the new feature engineering formulas
with the existing Tiannara Core PredictionEngine.
"""

import sys
from pathlib import Path
from datetime import datetime, timedelta

sys.path.insert(0, str(Path(__file__).parent))

from tiannara_core.prediction.feature_engineering import FeatureEngineer, engineer_features


def example_basic_usage():
    """Example 1: Basic feature calculation."""
    print("=" * 80)
    print("EXAMPLE 1: Basic Feature Calculation")
    print("=" * 80)
    
    fe = FeatureEngineer()
    
    # Calculate momentum for a live match
    print("\n📊 Match: Arsenal vs Chelsea (67th minute)")
    print("-" * 80)
    
    momentum = fe.calculate_momentum_index(
        shots_home=14,
        shots_away=8,
        shots_on_target_home=7,
        shots_on_target_away=3,
        dangerous_attacks_home=18,
        dangerous_attacks_away=10,
        possession_home=62,
        possession_away=38
    )
    
    print(f"Momentum Home (Arsenal): {momentum['momentum_home']:.2f}")
    print(f"Momentum Away (Chelsea): {momentum['momentum_away']:.2f}")
    print(f"Difference: {momentum['momentum_diff']:+.2f}")
    print(f"Status: {momentum['interpretation'].replace('_', ' ').title()}")
    
    return momentum


def example_odds_intelligence():
    """Example 2: Odds movement analysis."""
    print("\n" + "=" * 80)
    print("EXAMPLE 2: Odds Movement Intelligence")
    print("=" * 80)
    
    fe = FeatureEngineer()
    
    print("\n💰 Analyzing market movements...")
    print("-" * 80)
    
    # Sharp money coming in on home team
    odds_data = fe.calculate_odds_velocity(
        current_odds=1.85,
        previous_odds=2.10,
        time_delta_seconds=300,  # 5 minutes ago
        use_exponential_smoothing=True,
        alpha=0.3,
        previous_velocity=-0.0008
    )
    
    print(f"Current Odds: 1.85 (was 2.10)")
    print(f"Velocity: {odds_data['velocity_smoothed']:.6f}/sec")
    print(f"Direction: {odds_data['direction'].upper()}")
    print(f"Change: {odds_data['odds_change']:+.2f}")
    print(f"\nInterpretation: Sharp money betting on HOME TEAM")
    
    # Calculate volatility
    odds_history = [2.10, 2.05, 2.00, 1.95, 1.90, 1.85]
    volatility = fe.calculate_odds_volatility(odds_history)
    
    print(f"\nMarket Volatility: {volatility:.2f} ({'HIGH' if volatility > 0.1 else 'LOW'})")
    
    return odds_data


def example_news_impact():
    """Example 3: News impact scoring."""
    print("\n" + "=" * 80)
    print("EXAMPLE 3: News Impact Analysis")
    print("=" * 80)
    
    fe = FeatureEngineer()
    now = datetime.now()
    
    print("\n📰 Recent news events:")
    print("-" * 80)
    
    news_events = [
        {
            "headline": "Saka injury concern before match",
            "sentiment": -0.8,
            "impact_weight": 0.9,
            "timestamp": now - timedelta(hours=2),
            "category": "injury"
        },
        {
            "headline": "Arteta confirms strong lineup",
            "sentiment": 0.6,
            "impact_weight": 0.7,
            "timestamp": now - timedelta(hours=1),
            "category": "lineup"
        },
        {
            "headline": "Heavy rain expected during match",
            "sentiment": -0.3,
            "impact_weight": 0.4,
            "timestamp": now - timedelta(minutes=30),
            "category": "weather"
        }
    ]
    
    for i, news in enumerate(news_events, 1):
        age_hours = (now - news["timestamp"]).total_seconds() / 3600
        print(f"{i}. {news['headline']}")
        print(f"   Sentiment: {news['sentiment']:+.1f}, Age: {age_hours:.1f}h")
    
    result = fe.calculate_news_impact_score(news_events, reference_time=now)
    
    print(f"\n{'='*60}")
    print(f"Overall News Impact Score: {result['nis_total']:+.4f}")
    print(f"Dominant Sentiment: {result['dominant_sentiment'].upper()}")
    print(f"Events Considered: {result['event_count']}")
    print(f"\nInterpretation: {'NEGATIVE PRESSURE' if result['nis_total'] < -0.2 else 'NEUTRAL/POSITIVE'}")
    
    return result


def example_chaos_detection():
    """Example 4: Chaos Index for jackpot detection."""
    print("\n" + "=" * 80)
    print("EXAMPLE 4: Chaos Index (Jackpot Detection)")
    print("=" * 80)
    
    fe = FeatureEngineer()
    
    print("\n🎲 Assessing match unpredictability...")
    print("-" * 80)
    
    # High chaos scenario
    chaos = fe.calculate_chaos_index(
        odds_volatility=0.75,      # High odds swings
        momentum_volatility=0.60,  # Momentum shifting
        news_conflict_score=0.80,  # Conflicting reports
        red_cards_factor=0.5,      # Red card issued
        injuries_count=2           # Key injuries
    )
    
    print(f"Chaos Index: {chaos['chaos_index']:.2f}")
    print(f"Level: {chaos['level'].replace('_', ' ').upper()}")
    print(f"Jackpot Potential: {'✅ YES' if chaos['jackpot_potential'] else '❌ NO'}")
    
    print(f"\nComponent Breakdown:")
    for component, value in chaos['components'].items():
        name = component.replace('_contribution', '').replace('_', ' ').title()
        print(f"  • {name}: {value:.2f}")
    
    print(f"\nRecommendation: {'AVOID or HEDGE' if chaos['chaos_index'] > 0.6 else 'NORMAL BETTING'}")
    
    return chaos


def example_value_detection():
    """Example 5: Market inefficiency / value bet detection."""
    print("\n" + "=" * 80)
    print("EXAMPLE 5: Market Inefficiency (Value Bet Detection)")
    print("=" * 80)
    
    fe = FeatureEngineer()
    
    print("\n💡 Comparing model vs market probabilities...")
    print("-" * 80)
    
    # Model sees value that market misses
    mis = fe.calculate_market_inefficiency(
        model_probability=0.65,  # Model thinks 65% chance
        market_probability=0.50  # Market prices at 50%
    )
    
    print(f"Model Probability: {mis['model_prob']:.0%}")
    print(f"Market Probability: {mis['market_prob']:.0%}")
    print(f"Difference: {mis['mis_score']:.2f}")
    print(f"\nSignal: {mis['value_signal'].replace('_', ' ').upper()}")
    print(f"Value Opportunity: {'✅ YES' if mis['value_opportunity'] else '❌ NO'}")
    
    if mis['value_opportunity']:
        print(f"\nAction: BET ON THIS OUTCOME (model sees edge)")
    else:
        print(f"\nAction: SKIP (no significant edge)")
    
    return mis


def example_complete_workflow():
    """Example 6: Complete feature engineering workflow."""
    print("\n" + "=" * 80)
    print("EXAMPLE 6: Complete Workflow (All Features Combined)")
    print("=" * 80)
    
    print("\n🔧 Building unified feature vector...")
    print("-" * 80)
    
    # Simulate real-time data
    match_stats = {
        "shots_home": 12,
        "shots_away": 9,
        "shots_on_target_home": 6,
        "shots_on_target_away": 4,
        "dangerous_attacks_home": 15,
        "dangerous_attacks_away": 12,
        "possession_home": 55,
        "possession_away": 45,
        "red_cards": 0
    }
    
    now = datetime.now()
    odds_history = [
        {"odds_home": 2.20, "timestamp": now - timedelta(minutes=20)},
        {"odds_home": 2.15, "timestamp": now - timedelta(minutes=15)},
        {"odds_home": 2.10, "timestamp": now - timedelta(minutes=10)},
        {"odds_home": 2.05, "timestamp": now - timedelta(minutes=5)},
        {"odds_home": 2.00, "timestamp": now}
    ]
    
    news_events = [
        {
            "category": "injury",
            "sentiment": -0.7,
            "impact_weight": 0.85,
            "timestamp": now - timedelta(hours=3)
        }
    ]
    
    model_probs = {"home": 0.55, "draw": 0.25, "away": 0.20}
    market_probs = {"home": 0.48, "draw": 0.27, "away": 0.25}
    
    # Generate complete feature vector
    features = engineer_features(
        match_stats=match_stats,
        odds_history=odds_history,
        news_events=news_events,
        model_probs=model_probs,
        market_probs=market_probs
    )
    
    print("\n✅ Feature Vector Generated:")
    print(f"\nMomentum:")
    print(f"  Diff: {features['momentum_features']['momentum_diff']:+.2f} ({features['momentum_features']['momentum_interpretation'].replace('_', ' ')})")
    
    print(f"\nOdds Movement:")
    print(f"  Direction: {features['odds_features']['odds_direction']}")
    print(f"  Velocity: {features['odds_features']['odds_velocity']:.6f}")
    
    print(f"\nNews Impact:")
    print(f"  Score: {features['news_features']['news_impact_score']:+.2f}")
    print(f"  Sentiment: {features['news_features']['news_sentiment']}")
    
    print(f"\nChaos Index:")
    print(f"  Level: {features['chaos_features']['chaos_level'].replace('_', ' ').title()}")
    print(f"  Jackpot Potential: {'Yes' if features['chaos_features']['jackpot_potential'] else 'No'}")
    
    print(f"\nMarket Efficiency:")
    print(f"  Inefficiency: {features['market_features']['market_inefficiency']:.2f}")
    print(f"  Value Signal: {features['market_features']['value_signal'].replace('_', ' ').title()}")
    
    print(f"\nTimestamp: {features['timestamp']}")
    
    return features


def example_integration_with_prediction():
    """Example 7: How to use features in prediction."""
    print("\n" + "=" * 80)
    print("EXAMPLE 7: Integration with Prediction Engine")
    print("=" * 80)
    
    print("\n🤖 Using features for prediction...")
    print("-" * 80)
    
    # Generate features
    features = example_complete_workflow()
    
    print("\n📈 Feature-based prediction logic:")
    print("-" * 80)
    
    # Simple rule-based prediction using engineered features
    momentum_diff = features['momentum_features']['momentum_diff']
    chaos = features['chaos_features']['chaos_index']
    value = features['market_features']['market_inefficiency']
    
    print(f"\nDecision Factors:")
    print(f"  1. Momentum favors: {'HOME' if momentum_diff > 0 else 'AWAY'} (strength: {abs(momentum_diff):.2f})")
    print(f"  2. Match stability: {'STABLE' if chaos < 0.3 else 'CHAOTIC' if chaos > 0.6 else 'MODERATE'}")
    print(f"  3. Market efficiency: {'INEFFICIENT (value!)' if value > 0.1 else 'EFFICIENT'}")
    
    # Make prediction
    if momentum_diff > 0.2 and chaos < 0.5:
        prediction = "HOME WIN"
        confidence = "HIGH" if momentum_diff > 0.4 else "MEDIUM"
    elif momentum_diff < -0.2 and chaos < 0.5:
        prediction = "AWAY WIN"
        confidence = "HIGH" if momentum_diff < -0.4 else "MEDIUM"
    else:
        prediction = "DRAW or UNCERTAIN"
        confidence = "LOW"
    
    print(f"\n🎯 PREDICTION: {prediction}")
    print(f"   Confidence: {confidence}")
    print(f"   Chaos Warning: {'⚠️ HIGH RISK' if chaos > 0.6 else '✅ NORMAL RISK'}")
    
    return prediction


def main():
    """Run all examples."""
    print("\n" + "=" * 80)
    print("  TIANNARA CORE FEATURE ENGINEERING - INTEGRATION EXAMPLES")
    print("=" * 80)
    print("\nDemonstrating practical usage of realtime.md formulas\n")
    
    try:
        # Run examples
        example_basic_usage()
        example_odds_intelligence()
        example_news_impact()
        example_chaos_detection()
        example_value_detection()
        example_complete_workflow()
        example_integration_with_prediction()
        
        print("\n" + "=" * 80)
        print("  ALL EXAMPLES COMPLETED SUCCESSFULLY ✅")
        print("=" * 80)
        print("\nNext Steps:")
        print("  1. Integrate FeatureEngineer into PredictionEngine")
        print("  2. Add feature caching with Redis for real-time updates")
        print("  3. Create API endpoints for each feature type")
        print("  4. Build WebSocket streaming for live feature updates")
        print("  5. Implement feedback loop to tune formula weights")
        print()
        
    except Exception as e:
        print(f"\n❌ Error in examples: {e}")
        import traceback
        traceback.print_exc()
        return False
    
    return True


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
