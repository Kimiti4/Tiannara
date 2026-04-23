from tiannara_core.autonomous.orchestrator import Orchestrator
from tiannara_core.distributed.manager import run_distributed
from tiannara_core.evolution.graph_genome import GraphGenome


def test_graph_genome_forward_runs():
    genome = GraphGenome(size=5)
    output = genome.forward([0.1, 0.2, 0.3, 0.4, 0.5])
    assert len(output) == 5


def test_run_distributed_returns_sorted_results():
    results = run_distributed(
        [
            {
                "worker_id": 1,
                "question": "Optimize prosthetic grip stability",
                "population_size": 8,
                "generations": 3,
                "mutation_rate": 0.1,
                "selection_pressure": 0.5,
                "reward_bias": 1.0,
                "genome_type": "neural",
                "difficulty": 1.0,
                "use_adversary": True,
            }
        ],
        workers=1,
    )
    assert len(results) == 1
    assert "execution_backend" in results[0]


def test_phase5_orchestrator_cycle_returns_telemetry():
    orchestrator = Orchestrator()
    result = orchestrator.run_cycle(
        question="Optimize prosthetic grip stability with simulation-first validation",
        text="Prefer simulation-first safety validation under fatigue.",
        population_size=8,
        generations=3,
        workers=1,
        genome_type="mixed",
    )
    assert "distributed" in result
    assert "meta_evolution" in result
    assert "adversarial" in result
    assert result["distributed"]["worker_count"] >= 1
