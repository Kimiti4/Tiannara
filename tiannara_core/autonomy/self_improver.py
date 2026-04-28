from tiannara_core.reasoning.unified_reasoner import UnifiedReasoner
from tiannara_core.autonomy.environment_generator import EnvironmentGenerator
from tiannara_core.autonomy.curiosity_engine import CuriosityEngine
from tiannara_core.autonomy.knowledge_graph import KnowledgeGraph
from tiannara_core.autonomy.long_horizon_memory import LongHorizonMemory


class SelfImprover:

    def __init__(self):
        self.reasoner = UnifiedReasoner()
        self.env_gen = EnvironmentGenerator()
        self.curiosity = CuriosityEngine()
        self.memory = LongHorizonMemory()
        self.knowledge = KnowledgeGraph()

    def run(self, cycles=10):
        for c in range(cycles):
            print(f"\n🌌 Autonomous Cycle {c+1}")

            # 1. Generate environment
            env = self.env_gen.generate()

            # 2. Generate starting code
            code = "x = 1\nfor i in range(5): x += i"

            # 3. Run reasoning system
            result = self.reasoner.run_cycle(code, iterations=5)

            # 4. Score novelty
            novelty = self.curiosity.score_novelty([
                {"state": {"x": result["score"]}}
            ])

            # 5. Store memory
            self.memory.store({
                "env": env,
                "result": result,
                "score": result["score"],
                "novelty": novelty
            })

            # 6. Update knowledge graph
            self.knowledge.add("performance", "score", result["score"])
            self.knowledge.add("novelty", "value", novelty)

            print(f"Score: {result['score']:.3f} | Novelty: {novelty:.3f}")

        return {
            "best": self.memory.get_best(),
            "knowledge": self.knowledge.summarize()
        }