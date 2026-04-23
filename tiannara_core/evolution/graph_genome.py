from __future__ import annotations

import math
import random


class GraphGenome:
    def __init__(self, size: int = 5):
        self.size = max(3, int(size))
        self.nodes = list(range(self.size))
        self.edges = {
            (i, j): random.uniform(-1.0, 1.0)
            for i in self.nodes
            for j in self.nodes
            if i != j
        }

    def forward(self, x):
        out = [float(value) for value in x]
        if not out:
            out = [0.0]
        while len(out) < self.size:
            out.append(out[len(out) % len(out)] if out else 0.0)
        out = out[: self.size]

        for (i, j), weight in self.edges.items():
            out[j % self.size] += out[i % self.size] * weight

        return [math.tanh(value) for value in out]

    def mutate(self, rate: float = 0.3):
        mutation_rate = max(0.01, min(1.0, float(rate)))
        if random.random() < mutation_rate:
            edge = random.choice(list(self.edges.keys()))
            self.edges[edge] += random.uniform(-0.5, 0.5)
        if random.random() < mutation_rate * 0.5:
            edge = random.choice(list(self.edges.keys()))
            self.edges[edge] = random.uniform(-1.0, 1.0)


def graph_crossover(parent_a: GraphGenome, parent_b: GraphGenome) -> GraphGenome:
    if parent_a.size != parent_b.size:
        raise ValueError("Parent graph genomes must share the same size")

    child = GraphGenome(size=parent_a.size)
    all_edges = set(parent_a.edges) | set(parent_b.edges)
    child.edges = {
        edge: parent_a.edges.get(edge, parent_b.edges.get(edge, 0.0))
        if random.random() > 0.5
        else parent_b.edges.get(edge, parent_a.edges.get(edge, 0.0))
        for edge in all_edges
    }
    return child
