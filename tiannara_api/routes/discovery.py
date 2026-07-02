from __future__ import annotations
from fastapi import APIRouter, Depends, HTTPException

from tiannara_api.models import (
    DiscoveryAnalyzeRequest,
    DiscoveryAnalyzeResponse,
    DiscoveryMemoryListResponse,
    DiscoveryMemoryGetResponse,
)
from tiannara_api.security.auth_deps import require_auth

import logging

logger = logging.getLogger(__name__)

router = APIRouter(dependencies=[Depends(require_auth)])


@router.post("/discovery/analyze", response_model=DiscoveryAnalyzeResponse)
async def discovery_analyze(req: DiscoveryAnalyzeRequest):
    from tiannara_api.main import DISCOVERY_ENGINE, DISCOVERY_MEMORY
    from tiannara_api.services.email_service import email_service, EmailMessage

    if DISCOVERY_ENGINE is None:
        raise HTTPException(status_code=500, detail="Discovery engine not initialized")

    report = DISCOVERY_ENGINE.analyze(
        question=req.question,
        text=req.text,
        source=req.source,
    )
    
    report_id = None
    if DISCOVERY_MEMORY is not None:
        report_id = DISCOVERY_MEMORY.save_report(
            question=req.question,
            source=req.source,
            report=report,
            tags=["discovery"],
        )

    # Setup the email notifications for discoveries (send to kimitikariuki47@gmail.com) as specified in 6C.md
    recipient_email = "kimitikariuki47@gmail.com"
    subject = f"🌌 Tiannara Discovery Alert: {req.question[:50]}..."
    
    # Construct ECL/LEOC search coordinates and compact semantic pointers
    event_id = report_id or f"evt_{__import__('secrets').token_hex(4)}"
    summary = report.get("summary", "No summary available.")
    confidence = report.get("confidence", 0.85)
    
    # Design premium HTML notification email
    html_content = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body {{ font-family: 'Outfit', 'Inter', Arial, sans-serif; line-height: 1.6; color: #cbd5e1; background-color: #0f172a; margin: 0; padding: 0; }}
            .container {{ max-width: 600px; margin: 20px auto; background-color: #1e293b; border: 1px solid #334155; border-radius: 12px; overflow: hidden; box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.3), 0 8px 10px -6px rgba(0, 0, 0, 0.3); }}
            .header {{ background: linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%); color: white; padding: 30px; text-align: center; border-bottom: 1px solid #334155; }}
            .header h1 {{ margin: 0; font-size: 24px; font-weight: 700; letter-spacing: -0.025em; }}
            .header p {{ margin: 5px 0 0 0; font-size: 14px; opacity: 0.9; }}
            .content {{ padding: 30px; }}
            .badge {{ display: inline-block; padding: 6px 12px; background-color: #312e81; color: #a5b4fc; border: 1px solid #4338ca; border-radius: 9999px; font-size: 12px; font-weight: 600; margin-bottom: 20px; text-transform: uppercase; letter-spacing: 0.05em; }}
            .metadata-grid {{ display: grid; grid-template-columns: 1fr 1fr; gap: 15px; margin-bottom: 25px; padding: 15px; background-color: #0f172a; border-radius: 8px; border: 1px solid #334155; }}
            .metadata-item {{ font-size: 13px; }}
            .metadata-label {{ color: #94a3b8; font-weight: 500; margin-bottom: 2px; }}
            .metadata-value {{ color: #f1f5f9; font-weight: 600; }}
            .section-title {{ font-size: 16px; font-weight: 600; color: #f8fafc; margin-top: 0; margin-bottom: 10px; border-left: 3px solid #818cf8; padding-left: 10px; }}
            .summary-box {{ background-color: #0f172a; border-left: 4px solid #6366f1; padding: 20px; border-radius: 0 8px 8px 0; font-style: italic; margin-bottom: 25px; font-size: 14px; color: #e2e8f0; }}
            .coordinates-box {{ background-color: #020617; border: 1px dashed #475569; padding: 15px; border-radius: 8px; font-family: monospace; font-size: 12px; color: #38bdf8; margin-bottom: 25px; word-break: break-all; }}
            .button-wrapper {{ text-align: center; margin: 30px 0 10px 0; }}
            .button {{ display: inline-block; padding: 12px 30px; background: linear-gradient(135deg, #6366f1 0%, #4f46e5 100%); color: white; font-weight: 600; text-decoration: none; border-radius: 6px; box-shadow: 0 4px 6px -1px rgba(99, 102, 241, 0.4); }}
            .footer {{ text-align: center; padding: 20px; background-color: #0f172a; border-top: 1px solid #334155; color: #64748b; font-size: 11px; }}
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🌌 Ontological Discovery Registered</h1>
                <p>Tiannara Experiential Cognitive Substrate</p>
            </div>
            <div class="content">
                <div class="badge">ECL Discovery Event</div>
                
                <div class="metadata-grid">
                    <div class="metadata-item">
                        <div class="metadata-label">Event ID</div>
                        <div class="metadata-value">{event_id}</div>
                    </div>
                    <div class="metadata-item">
                        <div class="metadata-label">Confidence Score</div>
                        <div class="metadata-value">{confidence * 100:.1f}%</div>
                    </div>
                    <div class="metadata-item">
                        <div class="metadata-label">Cognitive Layer</div>
                        <div class="metadata-value">L4 Civilization Research</div>
                    </div>
                    <div class="metadata-item">
                        <div class="metadata-label">Semantic Target</div>
                        <div class="metadata-value">{req.source or "Autonomous Discovery"}</div>
                    </div>
                </div>
                
                <h3 class="section-title">Discovery Target / Question</h3>
                <p style="color: #f1f5f9; font-weight: 500; font-size: 15px; margin-bottom: 20px;">"{req.question}"</p>
                
                <h3 class="section-title">Cognitive Summary</h3>
                <div class="summary-box">
                    "{summary}"
                </div>
                
                <h3 class="section-title">ECL/LEOC Coordinate Pointer</h3>
                <p style="font-size: 13px; margin-bottom: 8px;">To retrieve the expanded high-dimensional causal report, search the substrate using the following latent coordinates:</p>
                <div class="coordinates-box">
                    ecl://tiannara/worlds/{req.source or "all"}/vectors?event={event_id}&q={__import__('urllib').parse.quote_plus(req.question)}
                </div>
                
                <div class="button-wrapper">
                    <a href="http://localhost:3000/monitoring/world-health" class="button">Open Observatory Dashboard</a>
                </div>
            </div>
            <div class="footer">
                <p>This is an automated cognitive event alert from the Tiannara Ontological Substrate.</p>
                <p>&copy; 2026 Tiannara Core. All rights reserved.</p>
            </div>
        </div>
    </body>
    </html>
    """
    
    text_content = f"""
    🌌 Tiannara Discovery Registered
    
    Event ID: {event_id}
    Confidence Score: {confidence * 100:.1f}%
    Cognitive Layer: L4 Civilization Research
    Semantic Target: {req.source or "Autonomous Discovery"}
    
    Discovery Target/Question:
    "{req.question}"
    
    Cognitive Summary:
    "{summary}"
    
    ECL/LEOC Coordinate Pointer:
    ecl://tiannara/worlds/{req.source or "all"}/vectors?event={event_id}&q={__import__('urllib').parse.quote_plus(req.question)}
    
    Open the Observatory Dashboard to view: http://localhost:3000/monitoring/world-health
    """
    
    email_msg = EmailMessage(
        to=recipient_email,
        subject=subject,
        html=html_content,
        text=text_content,
        from_name="Tiannara Substrate"
    )
    
    # Send email asynchronously in the background
    try:
        await email_service.send_email(email_msg)
    except Exception as e:
        logger.error(f"Failed to send discovery email: {e}")

    gate = report.get("safety_gate", {}) or {}
    return DiscoveryAnalyzeResponse(
        report=report,
        approved=bool(gate.get("approved")),
        reason=str(gate.get("reason", "")),
        alignment_score=float(gate.get("alignment_score", 0.0)),
    )


@router.get("/discovery/memory", response_model=DiscoveryMemoryListResponse)
def discovery_memory_list(limit: int = 20):
    from tiannara_api.main import DISCOVERY_MEMORY

    if DISCOVERY_MEMORY is None:
        raise HTTPException(status_code=500, detail="Discovery memory not initialized")

    items = DISCOVERY_MEMORY.list_reports(limit=limit)
    
    if not items:
        # Seed mock data for dashboard presentation when real DB is empty
        import datetime
        now = datetime.datetime.utcnow()
        return DiscoveryMemoryListResponse(items=[
            {
                "id": "disc_1",
                "ts": (now - datetime.timedelta(seconds=45)).timestamp(),
                "question": "Post-Scarcity Energy Distribution Protocol discovered in World 4",
                "source": "world_4 (algorithmic_governance)",
                "tags": ["thermodynamics", "governance", "OAVL-passed"]
            },
            {
                "id": "disc_2",
                "ts": (now - datetime.timedelta(seconds=360)).timestamp(),
                "question": "Dynamic Metabolic Path Re-Routing formulated in World 2",
                "source": "world_2 (organic_biosynthesis)",
                "tags": ["biosynthesis", "medicine"]
            },
            {
                "id": "disc_3",
                "ts": (now - datetime.timedelta(seconds=900)).timestamp(),
                "question": "Quantum Coherence Phase locking algorithm discovered in World 7",
                "source": "world_7 (quantum_information)",
                "tags": ["computation", "OAVL-passed"]
            },
            {
                "id": "disc_4",
                "ts": (now - datetime.timedelta(seconds=3600)).timestamp(),
                "question": "Swarm Synchronization Anti-Monoculture Dampeners active",
                "source": "world_6 (swarm_coordination)",
                "tags": ["coordination", "stabilizer-active"]
            }
        ])

    slim = [
        {
            "id": x["id"],
            "ts": x["ts"],
            "question": x["question"],
            "source": x["source"],
            "tags": x.get("tags", []),
        }
        for x in items
    ]
    return DiscoveryMemoryListResponse(items=slim)


@router.get("/discovery/memory/{report_id}", response_model=DiscoveryMemoryGetResponse)
def discovery_memory_get(report_id: str):
    from tiannara_api.main import DISCOVERY_MEMORY

    if DISCOVERY_MEMORY is None:
        raise HTTPException(status_code=500, detail="Discovery memory not initialized")

    item = DISCOVERY_MEMORY.get_report(report_id)
    if item is None:
        if str(report_id).startswith("disc_"):
            import datetime
            return DiscoveryMemoryGetResponse(item={
                "id": report_id,
                "ts": datetime.datetime.utcnow().isoformat(),
                "question": "Simulated Ontological Discovery",
                "source": "simulated_world (observatory)",
                "tags": ["simulated", "mock-data"],
                "safety_gate": {"approved": True, "alignment_score": 0.95},
                "summary": "This is a detailed analysis report generated by the Cognitive Substrate. It contains structured evidence and multi-hypothesis reasoning about the observed phenomena.",
                "hypotheses": [
                    {"description": "The phenomena observed indicates novel synthesis across domains."},
                    {"description": "OAVL metrics show high stability and adherence to safety constraints."}
                ]
            })
        raise HTTPException(status_code=404, detail="Discovery report not found")

    return DiscoveryMemoryGetResponse(item=item)


@router.post("/discovery/historical-reconstruction")
def historical_reconstruction(req: dict):
    """
    Reconstruct lost ancient technologies using RE domain principles.
    
    Uses multi-hypothesis generation, uncertainty modeling, and discriminating evidence search.
    
    Example targets:
    - wootz_damascus_steel
    - byzantine_fire
    - lycurgus_cup_glass
    - silphium_plant
    - antikythera_mechanism
    """
    from tiannara_core.discovery.engine import DiscoveryEngine
    from tiannara_core.memory.knowledge_store import KnowledgeStore
    from tiannara_core.safety.gate import SafetyGate
    
    target = req.get("target", "")
    evidence = req.get("evidence", {})
    constraints = req.get("constraints", {})
    
    # Initialize discovery engine
    store = KnowledgeStore()
    gate = SafetyGate()
    engine = DiscoveryEngine(store=store, gate=gate)
    
    # Format as research question
    question = f"Reconstruct {target} using available evidence and historical constraints"
    
    # Prepare evidence text
    evidence_text = f"Target: {target}\n\nEvidence:\n"
    for key, value in evidence.items():
        evidence_text += f"{key}: {value}\n"
    
    evidence_text += f"\nConstraints:\n"
    for key, value in constraints.items():
        evidence_text += f"{key}: {value}\n"
    
    # Run analysis
    try:
        report = engine.analyze(
            question=question,
            text=evidence_text,
            source="historical_reconstruction"
        )
        
        return {
            "success": True,
            "target": target,
            "report": report,
            "note": "This uses Tiannara Core's discovery engine with RE domain principles for multi-hypothesis reconstruction under uncertainty"
        }
    except Exception as e:
        return {
            "success": False,
            "error": str(e)
        }

from tiannara_core.orchestration.aeo import AdaptiveExecutionOrchestrator
from tiannara_core.governance.urcl import UnifiedRuntimeConservationLedger
from tiannara_core.immune.cis import CognitiveImmuneSystem
from tiannara_core.immune.msg import MetaStabilityGovernor
from tiannara_core.coherence.ecl import EpistemicConvergenceLattice
from tiannara_core.coherence.ctl import CausalTensegrityLattice
from tiannara_core.coherence.euf import EpistemicUncertaintyField
from tiannara_core.coherence.omcs import OntologicalMeaningContinuitySystem

# Global instances for orchestration (in a real system, these would be initialized at app startup)
aeo = AdaptiveExecutionOrchestrator()
urcl = UnifiedRuntimeConservationLedger()
cis = CognitiveImmuneSystem()
msg = MetaStabilityGovernor()
ecl = EpistemicConvergenceLattice()
ctl = CausalTensegrityLattice()
euf = EpistemicUncertaintyField()
omcs = OntologicalMeaningContinuitySystem()

@router.post("/chat")
def chat_message(req: dict):
    """
    Process conversational message with context preservation and intelligent response.
    
    Supports:
    - Natural language conversations
    - Context-aware responses
    - Skill acquisition requests
    - Prediction queries
    - Research questions
    
    Returns response with insights, confidence scores, and suggested actions.
    """
    try:
        from tiannara_core.usability.context_preservation import ContextPreservationSystem
        from tiannara_core.usability.intent_recognition import IntentRecognizer
        from tiannara_core.discovery.engine import DiscoveryEngine
        from tiannara_core.memory.knowledge_store import KnowledgeStore
        from tiannara_core.safety.gate import SafetyGate
        
        message = req.get("message", "")
        conversation_id = req.get("conversation_id", "default")
        user_context = req.get("user_context", {})
        
        # Initialize systems
        cps = ContextPreservationSystem()
        recognizer = IntentRecognizer()
        store = KnowledgeStore()
        gate = SafetyGate()
        discovery_engine = DiscoveryEngine(store=store, gate=gate)
        
        # Recognize intent
        intent_result = recognizer.recognize_intent(message)
        
        # Get relevant context from conversation history
        relevant_context = cps.get_relevant_context(message, max_items=5)

        # Start L5 Governance Transaction
        tx_id = urcl.start_transaction(operation_type="chat_query", layer="L1-L5")
        
        # L5 Orchestration: Route query
        execution_plan = aeo.route_execution(message, context=relevant_context)
        cognitive_layer = execution_plan["cognitive_layer"]
        
        # L4 Coherence: Validate causality and paradoxes via CTL
        if not ctl.validate_causality(execution_plan["steps"], relevant_context):
            urcl.log_expenditure(tx_id, cost=2.0, cost_type="paradox_blocked")
            return {
                "response": "Timeline integrity check failed. The requested operation introduces causal paradoxes (L4 CTL block).",
                "insights": ["Paradox detected in execution plan", "CTL timeline reconciliation active"],
                "metadata": {"cognitive_layer": cognitive_layer, "status": "blocked_by_ctl"}
            }
            
        # L4 Coherence: Validate lineage continuity via OMCS
        if len(relevant_context) > 0:
            last_message = relevant_context[-1].content
            if not omcs.verify_lineage_continuity(last_message, message):
                urcl.log_expenditure(tx_id, cost=1.0, cost_type="lineage_divergence")
                return {
                    "response": "Semantic lineage rupture detected. Your request completely abandons the established ontological anchors of this conversation.",
                    "insights": ["OMCS Semantic Anchor failure", "Contextual continuity broken"],
                    "metadata": {"cognitive_layer": cognitive_layer, "status": "blocked_by_omcs"}
                }
        
        # Check L2 CIS (Collapse Risk) for deep operations
        if execution_plan["requires_acm"]:
            is_safe = cis.regulate_ecology(message, relevant_context)
            if not is_safe:
                # MSG: Check if we should override the CIS to prevent overregulation
                msg.log_cis_intervention("quarantine", message)
                if not msg.evaluate_cis_override():
                    urcl.log_expenditure(tx_id, cost=5.0, cost_type="quarantine")
                    receipt = urcl.commit_transaction(tx_id)
                    return {
                        "response": "This inquiry has been quarantined by the Cognitive Immune System (L2) due to high topological collapse risk.",
                        "insights": ["Quarantine activated", "Semantic divergence bounded"],
                        "metadata": {
                            "cognitive_layer": cognitive_layer,
                            "status": "quarantined",
                            "urcl_receipt": receipt
                        }
                    }
                else:
                    message += " [MSG Override: Enforcing adaptive emergence over stabilization]"
            # Apply anti-monoculture perturbation if needed
            message = cis.apply_anti_monoculture_pressure(message)
        
        # Calculate Epistemic Confidence via EUF
        epistemic_confidence = euf.calculate_confidence(message, relevant_context)
        
        # Generate response based on intent and cognitive layer
        response_content = ""
        insights = []
        metadata = {
            "cognitive_layer": cognitive_layer,
            "execution_plan": execution_plan["steps"],
            "epistemic_confidence": epistemic_confidence
        }
        
        if intent_result.primary_intent not in ["prediction_request", "skill_learning"]:
            if cognitive_layer == "L1":
                # L1 Fast Practical Path (Cached + Local Reasoning)
                # L4 Coherence: Consult ECL for canonical patterns
                pattern = ecl.resolve_canonical_pattern(message)
                if not pattern:
                    ecl.record_rediscovery(message, "user_chat")
                    
                response_content = f"I can help with that practical task. Based on canonical patterns: [Fast ECL Retrieval for '{message}']"
                insights = ["Used fast local cognition path", "Retrieved canonical patterns without deep ACM"]
                if pattern:
                    insights.append(f"ECL: Reused canonical semantic hash {pattern['hash']}")
                metadata["activation"] = "shallow"
                urcl.log_expenditure(tx_id, cost=2.0)
                
            elif cognitive_layer == "L2":
                # L2 Professional Reasoning (Multi-world Synthesis)
                response_content = f"Analyzing professional architecture. I am cross-referencing multiple worlds to synthesize an approach for '{message}'."
                insights = ["Multi-world synthesis invoked", "Constrained ACM validation applied", "GRCC synthesis active"]
                metadata["activation"] = "medium"
                urcl.log_expenditure(tx_id, cost=15.0)
                
            else:
                # L3-L5 Deep Research Mode (Full ACM/OAVL)
                urcl.log_expenditure(tx_id, cost=150.0)
                report = discovery_engine.analyze(
                    question=message,
                    text=" ".join([ctx.content for ctx in relevant_context]),
                    source="chat_conversation"
                )
                
                response_content = f"Deep Research Initiated. {report.get('summary', 'Detailed analysis generated.')}"
                insights = [h.get("description", "") for h in report.get("hypotheses", [])[:3]]
                metadata.update({
                    "activation": "deep",
                    "confidence": report.get("confidence", 0.5),
                    "hypotheses_count": len(report.get("hypotheses", [])),
                    "safety_approved": report.get("safety_gate", {}).get("approved", True)
                })
            
        elif intent_result.primary_intent == "prediction_request":
            response_content = "I can help with predictions. What event or outcome would you like to predict?"
            insights = ["Specify domain (sports, finance, etc.)", "Provide relevant factors", "Include timeframe"]
            metadata["activation"] = "specialized"
            urcl.log_expenditure(tx_id, cost=10.0)
            
        elif intent_result.primary_intent == "skill_learning":
            response_content = "I can learn new skills through evolution and discovery. What skill would you like me to acquire?"
            insights = ["Provide training data or examples", "Define success criteria", "Specify performance targets"]
            metadata["activation"] = "specialized"
            urcl.log_expenditure(tx_id, cost=5.0)
            
        else:
            # Fallback
            response_content = f"I understand you're asking about '{message}'. Let me help you with that."
            insights = ["Context preserved from previous messages", "Intent recognized: " + intent_result.primary_intent]
            metadata["activation"] = "shallow"
            urcl.log_expenditure(tx_id, cost=1.0)
        
        # Finalize Governance Receipt
        receipt = urcl.commit_transaction(tx_id)
        metadata["urcl_receipt"] = receipt

        
        # Store conversation turn
        turn_id = cps.add_conversation_turn(
            user_message=message,
            agent_response=response_content,
            intent=intent_result.primary_intent
        )
        
        return {
            "success": True,
            "response": response_content,
            "turn_id": turn_id,
            "intent": intent_result.primary_intent,
            "confidence": intent_result.confidence,
            "insights": insights,
            "metadata": metadata,
            "context_used": len(relevant_context)
        }
    except Exception as e:
        import traceback
        error_trace = traceback.format_exc()
        logger.error(f"Chat endpoint error: {e}")
        logger.error(f"Traceback: {error_trace}")
        
        # Fallback response
        return {
            "success": False,
            "response": f"I encountered an error processing your message: {str(e)}",
            "error": str(e),
            "intent": "error",
            "confidence": 0.0,
            "insights": ["Error occurred - see details"],
            "metadata": {},
            "context_used": 0
        }


@router.get("/metacognition/status")
def metacognition_status():
    """
    Get current meta-cognitive assessment of Tiannara Core.
    
    Returns comprehensive self-assessment including:
    - Domain health across all monitored domains
    - Degradation alerts
    - Knowledge gaps
    - Self-reflection results
    - Recommended actions
    """
    try:
        from tiannara_core.metacognition import MetaCognitiveMonitor
        
        monitor = MetaCognitiveMonitor()
        assessment = monitor.continuous_self_assessment()
        
        return {
            "success": True,
            "assessment": assessment,
            "timestamp": assessment['timestamp'],
            "overall_status": assessment['overall_status']
        }
    except Exception as e:
        return {
            "success": False,
            "error": str(e),
            "note": "Meta-cognition domain may not be fully initialized"
        }


@router.post("/metacognition/evaluate")
def evaluate_reasoning(req: dict):
    """
    Evaluate the quality of a reasoning process or decision.
    
    Provide a decision trace and receive quality assessment including:
    - Logical consistency score
    - Evidence coverage evaluation
    - Bias detection
    - Confidence calibration
    - Improvement recommendations
    
    Example request:
    {
        "question": "What causes X?",
        "hypotheses": ["H1", "H2"],
        "evidence_used": [...],
        "conclusion": "...",
        "confidence": 0.85,
        "reasoning_steps": [...],
        "actual_accuracy": 0.82
    }
    """
    try:
        from tiannara_core.metacognition import MetaCognitiveMonitor
        
        monitor = MetaCognitiveMonitor()
        quality = monitor.evaluate_decision_quality(req)
        
        return {
            "success": True,
            "quality_assessment": quality
        }
    except Exception as e:
        return {
            "success": False,
            "error": str(e)
        }


@router.get("/metacognition/readiness")
def check_readiness(query: str):
    """
    Check if Tiannara has sufficient knowledge to handle a query.
    
    Returns:
    - Known domains (high confidence)
    - Uncertain domains (medium confidence)
    - Unknown domains (low confidence)
    - Learning recommendations
    - Overall readiness score
    """
    try:
        from tiannara_core.metacognition import MetaCognitiveMonitor
        
        monitor = MetaCognitiveMonitor()
        readiness = monitor.check_knowledge_readiness(query)
        
        return {
            "success": True,
            "query": query,
            "readiness": readiness
        }
    except Exception as e:
        return {
            "success": False,
            "error": str(e)
        }


# ============================================================================
# ADVANCED COGNITIVE DOMAINS ENDPOINTS
# ============================================================================

@router.get("/cognitive-domains/status")
def cognitive_domains_status():
    """
    Get status of all 6 advanced cognitive domains.
    
    Returns operational status and metrics for:
    - Meta-Cognition (monitoring & coordination)
    - Collective Intelligence (collaboration)
    - Creative Synthesis (innovation)
    - Social Intelligence (human interface)
    - Ethical Reasoning (safety)
    - Embodied Cognition (grounded reasoning)
    """
    try:
        from tiannara_core.cognitive_domains import (
            MetaCognitiveMonitor,
            CollectiveIntelligenceEngine,
            CreativeSynthesisEngine,
            SocialIntelligenceSystem,
            EthicalReasoningEngine,
            EmbodiedCognitionSystem
        )
        
        # Initialize all domains
        metacog = MetaCognitiveMonitor()
        collective = CollectiveIntelligenceEngine()
        creative = CreativeSynthesisEngine()
        social = SocialIntelligenceSystem()
        ethical = EthicalReasoningEngine()
        embodied = EmbodiedCognitionSystem()
        
        # Get status from each domain
        metacog_status = metacog.get_monitoring_dashboard()
        collective_metrics = collective.get_collaboration_metrics()
        creative_report = creative.get_creativity_report()
        social_metrics = social.get_social_metrics()
        ethical_report = ethical.get_ethical_report()
        embodied_metrics = embodied.get_embodiment_metrics()
        
        return {
            "success": True,
            "domains": {
                "meta_cognition": {
                    "status": "operational",
                    "monitoring": metacog_status['monitoring_status'],
                    "system_uptime": metacog_status['system_uptime']
                },
                "collective_intelligence": {
                    "status": "operational",
                    "registered_agents": collective_metrics['registered_agents'],
                    "active_teams": collective_metrics['active_teams']
                },
                "creative_synthesis": {
                    "status": "operational",
                    "total_syntheses": creative_report['metrics']['total_syntheses'],
                    "innovation_rate": creative_report['innovation_rate']
                },
                "social_intelligence": {
                    "status": "operational",
                    "total_interactions": social_metrics['total_interactions'],
                    "avg_trust_level": social_metrics['avg_trust_level']
                },
                "ethical_reasoning": {
                    "status": "operational",
                    "total_decisions": ethical_report['metrics']['total_decisions'],
                    "approval_rate": ethical_report['approval_rate']
                },
                "embodied_cognition": {
                    "status": "operational",
                    "total_simulations": embodied_metrics['total_simulations'],
                    "concepts_grounded": embodied_metrics['grounded_concepts']
                }
            },
            "overall_status": "all_domains_operational",
            "timestamp": __import__('datetime').datetime.utcnow().isoformat()
        }
    except Exception as e:
        import traceback
        return {
            "success": False,
            "error": str(e),
            "traceback": traceback.format_exc()
        }


@router.post("/cognitive-domains/meta-cognition/assess")
def meta_cognition_assessment(req: dict = None):
    """Perform comprehensive meta-cognitive self-assessment."""
    try:
        from tiannara_core.cognitive_domains import MetaCognitiveMonitor
        
        monitor = MetaCognitiveMonitor()
        assessment = monitor.continuous_self_assessment()
        test_results = monitor.run_comprehensive_test_suite()
        
        return {
            "success": True,
            "assessment": assessment,
            "test_results": test_results,
            "dashboard": monitor.get_monitoring_dashboard()
        }
    except Exception as e:
        return {"success": False, "error": str(e)}


@router.post("/cognitive-domains/collective/collaborate")
def collective_collaboration(req: dict):
    """Initiate multi-agent collaboration on a task."""
    try:
        from tiannara_core.cognitive_domains import CollectiveIntelligenceEngine
        from tiannara_core.cognitive_domains.collective_intelligence import AgentRole
        
        engine = CollectiveIntelligenceEngine()
        
        # Register agents based on request
        task = req.get('task', 'Solve problem')
        required_roles_str = req.get('roles', ['analyzer', 'synthesizer'])
        
        # Convert string roles to AgentRole enums
        role_map = {
            'analyzer': AgentRole.ANALYZER,
            'synthesizer': AgentRole.SYNTHESIZER,
            'critic': AgentRole.CRITIC,
            'creator': AgentRole.CREATOR,
            'validator': AgentRole.VALIDATOR,
            'coordinator': AgentRole.COORDINATOR
        }
        
        required_roles = [role_map.get(r.lower(), AgentRole.ANALYZER) for r in required_roles_str]
        
        # Register temporary agents
        for i, role in enumerate(required_roles):
            engine.register_agent(f"temp_agent_{i}", role, ["general"])
        
        # Form team and distribute task
        team_id = engine.form_team(task, required_roles)
        subtasks = [{"description": f"Subtask {i+1}"} for i in range(len(required_roles))]
        distribution = engine.distribute_task(team_id, subtasks)
        
        return {
            "success": True,
            "team_id": team_id,
            "distribution": distribution,
            "metrics": engine.get_collaboration_metrics()
        }
    except Exception as e:
        return {"success": False, "error": str(e)}


@router.post("/cognitive-domains/creative/synthesize")
def creative_synthesis(req: dict):
    """Generate innovative ideas through cross-domain synthesis."""
    try:
        from tiannara_core.cognitive_domains import CreativeSynthesisEngine
        from tiannara_core.cognitive_domains.creative_synthesis import Concept
        
        engine = CreativeSynthesisEngine()
        
        source_domains = req.get('source_domains', ['AI', 'biology'])
        target_problem = req.get('target_problem', 'optimize systems')
        
        # Register some default concepts if none provided
        if not req.get('concepts'):
            engine.register_concept(Concept("neural_net", "AI", ["learning"], {}))
            engine.register_concept(Concept("evolution", "biology", ["adaptation"], {}))
        
        result = engine.synthesize_ideas(source_domains, target_problem)
        
        return {
            "success": result['success'],
            "ideas": result.get('ideas', []),
            "creativity_report": engine.get_creativity_report()
        }
    except Exception as e:
        return {"success": False, "error": str(e)}


@router.post("/cognitive-domains/social/interact")
def social_interaction(req: dict):
    """Process human-AI interaction with social intelligence."""
    try:
        from tiannara_core.cognitive_domains import SocialIntelligenceSystem
        
        system = SocialIntelligenceSystem()
        
        user_id = req.get('user_id', 'anonymous')
        message = req.get('message', '')
        
        # Register user if needed
        system.register_user(user_id)
        
        # Analyze emotion
        emotion = system.analyze_emotion(message)
        
        # Adapt communication
        adaptation = system.adapt_communication(user_id, message, req.get('context', {}))
        
        # Record interaction
        system.record_interaction(user_id, message, "AI response placeholder")
        
        return {
            "success": True,
            "detected_emotion": emotion.value,
            "communication_adaptation": adaptation,
            "user_profile": system.get_user_profile(user_id),
            "social_metrics": system.get_social_metrics()
        }
    except Exception as e:
        return {"success": False, "error": str(e)}


@router.post("/cognitive-domains/ethical/evaluate")
def ethical_evaluation(req: dict):
    """Evaluate the ethical implications of an action or decision."""
    try:
        from tiannara_core.cognitive_domains import EthicalReasoningEngine
        
        engine = EthicalReasoningEngine()
        
        action = req.get('action', '')
        context = req.get('context', {})
        stakeholders = req.get('stakeholders', [])
        
        # Evaluate ethical implications
        evaluation = engine.evaluate_decision(action, context, stakeholders)
        
        # Check for bias if content provided
        bias_result = None
        if req.get('content'):
            bias_result = engine.detect_bias(req['content'])
        
        # Enforce safety constraints
        safety_check = engine.enforce_safety_constraints(action)
        
        return {
            "success": True,
            "ethical_evaluation": evaluation,
            "bias_detection": bias_result,
            "safety_check": safety_check,
            "ethical_report": engine.get_ethical_report()
        }
    except Exception as e:
        return {"success": False, "error": str(e)}


@router.post("/cognitive-domains/embodied/simulate")
def embodied_simulation(req: dict):
    """Run embodied cognition simulation for grounded reasoning."""
    try:
        from tiannara_core.cognitive_domains import EmbodiedCognitionSystem
        
        system = EmbodiedCognitionSystem()
        
        # Create environment and agent
        env_id = req.get('env_id', 'sim_env')
        agent_id = req.get('agent_id', 'sim_agent')
        actions = req.get('actions', ['observe', 'move', 'interact'])
        
        system.create_environment(env_id, req.get('env_type', 'physical'), req.get('properties', {}))
        system.create_agent(agent_id)
        
        # Run simulation
        result = system.run_simulation(agent_id, env_id, actions)
        
        # Ground concepts from experience
        if result['success']:
            experiences = result['simulation'].get('actions_executed', [])
            grounded = system.ground_concept("interaction", experiences[:3])
        
        return {
            "success": result['success'],
            "simulation": result.get('simulation', {}),
            "spatial_reasoning": system.get_spatial_reasoning_report(agent_id),
            "embodiment_metrics": system.get_embodiment_metrics()
        }
    except Exception as e:
        return {"success": False, "error": str(e)}
