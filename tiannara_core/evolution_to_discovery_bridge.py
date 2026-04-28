"""
Evolution to Discovery Bridge

Compresses evolution outputs into structured hypotheses for DiscoveryLab.
Implements the Algorithmic Compression-Driven Reasoning (ACDR) concept
from the upgrades.txt file.
"""

from dataclasses import dataclass, field
from typing import List, Dict, Tuple, Optional
import hashlib
import json
from collections import defaultdict
import zlib
import logging
from .evolution.ir_representation import ExecutionIR
from .evolution.ecm_orchestrator import ECMOrchestrator


@dataclass
class EvolutionResult:
    """Result from the evolution system."""
    code_diff: str
    fitness_score: float
    input_output_pairs: List[Tuple[dict, dict]]
    execution_trace: Optional[dict] = None
    ir_representation: Optional[ExecutionIR] = None
    metadata: Dict = field(default_factory=dict)


@dataclass
class Hypothesis:
    """Structured hypothesis for DiscoveryLab."""
    id: str
    causal_rule: str
    confidence: float
    testable_predicate: str  # e.g., "if x > threshold and y contains 'v2', output shifts by +z"
    compressed_code: str = ""
    metadata: dict = field(default_factory=dict)


class EvolutionToDiscoveryBridge:
    """Translates evolution results into testable hypotheses for DiscoveryLab."""
    
    def __init__(self, compression_threshold: float = 0.75):
        self.compression_threshold = compression_threshold
        self.rule_cache: Dict[str, Hypothesis] = {}
        self.logger = logging.getLogger("tiannara.evolution.bridge")
        
        # Initialize ECM orchestrator for deeper analysis
        self.ecm_orchestrator = ECMOrchestrator()
    
    def translate(self, results: List[EvolutionResult]) -> List[Hypothesis]:
        """
        Translate evolution results into structured hypotheses.
        
        Args:
            results: List of evolution results
            
        Returns:
            List of structured hypotheses for DiscoveryLab
        """
        hypotheses = []
        
        for res in results:
            try:
                # 1. Extract behavioral deltas from input-output pairs
                deltas = self._extract_deltas(res.input_output_pairs)
                
                # 2. Compress behavior using ACDR principles (compression-driven reasoning)
                rule = self._compress_behavior(deltas, res.fitness_score)
                
                if not rule:
                    continue
                
                # 3. Generate testable predicate from the rule
                predicate = self._generate_predicate(deltas)
                
                # 4. Create hypothesis ID based on the rule
                rule_hash = hashlib.sha256(rule.encode()).hexdigest()[:12]
                
                # 5. Apply ACDR compression to the code as well
                compressed_code = self._compress_code(res.code_diff)
                
                # 6. Create the hypothesis
                h = Hypothesis(
                    id=rule_hash,
                    causal_rule=rule,
                    confidence=res.fitness_score,
                    testable_predicate=predicate,
                    compressed_code=compressed_code,
                    metadata={
                        "code_diff": res.code_diff,
                        "trace_hash": str(hash(str(res.execution_trace)) if res.execution_trace else ""),
                        "ir_nodes": len(res.ir_representation.nodes) if res.ir_representation else 0,
                        "delta_count": len(deltas)
                    }
                )
                
                hypotheses.append(h)
                
                # Cache the hypothesis
                self.rule_cache[h.id] = h
                
            except Exception as e:
                self.logger.error(f"Failed to translate evolution result: {e}")
                continue
        
        return hypotheses
    
    def _extract_deltas(self, io_pairs: List[Tuple[dict, dict]]) -> dict:
        """Map input changes → output changes to identify behavioral deltas."""
        deltas = defaultdict(list)
        
        for inp, out in io_pairs:
            for in_key, in_value in inp.items():
                for out_key, out_value in out.items():
                    # Capture the relationship between input and output changes
                    deltas[f"{in_key}→{out_key}"].append({
                        "input_val": in_value,
                        "output_val": out_value,
                        "input_type": type(in_value).__name__,
                        "output_type": type(out_value).__name__
                    })
        
        return dict(deltas)
    
    def _compress_behavior(self, deltas: dict, fitness: float) -> Optional[str]:
        """
        ACDR-style compression: keep only high-signal input→output mappings.
        Uses compression ratio as a proxy for algorithmic simplicity.
        """
        if fitness < self.compression_threshold:
            return None
        
        # Filter mappings that show consistent behavior
        compressed = {}
        
        for mapping, pairs in deltas.items():
            # Calculate variance in input-output relationships
            input_values = [p['input_val'] for p in pairs if isinstance(p['input_val'], (int, float))]
            output_values = [p['output_val'] for p in pairs if isinstance(p['output_val'], (int, float))]
            
            if len(input_values) > 1 and len(output_values) > 1:
                # Check if there's a consistent mathematical relationship
                if self._has_consistent_relationship(input_values, output_values):
                    relationship = self._identify_relationship(input_values, output_values)
                    compressed[mapping] = relationship
        
        if compressed:
            return json.dumps(compressed, indent=2)
        else:
            return None
    
    def _has_consistent_relationship(self, inputs: List[float], outputs: List[float]) -> bool:
        """Check if there's a consistent mathematical relationship between inputs and outputs."""
        if len(inputs) < 2:
            return False
        
        # Check for linear relationship
        diffs = []
        for i in range(1, len(inputs)):
            input_diff = inputs[i] - inputs[i-1]
            output_diff = outputs[i] - outputs[i-1]
            
            if input_diff != 0:
                rate_of_change = output_diff / input_diff
                diffs.append(rate_of_change)
        
        # If the rate of change is relatively consistent, we have a relationship
        if len(diffs) > 0:
            avg_rate = sum(diffs) / len(diffs)
            variance = sum((rate - avg_rate) ** 2 for rate in diffs) / len(diffs)
            return variance < 0.1  # Threshold for consistency
        
        return False
    
    def _identify_relationship(self, inputs: List[float], outputs: List[float]) -> str:
        """Identify the type of mathematical relationship."""
        if len(inputs) < 2:
            return "insufficient_data"
        
        # Check for linear relationship
        diffs = []
        for i in range(1, len(inputs)):
            input_diff = inputs[i] - inputs[i-1]
            output_diff = outputs[i] - outputs[i-1]
            
            if input_diff != 0:
                rate_of_change = output_diff / input_diff
                diffs.append(rate_of_change)
        
        if len(diffs) > 0:
            avg_rate = sum(diffs) / len(diffs)
            # Check if intercept is consistent
            intercepts = [outputs[i] - avg_rate * inputs[i] for i in range(len(inputs))]
            avg_intercept = sum(intercepts) / len(intercepts)
            
            return f"linear: output = {avg_rate:.2f} * input + {avg_intercept:.2f}"
        
        return "non_linear_or_complex"
    
    def _generate_predicate(self, deltas: dict) -> str:
        """Convert deltas into a testable logical statement."""
        conditions = []
        
        for mapping, pairs in deltas.items():
            if len(pairs) > 0:
                # Extract common patterns
                input_vals = [p['input_val'] for p in pairs if isinstance(p['input_val'], (int, float))]
                output_vals = [p['output_val'] for p in pairs if isinstance(p['output_val'], (int, float))]
                
                if input_vals:
                    min_in, max_in = min(input_vals), max(input_vals)
                    conditions.append(f"{mapping.split('→')[0]} in range[{min_in}, {max_in}]")
                
        return " AND ".join(conditions) if conditions else "behavior_observed"
    
    def _compress_code(self, code: str) -> str:
        """
        Apply ACDR-style compression to code.
        Uses zlib compression as a proxy for algorithmic compression.
        """
        if not code:
            return ""
        
        # Convert code to bytes
        code_bytes = code.encode('utf-8')
        
        # Compress using zlib
        compressed = zlib.compress(code_bytes)
        
        # Calculate compression ratio
        original_len = len(code_bytes)
        compressed_len = len(compressed)
        compression_ratio = compressed_len / original_len if original_len > 0 else 0
        
        # If compression is effective (ratio < 0.9), return compressed version
        # Otherwise return original
        if compression_ratio < 0.9:
            # For now, return the original code with a note about compression
            return f"// Compressed ratio: {compression_ratio:.2f}\n{code}"
        else:
            return code
    
    def get_cached_hypothesis(self, hypothesis_id: str) -> Optional[Hypothesis]:
        """Retrieve a cached hypothesis by ID."""
        return self.rule_cache.get(hypothesis_id)
    
    def update_cache(self, hypothesis: Hypothesis):
        """Update the cache with a new or updated hypothesis."""
        self.rule_cache[hypothesis.id] = hypothesis
    
    def analyze_evolution_result_with_ecm(self, evolution_result: EvolutionResult) -> Dict[str, Any]:
        """
        Perform deeper analysis of an evolution result using ECM.
        
        Args:
            evolution_result: An evolution result to analyze deeply
            
        Returns:
            Analysis results including causal models and hypotheses
        """
        if evolution_result.ir_representation is None:
            # If no IR representation, try to create one from the code diff
            try:
                from .evolution.ir_representation import IRConverter
                converter = IRConverter()
                ir = converter.convert_python_to_ir(evolution_result.code_diff)
                evolution_result.ir_representation = ir
            except Exception as e:
                self.logger.warning(f"Could not convert code to IR: {e}")
                return {}
        
        if evolution_result.ir_representation is None:
            return {}
        
        # Use ECM to analyze the IR
        # Create sample inputs based on the evolution result's I/O pairs
        if evolution_result.input_output_pairs:
            sample_input = evolution_result.input_output_pairs[0][0]
        else:
            sample_input = {"x": 1, "y": 1}  # default sample
        
        ecm_analysis = self.ecm_orchestrator.execute_ecm_cycle(
            evolution_result.code_diff,
            sample_input
        )
        
        return ecm_analysis


# Standalone function for easy integration
def translate_evolution_results(results: List[EvolutionResult]) -> List[Hypothesis]:
    """Standalone function to translate evolution results to hypotheses."""
    bridge = EvolutionToDiscoveryBridge()
    return bridge.translate(results)


# Example usage
if __name__ == "__main__":
    # Create sample evolution results
    sample_results = [
        EvolutionResult(
            code_diff="""
def evolved_function(x, y):
    result = x * 2 + y
    return result
""",
            fitness_score=0.85,
            input_output_pairs=[
                ({"x": 1, "y": 2}, {"result": 4}),
                ({"x": 3, "y": 4}, {"result": 10}),
                ({"x": 5, "y": 1}, {"result": 11})
            ],
            metadata={"generation": 5, "parent_id": "abc123"}
        ),
        EvolutionResult(
            code_diff="""
def evolved_function(x, y):
    if x > 5:
        result = x * 3
    else:
        result = x + y
    return result
""",
            fitness_score=0.92,
            input_output_pairs=[
                ({"x": 2, "y": 3}, {"result": 5}),
                ({"x": 7, "y": 1}, {"result": 21}),
                ({"x": 4, "y": 8}, {"result": 12})
            ],
            metadata={"generation": 7, "parent_id": "def456"}
        )
    ]
    
    # Create bridge and translate
    bridge = EvolutionToDiscoveryBridge()
    hypotheses = bridge.translate(sample_results)
    
    print(f"Translated {len(sample_results)} evolution results into {len(hypotheses)} hypotheses")
    
    for i, hypothesis in enumerate(hypotheses):
        print(f"\nHypothesis {i+1}:")
        print(f"  ID: {hypothesis.id}")
        print(f"  Confidence: {hypothesis.confidence}")
        print(f"  Rule: {hypothesis.causal_rule}")
        print(f"  Predicate: {hypothesis.testable_predicate}")
        print(f"  Metadata keys: {list(hypothesis.metadata.keys())}")
    
    # Demonstrate deeper ECM analysis
    print("\n" + "="*50)
    print("DEEP ECM ANALYSIS OF FIRST RESULT")
    print("="*50)
    
    ecm_analysis = bridge.analyze_evolution_result_with_ecm(sample_results[0])
    if ecm_analysis:
        print(f"Success: {ecm_analysis.get('success', False)}")
        print(f"Final IR nodes: {ecm_analysis.get('final_ir_nodes', 0)}")
        print(f"Generated hypotheses: {len(ecm_analysis.get('hypotheses', []))}")
        
        for j, hyp in enumerate(ecm_analysis.get('hypotheses', [])):
            print(f"  ECM Hypothesis {j+1}: {hyp.get('type', 'unknown')} - {hyp.get('description', '')[:50]}...")