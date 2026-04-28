"""
Adaptive Mutation Intelligence

Self-improving mutation system that learns which mutation strategies work best.
"""

import random
from typing import Dict, Any, List, Callable, Optional
from enum import Enum
import logging
import json
from datetime import datetime


class MutationStrategy(Enum):
    """Types of mutation strategies."""
    FLIP_OPERATOR = "flip_op"
    INVERT_CONDITION = "invert_condition"
    SCALE_VALUE = "scale_value"
    SWAP_ARGUMENTS = "swap_arguments"
    INSERT_NODE = "insert_node"
    DELETE_NODE = "delete_node"
    CHANGE_TYPE = "change_type"
    MODIFY_BRANCH = "modify_branch"


class MetaMutator:
    """Self-improving mutation system that adapts based on success."""
    
    def __init__(self, initial_weight: float = 1.0, learning_rate: float = 0.1):
        self.learning_rate = learning_rate
        self.mutation_history = []
        self.performance_stats = {}
        
        # Initialize strategy scores with equal weights
        self.strategy_scores = {
            strategy.value: initial_weight 
            for strategy in MutationStrategy
        }
        
        # Track usage count for each strategy
        self.strategy_usage = {
            strategy.value: 0 
            for strategy in MutationStrategy
        }
        
        # Track success count for each strategy
        self.strategy_success = {
            strategy.value: 0 
            for strategy in MutationStrategy
        }
        
        self.logger = logging.getLogger("tiannara.evolution.meta_mutator")
    
    def choose_strategy(self) -> MutationStrategy:
        """
        Choose a mutation strategy based on learned weights.
        
        Returns:
            Selected mutation strategy
        """
        # Use weighted random selection based on strategy scores
        total_score = sum(self.strategy_scores.values())
        
        if total_score <= 0:
            # If all scores are zero or negative, choose randomly
            strategy = random.choice(list(MutationStrategy))
            self.strategy_usage[strategy.value] += 1
            return strategy
        
        # Weighted random selection
        rand_val = random.uniform(0, total_score)
        cumulative = 0
        
        for strategy in MutationStrategy:
            cumulative += self.strategy_scores[strategy.value]
            if rand_val <= cumulative:
                self.strategy_usage[strategy.value] += 1
                return strategy
        
        # Fallback (shouldn't reach here)
        fallback_strategy = random.choice(list(MutationStrategy))
        self.strategy_usage[fallback_strategy.value] += 1
        return fallback_strategy
    
    def update(self, strategy: MutationStrategy, reward: float, successful: bool = False):
        """
        Update strategy weights based on reward received.
        
        Args:
            strategy: Strategy that was used
            reward: Reward value (higher is better)
            successful: Whether the mutation was successful
        """
        strategy_str = strategy.value
        
        # Update the strategy score using the learning rate
        current_score = self.strategy_scores[strategy_str]
        new_score = current_score + self.learning_rate * (reward - current_score)
        
        # Ensure score doesn't go below zero
        self.strategy_scores[strategy_str] = max(0.1, new_score)
        
        # Update success tracking
        if successful:
            self.strategy_success[strategy_str] += 1
        
        # Log the update
        self.mutation_history.append({
            'strategy': strategy_str,
            'reward': reward,
            'successful': successful,
            'timestamp': datetime.now().isoformat(),
            'updated_score': self.strategy_scores[strategy_str]
        })
        
        self.logger.debug(f"Updated strategy {strategy_str}: score={self.strategy_scores[strategy_str]:.3f}, "
                         f"reward={reward:.3f}, successful={successful}")
    
    def apply_mutation(self, code: str, strategy: Optional[MutationStrategy] = None) -> str:
        """
        Apply a mutation to code based on the selected strategy.
        
        Args:
            code: Original code to mutate
            strategy: Specific strategy to use, or None to choose automatically
            
        Returns:
            Mutated code string
        """
        if strategy is None:
            strategy = self.choose_strategy()
        
        self.logger.debug(f"Applying mutation strategy: {strategy.value}")
        
        try:
            if strategy == MutationStrategy.FLIP_OPERATOR:
                mutated = self._flip_operator(code)
            elif strategy == MutationStrategy.INVERT_CONDITION:
                mutated = self._invert_condition(code)
            elif strategy == MutationStrategy.SCALE_VALUE:
                mutated = self._scale_value(code)
            elif strategy == MutationStrategy.SWAP_ARGUMENTS:
                mutated = self._swap_arguments(code)
            elif strategy == MutationStrategy.INSERT_NODE:
                mutated = self._insert_node(code)
            elif strategy == MutationStrategy.DELETE_NODE:
                mutated = self._delete_node(code)
            elif strategy == MutationStrategy.CHANGE_TYPE:
                mutated = self._change_type(code)
            elif strategy == MutationStrategy.MODIFY_BRANCH:
                mutated = self._modify_branch(code)
            else:
                # Default to identity if strategy is unknown
                mutated = code
        except Exception as e:
            self.logger.error(f"Mutation failed with strategy {strategy.value}: {e}")
            # Return original code if mutation fails
            mutated = code
        
        return mutated
    
    def _flip_operator(self, code: str) -> str:
        """Flip arithmetic operators in the code."""
        # Simple implementation: replace some operators
        replacements = [
            ('+', '-'),
            ('-', '+'),
            ('*', '/'),
            ('/', '*'),
            ('>', '<'),
            ('<', '>'),
            ('>=', '<='),
            ('<=', '>='),
            ('==', '!='),
            ('!=', '=='),
            ('and', 'or'),
            ('or', 'and')
        ]
        
        # Pick a random replacement
        old_op, new_op = random.choice(replacements)
        return code.replace(old_op, new_op)
    
    def _invert_condition(self, code: str) -> str:
        """Invert conditional expressions."""
        # Look for common conditional patterns and invert them
        patterns = [
            ('if ', 'if not '),
            ('while ', 'while not '),
            ('not ', ''),
            ('if not ', 'if '),
            ('while not ', 'while ')
        ]
        
        # Pick a random pattern
        old_pattern, new_pattern = random.choice(patterns)
        return code.replace(old_pattern, new_pattern)
    
    def _scale_value(self, code: str) -> str:
        """Scale numeric literals by a factor."""
        import re
        
        # Find all numbers in the code
        numbers = re.findall(r'\b\d+(\.\d+)?\b', code)
        if not numbers:
            return code
        
        # Pick a random number to scale
        number_to_scale = random.choice(numbers)
        
        # Scale by a random factor
        try:
            original_val = float(number_to_scale)
            factor = random.uniform(0.5, 2.0)  # Scale between 0.5x and 2x
            new_val = original_val * factor
            
            # Replace the first occurrence of this number
            return code.replace(str(number_to_scale), str(new_val), 1)
        except:
            return code  # Return original if conversion fails
    
    def _swap_arguments(self, code: str) -> str:
        """Swap function arguments."""
        import re
        
        # Find function calls with arguments
        # Pattern: function_name(arg1, arg2, ...)
        pattern = r'(\w+)\(([^)]+)\)'
        matches = re.findall(pattern, code)
        
        if not matches:
            return code
        
        # Pick a random function call to modify
        func_name, args_str = random.choice(matches)
        
        # Split arguments and swap two randomly
        args = [arg.strip() for arg in args_str.split(',')]
        if len(args) < 2:
            return code
        
        # Swap two random arguments
        idx1, idx2 = random.sample(range(len(args)), 2)
        args[idx1], args[idx2] = args[idx2], args[idx1]
        
        # Create new function call
        new_args_str = ', '.join(args)
        new_call = f"{func_name}({new_args_str})"
        
        # Replace in code (only first occurrence to avoid changing other calls)
        return code.replace(f"{func_name}({args_str})", new_call, 1)
    
    def _insert_node(self, code: str) -> str:
        """Insert a new operation node."""
        lines = code.split('\n')
        
        # Find a random line to insert after
        insert_at = random.randint(1, len(lines) - 1)
        
        # Create a simple operation to insert
        operations = [
            "temp_var = 0",
            "x = x + 1",
            "y = y * 2",
            "result = None",
            "counter = counter + 1"
        ]
        
        new_line = random.choice(operations)
        lines.insert(insert_at, new_line)
        
        return '\n'.join(lines)
    
    def _delete_node(self, code: str) -> str:
        """Delete a random line of code."""
        lines = code.split('\n')
        
        # Filter out empty lines and essential lines
        non_empty_lines = [(i, line) for i, line in enumerate(lines) 
                          if line.strip() and not line.strip().startswith('#')]
        
        if len(non_empty_lines) < 2:
            return code  # Don't delete if only one line remains
        
        # Pick a random line to delete
        line_idx, line = random.choice(non_empty_lines)
        
        # Remove the line
        del lines[line_idx]
        
        return '\n'.join(lines)
    
    def _change_type(self, code: str) -> str:
        """Change data types in the code."""
        type_changes = [
            ('int', 'float'),
            ('float', 'int'),
            ('str', 'int'),  # May cause runtime errors but that's OK
            ('list', 'tuple'),
            ('tuple', 'list')
        ]
        
        old_type, new_type = random.choice(type_changes)
        return code.replace(old_type, new_type)
    
    def _modify_branch(self, code: str) -> str:
        """Modify branching logic."""
        # Add or remove a simple branch
        if random.choice([True, False]):
            # Add a simple branch
            lines = code.split('\n')
            insert_at = random.randint(1, len(lines) - 1)
            
            branch_code = [
                "if True:",
                "    pass  # New branch added by meta mutator",
                ""
            ]
            
            for line in reversed(branch_code):
                lines.insert(insert_at, line)
            
            return '\n'.join(lines)
        else:
            # Remove a branch if one exists
            lines = code.split('\n')
            for i, line in enumerate(lines):
                stripped = line.strip()
                if stripped.startswith('if ') and stripped.endswith(':'):
                    # Found an if statement, remove this line and the next indented block
                    if i + 1 < len(lines):
                        # Simple removal - just remove the if line
                        del lines[i]
                        return '\n'.join(lines)
        
        return code
    
    def get_strategy_performance(self) -> Dict[str, Dict[str, float]]:
        """
        Get performance metrics for each strategy.
        
        Returns:
            Dictionary with strategy performance metrics
        """
        performance = {}
        
        for strategy in MutationStrategy:
            strategy_str = strategy.value
            usage = self.strategy_usage[strategy_str]
            success = self.strategy_success[strategy_str]
            
            success_rate = success / usage if usage > 0 else 0.0
            avg_score = self.strategy_scores[strategy_str]
            
            performance[strategy_str] = {
                'usage_count': usage,
                'success_count': success,
                'success_rate': success_rate,
                'average_score': avg_score
            }
        
        return performance
    
    def reset(self):
        """Reset the mutator to initial state."""
        initial_weight = 1.0
        self.strategy_scores = {
            strategy.value: initial_weight 
            for strategy in MutationStrategy
        }
        self.strategy_usage = {
            strategy.value: 0 
            for strategy in MutationStrategy
        }
        self.strategy_success = {
            strategy.value: 0 
            for strategy in MutationStrategy
        }
        self.mutation_history = []
        
        self.logger.info("MetaMutator reset to initial state")


# Example usage
if __name__ == "__main__":
    # Create a sample code to mutate
    sample_code = """
def example_function(x, y):
    if x > 5:
        z = x * 2
    else:
        z = x + 10
    result = z + y
    return result
"""
    
    print("Original code:")
    print(sample_code)
    
    # Create meta mutator
    mutator = MetaMutator()
    
    # Apply several mutations
    current_code = sample_code
    for i in range(5):
        strategy = mutator.choose_strategy()
        print(f"\nMutation {i+1} using strategy: {strategy.value}")
        
        mutated_code = mutator.apply_mutation(current_code, strategy)
        print("Mutated code:")
        print(mutated_code)
        
        # Simulate evaluation - give reward based on some criteria
        # For demo, we'll just give random rewards
        reward = random.uniform(0.1, 1.0)
        successful = random.choice([True, False])
        
        mutator.update(strategy, reward, successful)
        print(f"Reward: {reward:.3f}, Successful: {successful}")
        
        current_code = mutated_code
    
    # Print performance stats
    print("\nStrategy Performance:")
    performance = mutator.get_strategy_performance()
    for strategy, stats in performance.items():
        print(f"  {strategy}: success_rate={stats['success_rate']:.3f}, "
              f"usage={stats['usage_count']}, avg_score={stats['average_score']:.3f}")
    
    print(f"\nTotal mutations performed: {len(mutator.mutation_history)}")