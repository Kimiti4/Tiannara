"""
UI/UX Enhancement Module

Purpose: Improve user experience across the Tiannara system
Features:
- Response formatting and presentation
- Progress indicators and feedback
- Error message improvement
- Accessibility enhancements
- Personalization engine
- User onboarding flow
- Help and guidance system

Date: May 8, 2026
Status: Implementation Phase - Week 17-20
"""

import json
from typing import Dict, List, Any, Optional
from datetime import datetime
from enum import Enum


class ResponseFormat(Enum):
    """Output format types."""
    PLAIN_TEXT = "plain_text"
    MARKDOWN = "markdown"
    JSON = "json"
    TABLE = "table"
    CHART_DATA = "chart_data"
    SUMMARY = "summary"


class UXEnhancementEngine:
    """
    Comprehensive UX enhancement engine for improving user interactions.
    
    Features:
    - Smart response formatting
    - Progressive disclosure
    - Contextual help
    - Personalization
    - Accessibility support
    """
    
    def __init__(self):
        # User preferences (loaded from context preservation)
        self.user_preferences = {
            "response_format": "markdown",
            "detail_level": "medium",  # brief, medium, detailed
            "language": "en",
            "timezone": "UTC",
            "accessibility_mode": False,
            "color_scheme": "light"
        }
        
        # Response templates
        self.templates = self._load_templates()
        
        # Help content
        self.help_database = self._build_help_database()
        
        # Statistics
        self.ux_stats = {
            "responses_formatted": 0,
            "help_requests_served": 0,
            "personalization_applied": 0
        }
    
    def _load_templates(self) -> Dict:
        """Load response templates."""
        return {
            "prediction_response": {
                "brief": "{sport} prediction: {outcome} ({confidence:.0%})",
                "medium": "**{sport} Prediction**\n\nOutcome: **{outcome}**\nConfidence: {confidence:.0%}\n\n{reasoning}",
                "detailed": "## {sport} Prediction\n\n### Predicted Outcome\n**{outcome}** with {confidence:.0%} confidence\n\n### Analysis\n{reasoning}\n\n### Key Factors\n{factors}\n\n### Recommendation\n{recommendation}"
            },
            
            "analysis_response": {
                "brief": "{subject}: {key_finding}",
                "medium": "**Analysis: {subject}**\n\n{key_finding}\n\nDetails: {details}",
                "detailed": "## Analysis: {subject}\n\n### Key Findings\n{key_finding}\n\n### Detailed Analysis\n{details}\n\n### Recommendations\n{recommendations}"
            },
            
            "error_response": {
                "brief": "Error: {message}",
                "medium": "⚠️ **Issue Encountered**\n\n{message}\n\n{solution}",
                "detailed": "## Issue Encountered\n\n### Problem\n{message}\n\n### What Happened\n{context}\n\n### Solution\n{solution}\n\n### Next Steps\n{next_steps}"
            }
        }
    
    def _build_help_database(self) -> Dict:
        """Build contextual help database."""
        return {
            "prediction": {
                "title": "Understanding Predictions",
                "content": "Predictions use AI models to forecast outcomes based on historical data, current form, and various factors.",
                "tips": [
                    "Check confidence scores - higher is better",
                    "Consider multiple predictions for important decisions",
                    "Review the reasoning behind each prediction"
                ]
            },
            
            "analysis": {
                "title": "Reading Analysis Reports",
                "content": "Analysis provides detailed insights into performance, trends, and patterns.",
                "tips": [
                    "Look for key findings at the top",
                    "Review supporting data in details section",
                    "Consider recommendations for action"
                ]
            },
            
            "settings": {
                "title": "Customizing Your Experience",
                "content": "Adjust settings to personalize your interaction with the system.",
                "tips": [
                    "Choose your preferred response format",
                    "Set detail level based on your needs",
                    "Enable accessibility features if needed"
                ]
            },
            
            "getting_started": {
                "title": "Getting Started Guide",
                "content": "Welcome! Here's how to make the most of Tiannara.",
                "tips": [
                    "Ask questions in natural language",
                    "Specify sports, teams, or dates for better results",
                    "Use 'help' anytime for assistance"
                ]
            }
        }
    
    def format_response(self, 
                       content: Any,
                       response_type: str = "prediction",
                       format_type: Optional[ResponseFormat] = None,
                       detail_level: Optional[str] = None) -> str:
        """
        Format response based on user preferences and content type.
        
        Args:
            content: Response content (dict, list, or string)
            response_type: Type of response (prediction, analysis, etc.)
            format_type: Override format type
            detail_level: Override detail level
            
        Returns:
            Formatted response string
        """
        # Use user preferences if not overridden
        fmt = format_type or ResponseFormat(self.user_preferences["response_format"])
        detail = detail_level or self.user_preferences["detail_level"]
        
        # Apply formatting
        if fmt == ResponseFormat.MARKDOWN:
            formatted = self._format_markdown(content, response_type, detail)
        elif fmt == ResponseFormat.JSON:
            formatted = self._format_json(content)
        elif fmt == ResponseFormat.TABLE:
            formatted = self._format_table(content)
        else:
            formatted = self._format_plain_text(content)
        
        # Update stats
        self.ux_stats["responses_formatted"] += 1
        
        return formatted
    
    def _format_markdown(self, 
                        content: Any,
                        response_type: str,
                        detail_level: str) -> str:
        """Format content as markdown."""
        
        if isinstance(content, dict):
            if response_type == "prediction":
                template = self.templates["prediction_response"].get(detail_level, "")
                return template.format(
                    sport=content.get("sport", "Sports"),
                    outcome=content.get("outcome", "Unknown"),
                    confidence=content.get("confidence", 0.5),
                    reasoning=content.get("reasoning", ""),
                    factors=self._format_list(content.get("factors", [])),
                    recommendation=content.get("recommendation", "")
                )
            
            elif response_type == "analysis":
                template = self.templates["analysis_response"].get(detail_level, "")
                return template.format(
                    subject=content.get("subject", "Analysis"),
                    key_finding=content.get("key_finding", ""),
                    details=content.get("details", ""),
                    recommendations=self._format_list(content.get("recommendations", []))
                )
        
        # Default: convert dict to readable format
        if isinstance(content, dict):
            lines = ["## Response\n"]
            for key, value in content.items():
                lines.append(f"**{key.replace('_', ' ').title()}**: {value}")
            return "\n".join(lines)
        
        elif isinstance(content, list):
            lines = ["## Results\n"]
            for i, item in enumerate(content, 1):
                lines.append(f"{i}. {item}")
            return "\n".join(lines)
        
        else:
            return str(content)
    
    def _format_json(self, content: Any) -> str:
        """Format content as JSON."""
        return json.dumps(content, indent=2, default=str)
    
    def _format_table(self, content: Any) -> str:
        """Format content as table."""
        if isinstance(content, list) and len(content) > 0:
            if isinstance(content[0], dict):
                # Get headers
                headers = list(content[0].keys())
                
                # Build table
                lines = []
                
                # Header row
                header_line = "| " + " | ".join(headers) + " |"
                lines.append(header_line)
                
                # Separator
                sep_line = "| " + " | ".join(["---"] * len(headers)) + " |"
                lines.append(sep_line)
                
                # Data rows
                for row in content:
                    values = [str(row.get(h, "")) for h in headers]
                    data_line = "| " + " | ".join(values) + " |"
                    lines.append(data_line)
                
                return "\n".join(lines)
        
        return str(content)
    
    def _format_plain_text(self, content: Any) -> str:
        """Format content as plain text."""
        if isinstance(content, dict):
            lines = []
            for key, value in content.items():
                lines.append(f"{key}: {value}")
            return "\n".join(lines)
        elif isinstance(content, list):
            return "\n".join([f"- {item}" for item in content])
        else:
            return str(content)
    
    def _format_list(self, items: List[str]) -> str:
        """Format list as bullet points."""
        if not items:
            return "N/A"
        return "\n".join([f"- {item}" for item in items])
    
    def get_contextual_help(self, topic: str) -> Dict:
        """
        Get contextual help for a specific topic.
        
        Args:
            topic: Help topic (prediction, analysis, settings, etc.)
            
        Returns:
            Help content dictionary
        """
        help_content = self.help_database.get(topic, {
            "title": "Help",
            "content": "No specific help available for this topic.",
            "tips": []
        })
        
        self.ux_stats["help_requests_served"] += 1
        
        return help_content
    
    def personalize_response(self, 
                            response: str,
                            user_context: Dict[str, Any]) -> str:
        """
        Personalize response based on user context and preferences.
        
        Args:
            response: Original response
            user_context: User context information
            
        Returns:
            Personalized response
        """
        personalized = response
        
        # Add user name if available
        user_name = user_context.get("name")
        if user_name:
            personalized = f"Hi {user_name},\n\n{personalized}"
        
        # Adjust tone based on user history
        interaction_count = user_context.get("interaction_count", 0)
        if interaction_count < 3:
            # New user - add encouraging message
            personalized += "\n\n💡 *Tip: Feel free to ask follow-up questions for more details!*"
        
        # Add timezone-aware timestamps
        if user_context.get("timezone"):
            timestamp = datetime.now().strftime("%I:%M %p")
            personalized += f"\n\n*Generated at {timestamp}* "
        
        self.ux_stats["personalization_applied"] += 1
        
        return personalized
    
    def generate_progress_indicator(self, 
                                   step: int,
                                   total_steps: int,
                                   message: str = "") -> str:
        """
        Generate progress indicator for long-running operations.
        
        Args:
            step: Current step number
            total_steps: Total number of steps
            message: Optional status message
            
        Returns:
            Progress indicator string
        """
        percentage = (step / total_steps) * 100
        bar_length = 20
        filled = int(bar_length * step / total_steps)
        
        bar = "█" * filled + "░" * (bar_length - filled)
        
        if message:
            return f"[{bar}] {percentage:.0f}% - {message}"
        else:
            return f"[{bar}] {percentage:.0f}%"
    
    def format_error_message(self, 
                            error: Exception,
                            user_friendly: bool = True) -> str:
        """
        Format error message for user display.
        
        Args:
            error: Exception object
            user_friendly: Whether to use user-friendly format
            
        Returns:
            Formatted error message
        """
        if user_friendly:
            # Map common errors to friendly messages
            error_message = str(error).lower()
            
            if "connection" in error_message or "timeout" in error_message:
                friendly_msg = "Unable to connect to the service. Please check your internet connection and try again."
                solution = "Try refreshing or checking your network settings."
            elif "permission" in error_message or "unauthorized" in error_message:
                friendly_msg = "You don't have permission to perform this action."
                solution = "Please log in or contact support if you believe this is an error."
            elif "not found" in error_message:
                friendly_msg = "The requested resource was not found."
                solution = "Please check the URL or search terms and try again."
            else:
                friendly_msg = "An unexpected error occurred."
                solution = "Please try again or contact support if the problem persists."
            
            template = self.templates["error_response"]["medium"]
            return template.format(
                message=friendly_msg,
                solution=solution
            )
        else:
            # Technical error message
            return f"Error: {type(error).__name__}: {str(error)}"
    
    def create_onboarding_flow(self) -> List[Dict]:
        """
        Create onboarding flow for new users.
        
        Returns:
            List of onboarding steps
        """
        return [
            {
                "step": 1,
                "title": "Welcome to Tiannara!",
                "message": "I'm your AI assistant for predictions, analysis, and insights.",
                "action": "introduction"
            },
            {
                "step": 2,
                "title": "What can I do?",
                "message": "I can help you with:\n- Sports predictions\n- Performance analysis\n- Trend forecasting\n- Data insights",
                "action": "capabilities_overview"
            },
            {
                "step": 3,
                "title": "Let's personalize your experience",
                "message": "Would you like to set your preferences?",
                "options": ["Yes, customize settings", "Skip for now"],
                "action": "preference_setup"
            },
            {
                "step": 4,
                "title": "Try it out!",
                "message": "Ask me anything! For example:\n- 'Predict tomorrow's football match'\n- 'Analyze Team A's performance'\n- 'Show me recent trends'",
                "action": "first_interaction"
            },
            {
                "step": 5,
                "title": "Need help?",
                "message": "Type 'help' anytime for assistance, or ask specific questions about features.",
                "action": "help_introduction"
            }
        ]
    
    def enhance_accessibility(self, content: str) -> str:
        """
        Enhance content for accessibility.
        
        Args:
            content: Original content
            
        Returns:
            Accessibility-enhanced content
        """
        enhanced = content
        
        # Add alt text descriptions for emojis
        emoji_descriptions = {
            "✅": "[Success] ",
            "⚠️": "[Warning] ",
            "❌": "[Error] ",
            "💡": "[Tip] ",
            "📊": "[Chart] ",
            "🎯": "[Target] "
        }
        
        for emoji, description in emoji_descriptions.items():
            enhanced = enhanced.replace(emoji, description + emoji)
        
        # Ensure proper heading structure
        enhanced = enhanced.replace("##", "\n## ")
        enhanced = enhanced.replace("###", "\n### ")
        
        return enhanced
    
    def get_ux_stats(self) -> Dict:
        """Get UX enhancement statistics."""
        return self.ux_stats.copy()


# Example usage and testing
if __name__ == "__main__":
    print("="*70)
    print("UI/UX ENHANCEMENT ENGINE - TEST")
    print("="*70)
    
    engine = UXEnhancementEngine()
    
    # Test 1: Format prediction response
    print("\n📝 Test 1: Formatting Prediction Response")
    print("-" * 70)
    
    prediction_data = {
        "sport": "Football",
        "outcome": "Home Win",
        "confidence": 0.72,
        "reasoning": "Based on recent form and head-to-head record",
        "factors": ["Strong home record", "Away team injuries", "Historical advantage"],
        "recommendation": "Moderate confidence - consider additional factors"
    }
    
    formatted = engine.format_response(
        prediction_data,
        response_type="prediction",
        detail_level="detailed"
    )
    print(formatted)
    
    # Test 2: Format analysis response
    print("\n\n📊 Test 2: Formatting Analysis Response")
    print("-" * 70)
    
    analysis_data = {
        "subject": "Team United Performance",
        "key_finding": "Team shows strong attacking form but defensive vulnerabilities",
        "details": "Last 5 matches: 4 wins, 1 loss. Goals scored: 12, Goals conceded: 7",
        "recommendations": ["Focus on defensive training", "Maintain attacking momentum"]
    }
    
    formatted = engine.format_response(
        analysis_data,
        response_type="analysis",
        detail_level="medium"
    )
    print(formatted)
    
    # Test 3: Contextual help
    print("\n\n❓ Test 3: Contextual Help")
    print("-" * 70)
    
    help_content = engine.get_contextual_help("prediction")
    print(f"**{help_content['title']}**\n")
    print(help_content['content'])
    print("\nTips:")
    for tip in help_content['tips']:
        print(f"  • {tip}")
    
    # Test 4: Progress indicator
    print("\n\n⏳ Test 4: Progress Indicators")
    print("-" * 70)
    
    for step in range(1, 6):
        progress = engine.generate_progress_indicator(
            step=step,
            total_steps=5,
            message=f"Processing step {step}"
        )
        print(progress)
    
    # Test 5: Error formatting
    print("\n\n⚠️  Test 5: Error Message Formatting")
    print("-" * 70)
    
    try:
        raise ConnectionError("Connection timeout")
    except Exception as e:
        error_msg = engine.format_error_message(e, user_friendly=True)
        print(error_msg)
    
    # Test 6: Personalization
    print("\n\n👤 Test 6: Response Personalization")
    print("-" * 70)
    
    user_ctx = {
        "name": "John",
        "interaction_count": 1,
        "timezone": "EST"
    }
    
    base_response = "Here are your predictions for today."
    personalized = engine.personalize_response(base_response, user_ctx)
    print(personalized)
    
    # Test 7: Onboarding flow
    print("\n\n🎓 Test 7: Onboarding Flow Preview")
    print("-" * 70)
    
    onboarding = engine.create_onboarding_flow()
    print(f"Onboarding flow has {len(onboarding)} steps:\n")
    for step in onboarding[:3]:  # Show first 3 steps
        print(f"Step {step['step']}: {step['title']}")
        print(f"  {step['message'][:80]}...\n")
    
    # Test 8: Table formatting
    print("\n\n📋 Test 8: Table Formatting")
    print("-" * 70)
    
    table_data = [
        {"Team": "Team A", "Wins": 10, "Losses": 2, "Draws": 3},
        {"Team": "Team B", "Wins": 8, "Losses": 4, "Draws": 3},
        {"Team": "Team C", "Wins": 6, "Losses": 6, "Draws": 3}
    ]
    
    formatted_table = engine.format_response(
        table_data,
        format_type=ResponseFormat.TABLE
    )
    print(formatted_table)
    
    # Show statistics
    print("\n\n📈 UX Enhancement Statistics:")
    print("-" * 70)
    stats = engine.get_ux_stats()
    for key, value in stats.items():
        print(f"  {key}: {value}")
    
    print("\n" + "="*70)
    print("✅ UI/UX ENHANCEMENT ENGINE TEST COMPLETE")
    print("="*70)
