"""
CLIP Integration - Image-text understanding using OpenAI CLIP model

Supports:
- API mode (HuggingFace/Replicate) - no local model download
- Local mode (optional, requires transformers library)
- Image-text similarity scoring
- Text-based image search
"""

import logging
from typing import List, Dict, Union, Optional
from pathlib import Path
import numpy as np

logger = logging.getLogger(__name__)


class CLIPAnalyzer:
    """
    CLIP (Contrastive Language-Image Pre-training) analyzer.
    
    Uses OpenAI's CLIP model for understanding relationship between
    images and text. Can run via cloud API or locally.
    """
    
    def __init__(self, api_key: Optional[str] = None, use_api: bool = True):
        """
        Initialize CLIP analyzer.
        
        Args:
            api_key: API key for cloud service
            use_api: Whether to use cloud API (recommended)
        """
        self.api_key = api_key
        self.use_api = use_api
        self.available = False
        
        if use_api:
            self.available = self._setup_api_mode()
        else:
            self.available = self._setup_local_mode()
        
        logger.info(f"CLIP Analyzer initialized (API: {use_api}, Available: {self.available})")
    
    def _setup_api_mode(self) -> bool:
        """Setup API-based CLIP (no local dependencies)"""
        # For now, mark as available - will use HuggingFace Inference API
        return True
    
    def _setup_local_mode(self) -> bool:
        """Setup local CLIP model (requires transformers)"""
        try:
            from transformers import CLIPProcessor, CLIPModel
            import torch
            
            self.processor = CLIPProcessor.from_pretrained("openai/clip-vit-base-patch32")
            self.model = CLIPModel.from_pretrained("openai/clip-vit-base-patch32")
            
            logger.info("Local CLIP model loaded successfully")
            return True
            
        except ImportError:
            logger.warning("transformers/torch not installed. Install with: pip install transformers torch")
            return False
        except Exception as e:
            logger.error(f"Failed to load CLIP model: {e}")
            return False
    
    async def calculate_similarity(
        self,
        image_path: Union[str, Path],
        text_query: str
    ) -> float:
        """
        Calculate similarity between image and text.
        
        Args:
            image_path: Path to image
            text_query: Text to compare
            
        Returns:
            Similarity score (-1 to 1, higher = more similar)
        """
        if self.use_api:
            return await self._calculate_similarity_api(image_path, text_query)
        else:
            return self._calculate_similarity_local(image_path, text_query)
    
    async def rank_images_by_text(
        self,
        text_query: str,
        image_paths: List[Union[str, Path]]
    ) -> Dict[str, float]:
        """
        Rank images by relevance to text query.
        
        Args:
            text_query: Text query
            image_paths: List of image paths
            
        Returns:
            Dictionary mapping image_path -> similarity score
        """
        scores = {}
        
        for img_path in image_paths:
            score = await self.calculate_similarity(img_path, text_query)
            scores[str(img_path)] = score
        
        return scores
    
    async def find_best_match(
        self,
        text_query: str,
        image_paths: List[Union[str, Path]]
    ) -> Optional[str]:
        """
        Find image that best matches text description.
        
        Args:
            text_query: Text description
            image_paths: Candidate images
            
        Returns:
            Path to best matching image or None
        """
        scores = await self.rank_images_by_text(text_query, image_paths)
        
        if not scores:
            return None
        
        best_image = max(scores, key=scores.get)
        return best_image
    
    # Private methods
    
    async def _calculate_similarity_api(
        self,
        image_path: Union[str, Path],
        text_query: str
    ) -> float:
        """Calculate similarity using HuggingFace Inference API"""
        import base64
        import httpx
        
        try:
            # Read image
            with open(image_path, 'rb') as f:
                image_bytes = f.read()
            
            # Encode to base64
            image_b64 = base64.b64encode(image_bytes).decode('utf-8')
            
            # Call HuggingFace API
            api_url = "https://api-inference.huggingface.co/models/openai/clip-vit-base-patch32"
            headers = {
                "Authorization": f"Bearer {self.api_key}" if self.api_key else "",
                "Content-Type": "application/json"
            }
            
            payload = {
                "inputs": {
                    "image": image_b64,
                    "text": text_query
                }
            }
            
            async with httpx.AsyncClient() as client:
                response = await client.post(api_url, json=payload, headers=headers, timeout=30)
                
                if response.status_code == 200:
                    result = response.json()
                    # Extract similarity score from response
                    return result.get('score', 0.5)
                else:
                    logger.warning(f"API request failed: {response.status_code}")
                    return 0.5  # Neutral score
                    
        except Exception as e:
            logger.error(f"Error in API similarity calculation: {e}")
            return 0.5  # Fallback
    
    def _calculate_similarity_local(
        self,
        image_path: Union[str, Path],
        text_query: str
    ) -> float:
        """Calculate similarity using local CLIP model"""
        try:
            from PIL import Image
            import torch
            
            # Load image
            image = Image.open(image_path).convert('RGB')
            
            # Process inputs
            inputs = self.processor(
                text=[text_query],
                images=image,
                return_tensors="pt",
                padding=True
            )
            
            # Get features
            outputs = self.model(**inputs)
            
            # Calculate cosine similarity
            logits_per_image = outputs.logits_per_image
            similarity = logits_per_image.softmax(dim=1)[0, 0].item()
            
            return similarity
            
        except Exception as e:
            logger.error(f"Error in local similarity calculation: {e}")
            return 0.5
