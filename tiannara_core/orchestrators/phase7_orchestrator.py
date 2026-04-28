"""
Phase 7 Orchestrator - Updated for Phase 8 Integration

Integrates all advanced components:
- Neural Trace Embeddings (DEG)
- Graph-based ECM Engine
- Parallel Evolution Engine
- Causal Memory Graph
- Adaptive Mutation Intelligence
"""

from typing import Dict, Any, List, Optional
import logging
import zlib
import time
from concurrent.futures import ThreadPoolExecutor

from tiannara_core.sandbox.executor import run_in_sandbox
from tiannara_core.evolution.reverse_engine import BehaviorReverseEngineer
from tiannara_core.evolution_to_discovery_bridge import EvolutionToDiscoveryBridge
from tiannara_core.memory.store import MemoryStore
from tiannara_core.srct.router import SRCTRouter

# Phase 8 components
from tiannara_core.deg.trace_embedder import DEGTrainer, create_deg_trainer
from tiannara_core.ecm.graph_engine import ECMGraphEngine, MutationOperator
from tiannara_core.evolution.parallel_engine import ParallelEvolution
from tiannara_core.memory.causal_graph import CausalMemory
from tiannara_core.evolution.meta_mutator import MetaMutator, MutationStrategy


class Phase7Orchestrator:
    def __init__(self):
        self.reverse_engine = BehaviorReverseEngineer()
        self.bridge = EvolutionToDiscoveryBridge()
        self.memory = MemoryStore()
        self.router = SRCTRouter()
        
        # Phase 8 components
        self.deg = create_deg_trainer()  # Neural trace embeddings (DEG)
        self.ecm = ECMGraphEngine()      # Graph-based ECM engine
        self.causal_memory = CausalMemory()  # Causal memory graph
        self.parallel = ParallelEvolution(workers=4)  # Parallel evolution
        self.meta = MetaMutator()        # Adaptive mutation intelligence
        
        self.logger = logging.getLogger("tiannara.orchestrator.phase7")

    def acdr_score(self, trace: List[Dict[str, Any]]) -> float:
        """
        Calculate Algorithmic Compression-Driven Reasoning (ACDR) score.
        
        Args:
            trace: Execution trace to score
            
        Returns:
            Compression ratio as a proxy for algorithmic simplicity
        """
        if not trace:
            return 0.0
        
        # Convert trace to string representation
        trace_str = str(trace)
        raw = trace_str.encode('utf-8')
        
        # Compress using zlib
        compressed = zlib.compress(raw)
        compression_ratio = len(compressed) / len(raw) if len(raw) > 0 else 0
        
        # A lower compression ratio indicates more complexity
        # So we return the inverse for scoring (higher = simpler/more compressible)
        return 1.0 - compression_ratio if compression_ratio < 1.0 else 0.0

    def run_cycle(self, candidate_fn, inputs, complexity=0.5):
        """
        Run a complete evolution cycle with all Phase 8 components.
        
        Args:
            candidate_fn: Function to evaluate
            inputs: Inputs for the function
            complexity: Complexity level (0-1) for determining which modules to use
            
        Returns:
            Dictionary with results from all components
        """
        modules = self.router.route(complexity)

        # Execute the candidate function in sandbox
        result = run_in_sandbox(candidate_fn, args=(inputs,))
        if not result.success:
            return {"error": result.error}

        output = result.output
        trace = output.get("trace", [])

        response = {}

        # ECM-RE
        if "ecm" in modules:
            rules = self.reverse_engine.infer_logic(trace)
            response["rules"] = rules
        else:
            rules = []

        # ACDR
        if "acdr" in modules:
            score = self.acdr_score(trace)
        else:
            score = 0.0

        # MEMORY
        self.memory.save({
            "trace": trace,
            "rules": rules,
            "score": score
        })

        # DISCOVERY LOOP
        from tiannara_core.evolution_to_discovery_bridge import EvolutionResult
        evolution_results = [
            EvolutionResult(
                code_diff=str(candidate_fn),
                fitness_score=score,
                input_output_pairs=[(inputs, output)],
                execution_trace=trace
            )
        ]
        
        hypotheses = self.bridge.translate(evolution_results)
        response.update({
            "output": output,
            "trace": trace,
            "score": score,
            "hypotheses": hypotheses
        })

        # PHASE 8 ENHANCEMENTS START HERE
        
        # DEG - Neural Trace Embeddings
        if "deg" in modules or True:  # Always run DEG to learn representations
            try:
                z, loss = self.deg.train_step(trace)
                response["embedding_loss"] = loss
                response["latent_embedding"] = z.tolist()  # Convert tensor to list for serialization
            except Exception as e:
                self.logger.error(f"DEG training failed: {e}")
                response["embedding_loss"] = float('inf')
                response["latent_embedding"] = []

        # ECM - Graph-based Structural Reasoning
        if "ecm_full" in modules or True:  # Always run full ECM for structural analysis
            try:
                # Build graph from trace
                self.ecm.build_from_trace(trace)
                
                # Apply a mutation to the graph
                applied_op = self.ecm.mutate_graph()
                
                # Extract execution paths
                paths = self.ecm.extract_paths()
                response["ecm_paths"] = paths
                response["applied_mutation"] = applied_op.value if applied_op else None
                
                # Analyze causal strengths
                causal_strengths = self.ecm.analyze_causal_strength()
                response["causal_strengths"] = causal_strengths
            except Exception as e:
                self.logger.error(f"ECM processing failed: {e}")
                response["ecm_paths"] = []
                response["applied_mutation"] = None

        # CAUSAL MEMORY - Store and query causal relationships
        if "causal_memory" in modules or True:  # Always update causal memory
            try:
                self.causal_memory.add_observation(trace, score=score)
                
                # Query for high-value paths
                high_value_paths = self.causal_memory.query_high_value_paths(min_score=0.3)
                response["high_value_paths"] = high_value_paths[:5]  # Limit to top 5
                
                # Get important nodes
                important_nodes = self.causal_memory.get_most_important_nodes(n=10)
                response["important_nodes"] = important_nodes
            except Exception as e:
                self.logger.error(f"Causal memory update failed: {e}")
                response["high_value_paths"] = []
                response["important_nodes"] = []

        # PARALLEL EVOLUTION - Run multiple evaluations simultaneously
        if "evolution" in modules and "parallel" in modules:
            try:
                # Create a small population based on the candidate function
                population = [candidate_fn for _ in range(4)]  # Multiple copies for parallel eval
                
                # Add some mutations to the population
                for i in range(1, min(4, len(population))):
                    strategy = self.meta.choose_strategy()
                    mutated_code = self.meta.apply_mutation(population[0].__code__.co_code.decode('utf-8', errors='ignore') if hasattr(population[0], '__code__') else str(population[0]), strategy)
                    # Note: Actual code mutation is complex, this is a simplified placeholder
                    # In a real implementation, we would properly mutate the function
                
                # Run parallel evaluation
                results = self.parallel.run_batch(population, inputs)
                response["parallel_results"] = [
                    {"output": r.output, "success": r.success, "error": r.error} 
                    for r in results
                ]
            except Exception as e:
                self.logger.error(f"Parallel evolution failed: {e}")
                response["parallel_results"] = []

        # META LEARNING - Adaptive mutation based on past success
        if "meta_learning" in modules or True:  # Always run meta learning
            try:
                # Choose a strategy based on past performance
                strategy = self.meta.choose_strategy()
                
                # Apply the strategy to the function (simplified)
                # In a real implementation, we would mutate the actual function
                function_code = str(candidate_fn)
                mutated_code = self.meta.apply_mutation(function_code, strategy)
                
                # For now, just record the strategy used
                response["mutation_strategy"] = strategy.value
                
                # Update meta learner with a reward based on the score
                # In a real system, we would evaluate the actual mutated function
                reward = score  # Use the ACDR score as a proxy for reward
                self.meta.update(strategy, reward, successful=(score > 0.5))
            except Exception as e:
                self.logger.error(f"Meta learning failed: {e}")
                response["mutation_strategy"] = "error"

        return response


def create_phase7_orchestrator() -> Phase7Orchestrator:
    """Factory function to create a Phase 7 orchestrator."""
    return Phase7Orchestrator()


# Example usage
if __name__ == "__main__":
    # Create a simple test function
    def sample_fn(x):
        if x > 10:
            return {"output": x * 2}
        else:
            return {"output": x + 5}
    
    # Create orchestrator
    orchestrator = create_phase7_orchestrator()
    
    # Run a cycle
    result = orchestrator.run_cycle(sample_fn, 12, complexity=0.9)
    
    print(f"Success: {result.get('output') is not None if 'output' in result else 'error' in result}")
    print(f"Score: {result.get('score', 'N/A')}")
    print(f"Embedding Loss: {result.get('embedding_loss', 'N/A')}")
    print(f"Applied Mutation: {result.get('applied_mutation', 'N/A')}")
    print(f"Number of ECM paths: {len(result.get('ecm_paths', []))}")
    print(f"High value paths: {len(result.get('high_value_paths', []))}")
    print(f"Important nodes: {len(result.get('important_nodes', []))}")
    print(f"Mutation strategy: {result.get('mutation_strategy', 'N/A')}")
    print(f"Hypotheses generated: {len(result.get('hypotheses', []))}")