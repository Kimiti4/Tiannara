"""
Object Detector - YOLO-based object detection

Supports:
- API mode (via cloud services)
- Local mode (requires ultralytics library)
"""

import logging
from typing import List, Dict, Any, Union
from pathlib import Path
import numpy as np

logger = logging.getLogger(__name__)


class YOLODetector:
    """YOLO object detector for identifying objects in images"""
    
    def __init__(self, api_key: str = None, use_api: bool = True):
        self.api_key = api_key
        self.use_api = use_api
        self.available = not use_api  # Local mode requires setup
        
        if not use_api:
            self._setup_local()
    
    def _setup_local(self):
        """Setup local YOLO model"""
        try:
            from ultralytics import YOLO
            self.model = YOLO('yolov8n.pt')  # Nano model for speed
            self.available = True
            logger.info("Local YOLO model loaded")
        except ImportError:
            logger.warning("ultralytics not installed. pip install ultralytics")
        except Exception as e:
            logger.error(f"Failed to load YOLO: {e}")
    
    async def detect(self, image_data: np.ndarray) -> List[Dict[str, Any]]:
        """Detect objects in image"""
        if self.use_api:
            return await self._detect_api(image_data)
        else:
            return self._detect_local(image_data)
    
    async def _detect_api(self, image_data: np.ndarray) -> List[Dict[str, Any]]:
        """Use API for detection (placeholder - integrate with Roboflow/Google Vision)"""
        # For now, return mock data
        return [
            {'label': 'person', 'confidence': 0.95, 'count': 2},
            {'label': 'car', 'confidence': 0.88, 'count': 1},
        ]
    
    def _detect_local(self, image_data: np.ndarray) -> List[Dict[str, Any]]:
        """Use local YOLO model"""
        if not self.available:
            return []
        
        results = self.model(image_data, verbose=False)
        
        detections = {}
        for result in results:
            for box in result.boxes:
                class_id = int(box.cls[0])
                class_name = self.model.names[class_id]
                confidence = float(box.conf[0])
                
                if class_name not in detections:
                    detections[class_name] = {'count': 0, 'confidence': 0}
                
                detections[class_name]['count'] += 1
                detections[class_name]['confidence'] = max(
                    detections[class_name]['confidence'],
                    confidence
                )
        
        return [
            {'label': label, 'count': info['count'], 'confidence': info['confidence']}
            for label, info in detections.items()
        ]
