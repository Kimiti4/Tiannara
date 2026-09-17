"""
Cognitive Domains API Routes

Provides REST endpoints for accessing Tiannara's cognitive domain engines:
- Metacognition (monitoring & coordination)
- Collective Intelligence (multi-agent collaboration)
- Creative Synthesis (innovation & idea generation)
- Social Intelligence (human interface & empathy)
- Ethical Reasoning (safety & alignment)
- Embodied Cognition (grounded reasoning & simulation)

Based on tiannara_core/cognitive_domains/ modules.
"""

from fastapi import APIRouter, HTTPException, Depends
from typing import Dict, Any, Optional, List
from pydantic import BaseModel
import time

router = APIRouter(prefix="/cognitive-domains", tags=["Cognitive Domains"])


# Request/Response Models
class DomainQueryRequest(BaseModel):
    query: str
    context: Optional[Dict[str, Any]] = {}
    domain: Optional[str] = None  # Specific domain to use


class DomainStatusResponse(BaseModel):
    domain: str
    status: str  # "operational", "degraded", "offline"
    version: str
    last_active: float
    capabilities: List[str]


class DomainResultResponse(BaseModel):
    domain: str
    result: Dict[str, Any]
    processing_time_ms: float
    confidence: float
    metadata: Dict[str, Any]


# Initialize domain engines (lazy loading)
_domain_engines = {}


def get_metacognition_engine():
    """Get or initialize metacognition engine."""
    if 'metacognition' not in _domain_engines:
        try:
            from tiannara_core.cognitive_domains.metacognition import MetaCognitionDomain
            _domain_engines['metacognition'] = MetaCognitionDomain()
        except Exception as e:
            raise HTTPException(status_code=503, detail=f"Metacognition engine unavailable: {str(e)}")
    return _domain_engines['metacognition']


def get_collective_intelligence_engine():
    """Get or initialize collective intelligence engine."""
    if 'collective_intelligence' not in _domain_engines:
        try:
            from tiannara_core.cognitive_domains.collective_intelligence import CollectiveIntelligenceDomain
            _domain_engines['collective_intelligence'] = CollectiveIntelligenceDomain()
        except Exception as e:
            raise HTTPException(status_code=503, detail=f"Collective intelligence engine unavailable: {str(e)}")
    return _domain_engines['collective_intelligence']


def get_creative_synthesis_engine():
    """Get or initialize creative synthesis engine."""
    if 'creative_synthesis' not in _domain_engines:
        try:
            from tiannara_core.cognitive_domains.creative_synthesis import CreativeSynthesisDomain
            _domain_engines['creative_synthesis'] = CreativeSynthesisDomain()
        except Exception as e:
            raise HTTPException(status_code=503, detail=f"Creative synthesis engine unavailable: {str(e)}")
    return _domain_engines['creative_synthesis']


def get_social_intelligence_engine():
    """Get or initialize social intelligence engine."""
    if 'social_intelligence' not in _domain_engines:
        try:
            from tiannara_core.cognitive_domains.social_intelligence import SocialIntelligenceDomain
            _domain_engines['social_intelligence'] = SocialIntelligenceDomain()
        except Exception as e:
            raise HTTPException(status_code=503, detail=f"Social intelligence engine unavailable: {str(e)}")
    return _domain_engines['social_intelligence']


def get_ethical_reasoning_engine():
    """Get or initialize ethical reasoning engine."""
    if 'ethical_reasoning' not in _domain_engines:
        try:
            from tiannara_core.cognitive_domains.ethical_reasoning import EthicalReasoningDomain
            _domain_engines['ethical_reasoning'] = EthicalReasoningDomain()
        except Exception as e:
            raise HTTPException(status_code=503, detail=f"Ethical reasoning engine unavailable: {str(e)}")
    return _domain_engines['ethical_reasoning']


def get_embodied_cognition_engine():
    """Get or initialize embodied cognition engine."""
    if 'embodied_cognition' not in _domain_engines:
        try:
            from tiannara_core.cognitive_domains.embodied_cognition import EmbodiedCognitionDomain
            _domain_engines['embodied_cognition'] = EmbodiedCognitionDomain()
        except Exception as e:
            raise HTTPException(status_code=503, detail=f"Embodied cognition engine unavailable: {str(e)}")
    return _domain_engines['embodied_cognition']


@router.get("/status", response_model=List[DomainStatusResponse])
async def get_all_domains_status():
    """
    Get status of all cognitive domain engines.
    
    Returns operational status for each domain.
    """
    domains = [
        ('metacognition', 'Meta-Cognition', ['monitoring', 'coordination', 'self_reflection']),
        ('collective_intelligence', 'Collective Intelligence', ['debate', 'synthesis', 'consensus']),
        ('creative_synthesis', 'Creative Synthesis', ['ideation', 'divergent_thinking', 'novelty']),
        ('social_intelligence', 'Social Intelligence', ['empathy', 'theory_of_mind', 'communication']),
        ('ethical_reasoning', 'Ethical Reasoning', ['alignment', 'safety', 'value_preservation']),
        ('embodied_cognition', 'Embodied Cognition', ['simulation', 'grounded_reasoning', 'spatial']),
    ]
    
    status_list = []
    for domain_id, name, capabilities in domains:
        try:
            # Try to get engine to check if operational
            engine_getter = globals()[f'get_{domain_id}_engine']
            engine = engine_getter()
            
            status_list.append(DomainStatusResponse(
                domain=name,
                status="operational",
                version="1.0.0",
                last_active=time.time(),
                capabilities=capabilities
            ))
        except Exception as e:
            status_list.append(DomainStatusResponse(
                domain=name,
                status="offline",
                version="N/A",
                last_active=0.0,
                capabilities=capabilities
            ))
    
    return status_list


@router.post("/metacognition/process", response_model=DomainResultResponse)
async def process_metacognition(request: DomainQueryRequest):
    """
    Process query through metacognition domain.
    
    Performs self-monitoring, coordination, and reflection on cognitive processes.
    """
    start_time = time.time()
    
    try:
        engine = get_metacognition_engine()
        
        # Process through metacognition
        result = engine.process_query(
            query=request.query,
            context=request.context or {}
        )
        
        processing_time = (time.time() - start_time) * 1000
        
        return DomainResultResponse(
            domain="metacognition",
            result=result,
            processing_time_ms=processing_time,
            confidence=result.get('confidence', 0.5),
            metadata={
                'timestamp': time.time(),
                'query_length': len(request.query)
            }
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Metacognition processing failed: {str(e)}")


@router.post("/collective-intelligence/debate", response_model=DomainResultResponse)
async def run_collective_debate(request: DomainQueryRequest):
    """
    Run multi-agent debate through collective intelligence domain.
    
    Simulates debate between multiple agent perspectives to reach consensus.
    """
    start_time = time.time()
    
    try:
        engine = get_collective_intelligence_engine()
        
        # Run debate
        result = engine.run_debate(
            topic=request.query,
            context=request.context or {},
            num_agents=request.context.get('num_agents', 5)
        )
        
        processing_time = (time.time() - start_time) * 1000
        
        return DomainResultResponse(
            domain="collective_intelligence",
            result=result,
            processing_time_ms=processing_time,
            confidence=result.get('consensus_confidence', 0.5),
            metadata={
                'timestamp': time.time(),
                'agents_participated': result.get('agent_count', 0)
            }
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Collective debate failed: {str(e)}")


@router.post("/creative-synthesis/generate", response_model=DomainResultResponse)
async def generate_creative_solutions(request: DomainQueryRequest):
    """
    Generate creative solutions through creative synthesis domain.
    
    Uses divergent thinking and novelty search to produce innovative ideas.
    """
    start_time = time.time()
    
    try:
        engine = get_creative_synthesis_engine()
        
        # Generate creative solutions
        result = engine.generate_solutions(
            problem=request.query,
            context=request.context or {},
            creativity_level=request.context.get('creativity_level', 0.7)
        )
        
        processing_time = (time.time() - start_time) * 1000
        
        return DomainResultResponse(
            domain="creative_synthesis",
            result=result,
            processing_time_ms=processing_time,
            confidence=result.get('novelty_score', 0.5),
            metadata={
                'timestamp': time.time(),
                'solutions_generated': len(result.get('solutions', []))
            }
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Creative synthesis failed: {str(e)}")


@router.post("/social-intelligence/analyze", response_model=DomainResultResponse)
async def analyze_social_context(request: DomainQueryRequest):
    """
    Analyze social/emotional context through social intelligence domain.
    
    Provides empathy, theory of mind, and communication optimization.
    """
    start_time = time.time()
    
    try:
        engine = get_social_intelligence_engine()
        
        # Analyze social context
        result = engine.analyze_interaction(
            interaction=request.query,
            context=request.context or {}
        )
        
        processing_time = (time.time() - start_time) * 1000
        
        return DomainResultResponse(
            domain="social_intelligence",
            result=result,
            processing_time_ms=processing_time,
            confidence=result.get('empathy_accuracy', 0.5),
            metadata={
                'timestamp': time.time(),
                'emotional_tone': result.get('detected_emotion', 'neutral')
            }
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Social intelligence analysis failed: {str(e)}")


@router.post("/ethical-reasoning/evaluate", response_model=DomainResultResponse)
async def evaluate_ethical_implications(request: DomainQueryRequest):
    """
    Evaluate ethical implications through ethical reasoning domain.
    
    Checks alignment, safety, and value preservation for decisions/actions.
    """
    start_time = time.time()
    
    try:
        engine = get_ethical_reasoning_engine()
        
        # Evaluate ethics
        result = engine.evaluate_action(
            action_description=request.query,
            context=request.context or {}
        )
        
        processing_time = (time.time() - start_time) * 1000
        
        return DomainResultResponse(
            domain="ethical_reasoning",
            result=result,
            processing_time_ms=processing_time,
            confidence=result.get('alignment_score', 0.5),
            metadata={
                'timestamp': time.time(),
                'safety_verified': result.get('safe', False)
            }
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ethical evaluation failed: {str(e)}")


@router.post("/embodied-cognition/simulate", response_model=DomainResultResponse)
async def run_embodied_simulation(request: DomainQueryRequest):
    """
    Run embodied simulation through embodied cognition domain.
    
    Performs grounded reasoning through physical/spatial simulation.
    """
    start_time = time.time()
    
    try:
        engine = get_embodied_cognition_engine()
        
        # Run simulation
        result = engine.run_simulation(
            scenario=request.query,
            context=request.context or {},
            simulation_steps=request.context.get('steps', 100)
        )
        
        processing_time = (time.time() - start_time) * 1000
        
        return DomainResultResponse(
            domain="embodied_cognition",
            result=result,
            processing_time_ms=processing_time,
            confidence=result.get('simulation_confidence', 0.5),
            metadata={
                'timestamp': time.time(),
                'simulation_steps': result.get('steps_completed', 0)
            }
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Embodied simulation failed: {str(e)}")


@router.post("/cross-domain/collaborate", response_model=Dict[str, Any])
async def cross_domain_collaboration(request: DomainQueryRequest):
    """
    Execute cross-domain collaboration.
    
    Coordinates multiple cognitive domains to solve complex problems.
    """
    start_time = time.time()
    
    try:
        # Determine which domains to involve
        domains_to_use = request.context.get('domains', [
            'metacognition',
            'collective_intelligence',
            'creative_synthesis'
        ])
        
        results = {}
        
        # Execute across selected domains
        for domain_name in domains_to_use:
            try:
                if domain_name == 'metacognition':
                    engine = get_metacognition_engine()
                    results[domain_name] = engine.process_query(request.query, request.context or {})
                elif domain_name == 'collective_intelligence':
                    engine = get_collective_intelligence_engine()
                    results[domain_name] = engine.run_debate(request.query, request.context or {})
                elif domain_name == 'creative_synthesis':
                    engine = get_creative_synthesis_engine()
                    results[domain_name] = engine.generate_solutions(request.query, request.context or {})
                # Add more domains as needed
                
            except Exception as e:
                results[domain_name] = {'error': str(e)}
        
        processing_time = (time.time() - start_time) * 1000
        
        return {
            'success': True,
            'processing_time_ms': processing_time,
            'domains_involved': domains_to_use,
            'results': results,
            'synthesis': "Cross-domain collaboration complete"
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Cross-domain collaboration failed: {str(e)}")
