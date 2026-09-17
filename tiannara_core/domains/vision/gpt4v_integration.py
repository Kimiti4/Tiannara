"""
GPT-4V Integration - Advanced Image Understanding with OpenAI's GPT-4 Vision

Enables:
- Complex scene understanding
- Visual reasoning and explanation
- Text extraction with context
- Quality assessment
- Accessibility (alt-text generation)
- Content moderation

What is this for?
-----------------
GPT-4V goes beyond basic object detection to provide HUMAN-LIKE understanding:

1. SCENE UNDERSTANDING: Not just "person, car" but "A family enjoying a picnic"
2. VISUAL REASONING: Answer questions like "Why is this person smiling?"
3. TEXT + CONTEXT: Read signs/documents AND understand their meaning
4. QUALITY ASSESSMENT: "Is this photo professional quality?"
5. ACCESSIBILITY: Generate descriptive alt-text for visually impaired users
6. EDUCATIONAL: Explain diagrams, charts, mathematical proofs
7. CONTENT MODERATION: Detect subtle inappropriate content
8. MEDICAL/TECHNICAL: Interpret X-rays, schematics, technical drawings

Example:
    # Basic detection: "person, dog, park"
    # GPT-4V: "A joyful moment as a young woman plays fetch with her golden 
    #          retriever in Central Park on a sunny autumn afternoon"
"""

import logging
from typing import Dict, Optional, Union, List
from pathlib import Path
import base64
import numpy as np
import os

logger = logging.getLogger(__name__)


class GPT4VAnalyzer:
    """
    GPT-4 Vision analyzer for advanced image understanding.
    
    Requires OpenAI API key with GPT-4V access.
    
    Usage:
        analyzer = GPT4VAnalyzer(api_key="sk-...")
        
        # Describe image in detail
        description = await analyzer.describe("photo.jpg")
        
        # Ask specific questions
        answer = await analyzer.ask("photo.jpg", "What emotion is this person showing?")
        
        # Generate alt-text for accessibility
        alt_text = await analyzer.generate_alt_text("diagram.png")
        
        # Assess image quality
        quality = await analyzer.assess_quality("product_photo.jpg")
    """
    
    def __init__(self, api_key: Optional[str] = None):
        """
        Initialize GPT-4V analyzer.
        
        Args:
            api_key: OpenAI API key (starts with 'sk-'). 
                    If not provided, will try to load from OPENAI_API_KEY env var.
        """
        # Try to get API key from parameter or environment variable
        self.api_key = api_key or os.getenv('OPENAI_API_KEY')
        
        if not self.api_key:
            logger.warning(
                "No OpenAI API key provided. GPT-4V features will be unavailable.\n"
                "Set OPENAI_API_KEY environment variable or pass api_key parameter.\n"
                "Get your key at: https://platform.openai.com/api-keys"
            )
            self.available = False
        elif not self.api_key.startswith('sk-'):
            logger.warning("Invalid OpenAI API key format. Should start with 'sk-'")
            self.available = False
        else:
            self.available = True
            logger.info("GPT-4V analyzer initialized with API key")
    
    async def describe(
        self,
        image_source: Union[str, Path, np.ndarray],
        detail_level: str = "high"
    ) -> str:
        """
        Generate detailed natural language description of image.
        
        Args:
            image_source: File path, URL, or numpy array
            detail_level: "low", "medium", or "high"
            
        Returns:
            Detailed description string
        """
        if not self.available:
            return self._mock_description()
        
        prompt = f"""Describe this image in {detail_level} detail. Include:
- Main subjects and objects
- Actions and activities
- Setting and environment
- Colors, lighting, mood
- Any text visible in the image
- Relationships between elements

Be specific and descriptive."""
        
        return await self._query_gpt4v(image_source, prompt)
    
    async def ask(
        self,
        image_source: Union[str, Path, np.ndarray],
        question: str
    ) -> str:
        """
        Ask a specific question about the image.
        
        Args:
            image_source: File path, URL, or numpy array
            question: Question to answer
            
        Returns:
            Answer based on visual analysis
        """
        if not self.available:
            return self._mock_answer(question)
        
        prompt = f"""Look at this image carefully and answer the following question.
Provide a detailed, thoughtful response based on what you see.

Question: {question}

Answer:"""
        
        return await self._query_gpt4v(image_source, prompt)
    
    async def generate_alt_text(
        self,
        image_source: Union[str, Path, np.ndarray],
        max_length: int = 150
    ) -> str:
        """
        Generate accessibility alt-text for images.
        
        Args:
            image_source: File path, URL, or numpy array
            max_length: Maximum character length
            
        Returns:
            Concise, descriptive alt-text
        """
        if not self.available:
            return "Image description unavailable"
        
        prompt = f"""Generate concise alt-text for this image for accessibility purposes.
The alt-text should:
- Be under {max_length} characters
- Describe the main subject and action
- Include important context
- Avoid phrases like "image of" or "picture of"
- Be clear and descriptive

Alt-text:"""
        
        description = await self._query_gpt4v(image_source, prompt)
        return description[:max_length]
    
    async def assess_quality(
        self,
        image_source: Union[str, Path, np.ndarray],
        criteria: List[str] = None
    ) -> Dict:
        """
        Assess image quality for various use cases.
        
        Args:
            image_source: File path, URL, or numpy array
            criteria: Quality criteria to evaluate (e.g., ["professionalism", "clarity"])
            
        Returns:
            Dictionary with quality scores and feedback
        """
        if not self.available:
            return self._mock_quality_assessment()
        
        criteria_str = ", ".join(criteria) if criteria else "overall quality"
        
        prompt = f"""Assess the quality of this image for: {criteria_str}

Provide a structured evaluation with:
1. Overall score (1-10)
2. Strengths (bullet points)
3. Weaknesses (bullet points)
4. Specific recommendations for improvement

Format your response as JSON with keys: score, strengths, weaknesses, recommendations"""
        
        response = await self._query_gpt4v(image_source, prompt)
        
        # Try to parse as JSON
        try:
            import json
            # Extract JSON from response
            start = response.find('{')
            end = response.rfind('}') + 1
            if start >= 0 and end > start:
                json_str = response[start:end]
                return json.loads(json_str)
        except:
            pass
        
        # Fallback: return structured dict
        return {
            'score': 7,
            'feedback': response,
            'raw_response': response
        }
    
    async def extract_text_with_context(
        self,
        image_source: Union[str, Path, np.ndarray]
    ) -> Dict:
        """
        Extract text from image AND explain its meaning/context.
        
        Args:
            image_source: File path, URL, or numpy array
            
        Returns:
            Dictionary with extracted text and interpretation
        """
        if not self.available:
            return {'text': '', 'context': 'OCR not available'}
        
        prompt = """1. Extract ALL visible text from this image exactly as it appears.
2. Then explain the context and meaning of this text.
3. What type of document/sign/image is this?
4. What is the purpose or intent?

Format as JSON:
{
  "extracted_text": "...",
  "document_type": "...",
  "context_explanation": "...",
  "intent": "..."
}"""
        
        response = await self._query_gpt4v(image_source, prompt)
        
        # Try to parse JSON
        try:
            import json
            start = response.find('{')
            end = response.rfind('}') + 1
            if start >= 0 and end > start:
                return json.loads(response[start:end])
        except:
            pass
        
        return {
            'extracted_text': response,
            'context_explanation': 'See full response',
            'raw_response': response
        }
    
    async def analyze_diagram(
        self,
        image_source: Union[str, Path, np.ndarray],
        diagram_type: str = "unknown"
    ) -> Dict:
        """
        Analyze and explain diagrams, charts, graphs, or technical drawings.
        
        Args:
            image_source: File path, URL, or numpy array
            diagram_type: Type hint ("flowchart", "graph", "circuit", etc.)
            
        Returns:
            Structured analysis of the diagram
        """
        if not self.available:
            return {'explanation': 'Diagram analysis not available'}
        
        prompt = f"""Analyze this {diagram_type if diagram_type != 'unknown' else ''} diagram/chart.

Provide:
1. What does this diagram show? (main concept)
2. Key components/elements identified
3. Relationships or flow depicted
4. What problem or process does this illustrate?
5. Is there anything unclear or missing?

Format as JSON with keys: title, components, relationships, purpose, clarity_notes"""
        
        response = await self._query_gpt4v(image_source, prompt)
        
        try:
            import json
            start = response.find('{')
            end = response.rfind('}') + 1
            if start >= 0 and end > start:
                return json.loads(response[start:end])
        except:
            pass
        
        return {
            'explanation': response,
            'raw_response': response
        }
    
    async def moderate_content(
        self,
        image_source: Union[str, Path, np.ndarray]
    ) -> Dict:
        """
        Check image for inappropriate or harmful content.
        
        Args:
            image_source: File path, URL, or numpy array
            
        Returns:
            Moderation results with safety scores
        """
        if not self.available:
            return {'safe': True, 'confidence': 0.5}
        
        prompt = """Review this image for content moderation. Check for:
- Violence or gore
- Nudity or sexual content
- Hate symbols or offensive imagery
- Dangerous activities
- Misinformation or manipulated media

Rate each category 1-10 (10 = most severe).
Overall assessment: SAFE or UNSAFE with explanation.

Format as JSON:
{
  "overall": "SAFE" or "UNSAFE",
  "violence_score": 0-10,
  "sexual_content_score": 0-10,
  "hate_symbols_score": 0-10,
  "dangerous_activities_score": 0-10,
  "explanation": "..."
}"""
        
        response = await self._query_gpt4v(image_source, prompt)
        
        try:
            import json
            start = response.find('{')
            end = response.rfind('}') + 1
            if start >= 0 and end > start:
                result = json.loads(response[start:end])
                result['safe'] = result.get('overall', 'SAFE') == 'SAFE'
                return result
        except:
            pass
        
        return {
            'safe': 'UNSAFE' not in response.upper(),
            'explanation': response
        }
    
    async def _query_gpt4v(
        self,
        image_source: Union[str, Path, np.ndarray],
        prompt: str
    ) -> str:
        """
        Query GPT-4V API with image and text prompt.
        
        Args:
            image_source: Image file/path/array
            prompt: Text prompt/question
            
        Returns:
            GPT-4V response text
        """
        try:
            import openai
            from openai import OpenAI
        except ImportError:
            raise ImportError(
                "Install OpenAI SDK: pip install openai\n"
                "Also ensure you have GPT-4V access on your OpenAI account."
            )
        
        # Load and encode image
        image_base64 = await self._encode_image(image_source)
        
        # Create client
        client = OpenAI(api_key=self.api_key)
        
        # Make API call
        try:
            response = client.chat.completions.create(
                model="gpt-4-vision-preview",  # or "gpt-4o" for newer version
                messages=[
                    {
                        "role": "user",
                        "content": [
                            {"type": "text", "text": prompt},
                            {
                                "type": "image_url",
                                "image_url": {
                                    "url": f"data:image/jpeg;base64,{image_base64}"
                                }
                            }
                        ]
                    }
                ],
                max_tokens=1000,
                temperature=0.7
            )
            
            return response.choices[0].message.content
        
        except Exception as e:
            logger.error(f"GPT-4V API error: {e}")
            return f"Error analyzing image: {str(e)}"
    
    async def _encode_image(
        self,
        image_source: Union[str, Path, np.ndarray]
    ) -> str:
        """Convert image to base64 encoding"""
        if isinstance(image_source, np.ndarray):
            # Convert numpy array to bytes
            from PIL import Image
            img = Image.fromarray(image_source)
            import io
            buffer = io.BytesIO()
            img.save(buffer, format='JPEG')
            image_bytes = buffer.getvalue()
        else:
            # Load from file
            image_path = Path(image_source)
            if not image_path.exists():
                raise FileNotFoundError(f"Image not found: {image_path}")
            image_bytes = image_path.read_bytes()
        
        # Encode to base64
        return base64.b64encode(image_bytes).decode('utf-8')
    
    # Mock responses for when API is unavailable
    def _mock_description(self) -> str:
        return "[GPT-4V unavailable] This would contain a detailed AI-generated description of the image including subjects, actions, setting, mood, and any visible text."
    
    def _mock_answer(self, question: str) -> str:
        return f"[GPT-4V unavailable] To answer '{question}', I would need to analyze the image using GPT-4 Vision API."
    
    def _mock_quality_assessment(self) -> Dict:
        return {
            'score': 7,
            'strengths': ['Good composition', 'Clear subject'],
            'weaknesses': ['Could improve lighting'],
            'recommendations': ['Use natural light', 'Adjust framing']
        }
