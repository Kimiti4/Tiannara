"""Test breakpoint detection for Task 45."""
import sys
from pathlib import Path
sys.path.insert(0, str(Path.cwd()))

from tiannara_core.evaluation.reverse_engineering_evolver import ReverseEngineeringEvolver

e = ReverseEngineeringEvolver()
sorted_pairs = [(5, 11), (6, 13), (7, 15), (10, 21), (13, 27), (14, 29), (19, 16), (20, 17)]

print("Testing different breakpoints:")
for bp in [4, 5, 6]:
    left = sorted_pairs[:bp]
    right = sorted_pairs[bp:]
    if len(left) >= 2 and len(right) >= 2:
        m1, b1 = e._fit_line([p[0] for p in left], [p[1] for p in left])
        m2, b2 = e._fit_line([p[0] for p in right], [p[1] for p in right])
        
        # Calculate R²
        mean_y_left = sum(y for _, y in left) / len(left)
        ss_tot_left = sum((y - mean_y_left)**2 for _, y in left)
        ss_res_left = sum((y - (m1*x + b1))**2 for x, y in left)
        r2_left = 1 - ss_res_left/ss_tot_left if ss_tot_left > 0 else 1.0
        
        mean_y_right = sum(y for _, y in right) / len(right)
        ss_tot_right = sum((y - mean_y_right)**2 for _, y in right)
        ss_res_right = sum((y - (m2*x + b2))**2 for x, y in right)
        r2_right = 1 - ss_res_right/ss_tot_right if ss_tot_right > 0 else 1.0
        
        combined = (r2_left*len(left) + r2_right*len(right)) / len(sorted_pairs)
        
        print(f"  BP={bp}: Left R²={r2_left:.3f} (slope {m1:.2f}), Right R²={r2_right:.3f} (slope {m2:.2f}), Combined={combined:.3f}")
        
        # Predict at x=18
        if bp <= 6:  # x=18 is in right segment
            pred = m2 * 18 + b2
            print(f"    Prediction at x=18: {pred:.2f} (expected 15)")
