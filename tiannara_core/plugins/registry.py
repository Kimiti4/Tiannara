"""
Plugin Registry System

Manages dynamic loading, registration, and validation of tools/plugins.
Provides the foundation for Tiannara's self-learning plugin system.
"""

import os
import sys
import importlib
import importlib.util
import inspect
import logging
from typing import Dict, Any, List, Optional, Callable, Type
from dataclasses import dataclass, field
from pathlib import Path
import json
import hashlib
import time


@dataclass
class ToolMetadata:
    """Metadata for a registered tool."""
    name: str
    description: str
    version: str
    author: str
    schema: Dict[str, Any]
    file_path: str
    module_name: str
    class_name: Optional[str] = None
    function_name: Optional[str] = None
    tags: List[str] = field(default_factory=list)
    dependencies: List[str] = field(default_factory=list)
    safety_level: str = "medium"  # "low", "medium", "high", "critical"
    last_modified: float = field(default_factory=time.time)
    hash: str = ""
    usage_count: int = 0
    success_rate: float = 1.0
    avg_execution_time: float = 0.0


@dataclass
class ValidationResult:
    """Result of tool validation."""
    is_valid: bool
    errors: List[str]
    warnings: List[str]
    safety_score: float
    recommended_actions: List[str]


class PluginRegistry:
    """
    Registry for managing Tiannara plugins and tools.
    
    Supports dynamic loading, validation, and performance tracking.
    """
    
    def __init__(self, plugin_dir: str = "plugins/generated"):
        self.plugin_dir = Path(plugin_dir)
        self.plugin_dir.mkdir(parents=True, exist_ok=True)
        
        self.logger = logging.getLogger("tiannara.plugins")
        
        # Registry storage
        self.tools: Dict[str, ToolMetadata] = {}
        self.tool_functions: Dict[str, Callable] = {}
        self.tool_classes: Dict[str, Type] = {}
        
        # Safety and validation
        self.forbidden_patterns = [
            "os.system",
            "subprocess.call",
            "subprocess.run",
            "eval(",
            "exec(",
            "compile(",
            "__import__",
            "open(",
            "file(",
            "input(",
            "raw_input(",
            "rm -rf",
            "sudo ",
            "admin ",
            "registry",
            "system32",
            "windows\\system32"
        ]
        
        # Performance tracking
        self.usage_stats: Dict[str, Dict[str, Any]] = {}
        
        # Load existing tools
        self.load_all_tools()
    
    def load_all_tools(self):
        """Load all tools from the plugin directory."""
        if not self.plugin_dir.exists():
            self.logger.info(f"Plugin directory {self.plugin_dir} does not exist, creating it")
            return
        
        self.logger.info(f"Loading tools from {self.plugin_dir}")
        
        for file_path in self.plugin_dir.glob("*.py"):
            if file_path.name.startswith("__"):
                continue
            
            try:
                self.load_tool_from_file(file_path)
            except Exception as e:
                self.logger.error(f"Failed to load tool from {file_path}: {e}")
        
        self.logger.info(f"Loaded {len(self.tools)} tools")
    
    def load_tool_from_file(self, file_path: Path) -> Optional[str]:
        """
        Load a tool from a Python file.
        
        Args:
            file_path: Path to the Python file
            
        Returns:
            Tool name if successful, None otherwise
        """
        try:
            # Read file content for hashing
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            file_hash = hashlib.md5(content.encode()).hexdigest()
            
            # Check if tool already loaded and unchanged
            tool_name = file_path.stem
            if (tool_name in self.tools and 
                self.tools[tool_name].hash == file_hash and
                self.tools[tool_name].last_modified >= file_path.stat().st_mtime):
                return tool_name
            
            # Validate tool before loading
            validation = self.validate_tool_code(content, file_path.name)
            if not validation.is_valid:
                self.logger.error(f"Tool validation failed for {file_path}: {validation.errors}")
                return None
            
            # Load module
            spec = importlib.util.spec_from_file_location(tool_name, file_path)
            if spec is None or spec.loader is None:
                raise ImportError(f"Could not load spec for {file_path}")
            
            module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(module)
            
            # Find tool function or class
            tool_func = None
            tool_class = None
            
            # Look for TOOL_SCHEMA and run function
            if hasattr(module, 'TOOL_SCHEMA') and hasattr(module, 'run'):
                tool_func = getattr(module, 'run')
                schema = getattr(module, 'TOOL_SCHEMA')
            else:
                # Look for classes with run method
                for name, obj in inspect.getmembers(module, inspect.isclass):
                    if hasattr(obj, 'run') and hasattr(obj, 'TOOL_SCHEMA'):
                        tool_class = obj
                        schema = getattr(obj, 'TOOL_SCHEMA')
                        break
                
                if tool_class is None:
                    # Look for standalone functions
                    for name, obj in inspect.getmembers(module, inspect.isfunction):
                        if name == 'run' or name.endswith('_tool'):
                            tool_func = obj
                            schema = self._infer_schema(obj, content)
                            break
            
            if tool_func is None and tool_class is None:
                raise ValueError("No valid tool function or class found")
            
            # Register tool
            metadata = ToolMetadata(
                name=schema.get('name', tool_name),
                description=schema.get('description', f'Tool from {file_path.name}'),
                version=schema.get('version', '1.0.0'),
                author=schema.get('author', 'Generated'),
                schema=schema,
                file_path=str(file_path),
                module_name=tool_name,
                class_name=tool_class.__name__ if tool_class else None,
                function_name=tool_func.__name__ if tool_func else None,
                tags=schema.get('tags', []),
                dependencies=schema.get('dependencies', []),
                safety_level=validation.safety_score,
                last_modified=file_path.stat().st_mtime,
                hash=file_hash
            )
            
            self.tools[tool_name] = metadata
            
            if tool_func:
                self.tool_functions[tool_name] = tool_func
            if tool_class:
                self.tool_classes[tool_name] = tool_class
            
            # Initialize usage stats
            if tool_name not in self.usage_stats:
                self.usage_stats[tool_name] = {
                    'usage_count': 0,
                    'success_count': 0,
                    'total_time': 0.0,
                    'last_used': None
                }
            
            self.logger.info(f"Successfully loaded tool: {tool_name}")
            return tool_name
            
        except Exception as e:
            self.logger.error(f"Failed to load tool from {file_path}: {e}")
            return None
    
    def validate_tool_code(self, code: str, filename: str) -> ValidationResult:
        """
        Validate tool code for safety and correctness.
        
        Args:
            code: Python code to validate
            filename: Name of the file being validated
            
        Returns:
            ValidationResult with validation details
        """
        errors = []
        warnings = []
        safety_score = 1.0
        
        # Check for forbidden patterns
        for pattern in self.forbidden_patterns:
            if pattern in code:
                severity = self._get_pattern_severity(pattern)
                if severity == "critical":
                    errors.append(f"Critical security issue: {pattern} detected")
                    safety_score -= 0.5
                elif severity == "high":
                    warnings.append(f"High risk pattern: {pattern} detected")
                    safety_score -= 0.2
                else:
                    warnings.append(f"Potentially unsafe pattern: {pattern} detected")
                    safety_score -= 0.1
        
        # Basic syntax check
        try:
            compile(code, filename, 'exec')
        except SyntaxError as e:
            errors.append(f"Syntax error: {e}")
            safety_score -= 0.3
        
        # Check for required elements
        if "TOOL_SCHEMA" not in code:
            warnings.append("No TOOL_SCHEMA found - will try to infer schema")
            safety_score -= 0.1
        
        if "def run(" not in code and "class " not in code:
            errors.append("No run function or class found")
            safety_score -= 0.4
        
        # Check imports
        dangerous_imports = ["os", "sys", "subprocess", "socket", "urllib"]
        for imp in dangerous_imports:
            if f"import {imp}" in code or f"from {imp}" in code:
                warnings.append(f"Potentially dangerous import: {imp}")
                safety_score -= 0.1
        
        # Ensure safety score is bounded
        safety_score = max(0.0, min(1.0, safety_score))
        
        # Generate recommendations
        recommendations = []
        if safety_score < 0.5:
            recommendations.append("Tool has significant safety concerns - review before use")
        if len(errors) > 0:
            recommendations.append("Fix syntax and structural errors before using")
        if len(warnings) > 3:
            recommendations.append("Consider reducing complexity and risky operations")
        
        return ValidationResult(
            is_valid=len(errors) == 0,
            errors=errors,
            warnings=warnings,
            safety_score=safety_score,
            recommended_actions=recommendations
        )
    
    def _get_pattern_severity(self, pattern: str) -> str:
        """Get severity level for a forbidden pattern."""
        critical_patterns = ["os.system", "subprocess.call", "eval(", "exec("]
        high_patterns = ["subprocess.run", "__import__", "rm -rf", "sudo "]
        
        if pattern in critical_patterns:
            return "critical"
        elif pattern in high_patterns:
            return "high"
        else:
            return "medium"
    
    def _infer_schema(self, func: Callable, code: str) -> Dict[str, Any]:
        """Infer tool schema from function and code."""
        sig = inspect.signature(func)
        params = list(sig.parameters.keys())
        
        return {
            "name": func.__name__,
            "description": func.__doc__ or f"Tool function {func.__name__}",
            "version": "1.0.0",
            "author": "Inferred",
            "params": params,
            "tags": ["inferred"]
        }
    
    def get_tool(self, name: str) -> Optional[Callable]:
        """Get a tool function by name."""
        if name in self.tool_functions:
            return self.tool_functions[name]
        elif name in self.tool_classes:
            # Instantiate class and return run method
            tool_class = self.tool_classes[name]
            try:
                instance = tool_class()
                return getattr(instance, 'run', None)
            except Exception as e:
                self.logger.error(f"Failed to instantiate tool class {name}: {e}")
                return None
        
        return None
    
    def get_tool_metadata(self, name: str) -> Optional[ToolMetadata]:
        """Get metadata for a tool."""
        return self.tools.get(name)
    
    def list_tools(self, tag_filter: Optional[str] = None) -> List[str]:
        """List all registered tools, optionally filtered by tag."""
        if tag_filter:
            return [name for name, metadata in self.tools.items() 
                   if tag_filter in metadata.tags]
        return list(self.tools.keys())
    
    def execute_tool(self, name: str, params: Dict[str, Any]) -> Dict[str, Any]:
        """
        Execute a tool with given parameters.
        
        Args:
            name: Tool name
            params: Parameters for the tool
            
        Returns:
            Execution result with metadata
        """
        if name not in self.tools:
            return {
                "success": False,
                "error": f"Tool '{name}' not found",
                "available_tools": list(self.tools.keys())
            }
        
        tool = self.get_tool(name)
        if tool is None:
            return {
                "success": False,
                "error": f"Tool '{name}' found but not executable"
            }
        
        metadata = self.tools[name]
        start_time = time.time()
        
        try:
            # Update usage stats
            self.usage_stats[name]['usage_count'] += 1
            self.usage_stats[name]['last_used'] = time.time()
            
            # Execute tool
            result = tool(params)
            
            execution_time = time.time() - start_time
            
            # Update success stats
            self.usage_stats[name]['success_count'] += 1
            self.usage_stats[name]['total_time'] += execution_time
            
            # Update metadata
            metadata.usage_count += 1
            metadata.avg_execution_time = (
                (metadata.avg_execution_time * (metadata.usage_count - 1) + execution_time) / 
                metadata.usage_count
            )
            metadata.success_rate = (
                (metadata.success_rate * (metadata.usage_count - 1) + 1.0) / 
                metadata.usage_count
            )
            
            return {
                "success": True,
                "result": result,
                "tool_name": name,
                "execution_time": execution_time,
                "metadata": {
                    "version": metadata.version,
                    "author": metadata.author
                }
            }
            
        except Exception as e:
            execution_time = time.time() - start_time
            
            # Update failure stats
            self.usage_stats[name]['total_time'] += execution_time
            
            # Update metadata
            metadata.usage_count += 1
            metadata.avg_execution_time = (
                (metadata.avg_execution_time * (metadata.usage_count - 1) + execution_time) / 
                metadata.usage_count
            )
            metadata.success_rate = (
                (metadata.success_rate * (metadata.usage_count - 1)) / 
                metadata.usage_count
            )
            
            self.logger.error(f"Tool '{name}' execution failed: {e}")
            
            return {
                "success": False,
                "error": str(e),
                "tool_name": name,
                "execution_time": execution_time
            }
    
    def create_tool(self, name: str, code: str, schema: Optional[Dict[str, Any]] = None) -> bool:
        """
        Create a new tool from code.
        
        Args:
            name: Tool name
            code: Python code for the tool
            schema: Optional tool schema
            
        Returns:
            True if successful, False otherwise
        """
        try:
            # Validate code first
            validation = self.validate_tool_code(code, f"{name}.py")
            if not validation.is_valid:
                self.logger.error(f"Tool creation failed validation: {validation.errors}")
                return False
            
            # Create file
            tool_file = self.plugin_dir / f"{name}.py"
            
            # Add schema if provided
            if schema and "TOOL_SCHEMA" not in code:
                schema_code = f"TOOL_SCHEMA = {json.dumps(schema, indent=2)}\n\n"
                code = schema_code + code
            
            with open(tool_file, 'w', encoding='utf-8') as f:
                f.write(code)
            
            # Load the tool
            loaded_name = self.load_tool_from_file(tool_file)
            
            return loaded_name is not None
            
        except Exception as e:
            self.logger.error(f"Failed to create tool '{name}': {e}")
            return False
    
    def remove_tool(self, name: str) -> bool:
        """Remove a tool from the registry."""
        if name not in self.tools:
            return False
        
        try:
            # Remove file
            metadata = self.tools[name]
            file_path = Path(metadata.file_path)
            if file_path.exists():
                file_path.unlink()
            
            # Remove from registry
            del self.tools[name]
            self.tool_functions.pop(name, None)
            self.tool_classes.pop(name, None)
            self.usage_stats.pop(name, None)
            
            self.logger.info(f"Removed tool: {name}")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to remove tool '{name}': {e}")
            return False
    
    def get_tool_statistics(self) -> Dict[str, Any]:
        """Get statistics about tool usage."""
        total_usage = sum(stats['usage_count'] for stats in self.usage_stats.values())
        total_success = sum(stats['success_count'] for stats in self.usage_stats.values())
        
        return {
            "total_tools": len(self.tools),
            "total_usage": total_usage,
            "overall_success_rate": total_success / total_usage if total_usage > 0 else 0,
            "most_used_tools": sorted(
                [(name, stats['usage_count']) for name, stats in self.usage_stats.items()],
                key=lambda x: x[1],
                reverse=True
            )[:5],
            "tool_performance": {
                name: {
                    "usage_count": stats['usage_count'],
                    "success_rate": stats['success_count'] / stats['usage_count'] if stats['usage_count'] > 0 else 0,
                    "avg_time": stats['total_time'] / stats['usage_count'] if stats['usage_count'] > 0 else 0
                }
                for name, stats in self.usage_stats.items()
            }
        }
    
    def reload_tool(self, name: str) -> bool:
        """Reload a tool from its file."""
        if name not in self.tools:
            return False
        
        metadata = self.tools[name]
        file_path = Path(metadata.file_path)
        
        if not file_path.exists():
            self.logger.error(f"Tool file {file_path} does not exist")
            return False
        
        try:
            return self.load_tool_from_file(file_path) is not None
        except Exception as e:
            self.logger.error(f"Failed to reload tool '{name}': {e}")
            return False


# Global registry instance
_plugin_registry = None

def get_plugin_registry() -> PluginRegistry:
    """Get or create the global plugin registry instance."""
    global _plugin_registry
    if _plugin_registry is None:
        _plugin_registry = PluginRegistry()
    return _plugin_registry

def register_tool(name: str, code: str, schema: Optional[Dict[str, Any]] = None) -> bool:
    """Quick access function for registering tools."""
    registry = get_plugin_registry()
    return registry.create_tool(name, code, schema)

def execute_tool(name: str, params: Dict[str, Any]) -> Dict[str, Any]:
    """Quick access function for executing tools."""
    registry = get_plugin_registry()
    return registry.execute_tool(name, params)

def list_available_tools(tag_filter: Optional[str] = None) -> List[str]:
    """Quick access function for listing tools."""
    registry = get_plugin_registry()
    return registry.list_tools(tag_filter)
