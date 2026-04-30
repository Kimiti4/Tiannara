"""Test calling closure with kwargs."""

def make_closure():
    data = [3, 1, 2]
    
    def solve():
        return {"output": sorted(data), "success": True}
    
    return solve

closure = make_closure()

# Try calling with kwargs (what evaluator does)
try:
    result = closure(data=[3, 1, 2])
    print(f"Result: {result}")
except TypeError as e:
    print(f"Error: {e}")
    print("Closures don't accept **kwargs!")
