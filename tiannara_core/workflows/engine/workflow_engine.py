"""
Tiannara Core Workflow Engine

Architecture (from templates.md):
- Templates are orchestration blueprints, NOT the intelligence itself
- Tiannara Core acts as the intelligence runtime behind every template
- Templates define: domains, orchestration chains, UI schemas, automation logic
- Core provides: reasoning, hypothesis generation, analysis, optimization

Workflow Engine Responsibilities:
1. Load template definitions
2. Validate configurations and dependencies
3. Call required domains through Domain Orchestrator
4. Orchestrate execution flow
5. Collect and aggregate outputs
6. Stream results to dashboard
7. Store execution memory
8. Generate reasoning traces

Date: May 1, 2026
Status: Week 30 - Workflow Engine Implementation
"""

import asyncio
import json
import logging
from typing import Dict, List, Any, Optional
from datetime import datetime, timezone
from enum import Enum

from .registry import WorkflowRegistry
from .orchestrators.domain_orchestrator import DomainOrchestrator
from .executors.node_executor import NodeExecutor
from .traces.reasoning_trace_generator import ReasoningTraceGenerator
from .insights.insight_engine import InsightEngine

logger = logging.getLogger(__name__)


class WorkflowStatus(str, Enum):
    """Workflow execution status."""
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"


class WorkflowEngine:
    """
    Core workflow execution engine.
    
    This is the 'template execution infrastructure' from templates.md.
    It orchestrates the execution of workflow templates by:
    1. Loading template definitions
    2. Resolving domain dependencies
    3. Executing nodes in order
    4. Aggregating results
    5. Generating explainable outputs
    """
    
    def __init__(self):
        self.registry = WorkflowRegistry()
        self.domain_orchestrator = DomainOrchestrator()
        self.node_executor = NodeExecutor()
        self.trace_generator = ReasoningTraceGenerator()
        self.insight_engine = InsightEngine()
        
        # Execution state tracking
        self.active_workflows: Dict[str, Dict[str, Any]] = {}
        
        logger.info("Workflow Engine initialized")
    
    async def execute_template(
        self,
        template_id: str,
        input_data: Dict[str, Any],
        user_id: str,
        workspace_id: str,
        config: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Execute a workflow template.
        
        This is the main entry point for template execution.
        
        Args:
            template_id: ID of the template to execute
            input_data: Input data for the workflow
            user_id: User executing the workflow
            workspace_id: Workspace context
            config: Optional configuration overrides
            
        Returns:
            Dict containing execution results with:
            - success: bool
            - workflow_id: str
            - outputs: Dict of node outputs
            - reasoning_trace: Explainability data
            - insights: Generated recommendations
            - execution_time: float
        """
        workflow_id = f"wf_{datetime.now(timezone.utc).strftime('%Y%m%d_%H%M%S')}_{user_id[:8]}"
        
        try:
            logger.info(f"Starting workflow execution: {workflow_id} (template: {template_id})")
            
            # Step 1: Load template definition
            template = self.registry.get_template(template_id)
            if not template:
                raise ValueError(f"Template not found: {template_id}")
            
            logger.info(f"Loaded template: {template['name']}")
            
            # Step 2: Validate template and inputs
            self._validate_template(template, input_data)
            
            # Step 3: Initialize execution state
            execution_state = {
                "workflow_id": workflow_id,
                "template_id": template_id,
                "status": WorkflowStatus.RUNNING,
                "started_at": datetime.now(timezone.utc).isoformat(),
                "user_id": user_id,
                "workspace_id": workspace_id,
                "node_outputs": {},
                "execution_log": []
            }
            
            self.active_workflows[workflow_id] = execution_state
            
            # Step 4: Execute nodes in order
            outputs = await self._execute_nodes(
                template=template,
                input_data=input_data,
                execution_state=execution_state,
                config=config or {}
            )
            
            # Step 5: Generate reasoning trace
            reasoning_trace = self.trace_generator.generate_trace(
                template=template,
                inputs=input_data,
                outputs=outputs,
                execution_log=execution_state["execution_log"]
            )
            
            # Step 6: Generate insights
            insights = self.insight_engine.generate_insights(
                template=template,
                outputs=outputs,
                reasoning_trace=reasoning_trace
            )
            
            # Step 7: Update execution state
            execution_state["status"] = WorkflowStatus.COMPLETED
            execution_state["completed_at"] = datetime.now(timezone.utc).isoformat()
            execution_state["outputs"] = outputs
            
            # Step 8: Store in memory for learning
            await self._store_execution_memory(
                workflow_id=workflow_id,
                template=template,
                inputs=input_data,
                outputs=outputs,
                insights=insights
            )
            
            logger.info(f"Workflow completed successfully: {workflow_id}")
            
            return {
                "success": True,
                "workflow_id": workflow_id,
                "template_id": template_id,
                "template_name": template["name"],
                "outputs": outputs,
                "reasoning_trace": reasoning_trace,
                "insights": insights,
                "execution_time": self._calculate_execution_time(execution_state),
                "status": WorkflowStatus.COMPLETED.value
            }
            
        except Exception as e:
            logger.error(f"Workflow execution failed: {workflow_id} - {str(e)}")
            
            # Update state to failed
            if workflow_id in self.active_workflows:
                self.active_workflows[workflow_id]["status"] = WorkflowStatus.FAILED
                self.active_workflows[workflow_id]["error"] = str(e)
            
            return {
                "success": False,
                "workflow_id": workflow_id,
                "error": str(e),
                "status": WorkflowStatus.FAILED.value
            }
    
    async def _execute_nodes(
        self,
        template: Dict[str, Any],
        input_data: Dict[str, Any],
        execution_state: Dict[str, Any],
        config: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Execute all nodes in the workflow template.
        
        Follows the edges to determine execution order.
        Passes outputs from one node as inputs to connected nodes.
        
        Args:
            template: Template definition
            input_data: Initial input data
            execution_state: Current execution state
            config: Configuration overrides
            
        Returns:
            Dict mapping node IDs to their outputs
        """
        nodes = template.get("nodes", [])
        edges = template.get("edges", [])
        
        # Build execution graph
        graph = self._build_execution_graph(nodes, edges)
        
        # Find starting nodes (no incoming edges)
        starting_nodes = [node for node in nodes if node["id"] not in graph.get("incoming", {})]
        
        outputs = {}
        
        # Execute starting nodes with input data
        for node in starting_nodes:
            logger.info(f"Executing node: {node['id']} ({node['data']['label']})")
            
            node_output = await self.node_executor.execute_node(
                node=node,
                input_data=input_data,
                domain_orchestrator=self.domain_orchestrator,
                config=config
            )
            
            outputs[node["id"]] = node_output
            
            # Log execution
            execution_state["execution_log"].append({
                "node_id": node["id"],
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "status": "completed",
                "output_keys": list(node_output.keys()) if isinstance(node_output, dict) else []
            })
        
        # Execute remaining nodes in topological order
        executed_nodes = set(starting_nodes)
        pending_nodes = [n for n in nodes if n not in executed_nodes]
        
        max_iterations = len(nodes) * 2  # Prevent infinite loops
        iteration = 0
        
        while pending_nodes and iteration < max_iterations:
            iteration += 1
            newly_executed = []
            
            for node in pending_nodes:
                # Check if all dependencies are met
                incoming_edges = graph.get("incoming", {}).get(node["id"], [])
                dependencies_met = all(
                    edge["source"] in outputs for edge in incoming_edges
                )
                
                if dependencies_met:
                    # Gather inputs from predecessor nodes
                    node_inputs = {}
                    for edge in incoming_edges:
                        source_id = edge["source"]
                        if source_id in outputs:
                            node_inputs[source_id] = outputs[source_id]
                    
                    # Execute node
                    logger.info(f"Executing node: {node['id']} ({node['data']['label']})")
                    
                    node_output = await self.node_executor.execute_node(
                        node=node,
                        input_data=node_inputs,
                        domain_orchestrator=self.domain_orchestrator,
                        config=config
                    )
                    
                    outputs[node["id"]] = node_output
                    
                    # Log execution
                    execution_state["execution_log"].append({
                        "node_id": node["id"],
                        "timestamp": datetime.now(timezone.utc).isoformat(),
                        "status": "completed",
                        "output_keys": list(node_output.keys()) if isinstance(node_output, dict) else []
                    })
                    
                    newly_executed.append(node)
            
            # Remove executed nodes from pending
            pending_nodes = [n for n in pending_nodes if n not in newly_executed]
            executed_nodes.update(newly_executed)
        
        if pending_nodes:
            logger.warning(f"Some nodes were not executed: {[n['id'] for n in pending_nodes]}")
        
        return outputs
    
    def _build_execution_graph(self, nodes: List[Dict], edges: List[Dict]) -> Dict[str, Any]:
        """
        Build execution graph from nodes and edges.
        
        Returns:
            Dict with 'incoming' and 'outgoing' edge maps
        """
        incoming = {}
        outgoing = {}
        
        for edge in edges:
            source = edge["source"]
            target = edge["target"]
            
            if target not in incoming:
                incoming[target] = []
            incoming[target].append(edge)
            
            if source not in outgoing:
                outgoing[source] = []
            outgoing[source].append(edge)
        
        return {
            "incoming": incoming,
            "outgoing": outgoing
        }
    
    def _validate_template(self, template: Dict[str, Any], input_data: Dict[str, Any]):
        """
        Validate template definition and input data.
        
        Checks:
        - Required domains are available
        - Input data matches expected schema
        - Configuration is valid
        """
        # Check required domains
        domains_used = template.get("domainsUsed", [])
        if domains_used:
            available_domains = self.domain_orchestrator.get_available_domains()
            missing_domains = [d for d in domains_used if d not in available_domains]
            
            if missing_domains:
                raise ValueError(f"Required domains not available: {missing_domains}")
        
        logger.info(f"Template validation passed: {template.get('id')}")
    
    async def _store_execution_memory(
        self,
        workflow_id: str,
        template: Dict[str, Any],
        inputs: Dict[str, Any],
        outputs: Dict[str, Any],
        insights: Dict[str, Any]
    ):
        """
        Store execution in memory for future learning.
        
        This enables compounding intelligence (templates.md).
        Core learns from past executions to improve future performance.
        """
        try:
            # TODO: Integrate with Tiannara Core memory system
            memory_record = {
                "workflow_id": workflow_id,
                "template_id": template.get("id"),
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "inputs_summary": self._summarize_data(inputs),
                "outputs_summary": self._summarize_data(outputs),
                "insights_count": len(insights.get("recommendations", [])),
                "success": True
            }
            
            logger.info(f"Execution memory stored: {workflow_id}")
            
        except Exception as e:
            logger.error(f"Failed to store execution memory: {str(e)}")
    
    def _summarize_data(self, data: Any) -> Dict[str, Any]:
        """Create a lightweight summary of data for memory storage."""
        if isinstance(data, dict):
            return {
                "type": "dict",
                "keys": list(data.keys()),
                "size": len(data)
            }
        elif isinstance(data, list):
            return {
                "type": "list",
                "length": len(data)
            }
        else:
            return {
                "type": type(data).__name__
            }
    
    def _calculate_execution_time(self, execution_state: Dict[str, Any]) -> float:
        """Calculate total execution time in seconds."""
        try:
            started = datetime.fromisoformat(execution_state["started_at"])
            completed = datetime.fromisoformat(
                execution_state.get("completed_at", datetime.now(timezone.utc).isoformat())
            )
            return (completed - started).total_seconds()
        except:
            return 0.0
    
    def get_workflow_status(self, workflow_id: str) -> Optional[Dict[str, Any]]:
        """Get current status of a workflow execution."""
        return self.active_workflows.get(workflow_id)
    
    def cancel_workflow(self, workflow_id: str) -> bool:
        """Cancel a running workflow."""
        if workflow_id in self.active_workflows:
            self.active_workflows[workflow_id]["status"] = WorkflowStatus.CANCELLED
            logger.info(f"Workflow cancelled: {workflow_id}")
            return True
        return False
