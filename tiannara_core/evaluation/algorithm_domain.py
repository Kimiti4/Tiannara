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
        Initialize task generator.
        
        Args:
            seed: Random seed for reproducibility
        """
        self.rng = random.Random(seed)
        # Refined: Added optimization and graph tasks for more diversity
        self.task_types = ["sorting", "arithmetic", "string_transform", "search", "optimization", "graph"]

    def generate_task(self) -> Dict[str, Any]:
        """
        Generate a random algorithm task.
        
        Returns:
            Dictionary with task definition including:
                - type: Task category
                - inputs: Input parameters
                - expected_output: Ground truth answer
                - description: Human-readable description
        """
        task_type = self.rng.choice(self.task_types)
        
        if task_type == "sorting":
            return self._generate_sorting_task()
        elif task_type == "arithmetic":
            return self._generate_arithmetic_task()
        elif task_type == "string_transform":
            return self._generate_string_task()
        elif task_type == "search":
            return self._generate_search_task()
        elif task_type == "optimization":  # Refined: New task type
            return self._generate_optimization_task()
        else:  # graph  # Refined: New task type
            return self._generate_graph_task()

    def _generate_sorting_task(self) -> Dict[str, Any]:
        """Generate sorting problem."""
        size = self.rng.randint(5, 15)
        data = [self.rng.randint(-100, 100) for _ in range(size)]
        expected = sorted(data)
        
        return {
            "type": "sorting",
            "inputs": {"data": data.copy()},
            "expected_output": expected,
            "description": f"Sort array of {size} elements"
        }

    def _generate_arithmetic_task(self) -> Dict[str, Any]:
        """Generate arithmetic problem."""
        operation = self.rng.choice(["sum", "product", "max", "min"])
        size = self.rng.randint(3, 10)
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
            "description": f"Compute {operation} of {size} numbers"
        }

    def _generate_string_task(self) -> Dict[str, Any]:
        """Generate string transformation problem."""
        transform_type = self.rng.choice(["reverse", "uppercase", "length"])
        
        if transform_type == "reverse":
            text = ''.join(self.rng.choices('abcdefghijklmnopqrstuvwxyz', k=10))
            expected = text[::-1]
        elif transform_type == "uppercase":
            text = ''.join(self.rng.choices('abcdefghijklmnopqrstuvwxyz', k=10))
            expected = text.upper()
        else:  # length
            text = ''.join(self.rng.choices('abcdefghijklmnopqrstuvwxyz', k=10))
            expected = len(text)
        
        return {
            "type": "string_transform",
            "inputs": {"text": text, "transform": transform_type},
            "expected_output": expected,
            "description": f"Apply {transform_type} transformation"
        }

    def _generate_search_task(self) -> Dict[str, Any]:
        """Generate search problem."""
        size = self.rng.randint(10, 30)
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
            "description": f"Find target {target} in sorted array"
        }
    
    def _generate_optimization_task(self) -> Dict[str, Any]:
        """Performance fix: Generate optimization problem (simplified - no knapsack)."""
        # Performance fix: Removed knapsack brute force (O(2^n))
        # Now only uses greedy algorithms for fast execution
        opt_type = self.rng.choice(["maximize", "minimize"])
        
        if opt_type == "maximize":
            # Find maximum value under constraint
            values = [self.rng.randint(1, 100) for _ in range(self.rng.randint(5, 10))]
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
                "description": f"Maximize value with capacity {capacity}"
            }
        elif opt_type == "minimize":
            # Find minimum cost path (simplified)
            n = self.rng.randint(3, 6)
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
                "description": f"Find minimum cost from node 0 in {n}-node graph"
            }
    
    def _generate_graph_task(self) -> Dict[str, Any]:
        """Refined: Generate graph algorithm task."""
        graph_type = self.rng.choice(["path_exists", "count_edges", "degree"])
        
        if graph_type == "path_exists":
            # Performance fix: Reduced from randint(4, 8) to randint(3, 5)
            n = self.rng.randint(3, 5)
            edges = []
            # Create a connected graph
            for i in range(n - 1):
                edges.append((i, i + 1))
            # Add some random edges
            for _ in range(self.rng.randint(2, 5)):
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
                "description": f"Check if path exists from {start} to {end}"
            }
        elif graph_type == "count_edges":
            # Count edges in graph
            n = self.rng.randint(3, 7)
            num_edges = self.rng.randint(n - 1, n * 2)
            edges = set()
            while len(edges) < num_edges:
                u = self.rng.randint(0, n - 1)
                v = self.rng.randint(0, n - 1)
                if u != v:
                    edges.add((min(u, v), max(u, v)))
            
            return {
                "type": "graph",
                "inputs": {"edges": list(edges), "num_nodes": n},
                "expected_output": len(edges),
                "description": f"Count edges in graph with {n} nodes"
            }
        else:  # degree
            # Performance fix: Reduced from randint(4, 8) to randint(3, 5)
            n = self.rng.randint(3, 5)
            node = self.rng.randint(0, n - 1)
            edges = []
            degree = 0
            
            for i in range(n):
                if i != node and self.rng.random() < 0.5:
                    edges.append((min(node, i), max(node, i)))
                    degree += 1
            
            # Add some other edges
            for _ in range(self.rng.randint(2, 5)):
                u = self.rng.randint(0, n - 1)
                v = self.rng.randint(0, n - 1)
                if u != v and u != node and v != node:
                    edges.append((min(u, v), max(u, v)))
            
            return {
                "type": "graph",
                "inputs": {"edges": edges, "num_nodes": n, "node": node},
                "expected_output": degree,
                "description": f"Find degree of node {node}"
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
