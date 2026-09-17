"""Test multi-agent autonomy system."""

from tiannara_core.evaluation.multi_agent_autonomy import (
    AgentOrchestrator,
    SubAgent,
    AgentTask,
    AgentRole,
    TaskDecomposer
)


def test_agent_creation():
    """Test creating agents with different roles."""
    orchestrator = AgentOrchestrator(max_workers=4)
    
    # Check default agents were spawned
    assert len(orchestrator.agents) >= 4, "Should have default agents"
    
    # Spawn a custom agent
    agent_id = orchestrator.spawn_agent(
        role=AgentRole.PLANNER,
        capabilities=["planning", "decomposition"]
    )
    
    assert agent_id in orchestrator.agents
    assert orchestrator.agents[agent_id].role == AgentRole.PLANNER
    
    print("✓ Agent creation test passed!")
    return True


def test_task_execution():
    """Test executing a task with an agent."""
    orchestrator = AgentOrchestrator(max_workers=2)
    
    # Create a simple task
    task = AgentTask(
        task_id="test_001",
        description="Sort an array",
        task_type="sorting",
        inputs={"array": [3, 1, 2]}
    )
    
    # Define executor function
    def sort_executor(inputs):
        return sorted(inputs["array"])
    
    # Execute task
    result = orchestrator.submit_and_execute(task, sort_executor)
    
    assert result.success, "Task should succeed"
    assert result.output == [1, 2, 3], "Output should be sorted"
    assert result.agent_id != "none", "Should have an assigned agent"
    
    print(f"✓ Task execution test passed! (Agent: {result.agent_id})")
    return True


def test_parallel_execution():
    """Test executing multiple tasks in parallel."""
    orchestrator = AgentOrchestrator(max_workers=4)
    
    # Create multiple tasks
    tasks = [
        AgentTask(
            task_id=f"parallel_{i}",
            description=f"Task {i}",
            task_type="arithmetic",
            inputs={"value": i * 10}
        )
        for i in range(5)
    ]
    
    # Define executor
    def arithmetic_executor(inputs):
        return inputs["value"] * 2
    
    # Execute in parallel
    results = orchestrator.execute_parallel(tasks, arithmetic_executor)
    
    assert len(results) == 5, "Should have 5 results"
    assert all(r.success for r in results), "All tasks should succeed"
    
    print(f"✓ Parallel execution test passed! ({len(results)} tasks)")
    return True


def test_agent_selection():
    """Test that orchestrator selects appropriate agents."""
    orchestrator = AgentOrchestrator(max_workers=2)
    
    # Create tasks for different domains
    sorting_task = AgentTask(
        task_id="sort_test",
        description="Sort test",
        task_type="sorting",
        inputs={"array": [3, 1, 2]}
    )
    
    logic_task = AgentTask(
        task_id="logic_test",
        description="Logic test",
        task_type="pattern_recognition",
        inputs={"pattern": [1, 2, 3]}
    )
    
    def dummy_executor(inputs):
        return "result"
    
    # Execute both tasks
    result1 = orchestrator.submit_and_execute(sorting_task, dummy_executor)
    result2 = orchestrator.submit_and_execute(logic_task, dummy_executor)
    
    # Different agents should handle different task types
    assert result1.success and result2.success
    
    print("✓ Agent selection test passed!")
    return True


def test_task_decomposition():
    """Test decomposing complex tasks."""
    decomposer = TaskDecomposer()
    
    # Register a decomposition rule
    def decompose_multi_domain(task):
        domains = task.metadata.get("domains", [])
        sub_tasks = []
        for i, domain in enumerate(domains):
            sub_task = AgentTask(
                task_id=f"{task.task_id}_sub_{i}",
                description=f"{domain} component",
                task_type=domain,
                inputs=task.inputs.copy(),
                metadata={"parent": task.task_id}
            )
            sub_tasks.append(sub_task)
        return sub_tasks
    
    decomposer.register_rule("multi_domain", decompose_multi_domain)
    
    # Create a multi-domain task
    task = AgentTask(
        task_id="complex_001",
        description="Multi-domain task",
        task_type="multi_domain",
        inputs={"data": "test"},
        metadata={"domains": ["sorting", "arithmetic"]}
    )
    
    # Decompose
    sub_tasks = decomposer.decompose(task)
    
    assert len(sub_tasks) == 2, "Should decompose into 2 sub-tasks"
    assert sub_tasks[0].task_type == "sorting"
    assert sub_tasks[1].task_type == "arithmetic"
    
    print("✓ Task decomposition test passed!")
    return True


def test_agent_statistics():
    """Test collecting agent statistics."""
    orchestrator = AgentOrchestrator(max_workers=2)
    
    # Execute some tasks
    for i in range(3):
        task = AgentTask(
            task_id=f"stats_test_{i}",
            description=f"Stats test {i}",
            task_type="sorting",
            inputs={"array": [3, 1, 2]}
        )
        
        def sort_exec(inputs):
            return sorted(inputs["array"])
        
        orchestrator.submit_and_execute(task, sort_exec)
    
    # Get stats
    agent_stats = orchestrator.get_agent_stats()
    overall_stats = orchestrator.get_overall_stats()
    
    assert len(agent_stats) > 0, "Should have agent stats"
    assert overall_stats["total_tasks_completed"] == 3
    assert overall_stats["success_rate"] == 1.0
    
    print(f"✓ Agent statistics test passed!")
    print(f"  Total tasks: {overall_stats['total_tasks_completed']}")
    print(f"  Success rate: {overall_stats['success_rate']:.0%}")
    
    return True


def test_error_handling():
    """Test handling of task failures."""
    orchestrator = AgentOrchestrator(max_workers=2)
    
    task = AgentTask(
        task_id="error_test",
        description="Task that will fail",
        task_type="sorting",
        inputs={"array": [3, 1, 2]}
    )
    
    def failing_executor(inputs):
        raise ValueError("Intentional failure")
    
    result = orchestrator.submit_and_execute(task, failing_executor)
    
    assert not result.success, "Task should fail"
    assert result.error is not None, "Should have error message"
    
    print("✓ Error handling test passed!")
    return True


if __name__ == "__main__":
    print("Testing Multi-Agent Autonomy System\n")
    print("=" * 60)
    
    test_agent_creation()
    test_task_execution()
    test_parallel_execution()
    test_agent_selection()
    test_task_decomposition()
    test_agent_statistics()
    test_error_handling()
    
    print("\n" + "=" * 60)
    print("All tests passed! ✓")
