from collections import defaultdict

class SkillMemory:
    """
    Very small skill learner:
    - keeps success/fail counts per (tag -> intent)
    - converts that into a bias score
    """

    def __init__(self):
        # stats[tag][intent] = {"good": int, "bad": int}
        self.stats = defaultdict(lambda: defaultdict(lambda: {"good": 0, "bad": 0}))

    def update(self, context_tags, intent, outcome):
        outcome = outcome.lower().strip()
        for tag in context_tags:
            if outcome == "good":
                self.stats[tag][intent]["good"] += 1
            else:
                self.stats[tag][intent]["bad"] += 1

    def bias(self, context_tags, intent):
        """
        Returns a small bias value.
        Positive if intent has performed well under these tags.
        """
        total_bias = 0.0
        for tag in context_tags:
            s = self.stats[tag][intent]
            good = s["good"]
            bad = s["bad"]
            total = good + bad
            if total == 0:
                continue

            # success rate in [-1..+1] scaled
            rate = (good - bad) / total
            total_bias += rate

        # keep it small so patterns still dominate
        return 0.75 * total_bias
