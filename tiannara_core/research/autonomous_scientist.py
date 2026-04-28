# tiannara_core/research/autonomous_scientist.py

from dataclasses import dataclass, field
from typing import List, Dict, Any
import random
import time

from tiannara_core.evolution_to_discovery_bridge import EvolutionToDiscoveryBridge
from tiannara_core.evolution.reverse_engine import BehaviorReverseEngineer
from tiannara_core.memory.experience_db import ExperienceDB

@dataclass
class ResearchGoal:
    id: str
    objective: str
    priority: float
    constraints: Dict[str, Any] = field(default_factory=dict)

@dataclass
class ExperimentResult:
    goal_id: str
    success: bool
    score: float
    insights: List[str]

class AutonomousScientist:

    def __init__(self, evolver, simulator, memory: ExperienceDB):
        self.evolver = evolver
        self.simulator = simulator
        self.memory = memory
        self.bridge = EvolutionToDiscoveryBridge()
        self.reverse_engineer = BehaviorReverseEngineer()

        self.active_goals: List[ResearchGoal] = []

    # ─────────────────────────────────────────────
    # 1. Goal Generation (Self-directed curiosity)
    # ─────────────────────────────────────────────
    def generate_goals(self) -> List[ResearchGoal]:
        base_topics = [
            "optimize reward shaping",
            "discover hidden causal patterns",
            "reduce failure rate in simulation",
            "improve mutation efficiency",
            "reverse engineer behavior"
        ]

        goals = []
        for topic in base_topics:
            goals.append(ResearchGoal(
                id=str(random.randint(1000, 9999)),
                objective=topic,
                priority=random.uniform(0.5, 1.0)
            ))

        self.active_goals = goals
        return goals

    # ─────────────────────────────────────────────
    # 2. Experiment Design (ECM-driven)
    # ─────────────────────────────────────────────
    def design_experiment(self, goal: ResearchGoal) -> Dict:
        return {
            "mutation_rate": random.uniform(0.05, 0.3),
            "iterations": random.randint(5, 20),
            "target": goal.objective
        }

    # ─────────────────────────────────────────────
    # 3. Execute Experiment
    # ─────────────────────────────────────────────
    def run_experiment(self, config: Dict) -> Dict:
        results = self.evolver.run(config)
        simulation = self.simulator.run(results)

        return {
            "evolution": results,
            "simulation": simulation
        }

    # ─────────────────────────────────────────────
    # 4. Analyze Results (ACDR + ECM)
    # ─────────────────────────────────────────────
    def analyze(self, raw_results: Dict) -> ExperimentResult:
        evo_results = raw_results["evolution"]

        hypotheses = self.bridge.translate(evo_results)

        traces = raw_results["simulation"].get("traces", [])
        rules = self.reverse_engineer.infer_logic(traces)

        score = sum([h.confidence for h in hypotheses]) / (len(hypotheses) + 1)

        insights = [h.causal_rule for h in hypotheses]
        insights += [r.pseudo_code for r in rules]

        return ExperimentResult(
            goal_id="unknown",
            success=score > 0.5,
            score=score,
            insights=insights
        )

    # ─────────────────────────────────────────────
    # 5. Memory Update
    # ─────────────────────────────────────────────
    def store(self, result: ExperimentResult):
        self.memory.save({
            "goal": result.goal_id,
            "score": result.score,
            "insights": result.insights
        })

    # ─────────────────────────────────────────────
    # 6. Full Loop
    # ─────────────────────────────────────────────
    def run_cycle(self):
        goals = self.generate_goals()

        for goal in goals:
            config = self.design_experiment(goal)
            raw = self.run_experiment(config)
            result = self.analyze(raw)

            result.goal_id = goal.id
            self.store(result)

            print(f"[GOAL] {goal.objective}")
            print(f"[SCORE] {result.score}")
            print(f"[INSIGHTS] {len(result.insights)} generated\n")

    def run_forever(self, cycles=10):
        for i in range(cycles):
            print(f"\n=== Research Cycle {i+1} ===")
            self.run_cycle()
            time.sleep(1)