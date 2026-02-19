
from tiannara_core.cognition.context_processor import ContextProcessor

def test_stability():
    cp = ContextProcessor()
    result = cp.process({'joint_angles': [10, 20, 30]})
    assert 'stability' in result
