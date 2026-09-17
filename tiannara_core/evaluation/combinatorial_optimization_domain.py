"""
Combinatorial Optimization Domain - Task Generator

Generates NP-hard optimization problems including:
- Traveling Salesman Problem (TSP)
- Knapsack Problem (0/1, bounded, fractional)
- Graph Coloring
- Job Scheduling
- Set Cover

Tests optimization heuristics, constraint handling, and approximation algorithms.
"""

import random
import math
from typing import Dict, Any, List, Tuple


class CombinatorialOptimizationGenerator:
    """Generates combinatorial optimization tasks with adaptive difficulty."""
    
    def __init__(self, seed: int = None):
        self.rng = random.Random(seed)
        
        # Task types
        self.task_types = [
            "tsp",              # Traveling Salesman Problem
            "knapsack",         # 0/1 Knapsack
            "graph_coloring",   # Graph Coloring Problem
            "scheduling",       # Job Scheduling
            "set_cover"         # Set Cover Problem
        ]
        
        # Adaptive difficulty tracking
        self.episode_count = 0
        self.difficulty_level = "easy"
        self.success_history = []
    
    def _get_difficulty_params(self, episode: int = None) -> Dict[str, Any]:
        """
        Adaptive difficulty based on episode progression and performance.
        
        Phases:
        - Episodes 0-30: Easy (small instances, simple structures)
        - Episodes 31-70: Medium (moderate size)
        - Episodes 71-100: Hard (larger instances, tighter constraints)
        """
        if episode is not None:
            self.episode_count = episode
        
        # Base difficulty from episode progression
        if self.episode_count < 30:
            base_difficulty = "easy"
        elif self.episode_count < 70:
            base_difficulty = "medium"
        else:
            base_difficulty = "hard"
        
        # Adjust based on recent performance
        if len(self.success_history) >= 10:
            recent_success = sum(self.success_history[-10:]) / len(self.success_history[-10:])
            
            if recent_success > 0.7 and base_difficulty != "hard":
                if base_difficulty == "easy":
                    base_difficulty = "medium"
                elif base_difficulty == "medium":
                    base_difficulty = "hard"
            elif recent_success < 0.3 and base_difficulty != "easy":
                if base_difficulty == "hard":
                    base_difficulty = "medium"
                elif base_difficulty == "medium":
                    base_difficulty = "easy"
        
        self.difficulty_level = base_difficulty
        
        # Define parameters for each difficulty level
        params = {
            "easy": {
                "tsp_cities": (4, 6),           # Few cities
                "knapsack_items": (5, 8),       # Few items
                "graph_nodes": (4, 6),          # Small graphs
                "jobs": (3, 5),                 # Few jobs
                "sets": (4, 6),                 # Few sets
                "capacity_ratio": 0.5           # Loose constraints
            },
            "medium": {
                "tsp_cities": (6, 8),           # Moderate cities
                "knapsack_items": (8, 12),      # More items
                "graph_nodes": (6, 8),          # Medium graphs
                "jobs": (5, 7),                 # More jobs
                "sets": (6, 8),                 # More sets
                "capacity_ratio": 0.4           # Tighter constraints
            },
            "hard": {
                "tsp_cities": (8, 10),          # Many cities
                "knapsack_items": (12, 15),     # Many items
                "graph_nodes": (8, 10),         # Larger graphs
                "jobs": (7, 10),                # Many jobs
                "sets": (8, 10),                # Many sets
                "capacity_ratio": 0.3           # Very tight constraints
            }
        }
        
        return params[base_difficulty]
    
    def update_performance(self, success: bool):
        """Record task outcome for adaptive difficulty."""
        self.success_history.append(1 if success else 0)
        if len(self.success_history) > 20:
            self.success_history.pop(0)
    
    def generate_task(self, episode: int = None) -> Dict[str, Any]:
        """
        Generate a combinatorial optimization task.
        
        Args:
            episode: Episode number for adaptive difficulty
            
        Returns:
            Dictionary with task specification
        """
        params = self._get_difficulty_params(episode)
        
        # Select task type
        task_type = self.rng.choice(self.task_types)
        
        # Generate specific task
        if task_type == "tsp":
            task = self._generate_tsp(params)
        elif task_type == "knapsack":
            task = self._generate_knapsack(params)
        elif task_type == "graph_coloring":
            task = self._generate_graph_coloring(params)
        elif task_type == "scheduling":
            task = self._generate_scheduling(params)
        else:  # set_cover
            task = self._generate_set_cover(params)
        
        task["type"] = task_type
        task["difficulty"] = self.difficulty_level
        task["episode"] = self.episode_count
        
        return task
    
    def _generate_tsp(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Generate Traveling Salesman Problem."""
        num_cities = self.rng.randint(*params["tsp_cities"])
        
        # Generate city coordinates
        cities = []
        for i in range(num_cities):
            x = self.rng.uniform(0, 100)
            y = self.rng.uniform(0, 100)
            cities.append({"id": i, "x": round(x, 2), "y": round(y, 2)})
        
        # Calculate distance matrix
        distances = {}
        for i in range(num_cities):
            for j in range(i+1, num_cities):
                dist = math.sqrt((cities[i]["x"] - cities[j]["x"])**2 + 
                               (cities[i]["y"] - cities[j]["y"])**2)
                distances[(i, j)] = round(dist, 2)
                distances[(j, i)] = round(dist, 2)
        
        # Compute optimal solution (brute force for small instances)
        optimal_tour, optimal_cost = self._solve_tsp_brute_force(num_cities, distances)
        
        return {
            "inputs": {
                "cities": cities,
                "distances": {(str(k[0]), str(k[1])): v for k, v in distances.items()},
                "num_cities": num_cities
            },
            "expected_output": {
                "tour": optimal_tour,
                "cost": optimal_cost
            },
            "metadata": {
                "optimal_cost": optimal_cost,
                "search_space_size": math.factorial(num_cities - 1)
            }
        }
    
    def _solve_tsp_brute_force(self, num_cities: int, distances: Dict) -> Tuple[List[int], float]:
        """Solve TSP optimally using brute force (only for small instances)."""
        from itertools import permutations
        
        best_tour = None
        best_cost = float('inf')
        
        # Fix first city, permute rest
        other_cities = list(range(1, num_cities))
        
        for perm in permutations(other_cities):
            tour = [0] + list(perm) + [0]  # Return to start
            
            # Calculate cost
            cost = 0
            for i in range(len(tour) - 1):
                cost += distances.get((tour[i], tour[i+1]), float('inf'))
            
            if cost < best_cost:
                best_cost = cost
                best_tour = tour
        
        return best_tour, round(best_cost, 2)
    
    def _generate_knapsack(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Generate 0/1 Knapsack Problem."""
        num_items = self.rng.randint(*params["knapsack_items"])
        capacity_ratio = params["capacity_ratio"]
        
        # Generate items with weights and values
        items = []
        total_weight = 0
        for i in range(num_items):
            weight = self.rng.randint(1, 20)
            value = self.rng.randint(1, 50)
            items.append({"id": i, "weight": weight, "value": value})
            total_weight += weight
        
        # Set capacity as fraction of total weight
        capacity = max(1, int(total_weight * capacity_ratio))
        
        # Solve optimally using dynamic programming
        optimal_value, selected_items = self._solve_knapsack_dp(items, capacity)
        
        return {
            "inputs": {
                "items": items,
                "capacity": capacity,
                "num_items": num_items
            },
            "expected_output": {
                "max_value": optimal_value,
                "selected_items": selected_items
            },
            "metadata": {
                "total_weight": total_weight,
                "capacity_ratio": capacity_ratio,
                "optimal_value": optimal_value
            }
        }
    
    def _solve_knapsack_dp(self, items: List[Dict], capacity: int) -> Tuple[int, List[int]]:
        """Solve 0/1 knapsack using dynamic programming."""
        n = len(items)
        
        # DP table
        dp = [[0] * (capacity + 1) for _ in range(n + 1)]
        
        # Fill table
        for i in range(1, n + 1):
            w = items[i-1]["weight"]
            v = items[i-1]["value"]
            for j in range(capacity + 1):
                dp[i][j] = dp[i-1][j]
                if w <= j:
                    dp[i][j] = max(dp[i][j], dp[i-1][j-w] + v)
        
        # Backtrack to find selected items
        selected = []
        j = capacity
        for i in range(n, 0, -1):
            if dp[i][j] != dp[i-1][j]:
                selected.append(items[i-1]["id"])
                j -= items[i-1]["weight"]
        
        return dp[n][capacity], sorted(selected)
    
    def _generate_graph_coloring(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Generate Graph Coloring Problem."""
        num_nodes = self.rng.randint(*params["graph_nodes"])
        
        # Generate random graph
        edges = []
        for i in range(num_nodes):
            for j in range(i+1, num_nodes):
                # Edge probability increases with difficulty
                edge_prob = 0.3 if self.difficulty_level == "easy" else \
                           0.5 if self.difficulty_level == "medium" else 0.7
                if self.rng.random() < edge_prob:
                    edges.append((i, j))
        
        # Find chromatic number (minimum colors needed)
        chromatic_number, coloring = self._solve_graph_coloring(num_nodes, edges)
        
        return {
            "inputs": {
                "nodes": list(range(num_nodes)),
                "edges": edges,
                "num_nodes": num_nodes,
                "num_edges": len(edges)
            },
            "expected_output": {
                "chromatic_number": chromatic_number,
                "coloring": coloring  # node_id -> color
            },
            "metadata": {
                "min_colors": chromatic_number,
                "edge_density": len(edges) / (num_nodes * (num_nodes - 1) / 2) if num_nodes > 1 else 0
            }
        }
    
    def _solve_graph_coloring(self, num_nodes: int, edges: List[Tuple[int, int]]) -> Tuple[int, Dict[int, int]]:
        """Solve graph coloring using backtracking."""
        # Build adjacency list
        adj = {i: [] for i in range(num_nodes)}
        for u, v in edges:
            adj[u].append(v)
            adj[v].append(u)
        
        # Try increasing number of colors
        for num_colors in range(1, num_nodes + 1):
            coloring = {}
            if self._color_graph(adj, 0, num_colors, coloring):
                return num_colors, coloring
        
        return num_nodes, {i: i for i in range(num_nodes)}
    
    def _color_graph(self, adj: Dict, node: int, num_colors: int, coloring: Dict) -> bool:
        """Backtracking graph coloring."""
        if node == len(adj):
            return True
        
        for color in range(num_colors):
            # Check if color is valid
            valid = True
            for neighbor in adj[node]:
                if neighbor in coloring and coloring[neighbor] == color:
                    valid = False
                    break
            
            if valid:
                coloring[node] = color
                if self._color_graph(adj, node + 1, num_colors, coloring):
                    return True
                del coloring[node]
        
        return False
    
    def _generate_scheduling(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Generate Job Scheduling Problem."""
        num_jobs = self.rng.randint(*params["jobs"])
        
        # Generate jobs with processing times and deadlines
        jobs = []
        for i in range(num_jobs):
            processing_time = self.rng.randint(1, 10)
            deadline = self.rng.randint(processing_time, processing_time + 20)
            profit = self.rng.randint(1, 100)
            jobs.append({
                "id": i,
                "processing_time": processing_time,
                "deadline": deadline,
                "profit": profit
            })
        
        # Solve using greedy algorithm (schedule by profit/deadline)
        schedule, total_profit = self._solve_scheduling(jobs)
        
        return {
            "inputs": {
                "jobs": jobs,
                "num_jobs": num_jobs
            },
            "expected_output": {
                "schedule": schedule,  # List of job IDs in order
                "total_profit": total_profit
            },
            "metadata": {
                "optimal_profit": total_profit,
                "avg_processing_time": sum(j["processing_time"] for j in jobs) / num_jobs
            }
        }
    
    def _solve_scheduling(self, jobs: List[Dict]) -> Tuple[List[int], int]:
        """Solve job scheduling to maximize profit."""
        # Sort by profit (greedy)
        sorted_jobs = sorted(jobs, key=lambda x: x["profit"], reverse=True)
        
        schedule = []
        total_profit = 0
        time_slots = set()
        
        for job in sorted_jobs:
            # Try to schedule at latest possible slot before deadline
            scheduled = False
            for t in range(job["deadline"], 0, -1):
                if t not in time_slots:
                    time_slots.add(t)
                    schedule.append(job["id"])
                    total_profit += job["profit"]
                    scheduled = True
                    break
        
        return schedule, total_profit
    
    def _generate_set_cover(self, params: Dict[str, Any]) -> Dict[str, Any]:
        """Generate Set Cover Problem."""
        num_sets = self.rng.randint(*params["sets"])
        universe_size = num_sets * 2  # Universe is larger than number of sets
        
        universe = list(range(universe_size))
        
        # Generate sets
        sets = []
        for i in range(num_sets):
            # Each set covers random subset of universe
            set_size = self.rng.randint(2, min(5, universe_size))
            covered = set(self.rng.sample(universe, set_size))
            sets.append({"id": i, "elements": sorted(covered), "cost": self.rng.randint(1, 10)})
        
        # Solve using greedy approximation
        selected_sets, coverage = self._solve_set_cover_greedy(universe, sets)
        
        return {
            "inputs": {
                "universe": universe,
                "sets": sets,
                "universe_size": universe_size,
                "num_sets": num_sets
            },
            "expected_output": {
                "selected_sets": selected_sets,
                "coverage": coverage,
                "total_cost": sum(sets[i]["cost"] for i in selected_sets)
            },
            "metadata": {
                "approximation_ratio": "O(log n)",
                "greedy_solution": True
            }
        }
    
    def _solve_set_cover_greedy(self, universe: List[int], sets: List[Dict]) -> Tuple[List[int], int]:
        """Solve set cover using greedy approximation."""
        uncovered = set(universe)
        selected = []
        
        while uncovered:
            # Find set that covers most uncovered elements per cost
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
        
        return selected, len(universe) - len(uncovered)
    
    def verify_solution(self, task: Dict[str, Any], solution: Any) -> float:
        """
        Verify correctness of solution.
        
        Returns:
            Correctness score (0.0 to 1.0)
        """
        task_type = task["type"]
        expected = task["expected_output"]
        
        if task_type == "tsp":
            return self._verify_tsp(task, solution, expected)
        elif task_type == "knapsack":
            return self._verify_knapsack(task, solution, expected)
        elif task_type == "graph_coloring":
            return self._verify_graph_coloring(task, solution, expected)
        elif task_type == "scheduling":
            return self._verify_scheduling(task, solution, expected)
        elif task_type == "set_cover":
            return self._verify_set_cover(task, solution, expected)
        
        return 0.0
    
    def _verify_tsp(self, task, solution, expected) -> float:
        """Verify TSP solution."""
        if isinstance(solution, dict):
            tour = solution.get("tour", [])
            cost = solution.get("cost", float('inf'))
        elif isinstance(solution, (list, tuple)):
            tour = list(solution)
            # Calculate cost
            distances = task["inputs"]["distances"]
            cost = 0
            for i in range(len(tour) - 1):
                key = (str(tour[i]), str(tour[i+1]))
                cost += distances.get(key, float('inf'))
        else:
            return 0.0
        
        optimal_cost = expected["cost"]
        
        if cost == float('inf'):
            return 0.0
        
        # Score based on how close to optimal
        if cost <= optimal_cost * 1.1:  # Within 10%
            return 1.0
        elif cost <= optimal_cost * 1.5:  # Within 50%
            return 0.7
        else:
            return max(0.0, 1.0 - (cost - optimal_cost) / optimal_cost)
    
    def _verify_knapsack(self, task, solution, expected) -> float:
        """Verify knapsack solution."""
        if isinstance(solution, dict):
            selected = solution.get("selected_items", [])
            value = solution.get("max_value", 0)
        elif isinstance(solution, list):
            selected = solution
            # Calculate value
            items = task["inputs"]["items"]
            capacity = task["inputs"]["capacity"]
            value = 0
            total_weight = 0
            for idx in selected:
                if idx < len(items):
                    value += items[idx]["value"]
                    total_weight += items[idx]["weight"]
            if total_weight > capacity:
                return 0.0
        else:
            return 0.0
        
        optimal_value = expected["max_value"]
        
        if value >= optimal_value:
            return 1.0
        else:
            return value / optimal_value if optimal_value > 0 else 0.0
    
    def _verify_graph_coloring(self, task, solution, expected) -> float:
        """Verify graph coloring solution."""
        if isinstance(solution, dict):
            coloring = solution.get("coloring", {})
            num_colors = solution.get("chromatic_number", len(set(coloring.values())))
        elif isinstance(solution, dict):
            coloring = solution
            num_colors = len(set(coloring.values()))
        else:
            return 0.0
        
        # Check if coloring is valid (no adjacent nodes have same color)
        edges = task["inputs"]["edges"]
        valid = True
        for u, v in edges:
            if u in coloring and v in coloring:
                if coloring[u] == coloring[v]:
                    valid = False
                    break
        
        if not valid:
            return 0.0
        
        optimal_colors = expected["chromatic_number"]
        
        if num_colors == optimal_colors:
            return 1.0
        else:
            # Partial credit for using few colors
            return max(0.0, 1.0 - (num_colors - optimal_colors) / optimal_colors)
    
    def _verify_scheduling(self, task, solution, expected) -> float:
        """Verify scheduling solution."""
        if isinstance(solution, dict):
            schedule = solution.get("schedule", [])
            profit = solution.get("total_profit", 0)
        elif isinstance(solution, list):
            schedule = solution
            # Calculate profit
            jobs = task["inputs"]["jobs"]
            profit = 0
            time = 0
            for job_id in schedule:
                if job_id < len(jobs):
                    job = jobs[job_id]
                    if time + job["processing_time"] <= job["deadline"]:
                        profit += job["profit"]
                        time += job["processing_time"]
        else:
            return 0.0
        
        optimal_profit = expected["total_profit"]
        
        if profit >= optimal_profit:
            return 1.0
        else:
            return profit / optimal_profit if optimal_profit > 0 else 0.0
    
    def _verify_set_cover(self, task, solution, expected) -> float:
        """Verify set cover solution."""
        if isinstance(solution, dict):
            selected = solution.get("selected_sets", [])
            coverage = solution.get("coverage", 0)
        elif isinstance(solution, list):
            selected = solution
            # Calculate coverage
            sets = task["inputs"]["sets"]
            universe = set(task["inputs"]["universe"])
            covered = set()
            for idx in selected:
                if idx < len(sets):
                    covered.update(sets[idx]["elements"])
            coverage = len(covered & universe)
        else:
            return 0.0
        
        universe_size = task["inputs"]["universe_size"]
        
        # Check if all elements are covered
        if coverage >= universe_size:
            return 1.0
        else:
            return coverage / universe_size
