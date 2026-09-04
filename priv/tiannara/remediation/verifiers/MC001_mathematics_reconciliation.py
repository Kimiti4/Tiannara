"""
MC-001 reconciliation verifier.

Performs actual static verification over the inspected source files to confirm
the inventory / truth-classification claims in the MC-001 deliverables. It does
NOT fabricate results: it scans real files and reports what it finds.

Checks:
  1. REAL primitives present (bayes_update, kl_divergence, BFS, cosine, numerics).
  2. THEATRICAL mocks flagged with `mock: true` (Optimization, solve_ode,
     FormalVerification).
  3. Duplicate operations (entropy, variance, std_dev, cosine) across modules.
  4. Physics domain coupling to mocks (simulate->solve_ode, validate->
     verify_invariants).
  5. Physics.metrics hardcoded numbers (fabrication indicator).
  6. Mathematics NOT in the canonical domain registry.
"""
import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", ".."))
LIB = os.path.join(ROOT, "lib", "tiannara")


def read(rel):
    with open(os.path.join(LIB, rel), encoding="utf-8", errors="replace") as fh:
        return fh.read()


def contains(big, small):
    return small in big


def main():
    failures = []

    # --- 1. REAL primitives (must exist) ---
    prob = read(os.path.join("math", "probability.ex"))
    info = read(os.path.join("foundations", "information_theory.ex"))
    graphs = read(os.path.join("math", "graphs.ex"))
    mathmod = read(os.path.join("math.ex"))
    nums = read("numerics.ex")

    if "def bayes_update" not in prob:
        failures.append("bayes_update/3 missing in Math.Probability")
    if "def kl_divergence" not in info:
        failures.append("kl_divergence/2 missing")
    if "def shortest_path" not in graphs:
        failures.append("BFS shortest_path missing in Math.Graphs")
    if "def cosine_similarity" not in mathmod:
        failures.append("cosine_similarity missing in Tiannara.Math")
    if "def newton_interpolate" not in nums or "def t_statistic" not in nums:
        failures.append("Numerics interpolation/statistics missing")

    # --- 2. THEATRICAL mocks (must be flagged mock: true) ---
    opt = read(os.path.join("math", "optimization.ex"))
    calc = read(os.path.join("foundations", "mathematics", "calculus.ex"))
    fv = read(os.path.join("foundations", "formal_verification.ex"))
    if "mock: true" not in opt:
        failures.append("Optimization not flagged mock:true")
    if "mock: true" not in calc:
        failures.append("solve_ode not flagged mock:true")
    if "mock: true" not in fv:
        failures.append("FormalVerification not flagged mock:true")

    # --- 3. Duplicate operations ---
    orbit = read(os.path.join("discoveries", "orbit_memory_ecology.ex"))
    ch = read(os.path.join("rea", "causal", "channel.ex"))
    stats = read(os.path.join("math", "statistics.ex"))
    if not (contains(prob, "def shannon_entropy") and contains(info, "def shannon_entropy")):
        failures.append("entropy duplication not confirmed")
    if not (contains(nums, "def variance") and contains(stats, "def variance") and contains(ch, "def variance")):
        failures.append("variance duplication not confirmed")
    if not (contains(mathmod, "def cosine_similarity") and contains(orbit, "def cosine_similarity")):
        failures.append("cosine duplication not confirmed")

    # --- 4. Physics coupling to mocks ---
    phys = read(os.path.join("domains", "physics.ex"))
    if "Calculus.solve_ode" not in phys or "simulate" not in phys:
        failures.append("Physics not coupled to solve_ode mock")
    if "FormalVerification.verify_invariants" not in phys:
        failures.append("Physics not coupled to formal-verification mock")

    # --- 5. Physics.metrics fabricated (hardcoded numbers) ---
    m = re.search(r"def metrics do\s*\n\s*%(.*?)\n\s*end", phys, re.DOTALL)
    if not m:
        failures.append("Physics.metrics not found")
    else:
        if "discoveries_this_cycle: 4" not in phys or "evidence_quality_score: 0.88" not in phys:
            failures.append("Physics.metrics hardcoded values not confirmed")

    # --- 6. Mathematics NOT a canonical domain ---
    try:
        cr = read(os.path.join("domains", "canonical_registry.ex"))
    except FileNotFoundError:
        failures.append("canonical_registry.ex not found")
        cr = ""
    # :mathematics must NOT be in the canonical @canonical_domains list
    if re.search(r":mathematics\b", cr) and ":mathematics (epistemic" not in cr:
        failures.append(":mathematics appears in canonical registry as a domain")

    if failures:
        print("MC-001 VERIFY: FAIL")
        for f_ in failures:
            print("  -", f_)
        sys.exit(1)

    print("MC-001 VERIFY: PASS")
    print("  REAL primitives       : present")
    print("  THEATRICAL mocks      : confirmed (mock: true)")
    print("  Duplicate operations  : confirmed")
    print("  Physics->mock coupling: confirmed")
    print("  Physics.metrics       : fabricated numbers confirmed")
    print("  :mathematics not domain: confirmed")


if __name__ == "__main__":
    main()
