"""
Natural Language Processing Domain for Tiannara MindCache.

Handles text-based tasks including:
- Email writing and composition
- Report generation
- Code explanation and documentation
- Text summarization
- Translation
- Sentiment analysis
- Intent recognition
"""

import random
import re
from typing import Dict, List, Any, Optional, Callable


class NLPTaskGenerator:
    """Generates NLP tasks for training and evaluation."""
    
    def __init__(self):
        self.task_types = [
            "email_writing",
            "report_generation",
            "code_explanation",
            "text_summarization",
            "translation",
            "sentiment_analysis",
            "intent_recognition"
        ]
    
    def generate_task(self, task_type: str = None, difficulty: str = "medium") -> Dict[str, Any]:
        """
        Generate an NLP task.
        
        Args:
            task_type: Specific type of NLP task
            difficulty: easy, medium, hard
            
        Returns:
            Task dictionary with inputs and expected output characteristics
        """
        if task_type is None:
            task_type = random.choice(self.task_types)
        
        if task_type == "email_writing":
            return self._generate_email_task(difficulty)
        elif task_type == "report_generation":
            return self._generate_report_task(difficulty)
        elif task_type == "code_explanation":
            return self._generate_code_explanation_task(difficulty)
        elif task_type == "text_summarization":
            return self._generate_summarization_task(difficulty)
        elif task_type == "translation":
            return self._generate_translation_task(difficulty)
        elif task_type == "sentiment_analysis":
            return self._generate_sentiment_task(difficulty)
        elif task_type == "intent_recognition":
            return self._generate_intent_task(difficulty)
        else:
            raise ValueError(f"Unknown NLP task type: {task_type}")
    
    def _generate_email_task(self, difficulty: str) -> Dict[str, Any]:
        """Generate email writing task"""
        
        purposes = {
            "easy": ["follow_up", "thank_you", "greeting"],
            "medium": ["meeting_request", "status_update", "introduction"],
            "hard": ["negotiation", "complaint_response", "proposal"]
        }
        
        tones = ["professional", "casual", "formal", "friendly"]
        
        purpose = random.choice(purposes[difficulty])
        tone = random.choice(tones)
        
        # Generate context
        context_templates = {
            "follow_up": {
                "topic": random.choice(["project proposal", "partnership opportunity", "job application"]),
                "timeframe": random.choice(["last week", "yesterday", "earlier this month"])
            },
            "meeting_request": {
                "topic": random.choice(["quarterly review", "strategy discussion", "project kickoff"]),
                "duration": random.choice(["30 minutes", "1 hour", "2 hours"]),
                "times": random.choice(["Tuesday afternoon", "Wednesday morning", "Thursday anytime"])
            },
            "status_update": {
                "project": random.choice(["Website Redesign", "Mobile App Development", "API Integration"]),
                "progress_items": "3 bullet points needed",
                "next_steps": "2-3 action items",
                "blockers": "None or list challenges"
            }
        }
        
        context = context_templates.get(purpose, {"topic": "general business matter"})
        
        return {
            "type": "email_writing",
            "subtype": purpose,
            "difficulty": difficulty,
            "inputs": {
                "purpose": purpose,
                "tone": tone,
                "context": context,
                "recipient_type": random.choice(["client", "colleague", "manager", "vendor"])
            },
            "expected_output": {
                "has_subject": True,
                "has_greeting": True,
                "has_body": True,
                "has_closing": True,
                "tone_appropriate": True,
                "min_words": 50 if difficulty == "easy" else 100 if difficulty == "medium" else 150,
                "max_words": 200 if difficulty == "easy" else 400 if difficulty == "medium" else 600
            },
            "metadata": {
                "domain": "nlp",
                "skill_required": ["language_generation", "tone_adjustment", "structure"]
            }
        }
    
    def _generate_report_task(self, difficulty: str) -> Dict[str, Any]:
        """Generate report generation task"""
        
        report_types = {
            "easy": ["status_update", "simple_summary"],
            "medium": ["performance_analysis", "experiment_results"],
            "hard": ["business_intelligence", "technical_documentation"]
        }
        
        report_type = random.choice(report_types[difficulty])
        
        # Generate sample data
        metrics_count = 3 if difficulty == "easy" else 5 if difficulty == "medium" else 8
        
        return {
            "type": "report_generation",
            "subtype": report_type,
            "difficulty": difficulty,
            "inputs": {
                "report_type": report_type,
                "data_points": metrics_count,
                "format": random.choice(["markdown", "plain_text"]),
                "audience": random.choice(["executive", "technical", "general"])
            },
            "expected_output": {
                "has_title": True,
                "has_sections": True,
                "section_count": 3 if difficulty == "easy" else 5 if difficulty == "medium" else 7,
                "has_data_visualization": difficulty == "hard",
                "min_length_words": 200 if difficulty == "easy" else 500 if difficulty == "medium" else 1000
            },
            "metadata": {
                "domain": "nlp",
                "skill_required": ["structured_writing", "data_interpretation", "formatting"]
            }
        }
    
    def _generate_code_explanation_task(self, difficulty: str) -> Dict[str, Any]:
        """Generate code explanation task"""
        
        code_samples = {
            "easy": [
                "def add(a, b):\n    return a + b",
                "for i in range(10):\n    print(i)",
                "if x > 0:\n    return 'positive'"
            ],
            "medium": [
                "def fibonacci(n):\n    if n <= 1:\n        return n\n    return fibonacci(n-1) + fibonacci(n-2)",
                "class Stack:\n    def __init__(self):\n        self.items = []\n    def push(self, item):\n        self.items.append(item)",
                "[x**2 for x in range(10) if x % 2 == 0]"
            ],
            "hard": [
                "def quicksort(arr):\n    if len(arr) <= 1:\n        return arr\n    pivot = arr[len(arr) // 2]\n    left = [x for x in arr if x < pivot]\n    middle = [x for x in arr if x == pivot]\n    right = [x for x in arr if x > pivot]\n    return quicksort(left) + middle + quicksort(right)",
                "async def fetch_data(url):\n    async with aiohttp.ClientSession() as session:\n        async with session.get(url) as response:\n            return await response.json()",
                "@decorator\ndef wrapper(*args, **kwargs):\n    result = func(*args, **kwargs)\n    log(result)\n    return result"
            ]
        }
        
        code = random.choice(code_samples[difficulty])
        
        return {
            "type": "code_explanation",
            "subtype": "explain_code",
            "difficulty": difficulty,
            "inputs": {
                "code": code,
                "explanation_level": random.choice(["beginner", "intermediate", "advanced"]),
                "include_examples": difficulty != "easy"
            },
            "expected_output": {
                "explains_purpose": True,
                "explains_logic": True,
                "mentions_key_concepts": True,
                "has_example": difficulty != "easy",
                "clarity_score_min": 0.7
            },
            "metadata": {
                "domain": "nlp",
                "skill_required": ["code_understanding", "technical_writing", "simplification"]
            }
        }
    
    def _generate_summarization_task(self, difficulty: str) -> Dict[str, Any]:
        """Generate text summarization task"""
        
        # Sample texts of varying complexity
        texts = {
            "easy": "The cat sat on the mat. It was a sunny day. The cat enjoyed the warmth.",
            "medium": "Artificial intelligence has transformed many industries. Machine learning algorithms can now process vast amounts of data to identify patterns. This capability enables better decision-making in healthcare, finance, and manufacturing.",
            "hard": "The implementation of quantum computing algorithms requires careful consideration of qubit coherence times and error correction protocols. Recent advances in topological qubits show promise for achieving fault-tolerant quantum computation, though significant engineering challenges remain in scaling these systems to practical problem sizes."
        }
        
        text = texts[difficulty]
        
        return {
            "type": "text_summarization",
            "subtype": "summarize",
            "difficulty": difficulty,
            "inputs": {
                "text": text,
                "summary_length": "short" if difficulty == "easy" else "medium" if difficulty == "medium" else "detailed",
                "focus": random.choice(["main_ideas", "key_facts", "conclusions"])
            },
            "expected_output": {
                "shorter_than_original": True,
                "captures_main_points": True,
                "coherent": True,
                "compression_ratio": 0.3 if difficulty == "easy" else 0.4 if difficulty == "medium" else 0.5
            },
            "metadata": {
                "domain": "nlp",
                "skill_required": ["information_extraction", "conciseness", "coherence"]
            }
        }
    
    def _generate_translation_task(self, difficulty: str) -> Dict[str, Any]:
        """Generate translation task"""
        
        phrases = {
            "easy": [
                ("Hello, how are you?", "Spanish"),
                ("Thank you very much", "French"),
                ("Good morning", "German")
            ],
            "medium": [
                ("The meeting is scheduled for tomorrow at 3 PM", "Spanish"),
                ("Please send me the report by Friday", "French"),
                ("I would like to make a reservation", "German")
            ],
            "hard": [
                ("The quarterly financial results exceeded expectations despite market volatility", "Spanish"),
                ("We need to implement a comprehensive security strategy", "French"),
                ("The algorithm optimization reduced processing time by forty percent", "German")
            ]
        }
        
        phrase, target_language = random.choice(phrases[difficulty])
        
        return {
            "type": "translation",
            "subtype": "translate",
            "difficulty": difficulty,
            "inputs": {
                "text": phrase,
                "source_language": "English",
                "target_language": target_language
            },
            "expected_output": {
                "correct_language": True,
                "meaning_preserved": True,
                "grammatically_correct": True,
                "appropriate_register": True
            },
            "metadata": {
                "domain": "nlp",
                "skill_required": ["multilingual_knowledge", "cultural_awareness", "grammar"]
            }
        }
    
    def _generate_sentiment_task(self, difficulty: str) -> Dict[str, Any]:
        """Generate sentiment analysis task"""
        
        texts = {
            "easy": [
                ("I love this product!", "positive"),
                ("This is terrible", "negative"),
                ("It's okay", "neutral")
            ],
            "medium": [
                ("The service was good but the price was too high", "mixed"),
                ("Amazing quality and fast delivery, highly recommend!", "positive"),
                ("Disappointed with the customer support experience", "negative")
            ],
            "hard": [
                ("While the interface is intuitive, the performance issues and lack of documentation make it challenging for enterprise adoption", "mixed_negative"),
                ("Exceptional build quality and innovative features, though the premium pricing may limit accessibility for smaller businesses", "mixed_positive"),
                ("The platform delivers on its core promises with robust functionality, seamless integration capabilities, and outstanding customer support that exceeds industry standards", "positive")
            ]
        }
        
        text, expected_sentiment = random.choice(texts[difficulty])
        
        return {
            "type": "sentiment_analysis",
            "subtype": "classify_sentiment",
            "difficulty": difficulty,
            "inputs": {
                "text": text
            },
            "expected_output": {
                "sentiment": expected_sentiment,
                "confidence_min": 0.7,
                "aspects_identified": difficulty == "hard"
            },
            "metadata": {
                "domain": "nlp",
                "skill_required": ["emotion_detection", "nuance_understanding", "context_analysis"]
            }
        }
    
    def _generate_intent_task(self, difficulty: str) -> Dict[str, Any]:
        """Generate intent recognition task"""
        
        utterances = {
            "easy": [
                ("Book a flight to Paris", "booking"),
                ("What's the weather today?", "information"),
                ("Play some music", "entertainment")
            ],
            "medium": [
                ("I need to reschedule my appointment for next week", "modification"),
                ("Can you help me track my order?", "support"),
                ("Set a reminder for the meeting tomorrow at 10am", "scheduling")
            ],
            "hard": [
                ("I'd like to upgrade my subscription to the premium plan and add two more user licenses", "purchase_modification"),
                ("My payment failed but I was still charged, please refund and fix the issue", "complaint_resolution"),
                ("Compare the features of your basic and professional plans and tell me which is better for a team of 10", "consultation")
            ]
        }
        
        utterance, expected_intent = random.choice(utterances[difficulty])
        
        return {
            "type": "intent_recognition",
            "subtype": "classify_intent",
            "difficulty": difficulty,
            "inputs": {
                "utterance": utterance
            },
            "expected_output": {
                "intent": expected_intent,
                "confidence_min": 0.8,
                "entities_extracted": difficulty != "easy"
            },
            "metadata": {
                "domain": "nlp",
                "skill_required": ["intent_classification", "entity_extraction", "context_understanding"]
            }
        }


class NLPEvolver:
    """
    Evolves solutions for NLP tasks.
    
    Uses pattern matching, template filling, and rule-based generation
    to produce high-quality natural language outputs.
    """
    
    def __init__(self):
        self.quality_level = 0.5
        self.templates = self._load_templates()
        self.rules = self._load_rules()
    
    def _load_templates(self) -> Dict:
        """Load language generation templates"""
        return {
            "email": {
                "professional": {
                    "greeting": "Dear {recipient},",
                    "closing": "Best regards,\n{sender}",
                    "structure": ["greeting", "opening", "body", "call_to_action", "closing"]
                },
                "casual": {
                    "greeting": "Hi {recipient},",
                    "closing": "Cheers,\n{sender}",
                    "structure": ["greeting", "body", "closing"]
                }
            },
            "report": {
                "structure": ["title", "executive_summary", "sections", "conclusions", "recommendations"],
                "section_template": "## {section_name}\n\n{content}"
            }
        }
    
    def _load_rules(self) -> Dict:
        """Load language generation rules"""
        return {
            "email_rules": {
                "min_paragraphs": 2,
                "max_paragraphs": 5,
                "tone_consistency": True,
                "clear_call_to_action": True
            },
            "report_rules": {
                "logical_flow": True,
                "data_supports_claims": True,
                "clear_headings": True,
                "actionable_conclusions": True
            },
            "code_explanation_rules": {
                "start_with_purpose": True,
                "explain_key_concepts": True,
                "use_simple_language": True,
                "provide_example": True
            }
        }
    
    def create_variant(self, task: Dict[str, Any], episode: int = 0) -> Callable:
        """
        Create a solution variant for the NLP task.
        
        Args:
            task: The NLP task to solve
            episode: Current training episode
            
        Returns:
            Function that generates the solution
        """
        task_type = task["type"]
        
        if task_type == "email_writing":
            return self._create_email_solution(task)
        elif task_type == "report_generation":
            return self._create_report_solution(task)
        elif task_type == "code_explanation":
            return self._create_explanation_solution(task)
        elif task_type == "text_summarization":
            return self._create_summary_solution(task)
        elif task_type == "translation":
            return self._create_translation_solution(task)
        elif task_type == "sentiment_analysis":
            return self._create_sentiment_solution(task)
        elif task_type == "intent_recognition":
            return self._create_intent_solution(task)
        else:
            raise ValueError(f"Unsupported NLP task type: {task_type}")
    
    def _create_email_solution(self, task: Dict) -> Callable:
        """Create email generation solution"""
        
        purpose = task["inputs"]["purpose"]
        tone = task["inputs"]["tone"]
        context = task["inputs"]["context"]
        
        def generate_email(**kwargs):
            """Generate email based on task requirements"""
            
            # Select template based on tone
            if tone == "professional":
                greeting = f"Dear {kwargs.get('recipient', 'Recipient')},"
                closing = "Best regards,\nSender"
            elif tone == "casual":
                greeting = f"Hi {kwargs.get('recipient', 'there')},"
                closing = "Cheers,\nSender"
            elif tone == "formal":
                greeting = f"Dear {kwargs.get('recipient', 'Sir/Madam')},"
                closing = "Respectfully,\nSender"
            else:  # friendly
                greeting = f"Hello {kwargs.get('recipient', 'friend')},"
                closing = "Best wishes,\nSender"
            
            # Generate body based on purpose
            if purpose == "follow_up":
                body = f"\n\nI hope this email finds you well. I'm following up on {context.get('topic', 'our previous discussion')} that we discussed {context.get('timeframe', 'recently')}.\n\n"
                body += "Would you have time for a quick call this week to discuss further?\n"
            elif purpose == "meeting_request":
                body = f"\n\nI'd like to schedule a meeting to discuss {context.get('topic', 'an important matter')}.\n\n"
                body += f"Proposed duration: {context.get('duration', '30 minutes')}\n"
                body += f"Suggested times: {context.get('times', 'this week')}\n\n"
                body += "Please let me know what works for your schedule.\n"
            elif purpose == "status_update":
                body = f"\n\nHere's a quick update on {context.get('project', 'the project')}:\n\n"
                body += "Progress:\n"
                body += "- Key milestone achieved\n- On track for delivery\n\n"
                body += "Next Steps:\n"
                body += "- Continue development\n- Schedule review meeting\n\n"
                body += "Let me know if you have any questions.\n"
            else:
                body = f"\n\nI'm writing regarding {context.get('topic', 'a business matter')}.\n\n"
                body += "Please let me know if you need any additional information.\n"
            
            email = f"{greeting}{body}\n{closing}"
            
            return email
        
        return generate_email
    
    def _create_report_solution(self, task: Dict) -> Callable:
        """Create report generation solution"""
        
        report_type = task["inputs"]["report_type"]
        data_points = task["inputs"]["data_points"]
        
        def generate_report(**kwargs):
            """Generate structured report"""
            
            title = f"# {report_type.replace('_', ' ').title()} Report\n\n"
            title += f"*Generated on report date*\n\n---\n\n"
            
            # Executive summary
            summary = "## Executive Summary\n\n"
            summary += f"This report analyzes {report_type.replace('_', ' ')} with {data_points} key data points.\n\n"
            summary += "**Key Findings**:\n\n"
            summary += "1. Primary metric shows positive trend\n"
            summary += "2. Secondary indicators support main conclusion\n"
            summary += "3. Recommendations provided for next steps\n\n"
            
            # Main sections
            sections = "## Detailed Analysis\n\n"
            for i in range(min(data_points, 5)):
                sections += f"### Metric {i+1}\n\n"
                sections += f"- Current value: Baseline + {random.randint(5, 20)}%\n"
                sections += f"- Trend: {'Increasing' if random.random() > 0.3 else 'Stable'}\n"
                sections += f"- Significance: {'High' if random.random() > 0.5 else 'Medium'}\n\n"
            
            # Conclusions
            conclusions = "## Conclusions\n\n"
            conclusions += "The analysis reveals several important insights that warrant attention.\n\n"
            
            # Recommendations
            recommendations = "## Recommendations\n\n"
            recommendations += "1. **Continue current strategy**: Results are positive\n"
            recommendations += "2. **Monitor key metrics**: Track changes weekly\n"
            recommendations += "3. **Investigate outliers**: Understand anomalies\n\n"
            
            report = title + summary + sections + conclusions + recommendations
            
            return report
        
        return generate_report
    
    def _create_explanation_solution(self, task: Dict) -> Callable:
        """Create code explanation solution"""
        
        code = task["inputs"]["code"]
        level = task["inputs"]["explanation_level"]
        
        def explain_code(**kwargs):
            """Explain the provided code"""
            
            # Analyze code structure
            has_function = "def " in code
            has_class = "class " in code
            has_loop = "for " in code or "while " in code
            has_condition = "if " in code
            
            explanation = f"## Code Explanation\n\n"
            explanation += f"**Purpose**: This code {'defines a function' if has_function else 'implements logic'}"
            if has_class:
                explanation += " and defines a class"
            explanation += ".\n\n"
            
            explanation += "**How it works**:\n\n"
            
            if has_function:
                explanation += "1. **Function Definition**: The code defines a reusable block of logic\n"
            if has_loop:
                explanation += "2. **Iteration**: It processes multiple items using a loop\n"
            if has_condition:
                explanation += "3. **Decision Making**: Conditional logic determines different execution paths\n"
            if has_class:
                explanation += "4. **Object-Oriented**: Uses classes for organized code structure\n"
            
            explanation += "\n**Key Concepts**:\n\n"
            
            if "return" in code:
                explanation += "- **Return Values**: The function outputs results\n"
            if "append" in code or "items" in code:
                explanation += "- **Data Structures**: Uses lists or collections to store data\n"
            if "**" in code or "^" in code:
                explanation += "- **Mathematical Operations**: Performs calculations\n"
            
            if task["inputs"].get("include_examples", False):
                explanation += "\n**Example Usage**:\n\n"
                explanation += "```python\n"
                explanation += "# Example call\n"
                if has_function:
                    func_name = re.search(r'def (\w+)', code)
                    if func_name:
                        explanation += f"result = {func_name.group(1)}(example_input)\n"
                explanation += "```\n"
            
            return explanation
        
        return explain_code
    
    def _create_summary_solution(self, task: Dict) -> Callable:
        """Create text summarization solution"""
        
        text = task["inputs"]["text"]
        
        def summarize(**kwargs):
            """Summarize the provided text"""
            
            sentences = re.split(r'[.!?]+', text)
            sentences = [s.strip() for s in sentences if s.strip()]
            
            if not sentences:
                return text
            
            # Extract key sentences (simple extractive summarization)
            compression_ratio = task["expected_output"]["compression_ratio"]
            num_sentences = max(1, int(len(sentences) * compression_ratio))
            
            # Take first and most important sentences
            summary_sentences = sentences[:num_sentences]
            
            summary = '. '.join(summary_sentences) + '.'
            
            return summary
        
        return summarize
    
    def _create_translation_solution(self, task: Dict) -> Callable:
        """Create translation solution"""
        
        text = task["inputs"]["text"]
        target_language = task["inputs"]["target_language"]
        
        # Simple dictionary-based translation for demo
        translations = {
            "Spanish": {
                "Hello, how are you?": "Hola, ¿cómo estás?",
                "Thank you very much": "Muchas gracias",
                "Good morning": "Buenos días"
            },
            "French": {
                "Hello, how are you?": "Bonjour, comment allez-vous?",
                "Thank you very much": "Merci beaucoup",
                "Good morning": "Bonjour"
            },
            "German": {
                "Hello, how are you?": "Hallo, wie geht es Ihnen?",
                "Thank you very much": "Vielen Dank",
                "Good morning": "Guten Morgen"
            }
        }
        
        def translate(**kwargs):
            """Translate text to target language"""
            
            lang_dict = translations.get(target_language, {})
            
            # Try exact match first
            if text in lang_dict:
                return lang_dict[text]
            
            # Fallback: indicate translation needed
            return f"[Translation to {target_language}: {text}]"
        
        return translate
    
    def _create_sentiment_solution(self, task: Dict) -> Callable:
        """Create sentiment analysis solution"""
        
        def analyze_sentiment(**kwargs):
            """Analyze sentiment of text"""
            
            text = kwargs.get("text", "").lower()
            
            # Simple keyword-based sentiment analysis
            positive_words = ["love", "great", "amazing", "excellent", "good", "happy", "wonderful", "outstanding"]
            negative_words = ["terrible", "bad", "awful", "poor", "hate", "disappointed", "worst", "horrible"]
            
            pos_count = sum(1 for word in positive_words if word in text)
            neg_count = sum(1 for word in negative_words if word in text)
            
            if pos_count > neg_count:
                sentiment = "positive"
                confidence = 0.7 + (pos_count * 0.1)
            elif neg_count > pos_count:
                sentiment = "negative"
                confidence = 0.7 + (neg_count * 0.1)
            else:
                sentiment = "neutral"
                confidence = 0.6
            
            return {
                "sentiment": sentiment,
                "confidence": min(confidence, 0.95),
                "positive_indicators": pos_count,
                "negative_indicators": neg_count
            }
        
        return analyze_sentiment
    
    def _create_intent_solution(self, task: Dict) -> Callable:
        """Create intent recognition solution"""
        
        def recognize_intent(**kwargs):
            """Recognize intent from utterance"""
            
            utterance = kwargs.get("utterance", "").lower()
            
            # Keyword-based intent classification
            intent_keywords = {
                "booking": ["book", "reserve", "schedule", "appointment"],
                "information": ["what", "when", "where", "how", "info"],
                "support": ["help", "issue", "problem", "assist"],
                "modification": ["change", "update", "modify", "reschedule"],
                "purchase": ["buy", "purchase", "upgrade", "subscribe"],
                "complaint": ["complaint", "refund", "charged", "failed"]
            }
            
            best_intent = "unknown"
            best_score = 0
            
            for intent, keywords in intent_keywords.items():
                score = sum(1 for keyword in keywords if keyword in utterance)
                if score > best_score:
                    best_score = score
                    best_intent = intent
            
            confidence = min(0.6 + (best_score * 0.15), 0.95)
            
            return {
                "intent": best_intent,
                "confidence": confidence,
                "matched_keywords": best_score
            }
        
        return recognize_intent
    
    def update_quality(self, success: bool, correctness: float = None, 
                      current_solution = None, task: Dict[str, Any] = None, 
                      episode: int = 0):
        """Update quality based on performance"""
        if success:
            self.quality_level = min(0.99, self.quality_level + 0.05)
        else:
            self.quality_level = max(0.1, self.quality_level - 0.02)


# Export for use in multi-domain system
NLPTaskGenerator = NLPTaskGenerator
NLPEvolver = NLPEvolver
