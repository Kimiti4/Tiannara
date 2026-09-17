"""
Stagnation Detector Test Script

Demonstrates stagnation detection capabilities with synthetic data.
Shows how the detector identifies plateaus and provides recovery recommendations.

Usage:
    python tiannara_core/autonomy/test_stagnation_detector.py
"""

import sys
from pathlib import Path
import numpy as np

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

from tiannara_core.autonomy.stagnation_detector import (
    StagnationDetector, 
    StagnationSeverity,
    check_stagnation
)


def simulate_learning_curve(num_episodes=200):
    """
    Simulate a learning curve with distinct phases:
    1. Rapid improvement (episodes 0-50)
    2. Plateau/stagnation (episodes 50-120)
    3. Recovery and continued learning (episodes 120-200)
    """
    performances = []
    
    for episode in range(num_episodes):
        if episode < 50:
            # Phase 1: Rapid improvement
            base = 0.3 + (0.4 * (episode / 50))
            noise = np.random.normal(0, 0.03)
        elif episode < 120:
            # Phase 2: Plateau with slight decline
            base = 0.70 - (0.001 * (episode - 50))
            noise = np.random.normal(0, 0.02)
        else:
            # Phase 3: Recovery and continued learning
            base = 0.65 + (0.25 * ((episode - 120) / 80))
            noise = np.random.normal(0, 0.025)
        
        performance = np.clip(base + noise, 0.0, 1.0)
        performances.append(performance)
    
    return performances


def test_stagnation_detection():
    """Test stagnation detector with simulated learning curve."""
    
    print("=" * 80)
    print("Tiannara Stagnation Detector - Test & Demo")
    print("=" * 80)
    print()
    
    # Initialize detector
    db_path = project_root / "test_stagnation_events.db"
    detector = StagnationDetector(
        window_size=50,
        threshold=0.01,
        min_episodes=20,
        db_path=str(db_path)
    )
    
    print("📊 Simulating 200-episode learning curve...")
    print("   Phase 1: Episodes 0-50   (Rapid improvement)")
    print("   Phase 2: Episodes 50-120 (Plateau/stagnation)")
    print("   Phase 3: Episodes 120-200 (Recovery)")
    print()
    
    # Generate synthetic learning curve
    performances = simulate_learning_curve(200)
    
    # Track stagnation events
    stagnation_events = []
    phase_labels = {
        (0, 50): "Phase 1: Improvement",
        (50, 120): "Phase 2: Plateau",
        (120, 200): "Phase 3: Recovery"
    }
    
    # Process each episode
    for episode in range(200):
        success_rate = performances[episode]
        
        # Record episode
        detector.record_episode(episode, success_rate)
        
        # Check for stagnation every 10 episodes
        if episode % 10 == 0 and episode >= 20:
            result = check_stagnation(detector, episode, success_rate, auto_log=True)
            
            if result['stagnant']:
                stagnation_events.append({
                    'episode': episode,
                    'severity': result['severity'],
                    'performance': success_rate
                })
                
                # Print stagnation alert
                current_phase = None
                for (start, end), label in phase_labels.items():
                    if start <= episode < end:
                        current_phase = label
                        break
                
                print(f"\n{'='*80}")
                print(f"⚠️  STAGNATION DETECTED - Episode {episode}")
                print(f"{'='*80}")
                print(f"Current Phase: {current_phase}")
                print(f"Severity: {result['severity'].upper()}")
                print(f"Performance: {success_rate:.3f}")
                print(f"Peak Performance: {detector.peak_performance:.3f}")
                print()
                print("Recommendations:")
                for i, rec in enumerate(result['recommendations'], 1):
                    print(f"  {i}. {rec}")
                print()
    
    # Summary statistics
    print("\n" + "=" * 80)
    print("📈 LEARNING CURVE ANALYSIS")
    print("=" * 80)
    
    stats = detector.get_learning_curve_stats()
    print(f"\nOverall Statistics:")
    print(f"  Episodes analyzed: {stats.episodes_analyzed}")
    print(f"  Mean performance: {stats.mean_performance:.3f}")
    print(f"  Std deviation: {stats.std_performance:.3f}")
    print(f"  Trend slope: {stats.trend_slope:.4f}")
    print(f"  Volatility: {stats.volatility:.3f}")
    print()
    
    # Stagnation summary
    print(f"📉 STAGNATION SUMMARY")
    print(f"{'='*80}")
    print(f"Total stagnation events detected: {len(stagnation_events)}")
    
    if stagnation_events:
        severity_counts = {}
        for event in stagnation_events:
            sev = event['severity']
            severity_counts[sev] = severity_counts.get(sev, 0) + 1
        
        print(f"\nSeverity breakdown:")
        for severity, count in sorted(severity_counts.items()):
            print(f"  {severity}: {count} events")
        
        print(f"\nFirst stagnation detected at episode: {stagnation_events[0]['episode']}")
        print(f"Last stagnation detected at episode: {stagnation_events[-1]['episode']}")
        
        # Show when stagnation cleared
        print(f"\nStagnation timeline:")
        for event in stagnation_events[:5]:  # Show first 5
            print(f"  Episode {event['episode']:3d}: {event['severity']:10s} "
                  f"(performance: {event['performance']:.3f})")
        
        if len(stagnation_events) > 5:
            print(f"  ... and {len(stagnation_events) - 5} more events")
    
    print()
    
    # Final status
    final_stagnant = detector.is_stagnant()
    final_severity = detector.get_severity()
    
    print(f"🎯 FINAL STATUS (Episode 199)")
    print(f"{'='*80}")
    print(f"Currently stagnant: {'YES ⚠️' if final_stagnant else 'NO ✅'}")
    print(f"Severity: {final_severity.value}")
    print(f"Final performance: {performances[-1]:.3f}")
    print(f"Peak performance: {detector.peak_performance:.3f} (episode {detector.peak_episode})")
    print()
    
    if not final_stagnant:
        print("✅ System successfully recovered from stagnation!")
    else:
        print("⚠️  System still stagnant - interventions needed")
        print("\nRecommended actions:")
        for rec in detector.get_recovery_recommendations():
            print(f"  • {rec}")
    
    print()
    print(f"📝 Stagnation events logged to: {db_path}")
    print()
    
    # Clean up test database
    if db_path.exists():
        db_path.unlink()
        print(f"🗑️  Test database cleaned up")
    
    print()
    print("=" * 80)
    print("Test complete!")
    print("=" * 80)


if __name__ == "__main__":
    test_stagnation_detection()
