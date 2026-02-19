
from tiannara_core.memory.memory_engine import MemoryEngine

def test_record_and_recall():
    mem = MemoryEngine()
    mem.record({'intent': 'test', 'tags': ['unit']})
    assert len(mem.recall()) == 1
