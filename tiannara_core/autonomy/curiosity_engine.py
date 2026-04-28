import random

class CuriosityEngine:

    def __init__(self):
        self.history = []

    def score_novelty(self, trace):
        if not self.history:
            return 1.0

        last = self.history[-1]

        diff = abs(trace[-1]["state"]["x"] - last[-1]["state"]["x"])
        return min(1.0, diff)

    def select_goal(self, hypotheses):
        if not hypotheses:
            return {"goal": "explore_random"}

        return random.choice(hypotheses)