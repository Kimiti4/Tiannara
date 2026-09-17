"""
Combinatorial Optimization Domain - Evolution Engine

Implements mutation operators for NP-hard optimization problems:
- Greedy heuristic refinement
- Local search (2-opt, swap)
- Constraint relaxation
- Approximation algorithm selection
- Metaheuristic tuning (simulated annealing, genetic algorithms)
"""

import random
import math
from typing import Dict, Any, Optional, Callable, List
from tiannara_core.evaluation.combinatorial_optimization_domain import CombinatorialOptimizationGenerator

# Import enhancement modules
try:
    from tiannara_core.evaluation.combinatorial_enhancements import (
        GeneticAlgorithmOptimizer,
        SimulatedAnnealingOptimizer,
        HybridOptimizer,
        knapsack_fitness,
        knapsack_neighbor,
        tsp_fitness,
        tsp_neighbor
    )
    ENHANCEMENTS_AVAILABLE = True
except ImportError:
    ENHANCEMENTS_AVAILABLE = False


class CombinatorialOptimizationEvolver:
    """Evolves solutions for combinatorial optimization problems."""
    
    def __init__(self, seed: int = None):
        self.rng = random.Random(seed)
        
        # Mutation operators
        self.mutation_operators = [
            "greedy_refinement",       # Improve greedy solution
            "local_search_2opt",       # 2-opt for TSP
            "constraint_relaxation",   # Relax constraints temporarily
            "approximation_switch",    # Switch approximation algorithm
            "metaheuristic_tuning",    # Adjust metaheuristic parameters
            "construction_heuristic",  # Change construction method
            "genetic_algorithm",       # NEW: Genetic Algorithm optimizer
            "simulated_annealing"      # NEW: Simulated Annealing optimizer
        ]
        
        # Operator statistics
        self.operator_stats = {op: {"success": 0, "total": 0} for op in self.mutation_operators}
    
    def create_variant(self, task: Dict[str, Any], episode: int = 0,
                      external_skills: Optional[List] = None) -> Optional[Callable]:
        """
        Create a mutated variant for solving the optimization task.
        
        Args:
            task: Task specification from CombinatorialOptimizationGenerator
            episode: Episode number (for adaptive mutation)
            external_skills: Skills from other domains for transfer
            
        Returns:
            Callable that attempts to solve the task, or None if creation fails
        """
        task_type = task.get("type")
        
        # Select mutation operator based on task type and problem size
        problem_size = self._estimate_problem_size(task)
        
        if task_type == "tsp":
            # For large TSP problems, prefer advanced algorithms
            if problem_size > 50 and ENHANCEMENTS_AVAILABLE:
                operator = self.rng.choice(["genetic_algorithm", "simulated_annealing", "local_search_2opt"])
            else:
                operator = self.rng.choice(["local_search_2opt", "greedy_refinement", "metaheuristic_tuning"])
        elif task_type == "knapsack":
            # For large knapsack, use GA/SA
            if problem_size > 30 and ENHANCEMENTS_AVAILABLE:
                operator = self.rng.choice(["genetic_algorithm", "simulated_annealing", "greedy_refinement"])
            else:
                operator = self.rng.choice(["greedy_refinement", "constraint_relaxation", "approximation_switch"])
        elif task_type == "graph_coloring":
            operator = self.rng.choice(["construction_heuristic", "local_search_2opt", "constraint_relaxation"])
        elif task_type == "scheduling":
            # For complex scheduling, use advanced methods
            if problem_size > 20 and ENHANCEMENTS_AVAILABLE:
                operator = self.rng.choice(["genetic_algorithm", "greedy_refinement"])
            else:
                operator = self.rng.choice(["greedy_refinement", "approximation_switch"])
        else:  # set_cover
            operator = self.rng.choice(["greedy_refinement", "construction_heuristic"])
        
        # Apply external skills if available (cross-domain transfer)
        if external_skills:
            transferred_solution = self._apply_external_skills(task, external_skills)
            if transferred_solution:
                return transferred_solution
        
        # Create base solution strategy
        if task_type == "tsp":
            base_strategy = self._create_tsp_strategy(task)
        elif task_type == "knapsack":
            base_strategy = self._create_knapsack_strategy(task)
        elif task_type == "graph_coloring":
            base_strategy = self._create_graph_coloring_strategy(task)
        elif task_type == "scheduling":
            base_strategy = self._create_scheduling_strategy(task)
        else:  # set_cover
            base_strategy = self._create_set_cover_strategy(task)
        
        if not base_strategy:
            return None
        
        # Apply mutation
        mutated_strategy = self._apply_mutation(base_strategy, operator, task)
        
        return mutated_strategy
    
    def _apply_external_skills(self, task: Dict[str, Any], 
                              external_skills: List) -> Optional[Callable]:
        """
        Apply skills from other domains to solve optimization task.
        
        Cross-domain transfer opportunities:
        - Algorithm domain: Search strategies, pattern recognition
        - Logic domain: Constraint satisfaction
        - Temporal domain: Sequential reasoning for scheduling
        """
        for skill in external_skills:
            skill_type = skill.get("skill_type", "").lower()
            
            # Transfer search strategies from algorithm domain
            if skill_type in ["search_strategy", "pattern_recognition"]:
                if task["type"] == "tsp":
                    return self._create_nearest_neighbor_solver(task, skill)
            
            # Transfer constraint solving from logic domain
            elif skill_type in ["constraint_satisfaction"]:
                if task["type"] in ["graph_coloring", "scheduling"]:
                    return self._create_constraint_based_solver(task, skill)
            
            # Transfer sequential reasoning from temporal domain
            elif skill_type in ["sequential_reasoning"]:
                if task["type"] == "scheduling":
                    return self._create_sequential_scheduler(task, skill)
        
        return None
    
    def _estimate_problem_size(self, task: Dict[str, Any]) -> int:
        """
        Estimate problem size for parameter tuning.
        
        Returns:
            Integer representing problem complexity (number of variables/items/cities)
        """
        task_type = task.get("type")
        inputs = task.get("inputs", {})
        
        if task_type == "tsp":
            cities = inputs.get("cities", [])
            return len(cities)
        elif task_type == "knapsack":
            items = inputs.get("items", [])
            return len(items)
        elif task_type == "graph_coloring":
            num_nodes = inputs.get("num_nodes", 0)
            return num_nodes
        elif task_type == "scheduling":
            jobs = inputs.get("jobs", [])
            return len(jobs)
        else:  # set_cover
            variables = inputs.get("variables", [])
            return len(variables)
    
    def _create_ga_optimizer_params(self, problem_size: int) -> Dict[str, Any]:
        """
        Tune GA parameters based on problem size.
        
        Larger problems need larger populations and more generations.
        """
        if problem_size <= 20:
            return {
                'population_size': 30,
                'max_generations': 30,
                'mutation_rate': 0.15,
                'crossover_rate': 0.8,
                'elitism_count': 3,
                'tournament_size': 3
            }
        elif problem_size <= 50:
            return {
                'population_size': 50,
                'max_generations': 50,
                'mutation_rate': 0.1,
                'crossover_rate': 0.85,
                'elitism_count': 5,
                'tournament_size': 5
            }
        else:  # Large problems
            return {
                'population_size': 100,
                'max_generations': 100,
                'mutation_rate': 0.08,
                'crossover_rate': 0.9,
                'elitism_count': 10,
                'tournament_size': 7
            }
    
    def _create_sa_optimizer_params(self, problem_size: int) -> Dict[str, Any]:
        """
        Tune SA parameters based on problem size.
        
        Larger problems need higher initial temperature and more iterations.
        """
        if problem_size <= 20:
            return {
                'initial_temp': 500.0,
                'cooling_rate': 0.99,
                'min_temp': 1e-6,
                'max_iterations': 2000
            }
        elif problem_size <= 50:
            return {
                'initial_temp': 1000.0,
                'cooling_rate': 0.995,
                'min_temp': 1e-8,
                'max_iterations': 5000
            }
        else:  # Large problems
            return {
                'initial_temp': 2000.0,
                'cooling_rate': 0.998,
                'min_temp': 1e-10,
                'max_iterations': 10000
            }
    
    def _create_nearest_neighbor_solver(self, task: Dict[str, Any], 
                                       skill: Dict[str, Any]) -> Callable:
        """Create TSP solver using nearest neighbor heuristic."""
        cities = task["inputs"]["cities"]
        distances = task["inputs"]["distances"]
        
        def solver(**kwargs):
            n = len(cities)
            visited = [False] * n
            tour = [0]  # Start at city 0
            visited[0] = True
            
            for _ in range(n - 1):
                current = tour[-1]
                nearest = -1
                min_dist = float('inf')
                
                for j in range(n):
                    if not visited[j]:
                        dist = distances.get((str(current), str(j)), float('inf'))
                        if dist < min_dist:
                            min_dist = dist
                            nearest = j
                
                if nearest != -1:
                    tour.append(nearest)
                    visited[nearest] = True
            
            tour.append(0)  # Return to start
            
            # Calculate cost
            cost = 0
            for i in range(len(tour) - 1):
                cost += distances.get((str(tour[i]), str(tour[i+1])), 0)
            
            return {"tour": tour, "cost": cost}
        
        return solver
    
    def _create_constraint_based_solver(self, task: Dict[str, Any], 
                                       skill: Dict[str, Any]) -> Callable:
        """Create solver using constraint propagation."""
        task_type = task["type"]
        
        if task_type == "graph_coloring":
            nodes = task["inputs"]["nodes"]
            edges = task["inputs"]["edges"]
            
            def solver(**kwargs):
                # Build adjacency list
                adj = {node: [] for node in nodes}
                for u, v in edges:
                    adj[u].append(v)
                    adj[v].append(u)
                
                # Greedy coloring with constraint checking
                coloring = {}
                for node in nodes:
                    # Find colors used by neighbors
                    neighbor_colors = set()
                    for neighbor in adj[node]:
                        if neighbor in coloring:
                            neighbor_colors.add(coloring[neighbor])
                    
                    # Assign smallest available color
                    color = 0
                    while color in neighbor_colors:
                        color += 1
                    
                    coloring[node] = color
                
                return {"coloring": coloring, "chromatic_number": max(coloring.values()) + 1}
            
            return solver
        
        elif task_type == "scheduling":
            jobs = task["inputs"]["jobs"]
            
            def solver(**kwargs):
                # Schedule by earliest deadline first (EDF)
                sorted_jobs = sorted(jobs, key=lambda x: x["deadline"])
                
                schedule = []
                time = 0
                total_profit = 0
                
                for job in sorted_jobs:
                    if time + job["processing_time"] <= job["deadline"]:
                        schedule.append(job["id"])
                        time += job["processing_time"]
                        total_profit += job["profit"]
                
                return {"schedule": schedule, "total_profit": total_profit}
            
            return solver
        
        return None
    
    def _create_sequential_scheduler(self, task: Dict[str, Any], 
                                    skill: Dict[str, Any]) -> Callable:
        """Create scheduler using sequential reasoning."""
        jobs = task["inputs"]["jobs"]
        
        def solver(**kwargs):
            # Sort by profit-to-time ratio
            sorted_jobs = sorted(jobs, 
                               key=lambda x: x["profit"] / x["processing_time"], 
                               reverse=True)
            
            schedule = []
            time_slots = set()
            total_profit = 0
            
            for job in sorted_jobs:
                # Try to fit job before deadline
                for start_time in range(job["deadline"] - job["processing_time"], -1, -1):
                    slots_needed = set(range(start_time, start_time + job["processing_time"]))
                    if not slots_needed & time_slots:  # No conflict
                        time_slots.update(slots_needed)
                        schedule.append(job["id"])
                        total_profit += job["profit"]
                        break
            
            return {"schedule": schedule, "total_profit": total_profit}
        
        return solver
    
    def _create_tsp_strategy(self, task: Dict[str, Any]) -> Optional[Callable]:
        """Create base TSP solving strategy."""
        cities = task["inputs"]["cities"]
        distances = task["inputs"]["distances"]
        
        def solver(**kwargs):
            # Nearest neighbor heuristic
            n = len(cities)
            visited = [False] * n
            tour = [0]
            visited[0] = True
            
            for _ in range(n - 1):
                current = tour[-1]
                nearest = -1
                min_dist = float('inf')
                
                for j in range(n):
                    if not visited[j]:
                        dist = distances.get((str(current), str(j)), float('inf'))
                        if dist < min_dist:
                            min_dist = dist
                            nearest = j
                
                if nearest != -1:
                    tour.append(nearest)
                    visited[nearest] = True
            
            tour.append(0)
            
            # Calculate cost
            cost = sum(distances.get((str(tour[i]), str(tour[i+1])), 0) 
                      for i in range(len(tour) - 1))
            
            return {"tour": tour, "cost": cost}
        
        return solver
    
    def _create_knapsack_strategy(self, task: Dict[str, Any]) -> Optional[Callable]:
        """Create base knapsack solving strategy."""
        items = task["inputs"]["items"]
        capacity = task["inputs"]["capacity"]
        
        def solver(**kwargs):
            # Greedy by value/weight ratio
            ratios = [(i, item["value"] / item["weight"]) 
                     for i, item in enumerate(items)]
            ratios.sort(key=lambda x: x[1], reverse=True)
            
            selected = []
            total_weight = 0
            total_value = 0
            
            for idx, _ in ratios:
                if total_weight + items[idx]["weight"] <= capacity:
                    selected.append(idx)
                    total_weight += items[idx]["weight"]
                    total_value += items[idx]["value"]
            
            return {"selected_items": selected, "max_value": total_value}
        
        return solver
    
    def _create_graph_coloring_strategy(self, task: Dict[str, Any]) -> Optional[Callable]:
        """Create base graph coloring strategy."""
        nodes = task["inputs"]["nodes"]
        edges = task["inputs"]["edges"]
        
        def solver(**kwargs):
            # Build adjacency list
            adj = {node: [] for node in nodes}
            for u, v in edges:
                adj[u].append(v)
                adj[v].append(u)
            
            # Greedy coloring
            coloring = {}
            for node in nodes:
                neighbor_colors = {coloring[neighbor] for neighbor in adj[node] 
                                 if neighbor in coloring}
                color = 0
                while color in neighbor_colors:
                    color += 1
                coloring[node] = color
            
            return {"coloring": coloring, "chromatic_number": max(coloring.values()) + 1}
        
        return solver
    
    def _create_scheduling_strategy(self, task: Dict[str, Any]) -> Optional[Callable]:
        """Create base scheduling strategy."""
        jobs = task["inputs"]["jobs"]
        
        def solver(**kwargs):
            # Sort by deadline
            sorted_jobs = sorted(jobs, key=lambda x: x["deadline"])
            
            schedule = []
            time = 0
            total_profit = 0
            
            for job in sorted_jobs:
                if time + job["processing_time"] <= job["deadline"]:
                    schedule.append(job["id"])
                    time += job["processing_time"]
                    total_profit += job["profit"]
            
            return {"schedule": schedule, "total_profit": total_profit}
        
        return solver
    
    def _create_set_cover_strategy(self, task: Dict[str, Any]) -> Optional[Callable]:
        """Create base set cover strategy."""
        universe = set(task["inputs"]["universe"])
        sets = task["inputs"]["sets"]
        
        def solver(**kwargs):
            uncovered = set(universe)
            selected = []
            
            while uncovered:
                best_set = None
                best_coverage = 0
                
                for s in sets:
                    if s["id"] in selected:
                        continue
                    coverage = len(set(s["elements"]) & uncovered)
                    if coverage > best_coverage:
                        best_coverage = coverage
                        best_set = s
                
                if best_set is None:
                    break
                
                selected.append(best_set["id"])
                uncovered -= set(best_set["elements"])
            
            return {
                "selected_sets": selected,
                "coverage": len(universe) - len(uncovered),
                "total_cost": sum(sets[i]["cost"] for i in selected)
            }
        
        return solver
    
    def _apply_mutation(self, base_strategy: Callable, operator: str, 
                       task: Dict[str, Any]) -> Callable:
        """Apply mutation operator to base strategy."""
        
        if operator == "greedy_refinement":
            return self._mutate_greedy_refinement(base_strategy, task)
        elif operator == "local_search_2opt":
            return self._mutate_local_search_2opt(base_strategy, task)
        elif operator == "constraint_relaxation":
            return self._mutate_constraint_relaxation(base_strategy, task)
        elif operator == "approximation_switch":
            return self._mutate_approximation_switch(base_strategy, task)
        elif operator == "metaheuristic_tuning":
            return self._mutate_metaheuristic_tuning(base_strategy, task)
        elif operator == "construction_heuristic":
            return self._mutate_construction_heuristic(base_strategy, task)
        elif operator == "genetic_algorithm":
            return self._apply_genetic_algorithm(task)
        elif operator == "simulated_annealing":
            return self._apply_simulated_annealing(task)
        else:
            return base_strategy
    
    def _mutate_greedy_refinement(self, base_strategy: Callable, 
                                  task: Dict[str, Any]) -> Callable:
        """Refine greedy solution with local improvements."""
        def mutated_solver(**kwargs):
            result = base_strategy(**kwargs)
            
            # Try swapping elements to improve
            if task["type"] == "knapsack" and isinstance(result, dict):
                selected = result.get("selected_items", [])
                items = task["inputs"]["items"]
                capacity = task["inputs"]["capacity"]
                
                # Try adding unselected items
                unselected = [i for i in range(len(items)) if i not in selected]
                for idx in unselected:
                    new_selected = selected + [idx]
                    total_weight = sum(items[i]["weight"] for i in new_selected)
                    if total_weight <= capacity:
                        new_value = sum(items[i]["value"] for i in new_selected)
                        if new_value > result.get("max_value", 0):
                            result["selected_items"] = new_selected
                            result["max_value"] = new_value
            
            return result
        
        return mutated_solver
    
    def _mutate_local_search_2opt(self, base_strategy: Callable, 
                                 task: Dict[str, Any]) -> Callable:
        """Apply 2-opt local search for TSP."""
        def mutated_solver(**kwargs):
            result = base_strategy(**kwargs)
            
            if task["type"] == "tsp" and isinstance(result, dict):
                tour = result.get("tour", [])
                distances = task["inputs"]["distances"]
                
                if len(tour) < 4:
                    return result
                
                # 2-opt improvement
                improved = True
                best_tour = tour[:]
                best_cost = result.get("cost", float('inf'))
                
                iterations = 0
                while improved and iterations < 10:
                    improved = False
                    iterations += 1
                    
                    for i in range(1, len(best_tour) - 2):
                        for j in range(i + 1, len(best_tour) - 1):
                            # Reverse segment between i and j
                            new_tour = best_tour[:i] + best_tour[i:j+1][::-1] + best_tour[j+1:]
                            
                            # Calculate new cost
                            new_cost = sum(distances.get((str(new_tour[k]), str(new_tour[k+1])), 0) 
                                         for k in range(len(new_tour) - 1))
                            
                            if new_cost < best_cost:
                                best_tour = new_tour
                                best_cost = new_cost
                                improved = True
                
                result["tour"] = best_tour
                result["cost"] = best_cost
            
            return result
        
        return mutated_solver
    
    def _mutate_constraint_relaxation(self, base_strategy: Callable, 
                                     task: Dict[str, Any]) -> Callable:
        """Temporarily relax constraints to explore solution space."""
        def mutated_solver(**kwargs):
            # For graph coloring, allow more colors initially
            if task["type"] == "graph_coloring":
                result = base_strategy(**kwargs)
                # Already uses minimal colors, so just return
                return result
            
            # For scheduling, allow slight deadline violations
            elif task["type"] == "scheduling":
                jobs = task["inputs"]["jobs"]
                sorted_jobs = sorted(jobs, key=lambda x: x["profit"], reverse=True)
                
                schedule = []
                time = 0
                total_profit = 0
                
                for job in sorted_jobs:
                    # Allow 10% deadline violation
                    if time + job["processing_time"] <= job["deadline"] * 1.1:
                        schedule.append(job["id"])
                        time += job["processing_time"]
                        total_profit += job["profit"]
                
                return {"schedule": schedule, "total_profit": total_profit}
            
            return base_strategy(**kwargs)
        
        return mutated_solver
    
    def _mutate_approximation_switch(self, base_strategy: Callable, 
                                    task: Dict[str, Any]) -> Callable:
        """Switch to different approximation algorithm."""
        def mutated_solver(**kwargs):
            if task["type"] == "knapsack":
                items = task["inputs"]["items"]
                capacity = task["inputs"]["capacity"]
                
                # Try dynamic programming for small instances
                if len(items) <= 20:
                    n = len(items)
                    dp = [[0] * (capacity + 1) for _ in range(n + 1)]
                    
                    for i in range(1, n + 1):
                        w = items[i-1]["weight"]
                        v = items[i-1]["value"]
                        for j in range(capacity + 1):
                            dp[i][j] = dp[i-1][j]
                            if w <= j:
                                dp[i][j] = max(dp[i][j], dp[i-1][j-w] + v)
                    
                    # Backtrack
                    selected = []
                    j = capacity
                    for i in range(n, 0, -1):
                        if dp[i][j] != dp[i-1][j]:
                            selected.append(i-1)
                            j -= items[i-1]["weight"]
                    
                    return {"selected_items": sorted(selected), "max_value": dp[n][capacity]}
            
            return base_strategy(**kwargs)
        
        return mutated_solver
    
    def _mutate_metaheuristic_tuning(self, base_strategy: Callable, 
                                    task: Dict[str, Any]) -> Callable:
        """Tune metaheuristic parameters."""
        def mutated_solver(**kwargs):
            # For TSP, try simulated annealing
            if task["type"] == "tsp":
                result = base_strategy(**kwargs)
                tour = result.get("tour", [])
                distances = task["inputs"]["distances"]
                
                if len(tour) < 3:
                    return result
                
                # Simple simulated annealing
                best_tour = tour[:]
                best_cost = result.get("cost", float('inf'))
                current_tour = tour[:]
                current_cost = best_cost
                
                temperature = 100.0
                cooling_rate = 0.95
                
                for _ in range(100):
                    # Random swap
                    i, j = self.rng.sample(range(1, len(current_tour) - 1), 2)
                    new_tour = current_tour[:]
                    new_tour[i], new_tour[j] = new_tour[j], new_tour[i]
                    
                    new_cost = sum(distances.get((str(new_tour[k]), str(new_tour[k+1])), 0) 
                                 for k in range(len(new_tour) - 1))
                    
                    delta = new_cost - current_cost
                    
                    if delta < 0 or self.rng.random() < math.exp(-delta / temperature):
                        current_tour = new_tour
                        current_cost = new_cost
                        
                        if current_cost < best_cost:
                            best_tour = current_tour[:]
                            best_cost = current_cost
                    
                    temperature *= cooling_rate
                
                result["tour"] = best_tour
                result["cost"] = best_cost
            
            return result
        
        return mutated_solver
    
    def _mutate_construction_heuristic(self, base_strategy: Callable, 
                                      task: Dict[str, Any]) -> Callable:
        """Change construction heuristic."""
        def mutated_solver(**kwargs):
            if task["type"] == "set_cover":
                universe = set(task["inputs"]["universe"])
                sets = task["inputs"]["sets"]
                
                # Greedy by cost-effectiveness
                uncovered = set(universe)
                selected = []
                
                while uncovered:
                    best_set = None
                    best_ratio = 0
                    
                    for s in sets:
                        if s["id"] in selected:
                            continue
                        covered_new = len(set(s["elements"]) & uncovered)
                        if covered_new > 0:
                            ratio = covered_new / s["cost"]
                            if ratio > best_ratio:
                                best_ratio = ratio
                                best_set = s
                    
                    if best_set is None:
                        break
                    
                    selected.append(best_set["id"])
                    uncovered -= set(best_set["elements"])
                
                return {
                    "selected_sets": selected,
                    "coverage": len(universe) - len(uncovered),
                    "total_cost": sum(sets[i]["cost"] for i in selected)
                }
            
            return base_strategy(**kwargs)
        
        return mutated_solver
    
    def _apply_genetic_algorithm(self, task: Dict[str, Any]) -> Callable:
        """
        Apply Genetic Algorithm optimization.
        
        Uses problem-size-tuned parameters for efficient search.
        """
        if not ENHANCEMENTS_AVAILABLE:
            # Fallback to base strategy if enhancements not available
            return lambda **kwargs: {"error": "GA not available", "fallback": True}
        
        task_type = task.get("type")
        inputs = task.get("inputs", {})
        problem_size = self._estimate_problem_size(task)
        ga_params = self._create_ga_optimizer_params(problem_size)
        
        def ga_solver(**kwargs):
            try:
                if task_type == "knapsack":
                    items = inputs.get("items", [])
                    capacity = inputs.get("capacity", 0)
                    
                    # Define fitness and operators
                    fitness_func = lambda sol, **kw: knapsack_fitness(sol, items, capacity, **kw)
                    solution_gen = lambda **kw: self.rng.sample(range(len(items)), 
                                                                 self.rng.randint(1, len(items)))
                    mutation_func = lambda sol, rate, **kw: self._ga_knapsack_mutation(sol, rate, items, capacity)
                    crossover_func = lambda p1, p2, **kw: self._ga_knapsack_crossover(p1, p2)
                    
                    # Run GA
                    optimizer = GeneticAlgorithmOptimizer(**ga_params)
                    result = optimizer.optimize(
                        fitness_func=fitness_func,
                        solution_generator=solution_gen,
                        mutation_func=mutation_func,
                        crossover_func=crossover_func,
                        items=items,
                        capacity=capacity
                    )
                    
                    selected_indices = result['best_solution']
                    total_value = sum(items[i]['value'] for i in selected_indices if i < len(items))
                    
                    return {
                        'selected_items': selected_indices,
                        'max_value': total_value,
                        'method': 'genetic_algorithm',
                        'generations': result['generations_run']
                    }
                    
                elif task_type == "tsp":
                    cities = inputs.get("cities", [])
                    
                    # Define fitness and operators
                    fitness_func = lambda tour, **kw: tsp_fitness(tour, cities, **kw)
                    solution_gen = lambda **kw: list(range(len(cities)))
                    mutation_func = lambda sol, rate, **kw: self._ga_tsp_mutation(sol, rate, cities)
                    crossover_func = lambda p1, p2, **kw: self._ga_tsp_crossover(p1, p2)
                    
                    # Run GA
                    optimizer = GeneticAlgorithmOptimizer(**ga_params)
                    result = optimizer.optimize(
                        fitness_func=fitness_func,
                        solution_generator=solution_gen,
                        mutation_func=mutation_func,
                        crossover_func=crossover_func,
                        cities=cities
                    )
                    
                    best_tour = result['best_solution']
                    distance = -result['best_fitness']  # Negate because fitness is negative distance
                    
                    return {
                        'tour': best_tour,
                        'cost': distance,
                        'method': 'genetic_algorithm',
                        'generations': result['generations_run']
                    }
                else:
                    # Fallback for other problem types
                    return {"error": f"GA not implemented for {task_type}", "fallback": True}
                    
            except Exception as e:
                return {"error": str(e), "fallback": True}
        
        return ga_solver
    
    def _apply_simulated_annealing(self, task: Dict[str, Any]) -> Callable:
        """
        Apply Simulated Annealing optimization.
        
        Uses problem-size-tuned cooling schedule for efficient search.
        """
        if not ENHANCEMENTS_AVAILABLE:
            # Fallback to base strategy if enhancements not available
            return lambda **kwargs: {"error": "SA not available", "fallback": True}
        
        task_type = task.get("type")
        inputs = task.get("inputs", {})
        problem_size = self._estimate_problem_size(task)
        sa_params = self._create_sa_optimizer_params(problem_size)
        
        def sa_solver(**kwargs):
            try:
                if task_type == "knapsack":
                    items = inputs.get("items", [])
                    capacity = inputs.get("capacity", 0)
                    
                    # Define fitness and neighbor function
                    fitness_func = lambda sol, **kw: knapsack_fitness(sol, items, capacity, **kw)
                    solution_gen = lambda **kw: self.rng.sample(range(len(items)),
                                                                 self.rng.randint(1, len(items)))
                    neighbor_func = lambda sol, temp, **kw: knapsack_neighbor(sol, temp, items, **kw)
                    
                    # Run SA
                    optimizer = SimulatedAnnealingOptimizer(**sa_params)
                    result = optimizer.optimize(
                        fitness_func=fitness_func,
                        solution_generator=solution_gen,
                        neighbor_func=neighbor_func,
                        items=items,
                        capacity=capacity
                    )
                    
                    selected_indices = result['best_solution']
                    total_value = sum(items[i]['value'] for i in selected_indices if i < len(items))
                    
                    return {
                        'selected_items': selected_indices,
                        'max_value': total_value,
                        'method': 'simulated_annealing',
                        'iterations': result['iterations_run']
                    }
                    
                elif task_type == "tsp":
                    cities = inputs.get("cities", [])
                    
                    # Define fitness and neighbor function
                    fitness_func = lambda tour, **kw: tsp_fitness(tour, cities, **kw)
                    solution_gen = lambda **kw: list(range(len(cities)))
                    neighbor_func = tsp_neighbor
                    
                    # Run SA
                    optimizer = SimulatedAnnealingOptimizer(**sa_params)
                    result = optimizer.optimize(
                        fitness_func=fitness_func,
                        solution_generator=solution_gen,
                        neighbor_func=neighbor_func,
                        cities=cities
                    )
                    
                    best_tour = result['best_solution']
                    distance = -result['best_fitness']  # Negate because fitness is negative distance
                    
                    return {
                        'tour': best_tour,
                        'cost': distance,
                        'method': 'simulated_annealing',
                        'iterations': result['iterations_run']
                    }
                else:
                    # Fallback for other problem types
                    return {"error": f"SA not implemented for {task_type}", "fallback": True}
                    
            except Exception as e:
                return {"error": str(e), "fallback": True}
        
        return sa_solver
    
    # GA/SA helper methods for problem-specific operators
    
    def _ga_knapsack_mutation(self, solution: List[int], rate: float, 
                              items: List[Dict], capacity: int) -> List[int]:
        """Mutate knapsack solution."""
        if self.rng.random() > rate:
            return solution.copy()
        
        mutated = solution.copy()
        action = self.rng.choice(['add', 'remove', 'swap'])
        
        if action == 'add' and len(mutated) < len(items):
            available = [i for i in range(len(items)) if i not in mutated]
            if available:
                idx = self.rng.choice(available)
                mutated.append(idx)
        elif action == 'remove' and mutated:
            mutated.pop(self.rng.randint(0, len(mutated) - 1))
        elif action == 'swap' and mutated:
            idx_to_remove = self.rng.randint(0, len(mutated) - 1)
            available = [i for i in range(len(items)) if i not in mutated]
            if available:
                mutated[idx_to_remove] = self.rng.choice(available)
        
        return mutated
    
    def _ga_knapsack_crossover(self, parent1: List[int], parent2: List[int]) -> tuple:
        """Crossover two knapsack solutions."""
        # Uniform crossover
        child1 = []
        child2 = []
        all_items = set(parent1 + parent2)
        
        for item in all_items:
            if self.rng.random() < 0.5:
                child1.append(item)
            else:
                child2.append(item)
        
        return child1, child2
    
    def _ga_tsp_mutation(self, tour: List[int], rate: float, cities: List[Dict]) -> List[int]:
        """Mutate TSP tour using swap or reversal."""
        if self.rng.random() > rate or len(tour) < 3:
            return tour.copy()
        
        mutated = tour.copy()
        action = self.rng.choice(['swap', 'reverse'])
        
        if action == 'swap':
            i, j = self.rng.sample(range(len(mutated)), 2)
            mutated[i], mutated[j] = mutated[j], mutated[i]
        else:  # reverse
            i, j = sorted(self.rng.sample(range(len(mutated)), 2))
            mutated[i:j+1] = reversed(mutated[i:j+1])
        
        return mutated
    
    def _ga_tsp_crossover(self, parent1: List[int], parent2: List[int]) -> tuple:
        """Order crossover (OX) for TSP."""
        size = len(parent1)
        if size < 3:
            return parent1.copy(), parent2.copy()
        
        # Select crossover points
        cx1, cx2 = sorted(self.rng.sample(range(size), 2))
        
        # Create children
        child1 = [-1] * size
        child2 = [-1] * size
        
        # Copy segment from parents
        child1[cx1:cx2+1] = parent1[cx1:cx2+1]
        child2[cx1:cx2+1] = parent2[cx1:cx2+1]
        
        # Fill remaining with order from other parent
        def fill_child(child, parent, start, end):
            current_idx = (end + 1) % size
            parent_idx = (end + 1) % size
            
            while current_idx != start:
                if parent[parent_idx] not in child:
                    while child[current_idx] != -1:
                        current_idx = (current_idx + 1) % size
                    child[current_idx] = parent[parent_idx]
                parent_idx = (parent_idx + 1) % size
        
        fill_child(child1, parent2, cx1, cx2)
        fill_child(child2, parent1, cx1, cx2)
        
        return child1, child2
    
    def update_operator_stats(self, operator: str, success: bool):
        """Track operator performance."""
        if operator in self.operator_stats:
            self.operator_stats[operator]["total"] += 1
            if success:
                self.operator_stats[operator]["success"] += 1
    
    def get_best_operators(self, top_k: int = 3) -> List[str]:
        """Get top-performing operators."""
        operators_with_rates = []
        for op, stats in self.operator_stats.items():
            if stats["total"] > 0:
                rate = stats["success"] / stats["total"]
                operators_with_rates.append((op, rate))
            else:
                operators_with_rates.append((op, 0.5))
        
        operators_with_rates.sort(key=lambda x: x[1], reverse=True)
        return [op for op, _ in operators_with_rates[:top_k]]
