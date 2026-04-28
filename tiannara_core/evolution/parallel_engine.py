"""
Parallel Evolution Engine

Scalable evolution engine that runs multiple candidates concurrently.
"""

from concurrent.futures import ThreadPoolExecutor, ProcessPoolExecutor, as_completed
from typing import List, Callable, Any, Dict, Optional
import logging
import time
import os
from ..sandbox.executor import run_in_sandbox, ExecutionResult


class ParallelEvolution:
    """Parallel execution engine for evolutionary computation."""
    
    def __init__(self, workers: int = 4, use_processes: bool = False):
        self.workers = workers
        self.use_processes = use_processes
        self.logger = logging.getLogger("tiannara.evolution.parallel")
        
        # On Windows, default to threads to avoid subprocess issues
        if os.name == "nt":
            self.use_processes = False
    
    def evaluate(self, fn: Callable, inputs: Any) -> ExecutionResult:
        """
        Evaluate a single function with given inputs.
        
        Args:
            fn: Function to evaluate
            inputs: Inputs to pass to the function
            
        Returns:
            ExecutionResult with output and success status
        """
        return run_in_sandbox(fn, args=(inputs,))
    
    def run_batch(self, population: List[Callable], inputs: Any) -> List[ExecutionResult]:
        """
        Run a batch of functions in parallel.
        
        Args:
            population: List of functions to evaluate
            inputs: Inputs to pass to each function
            
        Returns:
            List of execution results
        """
        results = []
        
        # Choose executor based on configuration
        if self.use_processes and not os.name == "nt":  # Avoid processes on Windows
            executor_class = ProcessPoolExecutor
        else:
            executor_class = ThreadPoolExecutor
        
        with executor_class(max_workers=self.workers) as executor:
            # Submit all tasks
            future_to_fn = {
                executor.submit(self.evaluate, fn, inputs): fn 
                for fn in population
            }
            
            # Collect results as they complete
            for future in as_completed(future_to_fn):
                fn = future_to_fn[future]
                try:
                    result = future.result()
                    results.append(result)
                    self.logger.debug(f"Completed evaluation for {fn.__name__ if hasattr(fn, '__name__') else 'anonymous'}")
                except Exception as e:
                    self.logger.error(f"Failed to evaluate function: {e}")
                    results.append(ExecutionResult(
                        output=None,
                        error=str(e),
                        success=False
                    ))
        
        return results
    
    def run_batch_with_fitness(self, 
                              population: List[Callable], 
                              inputs: Any, 
                              fitness_func: Callable[[Any], float]) -> List[Dict[str, Any]]:
        """
        Run a batch of functions and calculate fitness for each.
        
        Args:
            population: List of functions to evaluate
            inputs: Inputs to pass to each function
            fitness_func: Function to calculate fitness from output
            
        Returns:
            List of dictionaries with function, result, and fitness
        """
        results = self.run_batch(population, inputs)
        
        evaluated_population = []
        
        for i, result in enumerate(results):
            fitness = 0.0
            if result.success:
                try:
                    fitness = fitness_func(result.output)
                except Exception as e:
                    self.logger.error(f"Fitness calculation failed: {e}")
                    fitness = 0.0
            else:
                self.logger.warning(f"Evaluation failed for function {i}, assigning 0 fitness")
            
            evaluated_population.append({
                'function': population[i],
                'result': result,
                'fitness': fitness,
                'success': result.success
            })
        
        return evaluated_population
    
    def run_generational_evolution(self, 
                                  initial_population: List[Callable],
                                  inputs: Any,
                                  fitness_func: Callable[[Any], float],
                                  generations: int = 10,
                                  elite_size: int = 2,
                                  mutation_func: Optional[Callable[[Callable], Callable]] = None) -> Dict[str, Any]:
        """
        Run a complete generational evolution process.
        
        Args:
            initial_population: Starting population of functions
            inputs: Inputs for evaluation
            fitness_func: Function to calculate fitness
            generations: Number of generations to run
            elite_size: Number of top performers to keep each generation
            mutation_func: Function to create mutants from parents
            
        Returns:
            Dictionary with evolution results
        """
        population = initial_population[:]
        history = []
        
        for gen in range(generations):
            self.logger.info(f"Running generation {gen + 1}/{generations}")
            
            # Evaluate current population
            evaluated_pop = self.run_batch_with_fitness(population, inputs, fitness_func)
            
            # Sort by fitness (descending)
            evaluated_pop.sort(key=lambda x: x['fitness'], reverse=True)
            
            # Record generation stats
            gen_stats = {
                'generation': gen,
                'population_size': len(evaluated_pop),
                'best_fitness': evaluated_pop[0]['fitness'] if evaluated_pop else 0,
                'avg_fitness': sum(p['fitness'] for p in evaluated_pop) / len(evaluated_pop) if evaluated_pop else 0,
                'worst_fitness': evaluated_pop[-1]['fitness'] if evaluated_pop else 0
            }
            history.append(gen_stats)
            
            self.logger.info(f"Gen {gen}: Best={gen_stats['best_fitness']:.3f}, Avg={gen_stats['avg_fitness']:.3f}")
            
            # If we're not in the last generation, create next population
            if gen < generations - 1:
                # Keep elites
                next_population = [p['function'] for p in evaluated_pop[:elite_size]]
                
                # Generate offspring
                offspring = []
                while len(next_population) + len(offspring) < len(population):
                    # Select parent randomly from top 50%
                    parent_idx = min(random.randint(0, len(evaluated_pop)//2), len(evaluated_pop)-1)
                    parent = evaluated_pop[parent_idx]['function']
                    
                    if mutation_func:
                        try:
                            mutant = mutation_func(parent)
                            offspring.append(mutant)
                        except Exception as e:
                            self.logger.error(f"Mutation failed: {e}")
                            # Fallback to copying parent
                            offspring.append(parent)
                    else:
                        # If no mutation function, just copy parent
                        offspring.append(parent)
                
                next_population.extend(offspring)
                population = next_population
        
        # Final evaluation
        final_evaluated = self.run_batch_with_fitness(population, inputs, fitness_func)
        final_evaluated.sort(key=lambda x: x['fitness'], reverse=True)
        
        return {
            'best_solution': final_evaluated[0] if final_evaluated else None,
            'final_population': final_evaluated,
            'history': history,
            'generations_run': generations
        }


# Example usage and testing
if __name__ == "__main__":
    import random
    
    # Define some sample functions to evolve
    def func_1(x):
        return x * 2
    
    def func_2(x):
        return x + 5
    
    def func_3(x):
        return x ** 2
    
    def func_4(x):
        return x - 3
    
    # Fitness function: reward functions that produce output close to target
    def fitness_func(output):
        if not isinstance(output, (int, float)):
            return 0.0
        
        # Assume we want output to be close to 20
        target = 20
        distance = abs(output - target)
        return 1.0 / (1.0 + distance)  # Higher fitness for closer values
    
    # Create parallel evolution engine
    parallel_ev = ParallelEvolution(workers=4)
    
    # Test batch evaluation
    population = [func_1, func_2, func_3, func_4]
    inputs = 5  # x=5
    
    print("Testing batch evaluation...")
    results = parallel_ev.run_batch_with_fitness(population, inputs, fitness_func)
    
    for i, result in enumerate(results):
        print(f"Function {i+1}: {result['fitness']:.3f} - Success: {result['success']}")
    
    # Define a simple mutation function for evolution
    def simple_mutation(parent_func):
        # This is a placeholder - in real usage this would modify the function structure
        return parent_func
    
    # Run generational evolution
    print("\nRunning generational evolution...")
    evolution_result = parallel_ev.run_generational_evolution(
        initial_population=population,
        inputs=inputs,
        fitness_func=fitness_func,
        generations=5,
        elite_size=2,
        mutation_func=simple_mutation
    )
    
    print(f"Best solution fitness: {evolution_result['best_solution']['fitness']:.3f}")
    print(f"Best solution function: {evolution_result['best_solution']['function'].__name__}")
    
    for gen_stat in evolution_result['history']:
        print(f"Gen {gen_stat['generation']}: Best={gen_stat['best_fitness']:.3f}, Avg={gen_stat['avg_fitness']:.3f}")