"""
API Catalog - API discovery and documentation

Manages API listings, versioning, documentation,
and search functionality for the API marketplace.
"""

import logging
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum

logger = logging.getLogger(__name__)


class APIStatus(Enum):
    """API listing status."""
    DRAFT = "draft"
    PUBLISHED = "published"
    DEPRECATED = "deprecated"
    RETIRED = "retired"


@dataclass
class APIListing:
    """API marketplace listing."""
    api_id: str
    name: str
    description: str
    version: str
    status: APIStatus
    category: str
    pricing_tier: str  # 'free', 'basic', 'pro', 'enterprise'
    base_url: str
    documentation_url: str
    created_at: datetime
    updated_at: datetime
    tags: List[str] = field(default_factory=list)
    rating: float = 0.0
    total_subscribers: int = 0


class APICatalog:
    """API catalog and discovery service.
    
    Features:
    - API listing management
    - Version control
    - Category organization
    - Search and filtering
    - Rating and review system
    """
    
    def __init__(self):
        self.apis: Dict[str, APIListing] = {}
        self.categories: Dict[str, List[str]] = {}  # category -> api_ids
        
    def publish_api(self, api_data: Dict[str, Any]) -> APIListing:
        """Publish a new API to the marketplace.
        
        Args:
            api_data: API metadata
            
        Returns:
            Created APIListing
        """
        api_id = api_data.get('api_id', f"api_{len(self.apis) + 1}")
        
        listing = APIListing(
            api_id=api_id,
            name=api_data['name'],
            description=api_data.get('description', ''),
            version=api_data.get('version', '1.0.0'),
            status=APIStatus.PUBLISHED,
            category=api_data.get('category', 'general'),
            pricing_tier=api_data.get('pricing_tier', 'free'),
            base_url=api_data.get('base_url', ''),
            documentation_url=api_data.get('documentation_url', ''),
            created_at=datetime.now(),
            updated_at=datetime.now(),
            tags=api_data.get('tags', []),
            rating=0.0,
            total_subscribers=0
        )
        
        self.apis[api_id] = listing
        
        # Add to category
        if listing.category not in self.categories:
            self.categories[listing.category] = []
        self.categories[listing.category].append(api_id)
        
        logger.info(f"API published: {listing.name} ({api_id})")
        return listing
    
    def get_api(self, api_id: str) -> Optional[APIListing]:
        """Get API listing by ID.
        
        Args:
            api_id: API identifier
            
        Returns:
            APIListing or None if not found
        """
        return self.apis.get(api_id)
    
    def search_apis(self, query: str, category: Optional[str] = None,
                   pricing_tier: Optional[str] = None) -> List[APIListing]:
        """Search APIs with filters.
        
        Args:
            query: Search query string
            category: Filter by category
            pricing_tier: Filter by pricing tier
            
        Returns:
            Matching API listings
        """
        results = []
        query_lower = query.lower()
        
        for api in self.apis.values():
            # Check status
            if api.status != APIStatus.PUBLISHED:
                continue
            
            # Apply filters
            if category and api.category != category:
                continue
            
            if pricing_tier and api.pricing_tier != pricing_tier:
                continue
            
            # Search in name, description, tags
            if (query_lower in api.name.lower() or
                query_lower in api.description.lower() or
                any(query_lower in tag.lower() for tag in api.tags)):
                results.append(api)
        
        logger.info(f"Search returned {len(results)} results for '{query}'")
        return results
    
    def get_apis_by_category(self, category: str) -> List[APIListing]:
        """Get all APIs in a category.
        
        Args:
            category: Category name
            
        Returns:
            List of API listings
        """
        api_ids = self.categories.get(category, [])
        return [
            self.apis[api_id] for api_id in api_ids
            if api_id in self.apis
        ]
    
    def update_rating(self, api_id: str, rating: float):
        """Update API rating.
        
        Args:
            api_id: API identifier
            rating: New rating (0-5)
        """
        if api_id in self.apis:
            self.apis[api_id].rating = rating
            self.apis[api_id].updated_at = datetime.now()
    
    def increment_subscribers(self, api_id: str):
        """Increment subscriber count for an API.
        
        Args:
            api_id: API identifier
        """
        if api_id in self.apis:
            self.apis[api_id].total_subscribers += 1
    
    def get_catalog_stats(self) -> Dict[str, Any]:
        """Get catalog statistics."""
        return {
            'total_apis': len(self.apis),
            'published_apis': sum(
                1 for api in self.apis.values()
                if api.status == APIStatus.PUBLISHED
            ),
            'categories': len(self.categories),
            'total_subscribers': sum(
                api.total_subscribers for api in self.apis.values()
            )
        }
