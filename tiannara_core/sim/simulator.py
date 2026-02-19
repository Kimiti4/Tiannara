import random

class ProstheticSimulator:
    """
    Adds realism:
    - tremor noise on joint angles
    - fatigue buildup
    - stability penalty from fatigue
    """

    def __init__(self):
        self.fatigue = 0.0  # 0..1

    def add_tremor(self, joint_angles, intensity=0.8):
        return [a + random.uniform(-intensity, intensity) for a in joint_angles]

    def update_fatigue(self, intent):
        if intent == "grip":
            self.fatigue = min(1.0, self.fatigue + 0.05)
        elif intent == "release":
            self.fatigue = max(0.0, self.fatigue - 0.02)
        elif intent == "stabilize":
            self.fatigue = max(0.0, self.fatigue - 0.01)

    def stability_penalty(self):
        return 0.15 * self.fatigue
