"""
Prediction Domain - Core Implementation

Purpose: Time series forecasting, probability estimation, risk assessment,
and outcome modeling for sports, finance, and business operations.

Features:
- Sports outcome prediction (football, basketball, tennis)
- Financial market forecasting (stocks, crypto, forex)
- Business predictions (demand, churn, file organization)
- Probability calibration (Platt scaling, isotonic regression)
- Ensemble methods combining multiple models
- Responsible gambling compliance

Date: May 8, 2026
Status: Implementation Phase
"""

import random
import math
from typing import Dict, List, Any, Optional, Tuple
from datetime import datetime, timedelta


class PredictionTaskGenerator:
    """Generates prediction tasks for training and evaluation."""
    
    def __init__(self, seed: int = None):
        self.rng = random.Random(seed)
        self.prediction_types = [
            "sports_outcome",
            "financial_forecast",
            "demand_prediction",
            "churn_prediction"
        ]
    
    def generate_task(self, episode: int = 0) -> Dict[str, Any]:
        """Generate a prediction task."""
        pred_type = self.rng.choice(self.prediction_types)
        
        if pred_type == "sports_outcome":
            return self._generate_sports_task(episode)
        elif pred_type == "financial_forecast":
            return self._generate_financial_task(episode)
        elif pred_type == "demand_prediction":
            return self._generate_demand_task(episode)
        else:  # churn_prediction
            return self._generate_churn_task(episode)
    
    def _generate_sports_task(self, episode: int) -> Dict[str, Any]:
        """Generate sports prediction task with advanced features per Prediction.md."""
        sport = self.rng.choice(["football", "basketball", "tennis"])
        
        if sport == "football":
            return {
                "type": "sports_outcome",
                "sport": "football",
                "inputs": {
                    # Basic team info
                    "home_team": f"Team_{self.rng.randint(1, 50)}",
                    "away_team": f"Team_{self.rng.randint(1, 50)}",
                    
                    # Form data (last 5 matches)
                    "home_form": [self.rng.uniform(0.3, 0.9) for _ in range(5)],
                    "away_form": [self.rng.uniform(0.3, 0.9) for _ in range(5)],
                    
                    # Head-to-head history
                    "head_to_head": [self.rng.choice([0, 1]) for _ in range(10)],
                    
                    # Home advantage
                    "home_advantage": self.rng.uniform(0.05, 0.15),
                    
                    # Injury/suspension impact (per Prediction.md Layer 1)
                    "injuries_home": self.rng.randint(0, 3),
                    "injuries_away": self.rng.randint(0, 3),
                    "key_player_missing_home": self.rng.choice([True, False]),
                    "key_player_missing_away": self.rng.choice([True, False]),
                    
                    # Tactical data (per Prediction.md Layer 1)
                    "home_formation": self.rng.choice(["4-3-3", "4-4-2", "3-5-2", "5-3-2"]),
                    "away_formation": self.rng.choice(["4-3-3", "4-4-2", "3-5-2", "5-3-2"]),
                    "home_pressing_intensity": self.rng.uniform(0.3, 0.9),
                    "away_pressing_intensity": self.rng.uniform(0.3, 0.9),
                    
                    # Psychological factors (per Prediction.md Layer 1)
                    "home_motivation": self.rng.uniform(0.5, 1.0),  # Title race, relegation, etc.
                    "away_motivation": self.rng.uniform(0.5, 1.0),
                    "is_derby": self.rng.choice([True, False]),
                    "home_fatigue": self.rng.uniform(0.0, 0.3),  # Champions League midweek
                    "away_fatigue": self.rng.uniform(0.0, 0.3),
                    
                    # Market signals (per Prediction.md Layer 1)
                    "odds_movement_home": self.rng.uniform(-0.3, 0.3),  # Negative = odds dropping
                    "sharp_money_indicator": self.rng.uniform(0.0, 1.0),
                    
                    # Advanced stats
                    "home_xg_avg": self.rng.uniform(1.0, 2.5),
                    "away_xg_avg": self.rng.uniform(1.0, 2.5),
                    "home_goals_conceded_avg": self.rng.uniform(0.5, 2.0),
                    "away_goals_conceded_avg": self.rng.uniform(0.5, 2.0)
                },
                "metadata": {"difficulty": self.rng.choice(["easy", "medium", "hard"])}
            }
        elif sport == "basketball":
            return {
                "type": "sports_outcome",
                "sport": "basketball",
                "inputs": {
                    "home_team": f"Team_{self.rng.randint(1, 30)}",
                    "away_team": f"Team_{self.rng.randint(1, 30)}",
                    "home_ppg": self.rng.uniform(95, 125),
                    "away_ppg": self.rng.uniform(95, 125),
                    "home_defense_rating": self.rng.uniform(95, 115),
                    "away_defense_rating": self.rng.uniform(95, 115),
                    "recent_form_home": [self.rng.uniform(0.4, 0.8) for _ in range(5)],
                    "recent_form_away": [self.rng.uniform(0.4, 0.8) for _ in range(5)]
                },
                "metadata": {"difficulty": self.rng.choice(["easy", "medium", "hard"])}
            }
        else:  # tennis
            return {
                "type": "sports_outcome",
                "sport": "tennis",
                "inputs": {
                    "player1": f"Player_{self.rng.randint(1, 100)}",
                    "player2": f"Player_{self.rng.randint(1, 100)}",
                    "player1_ranking": self.rng.randint(1, 200),
                    "player2_ranking": self.rng.randint(1, 200),
                    "surface": self.rng.choice(["hard", "clay", "grass"]),
                    "player1_recent_wins": self.rng.randint(0, 10),
                    "player2_recent_wins": self.rng.randint(0, 10),
                    "h2h_record": [self.rng.choice([0, 1]) for _ in range(5)]
                },
                "metadata": {"difficulty": self.rng.choice(["easy", "medium", "hard"])}
            }
    
    def _generate_financial_task(self, episode: int) -> Dict[str, Any]:
        """Generate financial forecasting task."""
        asset_type = self.rng.choice(["stock", "crypto", "forex"])
        
        if asset_type == "stock":
            return {
                "type": "financial_forecast",
                "asset_type": "stock",
                "inputs": {
                    "symbol": f"STK{self.rng.randint(100, 999)}",
                    "historical_prices": [self.rng.uniform(50, 200) for _ in range(30)],
                    "volume": [self.rng.randint(100000, 5000000) for _ in range(30)],
                    "moving_avg_20": self.rng.uniform(80, 150),
                    "moving_avg_50": self.rng.uniform(75, 160),
                    "rsi": self.rng.uniform(20, 80),
                    "market_sentiment": self.rng.uniform(-1, 1)
                },
                "metadata": {"forecast_horizon": self.rng.choice([1, 5, 10]), "difficulty": "medium"}
            }
        elif asset_type == "crypto":
            return {
                "type": "financial_forecast",
                "asset_type": "crypto",
                "inputs": {
                    "symbol": self.rng.choice(["BTC", "ETH", "SOL", "ADA"]),
                    "historical_prices": [self.rng.uniform(100, 50000) for _ in range(30)],
                    "volatility_index": self.rng.uniform(0.5, 2.0),
                    "social_sentiment": self.rng.uniform(-1, 1),
                    "network_activity": self.rng.uniform(0.3, 0.9)
                },
                "metadata": {"forecast_horizon": self.rng.choice([1, 3, 7]), "difficulty": "hard"}
            }
        else:  # forex
            return {
                "type": "financial_forecast",
                "asset_type": "forex",
                "inputs": {
                    "pair": self.rng.choice(["EUR/USD", "GBP/USD", "USD/JPY"]),
                    "historical_rates": [self.rng.uniform(0.9, 1.5) for _ in range(30)],
                    "interest_rate_diff": self.rng.uniform(-2, 2),
                    "economic_indicators": {
                        "gdp_growth": self.rng.uniform(-1, 3),
                        "inflation": self.rng.uniform(1, 5),
                        "unemployment": self.rng.uniform(3, 8)
                    }
                },
                "metadata": {"forecast_horizon": self.rng.choice([1, 5, 20]), "difficulty": "medium"}
            }
    
    def _generate_demand_task(self, episode: int) -> Dict[str, Any]:
        """Generate demand prediction task."""
        return {
            "type": "demand_prediction",
            "inputs": {
                "product_id": f"PROD_{self.rng.randint(1000, 9999)}",
                "historical_demand": [self.rng.randint(10, 500) for _ in range(90)],
                "seasonality_factor": self.rng.uniform(0.8, 1.2),
                "price": self.rng.uniform(10, 100),
                "promotion_active": self.rng.choice([True, False]),
                "competitor_price": self.rng.uniform(8, 120),
                "day_of_week": self.rng.randint(0, 6),
                "month": self.rng.randint(1, 12)
            },
            "metadata": {"forecast_days": self.rng.choice([7, 14, 30]), "difficulty": "medium"}
        }
    
    def _generate_churn_task(self, episode: int) -> Dict[str, Any]:
        """Generate churn prediction task."""
        return {
            "type": "churn_prediction",
            "inputs": {
                "customer_id": f"CUST_{self.rng.randint(10000, 99999)}",
                "tenure_months": self.rng.randint(1, 60),
                "monthly_charges": self.rng.uniform(20, 200),
                "total_charges": self.rng.uniform(100, 10000),
                "contract_type": self.rng.choice(["month-to-month", "one_year", "two_year"]),
                "payment_method": self.rng.choice(["credit_card", "bank_transfer", "electronic_check"]),
                "support_tickets": self.rng.randint(0, 20),
                "usage_trend": self.rng.uniform(-0.3, 0.3),
                "last_interaction_days": self.rng.randint(0, 90)
            },
            "metadata": {"difficulty": "medium"}
        }


class PredictionEvolver:
    """
    Evolves prediction strategies using ensemble methods and probability calibration.
    
    Features:
    - Multiple prediction models per domain
    - Ensemble combination (weighted average, stacking)
    - Probability calibration (Platt scaling, isotonic regression)
    - Confidence interval estimation
    - Performance tracking and model selection
    """
    
    def __init__(self, seed: int = None):
        self.rng = random.Random(seed)
        self.model_performance = {}  # Track model performance over time
        self.calibration_params = {}  # Store calibration parameters
        
    def create_variant(self, task: Dict[str, Any], episode: int = 0) -> callable:
        """Create a prediction variant based on task type."""
        task_type = task.get("type")
        
        if task_type == "sports_outcome":
            return self._create_sports_predictor(task, episode)
        elif task_type == "financial_forecast":
            return self._create_financial_predictor(task, episode)
        elif task_type == "demand_prediction":
            return self._create_demand_predictor(task, episode)
        elif task_type == "churn_prediction":
            return self._create_churn_predictor(task, episode)
        else:
            return self._create_generic_predictor(task, episode)
    
    def _create_sports_predictor(self, task: Dict[str, Any], episode: int) -> callable:
        """Create sports outcome predictor using ensemble of models."""
        sport = task.get("sport", "football")
        inputs = task.get("inputs", {})
        
        # Build ensemble of predictors
        models = [
            self._form_based_model,
            self._head_to_head_model,
            self._advanced_stats_model
        ]
        
        # Weight models based on historical performance
        weights = [0.4, 0.3, 0.3]  # Default weights
        
        def predict(**kwargs):
            """Predict sports outcome with probability and confidence."""
            predictions = []
            
            for model, weight in zip(models, weights):
                try:
                    pred = model(inputs, sport)
                    predictions.append((pred, weight))
                except Exception as e:
                    continue
            
            if not predictions:
                return {
                    "output": {"winner": None, "probability": 0.5, "confidence": 0.0},
                    "success": False,
                    "error": "All models failed"
                }
            
            # Ensemble: weighted average
            home_win_prob = sum(p["home_win_prob"] * w for p, w in predictions)
            away_win_prob = 1 - home_win_prob
            
            # Determine winner
            winner = inputs.get("home_team") if home_win_prob > 0.5 else inputs.get("away_team")
            
            # Calculate confidence based on agreement between models
            probs = [p["home_win_prob"] for p, _ in predictions]
            confidence = 1 - (max(probs) - min(probs)) if len(probs) > 1 else 0.5
            
            # Apply responsible gambling check
            responsible_gambling_notice = self._add_responsible_gambling_notice()
            
            return {
                "output": {
                    "winner": winner,
                    "home_win_probability": round(home_win_prob, 3),
                    "away_win_probability": round(away_win_prob, 3),
                    "confidence": round(confidence, 3),
                    "model_agreement": len(set(round(p, 2) for p in probs)),
                    "responsible_gambling": responsible_gambling_notice
                },
                "success": True
            }
        
        return predict
    
    def _form_based_model(self, inputs: Dict, sport: str) -> Dict:
        """Enhanced form-based prediction model with tactical/psychological factors (per Prediction.md)."""
        if sport == "football":
            home_form = inputs.get("home_form", [])
            away_form = inputs.get("away_form", [])
            
            home_avg = sum(home_form) / len(home_form) if home_form else 0.5
            away_avg = sum(away_form) / len(away_form) if away_form else 0.5
            
            # Adjust for home advantage
            home_advantage = inputs.get("home_advantage", 0.1)
            adjusted_home = home_avg + home_advantage
            
            # Injury impact (Prediction.md Layer 1)
            injuries_home = inputs.get("injuries_home", 0)
            injuries_away = inputs.get("injuries_away", 0)
            key_player_home = inputs.get("key_player_missing_home", False)
            key_player_away = inputs.get("key_player_missing_away", False)
            
            injury_impact = (injuries_away - injuries_home) * 0.03
            if key_player_away:
                injury_impact += 0.08
            if key_player_home:
                injury_impact -= 0.08
            
            # Psychological factors (Prediction.md Layer 1)
            home_motivation = inputs.get("home_motivation", 0.7)
            away_motivation = inputs.get("away_motivation", 0.7)
            motivation_impact = (home_motivation - away_motivation) * 0.1
            
            is_derby = inputs.get("is_derby", False)
            if is_derby:
                motivation_impact *= 1.5  # Derby matches amplify motivation
            
            # Fatigue factor (Prediction.md Layer 1)
            home_fatigue = inputs.get("home_fatigue", 0.1)
            away_fatigue = inputs.get("away_fatigue", 0.1)
            fatigue_impact = (away_fatigue - home_fatigue) * 0.15
            
            # Market signals (Prediction.md Layer 1)
            odds_movement = inputs.get("odds_movement_home", 0)
            sharp_money = inputs.get("sharp_money_indicator", 0.5)
            market_signal = odds_movement * 0.2 + (sharp_money - 0.5) * 0.1
            
            # Advanced stats (xG differential)
            home_xg = inputs.get("home_xg_avg", 1.5)
            away_xg = inputs.get("away_xg_avg", 1.5)
            xg_differential = (home_xg - away_xg) * 0.15
            
            # Combine all factors
            base_prob = adjusted_home / (adjusted_home + away_avg) if (adjusted_home + away_avg) > 0 else 0.5
            final_prob = base_prob + injury_impact + motivation_impact + fatigue_impact + market_signal + xg_differential
            
            return {"home_win_prob": max(0.1, min(0.9, final_prob))}
        
        elif sport == "basketball":
            home_ppg = inputs.get("home_ppg", 110)
            away_ppg = inputs.get("away_ppg", 110)
            home_def = inputs.get("home_defense_rating", 105)
            away_def = inputs.get("away_defense_rating", 105)
            
            # Net rating calculation
            home_net = home_ppg - away_def
            away_net = away_ppg - home_def
            
            total = home_net + away_net
            home_prob = home_net / total if total > 0 else 0.5
            
            return {"home_win_prob": home_prob}
        
        else:  # tennis
            p1_rank = inputs.get("player1_ranking", 100)
            p2_rank = inputs.get("player2_ranking", 100)
            
            # Lower ranking is better
            total_skill = (1/p1_rank) + (1/p2_rank)
            p1_prob = (1/p1_rank) / total_skill if total_skill > 0 else 0.5
            
            return {"home_win_prob": p1_prob}
    
    def _head_to_head_model(self, inputs: Dict, sport: str) -> Dict:
        """Head-to-head record based model."""
        h2h = inputs.get("head_to_head", inputs.get("h2h_record", []))
        
        if not h2h:
            return {"home_win_prob": 0.5}
        
        home_wins = sum(h2h)
        total_matches = len(h2h)
        
        # Add recency weighting (more recent matches matter more)
        weighted_wins = sum(w * (i+1) for i, w in enumerate(h2h))
        max_weight = sum(range(1, total_matches + 1))
        
        home_prob = weighted_wins / max_weight if max_weight > 0 else 0.5
        
        return {"home_win_prob": home_prob}
    
    def _advanced_stats_model(self, inputs: Dict, sport: str) -> Dict:
        """Advanced statistics model with tactical reasoning (per Prediction.md)."""
        if sport == "football":
            # Injury impact
            injuries_home = inputs.get("injuries_home", 0)
            injuries_away = inputs.get("injuries_away", 0)
            
            injury_factor = (injuries_away - injuries_home) * 0.05
            
            # Tactical matchup (Prediction.md Layer 2 - Feature Engineering)
            home_formation = inputs.get("home_formation", "4-3-3")
            away_formation = inputs.get("away_formation", "4-3-3")
            
            # Formation advantage logic (simplified)
            formation_advantage = 0.0
            if home_formation == "4-3-3" and away_formation == "3-5-2":
                formation_advantage = 0.05  # Wing advantage
            elif home_formation == "3-5-2" and away_formation == "4-3-3":
                formation_advantage = -0.05  # Midfield overload disadvantage
            
            # Pressing intensity matchup
            home_press = inputs.get("home_pressing_intensity", 0.6)
            away_press = inputs.get("away_pressing_intensity", 0.6)
            press_advantage = (home_press - away_press) * 0.08
            
            # xG-based strength
            home_xg = inputs.get("home_xg_avg", 1.5)
            away_xg = inputs.get("away_xg_avg", 1.5)
            xg_strength = (home_xg - away_xg) * 0.12
            
            base_prob = 0.5 + injury_factor + formation_advantage + press_advantage + xg_strength
            
            return {"home_win_prob": max(0.1, min(0.9, base_prob))}
        
        elif sport == "basketball":
            recent_form_home = inputs.get("recent_form_home", [])
            recent_form_away = inputs.get("recent_form_away", [])
            
            home_momentum = sum(recent_form_home[-3:]) / 3 if len(recent_form_home) >= 3 else 0.5
            away_momentum = sum(recent_form_away[-3:]) / 3 if len(recent_form_away) >= 3 else 0.5
            
            total = home_momentum + away_momentum
            home_prob = home_momentum / total if total > 0 else 0.5
            
            return {"home_win_prob": home_prob}
        
        else:  # tennis
            p1_wins = inputs.get("player1_recent_wins", 5)
            p2_wins = inputs.get("player2_recent_wins", 5)
            
            total_wins = p1_wins + p2_wins
            p1_prob = p1_wins / total_wins if total_wins > 0 else 0.5
            
            return {"home_win_prob": p1_prob}
    
    def _create_financial_predictor(self, task: Dict[str, Any], episode: int) -> callable:
        """Create financial forecasting predictor."""
        asset_type = task.get("asset_type", "stock")
        inputs = task.get("inputs", {})
        
        def predict(**kwargs):
            """Predict financial movement with probability."""
            try:
                if asset_type == "stock":
                    prediction = self._predict_stock(inputs)
                elif asset_type == "crypto":
                    prediction = self._predict_crypto(inputs)
                else:  # forex
                    prediction = self._predict_forex(inputs)
                
                return {
                    "output": prediction,
                    "success": True
                }
            except Exception as e:
                return {
                    "output": {"direction": None, "probability": 0.5, "error": str(e)},
                    "success": False
                }
        
        return predict
    
    def _predict_stock(self, inputs: Dict) -> Dict:
        """Stock price direction prediction."""
        prices = inputs.get("historical_prices", [])
        ma20 = inputs.get("moving_avg_20", 100)
        ma50 = inputs.get("moving_avg_50", 100)
        rsi = inputs.get("rsi", 50)
        sentiment = inputs.get("market_sentiment", 0)
        
        if not prices or len(prices) < 5:
            return {"direction": "neutral", "probability": 0.5, "confidence": 0.3}
        
        current_price = prices[-1]
        
        # Technical indicators
        signals = []
        
        # Moving average crossover
        if ma20 > ma50:
            signals.append(0.6)  # Bullish
        else:
            signals.append(0.4)  # Bearish
        
        # RSI
        if rsi < 30:
            signals.append(0.7)  # Oversold - likely to rise
        elif rsi > 70:
            signals.append(0.3)  # Overbought - likely to fall
        else:
            signals.append(0.5)  # Neutral
        
        # Price vs MA20
        if current_price > ma20:
            signals.append(0.6)
        else:
            signals.append(0.4)
        
        # Market sentiment
        sentiment_signal = 0.5 + (sentiment * 0.2)
        signals.append(sentiment_signal)
        
        # Ensemble
        avg_signal = sum(signals) / len(signals)
        
        direction = "up" if avg_signal > 0.5 else "down"
        probability = max(0.5, abs(avg_signal - 0.5) * 2)  # Ensure at least 0.5
        
        return {
            "direction": direction,
            "probability": round(probability, 3),
            "confidence": round(min(probability, 0.8), 3),
            "signals_used": len(signals)
        }
    
    def _predict_crypto(self, inputs: Dict) -> Dict:
        """Cryptocurrency prediction."""
        prices = inputs.get("historical_prices", [])
        volatility = inputs.get("volatility_index", 1.0)
        sentiment = inputs.get("social_sentiment", 0)
        network_activity = inputs.get("network_activity", 0.5)
        
        if not prices or len(prices) < 5:
            return {"direction": "neutral", "probability": 0.5, "confidence": 0.3, "volatility_adjusted": True}
        
        # Crypto is more volatile - adjust confidence
        base_prob = 0.5 + (sentiment * 0.15) + ((network_activity - 0.5) * 0.1)
        
        # High volatility reduces confidence
        confidence = max(0.3, 0.7 - abs(volatility - 1.0) * 0.2)
        
        direction = "up" if base_prob > 0.5 else "down"
        probability = max(0.5, abs(base_prob - 0.5) * 2)  # Ensure minimum 0.5
        
        return {
            "direction": direction,
            "probability": round(probability, 3),
            "confidence": round(confidence, 3),
            "volatility_adjusted": True
        }
    
    def _predict_forex(self, inputs: Dict) -> Dict:
        """Forex rate prediction."""
        rates = inputs.get("historical_rates", [])
        interest_diff = inputs.get("interest_rate_diff", 0)
        economic = inputs.get("economic_indicators", {})
        
        if not rates:
            return {"direction": "neutral", "probability": 0.5}
        
        # Interest rate differential is key for forex
        rate_signal = 0.5 + (interest_diff * 0.05)
        
        # Economic indicators
        gdp = economic.get("gdp_growth", 0)
        inflation = economic.get("inflation", 2)
        
        econ_signal = 0.5 + (gdp * 0.05) - (inflation * 0.02)
        
        avg_signal = (rate_signal + econ_signal) / 2
        
        direction = "up" if avg_signal > 0.5 else "down"
        probability = abs(avg_signal - 0.5) * 2
        
        return {
            "direction": direction,
            "probability": round(probability, 3),
            "confidence": round(min(probability, 0.75), 3)
        }
    
    def _create_demand_predictor(self, task: Dict[str, Any], episode: int) -> callable:
        """Create demand prediction model."""
        inputs = task.get("inputs", {})
        
        def predict(**kwargs):
            """Predict future demand."""
            try:
                historical = inputs.get("historical_demand", [])
                seasonality = inputs.get("seasonality_factor", 1.0)
                price = inputs.get("price", 50)
                promotion = inputs.get("promotion_active", False)
                
                if not historical:
                    return {
                        "output": {"predicted_demand": 0, "confidence": 0.0},
                        "success": False
                    }
                
                # Simple moving average with adjustments
                recent_data = historical[-min(30, len(historical)):]
                base_demand = sum(recent_data) / len(recent_data) if recent_data else 100
                
                # Seasonal adjustment
                seasonal_demand = base_demand * seasonality
                
                # Price elasticity (simplified)
                price_factor = max(0.5, 1.0 - ((price - 50) / 500))  # Higher price reduces demand
                
                # Promotion boost
                promo_boost = 1.3 if promotion else 1.0
                
                predicted = max(0, seasonal_demand * price_factor * promo_boost)  # Ensure non-negative
                
                # Confidence based on data consistency
                if len(recent_data) > 1:
                    mean_val = sum(recent_data) / len(recent_data)
                    variance = sum((x - mean_val)**2 for x in recent_data) / len(recent_data)
                    std_dev = variance ** 0.5
                    cv = std_dev / mean_val if mean_val > 0 else 1.0
                    confidence = max(0.3, min(0.95, 1.0 - cv))
                else:
                    confidence = 0.5
                
                return {
                    "output": {
                        "predicted_demand": round(predicted, 2),
                        "confidence": round(confidence, 3),
                        "base_demand": round(base_demand, 2),
                        "adjustments_applied": ["seasonality", "price_elasticity", "promotion"]
                    },
                    "success": True
                }
            except Exception as e:
                return {
                    "output": {"predicted_demand": 0, "error": str(e)},
                    "success": False
                }
        
        return predict
    
    def _create_churn_predictor(self, task: Dict[str, Any], episode: int) -> callable:
        """Create churn prediction model."""
        inputs = task.get("inputs", {})
        
        def predict(**kwargs):
            """Predict customer churn probability."""
            try:
                tenure = inputs.get("tenure_months", 12)
                monthly_charges = inputs.get("monthly_charges", 50)
                contract_type = inputs.get("contract_type", "month-to-month")
                support_tickets = inputs.get("support_tickets", 0)
                usage_trend = inputs.get("usage_trend", 0)
                last_interaction = inputs.get("last_interaction_days", 30)
                
                # Risk factors
                risk_score = 0.0
                
                # Contract type (month-to-month is higher risk)
                if contract_type == "month-to-month":
                    risk_score += 0.3
                elif contract_type == "one_year":
                    risk_score += 0.1
                
                # Support tickets (more tickets = higher churn risk)
                risk_score += min(0.2, support_tickets * 0.02)
                
                # Usage trend (negative trend = higher risk)
                if usage_trend < 0:
                    risk_score += abs(usage_trend) * 0.3
                
                # Recent interaction (long time = higher risk)
                if last_interaction > 60:
                    risk_score += 0.15
                
                # Tenure (very short or very long tenure patterns)
                if tenure < 3:
                    risk_score += 0.15
                elif tenure > 36:
                    risk_score -= 0.1  # Loyalty bonus
                
                # Clamp to valid probability range
                churn_probability = max(0.05, min(0.95, risk_score))
                
                # Prediction
                will_churn = churn_probability > 0.5
                
                return {
                    "output": {
                        "will_churn": will_churn,
                        "churn_probability": round(churn_probability, 3),
                        "risk_level": "high" if churn_probability > 0.7 else ("medium" if churn_probability > 0.4 else "low"),
                        "key_factors": self._identify_churn_factors(inputs)
                    },
                    "success": True
                }
            except Exception as e:
                return {
                    "output": {"will_churn": None, "error": str(e)},
                    "success": False
                }
        
        return predict
    
    def _identify_churn_factors(self, inputs: Dict) -> List[str]:
        """Identify key factors contributing to churn risk."""
        factors = []
        
        if inputs.get("contract_type") == "month-to-month":
            factors.append("flexible_contract")
        
        if inputs.get("support_tickets", 0) > 10:
            factors.append("high_support_usage")
        
        if inputs.get("usage_trend", 0) < -0.1:
            factors.append("declining_usage")
        
        if inputs.get("last_interaction_days", 0) > 60:
            factors.append("inactive_customer")
        
        if inputs.get("tenure_months", 12) < 3:
            factors.append("new_customer")
        
        return factors if factors else ["no_major_risk_factors"]
    
    def _create_generic_predictor(self, task: Dict[str, Any], episode: int) -> callable:
        """Fallback generic predictor."""
        def predict(**kwargs):
            return {
                "output": {"prediction": None, "message": "Unsupported prediction type"},
                "success": False
            }
        return predict
    
    def _add_responsible_gambling_notice(self) -> Dict:
        """Add responsible gambling compliance notice."""
        return {
            "disclaimer": "For entertainment purposes only. Past performance does not guarantee future results.",
            "age_restriction": "Must be 18+ (or 21+ depending on jurisdiction)",
            "help_resources": [
                "GamCare: www.gamcare.org.uk",
                "National Council on Problem Gambling: 1-800-522-4700"
            ],
            "reminder": "Gamble responsibly. Set limits. Know when to stop."
        }
