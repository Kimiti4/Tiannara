import numpy as np


class CausalScorer:
    def compute_effect(self, base, intervened):
        # effect size (simple but meaningful)
        return np.mean(np.abs(base - intervened))

    def score(self, trace_a, trace_b):
        return self.compute_effect(trace_a, trace_b)