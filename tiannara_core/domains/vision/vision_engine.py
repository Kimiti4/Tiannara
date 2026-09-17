"""
Vision Engine - Main orchestrator for computer vision tasks

Integrates:
- Image preprocessing
- Object detection (YOLO via API or local)
- Image-text understanding (CLIP via API)
- Scene analysis and description
- Multimodal reasoning with NLP domain
"""

import logging
from typing import Dict, List, Optional, Any, Union
from pathlib import Path
from dataclasses import dataclass, field
from datetime import datetime

from .image_processor import ImageProcessor
from .clip_integration import CLIPAnalyzer
from .object_detector import YOLODetector
from .scene_analyzer import SceneAnalyzer

logger = logging.getLogger(__name__)


@dataclass
class VisionResult:
    """Complete vision analysis result"""
    image_path: Optional[str] = None
    image_url: Optional[str] = None
    
    # Object detection
    detected_objects: List[Dict[str, Any]] = field(default_factory=list)
    
    # Image-text matching
    text_matches: List[Dict[str, float]] = field(default_factory=list)
    
    # Scene analysis
    scene_description: Optional[str] = None
    scene_categories: List[str] = field(default_factory=list)
    dominant_colors: List[str] = field(default_factory=list)
    
    # Metadata
    image_dimensions: Optional[Dict[str, int]] = None
    processing_time_ms: float = 0.0
    models_used: List[str] = field(default_factory=list)
    timestamp: datetime = field(default_factory=datetime.now)
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            'image_path': self.image_path,
            'image_url': self.image_url,
            'detected_objects': self.detected_objects,
            'text_matches': self.text_matches,
            'scene_description': self.scene_description,
            'scene_categories': self.scene_categories,
            'dominant_colors': self.dominant_colors,
            'image_dimensions': self.image_dimensions,
            'processing_time_ms': self.processing_time_ms,
            'models_used': self.models_used,
            'timestamp': self.timestamp.isoformat(),
        }


class VisionEngine:
    """
    Main vision engine orchestrating all CV tasks.
    
    Usage:
        engine = VisionEngine()
        
        # Analyze local image
        result = await engine.analyze_image("path/to/image.jpg")
        
        # Analyze image from URL
        result = await engine.analyze_image_url("https://example.com/image.jpg")
        
        # Find similar images by text
        matches = await engine.find_by_text("red car", ["img1.jpg", "img2.jpg"])
    """
    
    def __init__(
        self,
        use_api: bool = True,  # Use cloud APIs instead of local models
        api_provider: str = "huggingface",  # huggingface, replicate, custom
        api_key: Optional[str] = None,
    ):
        """
        Initialize Vision Engine.
        
        Args:
            use_api: Whether to use cloud APIs (recommended for production)
            api_provider: API provider name
            api_key: API key for cloud services
        """
        self.use_api = use_api
        self.api_provider = api_provider
        self.api_key = api_key
        
        # Initialize components
        self.image_processor = ImageProcessor()
        self.clip_analyzer = CLIPAnalyzer(api_key=api_key, use_api=use_api)
        self.yolo_detector = YOLODetector(api_key=api_key, use_api=use_api)
        self.scene_analyzer = SceneAnalyzer(api_key=api_key, use_api=use_api)
        
        logger.info(f"Vision Engine initialized (API mode: {use_api})")
    
    async def analyze_image(
        self,
        image_path: Union[str, Path],
        detect_objects: bool = True,
        analyze_scene: bool = True,
        extract_colors: bool = True,
    ) -> VisionResult:
        """
        Comprehensive image analysis.
        
        Args:
            image_path: Path to image file
            detect_objects: Run object detection
            analyze_scene: Run scene analysis
            extract_colors: Extract dominant colors
            
        Returns:
            VisionResult with complete analysis
        """
        import time
        start_time = time.time()
        
        result = VisionResult(image_path=str(image_path))
        
        try:
            # Load and preprocess image
            image_data = self.image_processor.load_image(image_path)
            result.image_dimensions = {
                'width': image_data.shape[1],
                'height': image_data.shape[0],
            }
            
            # Object detection
            if detect_objects:
                objects = await self.yolo_detector.detect(image_data)
                result.detected_objects = objects
                result.models_used.append('yolo')
            
            # Scene analysis
            if analyze_scene:
                scene_info = await self.scene_analyzer.analyze(image_data)
                result.scene_description = scene_info.get('description')
                result.scene_categories = scene_info.get('categories', [])
                result.models_used.append('scene_analyzer')
            
            # Color extraction
            if extract_colors:
                colors = self.image_processor.extract_dominant_colors(image_data, n_colors=5)
                result.dominant_colors = colors
            
            result.processing_time_ms = (time.time() - start_time) * 1000
            
            logger.info(f"Image analysis complete in {result.processing_time_ms:.0f}ms")
            
        except Exception as e:
            logger.error(f"Error analyzing image: {e}", exc_info=True)
            result.processing_time_ms = (time.time() - start_time) * 1000
        
        return result
    
    async def analyze_image_url(
        self,
        image_url: str,
        detect_objects: bool = True,
        analyze_scene: bool = True,
    ) -> VisionResult:
        """
        Analyze image from URL.
        
        Args:
            image_url: URL of image to analyze
            detect_objects: Run object detection
            analyze_scene: Run scene analysis
            
        Returns:
            VisionResult with analysis
        """
        # Download image
        image_data = await self.image_processor.download_image(image_url)
        
        # Save temporarily
        temp_path = self.image_processor.save_temporary(image_data)
        
        # Analyze
        result = await self.analyze_image(
            temp_path,
            detect_objects=detect_objects,
            analyze_scene=analyze_scene,
        )
        
        result.image_url = image_url
        
        # Cleanup
        Path(temp_path).unlink(missing_ok=True)
        
        return result
    
    async def find_by_text(
        self,
        query_text: str,
        image_paths: List[Union[str, Path]],
        top_k: int = 3,
    ) -> List[Dict[str, Any]]:
        """
        Find images most relevant to text query using CLIP.
        
        Args:
            query_text: Text query
            image_paths: List of image paths to search
            top_k: Number of top results
            
        Returns:
            List of {path, score} sorted by relevance
        """
        scores = await self.clip_analyzer.rank_images_by_text(query_text, image_paths)
        
        # Sort by score descending
        ranked = sorted(scores.items(), key=lambda x: x[1], reverse=True)
        
        return [
            {'image_path': path, 'relevance_score': score}
            for path, score in ranked[:top_k]
        ]
    
    async def describe_image(self, image_path: Union[str, Path]) -> str:
        """
        Generate natural language description of image.
        
        Args:
            image_path: Path to image
            
        Returns:
            Natural language description
        """
        result = await self.analyze_image(
            image_path,
            detect_objects=True,
            analyze_scene=True,
        )
        
        # Combine object detection and scene analysis into description
        description_parts = []
        
        if result.scene_description:
            description_parts.append(result.scene_description)
        
        if result.detected_objects:
            objects_str = ", ".join([
                f"{obj['count']} {obj['label']}"
                for obj in result.detected_objects[:5]
            ])
            description_parts.append(f"Contains: {objects_str}")
        
        return ". ".join(description_parts) if description_parts else "Unable to describe image"
    
    async def compare_images(
        self,
        image1_path: Union[str, Path],
        image2_path: Union[str, Path],
    ) -> Dict[str, float]:
        """
        Compare similarity between two images using CLIP embeddings.
        
        Args:
            image1_path: First image path
            image2_path: Second image path
            
        Returns:
            Dictionary with similarity metrics
        """
        similarity = await self.clip_analyzer.calculate_similarity(
            image1_path, image2_path
        )
        
        return {
            'cosine_similarity': similarity,
            'match_probability': (similarity + 1) / 2,  # Normalize to 0-1
        }
    
    def get_engine_status(self) -> Dict[str, Any]:
        """Get engine status and capabilities"""
        return {
            'status': 'operational',
            'use_api': self.use_api,
            'api_provider': self.api_provider,
            'capabilities': [
                'object_detection',
                'scene_analysis',
                'image_text_matching',
                'color_extraction',
                'image_comparison',
            ],
            'components': {
                'image_processor': 'active',
                'clip_analyzer': 'active' if self.clip_analyzer.available else 'inactive',
                'yolo_detector': 'active' if self.yolo_detector.available else 'inactive',
                'scene_analyzer': 'active' if self.scene_analyzer.available else 'inactive',
            }
        }
