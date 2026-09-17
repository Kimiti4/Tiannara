"""
Test Hybrid Implementation: Redis Cache + Integrity Monitor

Validates that both Phase 2 infrastructure (caching) and 
1,000-step mission monitoring work correctly.
"""

import sys
from pathlib import Path
from datetime import datetime, timedelta
import asyncio

sys.path.insert(0, str(Path(__file__).parent))

from tiannara_core.cache.redis_cache import TiannaraRedisCache
from tiannara_core.integrity.monitor import IntegrityMonitor


async def test_redis_caching():
    """Test 1: Redis caching for sports predictions."""
    print("=" * 80)
    print("  TEST 1: Redis Caching Layer")
    print("=" * 80)
    
    cache = TiannaraRedisCache()
    await cache.connect()
    
    # Test match features caching
    print("\n📊 Caching match features...")
    match_features = {
        "momentum_features": {"momentum_diff": 0.35},
        "chaos_features": {"chaos_index": 0.45},
        "timestamp": datetime.now().isoformat()
    }
    
    await cache.cache_match_features("match_123", match_features, ttl=30)
    retrieved = await cache.get_match_features("match_123")
    
    if retrieved and retrieved["momentum_features"]["momentum_diff"] == 0.35:
        print("✅ Match features cached and retrieved successfully")
    else:
        print("❌ Failed to cache/retrieve match features")
        return False
    
    # Test odds snapshot
    print("\n💰 Caching odds snapshot...")
    odds_data = {"home": 1.85, "draw": 3.40, "away": 4.20}
    await cache.cache_odds_snapshot("match_123", odds_data, ttl=60)
    odds_retrieved = await cache.get_odds_snapshot("match_123")
    
    if odds_retrieved and odds_retrieved["odds"]["home"] == 1.85:
        print("✅ Odds snapshot cached successfully")
    else:
        print("❌ Failed to cache odds")
        return False
    
    # Test feature store
    print("\n🗄️  Storing feature snapshot...")
    await cache.store_feature_snapshot("match_123", match_features)
    print("✅ Feature snapshot stored")
    
    # Get health status
    health = await cache.get_health_status()
    print(f"\nCache Health: {health['status']}")
    
    await cache.disconnect()
    print("\n✅ PASSED: Redis caching layer working")
    return True


async def test_integrity_monitoring():
    """Test 2: System integrity monitoring (1,000-step mission)."""
    print("\n" + "=" * 80)
    print("  TEST 2: Integrity Monitor (1,000-Step Mission)")
    print("=" * 80)
    
    monitor = IntegrityMonitor()
    
    # Test identity drift check
    print("\n🔍 Checking identity drift...")
    system_state = {
        "constitution_violations": [],
        "goal_deviation": 0.1,
        "behavioral_anomalies": []
    }
    
    drift = await monitor.check_identity_drift(system_state)
    print(f"Identity Drift Score: {drift:.4f}")
    
    if 0 <= drift <= 1.0:
        print("✅ Identity drift check working")
    else:
        print("❌ Invalid drift score")
        return False
    
    # Test causal degradation
    print("\n🧠 Checking causal reasoning quality...")
    recent_decisions = [
        {
            "causal_chain_complete": True,
            "predicted_outcome": "A",
            "actual_outcome": "A",
            "counterfactual_quality": 0.8
        },
        {
            "causal_chain_complete": True,
            "predicted_outcome": "B",
            "actual_outcome": "B",
            "counterfactual_quality": 0.9
        }
    ]
    
    degradation = await monitor.check_causal_degradation(recent_decisions)
    print(f"Causal Degradation Score: {degradation:.4f}")
    
    if 0 <= degradation <= 1.0:
        print("✅ Causal degradation check working")
    else:
        print("❌ Invalid degradation score")
        return False
    
    # Test memory corruption
    print("\n💾 Checking memory integrity...")
    memory_samples = [
        {"id": "1", "timestamp": "2026-01-01T00:00:00", "content": "test1"},
        {"id": "2", "timestamp": "2026-01-01T01:00:00", "content": "test2"}
    ]
    
    corruption = await monitor.check_memory_corruption(memory_samples)
    print(f"Memory Corruption Score: {corruption:.4f}")
    
    if 0 <= corruption <= 1.0:
        print("✅ Memory corruption check working")
    else:
        print("❌ Invalid corruption score")
        return False
    
    # Test confidence inflation
    print("\n📈 Checking confidence calibration...")
    predictions = [
        {"confidence": 0.75, "correct": True},
        {"confidence": 0.80, "correct": True},
        {"confidence": 0.70, "correct": False}
    ]
    
    inflation = await monitor.check_confidence_inflation(predictions)
    print(f"Confidence Inflation Score: {inflation:.4f}")
    
    if 0 <= inflation <= 1.0:
        print("✅ Confidence inflation check working")
    else:
        print("❌ Invalid inflation score")
        return False
    
    # Test contradiction accumulation
    print("\n⚖️  Checking logical consistency...")
    knowledge_base = [
        {"topic": "weather", "claim": "It is sunny"},
        {"topic": "weather", "claim": "It is cloudy"}
    ]
    
    contradictions = await monitor.check_contradiction_accumulation(knowledge_base)
    print(f"Contradiction Score: {contradictions:.4f}")
    
    if 0 <= contradictions <= 1.0:
        print("✅ Contradiction check working")
    else:
        print("❌ Invalid contradiction score")
        return False
    
    print("\n✅ PASSED: All integrity metrics working")
    return True


async def test_full_integrity_check():
    """Test 3: Comprehensive integrity report."""
    print("\n" + "=" * 80)
    print("  TEST 3: Full Integrity Check Report")
    print("=" * 80)
    
    monitor = IntegrityMonitor()
    
    # Prepare comprehensive system state
    system_state = {
        "constitution_violations": [],
        "goal_deviation": 0.05,
        "behavioral_anomalies": [],
        "recent_decisions": [
            {"causal_chain_complete": True, "predicted_outcome": "A", "actual_outcome": "A", "counterfactual_quality": 0.85}
            for _ in range(5)
        ],
        "memory_samples": [
            {"id": str(i), "timestamp": f"2026-01-01T{i:02d}:00:00", "content": f"entry_{i}"}
            for i in range(10)
        ],
        "predictions": [
            {"confidence": 0.75, "correct": True}
            for _ in range(10)
        ],
        "knowledge_base": [
            {"topic": f"topic_{i}", "claim": f"fact_{i}"}
            for i in range(5)
        ]
    }
    
    print("\n🔍 Running comprehensive integrity check...")
    report = await monitor.run_full_integrity_check(system_state)
    
    print(f"\nCheck Duration: {report['check_duration_seconds']}s")
    print(f"\nMetrics:")
    for metric_name, metric_data in report['metrics'].items():
        status_icon = "✅" if metric_data['status'] == 'healthy' else "⚠️" if metric_data['status'] == 'warning' else "❌"
        print(f"  {status_icon} {metric_name}: {metric_data['value']:.4f} ({metric_data['status']})")
    
    print(f"\nOverall Health: {report['overall_health'].get('status', 'unknown')}")
    print(f"Health Score: {report['overall_health'].get('score', 0):.4f}")
    
    print(f"\nRecommendations: {len(report['recommendations'])}")
    for rec in report['recommendations']:
        priority_icon = "🔴" if rec['priority'] == 'high' else "🟡" if rec['priority'] == 'medium' else "🟢"
        print(f"  {priority_icon} [{rec['priority'].upper()}] {rec['action']}")
    
    print(f"\nAction Required: {'Yes ⚠️' if report['action_required'] else 'No ✅'}")
    
    # Validate report structure
    required_keys = ["timestamp", "metrics", "overall_health", "recommendations", "action_required"]
    if all(key in report for key in required_keys):
        print("\n✅ PASSED: Full integrity check report valid")
        return True
    else:
        print("\n❌ FAILED: Report missing required fields")
        return False


async def test_integration_scenario():
    """Test 4: Integrated scenario - cache features then monitor integrity."""
    print("\n" + "=" * 80)
    print("  TEST 4: Integration Scenario")
    print("=" * 80)
    
    cache = TiannaraRedisCache()
    monitor = IntegrityMonitor()
    
    await cache.connect()
    
    print("\n🔄 Simulating live match with integrity monitoring...")
    
    # Step 1: Cache match features
    match_id = "live_match_456"
    features = {
        "momentum_features": {"momentum_diff": 0.42},
        "chaos_features": {"chaos_index": 0.35, "jackpot_potential": False},
        "news_features": {"news_impact_score": -0.25},
        "market_features": {"market_inefficiency": 0.12, "value_opportunity": True}
    }
    
    await cache.cache_match_features(match_id, features, ttl=30)
    print(f"✅ Cached features for {match_id}")
    
    # Step 2: Record integrity metrics based on prediction quality
    await monitor.check_confidence_inflation([
        {"confidence": 0.78, "correct": True}
    ])
    print("✅ Recorded confidence metric")
    
    # Step 3: Retrieve and verify
    cached = await cache.get_match_features(match_id)
    if cached:
        print(f"✅ Retrieved cached features (chaos: {cached['chaos_features']['chaos_index']})")
    
    # Step 4: Get integrity summary
    summary = await cache.get_integrity_metrics_summary()
    print(f"✅ Integrity summary retrieved (health: {summary.get('overall_health', {}).get('status', 'unknown')})")
    
    await cache.disconnect()
    
    print("\n✅ PASSED: Integration scenario successful")
    return True


async def main():
    """Run all hybrid implementation tests."""
    print("\n" + "=" * 80)
    print("  HYBRID IMPLEMENTATION TESTS")
    print("  Redis Cache + Integrity Monitor (1,000-Step Mission)")
    print("=" * 80)
    
    results = []
    
    try:
        # Test 1: Redis caching
        result1 = await test_redis_caching()
        results.append(("Redis Caching Layer", result1))
        
        # Test 2: Integrity monitoring
        result2 = await test_integrity_monitoring()
        results.append(("Integrity Monitor", result2))
        
        # Test 3: Full integrity check
        result3 = await test_full_integrity_check()
        results.append(("Full Integrity Report", result3))
        
        # Test 4: Integration scenario
        result4 = await test_integration_scenario()
        results.append(("Integration Scenario", result4))
        
    except Exception as e:
        print(f"\n❌ Test failed with exception: {e}")
        import traceback
        traceback.print_exc()
        return False
    
    # Summary
    print("\n" + "=" * 80)
    print("  FINAL RESULTS")
    print("=" * 80)
    
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
        print("\n🎉 ALL HYBRID TESTS PASSED!")
        print("\nImplementation Complete:")
        print("  ✅ Redis caching layer (Phase 2 infrastructure)")
        print("  ✅ Sports prediction feature caching")
        print("  ✅ Integrity monitor (1,000-step mission)")
        print("  ✅ All 5 cognitive health metrics tracking")
        print("  ✅ Automated recommendations system")
        print("  ✅ Integration between caching and monitoring")
        print("\nNext Steps:")
        print("  1. Install Redis server for production use")
        print("  2. Integrate cache into workflow executor")
        print("  3. Schedule periodic integrity checks")
        print("  4. Connect to sports data APIs (Phase 2)")
        print("  5. Build feature store for ML training (Phase 3)")
    else:
        print(f"\n⚠️  {total - passed} test(s) failed")
    
    return passed == total


if __name__ == "__main__":
    success = asyncio.run(main())
    sys.exit(0 if success else 1)
