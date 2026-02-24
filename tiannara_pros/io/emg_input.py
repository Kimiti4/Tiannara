import random
import math

class EMGInput:
    """
    Simulated EMG input provider.
    Produces EMG-like features:
      - rms: signal strength
      - zcr: zero-crossing rate (rough proxy for noise/activation pattern)
      - fatigue: slowly rising value
    Then maps them to tags for the pipeline.

    Later: replace generate_emg_window() with real EMG acquisition.
    """

    def __init__(self):
        self.t = 0
        self.fatigue = 0.0

    def generate_emg_window(self):
        """
        Returns EMG-like features for one time window.
        """
        self.t += 1

        # simulate cycles of activation
        phase = (self.t % 40) / 40.0
        base = 0.2 + 0.8 * (0.5 - abs(phase - 0.5))  # triangle-ish activation 0.2..0.6

        # fatigue increases slowly (reduces effective control quality)
        self.fatigue = min(1.0, self.fatigue + 0.01)

        # RMS around base with noise, reduced by fatigue
        rms = max(0.0, (base + random.uniform(-0.05, 0.05)) * (1.0 - 0.3 * self.fatigue))

        # ZCR: higher means noisier / less stable control
        zcr = max(0.0, 0.1 + random.uniform(0.0, 0.5) * self.fatigue)

        return {"rms": rms, "zcr": zcr, "fatigue": self.fatigue}

    def emg_to_tags(self, features):
        """
        Map features to context tags.
        These are just placeholder rules; tune later.
        """
        rms = features["rms"]
        zcr = features["zcr"]

        # if signal is strong and clean -> precision
        if rms >= 0.35 and zcr <= 0.25:
            return ["precision"]

        # strong but a bit noisy -> hand
        if rms >= 0.25:
            return ["hand"]

        # low RMS but noisy -> balance/stabilize context (shaky)
        if zcr >= 0.35:
            return ["balance"]

        return ["unknown"]

    def get_next(self):
        feats = self.generate_emg_window()
        tags = self.emg_to_tags(feats)
        print("[EMGInput] get_next() ->", tags)

        # include EMG features so you can log them later
        return {
            "joint_angles": [
                10 + random.uniform(-1, 1),
                20 + random.uniform(-1, 1),
                30 + random.uniform(-1, 1),
            ],
            "tags": tags,
            "emg": feats
        }
