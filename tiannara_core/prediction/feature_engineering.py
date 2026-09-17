"""
Tiannara Core Feature Engineering Module

Implements real-time feature engineering formulas from realtime.md specification.
Calculates momentum indices, odds velocity, news impact scores, chaos index,
and market inefficiency scores for sports prediction intelligence.

Reference: realtime.md Sections 1.1-1.5
"""

import math
import numpy as np
from typing import Dict, List, Optional, Tuple
from datetime import datetime, timedelta


class FeatureEngineer:
    """
    Real-time feature engineering for Tiannara Core prediction system.
    
    Computes:
    - Momentum Index (match control strength)
    - Odds Movement Velocity (market intelligence)
    - News Impact Score (NIS)
    - Chaos Index (unpredictability measure)
    - Market Inefficiency Score (value detection)
    """
    
    def __init__(self):
        self.epsilon = 1e-8  # Small constant to prevent division by zero
        self.lambda_decay = 0.1  # Decay rate for news freshness
    
    # =========================================================================
    # 1.1 MOMENTUM INDEX (Match Control Strength)
    # =========================================================================
    
    def calculate_momentum_index(
        self,
        shots_home: int,
        shots_away: int,
        shots_on_target_home: int,
        shots_on_target_away: int,
        dangerous_attacks_home: int,
        dangerous_attacks_away: int,
        possession_home: float,
        possession_away: float
    ) -> Dict[str, float]:
        """
        Calculate momentum index measuring who is dominating RIGHT NOW.
        
        Formula:
        M_h = 0.4*(SoT_h/(SoT_h+SoT_a)) + 0.3*(DA_h/(DA_h+DA_a)) + 
              0.2*(S_h/(S_h+S_a)) + 0.1*(P_h/100)
        
        Args:
            shots_home: Total shots by home team
            shots_away: Total shots by away team
            shots_on_target_home: Shots on target by home
            shots_on_target_away: Shots on target by away
            dangerous_attacks_home: Dangerous attacks by home
            dangerous_attacks_away: Dangerous attacks by away
            possession_home: Possession % for home (0-100)
            possession_away: Possession % for away (0-100)
        
        Returns:
            Dictionary with momentum metrics:
            - momentum_home: Home team momentum (0-1)
            - momentum_away: Away team momentum (0-1)
            - momentum_diff: Difference (home - away), range -1 to +1
            - interpretation: Text description of momentum state
        """
        # Normalize components with epsilon to prevent division by zero
        sot_ratio_home = shots_on_target_home / (shots_on_target_home + shots_on_target_away + self.epsilon)
        sot_ratio_away = shots_on_target_away / (shots_on_target_home + shots_on_target_away + self.epsilon)
        
        da_ratio_home = dangerous_attacks_home / (dangerous_attacks_home + dangerous_attacks_away + self.epsilon)
        da_ratio_away = dangerous_attacks_away / (dangerous_attacks_home + dangerous_attacks_away + self.epsilon)
        
        shot_ratio_home = shots_home / (shots_home + shots_away + self.epsilon)
        shot_ratio_away = shots_away / (shots_home + shots_away + self.epsilon)
        
        # Weighted momentum calculation
        momentum_home = (
            0.4 * sot_ratio_home +
            0.3 * da_ratio_home +
            0.2 * shot_ratio_home +
            0.1 * (possession_home / 100.0)
        )
        
        momentum_away = (
            0.4 * sot_ratio_away +
            0.3 * da_ratio_away +
            0.2 * shot_ratio_away +
            0.1 * (possession_away / 100.0)
        )
        
        # Momentum difference
        momentum_diff = momentum_home - momentum_away
        
        # Interpretation
        if momentum_diff > 0.3:
            interpretation = "home_dominance"
        elif momentum_diff < -0.3:
            interpretation = "away_dominance"
        elif abs(momentum_diff) < 0.1:
            interpretation = "balanced_chaos_zone"
        else:
            interpretation = "slight_edge"
        
        return {
            "momentum_home": round(momentum_home, 4),
            "momentum_away": round(momentum_away, 4),
            "momentum_diff": round(momentum_diff, 4),
            "interpretation": interpretation
        }
    
    # =========================================================================
    # 1.2 ODDS MOVEMENT VELOCITY (Market Intelligence Signal)
    # =========================================================================
    
    def calculate_odds_velocity(
        self,
        current_odds: float,
        previous_odds: float,
        time_delta_seconds: float,
        use_exponential_smoothing: bool = True,
        alpha: float = 0.3,
        previous_velocity: Optional[float] = None
    ) -> Dict[str, float]:
        """
        Calculate odds movement velocity (sharp money detector).
        
        Simple Formula:
        V = (O_t - O_{t-1}) / Δt
        
        Exponential Smoothing (better):
        V_ema = α*V_t + (1-α)*V_{t-1}
        
        Args:
            current_odds: Current odds value
            previous_odds: Previous odds value
            time_delta_seconds: Time between measurements in seconds
            use_exponential_smoothing: Whether to apply EMA smoothing
            alpha: Smoothing factor (0-1), default 0.3
            previous_velocity: Previous velocity for EMA calculation
        
        Returns:
            Dictionary with velocity metrics:
            - velocity_raw: Raw velocity (odds change per second)
            - velocity_smoothed: Exponentially smoothed velocity (if enabled)
            - direction: "dropping" (favorite), "rising" (losing confidence), "stable"
            - magnitude: Absolute velocity magnitude
        """
        # Calculate raw velocity
        odds_change = current_odds - previous_odds
        velocity_raw = odds_change / max(time_delta_seconds, self.epsilon)
        
        # Apply exponential smoothing if requested
        velocity_smoothed = velocity_raw
        if use_exponential_smoothing and previous_velocity is not None:
            velocity_smoothed = alpha * velocity_raw + (1 - alpha) * previous_velocity
        
        # Determine direction
        if velocity_raw < -0.0001:
            direction = "dropping"  # Team becoming favorite
        elif velocity_raw > 0.0001:
            direction = "rising"  # Losing confidence / hidden risk
        else:
            direction = "stable"
        
        return {
            "velocity_raw": round(velocity_raw, 6),
            "velocity_smoothed": round(velocity_smoothed, 6),
            "direction": direction,
            "magnitude": round(abs(velocity_raw), 6),
            "odds_change": round(odds_change, 4)
        }
    
    def calculate_odds_volatility(
        self,
        odds_history: List[float],
        window_size: int = 10
    ) -> float:
        """
        Calculate odds volatility over a time window.
        
        Uses rolling standard deviation to measure market instability.
        
        Args:
            odds_history: List of historical odds values
            window_size: Number of recent observations to consider
        
        Returns:
            Volatility score (0-1, higher = more volatile)
        """
        if len(odds_history) < 2:
            return 0.0
        
        # Use recent window
        recent_odds = odds_history[-window_size:] if len(odds_history) >= window_size else odds_history
        
        # Calculate coefficient of variation (normalized std dev)
        mean_odds = np.mean(recent_odds)
        std_odds = np.std(recent_odds)
        
        # Normalize to 0-1 range
        volatility = std_odds / (mean_odds + self.epsilon)
        
        # Cap at 1.0
        return min(round(volatility, 4), 1.0)
    
    # =========================================================================
    # 1.3 NEWS IMPACT SCORE (NIS)
    # =========================================================================
    
    def calculate_news_impact_score(
        self,
        news_events: List[Dict],
        reference_time: Optional[datetime] = None
    ) -> Dict[str, float]:
        """
        Calculate News Impact Score using sentiment, weight, and freshness decay.
        
        Formula:
        NIS = Σ(s_i * w_i * e^(-λ*t_i))
        
        Where:
        - s_i = sentiment score (-1 to +1)
        - w_i = impact weight (0 to 1)
        - t_i = time since event (hours)
        - λ = decay rate (default 0.1)
        
        Args:
            news_events: List of news event dictionaries with keys:
                - sentiment: float (-1 to +1)
                - impact_weight: float (0 to 1)
                - timestamp: datetime object
            reference_time: Reference time for decay calculation (default: now)
        
        Returns:
            Dictionary with news impact metrics:
            - nis_total: Total news impact score (-1 to +1)
            - nis_positive: Positive impact component
            - nis_negative: Negative impact component
            - event_count: Number of events considered
            - dominant_sentiment: "positive", "negative", or "neutral"
        """
        if reference_time is None:
            reference_time = datetime.now()
        
        if not news_events:
            return {
                "nis_total": 0.0,
                "nis_positive": 0.0,
                "nis_negative": 0.0,
                "event_count": 0,
                "dominant_sentiment": "neutral"
            }
        
        total_impact = 0.0
        positive_impact = 0.0
        negative_impact = 0.0
        
        for event in news_events:
            sentiment = event.get("sentiment", 0.0)
            weight = event.get("impact_weight", 0.5)
            timestamp = event.get("timestamp")
            
            # Calculate time decay
            if timestamp:
                time_diff_hours = (reference_time - timestamp).total_seconds() / 3600.0
                decay = math.exp(-self.lambda_decay * time_diff_hours)
            else:
                decay = 1.0  # No timestamp = assume fresh
            
            # Calculate weighted impact
            weighted_impact = sentiment * weight * decay
            total_impact += weighted_impact
            
            if weighted_impact > 0:
                positive_impact += weighted_impact
            else:
                negative_impact += weighted_impact
        
        # Clamp to [-1, 1]
        total_impact = max(-1.0, min(1.0, total_impact))
        
        # Determine dominant sentiment
        if total_impact > 0.2:
            dominant = "positive"
        elif total_impact < -0.2:
            dominant = "negative"
        else:
            dominant = "neutral"
        
        return {
            "nis_total": round(total_impact, 4),
            "nis_positive": round(positive_impact, 4),
            "nis_negative": round(negative_impact, 4),
            "event_count": len(news_events),
            "dominant_sentiment": dominant
        }
    
    # =========================================================================
    # 1.4 CHAOS INDEX (Unpredictability Measure)
    # =========================================================================
    
    def calculate_chaos_index(
        self,
        odds_volatility: float,
        momentum_volatility: float,
        news_conflict_score: float,
        red_cards_factor: float = 0.0,
        injuries_count: int = 0,
        weights: Optional[Dict[str, float]] = None
    ) -> Dict[str, float]:
        """
        Calculate Chaos Index measuring match unpredictability.
        
        Formula:
        CI = 0.35*V_o + 0.25*V_m + 0.25*C_n + 0.15*R
        
        Where:
        - V_o = odds volatility
        - V_m = momentum volatility
        - C_n = news conflict score
        - R = red cards/injuries factor
        
        Args:
            odds_volatility: Odds movement volatility (0-1)
            momentum_volatility: Momentum swing volatility (0-1)
            news_conflict_score: Conflicting news signals (0-1)
            red_cards_factor: Red cards impact (0-1, typically 0 unless red card)
            injuries_count: Number of key injuries
            weights: Custom weights dict (optional)
        
        Returns:
            Dictionary with chaos metrics:
            - chaos_index: Overall chaos score (0-1)
            - level: "stable", "moderate_uncertainty", or "chaos_match"
            - components: Breakdown of contributing factors
            - jackpot_potential: Boolean indicating high-variance match
        """
        # Default weights
        if weights is None:
            weights = {
                "odds_volatility": 0.35,
                "momentum_volatility": 0.25,
                "news_conflict": 0.25,
                "disruption": 0.15
            }
        
        # Calculate disruption factor from red cards and injuries
        disruption_factor = min(red_cards_factor + (injuries_count * 0.1), 1.0)
        
        # Weighted chaos calculation
        chaos_index = (
            weights["odds_volatility"] * odds_volatility +
            weights["momentum_volatility"] * momentum_volatility +
            weights["news_conflict"] * news_conflict_score +
            weights["disruption"] * disruption_factor
        )
        
        # Clamp to [0, 1]
        chaos_index = max(0.0, min(1.0, chaos_index))
        
        # Determine chaos level
        if chaos_index < 0.3:
            level = "stable"
        elif chaos_index < 0.6:
            level = "moderate_uncertainty"
        else:
            level = "chaos_match"
        
        # Jackpot potential (high chaos = good for jackpot systems)
        jackpot_potential = chaos_index > 0.6
        
        return {
            "chaos_index": round(chaos_index, 4),
            "level": level,
            "components": {
                "odds_volatility_contribution": round(weights["odds_volatility"] * odds_volatility, 4),
                "momentum_volatility_contribution": round(weights["momentum_volatility"] * momentum_volatility, 4),
                "news_conflict_contribution": round(weights["news_conflict"] * news_conflict_score, 4),
                "disruption_contribution": round(weights["disruption"] * disruption_factor, 4)
            },
            "jackpot_potential": jackpot_potential
        }
    
    # =========================================================================
    # 1.5 MARKET INEFFICIENCY SCORE (MIS)
    # =========================================================================
    
    def calculate_market_inefficiency(
        self,
        model_probability: float,
        market_probability: float
    ) -> Dict[str, float]:
        """
        Calculate Market Inefficiency Score detecting value bets.
        
        Formula:
        MIS = |P_model - P_market|
        
        High MIS indicates bookmaker mispricing (value opportunity).
        
        Args:
            model_probability: Model's predicted probability (0-1)
            market_probability: Market/bookmaker implied probability (0-1)
        
        Returns:
            Dictionary with inefficiency metrics:
            - mis_score: Market inefficiency score (0-1)
            - direction: "model_favors" or "market_favors"
            - value_opportunity: Boolean indicating potential value bet
            - confidence_gap: Absolute difference
        """
        # Calculate absolute difference
        mis_score = abs(model_probability - market_probability)
        
        # Determine direction
        if model_probability > market_probability:
            direction = "model_favors"
            value_signal = "undervalued_by_market"
        elif model_probability < market_probability:
            direction = "market_favors"
            value_signal = "overvalued_by_market"
        else:
            direction = "aligned"
            value_signal = "no_value"
        
        # Value opportunity threshold (typically > 0.1 is significant)
        value_opportunity = mis_score > 0.1
        
        return {
            "mis_score": round(mis_score, 4),
            "direction": direction,
            "value_signal": value_signal,
            "value_opportunity": value_opportunity,
            "confidence_gap": round(mis_score, 4),
            "model_prob": round(model_probability, 4),
            "market_prob": round(market_probability, 4)
        }
    
    # =========================================================================
    # COMPOSITE FEATURE VECTOR
    # =========================================================================
    
    def create_feature_vector(
        self,
        momentum_data: Dict,
        odds_data: Dict,
        news_data: Dict,
        chaos_data: Dict,
        mis_data: Dict
    ) -> Dict:
        """
        Create unified feature vector combining all engineered features.
        
        This is the input to the prediction model.
        
        Args:
            momentum_data: Output from calculate_momentum_index()
            odds_data: Output from calculate_odds_velocity()
            news_data: Output from calculate_news_impact_score()
            chaos_data: Output from calculate_chaos_index()
            mis_data: Output from calculate_market_inefficiency()
        
        Returns:
            Unified feature vector dictionary ready for model input
        """
        return {
            "momentum_features": {
                "momentum_diff": momentum_data.get("momentum_diff", 0.0),
                "momentum_home": momentum_data.get("momentum_home", 0.5),
                "momentum_away": momentum_data.get("momentum_away", 0.5),
                "momentum_interpretation": momentum_data.get("interpretation", "balanced")
            },
            "odds_features": {
                "odds_velocity": odds_data.get("velocity_smoothed", 0.0),
                "odds_direction": odds_data.get("direction", "stable"),
                "odds_volatility": odds_data.get("volatility", 0.0),
                "odds_change": odds_data.get("odds_change", 0.0)
            },
            "news_features": {
                "news_impact_score": news_data.get("nis_total", 0.0),
                "news_sentiment": news_data.get("dominant_sentiment", "neutral"),
                "news_event_count": news_data.get("event_count", 0)
            },
            "chaos_features": {
                "chaos_index": chaos_data.get("chaos_index", 0.0),
                "chaos_level": chaos_data.get("level", "stable"),
                "jackpot_potential": chaos_data.get("jackpot_potential", False)
            },
            "market_features": {
                "market_inefficiency": mis_data.get("mis_score", 0.0),
                "value_signal": mis_data.get("value_signal", "no_value"),
                "value_opportunity": mis_data.get("value_opportunity", False)
            },
            "timestamp": datetime.now().isoformat()
        }


# Convenience function for quick usage
def engineer_features(
    match_stats: Dict,
    odds_history: List[Dict],
    news_events: List[Dict],
    model_probs: Dict,
    market_probs: Dict
) -> Dict:
    """
    Quick feature engineering from raw data.
    
    Args:
        match_stats: Live match statistics
        odds_history: Historical odds data
        news_events: Recent news events
        model_probs: Model predicted probabilities
        market_probs: Market implied probabilities
    
    Returns:
        Complete feature vector
    """
    fe = FeatureEngineer()
    
    # Calculate momentum
    momentum = fe.calculate_momentum_index(
        shots_home=match_stats.get("shots_home", 0),
        shots_away=match_stats.get("shots_away", 0),
        shots_on_target_home=match_stats.get("shots_on_target_home", 0),
        shots_on_target_away=match_stats.get("shots_on_target_away", 0),
        dangerous_attacks_home=match_stats.get("dangerous_attacks_home", 0),
        dangerous_attacks_away=match_stats.get("dangerous_attacks_away", 0),
        possession_home=match_stats.get("possession_home", 50),
        possession_away=match_stats.get("possession_away", 50)
    )
    
    # Calculate odds velocity (use most recent two odds)
    if len(odds_history) >= 2:
        latest = odds_history[-1]
        previous = odds_history[-2]
        odds_vel = fe.calculate_odds_velocity(
            current_odds=latest.get("odds_home", 2.0),
            previous_odds=previous.get("odds_home", 2.0),
            time_delta_seconds=(latest.get("timestamp", datetime.now()) - 
                               previous.get("timestamp", datetime.now())).total_seconds()
        )
        odds_vol = fe.calculate_odds_volatility(
            odds_history=[o.get("odds_home", 2.0) for o in odds_history[-10:]]
        )
        odds_vel["volatility"] = odds_vol
    else:
        odds_vel = {"velocity_smoothed": 0.0, "direction": "stable", "volatility": 0.0, "odds_change": 0.0}
    
    # Calculate news impact
    news_impact = fe.calculate_news_impact_score(news_events)
    
    # Calculate chaos index
    chaos = fe.calculate_chaos_index(
        odds_volatility=odds_vel.get("volatility", 0.0),
        momentum_volatility=abs(momentum.get("momentum_diff", 0.0)),
        news_conflict_score=abs(news_impact.get("nis_total", 0.0)),
        red_cards_factor=match_stats.get("red_cards", 0) * 0.5,
        injuries_count=len([e for e in news_events if e.get("category") == "injury"])
    )
    
    # Calculate market inefficiency (for home win as example)
    mis = fe.calculate_market_inefficiency(
        model_probability=model_probs.get("home", 0.33),
        market_probability=market_probs.get("home", 0.33)
    )
    
    # Create unified feature vector
    return fe.create_feature_vector(momentum, odds_vel, news_impact, chaos, mis)
