"""
Algorithm Engine

Wraps tiannara_core.evolution and tiannara_core.evolution.evolution_loop
Provides algorithmic optimization, parameter search, and evolutionary computation.
"""

import time
import logging
from typing import Dict, Any

from tiannara_api.engines.base import BaseEngine
from tiannara_core.evolution.evolution import evolve
from tiannara_core.evolution.evolution_loop import EvolutionLoop

logger = logging.getLogger(__name__)


class AlgorithmEngine(BaseEngine):
    """
    Algorithm Engine for evolutionary computation and optimization.
    
    Handles:
    - Parameter optimization
    - Evolutionary algorithms
    - Fitness function evaluation
    - Population-based search
    """
    
    def __init__(self):
        super().__init__(name="algorithm_engine", version="1.0.0")
        self.evolution_loop = EvolutionLoop()
        logger.info("Algorithm Engine initialized")
    
    def process(self, request: Dict[str, Any]) -> Dict[str, Any]:
        """
        Process algorithmic optimization request.
        
        Expected request format:
        {
            "question": str,
            "population_size": int (optional, default 24),
            "generations": int (optional, default 12),
            "fitness_function": str (optional),
            "genome_type": str (optional, "neural"|"graph"|"mixed")
        }
        """
        start_time = time.time()
        
        try:
            question = request.get("question", "Optimize prosthetic grip stability")
            population_size = request.get("population_size", 24)
            generations = request.get("generations", 12)
            fitness_function = request.get("fitness_function", "grip_stability")
            genome_type = request.get("genome_type", "neural")
            
            # Execute evolution
            result = evolve(
                question=question,
                population_size=population_size,
                generations=generations,
                fitness_function=fitness_function,
                genome_type=genome_type,
            )
            
            latency_ms = (time.time() - start_time) * 1000
            self.track_request(latency_ms, success=True)
            
            return {
                "status": "success",
                "engine": "algorithm_engine",
                "result": result,
                "latency_ms": round(latency_ms, 2),
            }
        
        except Exception as e:
            latency_ms = (time.time() - start_time) * 1000
            self.track_request(latency_ms, success=False)
            logger.error(f"Algorithm Engine error: {str(e)}")
            
            return {
                "status": "error",
                "engine": "algorithm_engine",
                "error": str(e),
                "latency_ms": round(latency_ms, 2),
            }
    
    def get_health(self) -> Dict[str, Any]:
        """Get engine health status."""
        metrics = self.get_metrics()
        return {
            "engine": "algorithm_engine",
            "status": metrics["status"],
            "uptime_percentage": 100.0,
            "total_requests": metrics["total_requests"],
            "avg_latency_ms": metrics["avg_latency_ms"],
            "success_rate": metrics["success_rate"],
        }
