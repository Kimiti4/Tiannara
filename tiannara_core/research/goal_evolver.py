# tiannara_core/research/goal_evolver.py

import random

class GoalEvolver:

    def evolve(self, past_goals):
        new_goals = []

        for g in past_goals:
            if g["score"] > 0.7:
                new_goals.append({
                    "objective": g["goal"] + " (refined)",
                    "priority": min(1.0, g["score"] + 0.1)
                })
            else:
                new_goals.append({
                    "objective": "alternative approach to " + g["goal"],
                    "priority": random.uniform(0.4, 0.8)
                })

        return new_goals