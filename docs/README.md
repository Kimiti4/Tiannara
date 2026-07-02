
# Tiannara MindCache Prosthetic Project

## Local setup on Windows

Step 0:
- Install Python 3.10+
- Install Rust
- Install Node.js if you want to run `tiannara_gui`
- Install VS Code
- Open the folder directly in VS Code
- Run `mindcache/orchestrator.py`

This project does not require WSL for normal local development.

## About the "no WSL distro found" message

That error usually appears when VS Code tries to open the optional `.devcontainer` environment on Windows before a WSL distro is installed.

If you want the quickest path, skip the dev container and work locally with Python, Rust, and Node.js installed on Windows.

If you specifically want to use the dev container, install:
- Docker Desktop
- WSL 2
- A Linux distro such as Ubuntu from the Microsoft Store

## Next step

- Develop memory and contextual processing modules.
"""
Planning engine for the Tiannara MindCache Prosthetic Project
Handles intent parsing, plan creation, and execution
"""

import asyncio
import json
import time
from typing import Any, Dict, List, Optional
from dataclasses import dataclass
from enum import Enum
import logging
from .memory_system import MemorySystem
from .context_processor import ContextProcessor


class PlanStatus(Enum):
    PENDING = "pending"
    EXECUTING = "executing"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"


@dataclass
class PlanStep:
    id: str
    description: str
    tool: str
    action: str
    params: Dict[str, Any]
    depends_on: List[str]
    requires_approval: bool
    timeout: int = 30  # seconds


@dataclass
class Plan:
    id: str
    intent: str
    steps: List[PlanStep]
    status: PlanStatus
    success_criteria: str
    fallback_instructions: str
    created_at: float
    updated_at: float


class PlanningEngine:
    def __init__(self, memory: MemorySystem, context: ContextProcessor, config: Dict[str, Any]):
        self.memory = memory
        self.context = context
        self.config = config
        self.model_name = config.get('model_name', 'default')
        self.logger = logging.getLogger(__name__)
        
    async def create_plan(self, intent: str, context: Dict[str, Any]) -> Plan:
        """Create a plan based on intent and context"""
        # Try to create plan using LLM first
        plan = await self._create_llm_plan(intent, context)
        
        # If LLM plan fails or is invalid, fall back to deterministic plan
        if not plan or not self._validate_plan(plan):
            plan = self._create_deterministic_plan(intent)
            
        return plan
        
    async def _create_llm_plan(self, intent: str, context: Dict[str, Any]) -> Optional[Plan]:
        """Attempt to create a plan using LLM"""
        try:
            # This would call your LLM service in a real implementation
            # For now, we'll simulate the response
            return self._create_deterministic_plan(intent)
        except Exception as e:
            self.logger.warning(f"LLM plan creation failed: {e}")
            return None
            
    def _create_deterministic_plan(self, intent: str) -> Plan:
        """Create a plan deterministically based on intent"""
        intent_lower = intent.lower()
        
        # Determine plan based on intent
        if any(word in intent_lower for word in ['save', 'store', 'write', 'create']):
            return self._create_save_plan(intent)
        elif any(word in intent_lower for word in ['find', 'search', 'look', 'get']):
            return self._create_search_plan(intent)
        elif any(word in intent_lower for word in ['help', 'what', 'how', 'explain']):
            return self._create_explain_plan(intent)
        else:
            # Default plan for general intents
            return self._create_default_plan(intent)
            
    def _create_save_plan(self, intent: str) -> Plan:
        """Create a plan for saving/storing operations"""
        from uuid import uuid4
        
        step_id = f"step_{uuid4().hex[:8]}"
        step = PlanStep(
            id=step_id,
            description=f"Save the content: {intent}",
            tool="file_system",
            action="write_file",
            params={
                "path": "./data/user_requests.txt",
                "content": f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] {intent}\n"
            },
            depends_on=[],
            requires_approval=False
        )
        
        plan = Plan(
            id=f"plan_{uuid4().hex[:8]}",
            intent=intent,
            steps=[step],
            status=PlanStatus.PENDING,
            success_criteria="File successfully written",
            fallback_instructions="Write to alternative location if primary fails",
            created_at=time.time(),
            updated_at=time.time()
        )
        
        return plan
        
    def _create_search_plan(self, intent: str) -> Plan:
        """Create a plan for search/retrieval operations"""
        from uuid import uuid4
        
        step = PlanStep(
            id=f"step_{uuid4().hex[:8]}",
            description=f"Search for information related to: {intent}",
            tool="search_engine",
            action="query",
            params={"query": intent},
            depends_on=[],
            requires_approval=False
        )
        
        plan = Plan(
            id=f"plan_{uuid4().hex[:8]}",
            intent=intent,
            steps=[step],
            status=PlanStatus.PENDING,
            success_criteria="Relevant information retrieved",
            fallback_instructions="Try broader search terms if initial search fails",
            created_at=time.time(),
            updated_at=time.time()
        )
        
        return plan
        
    def _create_explain_plan(self, intent: str) -> Plan:
        """Create a plan for explanation/help requests"""
        from uuid import uuid4
        
        step = PlanStep(
            id=f"step_{uuid4().hex[:8]}",
            description=f"Provide explanation for: {intent}",
            tool="knowledge_base",
            action="lookup",
            params={"topic": intent},
            depends_on=[],
            requires_approval=False
        )
        
        plan = Plan(
            id=f"plan_{uuid4().hex[:8]}",
            intent=intent,
            steps=[step],
            status=PlanStatus.PENDING,
            success_criteria="Helpful explanation provided",
            fallback_instructions="Provide general guidance if specific information unavailable",
            created_at=time.time(),
            updated_at=time.time()
        )
        
        return plan
        
    def _create_default_plan(self, intent: str) -> Plan:
        """Create a default plan for unrecognized intents"""
        from uuid import uuid4
        
        step = PlanStep(
            id=f"step_{uuid4().hex[:8]}",
            description=f"Process general request: {intent}",
            tool="conversation",
            action="respond",
            params={"message": f"I received your request: {intent}"},
            depends_on=[],
            requires_approval=False
        )
        
        plan = Plan(
            id=f"plan_{uuid4().hex[:8]}",
            intent=intent,
            steps=[step],
            status=PlanStatus.PENDING,
            success_criteria="Acknowledged user request",
            fallback_instructions="Ask for clarification if unsure about intent",
            created_at=time.time(),
            updated_at=time.time()
        )
        
        return plan
        
    def _validate_plan(self, plan: Plan) -> bool:
        """Validate that a plan is properly formed"""
        if not plan.id or not plan.intent or not plan.steps:
            return False
            
        # Check that all steps have required fields
        for step in plan.steps:
            if not step.id or not step.description or not step.tool or not step.action:
                return False
                
        return True
        
    async def execute_plan(self, plan: Plan) -> Dict[str, Any]:
        """Execute a plan and return results"""
        plan.status = PlanStatus.EXECUTING
        plan.updated_at = time.time()
        
        results = {
            'plan_id': plan.id,
            'intent': plan.intent,
            'steps_executed': [],
            'overall_result': '',
            'success': True,
            'errors': []
        }
        
        try:
            for step in plan.steps:
                step_result = await self._execute_step(step)
                results['steps_executed'].append({
                    'step_id': step.id,
                    'result': step_result,
                    'status': 'completed' if step_result.get('success') else 'failed'
                })
                
                if not step_result.get('success'):
                    results['success'] = False
                    results['errors'].append(step_result.get('error', 'Unknown error'))
                    
                    # If step requires approval and failed, ask for user input
                    if step.requires_approval:
                        # In a real implementation, this would prompt the user
                        pass
                        
                    # Apply fallback if specified
                    if plan.fallback_instructions:
                        fallback_result = await self._execute_fallback(plan, step, step_result)
                        results['steps_executed'][-1]['fallback_result'] = fallback_result
                        
        except Exception as e:
            results['success'] = False
            results['errors'].append(str(e))
            self.logger.error(f"Plan execution failed: {e}")
            
        finally:
            plan.status = PlanStatus.COMPLETED if results['success'] else PlanStatus.FAILED
            plan.updated_at = time.time()
            results['overall_result'] = 'Success' if results['success'] else 'Failed'
            
        return results
        
    async def _execute_step(self, step: PlanStep) -> Dict[str, Any]:
        """Execute a single plan step"""
        try:
            # Simulate step execution
            # In a real implementation, this would dispatch to appropriate tool handlers
            result = await self._dispatch_to_tool(step.tool, step.action, step.params)
            
            return {
                'success': True,
                'output': result,
                'step_id': step.id
            }
        except Exception as e:
            return {
                'success': False,
                'error': str(e),
                'step_id': step.id
            }
            
    async def _dispatch_to_tool(self, tool: str, action: str, params: Dict[str, Any]) -> Any:
        """Dispatch action to appropriate tool"""
        if tool == "file_system":
            return await self._handle_file_system_action(action, params)
        elif tool == "search_engine":
            return await self._handle_search_action(action, params)
        elif tool == "knowledge_base":
            return await self._handle_knowledge_action(action, params)
        elif tool == "conversation":
            return await self._handle_conversation_action(action, params)
        else:
            raise ValueError(f"Unknown tool: {tool}")
            
    async def _handle_file_system_action(self, action: str, params: Dict[str, Any]) -> str:
        """Handle file system actions"""
        if action == "write_file":
            import os
            path = params.get("path", "./default.txt")
            content = params.get("content", "")
            
            # Ensure directory exists
            os.makedirs(os.path.dirname(path), exist_ok=True)
            
            with open(path, "a" if params.get("append", False) else "w") as f:
                f.write(content)
                
            return f"Successfully wrote to {path}"
        else:
            raise ValueError(f"Unknown file system action: {action}")
            
    async def _handle_search_action(self, action: str, params: Dict[str, Any]) -> str:
        """Handle search actions"""
        if action == "query":
            query = params.get("query", "")
            # In a real implementation, this would search your knowledge base
            return f"Search results for '{query}' would appear here"
        else:
            raise ValueError(f"Unknown search action: {action}")
            
    async def _handle_knowledge_action(self, action: str, params: Dict[str, Any]) -> str:
        """Handle knowledge base actions"""
        if action == "lookup":
            topic = params.get("topic", "")
            # In a real implementation, this would look up information
            return f"Information about '{topic}' would be provided here"
        else:
            raise ValueError(f"Unknown knowledge action: {action}")
            
    async def _handle_conversation_action(self, action: str, params: Dict[str, Any]) -> str:
        """Handle conversation actions"""
        if action == "respond":
            message = params.get("message", "")
            # In a real implementation, this would format a response
            return f"Response: {message}"
        else:
            raise ValueError(f"Unknown conversation action: {action}")
            
    async def _execute_fallback(self, plan: Plan, step: PlanStep, step_result: Dict[str, Any]) -> str:
        """Execute fallback action for a failed step"""
        # In a real implementation, this would have more sophisticated fallback logic
        return f"Fallback executed for failed step {step.id}: {step_result.get('error')}"

        (Highest Priority):

Implement webhook handlers to update database

Connect Flutterwave backend (or switch to Stripe-only)

Add tier activation/deactivation logic

Enforce API quotas based on subscription tier

Finish Domain Engines (Medium Priority):

Implement Logic engine reasoning

Implement Causal engine analysis

Test multi-domain orchestration end-to-end

Add Queue System (Low Priority for MVP):

Set up Redis + Celery for background tasks

Move long-running AI operations to workers
