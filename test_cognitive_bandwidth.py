"""
TEST SUITE FOR COGNITIVE BANDWIDTH MONITORING

Validates:
1. Communication event recording and tracking
2. Metric aggregation accuracy
3. Alert detection thresholds
4. Health report generation
5. Scalability monitoring (signal-to-noise ratio)
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from tiannara_core.monitoring.cognitive_bandwidth import (
    CognitiveBandwidthMonitor,
    CommunicationEvent,
    CommunicationType,
    BandwidthMetrics
)


def test_basic_communication_recording():
    """Test: Can record and track communication events?"""
    print("\n" + "="*70)
    print("TEST 1: Basic Communication Recording")
    print("="*70)
    
    monitor = CognitiveBandwidthMonitor(window_size_seconds=60.0)
    
    # Record several communication events
    events = [
        CommunicationEvent(
            event_id=f"evt_{i}",
            sender_id="agent_1",
            receiver_id="agent_2",
            comm_type=CommunicationType.USEFUL if i % 3 == 0 else CommunicationType.REDUNDANT,
            message_size=100 + i * 10,
            novelty_score=0.8 if i % 3 == 0 else 0.2,
            actionability=0.9 if i % 3 == 0 else 0.3,
            topic="task_allocation" if i % 2 == 0 else "data_sharing"
        )
        for i in range(10)
    ]
    
    for event in events:
        monitor.record_communication(event)
    
    # Verify tracking
    assert len(monitor.events) == 10, f"Expected 10 events, got {len(monitor.events)}"
    assert len(monitor.agent_activity) == 2, f"Expected 2 agents, got {len(monitor.agent_activity)}"
    
    print(f"   [PASS] Recorded {len(monitor.events)} communication events")
    print(f"   [PASS] Tracked {len(monitor.agent_activity)} active agents")
    print(f"   [PASS] Topic distribution: {len(monitor.topic_distribution)} topics")
    
    return True


def test_metric_aggregation():
    """Test: Does metric computation aggregate correctly?"""
    print("\n" + "="*70)
    print("TEST 2: Metric Aggregation Accuracy")
    print("="*70)
    
    monitor = CognitiveBandwidthMonitor(window_size_seconds=60.0)
    
    # Create controlled mix of communication types
    import time
    now = time.time()
    
    # 6 useful, 3 redundant, 1 contradictory
    comm_types = (
        [CommunicationType.USEFUL] * 6 +
        [CommunicationType.REDUNDANT] * 3 +
        [CommunicationType.CONTRADICTORY] * 1
    )
    
    for i, ctype in enumerate(comm_types):
        event = CommunicationEvent(
            event_id=f"evt_{i}",
            sender_id="agent_1",
            receiver_id="agent_2",
            comm_type=ctype,
            message_size=100,
            timestamp=now - 30 + i,  # All within window
            processing_time_ms=50.0 + i * 5
        )
        monitor.record_communication(event)
    
    # Compute metrics
    metrics = monitor.compute_metrics(window_start=now - 60, window_end=now)
    
    # Verify ratios
    expected_signal_ratio = 6 / 10  # 0.6
    expected_redundancy_ratio = 3 / 10  # 0.3
    expected_contradiction_ratio = 1 / 10  # 0.1
    
    assert abs(metrics.signal_ratio - expected_signal_ratio) < 0.01, \
        f"Signal ratio {metrics.signal_ratio} != {expected_signal_ratio}"
    assert abs(metrics.redundancy_ratio - expected_redundancy_ratio) < 0.01, \
        f"Redundancy ratio {metrics.redundancy_ratio} != {expected_redundancy_ratio}"
    assert abs(metrics.contradiction_ratio - expected_contradiction_ratio) < 0.01, \
        f"Contradiction ratio {metrics.contradiction_ratio} != {expected_contradiction_ratio}"
    
    print(f"   [PASS] Signal ratio: {metrics.signal_ratio:.2f} (expected {expected_signal_ratio:.2f})")
    print(f"   [PASS] Redundancy ratio: {metrics.redundancy_ratio:.2f} (expected {expected_redundancy_ratio:.2f})")
    print(f"   [PASS] Contradiction ratio: {metrics.contradiction_ratio:.2f} (expected {expected_contradiction_ratio:.2f})")
    print(f"   [PASS] Total messages: {metrics.total_messages}")
    print(f"   [PASS] Throughput: {metrics.throughput_msgs_per_sec:.2f} msgs/sec")
    
    return True


def test_alert_detection():
    """Test: Does alert system detect threshold violations?"""
    print("\n" + "="*70)
    print("TEST 3: Alert Detection")
    print("="*70)
    
    monitor = CognitiveBandwidthMonitor(window_size_seconds=60.0)
    
    # Test 1: Low signal quality alert
    low_signal_metrics = BandwidthMetrics(
        window_start=0,
        window_end=60,
        total_messages=100,
        signal_ratio=0.2,  # Below 0.3 threshold
        redundancy_ratio=0.5,  # Above 0.4 threshold
        contradiction_ratio=0.4,  # Above 0.3 threshold
        avg_latency_ms=1500.0,  # Above 1000ms threshold
        coordination_entropy=0.8  # Above 0.7 threshold
    )
    
    alerts = monitor.detect_alerts(low_signal_metrics)
    
    alert_types = [a['type'] for a in alerts]
    
    assert 'LOW_SIGNAL_QUALITY' in alert_types, "Missing LOW_SIGNAL_QUALITY alert"
    assert 'HIGH_REDUNDANCY' in alert_types, "Missing HIGH_REDUNDANCY alert"
    assert 'HIGH_CONTRADICTION' in alert_types, "Missing HIGH_CONTRADICTION alert"
    assert 'LATENCY_BOTTLENECK' in alert_types, "Missing LATENCY_BOTTLENECK alert"
    assert 'COORDINATION_FRAGMENTATION' in alert_types, "Missing COORDINATION_FRAGMENTATION alert"
    
    print(f"   [PASS] Detected {len(alerts)} alerts:")
    for alert in alerts:
        print(f"      - {alert['type']}: {alert['severity']}")
    
    # Test 2: Healthy metrics should have no alerts
    healthy_metrics = BandwidthMetrics(
        window_start=0,
        window_end=60,
        total_messages=100,
        signal_ratio=0.7,
        redundancy_ratio=0.1,
        contradiction_ratio=0.05,
        avg_latency_ms=100.0,
        coordination_entropy=0.3
    )
    
    healthy_alerts = monitor.detect_alerts(healthy_metrics)
    assert len(healthy_alerts) == 0, f"Expected 0 alerts for healthy metrics, got {len(healthy_alerts)}"
    
    print(f"   [PASS] Healthy metrics generate 0 alerts")
    
    return True


def test_health_report_generation():
    """Test: Does health report provide comprehensive assessment?"""
    print("\n" + "="*70)
    print("TEST 4: Health Report Generation")
    print("="*70)
    
    monitor = CognitiveBandwidthMonitor(window_size_seconds=60.0)
    
    # Record some events
    import time
    now = time.time()
    
    for i in range(20):
        event = CommunicationEvent(
            event_id=f"evt_{i}",
            sender_id=f"agent_{i % 5}",
            receiver_id=f"agent_{(i+1) % 5}",
            comm_type=CommunicationType.USEFUL if i % 4 == 0 else CommunicationType.COORDINATION,
            message_size=150,
            timestamp=now - 60 + i,
            processing_time_ms=80.0,
            topic="planning"
        )
        monitor.record_communication(event)
    
    # Compute metrics to populate history
    monitor.compute_metrics(window_start=now - 60, window_end=now)
    
    # Generate health report
    report = monitor.get_health_report()
    
    assert report['status'] in ['HEALTHY', 'WARNING', 'CRITICAL'], \
        f"Invalid status: {report['status']}"
    assert 'metrics' in report, "Report missing metrics"
    assert 'alerts' in report, "Report missing alerts"
    assert 'total_events_tracked' in report, "Report missing event count"
    
    print(f"   [PASS] Health report status: {report['status']}")
    print(f"   [PASS] Total events tracked: {report['total_events_tracked']}")
    print(f"   [PASS] Windows analyzed: {report['windows_analyzed']}")
    print(f"   [PASS] Active alerts: {report['alert_count']}")
    
    return True


def test_scalability_monitoring():
    """Test: Can monitor detect scalability issues at different agent counts?"""
    print("\n" + "="*70)
    print("TEST 5: Scalability Monitoring (5 vs 20 vs 50 Agents)")
    print("="*70)
    
    import time
    now = time.time()
    
    # Simulate 5-agent scenario (healthy)
    monitor_5 = CognitiveBandwidthMonitor()
    for i in range(50):
        event = CommunicationEvent(
            event_id=f"evt_5_{i}",
            sender_id=f"agent_{i % 5}",
            receiver_id=f"agent_{(i+1) % 5}",
            comm_type=CommunicationType.USEFUL,
            message_size=100,
            timestamp=now - 60 + i,
            processing_time_ms=50.0,
            novelty_score=0.8,
            topic="task_coordination"
        )
        monitor_5.record_communication(event)
    
    metrics_5 = monitor_5.compute_metrics(window_start=now - 60, window_end=now)
    
    # Simulate 50-agent scenario (potential overload)
    monitor_50 = CognitiveBandwidthMonitor()
    for i in range(500):
        event = CommunicationEvent(
            event_id=f"evt_50_{i}",
            sender_id=f"agent_{i % 50}",
            receiver_id=f"agent_{(i+1) % 50}",
            comm_type=CommunicationType.REDUNDANT if i % 3 == 0 else CommunicationType.USEFUL,
            message_size=120,
            timestamp=now - 60 + i * 0.1,
            processing_time_ms=200.0,  # Higher latency due to scale
            novelty_score=0.4,  # Lower novelty due to redundancy
            topic="coordination_overhead"
        )
        monitor_50.record_communication(event)
    
    metrics_50 = monitor_50.compute_metrics(window_start=now - 60, window_end=now)
    
    # Compare scenarios
    print(f"\n   5-Agent Scenario:")
    print(f"      Signal Ratio: {metrics_5.signal_ratio:.2f}")
    print(f"      Avg Latency: {metrics_5.avg_latency_ms:.0f}ms")
    print(f"      Coordination Entropy: {metrics_5.coordination_entropy:.2f}")
    
    print(f"\n   50-Agent Scenario:")
    print(f"      Signal Ratio: {metrics_50.signal_ratio:.2f}")
    print(f"      Avg Latency: {metrics_50.avg_latency_ms:.0f}ms")
    print(f"      Coordination Entropy: {metrics_50.coordination_entropy:.2f}")
    
    # Verify degradation is detected
    assert metrics_50.signal_ratio < metrics_5.signal_ratio or \
           metrics_50.avg_latency_ms > metrics_5.avg_latency_ms, \
           "Should detect degradation at scale"
    
    print(f"\n   [PASS] Scalability monitoring detects performance differences")
    print(f"   [PASS] 5-agent: {metrics_5.total_messages} messages, healthy")
    print(f"   [PASS] 50-agent: {metrics_50.total_messages} messages, higher load")
    
    return True


def run_all_tests():
    """Execute all bandwidth monitoring tests."""
    print("\n" + "="*70)
    print("COGNITIVE BANDWIDTH MONITORING TEST SUITE")
    print("="*70)
    
    tests = [
        ("Basic Communication Recording", test_basic_communication_recording),
        ("Metric Aggregation Accuracy", test_metric_aggregation),
        ("Alert Detection", test_alert_detection),
        ("Health Report Generation", test_health_report_generation),
        ("Scalability Monitoring", test_scalability_monitoring),
    ]
    
    results = []
    for name, test_func in tests:
        try:
            passed = test_func()
            results.append((name, passed))
        except Exception as e:
            print(f"\n   [FAIL] {name}: {str(e)}")
            results.append((name, False))
    
    # Summary
    print("\n" + "="*70)
    print("TEST SUMMARY")
    print("="*70)
    
    passed_count = sum(1 for _, passed in results if passed)
    total_count = len(results)
    
    for name, passed in results:
        status = "[PASS]" if passed else "[FAIL]"
        print(f"   {status} {name}")
    
    print(f"\n   Overall: {passed_count}/{total_count} tests passed")
    
    if passed_count == total_count:
        print("\n   [EXCELLENT] All bandwidth monitoring tests passed!")
    else:
        print(f"\n   [WARNING] {total_count - passed_count} test(s) failed")
    
    return passed_count == total_count


if __name__ == "__main__":
    success = run_all_tests()
    sys.exit(0 if success else 1)
