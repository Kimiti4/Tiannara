import random

class ProstheticSimulator:
    """
    Realism helpers:
    - tremor/noise injection into joint angles
    - fatigue accumulation over time (dt-based)
    - stability penalty based on fatigue
    """

    def __init__(self):
        self.fatigue = 0.0  # 0..1

        # Rates are per second (tunable)
        self.fatigue_rise_grip = 0.30      # /sec
        self.fatigue_recover_release = 0.15 # /sec
        self.fatigue_recover_stabilize = 0.08 # /sec

    def add_tremor(self, joint_angles, intensity=0.8):
        return [a + random.uniform(-intensity, intensity) for a in joint_angles]

    def update_fatigue(self, intent, dt=0.05):
        """
        dt in seconds. Example: dt=0.05 means 20Hz control loop.
        """
        if intent == "grip":
            self.fatigue = min(1.0, self.fatigue + self.fatigue_rise_grip * dt)
        elif intent == "release":
            self.fatigue = max(0.0, self.fatigue - self.fatigue_recover_release * dt)
        elif intent == "stabilize":
            self.fatigue = max(0.0, self.fatigue - self.fatigue_recover_stabilize * dt)
        else:
            # idle slowly recovers
            self.fatigue = max(0.0, self.fatigue - 0.05 * dt)

    def stability_penalty(self):
        # More fatigue -> more penalty
        return 0.15 * self.fatigue
