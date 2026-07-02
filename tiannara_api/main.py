from __future__ import annotations

import sys
import os
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent))

# Load environment variables from .env file
from dotenv import load_dotenv
load_dotenv()

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from tiannara_api.middleware.rate_limiter import RateLimitMiddleware
from tiannara_api.middleware.security_headers import SecurityHeadersMiddleware
from tiannara_api.middleware.input_validation import InputValidationMiddleware
from tiannara_api.middleware.enhanced_rate_limiter import EnhancedRateLimiter
from tiannara_api.middleware.jwt_context import JWTContextMiddleware
from tiannara_api.middleware.production_auth import ProductionAuthMiddleware
from tiannara_api.middleware.quota_enforcer import check_and_enforce_quota
from tiannara_api.metrics import init_metrics
from tiannara_api.logging_config import LoggingMiddleware, setup_logging

from tiannara_api.routes.autonomous import router as autonomous_router
from tiannara_api.routes.discovery import router as discovery_router
from tiannara_api.routes.evolution import router as evolution_router
from tiannara_api.routes.memory import router as memory_router
from tiannara_api.routes.modules import router as modules_router
from tiannara_api.routes.status import router as status_router
from tiannara_api.routes.autonomy import router as autonomy_router  # New import
from tiannara_api.routes.explanations import router as explanations_router  # EU AI Act compliance
from tiannara_api.routes.payment import router as payment_router  # Payment processing
from tiannara_api.routes.efficiency import router as efficiency_router  # Efficiency features
from tiannara_api.routes.monitoring import router as monitoring_router  # Issue detection & monitoring
from tiannara_api.routes.monitoring_stabilization import router as monitoring_stabilization_router  # Monitoring & stabilization systems
from tiannara_api.routes.telemetry import router as telemetry_router  # Cognitive telemetry
from tiannara_api.routes.autonomous_testing import router as autonomous_testing_router  # Autonomous testing
from tiannara_api.routes.auth import router as auth_router  # Authentication with OTP
from tiannara_api.routes.email_verification import router as email_verification_router  # Email change verification
from tiannara_api.routes.mfa import router as mfa_router  # Multi-Factor Authentication
from tiannara_api.routes.sso import router as sso_router  # SSO (OAuth 2.0 / SAML)
from tiannara_api.routes.workspaces import router as workspaces_router  # Team workspaces
from tiannara_api.routes.audit import router as audit_router  # Audit logging
from tiannara_api.routes.analytics import router as analytics_router  # Advanced analytics
from tiannara_api.routes.white_label import router as white_label_router  # White-label branding
from tiannara_api.routes.mapek_security import router as mapek_security_router  # MAPE-K security loop
from tiannara_api.routes.admin import router as admin_router  # Admin dashboard & monitoring
from tiannara_api.routes.usage import router as usage_router  # Usage metrics & analytics
from tiannara_api.routes.moderation import router as moderation_router  # Content moderation for JamiiLink
from tiannara_api.routes.core_proxy import router as core_proxy_router  # Core AI proxy
from tiannara_api.routes.workflows import router as workflows_router  # Workflow management
from tiannara_api.routes.automations import router as automations_router  # Automation management
from tiannara_api.routes.analytics_insights import router as analytics_insights_router  # Analytics & insights
from tiannara_api.routes.team import router as team_router  # Team management
from tiannara_api.routes.gateway_routes import router as gateway_router  # Gateway monitoring & metrics
from tiannara_api.routes.unified_endpoints import router as unified_router  # Unified API endpoints (predict, classify, etc.)
from tiannara_api.routes.domain_tests import router as domain_tests_router  # Domain test results
from tiannara_api.routes.cognitive_domains import router as cognitive_domains_router  # Cognitive domain engines
from tiannara_api.routes.cognitive_analysis import router as cognitive_analysis_router  # Unified cognitive analysis
from tiannara_api.routes.football_predictions import router as football_predictions_router  # Football prediction engine
from tiannara_api.routes.websocket_metrics import router as websocket_metrics_router  # Real-time metrics WebSocket
from tiannara_api.routes.websocket_streaming import router as websocket_streaming_router  # Workflow execution streaming WebSocket
from tiannara_api.routes.alert_rules import router as alert_rules_router  # Custom alert rules
from tiannara_api.routes.collaboration import router as collaboration_router  # Team collaboration
from tiannara_api.routes.api_keys import router as api_keys_router  # API key management
from tiannara_api.routes.observatory import router as observatory_router  # Phase 4 Observatory backend integration
from tiannara_api.routes.meta_ecology import router as meta_ecology_router # Meta-Ecology & Tier 3 OPC
from tiannara_core.autonomous.orchestrator import Orchestrator
from tiannara_core.discovery.engine import DiscoveryEngine
from tiannara_core.evolution.evolution import evolve as run_evolution
from tiannara_core.evolution.evolution_loop import EvolutionLoop
from tiannara_core.memory.discovery_memory import DiscoveryMemory
from tiannara_core.memory.experience_db import ExperienceDB
from tiannara_core.memory.knowledge_store import KnowledgeStore
from tiannara_core.mission.alignment import AlignmentScorer
from tiannara_core.mission.constitution import TiannaraConstitution
from tiannara_core.modules.base import ModuleBase, ModuleManifest
from tiannara_core.modules.registry import ModuleRegistry
from tiannara_core.safety.gate import SafetyGate
from tiannara_core.safety.policy import SafetyPolicy


APP_VERSION = "1.3.0-phase5"

# Initialize structured logging
logger = setup_logging(
    level=os.getenv("LOG_LEVEL", "INFO"),
    log_file=os.getenv("LOG_FILE", "logs/tiannara.log")
)

app = FastAPI(title="Tiannara API", version=APP_VERSION)

# Initialize Prometheus metrics (must be before other middleware)
init_metrics(app)

# Add security middleware (order matters - security first!)
app.add_middleware(ProductionAuthMiddleware)
app.add_middleware(JWTContextMiddleware)
app.add_middleware(SecurityHeadersMiddleware)
app.add_middleware(InputValidationMiddleware)
app.add_middleware(EnhancedRateLimiter)

# Add logging middleware
app.add_middleware(LoggingMiddleware)

# Add legacy rate limiting (will be replaced by EnhancedRateLimiter)
# app.add_middleware(RateLimitMiddleware)

# Configure CORS with restricted origins for security
allowed_origins = os.getenv("ALLOWED_ORIGINS", "http://localhost:3000,http://127.0.0.1:3000").split(",")
app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type", "X-API-Key"],
    expose_headers=["X-Total-Count"],
    max_age=600,  # Cache preflight requests for 10 minutes
)


class CallableModule(ModuleBase):
    def __init__(self, *, name: str, version: str, risk_tier: str, permissions: list[str], description: str, run_fn):
        super().__init__(
            ModuleManifest(
                name=name,
                version=version,
                risk_tier=risk_tier,
                permissions=permissions,
                description=description,
            )
        )
        self._run_fn = run_fn

    def run(self, payload):
        return self._run_fn(payload)


def build_safety_gate() -> SafetyGate:
    return SafetyGate(
        constitution=TiannaraConstitution(),
        policy=SafetyPolicy(),
        scorer=AlignmentScorer(),
        min_alignment=0.35,
    )


REGISTRY = ModuleRegistry()
SAFETY_GATE = build_safety_gate()
DISCOVERY_ENGINE = DiscoveryEngine(store=KnowledgeStore(), gate=SAFETY_GATE)
DISCOVERY_MEMORY = DiscoveryMemory()
EXPERIENCE_DB = ExperienceDB()
EVOLUTION_LOOP = EvolutionLoop()
AUTONOMOUS_ORCHESTRATOR = Orchestrator(
    store=KnowledgeStore(),
    gate=SAFETY_GATE,
    memory=EXPERIENCE_DB,
    evolution=EVOLUTION_LOOP,
)

REGISTRY.register(
    CallableModule(
        name="discovery",
        version="1.0",
        risk_tier="low",
        permissions=["read_user_text"],
        description="Scientific discovery engine for claims, hypotheses, and experiment design.",
        run_fn=lambda payload: DISCOVERY_ENGINE.analyze(
            question=payload.get("question", ""),
            text=payload.get("text"),
            source=payload.get("source", "user_input"),
        ),
    )
)
REGISTRY.register(
    CallableModule(
        name="evolution",
        version="1.0",
        risk_tier="low",
        permissions=["simulate_parameter_search"],
        description="Evolution loop with adversarial simulation and graph or neural genomes.",
        run_fn=lambda payload: run_evolution(
            question=payload.get("question", "Optimize prosthetic grip stability"),
            population_size=payload.get("population_size", 24),
            generations=payload.get("generations", 12),
            fitness_function=payload.get("fitness_function", "grip_stability"),
            genome_type=payload.get("genome_type", "neural"),
        ),
    )
)
REGISTRY.register(
    CallableModule(
        name="autonomous",
        version="1.0",
        risk_tier="medium",
        permissions=["read_user_text", "simulate_parameter_search", "write_memory"],
        description="DEAA cycle with distributed evolution, adversarial environments, memory, and LLM-guided meta mutation.",
        run_fn=lambda payload: AUTONOMOUS_ORCHESTRATOR.run_cycle(
            question=payload.get("question", "Optimize prosthetic grip stability"),
            text=payload.get("text"),
            source=payload.get("source", "module_runner"),
            population_size=payload.get("population_size", 24),
            generations=payload.get("generations", 12),
            fitness_function=payload.get("fitness_function", "grip_stability"),
            workers=payload.get("workers", 4),
            genome_type=payload.get("genome_type", "mixed"),
        ),
    )
)

app.include_router(status_router)
app.include_router(modules_router)
app.include_router(discovery_router, prefix="/api/v1")  # Discovery memory & research endpoints
app.include_router(evolution_router)
app.include_router(autonomous_router)
app.include_router(memory_router)
app.include_router(autonomy_router)  # Adding the autonomy router
app.include_router(explanations_router, prefix="/api/v1")  # EU AI Act compliance
app.include_router(payment_router, prefix="/api/v1")  # Payment processing
app.include_router(efficiency_router, prefix="/api/v1")  # Efficiency features (email, reports, code)
app.include_router(monitoring_router, prefix="/api/v1")  # Issue detection & auto-resolution
app.include_router(autonomous_testing_router)  # Autonomous testing system
app.include_router(auth_router, prefix="/api/v1")  # Authentication with OTP verification
app.include_router(email_verification_router, prefix="/api/v1")  # Email change verification
app.include_router(mfa_router, prefix="/api/v1")  # Multi-Factor Authentication
app.include_router(sso_router, prefix="/api/v1")  # SSO (OAuth 2.0 / SAML)
app.include_router(workspaces_router, prefix="/api/v1")  # Team workspaces
app.include_router(audit_router, prefix="/api/v1")  # Audit logging
app.include_router(analytics_router, prefix="/api/v1")  # Advanced analytics
app.include_router(white_label_router, prefix="/api/v1")  # White-label branding
app.include_router(mapek_security_router, prefix="/api/v1")  # MAPE-K security loop
app.include_router(admin_router, prefix="/api/v1")  # Admin dashboard & monitoring
app.include_router(usage_router, prefix="/api/v1")  # Usage metrics & analytics
app.include_router(moderation_router)  # Content moderation for JamiiLink (already has /api/v1 prefix)
app.include_router(core_proxy_router, prefix="/api/v1")  # Core AI proxy (bridges to Tiannara Core)
app.include_router(workflows_router, prefix="/api/v1")  # Workflow CRUD operations
app.include_router(automations_router, prefix="/api/v1")  # Automation management
app.include_router(analytics_insights_router, prefix="/api/v1")  # Analytics & insights
app.include_router(team_router, prefix="/api/v1")  # Team management
app.include_router(gateway_router, prefix="/api/v1")  # Gateway monitoring & metrics
app.include_router(domain_tests_router, prefix="/api/v1")  # Domain test results
app.include_router(unified_router, prefix="/api/v1")  # Unified endpoints (predict, classify, optimize)
app.include_router(cognitive_domains_router, prefix="/api/v1")  # Cognitive domain engines
app.include_router(cognitive_analysis_router, prefix="/api/v1")  # Unified cognitive analysis
app.include_router(monitoring_stabilization_router, prefix="/api/v1")  # Monitoring & stabilization systems
app.include_router(telemetry_router, prefix="/api/v1")  # Cognitive telemetry system
app.include_router(football_predictions_router, prefix="/api/v1")  # Football prediction engine
app.include_router(websocket_metrics_router)  # Real-time metrics WebSocket (no prefix for ws://)
app.include_router(websocket_streaming_router)  # Workflow execution streaming WebSocket (no prefix for ws://)
app.include_router(alert_rules_router, prefix="/api/v1")  # Custom alert rules
app.include_router(collaboration_router, prefix="/api/v1")  # Team collaboration
app.include_router(api_keys_router, prefix="/api/v1")  # API key management
app.include_router(observatory_router, prefix="/api/v1")  # Phase 4 Observatory (real-time cognitive state)
app.include_router(meta_ecology_router, prefix="/api/v1/meta-ecology") # Meta-Ecology and Tier 3

@app.on_event("startup")
async def startup_event():
    """
    Initialize application on server startup.
    - Initialize admin user (for development)
    - Register gateway domain engines
    - Start background domain test runner
    """
    logger.info("✅ Metrics collection enabled at /metrics")
    
    # Start background domain test runner
    try:
        from tiannara_api.services.domain_test_runner import test_runner
        test_runner.start_background_runner(interval_seconds=60)  # Run tests every 60 seconds
        logger.info("✅ Domain test runner started (60s interval)")
    except Exception as e:
        logger.warning(f"⚠️  Could not start domain test runner: {e}")
    
    # Initialize gateway domain engines
    try:
        from tiannara_api.gateway.routing import register_engine
        from tiannara_api.engines.algorithm import AlgorithmEngine
        from tiannara_api.engines.logic import LogicEngine
        from tiannara_api.engines.nlp import NLPEngine
        from tiannara_api.engines.causal import CausalEngine
        from tiannara_api.engines.prediction import PredictionEngine
        
        register_engine("algorithm_engine", AlgorithmEngine())
        register_engine("logic_engine", LogicEngine())
        register_engine("nlp_engine", NLPEngine())
        register_engine("causal_engine", CausalEngine())
        register_engine("prediction_engine", PredictionEngine())
        
        logger.info("✅ All domain engines registered successfully")
    except Exception as e:
        logger.warning(f"⚠️  Could not register domain engines: {e}")
    
    # Initialize admin user for development/testing
    try:
        import secrets
        from datetime import datetime, timezone

        from tiannara_api.database import SessionLocal
        from tiannara_api.database.models import User
        from tiannara_api.security.password import hash_password

        db = SessionLocal()
        try:
            admin_email = "admin@tiannara.com"
            admin_user = db.query(User).filter(User.email == admin_email).first()

            if not admin_user:
                admin_password = os.getenv("ADMIN_PASSWORD") or secrets.token_urlsafe(16)
                new_admin = User(
                    id=f"admin_{secrets.token_hex(8)}",
                    email=admin_email,
                    name="Admin User",
                    password_hash=hash_password(admin_password),
                    tier="enterprise",
                    is_verified=True,
                    is_admin=True,
                    is_active=True,
                    created_at=datetime.now(timezone.utc),
                    total_requests=0,
                    api_keys=[],
                )
                db.add(new_admin)
                db.commit()
                logger.info(f"Admin user created: {admin_email}")
                if os.getenv("ENVIRONMENT", "development") == "development":
                    logger.warning(
                        "Set ADMIN_PASSWORD in .env for a known dev password (never log passwords in production)."
                    )
            else:
                logger.info("Admin user already exists in database")
        finally:
            db.close()
    except Exception as e:
        logger.warning(f"⚠️  Could not initialize admin user: {e}")
        logger.warning("   The dashboard will still work, but you may need to create users manually")


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "version": APP_VERSION,
        "service": "Tiannara API",
    }
