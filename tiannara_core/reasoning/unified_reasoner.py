from tiannara_core.evolution.neural_engine import NeuralGenome
from tiannara_core.evolution.evolution_loop import EvolutionLoop
from tiannara_core.causal.causal_scorer import CausalScorer
from tiannara_core.deg.trace_embedder import DEGTrainer
from tiannara_core.orchestrators.phase7_orchestrator import Phase7Orchestrator
from tiannara_core.planning.fallback_planner import FallbackPlanner
from tiannara_core.srct.topology_manager import TopologyManager
import time
import json
import re


class UnifiedReasoner:

    def __init__(self):
        self.evolution_loop = EvolutionLoop()  # Using EvolutionLoop instead of EvolutionEngine
        self.causal = CausalScorer()
        self.dege = DEGTrainer()  # Developmental Epigenetic Engine (renamed from dege)
        self.compression = Phase7Orchestrator()  # Using ACDR from Phase 7 Orchestrator
        self.ecm = None  # Will initialize if needed
        self.planner = FallbackPlanner()
        self.topology = TopologyManager()

    def reason(self, prompt: str, context: dict = None, iterations: int = 3) -> str:
        """
        Autonomous reasoning method for code generation and problem solving.
        
        Args:
            prompt: The task/request to reason about
            context: Optional context data (examples, specifications, etc.)
            iterations: Number of refinement iterations (default: 3)
        
        Returns:
            Generated response/code string
        """
        start_time = time.time()
        
        # Initialize reasoning state
        state = {
            "prompt": prompt,
            "context": context or {},
            "current_output": "",
            "trace": [],
            "score": 0.0,
            "iterations_completed": 0
        }
        
        print(f"[REASON] Starting autonomous reasoning...")
        print(f"   Prompt length: {len(prompt)} characters")
        print(f"   Context keys: {list(context.keys()) if context else 'None'}")
        print(f"   Iterations: {iterations}")
        
        # Iterative refinement loop
        for i in range(iterations):
            print(f"\n[ITER {i + 1}/{iterations}] Refining...")
            
            # Step 1: Plan using fallback planner
            plan = self.planner.plan(prompt, context)
            strategy = plan.steps[0].action if (plan and plan.steps) else "default_generation"
            print(f"   Strategy: {strategy}")
            
            # Step 2: Generate/evolve output
            if i == 0:
                # First iteration: initial generation from prompt
                state["current_output"] = self._initial_generation(prompt, context)
            else:
                # Subsequent iterations: refine based on feedback
                state["current_output"] = self._refine_output(state["current_output"], state)
            
            # Step 3: Evaluate quality
            quality_score = self._evaluate_quality(state["current_output"], prompt)
            state["score"] = quality_score
            print(f"   Quality score: {quality_score:.2f}/1.00")
            
            # Step 4: Record trace
            state["trace"].append({
                "iteration": i + 1,
                "output_length": len(state["current_output"]),
                "score": quality_score,
                "strategy": strategy
            })
            
            state["iterations_completed"] = i + 1
            
            # Early exit if quality is excellent
            if quality_score >= 0.95:
                print(f"   [EXCELLENT] Quality achieved, stopping early")
                break
        
        elapsed = time.time() - start_time
        print(f"\n[COMPLETE] Reasoning complete in {elapsed:.2f}s")
        print(f"Final quality: {state['score']:.2f}/1.00")
        print(f"Output length: {len(state['current_output'])} chars")
        
        return state["current_output"]
    
    def _initial_generation(self, prompt: str, context: dict) -> str:
        """Generate initial output from prompt and context"""
        # Extract key information from prompt
        lines = prompt.split('\n')
        
        # Look for code generation patterns
        if 'tsx' in prompt.lower() or 'react' in prompt.lower():
            # React component generation
            return self._generate_react_component(prompt, context)
        elif 'python' in prompt.lower() or 'fastapi' in prompt.lower():
            # Python/FastAPI generation
            return self._generate_python_code(prompt, context)
        else:
            # Generic text generation
            return self._generate_generic_response(prompt, context)
    
    def _generate_react_component(self, prompt: str, context: dict) -> str:
        """Generate React TypeScript component"""
        # Extract component name from prompt
        name_match = re.search(r"component named ['\"]?([A-Za-z0-9_]+)['\"]?", prompt, re.IGNORECASE)
        component_name = name_match.group(1) if name_match else "GeneratedComponent"
        
        # Use context examples if available
        examples = context.get('stat_card_component', '') if context else ''
        design_rules = context.get('design_system_rules', {}) if context else {}
        
        # Generate based on patterns
        generated = f"""'use client'

import React from 'react'

interface {component_name}Props {{
  // TODO: Define props based on requirements
}}

export default function {component_name}({{
  // TODO: Destructure props
}}: {component_name}Props) {{
  return (
    <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6">
      <h3 className="text-lg font-semibold text-white">{component_name}</h3>
      <p className="text-sm text-slate-400 mt-2">Generated by Tiannara Core</p>
    </div>
  )
}}
"""
        return generated
    
    def _generate_python_code(self, prompt: str, context: dict) -> str:
        """Generate Python/FastAPI code"""
        return "# Python code generation placeholder\n# To be implemented"
    
    def _generate_generic_response(self, prompt: str, context: dict) -> str:
        """Generate generic text response"""
        return f"Response to: {prompt[:100]}..."
    
    def _refine_output(self, current_output: str, state: dict) -> str:
        """Refine existing output based on evaluation feedback"""
        # For now, simple refinement - could be enhanced with LLM
        score = state.get('score', 0.5)
        
        if score < 0.7:
            # Low quality: major revision needed
            return current_output + "\n\n# Refined version with improvements"
        elif score < 0.9:
            # Medium quality: minor improvements
            return current_output + "\n# Minor refinements applied"
        else:
            # High quality: keep as is
            return current_output
    
    def _evaluate_quality(self, output: str, prompt: str) -> float:
        """Evaluate the quality of generated output"""
        score = 0.0
        
        # Check 1: Output is not empty
        if output and len(output) > 50:
            score += 0.2
        
        # Check 2: Contains expected keywords from prompt
        prompt_keywords = [word for word in prompt.split() if len(word) > 4]
        if prompt_keywords:
            matching_keywords = sum(1 for kw in prompt_keywords[:5] if kw.lower() in output.lower())
            score += (matching_keywords / min(5, len(prompt_keywords))) * 0.3
        else:
            # No keywords to match, give partial credit
            score += 0.15
        
        # Check 3: Proper structure (for code)
        if 'tsx' in prompt.lower() or 'react' in prompt.lower():
            if 'export default' in output:
                score += 0.2
            if 'interface' in output or 'type' in output:
                score += 0.15
            if 'className=' in output:
                score += 0.15
        
        # Cap at 1.0
        return min(score, 1.0)

    def run_cycle(self, code, iterations=10):
        state = {
            "code": code,
            "trace": [],
            "score": 0.0
        }

        for i in range(iterations):
            # Get dynamic execution plan from topology manager
            execution_plan = self.topology.get_execution_plan(state)
            
            # Initialize mutation_strategy with default value
            mutation_strategy = "default"

            for module in execution_plan:
                if module == "planner":
                    # FallbackPlanner uses plan() method, not select_strategy()
                    # Use a simple default strategy based on state
                    mutation_strategy = self._get_mutation_strategy(state)
                
                elif module == "evolution":
                    # Using evolution loop to process the code
                    evolved_result = self._evolve_code(state["code"], mutation_strategy)
                    state["code"] = evolved_result
                
                elif module == "causal":
                    # Evaluate the causal relationships in the trace
                    # CausalScorer uses score() method with two traces (expects numeric arrays)
                    if state["trace"] and len(state["trace"]) >= 2:
                        try:
                            # Extract numeric values from trace entries
                            trace_a = state["trace"][-2]
                            trace_b = state["trace"][-1]
                            
                            # If traces are dicts, extract 'score' or use default
                            if isinstance(trace_a, dict):
                                val_a = trace_a.get("score", 0.5)
                            else:
                                val_a = float(trace_a) if trace_a else 0.5
                            
                            if isinstance(trace_b, dict):
                                val_b = trace_b.get("score", 0.5)
                            else:
                                val_b = float(trace_b) if trace_b else 0.5
                            
                            causal_score = self.causal.score([val_a], [val_b])
                        except (TypeError, ValueError):
                            causal_score = 0.5
                    else:
                        causal_score = 0.5
                    state["causal_score"] = causal_score
                
                elif module == "compression":
                    # Use ACDR from Phase 7 Orchestrator
                    compression_score = self.compression.acdr_score(state["trace"]) if state["trace"] else 0.5
                    state["compression_score"] = compression_score
                
                elif module == "reverse_engine":
                    # Placeholder for reverse engineering logic
                    rules = self.extract_rules(state["code"])
                    state["rules"] = rules
                
                elif module == "memory":
                    # Placeholder for memory integration
                    pass

            # Calculate overall score
            state["score"] = self.calculate_score(state)
            
            # Add to trace
            state["trace"].append(state.copy())

        # Evolve the topology based on the total performance score
        self.topology.evolve_topology(state["score"])

        return state

    def _evolve_code(self, code, strategy):
        """Evolve the code using the evolution loop"""
        # In a real implementation, this would involve actual evolution of code
        # For now, we'll simulate the evolution by appending a comment
        return f"{code}\n# Evolved with strategy: {strategy}"

    def extract_rules(self, code):
        # Placeholder for reverse engineering logic
        return f"Extracted rules from: {code}"
    
    def _get_mutation_strategy(self, state):
        """Get mutation strategy based on current state."""
        # Simple heuristic: use different strategies based on iteration/score
        score = state.get("score", 0.0)
        if score < 0.3:
            return "aggressive"
        elif score < 0.6:
            return "moderate"
        else:
            return "conservative"

    def calculate_score(self, state):
        # Combine various scores to produce a final score
        causal_score = state.get("causal_score", 0.5)
        compression_score = state.get("compression_score", 0.5)
        
        # Simple scoring mechanism - can be made more sophisticated
        combined_score = (causal_score + compression_score) / 2
        
        # Ensure score is between 0 and 1
        return min(max(combined_score, 0.0), 1.0)
