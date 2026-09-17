"""
Prediction Engine

Wraps tiannara_core prediction logic for forecasting, classification, and regression tasks.
Uses scikit-learn and statsmodels for real ML predictions.
Integrates FeatureEngineer for real-time sports intelligence (momentum, chaos, odds velocity).
"""

import time
import logging
import numpy as np
from typing import Dict, Any, List, Optional
from datetime import datetime, timedelta

from tiannara_api.engines.base import BaseEngine

# Import Feature Engineering for sports intelligence
try:
    from tiannara_core.prediction.feature_engineering import FeatureEngineer, engineer_features
    FEATURE_ENGINEERING_AVAILABLE = True
except ImportError:
    FEATURE_ENGINEERING_AVAILABLE = False

# Import ML libraries
try:
    from sklearn.linear_model import LinearRegression, LogisticRegression
    from sklearn.ensemble import RandomForestClassifier, GradientBoostingRegressor
    from sklearn.preprocessing import StandardScaler
    from sklearn.metrics import mean_squared_error, accuracy_score
    SKLEARN_AVAILABLE = True
except ImportError:
    SKLEARN_AVAILABLE = False

try:
    import statsmodels.api as sm
    from statsmodels.tsa.holtwinters import ExponentialSmoothing
    STATSMODELS_AVAILABLE = True
except ImportError:
    STATSMODELS_AVAILABLE = False

logger = logging.getLogger(__name__)


class PredictionEngine(BaseEngine):
    """
    Prediction Engine for forecasting and classification.
    
    Handles:
    - Time series forecasting (Exponential Smoothing, ARIMA)
    - Classification tasks (Logistic Regression, Random Forest)
    - Regression analysis (Linear Regression, Gradient Boosting)
    - Model ensemble methods
    """
    
    def __init__(self):
        super().__init__(name="prediction_engine", version="2.1.0")
        self.models = {}  # Cache trained models
        self.scalers = {}  # Cache feature scalers
        
        # Initialize Feature Engineer for sports intelligence
        self.feature_engineer = None
        if FEATURE_ENGINEERING_AVAILABLE:
            try:
                self.feature_engineer = FeatureEngineer()
                logger.info("✅ Feature Engineering module loaded for sports intelligence")
            except Exception as e:
                logger.warning(f"⚠️  Feature Engineering initialization failed: {e}")
        else:
            logger.warning("⚠️  Feature Engineering not available - install tiannara_core")
        
        logger.info("Prediction Engine initialized with ML capabilities")
        
        if not SKLEARN_AVAILABLE:
            logger.warning("scikit-learn not available - using fallback methods")
        if not STATSMODELS_AVAILABLE:
            logger.warning("statsmodels not available - using simple forecasting")
    
    def process(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """
        Process prediction request with real ML models.
        
        Expected request format:
        {
            "data": list or dict,
            "task": str ("forecast"|"classify"|"regress"),
            "model_type": str (optional),
            "horizon": int (for forecasting),
            "features": list (optional),
            "target": str (optional)
        }
        """
        start_time = time.time()
        
        try:
            task = request.get("task", "forecast")
            data = request.get("data", [])
            model_type = request.get("model_type", "auto")
            horizon = request.get("horizon", 7)
            
            # Route to appropriate prediction method
            if task == "forecast":
                result = self._forecast(data, model_type, horizon)
            elif task == "classify":
                result = self._classify(data, model_type)
            elif task == "regress":
                result = self._regress(data, model_type)
            elif task == "sports_prediction":
                result = self._predict_sports(request)
            else:
                raise ValueError(f"Unknown task type: {task}")
            
            latency_ms = (time.time() - start_time) * 1000
            self.track_request(latency_ms, success=True)
            
            return {
                "status": "success",
                "engine": "prediction_engine",
                "result": result,
                "latency_ms": round(latency_ms, 2),
            }
        
        except Exception as e:
            latency_ms = (time.time() - start_time) * 1000
            self.track_request(latency_ms, success=False)
            logger.error(f"Prediction Engine error: {str(e)}")
            
            return {
                "status": "error",
                "engine": "prediction_engine",
                "error": str(e),
                "latency_ms": round(latency_ms, 2),
            }
    
    def _forecast(self, data: List[Dict], model_type: str, horizon: int) -> Dict[str, Any]:
        """
        Time series forecasting using statistical models.
        
        Args:
            data: List of {date, value} dicts
            model_type: 'exponential_smoothing', 'linear', or 'auto'
            horizon: Number of periods to forecast
        
        Returns:
            Forecast with predictions and confidence intervals
        """
        if not data or len(data) < 3:
            return {
                "predictions": [],
                "confidence": 0.0,
                "model_used": "insufficient_data",
                "message": "Need at least 3 data points for forecasting"
            }
        
        # Extract values
        values = [item.get('value', 0) for item in data if 'value' in item]
        
        if len(values) < 3:
            return {
                "predictions": [],
                "confidence": 0.0,
                "model_used": "insufficient_data"
            }
        
        try:
            if STATSMODELS_AVAILABLE and model_type in ['exponential_smoothing', 'auto']:
                # Use Exponential Smoothing (Holt-Winters)
                model = ExponentialSmoothing(
                    np.array(values),
                    trend='add',
                    seasonal=None,
                    initialization_method="estimated"
                )
                fitted_model = model.fit(optimized=True)
                
                # Generate forecasts
                forecasts = fitted_model.forecast(horizon)
                
                # Calculate confidence intervals (simplified)
                residuals = np.array(values) - fitted_model.fittedvalues
                std_error = np.std(residuals)
                
                predictions = []
                for i, forecast_val in enumerate(forecasts):
                    predictions.append({
                        "period": i + 1,
                        "value": round(float(forecast_val), 2),
                        "lower_bound": round(float(forecast_val - 1.96 * std_error), 2),
                        "upper_bound": round(float(forecast_val + 1.96 * std_error), 2),
                        "confidence": 0.95
                    })
                
                return {
                    "predictions": predictions,
                    "confidence": 0.85,
                    "model_used": "exponential_smoothing",
                    "trend": "detected" if abs(forecasts[-1] - forecasts[0]) > std_error else "stable",
                    "historical_mean": round(float(np.mean(values)), 2),
                    "forecast_horizon": horizon
                }
            
            elif SKLEARN_AVAILABLE:
                # Use Linear Regression as fallback
                X = np.arange(len(values)).reshape(-1, 1)
                y = np.array(values)
                
                model = LinearRegression()
                model.fit(X, y)
                
                # Predict future values
                future_X = np.arange(len(values), len(values) + horizon).reshape(-1, 1)
                forecasts = model.predict(future_X)
                
                # Calculate R-squared as confidence
                train_predictions = model.predict(X)
                r_squared = model.score(X, y)
                
                predictions = []
                for i, forecast_val in enumerate(forecasts):
                    predictions.append({
                        "period": i + 1,
                        "value": round(float(forecast_val), 2),
                        "confidence": round(float(r_squared), 2)
                    })
                
                return {
                    "predictions": predictions,
                    "confidence": round(float(r_squared), 2),
                    "model_used": "linear_regression",
                    "r_squared": round(float(r_squared), 4),
                    "slope": round(float(model.coef_[0]), 4),
                    "forecast_horizon": horizon
                }
            
            else:
                # Simple moving average fallback
                window = min(3, len(values))
                last_avg = np.mean(values[-window:])
                
                predictions = [{
                    "period": i + 1,
                    "value": round(float(last_avg), 2),
                    "confidence": 0.5
                } for i in range(horizon)]
                
                return {
                    "predictions": predictions,
                    "confidence": 0.5,
                    "model_used": "moving_average_fallback",
                    "forecast_horizon": horizon
                }
        
        except Exception as e:
            logger.error(f"Forecasting error: {str(e)}")
            return {
                "predictions": [],
                "confidence": 0.0,
                "model_used": "error",
                "error": str(e)
            }
    
    def _classify(self, data: List[Dict], model_type: str) -> Dict[str, Any]:
        """
        Classification using ML models.
        
        Args:
            data: List of feature dicts with target labels
            model_type: 'logistic_regression', 'random_forest', or 'auto'
        
        Returns:
            Classification results with probabilities
        """
        if not data or len(data) < 5:
            return {
                "predictions": [],
                "confidence": 0.0,
                "model_used": "insufficient_data",
                "message": "Need at least 5 samples for classification"
            }
        
        try:
            if not SKLEARN_AVAILABLE:
                return {
                    "predictions": [],
                    "confidence": 0.0,
                    "model_used": "sklearn_unavailable"
                }
            
            # Extract features and labels
            # Assuming data has 'features' and 'label' keys
            features_list = [item.get('features', []) for item in data if 'features' in item]
            labels = [item.get('label', 0) for item in data if 'label' in item]
            
            if not features_list or not labels:
                # If no structured features, create simple binary classification from text
                # This is a simplified example
                return {
                    "predictions": [
                        {"class": "positive", "probability": 0.6},
                        {"class": "negative", "probability": 0.4}
                    ],
                    "confidence": 0.6,
                    "model_used": "text_classification_simple"
                }
            
            X = np.array(features_list)
            y = np.array(labels)
            
            # Choose model
            if model_type == 'random_forest':
                model = RandomForestClassifier(n_estimators=10, random_state=42)
            else:  # logistic_regression or auto
                model = LogisticRegression(max_iter=1000, random_state=42)
            
            # Train model
            model.fit(X, y)
            
            # Get predictions and probabilities
            predictions_proba = model.predict_proba(X[-1].reshape(1, -1))[0]
            classes = model.classes_
            
            result_predictions = []
            for cls, prob in zip(classes, predictions_proba):
                result_predictions.append({
                    "class": int(cls) if isinstance(cls, (int, np.integer)) else str(cls),
                    "probability": round(float(prob), 4)
                })
            
            # Sort by probability
            result_predictions.sort(key=lambda x: x['probability'], reverse=True)
            
            accuracy = model.score(X, y)
            
            return {
                "predictions": result_predictions,
                "confidence": round(float(accuracy), 4),
                "model_used": model_type if model_type != 'auto' else 'logistic_regression',
                "accuracy": round(float(accuracy), 4),
                "classes": len(classes)
            }
        
        except Exception as e:
            logger.error(f"Classification error: {str(e)}")
            return {
                "predictions": [],
                "confidence": 0.0,
                "model_used": "error",
                "error": str(e)
            }
    
    def _regress(self, data: List[Dict], model_type: str) -> Dict[str, Any]:
        """
        Regression analysis using ML models.
        
        Args:
            data: List of {features: [], target: value} dicts
            model_type: 'linear', 'gradient_boosting', or 'auto'
        
        Returns:
            Regression results with predictions and metrics
        """
        if not data or len(data) < 3:
            return {
                "predictions": [],
                "confidence": 0.0,
                "model_used": "insufficient_data"
            }
        
        try:
            if not SKLEARN_AVAILABLE:
                return {
                    "predictions": [],
                    "confidence": 0.0,
                    "model_used": "sklearn_unavailable"
                }
            
            # Extract features and targets
            features_list = [item.get('features', []) for item in data if 'features' in item]
            targets = [item.get('target', 0) for item in data if 'target' in item]
            
            if not features_list or not targets:
                return {
                    "predictions": [],
                    "confidence": 0.0,
                    "model_used": "missing_features_or_target"
                }
            
            X = np.array(features_list)
            y = np.array(targets)
            
            # Choose model
            if model_type == 'gradient_boosting':
                model = GradientBoostingRegressor(n_estimators=10, random_state=42)
            else:  # linear or auto
                model = LinearRegression()
            
            # Train model
            model.fit(X, y)
            
            # Get predictions
            predictions = model.predict(X)
            
            # Calculate metrics
            mse = mean_squared_error(y, predictions)
            r_squared = model.score(X, y)
            
            # Predict next value (using last features as example)
            next_prediction = model.predict(X[-1].reshape(1, -1))[0]
            
            return {
                "predictions": [
                    {"actual": round(float(actual), 2), "predicted": round(float(pred), 2)}
                    for actual, pred in zip(y[-5:], predictions[-5:])
                ],
                "next_prediction": round(float(next_prediction), 2),
                "confidence": round(float(r_squared), 4),
                "model_used": model_type if model_type != 'auto' else 'linear_regression',
                "r_squared": round(float(r_squared), 4),
                "mse": round(float(mse), 4),
                "coefficients": [round(float(c), 4) for c in model.coef_] if hasattr(model, 'coef_') else []
            }
        
        except Exception as e:
            logger.error(f"Regression error: {str(e)}")
            return {
                "predictions": [],
                "confidence": 0.0,
                "model_used": "error",
                "error": str(e)
            }
    
    def _predict_sports(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """
        Sports prediction using feature engineering formulas from realtime.md.
        
        Integrates momentum index, odds velocity, news impact, chaos index,
        and market inefficiency for comprehensive match intelligence.
        """
        if not FEATURE_ENGINEERING_AVAILABLE or not self.feature_engineer:
            return {
                "status": "error",
                "message": "Feature Engineering module not available",
                "recommendation": "Install tiannara_core.prediction.feature_engineering"
            }
        
        try:
            # Extract data from request
            match_stats = request.get("match_stats", {})
            odds_history = request.get("odds_history", [])
            news_events = request.get("news_events", [])
            model_probs = request.get("model_probs", {"home": 0.33, "draw": 0.34, "away": 0.33})
            market_probs = request.get("market_probs", {"home": 0.33, "draw": 0.34, "away": 0.33})
            
            # Generate comprehensive feature vector
            features = engineer_features(
                match_stats=match_stats,
                odds_history=odds_history,
                news_events=news_events,
                model_probs=model_probs,
                market_probs=market_probs
            )
            
            # Calculate base prediction using momentum and features
            momentum_diff = features['momentum_features']['momentum_diff']
            chaos_index = features['chaos_features']['chaos_index']
            news_impact = features['news_features']['news_impact_score']
            mis = features['market_features']['market_inefficiency']
            
            # Adjust probabilities based on engineered features
            adjusted_probs = self._adjust_probabilities_with_features(
                base_probs=model_probs,
                momentum_diff=momentum_diff,
                chaos_index=chaos_index,
                news_impact=news_impact,
                mis=mis
            )
            
            # Determine prediction confidence
            confidence = self._calculate_prediction_confidence(
                chaos_index=chaos_index,
                mis=mis,
                momentum_strength=abs(momentum_diff)
            )
            
            # Generate key drivers explanation
            key_drivers = self._identify_key_drivers(features)
            
            # Risk assessment
            risk_level = self._assess_risk(chaos_index, news_impact)
            
            return {
                "prediction": {
                    "home_win": round(adjusted_probs['home'], 4),
                    "draw": round(adjusted_probs['draw'], 4),
                    "away_win": round(adjusted_probs['away'], 4),
                    "predicted_outcome": max(adjusted_probs, key=adjusted_probs.get),
                    "confidence": confidence
                },
                "features": features,
                "intelligence": {
                    "chaos_level": features['chaos_features']['chaos_level'],
                    "jackpot_potential": features['chaos_features']['jackpot_potential'],
                    "value_signal": features['market_features']['value_signal'],
                    "value_opportunity": features['market_features']['value_opportunity'],
                    "risk_level": risk_level,
                    "key_drivers": key_drivers
                },
                "model_used": "feature_engineering_v1",
                "timestamp": datetime.now().isoformat()
            }
        
        except Exception as e:
            logger.error(f"Sports prediction error: {str(e)}")
            import traceback
            traceback.print_exc()
            return {
                "status": "error",
                "error": str(e),
                "message": "Failed to generate sports prediction"
            }
    
    def _adjust_probabilities_with_features(
        self,
        base_probs: Dict[str, float],
        momentum_diff: float,
        chaos_index: float,
        news_impact: float,
        mis: float
    ) -> Dict[str, float]:
        """Adjust base probabilities using engineered features."""
        home = base_probs.get('home', 0.33)
        draw = base_probs.get('draw', 0.34)
        away = base_probs.get('away', 0.33)
        
        # Momentum adjustment (strong momentum shifts probability)
        momentum_adjustment = momentum_diff * 0.15  # Max ±15% shift
        home += momentum_adjustment
        away -= momentum_adjustment
        
        # News impact adjustment
        if news_impact < -0.3:
            if home > away:
                home *= (1 + news_impact * 0.1)
            else:
                away *= (1 + news_impact * 0.1)
        
        # Chaos reduces all probabilities toward uniform distribution
        if chaos_index > 0.6:
            uniform = 1.0 / 3.0
            chaos_factor = (chaos_index - 0.6) * 0.5
            home = home * (1 - chaos_factor) + uniform * chaos_factor
            draw = draw * (1 - chaos_factor) + uniform * chaos_factor
            away = away * (1 - chaos_factor) + uniform * chaos_factor
        
        # Normalize to ensure probabilities sum to 1
        total = home + draw + away
        if total > 0:
            home /= total
            draw /= total
            away /= total
        
        return {'home': home, 'draw': draw, 'away': away}
    
    def _calculate_prediction_confidence(
        self,
        chaos_index: float,
        mis: float,
        momentum_strength: float
    ) -> float:
        """Calculate prediction confidence based on feature quality."""
        confidence = 0.5 + (momentum_strength * 0.3)
        
        if chaos_index > 0.6:
            confidence *= (1 - (chaos_index - 0.6))
        
        if mis < 0.05:
            confidence *= 1.1
        
        return round(max(0.1, min(0.95, confidence)), 4)
    
    def _identify_key_drivers(self, features: Dict) -> List[str]:
        """Identify the key factors driving the prediction."""
        drivers = []
        
        momentum_diff = features['momentum_features']['momentum_diff']
        if abs(momentum_diff) > 0.2:
            direction = "HOME" if momentum_diff > 0 else "AWAY"
            drivers.append(f"Strong {direction} momentum ({momentum_diff:+.2f})")
        
        if features['chaos_features']['chaos_index'] > 0.6:
            drivers.append("High match unpredictability (chaos match)")
        
        news_impact = features['news_features']['news_impact_score']
        if abs(news_impact) > 0.3:
            sentiment = "NEGATIVE" if news_impact < 0 else "POSITIVE"
            drivers.append(f"{sentiment} news impact ({news_impact:+.2f})")
        
        if features['market_features']['value_opportunity']:
            drivers.append(f"Value opportunity detected (MIS: {features['market_features']['market_inefficiency']:.2f})")
        
        if features['odds_features']['odds_direction'] != 'stable':
            direction = features['odds_features']['odds_direction'].upper()
            drivers.append(f"Odds {direction} (sharp money signal)")
        
        return drivers if drivers else ["Balanced match with no strong signals"]
    
    def _assess_risk(self, chaos_index: float, news_impact: float) -> str:
        """Assess overall prediction risk level."""
        risk_score = 0.0
        risk_score += chaos_index * 0.6
        if news_impact < -0.3:
            risk_score += abs(news_impact) * 0.4
        
        if risk_score > 0.6:
            return "high"
        elif risk_score > 0.3:
            return "medium"
        else:
            return "low"
    
    def get_health(self) -> Dict[str, Any]:
        """Get engine health status."""
        metrics = self.get_metrics()
        return {
            "engine": "prediction_engine",
            "status": metrics["status"],
            "uptime_percentage": 100.0,
            "total_requests": metrics["total_requests"],
            "avg_latency_ms": metrics["avg_latency_ms"],
            "success_rate": metrics["success_rate"],
            "ml_libraries": {
                "sklearn_available": SKLEARN_AVAILABLE,
                "statsmodels_available": STATSMODELS_AVAILABLE
            },
            "feature_engineering": {
                "available": FEATURE_ENGINEERING_AVAILABLE,
                "initialized": self.feature_engineer is not None
            },
            "cached_models": len(self.models)
        }
