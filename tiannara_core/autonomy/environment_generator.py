import random

class EnvironmentGenerator:

    def generate(self):
        env_type = random.choice(["math", "logic", "dynamic"])

        if env_type == "math":
            return {
                "type": "math",
                "task": "optimize function",
                "target": random.uniform(-10, 10)
            }

        if env_type == "logic":
            return {
                "type": "logic",
                "task": "pattern discovery",
                "pattern": [random.randint(0, 5) for _ in range(5)]
            }

        return {
            "type": "dynamic",
            "task": "control system",
            "initial": random.random()
        }