#!/usr/bin/env python3
import sys
import os
import asyncio
import json
import numpy as np
import time
from pathlib import Path
from nats.aio.client import Client as NATS

# Add the parent directories to path so we can import phase_11_6_generativity_response_curve
sys.path.append(str(Path(__file__).parent.parent.parent.parent))
sys.path.append(str(Path(__file__).parent.parent.parent))

import phase_11_6_generativity_response_curve as rc

# State variables to be initialized
neighbors = None
K_csr = None
tt = None
et = None
baseline = None
donor_state = None
donor_fp = None
donor_arch = None
donor_ep = None
recipient_state = None
recipient_fp = None
recip_arch = None
recip_ep = None
donor_coords = None
recipient_coords = None

def init_environment():
    global neighbors, K_csr, tt, et, baseline
    global donor_state, donor_fp, donor_arch, donor_ep
    global recipient_state, recipient_fp, recip_arch, recip_ep
    global donor_coords, recipient_coords

    print("[Init] Initializing simulation state...")
    rc.get_kmeans_model()
    neighbors, K_csr = rc.generate_topology(rc.N_NODES, k_ring=rc.RADIUS * 2)
    rc.COUNTERFACTUAL_DEPTH = 1
    np.random.seed(42)
    niche = np.zeros(rc.N_AGENTS, dtype=np.int32)
    niche[33:66] = 1
    niche[66:] = 2
    tt = np.zeros(rc.N_AGENTS, dtype=np.int32)
    tt[niche == 2] = 1
    et = np.copy(niche)

    print("[Init] Running baseline warm-up (400 epochs)...")
    baseline = rc.warm_up(neighbors, K_csr, tt, et, niche)

    print("[Init] Acquiring donor (GENERATOR state)...")
    donor_state, donor_fp, donor_arch, donor_ep = rc.acquire_donor(
        baseline, neighbors, K_csr, tt, et,
        scan_archetypes=['Explorer']
    )
    if donor_state is None:
        raise RuntimeError("Failed to acquire donor state")

    print("[Init] Acquiring recipient (DESERT state)...")
    recipient_state, recipient_fp, recip_arch, recip_ep = rc.acquire_recipient(
        baseline, neighbors, K_csr, tt, et
    )
    if recipient_state is None:
        raise RuntimeError("Failed to acquire recipient state")

    gate_ok, contrast, contrast_lbl = rc.validate_contrast(donor_fp, recipient_fp)
    print(f"[Init] Contrast: {contrast:.2f}x ({contrast_lbl}) Gate Pass: {gate_ok}")

    arch_map = {
        'Settler': rc.SETTLER, 'Trader': rc.TRADER, 'Survivor': rc.SURVIVOR,
        'Explorer': rc.EXPLORER, 'Phoenix': rc.PHOENIX, 'baseline': rc.SETTLER
    }
    donor_coords = arch_map.get(donor_arch, rc.SETTLER)
    recipient_coords = rc.SETTLER if donor_coords == rc.TRADER else rc.TRADER

def evaluate_orbit(req: dict) -> dict:
    T = float(req.get('T', 0.5))
    H = float(req.get('H', 0.5))
    C = float(req.get('C', 0.5))
    I = float(req.get('I', 0.5))
    family = req.get('family', 'unknown')

    # Create blended state
    s = recipient_state.copy()
    
    # 1. Topology blend
    s.trust_matrix = np.clip(
        T * donor_state.trust_matrix + (1.0 - T) * recipient_state.trust_matrix,
        1.0, 5.0
    )
    
    # 2. History blend
    s.S_sparse = [
        donor_state.S_sparse[t].multiply(H) +
        recipient_state.S_sparse[t].multiply(1.0 - H)
        for t in range(3)
    ]
    if H >= 0.5:
        s.target_node = donor_state.target_node
        
    # 3. Constitution blend
    coords = tuple(
        C * d + (1.0 - C) * r
        for d, r in zip(donor_coords, recipient_coords)
    )
    
    # 4. Identity blend (persistence)
    if I == 0.0:
        s.trust_matrix = np.ones((rc.N_AGENTS, rc.N_AGENTS), dtype=np.float32)
    elif I == 1.0:
        s.trust_matrix = np.copy(donor_state.trust_matrix)
    else:
        mask = np.random.rand(rc.N_AGENTS, rc.N_AGENTS) < I
        s.trust_matrix = np.where(mask, donor_state.trust_matrix,
                                  np.ones((rc.N_AGENTS, rc.N_AGENTS), dtype=np.float32))
    s.trust_matrix = np.clip(s.trust_matrix, 1.0, 5.0)

    generator_sequence = []
    pr_values = []
    pe_values = []

    # Simulate and measure every 10 epochs
    for ep in range(0, rc.OBSERVATION_WINDOW, 10):
        for _ in range(10):
            rc.run_archetype_epoch(s, neighbors, K_csr, tt, et, coords)
            rc.update_target_node(s)
        
        m = rc.measure_full(s, neighbors, K_csr, tt, et)
        is_g = rc.is_generator(m)
        generator_sequence.append(is_g)
        pr_values.append(m['pr'])
        pe_values.append(m['pe'])

    # Calculate invariants
    total_generator_epochs = sum(1 for is_g in generator_sequence if is_g) * 10
    duty_cycle = total_generator_epochs / float(rc.OBSERVATION_WINDOW)

    bursts = []
    current_burst_len = 0
    inter_arrival_times = []
    last_arrival_index = None

    for idx, is_g in enumerate(generator_sequence):
        if is_g:
            if current_burst_len == 0:
                if last_arrival_index is not None:
                    inter_arrival_times.append((idx - last_arrival_index) * 10)
                last_arrival_index = idx
            current_burst_len += 10
        else:
            if current_burst_len > 0:
                bursts.append(current_burst_len)
                current_burst_len = 0
    if current_burst_len > 0:
        bursts.append(current_burst_len)

    burst_duration = float(np.mean(bursts)) if bursts else 0.0
    recurrence = len(bursts) / float(rc.OBSERVATION_WINDOW)
    
    if len(inter_arrival_times) >= 2:
        recurrence_stability = float(np.std(inter_arrival_times))
    else:
        recurrence_stability = 0.0

    largest_generator_burst = max(bursts) if bursts else 0.0
    if total_generator_epochs > 0:
        duty_concentration = largest_generator_burst / total_generator_epochs
    else:
        duty_concentration = 0.0

    return_times = []
    current_drop_len = 0
    in_drop = False
    for is_g in generator_sequence:
        if not is_g:
            if not in_drop:
                in_drop = True
                current_drop_len = 0
            current_drop_len += 2
        else:
            if in_drop:
                return_times.append(current_drop_len)
                in_drop = False
    if in_drop and current_drop_len > 0:
        return_times.append(current_drop_len)

    mean_return_time = float(np.mean(return_times)) if return_times else 0.0
    return_efficiency = 1.0 / (1.0 + mean_return_time)
    generator_hl = burst_duration * 1.44

    generator_indices = [i for i, is_g in enumerate(generator_sequence) if is_g]
    if generator_indices:
        mean_pr = float(np.mean([pr_values[i] for i in generator_indices]))
        mean_pe = float(np.mean([pe_values[i] for i in generator_indices]))
    else:
        mean_pr = float(np.mean(pr_values))
        mean_pe = float(np.mean(pe_values))

    # GSI Formula: 0.30*DutyCycle + 0.20*Recurrence + 0.20*PR + 0.10*PE + 0.20*ReturnEfficiency
    gsi = (0.30 * duty_cycle +
           0.20 * recurrence +
           0.20 * mean_pr +
           0.10 * mean_pe +
           0.20 * return_efficiency)

    return {
        'duty_cycle': round(duty_cycle, 4),
        'recurrence': round(recurrence, 4),
        'burst_duration': round(burst_duration, 4),
        'return_time': round(mean_return_time, 4),
        'return_efficiency': round(return_efficiency, 4),
        'recurrence_stability': round(recurrence_stability, 4),
        'duty_concentration': round(duty_concentration, 4),
        'half_life': round(generator_hl, 4),
        'mean_pr': round(mean_pr, 4),
        'mean_pe': round(mean_pe, 4),
        'gsi': round(gsi, 4),
        'family': family,
        'coordinates': {'T': T, 'H': H, 'C': C, 'I': I}
    }

async def main():
    print("=" * 80)
    print("PHASE 11.7 — TRAJECTORY TENSOR MICRO-PHYSICS ENGINE")
    print("=" * 80)
    
    init_environment()
    
    nc = NATS()
    print("Connecting to NATS at nats://127.0.0.1:4222...")
    await nc.connect("nats://127.0.0.1:4222")
    print("Connected successfully.")

    async def message_handler(msg):
        try:
            req_data = json.loads(msg.data.decode())
            print(f"Received request: family={req_data.get('family')} coordinates={req_data}", flush=True)
            res = evaluate_orbit(req_data)
            print(f"Processed request. GSI={res.get('gsi')}", flush=True)
            await nc.publish(msg.reply, json.dumps(res).encode())
        except Exception as e:
            print(f"[Error] Failed to process request: {e}", flush=True)
            err_res = {'error': str(e)}
            await nc.publish(msg.reply, json.dumps(err_res).encode())

    await nc.subscribe("tiannara.ucc.trajectory_tensor.request", cb=message_handler)
    print("Listening for requests on 'tiannara.ucc.trajectory_tensor.request'...")
    
    while True:
        await asyncio.sleep(1)

if __name__ == "__main__":
    asyncio.run(main())
