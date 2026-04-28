from collections import defaultdict

class KnowledgeGraph:

    def __init__(self):
        self.graph = defaultdict(list)

    def add(self, concept, relation, value):
        self.graph[concept].append((relation, value))

    def query(self, concept):
        return self.graph.get(concept, [])

    def summarize(self):
        return {k: len(v) for k, v in self.graph.items()}