from __future__ import annotations

import math
import random


def _resize(values, size: int):
    items = [float(v) for v in values]
    if not items:
        items = [0.0]
    if len(items) >= size:
        return items[:size]

    resized = list(items)
    while len(resized) < size:
        resized.append(items[len(resized) % len(items)])
    return resized


def _rand_matrix(rows: int, cols: int):
    return [[random.gauss(0.0, 1.0) for _ in range(cols)] for _ in range(rows)]


def _rand_vector(size: int):
    return [random.gauss(0.0, 1.0) for _ in range(size)]


class NeuralGenome:
    def __init__(self, input_size: int = 5, output_size: int = 3):
        self.input_size = max(1, int(input_size))
        self.output_size = max(1, int(output_size))
        self.w = _rand_matrix(self.input_size, self.output_size)
        self.bias = _rand_vector(self.output_size)

    def forward(self, x):
        values = _resize(x, self.input_size)
        outputs = []

        for column in range(self.output_size):
            total = self.bias[column]
            for row in range(self.input_size):
                total += values[row] * self.w[row][column]
            outputs.append(math.tanh(total))

        return outputs

    def mutate(self, rate: float):
        mutation_rate = max(0.0, min(1.0, float(rate)))
        if random.random() < mutation_rate:
            for row in range(self.input_size):
                for column in range(self.output_size):
                    self.w[row][column] += random.gauss(0.0, 0.3)
        if random.random() < mutation_rate:
            for index in range(self.output_size):
                self.bias[index] += random.gauss(0.0, 0.3)


def crossover(p1: NeuralGenome, p2: NeuralGenome) -> NeuralGenome:
    if (p1.input_size, p1.output_size) != (p2.input_size, p2.output_size):
        raise ValueError("Parent genomes must share the same shape")

    child = NeuralGenome(p1.input_size, p1.output_size)
    child.w = [
        [
            p1.w[row][column] if random.random() > 0.5 else p2.w[row][column]
            for column in range(p1.output_size)
        ]
        for row in range(p1.input_size)
    ]
    child.bias = [
        p1.bias[index] if random.random() > 0.5 else p2.bias[index]
        for index in range(p1.output_size)
    ]
    return child
