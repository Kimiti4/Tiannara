"""
Causal Path Tracer Test Script

Demonstrates causal path tracing and explanation generation
for Executable Causal Manifolds.

Usage:
    python tiannara_core/interpretability/test_causal_path_tracer.py
"""

import sys
from pathlib import Path
import numpy as np

# Add project root to path
project_root = Path(__file__).parent.parent.parent
sys.path.insert(0, str(project_root))

try:
    from tiannara_core.interpretability.causal_path_tracer import (
        CausalPathTracer,
        trace_causal_path
    )
    TRACER_AVAILABLE = True
except ImportError as e:
    print(f"WARNING: Interpretability module not available: {e}")
    TRACER_AVAILABLE = False


def create_sample_ecm_graph():
    """Create a sample ECM graph for testing."""
    # Simulated causal structure:
    # skill_memory -> pattern_recognition -> solution_quality
    #                      ↓
    # cross_domain_transfer -> adaptation_speed
    #                            ↓
    #                       final_outcome
    
    graph = {
        'nodes': [
            'skill_memory',
            'pattern_recognition', 
            'cross_domain_transfer',
            'solution_quality',
            'adaptation_speed',
            'final_outcome'
        ],
        'edges': [
            ('skill_memory', 'pattern_recognition', 0.8),
            ('skill_memory', 'cross_domain_transfer', 0.6),
            ('pattern_recognition', 'solution_quality', 0.9),
            ('cross_domain_transfer', 'adaptation_speed', 0.7),
            ('solution_quality', 'final_outcome', 0.85),
            ('adaptation_speed', 'final_outcome', 0.75)
        ],
        'parameters': {
            'learning_rate': 0.01,
            'exploration_factor': 0.3
        }
    }
    
    return graph


def test_basic_path_tracing():
    """Test basic causal path extraction."""
    print("=" * 80)
    print("Basic Causal Path Tracing Test")
    print("=" * 80)
    
    # Create graph
    print("\n1. Creating sample ECM graph...")
    graph = create_sample_ecm_graph()
    print(f"   Nodes: {len(graph['nodes'])}")
    print(f"   Edges: {len(graph['edges'])}")
    
    # Initialize tracer
    print("\n2. Initializing CausalPathTracer...")
    tracer = CausalPathTracer(max_path_length=8)
    tracer.set_graph_snapshot(graph)
    
    # Extract paths to final_outcome
    print("\n3. Extracting causal paths to 'final_outcome'...")
    paths = tracer.extract_path(target='final_outcome', top_k=5)
    
    print(f"\n4. Found {len(paths)} causal paths:")
    print("-" * 80)
    
    for i, path in enumerate(paths, 1):
        print(f"\nPath {i}:")
        print(f"   {path}")
        print(f"   Attribution scores:")
        for node, score in sorted(path.attribution_scores.items(), key=lambda x: x[1], reverse=True):
            print(f"      {node}: {score:.3f}")
    
    print("\n" + "=" * 80)
    print("Basic Path Tracing Test Completed!")
    print("=" * 80)


def test_intervention_tracking():
    """Test intervention tracking and explanation generation."""
    print("\n" + "=" * 80)
    print("Intervention Tracking Test")
    print("=" * 80)
    
    graph = create_sample_ecm_graph()
    tracer = CausalPathTracer()
    tracer.set_graph_snapshot(graph)
    
    # Start tracking interventions
    print("\n1. Starting intervention tracking...")
    tracer.start_tracking()
    
    # Simulate interventions
    print("\n2. Applying interventions...")
    tracer.record_intervention('skill_memory', 'do', value=0.9, previous_value=0.5, confidence=0.95)
    tracer.record_observation('pattern_recognition', value=0.85, context={'triggered_by': 'skill_memory'})
    tracer.record_intervention('cross_domain_transfer', 'soft_intervention', value=0.7, confidence=0.8)
    tracer.record_observation('adaptation_speed', value=0.75)
    tracer.record_observation('final_outcome', value=0.88)
    
    tracer.stop_tracking()
    
    # Get tracking summary
    print("\n3. Tracking Summary:")
    print("-" * 80)
    summary = tracer.get_tracking_summary()
    for key, value in summary.items():
        print(f"   {key}: {value}")
    
    # Extract and explain paths
    print("\n4. Extracting paths with explanations...")
    paths = tracer.extract_path(target='final_outcome', top_k=3)
    
    if paths:
        best_path = paths[0]
        explanation = tracer.generate_explanation(best_path)
        
        print(f"\n5. Path Explanation:")
        print("-" * 80)
        print(explanation.summary())
        
        # Generate visualization
        print(f"\n6. Mermaid Visualization:")
        print("-" * 80)
        viz = tracer.generate_mermaid_viz(best_path)
        print(viz)
    
    print("\n" + "=" * 80)
    print("Intervention Tracking Test Completed!")
    print("=" * 80)


def test_convenience_function():
    """Test convenience function for quick path tracing."""
    print("\n" + "=" * 80)
    print("Convenience Function Test")
    print("=" * 80)
    
    graph = create_sample_ecm_graph()
    
    print("\nRunning trace_causal_path()...")
    
    interventions = [
        {'node': 'skill_memory', 'type': 'do', 'value': 0.9},
        {'node': 'cross_domain_transfer', 'type': 'do', 'value': 0.7}
    ]
    
    paths = trace_causal_path(
        graph_data=graph,
        target='final_outcome',
        source='skill_memory',
        interventions=interventions
    )
    
    print(f"\nFound {len(paths)} paths from 'skill_memory' to 'final_outcome'")
    
    for i, path in enumerate(paths, 1):
        print(f"\nPath {i}: {path}")
    
    print("\nConvenience function test passed!")


def test_complex_graph():
    """Test with more complex causal structure."""
    print("\n" + "=" * 80)
    print("Complex Graph Test")
    print("=" * 80)
    
    # Create more complex graph with multiple pathways
    complex_graph = {
        'nodes': [
            'input_data',
            'feature_extraction',
            'model_selection',
            'hyperparameter_tuning',
            'training',
            'validation',
            'test_evaluation',
            'deployment_readiness'
        ],
        'edges': [
            ('input_data', 'feature_extraction', 0.9),
            ('feature_extraction', 'model_selection', 0.85),
            ('feature_extraction', 'hyperparameter_tuning', 0.7),
            ('model_selection', 'training', 0.9),
            ('hyperparameter_tuning', 'training', 0.8),
            ('training', 'validation', 0.95),
            ('validation', 'test_evaluation', 0.9),
            ('test_evaluation', 'deployment_readiness', 0.85),
            ('validation', 'deployment_readiness', 0.6)  # Shortcut path
        ]
    }
    
    tracer = CausalPathTracer(max_path_length=10)
    tracer.set_graph_snapshot(complex_graph)
    
    print("\nExtracting all paths to 'deployment_readiness'...")
    paths = tracer.extract_path(target='deployment_readiness', top_k=5)
    
    print(f"\nFound {len(paths)} paths:")
    print("-" * 80)
    
    for i, path in enumerate(paths, 1):
        print(f"\n{i}. {path}")
        print(f"   Length: {path.path_length} nodes")
        print(f"   Confidence: {path.confidence:.2f}")
    
    print("\n" + "=" * 80)
    print("Complex Graph Test Completed!")
    print("=" * 80)


if __name__ == "__main__":
    if not TRACER_AVAILABLE:
        print("WARNING: Cannot run tests - Interpretability module not available")
        sys.exit(1)
    
    try:
        test_basic_path_tracing()
        test_intervention_tracking()
        test_convenience_function()
        test_complex_graph()
        
        print("\n" + "=" * 80)
        print("ALL TESTS PASSED!")
        print("=" * 80)
        
    except Exception as e:
        print(f"\nERROR: Test failed with error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
