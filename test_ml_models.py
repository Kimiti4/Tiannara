"""
Test Enhanced PredictionEngine with Real ML Models

Tests the upgraded PredictionEngine with actual scikit-learn and statsmodels.
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from tiannara_api.engines.prediction import PredictionEngine


def print_section(title: str):
    print("\n" + "=" * 80)
    print(f"  {title}")
    print("=" * 80)


def test_forecasting():
    """Test time series forecasting with real data."""
    print_section("TEST 1: Time Series Forecasting")
    
    engine = PredictionEngine()
    
    # Test data: Sales over 7 days
    data = [
        {"date": "2026-01-01", "value": 100},
        {"date": "2026-01-02", "value": 105},
        {"date": "2026-01-03", "value": 98},
        {"date": "2026-01-04", "value": 110},
        {"date": "2026-01-05", "value": 115},
        {"date": "2026-01-06", "value": 112},
        {"date": "2026-01-07", "value": 120}
    ]
    
    request = {
        "data": data,
        "task": "forecast",
        "model_type": "auto",
        "horizon": 5
    }
    
    result = engine.process(request)
    
    print(f"\n✅ Status: {result['status']}")
    print(f"   Engine: {result['engine']}")
    print(f"   Latency: {result['latency_ms']:.2f}ms")
    
    if result['status'] == 'success':
        forecast_result = result['result']
        print(f"\n📊 Forecast Results:")
        print(f"   Model Used: {forecast_result.get('model_used', 'unknown')}")
        print(f"   Confidence: {forecast_result.get('confidence', 0):.2%}")
        print(f"   Horizon: {forecast_result.get('forecast_horizon', 0)} periods")
        
        if 'trend' in forecast_result:
            print(f"   Trend: {forecast_result['trend']}")
        
        predictions = forecast_result.get('predictions', [])
        print(f"\n🔮 Predictions:")
        for pred in predictions[:3]:  # Show first 3
            print(f"   Period {pred['period']}: {pred['value']} "
                  f"(CI: {pred.get('lower_bound', 'N/A')} - {pred.get('upper_bound', 'N/A')})")
        
        return True
    else:
        print(f"\n❌ Error: {result.get('error', 'Unknown error')}")
        return False


def test_classification():
    """Test classification with sample data."""
    print_section("TEST 2: Classification")
    
    engine = PredictionEngine()
    
    # Training data: Customer features and churn labels
    data = [
        {"features": [0.2, 0.8, 0.5], "label": 0},  # Not churned
        {"features": [0.9, 0.1, 0.2], "label": 1},  # Churned
        {"features": [0.3, 0.7, 0.6], "label": 0},
        {"features": [0.8, 0.2, 0.3], "label": 1},
        {"features": [0.1, 0.9, 0.7], "label": 0},
        {"features": [0.7, 0.3, 0.1], "label": 1},
        {"features": [0.4, 0.6, 0.4], "label": 0},
        {"features": [0.6, 0.4, 0.2], "label": 1}
    ]
    
    request = {
        "data": data,
        "task": "classify",
        "model_type": "logistic_regression"
    }
    
    result = engine.process(request)
    
    print(f"\n✅ Status: {result['status']}")
    print(f"   Engine: {result['engine']}")
    print(f"   Latency: {result['latency_ms']:.2f}ms")
    
    if result['status'] == 'success':
        class_result = result['result']
        print(f"\n📊 Classification Results:")
        print(f"   Model Used: {class_result.get('model_used', 'unknown')}")
        print(f"   Accuracy: {class_result.get('accuracy', 0):.2%}")
        print(f"   Classes: {class_result.get('classes', 0)}")
        
        predictions = class_result.get('predictions', [])
        print(f"\n🎯 Predictions:")
        for pred in predictions:
            print(f"   Class {pred['class']}: {pred['probability']:.2%} probability")
        
        return True
    else:
        print(f"\n❌ Error: {result.get('error', 'Unknown error')}")
        return False


def test_regression():
    """Test regression analysis."""
    print_section("TEST 3: Regression Analysis")
    
    engine = PredictionEngine()
    
    # Training data: House features and prices
    data = [
        {"features": [1500, 3, 2], "target": 300000},
        {"features": [2000, 4, 3], "target": 400000},
        {"features": [1200, 2, 1], "target": 250000},
        {"features": [2500, 5, 4], "target": 500000},
        {"features": [1800, 3, 2], "target": 350000},
        {"features": [2200, 4, 3], "target": 450000}
    ]
    
    request = {
        "data": data,
        "task": "regress",
        "model_type": "linear"
    }
    
    result = engine.process(request)
    
    print(f"\n✅ Status: {result['status']}")
    print(f"   Engine: {result['engine']}")
    print(f"   Latency: {result['latency_ms']:.2f}ms")
    
    if result['status'] == 'success':
        reg_result = result['result']
        print(f"\n📊 Regression Results:")
        print(f"   Model Used: {reg_result.get('model_used', 'unknown')}")
        print(f"   R-squared: {reg_result.get('r_squared', 0):.4f}")
        print(f"   MSE: {reg_result.get('mse', 0):.2f}")
        
        next_pred = reg_result.get('next_prediction', 0)
        print(f"\n🔮 Next Prediction: ${next_pred:,.2f}")
        
        predictions = reg_result.get('predictions', [])
        print(f"\n📈 Sample Predictions vs Actual:")
        for pred in predictions[:3]:
            print(f"   Actual: ${pred['actual']:,.2f} | Predicted: ${pred['predicted']:,.2f}")
        
        return True
    else:
        print(f"\n❌ Error: {result.get('error', 'Unknown error')}")
        return False


def test_health_check():
    """Test engine health status."""
    print_section("TEST 4: Health Check")
    
    engine = PredictionEngine()
    health = engine.get_health()
    
    print(f"\n✅ Engine: {health['engine']}")
    print(f"   Status: {health['status']}")
    print(f"   Uptime: {health['uptime_percentage']:.1f}%")
    print(f"   Total Requests: {health['total_requests']}")
    print(f"   Avg Latency: {health['avg_latency_ms']:.2f}ms")
    print(f"   Success Rate: {health['success_rate']:.2%}")
    
    ml_libs = health.get('ml_libraries', {})
    print(f"\n📚 ML Libraries:")
    print(f"   scikit-learn: {'✅ Available' if ml_libs.get('sklearn_available') else '❌ Not Available'}")
    print(f"   statsmodels: {'✅ Available' if ml_libs.get('statsmodels_available') else '❌ Not Available'}")
    
    return True


def main():
    """Run all ML model tests."""
    print("\n" + "=" * 80)
    print("  PREDICTION ENGINE - REAL ML MODELS TEST")
    print("  Testing scikit-learn and statsmodels integration")
    print("=" * 80)
    
    results = {}
    
    # Test 1: Forecasting
    results['forecasting'] = test_forecasting()
    
    # Test 2: Classification
    results['classification'] = test_classification()
    
    # Test 3: Regression
    results['regression'] = test_regression()
    
    # Test 4: Health Check
    results['health'] = test_health_check()
    
    # Summary
    print_section("FINAL SUMMARY")
    
    passed = sum(1 for v in results.values() if v)
    total = len(results)
    
    print(f"\n  Tests Run: {total}")
    print(f"  Passed: {passed}")
    print(f"  Failed: {total - passed}")
    print(f"  Success Rate: {(passed/total*100):.1f}%")
    
    print(f"\n  Detailed Results:")
    for test_name, success in results.items():
        status = "✅ PASSED" if success else "❌ FAILED"
        print(f"    {status}: {test_name.title()}")
    
    print("\n" + "=" * 80)
    
    if passed == total:
        print("\n🎉 ALL ML MODEL TESTS PASSED! PredictionEngine is ready with real ML.")
    else:
        print(f"\n⚠️  {total - passed} test(s) failed. Review errors above.")
    
    print("\n" + "=" * 80)
    
    return passed == total


if __name__ == "__main__":
    try:
        success = main()
        sys.exit(0 if success else 1)
    except Exception as e:
        print(f"\n\n❌ Fatal error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
