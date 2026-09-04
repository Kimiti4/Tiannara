import time

def run_test():
    with open('scripts/fast_rea_7n_c_world_b.py', 'r') as f:
        code = f.read()
    
    code = code.replace("for epoch in range(1, 401):", 
"""for epoch in range(1, 3):
        import time
        t0 = time.time()
        S_sum = np.array(state.S_sparse[0].sum(axis=1) + state.S_sparse[1].sum(axis=1) + state.S_sparse[2].sum(axis=1)).flatten()
        state.target_node = int(np.argmax(S_sum))
        t1 = time.time()
        ce = run_simulation_step_c(state, neighbors, K_csr, target_trace, emit_trace, MAX_PHI, DECAY, MORTALITY_RATE, WALK_STEPS, world_mode='A')
        t2 = time.time()
        print(f"Epoch {epoch} finished in {t2-t1:.4f}s")
""")
    
    # instrument run_simulation_step_c
    code = code.replace("for step in range(WALK_STEPS):", "import time\n    t_walk = 0.0\n    t_cons = 0.0\n    for step in range(WALK_STEPS):\n        w0 = time.time()")
    code = code.replace("agent_order = np.random.permutation(N_AGENTS)", "w1 = time.time()\n        t_walk += w1 - w0\n        c0 = time.time()\n        agent_order = np.random.permutation(N_AGENTS)")
    code = code.replace("for t in range(3):", "c1 = time.time()\n        t_cons += c1 - c0\n    s0 = time.time()\n    for t in range(3):")
    code = code.replace("return CE", "s1 = time.time()\n    print(f'  Walk: {t_walk:.4f} | Consume: {t_cons:.4f} | Sparse: {s1-s0:.4f}')\n    return CE")

    with open('scripts/test_perf3.py', 'w') as f:
        f.write(code)

if __name__ == "__main__":
    run_test()
