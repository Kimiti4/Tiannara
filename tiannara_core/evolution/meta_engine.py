# Meta Engine
import random

class MetaGenome:
    def __init__(self):
        self.mutation_rate = random.uniform(0.01, 0.25)
        self.selection_pressure = random.uniform(0.5, 0.9)
        self.reward_bias = random.uniform(0.8, 1.2)

    def mutate(self):
        if random.random() < 0.5:
            self.mutation_rate *= random.uniform(0.85, 1.15)

        if random.random() < 0.5:
            self.selection_pressure *= random.uniform(0.9, 1.1)

        if random.random() < 0.5:
            self.reward_bias *= random.uniform(0.9, 1.1)

        self.mutation_rate = min(0.45, max(0.01, self.mutation_rate))
        self.selection_pressure = min(0.95, max(0.35, self.selection_pressure))
        self.reward_bias = min(1.5, max(0.6, self.reward_bias))

    def as_dict(self):
        return {
            "mutation_rate": round(self.mutation_rate, 4),
            "selection_pressure": round(self.selection_pressure, 4),
            "reward_bias": round(self.reward_bias, 4),
        }
