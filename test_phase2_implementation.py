"""
Test Phase 2 Implementation: Sports API + Enhanced Integrity Monitor

Validates:
1. Sports API client initialization and data fetching
2. Integrity monitor auto-remediation capabilities
3. Integration between caching, sports data, and system health
"""

import sys
from pathlib import Path
from datetime import datetime, timedelta
import asyncio

sys.path.insert(0, str(Path(__file__).parent))

from tiannara_core.data.sports_api import SportsAPIClient
from tiannara_core.integrity.monitor import IntegrityMonitor
from tiannara_core.cache.redis_cache import cache


async def test_sports_api_initialization():
    """Test 1: Sports API client initialization."""
    print("=" * 80)
    print("  TEST 1: Sports API Client Initialization")
    print("=" * 80)
    
    # Initialize without API keys (demo mode)
    client = SportsAPIClient()
    
    print("\n✅ Sports API client created successfully")
    print(f"   Providers configured: {list(client.providers.keys())}")
    print(f"   Rate limits: API-Football={client.providers['api_football']['rate_limit']}/min, SportRadar={client.providers['sportradar']['rate_limit']}/min")
    
    # Test normalization functions
    print("\n📊 Testing data normalization...")
    
    # Simulate live match data
    raw_live_data = [
        {
            "statistics": [
                {"type": "Total Shots", "value": "14"},
                {"type": "Shots on Goal", "value": "7"},
                {"type": "Dangerous Attacks", "value": "18"},
                {"type": "Ball Possession", "value": "62"}
            ]
        },
        {
            "statistics": [
                {"type": "Total Shots", "value": "8"},
                {"type": "Shots on Goal", "value": "3"},
                {"type": "Dangerous Attacks", "value": "10"},
                {"type": "Ball Possession", "value": "38"}
            ]
        }
    ]
    
    normalized = client._normalize_live_data(raw_live_data)
    
    print(f"   Normalized live data:")
    print(f"     Home shots: {normalized.get('shots_home')}")
    print(f"     Away shots: {normalized.get('shots_away')}")
    print(f"     Home possession: {normalized.get('possession_home')}%")
    print(f"     Dangerous attacks: H{normalized.get('dangerous_attacks_home')}-A{normalized.get('dangerous_attacks_away')}")
    
    assert normalized['shots_home'] == 14, "Home shots mismatch"
    assert normalized['shots_away'] == 8, "Away shots mismatch"
    assert normalized['possession_home'] == 62, "Possession mismatch"
    
    print("\n✅ PASSED: Sports API client initialized and normalization works")
    return True


async def test_integrity_auto_remediation():
    """Test 2: Integrity monitor auto-remediation."""
    print("\n" + "=" * 80)
    print("  TEST 2: Integrity Auto-Remediation")
    print("=" * 80)
    
    monitor = IntegrityMonitor()
    
    # Simulate critical integrity report
    print("\n🚨 Simulating CRITICAL integrity issues...")
    
    critical_report = {
        'metrics': {
            'identity_drift': {'value': 0.75, 'status': 'critical'},
            'causal_degradation': {'value': 0.45, 'status': 'warning'},
            'memory_corruption': {'value': 0.65, 'status': 'critical'},
            'confidence_inflation': {'value': 0.80, 'status': 'critical'},
            'contradiction_accumulation': {'value': 0.35, 'status': 'warning'}
        },
        'recommendations': [
            {
                'metric': 'identity_drift',
                'priority': 'high',
                'action': 'Review constitutional constraints',
                'details': 'Significant drift detected'
            },
            {
                'metric': 'memory_corruption',
                'priority': 'high',
                'action': 'Run memory integrity scan',
                'details': 'Corruption exceeds threshold'
            },
            {
                'metric': 'confidence_inflation',
                'priority': 'medium',
                'action': 'Recalibrate confidence scoring',
                'details': 'Overconfidence detected'
            }
        ]
    }
    
    # Trigger auto-remediation
    result = await monitor.auto_remediate(critical_report)
    
    print(f"\n🔧 Auto-remediation actions taken:")
    for action in result['actions_taken']:
        print(f"   • {action['action']}: {action['status']}")
        print(f"     Reason: {action['reason']}")
    
    assert len(result['actions_taken']) >= 3, "Expected at least 3 remediation actions"
    assert any(a['action'] == 'reset_confidence_calibration' for a in result['actions_taken']), "Confidence reset missing"
    assert any(a['action'] == 'trigger_memory_consolidation' for a in result['actions_taken']), "Memory consolidation missing"
    assert any(a['action'] == 'flag_human_review' for a in result['actions_taken']), "Human review flag missing"
    
    print(f"\n✅ PASSED: Auto-remediation executed {len(result['actions_taken'])} actions")
    return True


async def test_high_risk_scheduling():
    """Test 3: High-risk maintenance scheduling."""
    print("\n" + "=" * 80)
    print("  TEST 3: High-Risk Maintenance Scheduling")
    print("=" * 80)
    
    monitor = IntegrityMonitor()
    
    # Simulate high-risk (non-critical) report
    print("\n⚠️  Simulating HIGH RISK issues...")
    
    high_risk_report = {
        'metrics': {
            'identity_drift': {'value': 0.55, 'status': 'warning'},
            'causal_degradation': {'value': 0.65, 'status': 'warning'},
            'memory_corruption': {'value': 0.30, 'status': 'normal'},
            'confidence_inflation': {'value': 0.40, 'status': 'normal'},
            'contradiction_accumulation': {'value': 0.25, 'status': 'normal'}
        },
        'recommendations': [
            {
                'metric': 'identity_drift',
                'priority': 'high',
                'action': 'Queue identity alignment check',
                'details': 'Moderate drift detected'
            },
            {
                'metric': 'causal_degradation',
                'priority': 'high',
                'action': 'Schedule causal graph rebuild',
                'details': 'Causal quality declining'
            }
        ]
    }
    
    # Trigger auto-remediation
    result = await monitor.auto_remediate(high_risk_report)
    
    print(f"\n📅 Scheduled maintenance tasks:")
    for action in result['actions_taken']:
        print(f"   • {action['action']}: {action['status']}")
    
    assert len(result['actions_taken']) >= 2, "Expected at least 2 scheduled tasks"
    assert any(a['action'] == 'queue_identity_alignment' for a in result['actions_taken']), "Identity alignment not queued"
    assert any(a['action'] == 'schedule_causal_rebuild' for a in result['actions_taken']), "Causal rebuild not scheduled"
    
    print(f"\n✅ PASSED: Maintenance tasks scheduled correctly")
    return True


async def test_medium_risk_monitoring():
    """Test 4: Medium-risk enhanced monitoring."""
    print("\n" + "=" * 80)
    print("  TEST 4: Medium-Risk Enhanced Monitoring")
    print("=" * 80)
    
    monitor = IntegrityMonitor()
    
    # Simulate medium-risk report
    print("\n📊 Simulating MEDIUM RISK issues...")
    
    medium_risk_report = {
        'metrics': {
            'identity_drift': {'value': 0.25, 'status': 'normal'},
            'causal_degradation': {'value': 0.35, 'status': 'normal'},
            'memory_corruption': {'value': 0.20, 'status': 'normal'},
            'confidence_inflation': {'value': 0.55, 'status': 'warning'},
            'contradiction_accumulation': {'value': 0.45, 'status': 'warning'}
        },
        'recommendations': [
            {
                'metric': 'confidence_inflation',
                'priority': 'medium',
                'action': 'Recalibrate confidence',
                'details': 'Slight overconfidence'
            },
            {
                'metric': 'contradiction_accumulation',
                'priority': 'medium',
                'action': 'Resolve contradictions',
                'details': 'Minor inconsistencies'
            }
        ]
    }
    
    # Trigger auto-remediation
    result = await monitor.auto_remediate(medium_risk_report)
    
    print(f"\n👁️  Enhanced monitoring activated:")
    for action in result['actions_taken']:
        print(f"   • {action['action']}: {action['status']}")
    
    assert len(result['actions_taken']) >= 1, "Expected at least 1 monitoring action"
    assert any(a['action'] == 'enable_enhanced_monitoring' for a in result['actions_taken']), "Enhanced monitoring not enabled"
    
    print(f"\n✅ PASSED: Enhanced monitoring enabled")
    return True


async def test_integration_workflow():
    """Test 5: Full integration workflow - sports prediction with integrity check."""
    print("\n" + "=" * 80)
    print("  TEST 5: Integration Workflow - Sports Prediction + Integrity")
    print("=" * 80)
    
    print("\n🔄 Running integrated workflow...")
    
    # Step 1: Cache match features (simulating real-time data)
    print("\n1️⃣  Caching live match features...")
    match_features = {
        'momentum_features': {'momentum_diff': 0.35},
        'chaos_features': {'chaos_index': 0.45},
        'timestamp': datetime.now().isoformat()
    }
    
    await cache.cache_match_features("test_match_456", match_features)
    cached = await cache.get_match_features("test_match_456")
    
    assert cached is not None, "Failed to cache match features"
    print(f"   ✅ Match features cached: momentum_diff={cached['momentum_features']['momentum_diff']}")
    
    # Step 2: Run integrity check after processing
    print("\n2️⃣  Running integrity check...")
    monitor = IntegrityMonitor()
    
    # Simulate system state with some predictions
    system_state = {
        'constitution_violations': [],
        'recent_decisions': [
            {'prediction': 'home_win', 'confidence': 0.85, 'correct': True},
            {'prediction': 'draw', 'confidence': 0.90, 'correct': False},
            {'prediction': 'away_win', 'confidence': 0.75, 'correct': True}
        ],
        'memory_samples': [
            {'id': 'mem1', 'timestamp': '2024-01-01T00:00:00', 'data': 'valid'},
            {'id': 'mem2', 'timestamp': '2024-01-02T00:00:00', 'data': 'valid'}
        ],
        'predictions': [
            {'confidence': 0.85, 'correct': True},
            {'confidence': 0.90, 'correct': False},
            {'confidence': 0.75, 'correct': True}
        ],
        'knowledge_base': [
            {'fact': 'Team A wins at home', 'source': 'historical'},
            {'fact': 'Team B struggles away', 'source': 'stats'}
        ]
    }
    
    report = await monitor.run_full_integrity_check(system_state)
    
    print(f"   ✅ Integrity check completed in {report['check_duration_seconds']}s")
    print(f"   Overall health: {report['overall_health'].get('status', 'unknown')}")
    
    # Step 3: Auto-remediate if needed
    if report.get('action_required'):
        print(f"\n3️⃣  Action required - running auto-remediation...")
        remediation = await monitor.auto_remediate(report)
        print(f"   🔧 Executed {len(remediation['actions_taken'])} remediation actions")
    else:
        print(f"\n3️⃣  No action required - system healthy ✅")
    
    print(f"\n✅ PASSED: Integration workflow completed successfully")
    return True


async def main():
    """Run all tests."""
    print("\n" + "=" * 80)
    print("  PHASE 2 IMPLEMENTATION TEST SUITE")
    print("  Sports API + Enhanced Integrity Monitoring")
    print("=" * 80)
    
    # Connect to cache
    await cache.connect()
    
    results = []
    
    try:
        # Test 1: Sports API
        result1 = await test_sports_api_initialization()
        results.append(("Sports API Initialization", result1))
        
        # Test 2: Critical auto-remediation
        result2 = await test_integrity_auto_remediation()
        results.append(("Critical Auto-Remediation", result2))
        
        # Test 3: High-risk scheduling
        result3 = await test_high_risk_scheduling()
        results.append(("High-Risk Scheduling", result3))
        
        # Test 4: Medium-risk monitoring
        result4 = await test_medium_risk_monitoring()
        results.append(("Medium-Risk Monitoring", result4))
        
        # Test 5: Integration workflow
        result5 = await test_integration_workflow()
        results.append(("Integration Workflow", result5))
        
    except Exception as e:
        print(f"\n❌ Test failed with error: {e}")
        import traceback
        traceback.print_exc()
        results.append(("Error", False))
    
    # Summary
    print("\n" + "=" * 80)
    print("  TEST SUMMARY")
    print("=" * 80)
    
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for name, result in results:
        status = "✅ PASSED" if result else "❌ FAILED"
        print(f"{status}: {name}")
    
    print(f"\nTotal: {passed}/{total} passed ({passed/total*100:.0f}%)")
    
    if passed == total:
        print("\n🎉 All Phase 2 tests passed!")
        print("\nNext Steps:")
        print("  • Configure API keys for production sports data")
        print("  • Set up WebSocket listeners for real-time updates")
        print("  • Implement feature store for historical ML training")
        print("  • Deploy Redis cluster for production caching")
    else:
        print(f"\n⚠️  {total - passed} test(s) failed - review errors above")
    
    await cache.disconnect()
    return passed == total


if __name__ == "__main__":
    success = asyncio.run(main())
    sys.exit(0 if success else 1)
