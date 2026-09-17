"""Check if BP=6 passes the penalty test."""
import sys
from pathlib import Path
sys.path.insert(0, str(Path.cwd()))

from tiannara_core.evaluation.reverse_engineering_evolver import ReverseEngineeringEvolver

e = ReverseEngineeringEvolver()
sorted_pairs = [(5, 11), (6, 13), (7, 15), (10, 21), (13, 27), (14, 29), (19, 16), (20, 17)]

# Baseline
xs = [p[0] for p in sorted_pairs]
ys = [p[1] for p in sorted_pairs]
m_base, b_base = e._fit_line(xs, ys)
baseline_rss = sum((y - (m_base * x + b_base))**2 for x, y in zip(xs, ys))
penalty = 2 * len(sorted_pairs)

print(f"Baseline RSS: {baseline_rss:.2f}")
print(f"Penalty: {penalty}")
print(f"Threshold: baseline_rss - penalty = {baseline_rss - penalty:.2f}\n")

for split in range(3, len(sorted_pairs) - 3):
    left = sorted_pairs[:split]
    right = sorted_pairs[split:]
    
    m1, b1 = e._fit_line([p[0] for p in left], [p[1] for p in left])
    rss_left = sum((y - (m1 * x + b1))**2 for x, y in left)
    
    m2, b2 = e._fit_line([p[0] for p in right], [p[1] for p in right])
    rss_right = sum((y - (m2 * x + b2))**2 for x, y in right)
    
    total_cost = rss_left + rss_right
    improvement = baseline_rss - total_cost
    
    passes = total_cost < baseline_rss - penalty
    
    print(f"Split={split}: RSS={total_cost:.2f}, Improvement={improvement:.2f}, Passes threshold? {passes}")
