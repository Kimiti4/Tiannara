"""
Task Taxonomy System for Algorithm Domain

Defines a comprehensive type system for algorithmic tasks to ensure
generator-evaluator compatibility and domain-aware evaluation.
"""

from enum import Enum
from typing import Dict, List, Optional, Any, Set
from dataclasses import dataclass, field


class AlgorithmCategory(Enum):
    """High-level algorithm categories."""
    SORTING = "sorting"
    SEARCH = "search"
    DYNAMIC_PROGRAMMING = "dynamic_programming"
    GRAPH = "graph"
    GREEDY = "greedy"
    DIVIDE_AND_CONQUER = "divide_and_conquer"
    BACKTRACKING = "backtracking"
    OPTIMIZATION = "optimization"


class DPSubcategory(Enum):
    """Dynamic programming subcategories."""
    DP_NUMERIC = "dp_numeric"
    DP_STRING = "dp_string"
    DP_GRAPH = "dp_graph"
    DP_2D = "dp_2d"
    DP_INTERVAL = "dp_interval"


class GraphSubcategory(Enum):
    """Graph algorithm subcategories."""
    SHORTEST_PATH = "shortest_path"
    MINIMUM_SPANNING_TREE = "minimum_spanning_tree"
    TOPOLOGICAL_SORT = "topological_sort"
    CONNECTIVITY = "connectivity"
    FLOW = "flow"
    MATCHING = "matching"


@dataclass
class TaskType:
    """
    Represents a typed algorithmic task.
    
    Ensures generator and evaluator agree on task semantics.
    """
    category: AlgorithmCategory
    subcategory: Optional[Enum] = None
    difficulty: str = "medium"  # easy, medium, hard
    tags: List[str] = field(default_factory=list)
    
    def matches(self, other: 'TaskType') -> bool:
        """Check if this task type is compatible with another."""
        if self.category != other.category:
            return False
        
        # If both have subcategories, they must match
        if self.subcategory and other.subcategory:
            return self.subcategory == other.subcategory
        
        # If one has subcategory and other doesn't, check if compatible
        if self.subcategory or other.subcategory:
            return True  # Partial match
        
        return True
    
    def to_dict(self) -> Dict[str, Any]:
        """Serialize task type."""
        return {
            'category': self.category.value,
            'subcategory': self.subcategory.value if self.subcategory else None,
            'difficulty': self.difficulty,
            'tags': self.tags
        }
    
    def __str__(self):
        base = self.category.value
        if self.subcategory:
            base += f"/{self.subcategory.value}"
        return base


@dataclass
class AlgorithmTask:
    """
    A fully typed algorithmic task.
    
    Contains all information needed for generation and evaluation.
    """
    task_id: str
    task_type: TaskType
    inputs: Dict[str, Any]
    expected_output: Any
    description: str
    constraints: Dict[str, Any] = field(default_factory=dict)
    metadata: Dict[str, Any] = field(default_factory=dict)
    
    def validate_against_evaluator(self, supported_types: List[TaskType]) -> bool:
        """Check if this task is supported by an evaluator."""
        for supported in supported_types:
            if self.task_type.matches(supported):
                return True
        return False
    
    def to_dict(self) -> Dict[str, Any]:
        """Serialize task."""
        return {
            'task_id': self.task_id,
            'task_type': self.task_type.to_dict(),
            'inputs': self.inputs,
            'description': self.description,
            'constraints': self.constraints
        }


class TaskTaxonomy:
    """
    Manages the hierarchy and relationships between task types.
    
    Provides:
    - Type validation
    - Compatibility checking
    - Curriculum organization
    """
    
    def __init__(self):
        # Define supported task types for each evaluator
        self.evaluator_support: Dict[str, List[TaskType]] = {}
        
        # Curriculum tree structure
        self.curriculum: Dict[str, List[str]] = {
            'algorithms': [
                'basic_arithmetic',
                'recursion',
                'sorting',
                'searching',
                'dynamic_programming',
                'graph_algorithms',
                'greedy_algorithms',
                'optimization'
            ],
            'dynamic_programming': [
                'dp_numeric',
                'dp_string', 
                'dp_graph',
                'dp_2d',
                'dp_interval'
            ],
            'graph_algorithms': [
                'shortest_path',
                'minimum_spanning_tree',
                'topological_sort',
                'connectivity',
                'flow_networks'
            ]
        }
        
        # Register default evaluators
        self._register_default_evaluators()
    
    def _register_default_evaluators(self):
        """Register default evaluator support mappings."""
        
        # Dynamic Programming Evaluator
        dp_types = [
            TaskType(AlgorithmCategory.DYNAMIC_PROGRAMMING, DPSubcategory.DP_NUMERIC),
            TaskType(AlgorithmCategory.DYNAMIC_PROGRAMMING, DPSubcategory.DP_STRING),
            TaskType(AlgorithmCategory.DYNAMIC_PROGRAMMING, DPSubcategory.DP_GRAPH),
            TaskType(AlgorithmCategory.DYNAMIC_PROGRAMMING, DPSubcategory.DP_2D),
        ]
        self.evaluator_support['dp_evaluator'] = dp_types
        
        # Graph Algorithm Evaluator
        graph_types = [
            TaskType(AlgorithmCategory.GRAPH, GraphSubcategory.SHORTEST_PATH),
            TaskType(AlgorithmCategory.GRAPH, GraphSubcategory.MINIMUM_SPANNING_TREE),
            TaskType(AlgorithmCategory.GRAPH, GraphSubcategory.TOPOLOGICAL_SORT),
        ]
        self.evaluator_support['graph_evaluator'] = graph_types
        
        # Sorting Evaluator
        sorting_types = [
            TaskType(AlgorithmCategory.SORTING),
        ]
        self.evaluator_support['sorting_evaluator'] = sorting_types
        
        # Search Evaluator
        search_types = [
            TaskType(AlgorithmCategory.SEARCH),
        ]
        self.evaluator_support['search_evaluator'] = search_types
    
    def register_evaluator(self, evaluator_name: str, supported_types: List[TaskType]):
        """Register which task types an evaluator supports."""
        self.evaluator_support[evaluator_name] = supported_types
    
    def get_compatible_evaluators(self, task_type: TaskType) -> List[str]:
        """Find all evaluators that can handle a given task type."""
        compatible = []
        for evaluator_name, supported_types in self.evaluator_support.items():
            for supported in supported_types:
                if task_type.matches(supported):
                    compatible.append(evaluator_name)
                    break
        return compatible
    
    def validate_task(self, task: AlgorithmTask, evaluator_name: str) -> bool:
        """Validate that a task is compatible with an evaluator."""
        if evaluator_name not in self.evaluator_support:
            raise ValueError(f"Unknown evaluator: {evaluator_name}")
        
        supported_types = self.evaluator_support[evaluator_name]
        return task.validate_against_evaluator(supported_types)
    
    def get_curriculum_path(self, start_category: str, end_category: str) -> List[str]:
        """Get learning path from one category to another."""
        # Simplified - would use graph traversal in production
        if start_category in self.curriculum and end_category in self.curriculum[start_category]:
            return [start_category, end_category]
        return []
    
    def get_all_categories(self) -> List[str]:
        """Get all algorithm categories."""
        return [cat.value for cat in AlgorithmCategory]
    
    def get_subcategories(self, category: AlgorithmCategory) -> List[str]:
        """Get subcategories for a given category."""
        if category == AlgorithmCategory.DYNAMIC_PROGRAMMING:
            return [sub.value for sub in DPSubcategory]
        elif category == AlgorithmCategory.GRAPH:
            return [sub.value for sub in GraphSubcategory]
        return []
    
    def to_dict(self) -> Dict:
        """Serialize taxonomy."""
        return {
            'evaluators': {
                name: [t.to_dict() for t in types]
                for name, types in self.evaluator_support.items()
            },
            'curriculum': self.curriculum,
            'categories': self.get_all_categories()
        }


# Helper functions for creating common task types
def create_dp_numeric_task(difficulty: str = "medium") -> TaskType:
    """Create a numeric dynamic programming task type."""
    return TaskType(
        category=AlgorithmCategory.DYNAMIC_PROGRAMMING,
        subcategory=DPSubcategory.DP_NUMERIC,
        difficulty=difficulty,
        tags=['fibonacci', 'knapsack', 'coin_change']
    )


def create_dp_string_task(difficulty: str = "medium") -> TaskType:
    """Create a string dynamic programming task type."""
    return TaskType(
        category=AlgorithmCategory.DYNAMIC_PROGRAMMING,
        subcategory=DPSubcategory.DP_STRING,
        difficulty=difficulty,
        tags=['lcs', 'edit_distance', 'palindrome']
    )


def create_shortest_path_task(difficulty: str = "medium") -> TaskType:
    """Create a shortest path graph task type."""
    return TaskType(
        category=AlgorithmCategory.GRAPH,
        subcategory=GraphSubcategory.SHORTEST_PATH,
        difficulty=difficulty,
        tags=['dijkstra', 'bellman_ford', 'floyd_warshall']
    )


if __name__ == "__main__":
    # Example usage
    taxonomy = TaskTaxonomy()
    
    # Create a DP task
    dp_task_type = create_dp_numeric_task("hard")
    print(f"Task type: {dp_task_type}")
    
    # Find compatible evaluators
    compatible = taxonomy.get_compatible_evaluators(dp_task_type)
    print(f"Compatible evaluators: {compatible}")
    
    # Get curriculum info
    print(f"\nAll categories: {taxonomy.get_all_categories()}")
    print(f"DP subcategories: {taxonomy.get_subcategories(AlgorithmCategory.DYNAMIC_PROGRAMMING)}")
