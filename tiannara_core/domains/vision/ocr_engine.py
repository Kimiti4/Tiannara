"""
OCR Module - Optical Character Recognition for Tiannara

Supports:
- Tesseract OCR (local, free)
- EasyOCR (local, supports 80+ languages)
- Cloud OCR APIs (Google Vision, AWS Textract)

Extracts text from images, screenshots, documents, and photos.
"""

import logging
from typing import Dict, List, Optional, Union
from pathlib import Path
import numpy as np

logger = logging.getLogger(__name__)


class OCREngine:
    """
    Optical Character Recognition engine.
    
    Usage:
        ocr = OCREngine(method='easyocr')  # or 'tesseract', 'google'
        
        # Extract text from image
        text = await ocr.extract_text("document.jpg")
        
        # Extract with layout preservation
        result = await ocr.extract_with_layout("invoice.pdf")
        
        # Detect language automatically
        text, lang = await ocr.extract_auto_lang("sign.png")
    """
    
    def __init__(
        self,
        method: str = 'easyocr',
        languages: List[str] = None,
        api_key: Optional[str] = None
    ):
        """
        Initialize OCR engine.
        
        Args:
            method: OCR method ('tesseract', 'easyocr', 'google', 'aws')
            languages: List of language codes (e.g., ['en', 'fr'])
            api_key: API key for cloud services
        """
        self.method = method
        self.languages = languages or ['en']
        self.api_key = api_key
        self.available = False
        
        if method in ['tesseract', 'easyocr']:
            self._setup_local()
        elif method in ['google', 'aws']:
            self.available = True  # Cloud mode always available
    
    def _setup_local(self):
        """Setup local OCR engine"""
        if self.method == 'tesseract':
            try:
                import pytesseract
                from PIL import Image
                self.pytesseract = pytesseract
                self.Image = Image
                self.available = True
                logger.info("Tesseract OCR initialized")
            except ImportError:
                logger.warning(
                    "pytesseract not installed. Install with: pip install pytesseract\n"
                    "Also need Tesseract OCR engine: https://github.com/tesseract-ocr/tesseract"
                )
        
        elif self.method == 'easyocr':
            try:
                import easyocr
                self.reader = easyocr.Reader(self.languages, gpu=False)
                self.available = True
                logger.info(f"EasyOCR initialized for languages: {self.languages}")
            except ImportError:
                logger.warning(
                    "easyocr not installed. Install with: pip install easyocr"
                )
    
    async def extract_text(
        self,
        image_source: Union[str, Path, np.ndarray],
        confidence_threshold: float = 0.5
    ) -> str:
        """
        Extract text from image.
        
        Args:
            image_source: File path, URL, or numpy array
            confidence_threshold: Minimum confidence (0-1)
            
        Returns:
            Extracted text string
        """
        if not self.available:
            raise RuntimeError(f"OCR engine '{self.method}' not available")
        
        # Load image
        image_data = await self._load_image(image_source)
        
        # Extract based on method
        if self.method == 'tesseract':
            return self._extract_tesseract(image_data, confidence_threshold)
        elif self.method == 'easyocr':
            return self._extract_easyocr(image_data, confidence_threshold)
        elif self.method == 'google':
            return await self._extract_google(image_data, confidence_threshold)
        elif self.method == 'aws':
            return await self._extract_aws(image_data, confidence_threshold)
        
        raise ValueError(f"Unsupported OCR method: {self.method}")
    
    async def extract_with_layout(
        self,
        image_source: Union[str, Path, np.ndarray]
    ) -> Dict:
        """
        Extract text with layout information (position, blocks).
        
        Returns:
            Dictionary with text blocks and positions
        """
        if not self.available:
            raise RuntimeError(f"OCR engine '{self.method}' not available")
        
        image_data = await self._load_image(image_source)
        
        if self.method == 'easyocr':
            return self._extract_layout_easyocr(image_data)
        elif self.method == 'google':
            return await self._extract_layout_google(image_data)
        
        # Fallback: simple extraction
        text = await self.extract_text(image_data)
        return {
            'text': text,
            'blocks': [{'text': text, 'confidence': 1.0}],
            'layout': 'simple'
        }
    
    async def extract_auto_lang(
        self,
        image_source: Union[str, Path, np.ndarray]
    ) -> tuple:
        """
        Extract text with automatic language detection.
        
        Returns:
            Tuple of (text, detected_language)
        """
        if self.method == 'easyocr':
            # EasyOCR supports multi-language detection
            image_data = await self._load_image(image_source)
            results = self.reader.readtext(np.array(image_data))
            
            texts = []
            langs = set()
            
            for (bbox, text, confidence) in results:
                if confidence > 0.5:
                    texts.append(text)
                    # EasyOCR doesn't provide per-word language
                    # but we can use overall detection
            
            full_text = ' '.join(texts)
            detected_lang = self._detect_language_simple(full_text)
            
            return full_text, detected_lang
        
        else:
            # Fallback: try multiple languages
            text = await self.extract_text(image_source)
            lang = self._detect_language_simple(text)
            return text, lang
    
    async def _load_image(self, source: Union[str, Path, np.ndarray]):
        """Load image from various sources"""
        if isinstance(source, np.ndarray):
            return source
        
        if isinstance(source, (str, Path)):
            source = Path(source)
            
            # Check if URL
            if str(source).startswith('http'):
                import httpx
                async with httpx.AsyncClient() as client:
                    response = await client.get(str(source))
                    response.raise_for_status()
                    
                    from PIL import Image
                    from io import BytesIO
                    img = Image.open(BytesIO(response.content))
                    return np.array(img)
            
            # Local file
            from PIL import Image
            img = Image.open(source)
            return np.array(img)
        
        raise ValueError(f"Unsupported image source type: {type(source)}")
    
    def _extract_tesseract(
        self,
        image_data: np.ndarray,
        confidence_threshold: float
    ) -> str:
        """Extract using Tesseract"""
        from PIL import Image
        
        img = Image.fromarray(image_data)
        
        # Get detailed output with confidence
        data = self.pytesseract.image_to_data(img, output_type=self.pytesseract.Output.DICT)
        
        texts = []
        for i, conf in enumerate(data['conf']):
            if conf > confidence_threshold * 100:  # Tesseract uses 0-100
                text = data['text'][i].strip()
                if text:
                    texts.append(text)
        
        return ' '.join(texts)
    
    def _extract_easyocr(
        self,
        image_data: np.ndarray,
        confidence_threshold: float
    ) -> str:
        """Extract using EasyOCR"""
        results = self.reader.readtext(image_data)
        
        texts = []
        for (bbox, text, confidence) in results:
            if confidence >= confidence_threshold:
                texts.append(text)
        
        return ' '.join(texts)
    
    async def _extract_google(
        self,
        image_data: np.ndarray,
        confidence_threshold: float
    ) -> str:
        """Extract using Google Cloud Vision API"""
        try:
            from google.cloud import vision
        except ImportError:
            raise ImportError(
                "Install Google Cloud Vision: pip install google-cloud-vision"
            )
        
        # Convert to bytes
        from PIL import Image
        img = Image.fromarray(image_data)
        import io
        buffer = io.BytesIO()
        img.save(buffer, format='PNG')
        image_bytes = buffer.getvalue()
        
        # Setup client
        client = vision.ImageAnnotatorClient(
            credentials=self.api_key if self.api_key else None
        )
        
        image = vision.Image(content=image_bytes)
        response = client.text_detection(image=image)
        
        texts = response.text_annotations
        
        if texts:
            return texts[0].description
        
        return ""
    
    async def _extract_aws(
        self,
        image_data: np.ndarray,
        confidence_threshold: float
    ) -> str:
        """Extract using AWS Textract"""
        try:
            import boto3
        except ImportError:
            raise ImportError("Install AWS SDK: pip install boto3")
        
        # Convert to bytes
        from PIL import Image
        img = Image.fromarray(image_data)
        import io
        buffer = io.BytesIO()
        img.save(buffer, format='PNG')
        image_bytes = buffer.getvalue()
        
        # Setup client
        client = boto3.client(
            'textract',
            aws_access_key_id=self.api_key.split(':')[0] if self.api_key else None,
            aws_secret_access_key=self.api_key.split(':')[1] if self.api_key else None
        )
        
        response = client.detect_document_text(Document={'Bytes': image_bytes})
        
        texts = []
        for item in response['Blocks']:
            if item['BlockType'] == 'LINE':
                texts.append(item['Text'])
        
        return ' '.join(texts)
    
    def _extract_layout_easyocr(self, image_data: np.ndarray) -> Dict:
        """Extract with layout info using EasyOCR"""
        results = self.reader.readtext(image_data)
        
        blocks = []
        for (bbox, text, confidence) in results:
            blocks.append({
                'text': text,
                'confidence': confidence,
                'bbox': bbox,  # [[x1,y1], [x2,y2], [x3,y3], [x4,y4]]
            })
        
        full_text = ' '.join([b['text'] for b in blocks])
        
        return {
            'text': full_text,
            'blocks': blocks,
            'layout': 'detailed'
        }
    
    async def _extract_layout_google(self, image_data: np.ndarray) -> Dict:
        """Extract with layout info using Google Vision"""
        try:
            from google.cloud import vision
        except ImportError:
            raise ImportError("Install Google Cloud Vision: pip install google-cloud-vision")
        
        from PIL import Image
        img = Image.fromarray(image_data)
        import io
        buffer = io.BytesIO()
        img.save(buffer, format='PNG')
        image_bytes = buffer.getvalue()
        
        client = vision.ImageAnnotatorClient(
            credentials=self.api_key if self.api_key else None
        )
        
        image = vision.Image(content=image_bytes)
        response = client.document_text_detection(image=image)
        
        blocks = []
        for page in response.full_text_annotation.pages:
            for block in page.blocks:
                block_text = ''.join(
                    word.text for paragraph in block.paragraphs
                    for word in paragraph.words
                )
                
                vertices = [(v.x, v.y) for v in block.bounding_box.vertices]
                
                blocks.append({
                    'text': block_text,
                    'confidence': block.confidence,
                    'bbox': vertices
                })
        
        full_text = response.full_text_annotation.text
        
        return {
            'text': full_text,
            'blocks': blocks,
            'layout': 'document'
        }
    
    def _detect_language_simple(self, text: str) -> str:
        """Simple language detection based on character patterns"""
        # This is a simplified version - use langdetect library for better results
        try:
            from langdetect import detect
            return detect(text)
        except ImportError:
            # Fallback heuristic
            if any(ord(c) > 127 for c in text):
                return 'unknown'
            return 'en'
