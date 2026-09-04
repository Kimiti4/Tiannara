#!/usr/bin/env python3
"""
Adaptation Metrics Calculator for Evolutionary Campaign
Calculates key metrics for law discovery from longitudinal data.
"""

import json
from typing import Dict, List, Any
from dataclasses import dataclass

@dataclass
class Observation:
    """Represents a single observation from the campaign."""
    project: str
    generation: int
    scenario: int
    timestamp: str
    fitness: float
    failures: List[str]
    exploits: List[str]
    repairs: List[str]
    survival: bool

@dataclass
class AdaptationMetrics:
    """Calculated adaptation metrics for a project."""
    project: str
    adaptation_velocity: float
    recovery_half_life: float
    failure_recurrence_rate: float
    repair_transferability: float

class AdaptationMetricsCalculator:
    """Calculates adaptation metrics from campaign observations."""
    
    def __init__(self):
        self.observations: List[Observation] = []
    
    def add_observation(self, obs: Observation):
        """Add an observation to the dataset."""
        self.observations.append(obs)
    
    def calculate_adaptation_velocity(self, project: str) -> float:
        """Calculate the average fitness change per generation."""
        project_obs = sorted([o for o in self.observations if o.project == project], key=lambda x: x.generation)
        if len(project_obs) < 2:
            return 0.0
        velocities = []
        for i in range(1, len(project_obs)):
            delta_f = project_obs[i].fitness - project_obs[i-1].fitness
            delta_g = project_obs[i].generation - project_obs[i-1].generation
            if delta_g > 0:
                velocities.append(delta_f / delta_g)
        return sum(velocities) / len(velocities) if velocities else 0.0
    
    def calculate_recovery_half_life(self, project: str) -> float:
        """Calculate the number of generations required to recover 50% of lost fitness after a failure."""
        project_obs = sorted([o for o in self.observations if o.project == project], key=lambda x: x.generation)
        if len(project_obs) < 2:
            return 0.0
        baseline = project_obs[0].fitness
        for i, obs in enumerate(project_obs):
            if not obs.survival:
                loss = baseline - obs.fitness
                target = obs.fitness + (loss * 0.5)
                for j in range(i, len(project_obs)):
                    if project_obs[j].fitness >= target:
                        return float(project_obs[j].generation - obs.generation)
        return 0.0
    
    def calculate_failure_recurrence_rate(self, project: str) -> float:
        """Calculate the percentage of failures that recur after repair."""
        project_obs = [o for o in self.observations if o.project == project]
        total_failures = sum(len(o.failures) for o in project_obs)
        if total_failures == 0:
            return 0.0
        recurring = 0
        seen = set()
        for obs in project_obs:
            for f in obs.failures:
                if f in seen:
                    recurring += 1
                seen.add(f)
        return (recurring / total_failures) * 100.0
    
    def calculate_repair_transferability(self) -> float:
        """Calculate the percentage of repairs that work across different projects."""
        all_repairs = {}
        for obs in self.observations:
            for r in obs.repairs:
                all_repairs.setdefault(r, set()).add(obs.project)
        if not all_repairs:
            return 0.0
        transferable = sum(1 for projects in all_repairs.values() if len(projects) > 1)
        return (transferable / len(all_repairs)) * 100.0
    
    def calculate_all_metrics(self) -> Dict[str, AdaptationMetrics]:
        """Calculate all metrics for all projects."""
        projects = set(o.project for o in self.observations)
        global_trans = self.calculate_repair_transferability()
        results = {}
        for p in projects:
            results[p] = AdaptationMetrics(
                project=p,
                adaptation_velocity=self.calculate_adaptation_velocity(p),
                recovery_half_life=self.calculate_recovery_half_life(p),
                failure_recurrence_rate=self.calculate_failure_recurrence_rate(p),
                repair_transferability=global_trans
            )
        return results

if __name__ == "__main__":
    pass