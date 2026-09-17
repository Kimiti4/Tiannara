"""
Workflow Template Registry

Stores and manages workflow template definitions.
Templates can be loaded from:
- JSON/YAML files
- Database
- API endpoints

Following templates.md architecture:
- Templates define orchestration blueprints
- Include metadata: domains, outputs, widgets, automation rules
- Support tier-based access control
"""

import json
import logging
from typing import Dict, List, Optional, Any
from pathlib import Path

logger = logging.getLogger(__name__)


class WorkflowRegistry:
    """
    Registry for workflow templates.
    
    Manages template storage, retrieval, and validation.
    """
    
    def __init__(self):
        self.templates: Dict[str, Dict[str, Any]] = {}
        self.template_categories: Dict[str, List[str]] = {}
        
        # Load default templates
        self._load_default_templates()
        
        logger.info(f"Workflow Registry initialized with {len(self.templates)} templates")
    
    def _load_default_templates(self):
        """Load default workflow templates."""
        # TODO: Load from tiannara_saas/lib/workflow-templates.ts or JSON files
        # For now, we'll load from a simplified JSON representation
        
        templates_path = Path(__file__).parent.parent / "templates" / "default_templates.json"
        
        if templates_path.exists():
            try:
                with open(templates_path, 'r') as f:
                    templates_data = json.load(f)
                    
                    for template in templates_data:
                        self.register_template(template)
                        
                logger.info(f"Loaded {len(templates_data)} templates from file")
                
            except Exception as e:
                logger.error(f"Failed to load templates from file: {str(e)}")
        else:
            logger.warning("No default templates file found, registry is empty")
    
    def register_template(self, template: Dict[str, Any]):
        """
        Register a workflow template.
        
        Args:
            template: Template definition dict
        """
        template_id = template.get("id")
        if not template_id:
            raise ValueError("Template must have an 'id' field")
        
        # Validate required fields
        required_fields = ["id", "name", "description", "category", "nodes", "edges"]
        missing_fields = [f for f in required_fields if f not in template]
        
        if missing_fields:
            raise ValueError(f"Template missing required fields: {missing_fields}")
        
        # Store template
        self.templates[template_id] = template
        
        # Update category index
        category = template.get("category", "uncategorized")
        if category not in self.template_categories:
            self.template_categories[category] = []
        
        if template_id not in self.template_categories[category]:
            self.template_categories[category].append(template_id)
        
        logger.info(f"Registered template: {template_id} ({template['name']})")
    
    def get_template(self, template_id: str) -> Optional[Dict[str, Any]]:
        """
        Get a template by ID.
        
        Args:
            template_id: Template ID
            
        Returns:
            Template definition or None if not found
        """
        return self.templates.get(template_id)
    
    def list_templates(
        self,
        category: Optional[str] = None,
        tier: Optional[str] = None,
        difficulty: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        List templates with optional filtering.
        
        Args:
            category: Filter by category
            tier: Filter by required tier (starter/professional/enterprise)
            difficulty: Filter by difficulty (beginner/intermediate/advanced)
            
        Returns:
            List of matching templates
        """
        templates = list(self.templates.values())
        
        # Apply filters
        if category:
            templates = [t for t in templates if t.get("category") == category]
        
        if tier:
            templates = [
                t for t in templates 
                if t.get("tierRequired", "starter") == tier
            ]
        
        if difficulty:
            templates = [
                t for t in templates 
                if t.get("difficulty") == difficulty
            ]
        
        return templates
    
    def get_templates_by_category(self, category: str) -> List[Dict[str, Any]]:
        """Get all templates in a category."""
        template_ids = self.template_categories.get(category, [])
        return [
            self.templates[tid] 
            for tid in template_ids 
            if tid in self.templates
        ]
    
    def get_templates_for_tier(self, tier: str) -> List[Dict[str, Any]]:
        """
        Get templates accessible to a specific tier.
        
        Enterprise gets all templates.
        Professional gets professional + starter.
        Starter gets only starter templates.
        """
        if tier == "enterprise":
            return list(self.templates.values())
        
        elif tier == "professional":
            return [
                t for t in self.templates.values()
                if t.get("tierRequired", "starter") in ["starter", "professional"]
            ]
        
        else:  # starter
            return [
                t for t in self.templates.values()
                if t.get("tierRequired", "starter") == "starter"
            ]
    
    def search_templates(self, query: str) -> List[Dict[str, Any]]:
        """
        Search templates by keyword.
        
        Searches in name, description, and tags.
        """
        query_lower = query.lower()
        
        results = []
        for template in self.templates.values():
            # Search in name
            if query_lower in template.get("name", "").lower():
                results.append(template)
                continue
            
            # Search in description
            if query_lower in template.get("description", "").lower():
                results.append(template)
                continue
            
            # Search in tags
            tags = template.get("tags", [])
            if any(query_lower in tag.lower() for tag in tags):
                results.append(template)
                continue
        
        return results
    
    def get_available_categories(self) -> List[str]:
        """Get list of all available categories."""
        return list(self.template_categories.keys())
    
    def get_template_count(self) -> int:
        """Get total number of registered templates."""
        return len(self.templates)
    
    def validate_template_access(
        self,
        template_id: str,
        user_tier: str
    ) -> bool:
        """
        Check if user has access to a template based on their tier.
        
        Args:
            template_id: Template ID
            user_tier: User's subscription tier
            
        Returns:
            True if user has access
        """
        template = self.get_template(template_id)
        if not template:
            return False
        
        required_tier = template.get("tierRequired", "starter")
        
        # Tier hierarchy
        tier_levels = {
            "starter": 1,
            "professional": 2,
            "enterprise": 3
        }
        
        user_level = tier_levels.get(user_tier, 0)
        required_level = tier_levels.get(required_tier, 0)
        
        return user_level >= required_level
