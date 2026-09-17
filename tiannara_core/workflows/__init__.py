"""
Tiannara Core Workflows Package

Workflow execution infrastructure for template-based AI workflows.

Architecture (from templates.md):
- Templates are orchestration blueprints
- Tiannara Core is the intelligence runtime
- Workflow Engine orchestrates execution
- Domain Orchestrator routes to intelligence domains
- Node Executor handles individual steps

Components:
- engine/: Core workflow execution engine
- orchestrators/: Domain routing and coordination
- executors/: Individual node execution
- templates/: Template storage and management
- runners/: Execution runners
- traces/: Reasoning trace generation
- insights/: Insight and recommendation engine
"""

__version__ = "1.0.0"
