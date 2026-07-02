"""
Algorithm Task Domain - Generates controlled algorithmic problems.

Provides multiple problem types for testing evaluation system:
- Sorting variants
- Mathematical operations
- String transformations
- Search algorithms
"""

import random
from typing import Dict, Any, Callable


class AlgorithmTaskGenerator:
    """Generates algorithm tasks with known ground truth."""

    def __init__(self, seed: int = None):
        """
        Initialize task generator with adaptive difficulty.
        
        Args:
            seed: Random seed for reproducibility
        """
        self.rng = random.Random(seed)
        # Refined: Added optimization and graph tasks for more diversity
        self.task_types = ["sorting", "arithmetic", "string_transform", "search", "optimization", "graph"]
        
        # Adaptive difficulty tracking
        self.episode_count = 0
        self.difficulty_level = "easy"  # easy, medium, hard
        self.success_history = []  # Track recent success rates

    def _get_difficulty_params(self, episode: int = None) -> Dict[str, Any]:
        """
        Adaptive difficulty: Calculate parameters based on episode and performance.
        
        Difficulty scales in 3 phases:
        - Episodes 0-30: Easy (small inputs, simple problems)
        - Episodes 31-70: Medium (moderate inputs)
        - Episodes 71-100: Hard (larger inputs, complex problems)
        
        Also adapts based on recent success rate:
        - If success > 70% in last 10 episodes: Increase difficulty
        - If success < 30% in last 10 episodes: Decrease difficulty
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
            recent_success = sum(self.success_history[-10:]) / 10
            if recent_success > 0.7 and base_difficulty != "hard":
                # Promote to next difficulty level
                if base_difficulty == "easy":
                    base_difficulty = "medium"
                elif base_difficulty == "medium":
                    base_difficulty = "hard"
            elif recent_success < 0.3 and base_difficulty != "easy":
                # Demote to previous difficulty level
                if base_difficulty == "hard":
                    base_difficulty = "medium"
                elif base_difficulty == "medium":
                    base_difficulty = "easy"
        
        self.difficulty_level = base_difficulty
        
        # Return size/complexity parameters for each difficulty
        params = {
            "easy": {
                "sort_size": (3, 7),
                "arith_count": (2, 5),
                "string_len": (3, 8),
                "search_size": (5, 10),
                "opt_items": (3, 5),
                "graph_nodes": (3, 4),
            },
            "medium": {
                "sort_size": (5, 12),
                "arith_count": (4, 8),
                "string_len": (6, 15),
                "search_size": (10, 20),
                "opt_items": (5, 8),
                "graph_nodes": (4, 6),
            },
            "hard": {
                "sort_size": (10, 20),
                "arith_count": (6, 12),
                "string_len": (10, 25),
                "search_size": (20, 50),
                "opt_items": (8, 12),
                "graph_nodes": (5, 8),
            }
        }
        
        return params[base_difficulty]
    
    def update_performance(self, success: bool):
        """Track success rate for adaptive difficulty."""
        self.success_history.append(1 if success else 0)
        # Keep only last 20 episodes
        if len(self.success_history) > 20:
            self.success_history = self.success_history[-20:]

    def generate_task(self, episode: int = None) -> Dict[str, Any]:
        """
        Generate a random algorithm task with adaptive difficulty.
        
        Args:
            episode: Current episode number (for difficulty scaling)
        
        Returns:
            Dictionary with task definition including:
                - type: Task category
                - inputs: Input parameters
                - expected_output: Ground truth answer
                - description: Human-readable description
                - difficulty: Current difficulty level
        """
        # Get difficulty parameters
        diff_params = self._get_difficulty_params(episode)
        
        task_type = self.rng.choice(self.task_types)
        
        if task_type == "sorting":
            return self._generate_sorting_task(diff_params)
        elif task_type == "arithmetic":
            return self._generate_arithmetic_task(diff_params)
        elif task_type == "string_transform":
            return self._generate_string_task(diff_params)
        elif task_type == "search":
            return self._generate_search_task(diff_params)
        elif task_type == "optimization":  # Refined: New task type
            return self._generate_optimization_task(diff_params)
        else:  # graph  # Refined: New task type
            return self._generate_graph_task(diff_params)

    def _generate_sorting_task(self, diff_params: Dict[str, Any]) -> Dict[str, Any]:
        """Generate sorting problem with adaptive difficulty."""
        size_range = diff_params["sort_size"]
        size = self.rng.randint(*size_range)
        data = [self.rng.randint(-100, 100) for _ in range(size)]
        expected = sorted(data)
        
        return {
            "type": "sorting",
            "inputs": {"data": data.copy()},
            "expected_output": expected,
            "description": f"Sort array of {size} elements",
            "difficulty": self.difficulty_level
        }

    def _generate_arithmetic_task(self, diff_params: Dict[str, Any]) -> Dict[str, Any]:
        """Generate arithmetic problem with adaptive difficulty."""
        operation = self.rng.choice(["sum", "product", "max", "min"])
        size_range = diff_params["arith_count"]
        size = self.rng.randint(*size_range)
        numbers = [self.rng.randint(1, 50) for _ in range(size)]
        
        if operation == "sum":
            expected = sum(numbers)
        elif operation == "product":
            expected = 1
            for n in numbers:
                expected *= n
        elif operation == "max":
            expected = max(numbers)
        else:  # min
            expected = min(numbers)
        
        return {
            "type": "arithmetic",
            "inputs": {"numbers": numbers, "operation": operation},
            "expected_output": expected,
            "description": f"Compute {operation} of {size} numbers",
            "difficulty": self.difficulty_level
        }

    def _generate_string_task(self, diff_params: Dict[str, Any]) -> Dict[str, Any]:
        """Generate string transformation problem with adaptive difficulty."""
        transform_type = self.rng.choice(["reverse", "uppercase", "length"])
        len_range = diff_params["string_len"]
        text_len = self.rng.randint(*len_range)
        
        if transform_type == "reverse":
            text = ''.join(self.rng.choices('abcdefghijklmnopqrstuvwxyz', k=text_len))
            expected = text[::-1]
        elif transform_type == "uppercase":
            text = ''.join(self.rng.choices('abcdefghijklmnopqrstuvwxyz', k=text_len))
            expected = text.upper()
        else:  # length
            text = ''.join(self.rng.choices('abcdefghijklmnopqrstuvwxyz', k=text_len))
            expected = len(text)
        
        return {
            "type": "string_transform",
            "inputs": {"text": text, "transform": transform_type},
            "expected_output": expected,
            "description": f"Apply {transform_type} transformation",
            "difficulty": self.difficulty_level
        }

    def _generate_search_task(self, diff_params: Dict[str, Any]) -> Dict[str, Any]:
        """Generate search problem with adaptive difficulty."""
        size_range = diff_params["search_size"]
        size = self.rng.randint(*size_range)
        data = sorted([self.rng.randint(0, 100) for _ in range(size)])
        target = self.rng.choice(data + [self.rng.randint(0, 100)])
        
        # Binary search result
        expected = -1
        left, right = 0, len(data) - 1
        while left <= right:
            mid = (left + right) // 2
            if data[mid] == target:
                expected = mid
                break
            elif data[mid] < target:
                left = mid + 1
            else:
                right = mid - 1
        
        return {
            "type": "search",
            "inputs": {"data": data, "target": target},
            "expected_output": expected,
            "description": f"Find target {target} in sorted array of {size} elements",
            "difficulty": self.difficulty_level
        }
    
    def _generate_optimization_task(self, diff_params: Dict[str, Any]) -> Dict[str, Any]:
        """Performance fix: Generate optimization problem with adaptive difficulty."""
        # Performance fix: Removed knapsack brute force (O(2^n))
        # Now only uses greedy algorithms for fast execution
        opt_type = self.rng.choice(["maximize", "minimize"])
        
        if opt_type == "maximize":
            # Find maximum value under constraint
            items_range = diff_params["opt_items"]
            num_items = self.rng.randint(*items_range)
            values = [self.rng.randint(1, 100) for _ in range(num_items)]
            weights = [self.rng.randint(1, 20) for _ in range(len(values))]
            capacity = sum(weights) // 2
            
            # Simple greedy: pick items by value/weight ratio
            items = list(zip(values, weights))
            items.sort(key=lambda x: x[0]/x[1] if x[1] > 0 else 0, reverse=True)
            
            total_value = 0
            remaining = capacity
            for val, wt in items:
                if wt <= remaining:
                    total_value += val
                    remaining -= wt
            
            return {
                "type": "optimization",
                "inputs": {"values": values, "weights": weights, "capacity": capacity},
                "expected_output": total_value,
                "description": f"Maximize value with {num_items} items and capacity {capacity}",
                "difficulty": self.difficulty_level
            }
        else:  # minimize
            # Find minimum cost path (simplified)
            nodes_range = diff_params["graph_nodes"]
            n = self.rng.randint(*nodes_range)
            costs = [[self.rng.randint(1, 50) for _ in range(n)] for _ in range(n)]
            # Make diagonal zero (no self-loops)
            for i in range(n):
                costs[i][i] = 0
            
            # Simple shortest path: just find min cost edge from node 0
            min_cost = min(costs[0][j] for j in range(1, n))
            
            return {
                "type": "optimization",
                "inputs": {"cost_matrix": costs, "start": 0},
                "expected_output": min_cost,
                "description": f"Find minimum cost from node 0 in {n}-node graph",
                "difficulty": self.difficulty_level
            }
    
    def _generate_graph_task(self, diff_params: Dict[str, Any]) -> Dict[str, Any]:
        """Generate graph algorithm task with adaptive difficulty."""
        graph_type = self.rng.choice(["path_exists", "count_edges", "degree"])
        nodes_range = diff_params["graph_nodes"]
        
        if graph_type == "path_exists":
            # Check if path exists between two nodes
            n = self.rng.randint(*nodes_range)
            edges = []
            # Create a connected graph
            for i in range(n - 1):
                edges.append((i, i + 1))
            # Add some random edges
            for _ in range(self.rng.randint(2, max(3, n))):
                u = self.rng.randint(0, n - 1)
                v = self.rng.randint(0, n - 1)
                if u != v and (u, v) not in edges and (v, u) not in edges:
                    edges.append((u, v))
            
            start = 0
            end = n - 1
            
            # BFS to check connectivity
            from collections import deque
            adj = [[] for _ in range(n)]
            for u, v in edges:
                adj[u].append(v)
                adj[v].append(u)
            
            visited = [False] * n
            queue = deque([start])
            visited[start] = True
            while queue:
                node = queue.popleft()
                if node == end:
                    break
                for neighbor in adj[node]:
                    if not visited[neighbor]:
                        visited[neighbor] = True
                        queue.append(neighbor)
            
            expected = visited[end]
            
            return {
                "type": "graph",
                "inputs": {"edges": edges, "num_nodes": n, "start": start, "end": end},
                "expected_output": expected,
                "description": f"Check if path exists from {start} to {end} in {n}-node graph",
                "difficulty": self.difficulty_level
            }
        elif graph_type == "count_edges":
            # Performance fix: Use deterministic edge generation instead of random
            n = self.rng.randint(*nodes_range)
            max_edges = n * (n - 1) // 2
            num_edges = self.rng.randint(n - 1, min(n * 2, max_edges))  # Cap at max possible edges
            
            # Generate edges deterministically to avoid infinite loops
            edges = []
            # First create a spanning tree (guaranteed connectivity)
            for i in range(n - 1):
                edges.append((i, i + 1))
            
            # Add random extra edges up to num_edges
            existing = set((min(u, v), max(u, v)) for u, v in edges)
            attempts = 0
            while len(edges) < num_edges and attempts < 100:  # Safety limit
                u = self.rng.randint(0, n - 1)
                v = self.rng.randint(0, n - 1)
                if u != v:
                    edge = (min(u, v), max(u, v))
                    if edge not in existing:
                        edges.append(edge)
                        existing.add(edge)
                attempts += 1
            
            return {
                "type": "graph",
                "inputs": {"edges": edges, "num_nodes": n},
                "expected_output": len(edges),
                "description": f"Count edges in graph with {n} nodes",
                "difficulty": self.difficulty_level
            }
        else:  # degree
            # Find degree of a node
            n = self.rng.randint(*nodes_range)
            node = self.rng.randint(0, n - 1)
            edges = []
            degree = 0
            
            for i in range(n):
                if i != node and self.rng.random() < 0.5:
                    edges.append((min(node, i), max(node, i)))
                    degree += 1
            
            # Add some other edges
            for _ in range(self.rng.randint(2, max(3, n))):
                u = self.rng.randint(0, n - 1)
                v = self.rng.randint(0, n - 1)
                if u != v and u != node and v != node:
                    edges.append((min(u, v), max(u, v)))
            
            return {
                "type": "graph",
                "inputs": {"edges": edges, "num_nodes": n, "node": node},
                "expected_output": degree,
                "description": f"Find degree of node {node} in {n}-node graph",
                "difficulty": self.difficulty_level
            }

    def verify_solution(self, task: Dict[str, Any], output: Any) -> bool:
        """
        Verify if output matches expected result.
        
        Args:
            task: Task definition
            output: Actual output from solution
            
        Returns:
            True if output matches expected
        """
        expected = task["expected_output"]
        
        # Handle different comparison types
        if isinstance(expected, list):
            return output == expected
        elif isinstance(expected, (int, float)):
            return abs(output - expected) < 1e-6
        else:
            return output == expected


# Example usage and testing
if __name__ == "__main__":
    generator = AlgorithmTaskGenerator(seed=42)
    
    print("Generating sample algorithm tasks:\n")
    
    for i in range(5):
        task = generator.generate_task()
        print(f"Task {i+1}: {task['description']}")
        print(f"  Type: {task['type']}")
        print(f"  Inputs: {task['inputs']}")
        print(f"  Expected: {task['expected_output']}")
        print()
