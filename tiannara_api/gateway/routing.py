"""
Request Routing Logic

Routes incoming API requests to appropriate domain engines.
Supports direct engine calls and multi-domain orchestration.
"""

from typing import Dict, Any, Optional, Callable
import logging

logger = logging.getLogger(__name__)

# Route mapping: endpoint -> engine name
ROUTE_MAP = {
    "/api/predict": "prediction_engine",
    "/api/reason": "logic_engine",
    "/api/analyze": "nlp_engine",
    "/api/causal": "causal_engine",
    "/api/algorithm": "algorithm_engine",
    "/api/evolve": "algorithm_engine",
    "/api/discovery": "nlp_engine",
}

# Engine registry - will be populated at runtime
ENGINE_REGISTRY: Dict[str, Any] = {}


def register_engine(name: str, engine: Any):
    """Register an engine instance in the routing registry."""
    ENGINE_REGISTRY[name] = engine
    logger.info(f"Engine registered: {name}")


def get_engine(endpoint: str) -> Optional[Any]:
    """
    Get the appropriate engine for an endpoint.
    
    Args:
        endpoint: API endpoint path
        
    Returns:
        Engine instance or None if not found
    """
    engine_name = ROUTE_MAP.get(endpoint)
    
    if not engine_name:
        logger.warning(f"No route mapping for endpoint: {endpoint}")
        return None
    
    engine = ENGINE_REGISTRY.get(engine_name)
    
    if not engine:
        logger.warning(f"Engine not registered: {engine_name}")
        return None
    
    return engine


def get_all_engines() -> Dict[str, Any]:
    """Get all registered engines."""
    return ENGINE_REGISTRY.copy()


def get_route_for_engine(engine_name: str) -> Optional[str]:
    """Get the endpoint route for a given engine name."""
    for endpoint, name in ROUTE_MAP.items():
        if name == engine_name:
            return endpoint
    return None
