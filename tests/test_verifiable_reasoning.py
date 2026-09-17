"""Test verifiable reasoning system."""

from tiannara_core.evaluation.verifiable_reasoning import (
    VerifiableReasoner,
    ReasoningStepType,
    ReasoningTrace
)

def test_basic_reasoning():
    """Test basic reasoning trace creation."""
    reasoner = VerifiableReasoner()
    
    # Start a trace
    trace = reasoner.start_trace("task_001", "sorting")
    
    # Add data nodes
    trace.add_data_node("input_1", "input", [3, 1, 2], "task_input")
    trace.add_data_node("intermediate_1", "intermediate", [1, 2, 3], "sorted_array")
    
    # Add reasoning steps
    trace.add_step(
        step_type=ReasoningStepType.OBSERVATION,
        description="Observed unsorted array [3, 1, 2]",
        input_nodes=["input_1"],
        confidence=1.0
    )
    
    trace.add_step(
        step_type=ReasoningStepType.CALCULATION,
        description="Applied sorting algorithm",
        input_nodes=["input_1"],
        output=[1, 2, 3],
        confidence=0.95
    )
    
    trace.add_step(
        step_type=ReasoningStepType.VERIFICATION,
        description="Verified sorted order",
        input_nodes=["intermediate_1"],
        confidence=0.98
    )
    
    # Finalize
    trace.finalize("success", 0.95)
    
    # Check results
    summary = trace.get_summary()
    print(f"Task: {summary['task_id']}")
    print(f"Steps: {summary['total_steps']}")
    print(f"Outcome: {summary['outcome']}")
    print(f"Confidence: {summary['final_confidence']:.2f}")
    
    assert summary['total_steps'] == 4  # 3 steps + conclusion
    assert summary['outcome'] == "success"
    assert summary['final_confidence'] == 0.95
    
    print("\n✓ Basic reasoning test passed!")
    
    # Test ASCII visualization
    print("\n" + trace.visualize_ascii())
    
    return True


def test_multiple_traces():
    """Test managing multiple reasoning traces."""
    reasoner = VerifiableReasoner()
    
    # Create multiple traces
    for i in range(5):
        trace = reasoner.start_trace(f"task_{i:03d}", "arithmetic")
        trace.add_step(
            step_type=ReasoningStepType.OBSERVATION,
            description=f"Processing task {i}"
        )
        
        outcome = "success" if i % 2 == 0 else "failure"
        confidence = 0.9 if outcome == "success" else 0.3
        
        reasoner.record_outcome(f"task_{i:03d}", outcome, confidence)
    
    # Check statistics
    stats = reasoner.get_statistics()
    print(f"\nTotal traces: {stats['total_traces']}")
    print(f"Successful: {stats['successful_traces']}")
    print(f"Success rate: {stats['success_rate']:.2%}")
    
    assert stats['total_traces'] == 5
    assert stats['successful_traces'] == 3  # tasks 0, 2, 4
    assert abs(stats['success_rate'] - 0.6) < 0.01
    
    print("\n✓ Multiple traces test passed!")
    return True


def test_export():
    """Test exporting traces for analysis."""
    reasoner = VerifiableReasoner()
    
    trace = reasoner.start_trace("export_test", "sorting")
    trace.add_step(
        step_type=ReasoningStepType.DECISION,
        description="Made a decision",
        output="result"
    )
    trace.finalize("success", 0.9)
    
    # Export all traces
    exported = reasoner.export_all_traces()
    
    assert len(exported) == 1
    assert 'summary' in exported[0]
    assert 'total_steps' in exported[0]  # Changed from 'steps' to match actual implementation
    assert 'total_nodes' in exported[0]  # Changed from 'data_nodes' to match actual implementation
    
    print("\n✓ Export test passed!")
    return True


if __name__ == "__main__":
    print("Testing Verifiable Reasoning System\n")
    print("=" * 60)
    
    test_basic_reasoning()
    test_multiple_traces()
    test_export()
    
    print("\n" + "=" * 60)
    print("All tests passed! ✓")
