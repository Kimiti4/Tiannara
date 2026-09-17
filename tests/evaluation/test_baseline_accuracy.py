"""
Baseline Prediction Accuracy Tests

Purpose: Establish baseline metrics before accuracy enhancements
Tests current prediction systems to measure:
- Cross-domain transfer accuracy
- Predictive assistance confidence
- Intent recognition accuracy
- Overall system performance

Date: May 8, 2026
Status: Baseline Measurement
"""

from tiannara_core.transfer.cross_domain_transfer import (
    CrossDomainTransferEngine,
    DomainProfile,
    DomainCategory
)
from tiannara_core.assistance.predictive_engine import (
    PredictiveAssistanceEngine,
    UserContext
)
from tiannara_core.nlp.advanced_nlp import AdvancedNLPEngine
from tiannara_core.ensemble.ensemble_predictor import EnsemblePredictor
from datetime import datetime, timedelta
import time


def test_cross_domain_transfer_baseline():
    """Test cross-domain transfer baseline accuracy."""
    print("\n" + "="*70)
    print("BASELINE TEST 1: CROSS-DOMAIN TRANSFER")
    print("="*70)
    
    engine = CrossDomainTransferEngine()
    
    # Register domains
    domains = [
        DomainProfile(
            domain_id="linear_regression",
            name="Linear Regression",
            category=DomainCategory.MATHEMATICAL,
            description="Simple linear regression",
            features_used=["mean", "variance", "correlation"],
            algorithms_used=["least_squares"],
            common_patterns=["linear_trend"]
        ),
        DomainProfile(
            domain_id="classification",
            name="Binary Classification",
            category=DomainCategory.CLASSIFICATION,
            description="Two-class classification",
            features_used=["mean", "variance", "entropy"],
            algorithms_used=["logistic_regression"],
            common_patterns=["boundary_detection"]
        )
    ]
    
    for domain in domains:
        engine.register_domain(domain)
    
    # Abstract skills
    engine.abstract_skill(
        domain_id="linear_regression",
        skill_name="Outlier Detection",
        skill_type="pattern",
        features=["mean", "variance"],
        performance=0.85
    )
    
    # Find and execute transfers
    candidates = engine.find_transfer_candidates(
        source_domain_id="linear_regression",
        target_domain_id="classification",
        min_confidence=0.4
    )
    
    results = []
    if candidates:
        for candidate in candidates[:3]:  # Test top 3
            result = engine.execute_transfer(candidate)
            results.append(result)
    
    # Calculate metrics
    if results:
        avg_performance = sum(r.actual_performance for r in results) / len(results)
        success_rate = sum(1 for r in results if r.validated) / len(results)
        avg_confidence = sum(r.candidate.confidence for r in results) / len(results)
        
        print(f"\n✓ Cross-domain transfer baseline:")
        print(f"  Transfers executed: {len(results)}")
        print(f"  Average performance: {avg_performance:.2f}")
        print(f"  Success rate: {success_rate:.2%}")
        print(f"  Average confidence: {avg_confidence:.2f}")
        
        return {
            "transfers": len(results),
            "avg_performance": avg_performance,
            "success_rate": success_rate,
            "avg_confidence": avg_confidence
        }
    else:
        print(f"\n⚠ No transfer candidates found")
        return {"transfers": 0, "avg_performance": 0, "success_rate": 0, "avg_confidence": 0}


def test_predictive_assistance_baseline():
    """Test predictive assistance baseline accuracy."""
    print("\n" + "="*70)
    print("BASELINE TEST 2: PREDICTIVE ASSISTANCE")
    print("="*70)
    
    engine = PredictiveAssistanceEngine()
    
    # Create test contexts
    contexts = [
        UserContext(
            user_id="test_user_1",
            current_task="model_training",
            current_domain="prediction",
            session_duration_minutes=15.0,
            recent_actions=["load_data", "explore_data", "select_model"],
            time_of_day="morning",
            day_of_week=2
        ),
        UserContext(
            user_id="test_user_2",
            current_task="data_analysis",
            current_domain="analysis",
            session_duration_minutes=20.0,
            recent_actions=["load_dataset", "clean_data", "explore_statistics"],
            time_of_day="afternoon",
            day_of_week=3
        )
    ]
    
    # Update contexts and get predictions
    all_predictions = []
    for context in contexts:
        engine.update_user_context(context)
        predictions = engine.predict_next_actions(context, top_k=2)
        all_predictions.extend(predictions)
    
    # Calculate metrics
    if all_predictions:
        avg_confidence = sum(p.confidence for p in all_predictions) / len(all_predictions)
        high_confidence = sum(1 for p in all_predictions if p.confidence >= 0.7)
        
        print(f"\n✓ Predictive assistance baseline:")
        print(f"  Total predictions: {len(all_predictions)}")
        print(f"  Average confidence: {avg_confidence:.2f}")
        print(f"  High confidence (≥0.7): {high_confidence}/{len(all_predictions)}")
        
        # Generate suggestions
        suggestions = engine.generate_suggestions(all_predictions, max_suggestions=5)
        print(f"  Suggestions generated: {len(suggestions)}")
        
        return {
            "predictions": len(all_predictions),
            "avg_confidence": avg_confidence,
            "high_confidence_count": high_confidence,
            "suggestions": len(suggestions)
        }
    else:
        print(f"\n⚠ No predictions generated")
        return {"predictions": 0, "avg_confidence": 0, "high_confidence_count": 0, "suggestions": 0}


def test_intent_recognition_baseline():
    """Test intent recognition baseline accuracy."""
    print("\n" + "="*70)
    print("BASELINE TEST 3: INTENT RECOGNITION")
    print("="*70)
    
    nlp_engine = AdvancedNLPEngine()
    
    # Test queries
    test_queries = [
        ("Predict who will win tomorrow", "prediction"),
        ("Analyze team performance", "analysis"),
        ("What are the standings?", "information"),
        ("Create a new model", "action"),
        ("Configure settings", "configuration"),
    ]
    
    results = []
    for query, expected_category in test_queries:
        result = nlp_engine.classify_intent(query)
        correct = result.category.value == expected_category
        results.append({
            "query": query,
            "expected": expected_category,
            "predicted": result.category.value,
            "correct": correct,
            "confidence": result.confidence
        })
    
    # Calculate metrics
    accuracy = sum(1 for r in results if r["correct"]) / len(results)
    avg_confidence = sum(r["confidence"] for r in results) / len(results)
    
    print(f"\n✓ Intent recognition baseline:")
    print(f"  Test queries: {len(results)}")
    print(f"  Accuracy: {accuracy:.2%}")
    print(f"  Average confidence: {avg_confidence:.2f}")
    
    for r in results:
        status = "✓" if r["correct"] else "✗"
        print(f"  {status} \"{r['query'][:40]}...\" → {r['predicted']} ({r['confidence']:.2f})")
    
    return {
        "queries": len(results),
        "accuracy": accuracy,
        "avg_confidence": avg_confidence
    }


def test_ensemble_baseline():
    """Test ensemble predictor baseline."""
    print("\n" + "="*70)
    print("BASELINE TEST 4: ENSEMBLE PREDICTOR")
    print("="*70)
    
    ensemble = EnsemblePredictor()
    
    # Test inputs
    test_inputs = [
        {"default_prediction": "A", "ml_prediction": "A", "temporal_prediction": "B"},
        {"default_prediction": "X", "ml_prediction": "Y", "temporal_prediction": "X"},
        {"default_prediction": "outcome_1", "ml_prediction": "outcome_1"},
    ]
    
    results = []
    start_time = time.time()
    
    for test_input in test_inputs:
        result = ensemble.predict(test_input)
        results.append(result)
    
    end_time = time.time()
    total_time = (end_time - start_time) * 1000
    
    # Calculate metrics
    avg_confidence = sum(r.final_confidence for r in results) / len(results)
    avg_agreement = sum(r.agreement_score for r in results) / len(results)
    avg_uncertainty = sum(r.uncertainty for r in results) / len(results)
    avg_inference_time = sum(r.total_inference_time_ms for r in results) / len(results)
    
    print(f"\n✓ Ensemble predictor baseline:")
    print(f"  Predictions made: {len(results)}")
    print(f"  Average confidence: {avg_confidence:.2f}")
    print(f"  Average agreement: {avg_agreement:.2f}")
    print(f"  Average uncertainty: {avg_uncertainty:.2f}")
    print(f"  Average inference time: {avg_inference_time:.2f}ms")
    print(f"  Total time: {total_time:.2f}ms")
    
    stats = ensemble.get_statistics()
    print(f"\n  Ensemble statistics:")
    print(f"    Models: {stats['models_count']}")
    print(f"    Method: {stats['method']}")
    
    return {
        "predictions": len(results),
        "avg_confidence": avg_confidence,
        "avg_agreement": avg_agreement,
        "avg_uncertainty": avg_uncertainty,
        "avg_inference_time": avg_inference_time
    }


def main():
    """Run all baseline tests."""
    
    print("\n" + "="*70)
    print("BASELINE PREDICTION ACCURACY TESTS")
    print("="*70)
    print("\nEstablishing baseline metrics before accuracy enhancements...")
    
    overall_start = time.time()
    
    # Run tests
    try:
        transfer_results = test_cross_domain_transfer_baseline()
    except Exception as e:
        print(f"\n❌ Transfer test failed: {e}")
        transfer_results = {"error": str(e)}
    
    try:
        assistance_results = test_predictive_assistance_baseline()
    except Exception as e:
        print(f"\n❌ Assistance test failed: {e}")
        assistance_results = {"error": str(e)}
    
    try:
        intent_results = test_intent_recognition_baseline()
    except Exception as e:
        print(f"\n❌ Intent test failed: {e}")
        intent_results = {"error": str(e)}
    
    try:
        ensemble_results = test_ensemble_baseline()
    except Exception as e:
        print(f"\n❌ Ensemble test failed: {e}")
        ensemble_results = {"error": str(e)}
    
    overall_end = time.time()
    total_time = overall_end - overall_start
    
    # Summary
    print("\n\n" + "="*70)
    print("BASELINE SUMMARY")
    print("="*70)
    
    print(f"\n📊 Current Performance Metrics:")
    print(f"{'─'*70}")
    
    if "error" not in transfer_results:
        print(f"\n1. Cross-Domain Transfer:")
        print(f"   - Success Rate: {transfer_results['success_rate']:.2%}")
        print(f"   - Avg Performance: {transfer_results['avg_performance']:.2f}")
        print(f"   - Avg Confidence: {transfer_results['avg_confidence']:.2f}")
    
    if "error" not in assistance_results:
        print(f"\n2. Predictive Assistance:")
        print(f"   - Avg Confidence: {assistance_results['avg_confidence']:.2f}")
        print(f"   - High Confidence: {assistance_results['high_confidence_count']}/{assistance_results['predictions']}")
    
    if "error" not in intent_results:
        print(f"\n3. Intent Recognition:")
        print(f"   - Accuracy: {intent_results['accuracy']:.2%}")
        print(f"   - Avg Confidence: {intent_results['avg_confidence']:.2f}")
    
    if "error" not in ensemble_results:
        print(f"\n4. Ensemble Predictor:")
        print(f"   - Avg Confidence: {ensemble_results['avg_confidence']:.2f}")
        print(f"   - Avg Agreement: {ensemble_results['avg_agreement']:.2f}")
        print(f"   - Inference Time: {ensemble_results['avg_inference_time']:.2f}ms")
    
    print(f"\n{'─'*70}")
    print(f"Total test time: {total_time:.2f}s")
    
    # Calculate overall baseline
    baselines = []
    if "error" not in transfer_results:
        baselines.append(("Cross-Domain Transfer", transfer_results['success_rate']))
    if "error" not in assistance_results:
        baselines.append(("Predictive Assistance", assistance_results['avg_confidence']))
    if "error" not in intent_results:
        baselines.append(("Intent Recognition", intent_results['accuracy']))
    if "error" not in ensemble_results:
        baselines.append(("Ensemble Predictor", ensemble_results['avg_confidence']))
    
    if baselines:
        overall_avg = sum(b[1] for b in baselines) / len(baselines)
        print(f"\n🎯 OVERALL BASELINE ACCURACY: {overall_avg:.2%}")
        print(f"\n📈 TARGET AFTER ENHANCEMENTS: >90%")
        print(f"📊 IMPROVEMENT NEEDED: +{(0.90 - overall_avg)*100:.1f}%")
    
    print(f"\n{'='*70}")
    print("✅ BASELINE TESTS COMPLETE")
    print(f"{'='*70}\n")
    
    return {
        "transfer": transfer_results,
        "assistance": assistance_results,
        "intent": intent_results,
        "ensemble": ensemble_results,
        "overall_avg": overall_avg if baselines else 0,
        "total_time": total_time
    }


if __name__ == "__main__":
    results = main()
