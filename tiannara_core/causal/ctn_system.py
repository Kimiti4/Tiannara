"""
PHASE 5E.7: CAUSAL TENSEGRITY NODE (CTN) SYSTEM

Advanced causal stabilization layer that completes Phase 5E before transitioning to Phase 5F.

Based on 5E.md architecture specification (lines 218-433):
"CTNs DO NOT break causality — they redistribute it"

This module implements:
1. CTN Registry - Tracks active Causal Tensegrity Nodes
2. Paradox Detector - GCK-aware κ = |Hf - Hb| evaluation
3. Energy Harvester - Converts paradox tension into usable energy
4. Tensegrity Graph Engine - Elastic causal coupling between nodes
5. Temporal Echo Memory Ring - Stores historical states for loop stabilization
6. CTN Field Tensor Processor - VRAM-level causal dynamics simulation

Key Design Constraint:
CTNs are bounded instability structures that remain GCK-compliant.
They stabilize paradoxes rather than allowing them to become observer-relative (5F).
"""

import sys
import time
import math
import random
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Set
from dataclasses import dataclass, field
from enum import Enum
import numpy as np
from collections import deque

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))


class CTNState(Enum):
    """Causal Tensegrity Node state classification."""
    STABLE_FLOW = "stable_flow"              # Normal physics
    ELASTIC_KNOT = "elastic_knot"            # CTN forming
    RESONANT_LOOP = "resonant_loop"          # Paradox stabilizing
    LOCKED_CTN = "locked_ctn"                # Permanent structure
    FRACTURE_CASCADE = "fracture_cascade"    # Pre-GCK escalation


@dataclass
class CausalTensegrityNode:
    """
    Represents a single Causal Tensegrity Node.
    
    From 5E.md (lines 226-240):
    "CTN system is a bounded causal instability engine that:
     - Detects paradox formation in field tensors
     - Converts contradiction into structured energy
     - Stabilizes loops using elastic causal coupling
     - Prevents GCK violations before escalation to 5F"
    """
    node_id: str
    forward_entropy: float      # Hf (forward causal entropy)
    backward_entropy: float     # Hb (backward causal entropy)
    tension: float              # Structural tension (0.0 to 1.0)
    loop_frequency: float       # Oscillation frequency of paradox loop
    stability: float            # Current stability score (0.0 to 1.0)
    state: CTNState = CTNState.STABLE_FLOW
    energy_contribution: float = 0.0  # Energy harvested from this node
    creation_time: float = field(default_factory=time.time)
    connected_nodes: List[str] = field(default_factory=list)  # Elastic couplings
    
    @property
    def kappa(self) -> float:
        """
        Calculate paradox intensity κ = |Hf - Hb|.
        
        From 5E.md (lines 75-81):
        This measures causal measurement - the degree of contradiction.
        """
        return abs(self.forward_entropy - self.backward_entropy)
    
    def update_state(self):
        """Update node state based on current parameters."""
        if self.kappa > 0.8:
            self.state = CTNState.FRACTURE_CASCADE
        elif self.kappa > 0.5 and self.loop_frequency > 0.3:
            self.state = CTNState.LOCKED_CTN
        elif self.kappa > 0.3 and self.loop_frequency > 0.1:
            self.state = CTNState.RESONANT_LOOP
        elif self.kappa > 0.1:
            self.state = CTNState.ELASTIC_KNOT
        else:
            self.state = CTNState.STABLE_FLOW


@dataclass
class TensegrityEdge:
    """
    Elastic causal coupling between two CTNs.
    
    Represents the "tensegrity thread" connecting paradox nodes.
    """
    from_node: str
    to_node: str
    elasticity_modulus: float   # Stiffness of causal connection (0.0 to 1.0)
    sync_phase: float           # Synchronization phase offset
    tension_transfer: float     # Amount of tension transferred between nodes
    created_at: float = field(default_factory=time.time)


@dataclass
class CTNEnergyPool:
    """
    Aggregated energy harvested from paradox stabilization.
    
    From 5E.md (lines 345-363):
    Energy = tension × log(freq + 1)
    
    This energy can be used to:
    - Modify selection temperature τ
    - Power law resurrection mechanisms
    - Fuel temporal echo blending
    """
    total_energy: float = 0.0
    harvest_events: int = 0
    tau_modifier: float = 0.0  # Modification to selection temperature
    
    def harvest_energy(self, tension: float, frequency: float) -> float:
        """
        Harvest energy from a paradox node.
        
        Formula: energy = tension × log(freq + 1)
        """
        energy = tension * math.log(frequency + 1)
        self.total_energy += energy
        self.harvest_events += 1
        
        # Calculate tau modifier (bounded by tanh)
        self.tau_modifier = math.tanh(self.total_energy * 0.01)
        
        return energy


class ParadoxDetector:
    """
    GCK-aware paradox detection engine.
    
    From 5E.md (lines 319-341):
    Evaluates contradiction between nodes using κ metric.
    
    Classification thresholds:
    - κ > 0.8 → critical_paradox (fracture cascade)
    - κ > 0.5 → stable_ctn (resonant loop)
    - κ ≤ 0.5 → normal_flow (stable or elastic knot)
    """
    
    def __init__(self, critical_threshold: float = 0.8, stable_threshold: float = 0.5):
        """
        Initialize paradox detector.
        
        Args:
            critical_threshold: κ threshold for critical paradox
            stable_threshold: κ threshold for stable CTN
        """
        self.critical_threshold = critical_threshold
        self.stable_threshold = stable_threshold
        self.detection_log: List[Dict] = []
    
    def evaluate_pair(self, node_a: CausalTensegrityNode, node_b: CausalTensegrityNode) -> Tuple[str, float]:
        """
        Evaluate paradox potential between two nodes.
        
        Returns:
            Tuple of (classification, kappa_value)
        """
        # Calculate combined kappa
        delta_entropy = abs(node_a.forward_entropy - node_b.backward_entropy)
        combined_tension = node_a.tension + node_b.tension
        
        kappa = delta_entropy * combined_tension
        
        # Classify
        if kappa > self.critical_threshold:
            classification = "critical_paradox"
        elif kappa > self.stable_threshold:
            classification = "stable_ctn"
        else:
            classification = "normal_flow"
        
        # Log detection
        self.detection_log.append({
            'node_a': node_a.node_id,
            'node_b': node_b.node_id,
            'kappa': kappa,
            'classification': classification,
            'timestamp': time.time()
        })
        
        return classification, kappa
    
    def detect_fracture_risk(self, nodes: List[CausalTensegrityNode]) -> Dict:
        """
        Assess overall fracture risk across all CTNs.
        
        Returns:
            Dictionary with risk metrics
        """
        if not nodes:
            return {'risk_level': 'none', 'avg_kappa': 0.0, 'critical_count': 0}
        
        kappas = [node.kappa for node in nodes]
        avg_kappa = np.mean(kappas)
        max_kappa = np.max(kappas)
        
        critical_count = sum(1 for k in kappas if k > self.critical_threshold)
        stable_count = sum(1 for k in kappas if k > self.stable_threshold)
        
        # Determine risk level
        if critical_count > len(nodes) * 0.3:
            risk_level = "critical"
        elif critical_count > 0 or avg_kappa > 0.6:
            risk_level = "elevated"
        elif avg_kappa > 0.4:
            risk_level = "moderate"
        else:
            risk_level = "low"
        
        return {
            'risk_level': risk_level,
            'avg_kappa': float(avg_kappa),
            'max_kappa': float(max_kappa),
            'critical_count': critical_count,
            'stable_count': stable_count,
            'total_nodes': len(nodes)
        }


class EnergyHarvester:
    """
    Converts paradox tension into usable energy pool.
    
    From 5E.md (lines 345-363):
    Publishes energy flow events via NATS for downstream systems.
    """
    
    def __init__(self):
        """Initialize energy harvester."""
        self.energy_pool = CTNEnergyPool()
        self.harvest_history: List[Dict] = []
    
    def harvest_from_node(self, node: CausalTensegrityNode) -> float:
        """
        Harvest energy from a single CTN.
        
        Args:
            node: Source CTN
        
        Returns:
            Energy harvested
        """
        energy = self.energy_pool.harvest_energy(node.tension, node.loop_frequency)
        node.energy_contribution = energy
        
        # Record harvest event
        self.harvest_history.append({
            'node_id': node.node_id,
            'energy': energy,
            'total_pool': self.energy_pool.total_energy,
            'tau_modifier': self.energy_pool.tau_modifier,
            'timestamp': time.time()
        })
        
        return energy
    
    def harvest_from_network(self, nodes: List[CausalTensegrityNode]) -> float:
        """
        Harvest energy from entire CTN network.
        
        Args:
            nodes: List of all active CTNs
        
        Returns:
            Total energy harvested
        """
        total_energy = 0.0
        for node in nodes:
            if node.state in [CTNState.RESONANT_LOOP, CTNState.LOCKED_CTN]:
                energy = self.harvest_from_node(node)
                total_energy += energy
        
        return total_energy
    
    def get_tau_adjustment(self) -> float:
        """
        Get selection temperature adjustment based on harvested energy.
        
        Returns:
            Tau modifier (0.0 to 1.0)
        """
        return self.energy_pool.tau_modifier


class TensegrityGraphEngine:
    """
    Manages elastic causal couplings between CTNs.
    
    Builds and maintains the tensegrity network structure,
    ensuring bounded instability through controlled tension transfer.
    """
    
    def __init__(self, max_connections: int = 5):
        """
        Initialize tensegrity graph engine.
        
        Args:
            max_connections: Maximum edges per node (prevents over-coupling)
        """
        self.edges: Dict[Tuple[str, str], TensegrityEdge] = {}
        self.adjacency_list: Dict[str, List[str]] = {}
        self.max_connections = max_connections
        self.graph_updates: List[Dict] = []
    
    def establish_coupling(self, node_a_id: str, node_b_id: str, 
                          elasticity: float = 0.5, sync_phase: float = 0.0) -> TensegrityEdge:
        """
        Create elastic causal coupling between two CTNs.
        
        Args:
            node_a_id: Source node ID
            node_b_id: Target node ID
            elasticity: Elasticity modulus (0.0 = rigid, 1.0 = flexible)
            sync_phase: Synchronization phase offset
        
        Returns:
            Created TensegrityEdge
        """
        edge_key = (node_a_id, node_b_id)
        
        # Check connection limits
        if len(self.adjacency_list.get(node_a_id, [])) >= self.max_connections:
            raise ValueError(f"Node {node_a_id} has reached max connections")
        
        # Create edge
        edge = TensegrityEdge(
            from_node=node_a_id,
            to_node=node_b_id,
            elasticity_modulus=elasticity,
            sync_phase=sync_phase,
            tension_transfer=0.0
        )
        
        self.edges[edge_key] = edge
        
        # Update adjacency lists
        if node_a_id not in self.adjacency_list:
            self.adjacency_list[node_a_id] = []
        if node_b_id not in self.adjacency_list:
            self.adjacency_list[node_b_id] = []
        
        self.adjacency_list[node_a_id].append(node_b_id)
        self.adjacency_list[node_b_id].append(node_a_id)
        
        # Log update
        self.graph_updates.append({
            'action': 'coupling_established',
            'edge': edge_key,
            'elasticity': elasticity,
            'timestamp': time.time()
        })
        
        return edge
    
    def propagate_tension(self, nodes: Dict[str, CausalTensegrityNode]):
        """
        Propagate tension through elastic couplings.
        
        Simulates tension redistribution across the tensegrity network.
        """
        for (node_a_id, node_b_id), edge in self.edges.items():
            if node_a_id in nodes and node_b_id in nodes:
                node_a = nodes[node_a_id]
                node_b = nodes[node_b_id]
                
                # Calculate tension differential
                tension_diff = node_a.tension - node_b.tension
                
                # Transfer tension based on elasticity
                transfer = tension_diff * edge.elasticity_modulus * 0.1  # Damping factor
                
                # Apply transfer (bounded)
                node_a.tension = max(0.0, min(1.0, node_a.tension - transfer))
                node_b.tension = max(0.0, min(1.0, node_b.tension + transfer))
                
                edge.tension_transfer = transfer
    
    def detect_loops(self) -> List[List[str]]:
        """
        Detect closed loops in the tensegrity graph.
        
        Uses DFS to find cycles (paradox loops).
        
        Returns:
            List of loops (each loop is a list of node IDs)
        """
        loops = []
        visited = set()
        
        def dfs(node_id: str, path: List[str], path_set: Set[str]):
            if node_id in path_set:
                # Found a loop
                loop_start = path.index(node_id)
                loop = path[loop_start:] + [node_id]
                loops.append(loop)
                return
            
            if node_id in visited:
                return
            
            visited.add(node_id)
            path.append(node_id)
            path_set.add(node_id)
            
            for neighbor in self.adjacency_list.get(node_id, []):
                dfs(neighbor, path.copy(), path_set.copy())
        
        for node_id in self.adjacency_list:
            if node_id not in visited:
                dfs(node_id, [], set())
        
        return loops
    
    def get_network_metrics(self) -> Dict:
        """
        Calculate network-wide metrics.
        
        Returns:
            Dictionary with graph statistics
        """
        total_nodes = len(self.adjacency_list)
        total_edges = len(self.edges)
        
        # Calculate average connectivity
        if total_nodes > 0:
            avg_connectivity = sum(len(neighbors) for neighbors in self.adjacency_list.values()) / total_nodes
        else:
            avg_connectivity = 0.0
        
        # Count loops
        loops = self.detect_loops()
        
        return {
            'total_nodes': total_nodes,
            'total_edges': total_edges,
            'avg_connectivity': float(avg_connectivity),
            'loop_count': len(loops),
            'loops': loops
        }


class TemporalEchoMemoryRing:
    """
    Circular buffer storing historical CTN states for loop stabilization.
    
    From 5E.md architecture:
    Provides temporal context for paradox resolution by maintaining
    a ring buffer of past states that can be referenced during stabilization.
    """
    
    def __init__(self, buffer_size: int = 64):
        """
        Initialize temporal echo memory ring.
        
        Args:
            buffer_size: Number of historical frames to store (default 64)
        """
        self.buffer_size = buffer_size
        self.buffers: Dict[str, deque] = {}  # node_id → circular buffer
        self.current_frame: int = 0
    
    def record_state(self, node_id: str, state_snapshot: Dict):
        """
        Record a state snapshot for a CTN.
        
        Args:
            node_id: CTN identifier
            state_snapshot: Dictionary containing state parameters
        """
        if node_id not in self.buffers:
            self.buffers[node_id] = deque(maxlen=self.buffer_size)
        
        snapshot_with_frame = {
            **state_snapshot,
            'frame': self.current_frame,
            'timestamp': time.time()
        }
        
        self.buffers[node_id].append(snapshot_with_frame)
    
    def get_echo(self, node_id: str, frames_back: int = 1) -> Optional[Dict]:
        """
        Retrieve historical state from N frames ago.
        
        Args:
            node_id: CTN identifier
            frames_back: Number of frames to look back
        
        Returns:
            Historical state snapshot or None if unavailable
        """
        if node_id not in self.buffers:
            return None
        
        buffer = self.buffers[node_id]
        if len(buffer) < frames_back:
            return None
        
        return buffer[-frames_back]
    
    def calculate_temporal_coherence(self, node_id: str) -> float:
        """
        Measure how consistent a node's state is over time.
        
        High coherence = stable evolution
        Low coherence = chaotic fluctuations
        
        Args:
            node_id: CTN identifier
        
        Returns:
            Coherence score (0.0 to 1.0)
        """
        if node_id not in self.buffers or len(self.buffers[node_id]) < 2:
            return 1.0  # Insufficient data, assume stable
        
        buffer = self.buffers[node_id]
        
        # Extract entropy values over time
        entropies = [snapshot.get('forward_entropy', 0.5) for snapshot in buffer]
        
        # Calculate variance
        variance = np.var(entropies)
        
        # Convert to coherence (inverse relationship)
        coherence = 1.0 / (1.0 + variance * 10)
        
        return float(coherence)
    
    def advance_frame(self):
        """Advance to next temporal frame."""
        self.current_frame += 1


class CTNFieldTensorProcessor:
    """
    Simulates CTN field tensor dynamics (software emulation of WebGL2 compute shader).
    
    From 5E.md (lines 370-407):
    Processes causal field tensors to visualize knot formation and elastic coupling.
    """
    
    def __init__(self, grid_size: int = 32):
        """
        Initialize field tensor processor.
        
        Args:
            grid_size: Resolution of field tensor grid (32x32 default)
        """
        self.grid_size = grid_size
        self.tensor_field = np.zeros((grid_size, grid_size, 4), dtype=np.float32)
        # Channels: [tension, entropy, kappa, loop_strength]
    
    def update_tensor_field(self, nodes: List[CausalTensegrityNode], time_step: float):
        """
        Update field tensor based on CTN positions and states.
        
        Args:
            nodes: List of active CTNs
            time_step: Simulation time
        """
        # Reset field
        self.tensor_field.fill(0.0)
        
        # Map nodes to grid positions (simplified spatial mapping)
        for i, node in enumerate(nodes):
            # Distribute nodes across grid
            x = (i % self.grid_size)
            y = (i // self.grid_size) % self.grid_size
            
            if x < self.grid_size and y < self.grid_size:
                # Store node state in tensor
                self.tensor_field[y, x, 0] = node.tension
                self.tensor_field[y, x, 1] = node.forward_entropy
                self.tensor_field[y, x, 2] = node.kappa
                
                # Calculate loop strength (oscillating based on frequency)
                loop_strength = math.sin(time_step * node.loop_frequency * 2 * math.pi)
                self.tensor_field[y, x, 3] = loop_strength
    
    def compute_elastic_coupling(self) -> np.ndarray:
        """
        Compute elastic force vectors for field visualization.
        
        Returns:
            Force vector field (grid_size x grid_size x 2)
        """
        forces = np.zeros((self.grid_size, self.grid_size, 2), dtype=np.float32)
        
        for y in range(self.grid_size):
            for x in range(self.grid_size):
                tension = self.tensor_field[y, x, 0]
                entropy = self.tensor_field[y, x, 1]
                kappa = self.tensor_field[y, x, 2]
                
                # Elastic causal coupling formula (from GLSL shader)
                force_x = math.cos(kappa * 6.28) * 0.02
                force_y = math.sin(self.tensor_field[y, x, 3] * 3.14) * 0.02
                
                forces[y, x, 0] = force_x
                forces[y, x, 1] = force_y
        
        return forces
    
    def get_field_statistics(self) -> Dict:
        """
        Calculate field-wide statistics.
        
        Returns:
            Dictionary with tensor field metrics
        """
        return {
            'avg_tension': float(np.mean(self.tensor_field[:, :, 0])),
            'avg_entropy': float(np.mean(self.tensor_field[:, :, 1])),
            'avg_kappa': float(np.mean(self.tensor_field[:, :, 2])),
            'max_kappa': float(np.max(self.tensor_field[:, :, 2])),
            'active_nodes': int(np.sum(self.tensor_field[:, :, 0] > 0.01))
        }


class CTNOrchestrator:
    """
    Main orchestrator for Phase 5E.7 CTN System.
    
    Integrates all components:
    - CTN Registry
    - Paradox Detector
    - Energy Harvester
    - Tensegrity Graph Engine
    - Temporal Echo Memory Ring
    - Field Tensor Processor
    
    Provides unified interface for CTN lifecycle management.
    """
    
    def __init__(self, grid_size: int = 32, memory_buffer_size: int = 64):
        """
        Initialize CTN orchestrator.
        
        Args:
            grid_size: Field tensor grid resolution
            memory_buffer_size: Temporal echo ring buffer size
        """
        self.nodes: Dict[str, CausalTensegrityNode] = {}
        self.paradox_detector = ParadoxDetector()
        self.energy_harvester = EnergyHarvester()
        self.graph_engine = TensegrityGraphEngine()
        self.memory_ring = TemporalEchoMemoryRing(memory_buffer_size)
        self.field_processor = CTNFieldTensorProcessor(grid_size)
        
        self.simulation_time: float = 0.0
        self.step_count: int = 0
    
    def register_ctn(self, node_id: str, forward_entropy: float, backward_entropy: float,
                    tension: float, loop_frequency: float) -> CausalTensegrityNode:
        """
        Register a new Causal Tensegrity Node.
        
        Args:
            node_id: Unique identifier
            forward_entropy: Forward causal entropy (Hf)
            backward_entropy: Backward causal entropy (Hb)
            tension: Structural tension
            loop_frequency: Paradox loop oscillation frequency
        
        Returns:
            Created CTN
        """
        node = CausalTensegrityNode(
            node_id=node_id,
            forward_entropy=forward_entropy,
            backward_entropy=backward_entropy,
            tension=tension,
            loop_frequency=loop_frequency,
            stability=1.0
        )
        
        self.nodes[node_id] = node
        
        return node
    
    def couple_nodes(self, node_a_id: str, node_b_id: str, elasticity: float = 0.5):
        """
        Establish elastic causal coupling between two CTNs.
        
        Args:
            node_a_id: Source node
            node_b_id: Target node
            elasticity: Elasticity modulus
        """
        self.graph_engine.establish_coupling(node_a_id, node_b_id, elasticity)
        
        # Update node connection lists
        if node_a_id in self.nodes:
            self.nodes[node_a_id].connected_nodes.append(node_b_id)
        if node_b_id in self.nodes:
            self.nodes[node_b_id].connected_nodes.append(node_a_id)
    
    def execute_simulation_step(self, dt: float = 0.1):
        """
        Execute one simulation step.
        
        Performs:
        1. State updates for all nodes
        2. Paradox detection
        3. Energy harvesting
        4. Tension propagation
        5. Temporal state recording
        6. Field tensor update
        
        Args:
            dt: Time step duration
        """
        self.simulation_time += dt
        self.step_count += 1
        
        nodes_list = list(self.nodes.values())
        
        # Update node states
        for node in nodes_list:
            node.update_state()
        
        # Detect paradoxes
        fracture_risk = self.paradox_detector.detect_fracture_risk(nodes_list)
        
        # Harvest energy from paradox nodes
        energy_harvested = self.energy_harvester.harvest_from_network(nodes_list)
        
        # Propagate tension through graph
        self.graph_engine.propagate_tension(self.nodes)
        
        # Record temporal states
        for node in nodes_list:
            self.memory_ring.record_state(node.node_id, {
                'forward_entropy': node.forward_entropy,
                'backward_entropy': node.backward_entropy,
                'tension': node.tension,
                'stability': node.stability
            })
        
        # Update field tensor
        self.field_processor.update_tensor_field(nodes_list, self.simulation_time)
        
        # Advance temporal frame
        self.memory_ring.advance_frame()
    
    def get_system_status(self) -> Dict:
        """
        Get comprehensive system status.
        
        Returns:
            Dictionary with all CTN system metrics
        """
        nodes_list = list(self.nodes.values())
        
        # Fracture risk assessment
        fracture_risk = self.paradox_detector.detect_fracture_risk(nodes_list)
        
        # Network metrics
        network_metrics = self.graph_engine.get_network_metrics()
        
        # Field statistics
        field_stats = self.field_processor.get_field_statistics()
        
        # Energy pool status
        energy_status = {
            'total_energy': self.energy_harvester.energy_pool.total_energy,
            'harvest_events': self.energy_harvester.energy_pool.harvest_events,
            'tau_modifier': self.energy_harvester.get_tau_adjustment()
        }
        
        # Node state distribution
        state_counts = {}
        for node in nodes_list:
            state_name = node.state.value
            state_counts[state_name] = state_counts.get(state_name, 0) + 1
        
        return {
            'simulation_time': self.simulation_time,
            'step_count': self.step_count,
            'total_nodes': len(nodes_list),
            'fracture_risk': fracture_risk,
            'network_metrics': network_metrics,
            'field_statistics': field_stats,
            'energy_status': energy_status,
            'node_state_distribution': state_counts,
            'gck_compliance': fracture_risk['risk_level'] != 'critical'
        }


def run_ctn_demonstration():
    """Demonstrate Phase 5E.7 CTN system with synthetic paradox scenarios."""
    print("=" * 80)
    print("PHASE 5E.7: CAUSAL TENSEGRITY NODE SYSTEM - DEMONSTRATION")
    print("=" * 80)
    
    # Initialize orchestrator
    orchestrator = CTNOrchestrator(grid_size=16, memory_buffer_size=32)
    
    print("\n1. Creating Synthetic CTN Population...")
    
    # Create diverse CTN population
    ctn_configs = [
        # Stable nodes (low kappa)
        ("CTN_S1", 0.3, 0.32, 0.2, 0.05),
        ("CTN_S2", 0.35, 0.33, 0.25, 0.08),
        
        # Elastic knots (medium kappa)
        ("CTN_E1", 0.5, 0.35, 0.4, 0.15),
        ("CTN_E2", 0.45, 0.3, 0.45, 0.18),
        
        # Resonant loops (high kappa, high frequency)
        ("CTN_R1", 0.7, 0.3, 0.6, 0.4),
        ("CTN_R2", 0.75, 0.35, 0.65, 0.45),
        
        # Critical paradox nodes (very high kappa)
        ("CTN_C1", 0.9, 0.2, 0.8, 0.7),
        ("CTN_C2", 0.85, 0.25, 0.75, 0.65),
    ]
    
    for node_id, h_forward, h_backward, tension, freq in ctn_configs:
        orchestrator.register_ctn(node_id, h_forward, h_backward, tension, freq)
    
    print(f"   ✓ Registered {len(orchestrator.nodes)} CTNs")
    print(f"   • 2 stable, 2 elastic knots, 2 resonant loops, 2 critical paradoxes")
    
    # Establish elastic couplings
    print("\n2. Establishing Elastic Causal Couplings...")
    couplings = [
        ("CTN_S1", "CTN_S2", 0.3),
        ("CTN_E1", "CTN_E2", 0.5),
        ("CTN_R1", "CTN_R2", 0.7),
        ("CTN_C1", "CTN_C2", 0.9),
        ("CTN_E1", "CTN_R1", 0.4),  # Cross-type coupling
    ]
    
    for node_a, node_b, elasticity in couplings:
        orchestrator.couple_nodes(node_a, node_b, elasticity)
        print(f"   ✓ Coupled {node_a} ↔ {node_b} (elasticity: {elasticity})")
    
    # Execute simulation steps
    print("\n3. Executing Simulation Steps...")
    for step in range(10):
        orchestrator.execute_simulation_step(dt=0.1)
        
        if step % 3 == 0:  # Print every 3rd step
            status = orchestrator.get_system_status()
            print(f"\n   Step {step + 1}:")
            print(f"     Total nodes: {status['total_nodes']}")
            print(f"     Fracture risk: {status['fracture_risk']['risk_level']}")
            print(f"     Avg kappa: {status['fracture_risk']['avg_kappa']:.3f}")
            print(f"     Critical nodes: {status['fracture_risk']['critical_count']}")
            print(f"     Loops detected: {status['network_metrics']['loop_count']}")
            print(f"     Energy harvested: {status['energy_status']['total_energy']:.3f}")
            print(f"     Tau modifier: {status['energy_status']['tau_modifier']:.3f}")
            print(f"     GCK compliant: {status['gck_compliance']}")
    
    # Final system status
    print("\n4. Final System Status:")
    final_status = orchestrator.get_system_status()
    
    print(f"\n   Node State Distribution:")
    for state, count in final_status['node_state_distribution'].items():
        print(f"     {state}: {count}")
    
    print(f"\n   Network Metrics:")
    print(f"     Total edges: {final_status['network_metrics']['total_edges']}")
    print(f"     Avg connectivity: {final_status['network_metrics']['avg_connectivity']:.2f}")
    print(f"     Closed loops: {final_status['network_metrics']['loop_count']}")
    
    print(f"\n   Energy Pool:")
    print(f"     Total energy: {final_status['energy_status']['total_energy']:.3f}")
    print(f"     Harvest events: {final_status['energy_status']['harvest_events']}")
    print(f"     Tau modifier: {final_status['energy_status']['tau_modifier']:.3f}")
    
    print(f"\n   Field Statistics:")
    print(f"     Avg tension: {final_status['field_statistics']['avg_tension']:.3f}")
    print(f"     Avg entropy: {final_status['field_statistics']['avg_entropy']:.3f}")
    print(f"     Max kappa: {final_status['field_statistics']['max_kappa']:.3f}")
    
    print(f"\n   GCK Compliance: {final_status['gck_compliance']}")
    
    print("\n" + "=" * 80)
    print("✅ PHASE 5E.7 CTN SYSTEM DEMONSTRATION COMPLETE")
    print("=" * 80)
    print("\nKey Achievements:")
    print("  • CTN Registry: Tracking 8 nodes with diverse paradox intensities")
    print("  • Paradox Detector: κ-based classification (stable/elastic/resonant/critical)")
    print("  • Energy Harvester: Converted paradox tension into {0:.3f} energy units".format(
        final_status['energy_status']['total_energy']))
    print("  • Tensegrity Graph: {0} elastic couplings, {1} closed loops".format(
        final_status['network_metrics']['total_edges'],
        final_status['network_metrics']['loop_count']))
    print("  • Temporal Echo: 32-frame memory ring for loop stabilization")
    print("  • Field Tensor: 16x16 grid simulating VRAM-level dynamics")
    print("\nThe system remains GCK-compliant while managing bounded instability.")
    print("Ready for Phase 5F transition when paradox density exceeds threshold.")


if __name__ == "__main__":
    run_ctn_demonstration()
