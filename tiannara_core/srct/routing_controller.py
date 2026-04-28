class RoutingController:

    def __init__(self, graph):
        self.graph = graph

    def route(self, state):
        active_modules = self.graph.get_active_path()

        execution_order = []

        # simple weighted routing (can upgrade later)
        for m in active_modules:
            if m in self.graph.nodes and self.graph.nodes[m].weight > 0.5:
                execution_order.append(m)

        return execution_order