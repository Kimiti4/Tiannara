import random

class TopologyMutator:

    def mutate(self, graph, performance_score):
        for name, node in graph.nodes.items():

            # deactivate weak modules
            if performance_score < 0.5 and random.random() < 0.3:
                node.active = False

            # reactivate if system struggling
            if performance_score < 0.3 and random.random() < 0.4:
                node.active = True

            # adjust weights
            node.weight += random.uniform(-0.1, 0.1)

            node.weight = max(0.0, min(1.0, node.weight))