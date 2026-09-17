from enum import Enum
from pydantic import BaseModel, Field
from typing import List, Dict, Optional
import uuid


class PhysicsCategory(str, Enum):
    SEMANTIC = "semantic"
    CAUSAL = "causal"
    TOPOLOGICAL = "topological"
    ECOLOGICAL = "ecological"
    INFORMATIONAL = "informational"
    STABILIZING = "stabilizing"


class LawDecay(BaseModel):
    """
    Every deployed law has automatic temporal decay unless renewed.
    Prevents ontology sediment and branch complexity explosions.
    """
    half_life_ticks: int = Field(default=1000, description="Number of execution ticks before law influence halves")
    renewal_mode: str = Field(default="survivability_based", description="How the law can be renewed")


class ResourceProfile(BaseModel):
    """
    URCL projections for the law.
    Must be included before reaching Elixir to ensure budget constraints.
    """
    expected_branch_factor: float
    entropy_impact: str  # "low", "medium", "high"
    topology_pressure: str
    stabilization_cost: str

class ObserverSignature(BaseModel):
    """
    Observer identity isolation for law lineage accountability.
    """
    observer_id: str
    lineage: str
    ontology_class: str
    trust_score: float = Field(default=0.5, ge=0.0, le=1.0)


class PhysicsIntentSpecification(BaseModel):
    """
    Physics Intent Specification (PIS)
    The strictly declarative boundary between Python cognition and Elixir substrate authority.
    Python may NEVER define execution semantics, tensor ops, or topology rewrites here.
    """
    intent_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    
    # 1. Strict Declarative DSL
    category: PhysicsCategory
    domain: str
    interaction: str
    target: str
    
    # 2. Hard Constraints
    conservation_enabled: bool = True
    
    # 3. Decay & Reversibility
    law_decay: LawDecay
    reversible: bool = True  # Always True initially
    
    # 4. Attribution
    observer_signature: ObserverSignature
    
    # 5. Budgets & Epistemic Uncertainty (Stage 2)
    resource_profile: ResourceProfile
    epistemic_confidence: float = Field(ge=0.0, le=1.0, description="EUF semantic ambiguity score")
    
    # Human-readable concept
    description: str
