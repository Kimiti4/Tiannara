"""
Vision-NLP Integration - Multimodal Reasoning Bridge

Connects Vision domain with NLP domain for:
- Image caption generation using NLP
- Visual question answering (VQA)
- Cross-modal reasoning (image + text context)
- Semantic search across images and documents
- Multimodal summarization
- Context-aware image analysis

This enables Tiannara to reason about images using language understanding.
"""

import logging
from typing import Dict, List, Optional, Any, Union
from dataclasses import dataclass, field
import os

logger = logging.getLogger(__name__)


@dataclass
class MultimodalResult:
    """Result from multimodal reasoning"""
    query: str
    image_source: Optional[str] = None
    text_context: Optional[str] = None
    
    # Results
    answer: str = ""
    confidence: float = 0.0
    reasoning_steps: List[str] = field(default_factory=list)
    
    # Supporting evidence
    visual_evidence: List[str] = field(default_factory=list)
    textual_evidence: List[str] = field(default_factory=list)
    
    metadata: Dict[str, Any] = field(default_factory=dict)


class VisionNLPPipeline:
    """
    Pipeline connecting Vision and NLP domains for multimodal reasoning.
    
    Usage:
        pipeline = VisionNLPPipeline()
        
        # Visual Question Answering
        result = await pipeline.visual_qa(
            image="photo.jpg",
            question="What is happening in this scene?"
        )
        
        # Image-text matching
        match_score = await pipeline.image_text_match(
            image="diagram.png",
            text="A flowchart showing decision process"
        )
        
        # Generate caption
        caption = await pipeline.generate_caption("landscape.jpg")
        
        # Multimodal search
        results = await pipeline.multimodal_search(
            query="red sports cars",
            images=["car1.jpg", "car2.jpg"],
            texts=["doc1.txt", "doc2.txt"]
        )
    """
    
    def __init__(self):
        """Initialize Vision-NLP pipeline"""
        self.vision_engine = None
        self.nlp_engine = None
        self.available = False
        
        self._initialize_domains()
    
    def _initialize_domains(self):
        """Initialize vision and NLP engines"""
        try:
            # Import vision components
            from tiannara_core.domains.vision.vision_engine import VisionEngine
            from tiannara_core.domains.vision.gpt4v_integration import GPT4VAnalyzer
            from tiannara_core.domains.vision.ocr_engine import OCREngine
            
            self.vision_engine = VisionEngine()
            
            # Initialize GPT-4V with API key from environment
            openai_api_key = os.getenv('OPENAI_API_KEY')
            self.gpt4v = GPT4VAnalyzer(api_key=openai_api_key) if openai_api_key else None
            
            self.ocr = OCREngine(method='easyocr')
            
            logger.info("Vision components initialized")
            
            # Import NLP components
            from tiannara_core.domains.nlp.nlp_engine import NLPEngine
            
            self.nlp_engine = NLPEngine()
            
            logger.info("NLP components initialized")
            
            self.available = True
        
        except ImportError as e:
            logger.warning(f"Could not initialize all components: {e}")
            logger.warning("Some multimodal features may be limited")
    
    async def visual_question_answering(
        self,
        image_source: Union[str, bytes],
        question: str,
        context: Optional[str] = None
    ) -> MultimodalResult:
        """
        Answer questions about images using combined vision+NLP reasoning.
        
        Args:
            image_source: Image file path or bytes
            question: Question to answer about the image
            context: Additional text context
            
        Returns:
            MultimodalResult with answer and reasoning
        """
        if not self.available:
            return self._mock_vqa_result(question)
        
        result = MultimodalResult(
            query=question,
            image_source=str(image_source)
        )
        
        try:
            # Step 1: Analyze image with GPT-4V (if available) or vision engine
            if self.gpt4v and self.gpt4v.available:
                image_description = await self.gpt4v.describe(image_source)
                answer = await self.gpt4v.ask(image_source, question)
                
                result.visual_evidence.append(image_description)
                result.answer = answer
                result.confidence = 0.85
            
            else:
                # Fallback: use basic vision engine
                vision_result = await self.vision_engine.analyze_image(image_source)
                image_description = vision_result.get('description', '')
                
                result.visual_evidence.append(image_description)
                
                # Step 2: Use NLP to generate answer based on description
                if self.nlp_engine:
                    prompt = f"""Based on this image description, answer the question.

Image: {image_description}
Question: {question}

Answer:"""
                    
                    answer = await self.nlp_engine.generate_text(prompt, max_length=200)
                    result.answer = answer
                    result.confidence = 0.70
            
            # Step 3: Add contextual reasoning if provided
            if context:
                result.textual_evidence.append(context)
                
                if self.nlp_engine:
                    # Combine visual and textual evidence
                    synthesis_prompt = f"""Synthesize information from both visual and textual sources.

Visual Evidence: {result.visual_evidence[0]}
Textual Context: {context}
Question: {question}

Comprehensive Answer:"""
                    
                    refined_answer = await self.nlp_engine.generate_text(
                        synthesis_prompt,
                        max_length=300
                    )
                    result.answer = refined_answer
                    result.confidence = min(result.confidence + 0.1, 1.0)
            
            # Step 4: Extract reasoning steps
            result.reasoning_steps = [
                f"Analyzed image: {image_description[:100]}...",
                f"Processed question: {question}",
                f"Generated answer using {'GPT-4V' if self.gpt4v else 'vision+NLP'}",
            ]
            
            if context:
                result.reasoning_steps.append(
                    f"Incorporated textual context ({len(context)} chars)"
                )
            
            result.metadata['method'] = 'visual_qa'
            result.metadata['has_context'] = context is not None
            
            return result
        
        except Exception as e:
            logger.error(f"Error in VQA: {e}")
            result.answer = f"Error processing: {str(e)}"
            result.confidence = 0.0
            return result
    
    async def generate_caption(
        self,
        image_source: Union[str, bytes],
        style: str = "descriptive"
    ) -> str:
        """
        Generate natural language caption for an image.
        
        Args:
            image_source: Image file path or bytes
            style: Caption style ("descriptive", "concise", "creative")
            
        Returns:
            Generated caption string
        """
        if not self.available:
            return "[Caption generation unavailable]"
        
        try:
            # Get image description from vision
            if self.gpt4v and self.gpt4v.available:
                caption = await self.gpt4v.describe(image_source, detail_level="medium")
            
            else:
                vision_result = await self.vision_engine.analyze_image(image_source)
                base_description = vision_result.get('description', '')
                
                # Enhance with NLP
                if self.nlp_engine:
                    style_prompts = {
                        'descriptive': f"Write a detailed, descriptive caption: {base_description}",
                        'concise': f"Write a brief, concise caption (max 15 words): {base_description}",
                        'creative': f"Write a creative, engaging caption: {base_description}"
                    }
                    
                    prompt = style_prompts.get(style, style_prompts['descriptive'])
                    caption = await self.nlp_engine.generate_text(prompt, max_length=150)
                else:
                    caption = base_description
            
            return caption
        
        except Exception as e:
            logger.error(f"Error generating caption: {e}")
            return "[Caption generation failed]"
    
    async def image_text_match(
        self,
        image_source: Union[str, bytes],
        text: str
    ) -> Dict[str, Any]:
        """
        Calculate semantic similarity between image and text.
        
        Args:
            image_source: Image file path or bytes
            text: Text to compare with image
            
        Returns:
            Dictionary with match score and explanation
        """
        if not self.available:
            return {'score': 0.5, 'match': 'unknown'}
        
        try:
            # Method 1: Use CLIP if available (best for image-text matching)
            if hasattr(self.vision_engine, 'clip_analyzer'):
                clip_result = await self.vision_engine.clip_analyzer.match_image_to_text(
                    image_source, [text]
                )
                
                if clip_result:
                    score = clip_result.get('scores', [0.5])[0]
                    return {
                        'score': score,
                        'match': 'high' if score > 0.7 else 'medium' if score > 0.4 else 'low',
                        'method': 'CLIP',
                        'confidence': 0.90
                    }
            
            # Method 2: Describe image and compare with NLP
            if self.gpt4v and self.gpt4v.available:
                image_desc = await self.gpt4v.describe(image_source, detail_level="low")
            else:
                vision_result = await self.vision_engine.analyze_image(image_source)
                image_desc = vision_result.get('description', '')
            
            # Use NLP for semantic similarity
            if self.nlp_engine:
                similarity = await self.nlp_engine.semantic_similarity(
                    image_desc, text
                )
                
                return {
                    'score': similarity,
                    'match': 'high' if similarity > 0.7 else 'medium' if similarity > 0.4 else 'low',
                    'method': 'NLP+Vision',
                    'image_description': image_desc[:200],
                    'confidence': 0.75
                }
            
            return {'score': 0.5, 'match': 'unknown', 'method': 'fallback'}
        
        except Exception as e:
            logger.error(f"Error in image-text matching: {e}")
            return {'score': 0.0, 'match': 'error', 'error': str(e)}
    
    async def multimodal_summarization(
        self,
        images: List[Union[str, bytes]],
        texts: List[str],
        summary_length: str = "medium"
    ) -> str:
        """
        Generate summary combining multiple images and texts.
        
        Args:
            images: List of image sources
            texts: List of text documents
            summary_length: "short", "medium", or "long"
            
        Returns:
            Unified summary
        """
        if not self.available:
            return "[Multimodal summarization unavailable]"
        
        try:
            # Step 1: Process all images
            image_descriptions = []
            for img in images:
                if self.gpt4v and self.gpt4v.available:
                    desc = await self.gpt4v.describe(img, detail_level="low")
                else:
                    vision_result = await self.vision_engine.analyze_image(img)
                    desc = vision_result.get('description', '')
                image_descriptions.append(desc)
            
            # Step 2: Combine with texts
            all_content = "\n\n".join([
                "IMAGES:",
                *image_descriptions,
                "\nTEXTS:",
                *texts
            ])
            
            # Step 3: Generate summary using NLP
            length_instructions = {
                'short': "Summarize in 2-3 sentences.",
                'medium': "Summarize in 1 paragraph (5-7 sentences).",
                'long': "Provide a detailed summary (2-3 paragraphs)."
            }
            
            instruction = length_instructions.get(summary_length, length_instructions['medium'])
            
            summary_prompt = f"""{instruction}

Content to summarize:
{all_content[:3000]}  # Limit to avoid token overflow

Summary:"""
            
            if self.nlp_engine:
                summary = await self.nlp_engine.generate_text(
                    summary_prompt,
                    max_length=500 if summary_length == 'long' else 200
                )
            else:
                summary = f"[Summary of {len(images)} images and {len(texts)} texts]"
            
            return summary
        
        except Exception as e:
            logger.error(f"Error in multimodal summarization: {e}")
            return f"[Summarization failed: {str(e)}]"
    
    async def multimodal_search(
        self,
        query: str,
        images: Optional[List[str]] = None,
        texts: Optional[List[str]] = None
    ) -> List[Dict[str, Any]]:
        """
        Search across both images and texts using natural language query.
        
        Args:
            query: Search query
            images: List of image paths to search
            texts: List of text documents to search
            
        Returns:
            Ranked list of relevant results
        """
        if not self.available:
            return []
        
        results = []
        
        try:
            # Search in texts using NLP
            if texts and self.nlp_engine:
                for i, text in enumerate(texts):
                    relevance = await self.nlp_engine.semantic_similarity(
                        query, text[:1000]  # First 1000 chars
                    )
                    
                    results.append({
                        'type': 'text',
                        'source': f'text_{i}',
                        'relevance_score': relevance,
                        'preview': text[:200] + '...' if len(text) > 200 else text,
                        'full_text': text
                    })
            
            # Search in images using vision+NLP
            if images:
                for i, img_path in enumerate(images):
                    # Describe image
                    if self.gpt4v and self.gpt4v.available:
                        desc = await self.gpt4v.describe(img_path, detail_level="low")
                    else:
                        vision_result = await self.vision_engine.analyze_image(img_path)
                        desc = vision_result.get('description', '')
                    
                    # Calculate relevance
                    if self.nlp_engine:
                        relevance = await self.nlp_engine.semantic_similarity(
                            query, desc
                        )
                    else:
                        relevance = 0.5
                    
                    results.append({
                        'type': 'image',
                        'source': img_path,
                        'relevance_score': relevance,
                        'description': desc,
                        'image_path': img_path
                    })
            
            # Sort by relevance
            results.sort(key=lambda x: x['relevance_score'], reverse=True)
            
            return results
        
        except Exception as e:
            logger.error(f"Error in multimodal search: {e}")
            return []
    
    def _mock_vqa_result(self, question: str) -> MultimodalResult:
        """Mock VQA result when systems unavailable"""
        return MultimodalResult(
            query=question,
            answer="[Visual QA unavailable - requires vision+NLP integration]",
            confidence=0.0,
            reasoning_steps=["System initialization pending"]
        )
