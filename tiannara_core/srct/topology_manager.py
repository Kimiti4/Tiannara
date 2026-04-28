from tiannara_core.srct.module_graph import ModuleGraph
from tiannara_core.srct.routing_controller import RoutingController
from tiannara_core.srct.topology_mutator import TopologyMutator


class TopologyManager:

    def __init__(self):
        self.graph = ModuleGraph()
        self._init_modules()

        self.router = RoutingController(self.graph)
        self.mutator = TopologyMutator()

    def _init_modules(self):
        modules = [
            "evolution",
            "causal",
            "compression",
            "reverse_engine",
            "memory",
            "planner"
        ]

        for m in modules:
            self.graph.add_module(m)

        # basic pipeline connections
        self.graph.connect("planner", "evolution")
        self.graph.connect("evolution", "causal")
        self.graph.connect("causal", "compression")
        self.graph.connect("compression", "reverse_engine")

    def get_execution_plan(self, state):
        return self.router.route(state)

    def evolve_topology(self, score):
        self.mutator.mutate(self.graph, score)