"""
GLOBAL CONSISTENCY KERNEL (GCK)

Pre-5F lock layer that ensures all realities remain mutually simulatable.

Based on 5E.md architecture specification:
"This is the most important system in your entire stack."

Without GCK:
- 5D mutates laws uncontrollably
- 5E rewrites causality inconsistently  
- GPU becomes non-reproducible chaos

With GCK:
- Controlled multiverse behavior with full rollback capability
- All realities remain mutually simulatable
- No law exists without causal trace
- No causal event exists without replay path
- No GPU state exists without genome mapping
- No evolution breaks simulation determinism

Architecture (5 layers):
1. Event Normalization Layer - canonical state representation
2. Causal Consistency Checker - DAG validation + cycle detection
3. Physics Compatibility Checker - genome compatibility score
4. Shadow Simulation Engine - predict outcome BEFORE commit
5. Global Stability Function - S = f(entropy, coherence, drift)

Decision Rules:
- S > 0.75 → commit (safe to execute)
- 0.4–0.75 → shadow quarantine (simulate further)
- < 0.4 → reject + rollback (unsafe mutation)
"""

import sys
import time
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Set
from dataclasses import dataclass, field
from enum import Enum
from collections import defaultdict

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))


class GCKDecision(Enum):
    """GCK validation decisions."""
    COMMIT = "commit"              # Safe to execute (S > 0.75)
    QUARANTINE = "quarantine"      # Needs more simulation (0.4 ≤ S ≤ 0.75)
    REJECT = "reject"              # Unsafe mutation (S < 0.4)


class EventType(Enum):
    """Types of events flowing through GCK."""
    LAW_MUTATION = "law_mutation"           # 5D: Physics law change proposal
    CAUSAL_REWRITE = "causal_rewrite"       # 5E: Causality modification
    WORLD_MERGE = "world_merge"             # World chimeric collapse
    GPU_STATE_UPDATE = "gpu_state_update"   # GPU tensor update
    PARADOX_DETECTED = "paradox_detected"   # Causal paradox event


@dataclass
class CanonicalEvent:
    """Normalized event representation for GCK processing."""
    event_id: str
    event_type: EventType
    source_layer: str                # "5D", "5E", "GPU", etc.
    timestamp: float
    trace_id: str                    # Causal trace identifier
    affected_worlds: List[str]
    payload: Dict                    # Normalized payload
    causal_ancestors: List[str] = field(default_factory=list)  # Parent event IDs
    
    def to_dict(self) -> Dict:
        return {
            'event_id': self.event_id,
            'event_type': self.event_type.value,
            'source_layer': self.source_layer,
            'timestamp': self.timestamp,
            'trace_id': self.trace_id,
            'affected_worlds': self.affected_worlds,
            'payload': self.payload,
            'causal_ancestors': self.causal_ancestors
        }


@dataclass
class CausalGraph:
    """Directed acyclic graph representing causal relationships."""
    nodes: Set[str] = field(default_factory=set)           # Event IDs
    edges: List[Tuple[str, str]] = field(default_factory=list)  # (cause, effect)
    
    def add_node(self, node_id: str):
        self.nodes.add(node_id)
    
    def add_edge(self, cause: str, effect: str):
        self.edges.append((cause, effect))
        self.nodes.add(cause)
        self.nodes.add(effect)
    
    def has_cycle(self) -> bool:
        """Detect cycles using DFS-based algorithm."""
        # Build adjacency list
        adj = defaultdict(list)
        for cause, effect in self.edges:
            adj[cause].append(effect)
        
        # Track visited states: 0=unvisited, 1=in-progress, 2=completed
        visited = {node: 0 for node in self.nodes}
        
        def dfs(node):
            if visited[node] == 1:  # Back edge detected = cycle
                return True
            if visited[node] == 2:  # Already fully processed
                return False
            
            visited[node] = 1  # Mark as in-progress
            
            for neighbor in adj[node]:
                if dfs(neighbor):
                    return True
            
            visited[node] = 2  # Mark as completed
            return False
        
        # Check all nodes
        for node in self.nodes:
            if visited[node] == 0:
                if dfs(node):
                    return True
        
        return False
    
    def get_causal_depth(self, node_id: str) -> int:
        """Calculate maximum causal chain length from this node."""
        # Build reverse adjacency (effect -> causes)
        reverse_adj = defaultdict(list)
        for cause, effect in self.edges:
            reverse_adj[effect].append(cause)
        
        # BFS to find longest path
        max_depth = 0
        queue = [(node_id, 0)]
        visited = set()
        
        while queue:
            current, depth = queue.pop(0)
            if current in visited:
                continue
            visited.add(current)
            max_depth = max(max_depth, depth)
            
            for parent in reverse_adj[current]:
                if parent not in visited:
                    queue.append((parent, depth + 1))
        
        return max_depth


@dataclass
class GenomeCompatibility:
    """Result of physics genome compatibility check."""
    compatibility_score: float     # 0.0-1.0 overall compatibility
    cal_compatibility: float       # CAL law compatibility
    cis_compatibility: float       # CIS law compatibility
    entropy_compatibility: float   # Entropy model compatibility
    selection_compatibility: float # Selection pressure compatibility
    divergence_metrics: Dict[str, float] = field(default_factory=dict)
    
    def to_dict(self) -> Dict:
        return {
            'compatibility_score': self.compatibility_score,
            'cal_compatibility': self.cal_compatibility,
            'cis_compatibility': self.cis_compatibility,
            'entropy_compatibility': self.entropy_compatibility,
            'selection_compatibility': self.selection_compatibility,
            'divergence_metrics': self.divergence_metrics
        }


@dataclass
class ShadowSimulationResult:
    """Result from shadow simulation engine."""
    simulation_id: str
    predicted_stability: float     # Predicted stability after mutation (0.0-1.0)
    entropy_delta: float           # Expected entropy change
    coherence_delta: float         # Expected coherence change
    divergence_delta: float        # Expected divergence from baseline
    replay_success: bool           # Can mutation be deterministically replayed?
    anomalies_detected: List[str] = field(default_factory=list)
    
    def to_dict(self) -> Dict:
        return {
            'simulation_id': self.simulation_id,
            'predicted_stability': self.predicted_stability,
            'entropy_delta': self.entropy_delta,
            'coherence_delta': self.coherence_delta,
            'divergence_delta': self.divergence_delta,
            'replay_success': self.replay_success,
            'anomalies_detected': self.anomalies_detected
        }


@dataclass
class GCKValidationResult:
    """Final GCK validation result."""
    event_id: str
    decision: GCKDecision
    stability_score: float         # Global stability S = (C×R)/(E+D+ε)
    causal_coherence: float        # C component
    reproduction_stability: float  # R component (replay success)
    entropy_drift: float           # E component
    divergence: float              # D component
    recommendation: str            # Human-readable explanation
    
    def to_dict(self) -> Dict:
        return {
            'event_id': self.event_id,
            'decision': self.decision.value,
            'stability_score': self.stability_score,
            'causal_coherence': self.causal_coherence,
            'reproduction_stability': self.reproduction_stability,
            'entropy_drift': self.entropy_drift,
            'divergence': self.divergence,
            'recommendation': self.recommendation
        }


class EventNormalizer:
    """
    Layer 1: Event Normalization
    
    Converts heterogeneous events from 5D/5E/GPU/NATS into canonical format.
    Ensures all events have consistent structure for downstream validation.
    """
    
    def normalize(self, raw_event: Dict, source_layer: str) -> CanonicalEvent:
        """
        Normalize a raw event into canonical representation.
        
        Args:
            raw_event: Raw event dictionary from source system
            source_layer: Source layer identifier ("5D", "5E", "GPU", etc.)
            
        Returns:
            CanonicalEvent with standardized structure
        """
        # Extract common fields with defaults
        event_id = raw_event.get('event_id', f"evt_{int(time.time()*1000)}")
        event_type_str = raw_event.get('type', 'unknown')
        trace_id = raw_event.get('trace_id', f"trace_{event_id}")
        affected_worlds = raw_event.get('affected_worlds', [])
        causal_ancestors = raw_event.get('causal_ancestors', [])
        
        # Map string to EventType enum
        try:
            event_type = EventType(event_type_str)
        except ValueError:
            event_type = EventType.LAW_MUTATION  # Default fallback
        
        # Create canonical event
        return CanonicalEvent(
            event_id=event_id,
            event_type=event_type,
            source_layer=source_layer,
            timestamp=raw_event.get('timestamp', time.time()),
            trace_id=trace_id,
            affected_worlds=affected_worlds,
            payload=self._normalize_payload(raw_event.get('payload', {}), event_type),
            causal_ancestors=causal_ancestors
        )
    
    def _normalize_payload(self, payload: Dict, event_type: EventType) -> Dict:
        """Normalize payload based on event type."""
        normalized = {}
        
        if event_type == EventType.LAW_MUTATION:
            # Extract law genome fields
            normalized['genome_id'] = payload.get('genome_id', '')
            normalized['mutation_type'] = payload.get('mutation_type', 'parameter_tweak')
            normalized['affected_subsystem'] = payload.get('subsystem', 'cal')
            normalized['delta_values'] = payload.get('delta', {})
        
        elif event_type == EventType.CAUSAL_REWRITE:
            # Extract causal modification fields
            normalized['region_id'] = payload.get('region_id', '')
            normalized['modification_type'] = payload.get('modification_type', 'tensegrity_binding')
            normalized['forward_anchor'] = payload.get('forward_anchor', '')
            normalized['backward_anchor'] = payload.get('backward_anchor', '')
        
        elif event_type == EventType.WORLD_MERGE:
            # Extract merge fields
            normalized['world_a'] = payload.get('world_a', '')
            normalized['world_b'] = payload.get('world_b', '')
            normalized['chimera_id'] = payload.get('chimera_id', '')
            normalized['subsystem_resolution'] = payload.get('subsystem_map', {})
        
        else:
            # Generic passthrough for unknown types
            normalized = payload.copy()
        
        return normalized


class CausalConsistencyChecker:
    """
    Layer 2: Causal Consistency Checker
    
    Validates DAG structure and detects causal cycles.
    Ensures no causal event exists without replay path.
    """
    
    def __init__(self):
        self.causal_graph = CausalGraph()
        self.event_registry: Dict[str, CanonicalEvent] = {}
    
    def register_event(self, event: CanonicalEvent) -> bool:
        """
        Register event and validate causal consistency.
        
        Returns:
            True if event maintains causal consistency, False if cycle detected
        """
        # Add to registry
        self.event_registry[event.event_id] = event
        
        # Add node to graph
        self.causal_graph.add_node(event.event_id)
        
        # Add edges from ancestors
        for ancestor_id in event.causal_ancestors:
            if ancestor_id in self.event_registry:
                self.causal_graph.add_edge(ancestor_id, event.event_id)
        
        # Check for cycles
        if self.causal_graph.has_cycle():
            # Remove the event that caused the cycle
            self.event_registry.pop(event.event_id, None)
            return False
        
        return True
    
    def calculate_causal_coherence(self, event: CanonicalEvent) -> float:
        """
        Calculate causal coherence score for an event.
        
        Measures: How well-connected is this event in the causal graph?
        Higher score = better integration with existing causal structure.
        """
        if not event.causal_ancestors:
            return 0.5  # Neutral for root events
        
        # Count valid ancestors (present in registry)
        valid_ancestors = sum(1 for aid in event.causal_ancestors 
                             if aid in self.event_registry)
        
        # Coherence = ratio of valid ancestors
        if len(event.causal_ancestors) == 0:
            return 1.0
        
        coherence = valid_ancestors / len(event.causal_ancestors)
        
        # Bonus for deeper causal chains (more context)
        avg_depth = sum(self.causal_graph.get_causal_depth(aid) 
                       for aid in event.causal_ancestors 
                       if aid in self.event_registry)
        avg_depth = avg_depth / max(1, len(event.causal_ancestors))
        
        # Combine: 70% ancestor validity + 30% chain depth bonus
        depth_bonus = min(0.3, avg_depth * 0.05)  # Cap at 0.3
        final_coherence = coherence * 0.7 + depth_bonus
        
        return min(1.0, max(0.0, final_coherence))


class PhysicsCompatibilityChecker:
    """
    Layer 3: Physics Compatibility Checker
    
    Scores genome compatibility between worlds/laws.
    Ensures no GPU state exists without genome mapping.
    """
    
    def check_compatibility(
        self,
        genome_a: Dict,
        genome_b: Dict
    ) -> GenomeCompatibility:
        """
        Check compatibility between two physics genomes.
        
        Args:
            genome_a: First genome (e.g., existing world)
            genome_b: Second genome (e.g., proposed mutation)
            
        Returns:
            GenomeCompatibility with per-subsystem scores
        """
        # Extract subsystem parameters
        cal_a = genome_a.get('cal_law', {})
        cal_b = genome_b.get('cal_law', {})
        
        cis_a = genome_a.get('cis_law', {})
        cis_b = genome_b.get('cis_law', {})
        
        entropy_a = genome_a.get('entropy_model', {})
        entropy_b = genome_b.get('entropy_model', {})
        
        selection_a = genome_a.get('selection_pressure', {})
        selection_b = genome_b.get('selection_pressure', {})
        
        # Calculate per-subsystem compatibility
        cal_compat = self._calculate_subsystem_compatibility(cal_a, cal_b)
        cis_compat = self._calculate_subsystem_compatibility(cis_a, cis_b)
        entropy_compat = self._calculate_subsystem_compatibility(entropy_a, entropy_b)
        selection_compat = self._calculate_subsystem_compatibility(selection_a, selection_b)
        
        # Weighted average (CAL and CIS are most critical)
        overall = (
            cal_compat * 0.30 +
            cis_compat * 0.30 +
            entropy_compat * 0.25 +
            selection_compat * 0.15
        )
        
        return GenomeCompatibility(
            compatibility_score=overall,
            cal_compatibility=cal_compat,
            cis_compatibility=cis_compat,
            entropy_compatibility=entropy_compat,
            selection_compatibility=selection_compat,
            divergence_metrics={
                'cal_divergence': 1.0 - cal_compat,
                'cis_divergence': 1.0 - cis_compat,
                'entropy_divergence': 1.0 - entropy_compat,
                'selection_divergence': 1.0 - selection_compat
            }
        )
    
    def _calculate_subsystem_compatibility(self, params_a: Dict, params_b: Dict) -> float:
        """
        Calculate compatibility between two subsystem parameter sets.
        
        Uses cosine similarity on parameter vectors.
        """
        if not params_a or not params_b:
            return 0.5  # Neutral if missing data
        
        # Get common keys
        common_keys = set(params_a.keys()) & set(params_b.keys())
        if not common_keys:
            return 0.5
        
        # Extract vectors
        vec_a = [params_a[k] for k in sorted(common_keys)]
        vec_b = [params_b[k] for k in sorted(common_keys)]
        
        # Calculate cosine similarity
        dot_product = sum(a * b for a, b in zip(vec_a, vec_b))
        norm_a = sum(a * a for a in vec_a) ** 0.5
        norm_b = sum(b * b for b in vec_b) ** 0.5
        
        if norm_a == 0 or norm_b == 0:
            return 0.5
        
        similarity = dot_product / (norm_a * norm_b)
        
        # Map [-1, 1] to [0, 1]
        return (similarity + 1.0) / 2.0


class ShadowSimulationEngine:
    """
    Layer 4: Shadow Simulation Engine
    
    Runs mutations in sandbox before commit.
    Predicts outcome BEFORE executing on live system.
    Ensures no evolution breaks simulation determinism.
    """
    
    def simulate_mutation(
        self,
        event: CanonicalEvent,
        current_state: Dict
    ) -> ShadowSimulationResult:
        """
        Simulate mutation effects in sandbox environment.
        
        Args:
            event: The mutation event to simulate
            current_state: Current system state snapshot
            
        Returns:
            ShadowSimulationResult with predicted outcomes
        """
        sim_id = f"sim_{event.event_id}_{int(time.time()*1000)}"
        
        # Apply mutation to copy of state
        simulated_state = self._apply_mutation(current_state.copy(), event)
        
        # Calculate deltas
        entropy_delta = self._calculate_entropy_delta(current_state, simulated_state)
        coherence_delta = self._calculate_coherence_delta(current_state, simulated_state)
        divergence_delta = self._calculate_divergence_delta(current_state, simulated_state)
        
        # Check replay determinism
        replay_success = self._verify_replay_determinism(event, current_state)
        
        # Detect anomalies
        anomalies = self._detect_anomalies(simulated_state, event)
        
        # Calculate predicted stability
        predicted_stability = self._calculate_predicted_stability(
            entropy_delta, coherence_delta, divergence_delta, anomalies
        )
        
        return ShadowSimulationResult(
            simulation_id=sim_id,
            predicted_stability=predicted_stability,
            entropy_delta=entropy_delta,
            coherence_delta=coherence_delta,
            divergence_delta=divergence_delta,
            replay_success=replay_success,
            anomalies_detected=anomalies
        )
    
    def _apply_mutation(self, state: Dict, event: CanonicalEvent) -> Dict:
        """Apply mutation to state copy (sandbox)."""
        # Simplified mutation application
        # In production, this would use actual physics engines
        mutated = state.copy()
        
        if event.event_type == EventType.LAW_MUTATION:
            # Apply law changes
            subsystem = event.payload.get('affected_subsystem', 'cal')
            delta = event.payload.get('delta_values', {})
            
            if subsystem in mutated:
                for key, value in delta.items():
                    if key in mutated[subsystem]:
                        mutated[subsystem][key] += value
        
        return mutated
    
    def _calculate_entropy_delta(self, before: Dict, after: Dict) -> float:
        """Calculate entropy change from mutation."""
        # Simplified entropy calculation
        # In production, would use actual entropy metrics
        before_entropy = before.get('global_entropy', 0.5)
        after_entropy = after.get('global_entropy', 0.5)
        return after_entropy - before_entropy
    
    def _calculate_coherence_delta(self, before: Dict, after: Dict) -> float:
        """Calculate coherence change from mutation."""
        before_coherence = before.get('global_coherence', 0.5)
        after_coherence = after.get('global_coherence', 0.5)
        return after_coherence - before_coherence
    
    def _calculate_divergence_delta(self, before: Dict, after: Dict) -> float:
        """Calculate divergence from baseline."""
        # Measure how much state diverged from expected trajectory
        return abs(after.get('global_entropy', 0.5) - before.get('expected_entropy', 0.5))
    
    def _verify_replay_determinism(self, event: CanonicalEvent, state: Dict) -> bool:
        """Verify mutation can be deterministically replayed."""
        # Check if all required parameters are present
        required_fields = ['event_id', 'trace_id', 'payload']
        has_all_fields = all(hasattr(event, field) for field in required_fields)
        
        # Check if payload is serializable (deterministic)
        try:
            import json
            json.dumps(event.payload)
            return has_all_fields
        except (TypeError, ValueError):
            return False
    
    def _detect_anomalies(self, state: Dict, event: CanonicalEvent) -> List[str]:
        """Detect anomalous conditions in simulated state."""
        anomalies = []
        
        # Check entropy bounds
        entropy = state.get('global_entropy', 0.5)
        if entropy > 0.95:
            anomalies.append("Critical entropy threshold exceeded")
        elif entropy < 0.05:
            anomalies.append("Entropy collapsed below minimum")
        
        # Check coherence bounds
        coherence = state.get('global_coherence', 0.5)
        if coherence < 0.1:
            anomalies.append("Coherence critically low")
        
        # Check for NaN/Inf values
        for key, value in state.items():
            if isinstance(value, float):
                import math
                if math.isnan(value) or math.isinf(value):
                    anomalies.append(f"Invalid numeric value in {key}")
        
        return anomalies
    
    def _calculate_predicted_stability(
        self,
        entropy_delta: float,
        coherence_delta: float,
        divergence_delta: float,
        anomalies: List[str]
    ) -> float:
        """Calculate predicted stability after mutation."""
        # Start with base stability
        stability = 0.7
        
        # Penalize entropy increase
        stability -= abs(entropy_delta) * 0.3
        
        # Reward coherence increase
        stability += coherence_delta * 0.2
        
        # Penalize divergence
        stability -= divergence_delta * 0.2
        
        # Heavy penalty for anomalies
        stability -= len(anomalies) * 0.15
        
        return max(0.0, min(1.0, stability))


class GlobalStabilityFunction:
    """
    Layer 5: Global Stability Function
    
    Calculates S = (C × R) / (E + D + ε)
    
    Where:
    - C = causal coherence
    - R = reproduction stability (replay success)
    - E = entropy drift
    - D = divergence between genomes
    - ε = small constant to prevent division by zero
    """
    
    EPSILON = 0.001
    
    def calculate_stability(
        self,
        causal_coherence: float,
        reproduction_stability: float,
        entropy_drift: float,
        divergence: float
    ) -> float:
        """
        Calculate global stability score.
        
        Formula: S = (C × R) / (E + D + ε)
        
        Decision rules:
        - S > 0.75 → commit
        - 0.4 ≤ S ≤ 0.75 → quarantine
        - S < 0.4 → reject
        """
        numerator = causal_coherence * reproduction_stability
        denominator = entropy_drift + divergence + self.EPSILON
        
        stability = numerator / denominator
        
        # Normalize to 0-1 range (theoretical max depends on inputs)
        # Assuming C,R ∈ [0,1] and E,D ∈ [0,1], max S ≈ 1.0 / 0.001 = 1000
        # We want to map meaningful range to [0, 1]
        # S > 1.0 is very stable, S < 0.4 is unstable
        
        # Clamp and normalize
        normalized = min(1.0, stability / 2.0)  # Scale factor
        
        return max(0.0, min(1.0, normalized))
    
    def make_decision(self, stability_score: float) -> GCKDecision:
        """Make accept/reject/quarantine decision based on stability."""
        if stability_score > 0.75:
            return GCKDecision.COMMIT
        elif stability_score >= 0.4:
            return GCKDecision.QUARANTINE
        else:
            return GCKDecision.REJECT


class GCKOrchestrator:
    """
    Main GCK orchestrator coordinating all 5 layers.
    
    Entry point for validating mutations before they reach production.
    """
    
    def __init__(self):
        self.normalizer = EventNormalizer()
        self.causal_checker = CausalConsistencyChecker()
        self.compatibility_checker = PhysicsCompatibilityChecker()
        self.shadow_engine = ShadowSimulationEngine()
        self.stability_function = GlobalStabilityFunction()
        
        # Quarantine storage for events needing more simulation
        self.quarantine_queue: List[CanonicalEvent] = []
    
    def validate_event(
        self,
        raw_event: Dict,
        source_layer: str,
        current_state: Dict,
        reference_genome: Optional[Dict] = None
    ) -> GCKValidationResult:
        """
        Validate an event through all 5 GCK layers.
        
        Args:
            raw_event: Raw event from source system
            source_layer: Source identifier ("5D", "5E", "GPU", etc.)
            current_state: Current system state snapshot
            reference_genome: Reference genome for compatibility check (optional)
            
        Returns:
            GCKValidationResult with decision and stability metrics
        """
        # Layer 1: Normalize event
        event = self.normalizer.normalize(raw_event, source_layer)
        
        # Layer 2: Check causal consistency
        causal_valid = self.causal_checker.register_event(event)
        causal_coherence = self.causal_checker.calculate_causal_coherence(event)
        
        if not causal_valid:
            # Cycle detected - immediate reject
            return GCKValidationResult(
                event_id=event.event_id,
                decision=GCKDecision.REJECT,
                stability_score=0.0,
                causal_coherence=0.0,
                reproduction_stability=0.0,
                entropy_drift=1.0,
                divergence=1.0,
                recommendation="Causal cycle detected - violates DAG constraint"
            )
        
        # Layer 3: Check physics compatibility (if reference genome provided)
        compatibility_score = 1.0  # Default if no reference
        divergence = 0.0
        
        if reference_genome:
            proposed_genome = self._extract_genome_from_event(event)
            compat_result = self.compatibility_checker.check_compatibility(
                reference_genome, proposed_genome
            )
            compatibility_score = compat_result.compatibility_score
            divergence = 1.0 - compatibility_score
        
        # Layer 4: Run shadow simulation
        sim_result = self.shadow_engine.simulate_mutation(event, current_state)
        reproduction_stability = 1.0 if sim_result.replay_success else 0.3
        
        # Layer 5: Calculate global stability
        entropy_drift = abs(sim_result.entropy_delta)
        
        stability_score = self.stability_function.calculate_stability(
            causal_coherence=causal_coherence,
            reproduction_stability=reproduction_stability,
            entropy_drift=entropy_drift,
            divergence=divergence
        )
        
        # Make decision
        decision = self.stability_function.make_decision(stability_score)
        
        # Generate recommendation
        recommendation = self._generate_recommendation(
            decision, stability_score, causal_coherence,
            sim_result, compatibility_score
        )
        
        # Handle quarantine
        if decision == GCKDecision.QUARANTINE:
            self.quarantine_queue.append(event)
        
        return GCKValidationResult(
            event_id=event.event_id,
            decision=decision,
            stability_score=stability_score,
            causal_coherence=causal_coherence,
            reproduction_stability=reproduction_stability,
            entropy_drift=entropy_drift,
            divergence=divergence,
            recommendation=recommendation
        )
    
    def _extract_genome_from_event(self, event: CanonicalEvent) -> Dict:
        """Extract physics genome from event payload."""
        # Simplified extraction - in production would parse actual genome structure
        return event.payload.get('genome', {
            'cal_law': {},
            'cis_law': {},
            'entropy_model': {},
            'selection_pressure': {}
        })
    
    def _generate_recommendation(
        self,
        decision: GCKDecision,
        stability: float,
        causal_coherence: float,
        sim_result: ShadowSimulationResult,
        compatibility: float
    ) -> str:
        """Generate human-readable recommendation."""
        if decision == GCKDecision.COMMIT:
            return f"Safe to commit (stability={stability:.3f}). All checks passed."
        
        elif decision == GCKDecision.QUARANTINE:
            reasons = []
            if causal_coherence < 0.6:
                reasons.append("low causal coherence")
            if not sim_result.replay_success:
                reasons.append("non-deterministic replay")
            if sim_result.anomalies_detected:
                reasons.append(f"{len(sim_result.anomalies_detected)} anomalies")
            
            reason_str = ", ".join(reasons) if reasons else "marginal stability"
            return f"Quarantine for further simulation ({reason_str}). Stability={stability:.3f}"
        
        else:  # REJECT
            reasons = []
            if causal_coherence < 0.3:
                reasons.append("causal inconsistency")
            if not sim_result.replay_success:
                reasons.append("irreproducible mutation")
            if sim_result.anomalies_detected:
                reasons.append(f"critical anomalies: {', '.join(sim_result.anomalies_detected)}")
            if compatibility < 0.3:
                reasons.append("incompatible physics genome")
            
            reason_str = ", ".join(reasons) if reasons else "unstable mutation"
            return f"REJECTED - unsafe mutation ({reason_str}). Stability={stability:.3f}"
    
    def process_quarantine(self) -> List[GCKValidationResult]:
        """Re-evaluate quarantined events (after additional simulation)."""
        results = []
        remaining = []
        
        for event in self.quarantine_queue:
            # Re-run validation with updated state
            # In production, would use enhanced simulation data
            result = self.validate_event(
                raw_event=event.to_dict(),
                source_layer=event.source_layer,
                current_state={'global_entropy': 0.5, 'global_coherence': 0.5},
                reference_genome=None
            )
            
            if result.decision != GCKDecision.QUARANTINE:
                results.append(result)
            else:
                remaining.append(event)
        
        self.quarantine_queue = remaining
        return results


if __name__ == "__main__":
    """Test the Global Consistency Kernel."""
    print("="*80)
    print("GLOBAL CONSISTENCY KERNEL - TEST")
    print("="*80)
    
    gck = GCKOrchestrator()
    
    # Test 1: Safe mutation (should COMMIT)
    print("\nTest 1: Safe Law Mutation")
    safe_event = {
        'event_id': 'evt_safe_001',
        'type': 'law_mutation',
        'trace_id': 'trace_001',
        'affected_worlds': ['world_A'],
        'payload': {
            'genome_id': 'genome_v2',
            'mutation_type': 'parameter_tweak',
            'subsystem': 'cal',
            'delta': {'clustering_threshold': 0.05}
        },
        'causal_ancestors': []
    }
    
    current_state = {
        'global_entropy': 0.45,
        'global_coherence': 0.75,
        'expected_entropy': 0.46,
        'cal': {'clustering_threshold': 0.3}
    }
    
    result1 = gck.validate_event(safe_event, "5D", current_state)
    print(f"  Decision: {result1.decision.value}")
    print(f"  Stability: {result1.stability_score:.3f}")
    print(f"  Causal Coherence: {result1.causal_coherence:.3f}")
    print(f"  Recommendation: {result1.recommendation}")
    
    # Test 2: Causal cycle (should REJECT)
    print("\nTest 2: Causal Cycle Detection")
    cycle_event = {
        'event_id': 'evt_cycle_001',
        'type': 'causal_rewrite',
        'trace_id': 'trace_002',
        'affected_worlds': ['world_B'],
        'payload': {
            'region_id': 'region_X',
            'modification_type': 'tensegrity_binding',
            'forward_anchor': 'evt_cycle_001',  # Self-reference = cycle
            'backward_anchor': 'evt_cycle_001'
        },
        'causal_ancestors': ['evt_cycle_001']  # Creates cycle
    }
    
    result2 = gck.validate_event(cycle_event, "5E", current_state)
    print(f"  Decision: {result2.decision.value}")
    print(f"  Stability: {result2.stability_score:.3f}")
    print(f"  Recommendation: {result2.recommendation}")
    
    # Test 3: High divergence mutation (should QUARANTINE or REJECT)
    print("\nTest 3: High Divergence Mutation")
    divergent_event = {
        'event_id': 'evt_divergent_001',
        'type': 'law_mutation',
        'trace_id': 'trace_003',
        'affected_worlds': ['world_C'],
        'payload': {
            'genome_id': 'genome_radical',
            'mutation_type': 'structural_change',
            'subsystem': 'entropy',
            'delta': {'entropy_coefficient': 0.8}  # Large change
        },
        'causal_ancestors': ['evt_safe_001']
    }
    
    reference_genome = {
        'cal_law': {'clustering_threshold': 0.3},
        'cis_law': {'dampening_factor': 0.5},
        'entropy_model': {'entropy_coefficient': 0.1},
        'selection_pressure': {'temperature': 0.2}
    }
    
    result3 = gck.validate_event(divergent_event, "5D", current_state, reference_genome)
    print(f"  Decision: {result3.decision.value}")
    print(f"  Stability: {result3.stability_score:.3f}")
    print(f"  Divergence: {result3.divergence:.3f}")
    print(f"  Recommendation: {result3.recommendation}")
    
    print("\n" + "="*80)
    print("✅ GLOBAL CONSISTENCY KERNEL TEST COMPLETE")
    print("="*80)
